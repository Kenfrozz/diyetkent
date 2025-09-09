import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/diet_package_model.dart';
import '../models/diet_file_model.dart';
import '../database/drift_service.dart';
import 'directory_parser_service.dart';
import 'local_file_storage_service.dart';

typedef ProgressCallback = void Function(int current, int total, String message);

/// Service for bulk upload of diet packages with progress tracking
class BulkDietUploadService {
  /// Analyze folder structure for diet packages
  Future<Map<String, dynamic>> analyzeFolderStructure(String folderPath) async {
    return await DirectoryParserService.parseDirectory(folderPath);
  }

  /// Upload bulk diet packages with progress tracking
  Future<Map<String, dynamic>> uploadBulkDietPackages({
    required String folderPath,
    required Map<String, dynamic> analysis,
    required String dietitianId,
    ProgressCallback? onProgress,
  }) async {
    final results = <String, dynamic>{
      'success': false,
      'uploadedPackages': <Map<String, dynamic>>[],
      'failedPackages': <Map<String, dynamic>>[],
      'totalProcessed': 0,
      'errors': <String>[],
    };

    try {
      if (!analysis['isValid']) {
        throw Exception('Klasör yapısı analizi başarısız oldu');
      }

      final packages = analysis['packages'] as List<Map<String, dynamic>>;
      if (packages.isEmpty) {
        throw Exception('Yüklenecek paket bulunamadı');
      }

      // Calculate total items for progress tracking
      int totalItems = 0;
      for (final package in packages) {
        final diets = package['diets'] as List<Map<String, dynamic>>;
        for (final diet in diets) {
          totalItems += (diet['files'] as List).length;
        }
      }

      int currentItem = 0;
      onProgress?.call(currentItem, totalItems, 'Yükleme başlıyor...');

      // Process each package
      for (final packageData in packages) {
        try {
          final uploadResult = await _uploadSinglePackage(
            packageData: packageData,
            dietitianId: dietitianId,
            onProgress: (current, total, message) {
              currentItem = current;
              onProgress?.call(currentItem, totalItems, message);
            },
            totalItemsSoFar: currentItem,
          );

          if (uploadResult['success']) {
            results['uploadedPackages'].add(uploadResult);
            currentItem += uploadResult['processedFiles'] as int;
          } else {
            results['failedPackages'].add({
              'packageName': packageData['name'],
              'error': uploadResult['error'],
            });
            results['errors'].add('${packageData['name']}: ${uploadResult['error']}');
          }

          results['totalProcessed']++;

        } catch (e) {
          results['failedPackages'].add({
            'packageName': packageData['name'],
            'error': e.toString(),
          });
          results['errors'].add('${packageData['name']}: $e');
        }
      }

      results['success'] = results['uploadedPackages'].isNotEmpty;
      onProgress?.call(totalItems, totalItems, 
        'Tamamlandı! ${results['uploadedPackages'].length}/${packages.length} paket yüklendi');

      return results;

    } catch (e) {
      results['errors'].add('Genel hata: $e');
      onProgress?.call(0, 1, 'Hata: $e');
      return results;
    }
  }

  /// Upload a single diet package
  Future<Map<String, dynamic>> _uploadSinglePackage({
    required Map<String, dynamic> packageData,
    required String dietitianId,
    ProgressCallback? onProgress,
    int totalItemsSoFar = 0,
  }) async {
    try {
      final packageName = packageData['name'] as String;
      onProgress?.call(totalItemsSoFar, 0, 'Paket işleniyor: $packageName');

      // Create diet package model
      final packageModel = await _createDietPackageModel(packageData, dietitianId);
      
      // Save package to database
      await DriftService.saveDietPackage(packageModel);
      
      final diets = packageData['diets'] as List<Map<String, dynamic>>;
      int processedFiles = 0;
      final dietFiles = <DietFileModel>[];

      // Process each diet in the package
      for (final dietData in diets) {
        final files = dietData['files'] as List<Map<String, dynamic>>;
        
        for (final fileData in files) {
          try {
            processedFiles++;
            final fileName = fileData['fileName'] as String;
            onProgress?.call(
              totalItemsSoFar + processedFiles, 
              0, 
              'Dosya kopyalanıyor: $fileName'
            );

            // Copy file to local storage
            final originalFile = File(fileData['filePath'] as String);
            final storedFile = await _copyFileToStorage(originalFile, packageName, dietData['name'], fileData['bmiRange']);
            
            // Create diet file model
            final dietFile = _createDietFileModel(
              packageModel: packageModel,
              dietName: dietData['name'],
              fileData: fileData,
              storedFilePath: storedFile.path,
            );

            dietFiles.add(dietFile);
            await DriftService.saveDietFile(dietFile);

          } catch (e) {
            throw Exception('Dosya işleme hatası (${fileData['fileName']}): $e');
          }
        }
      }

      return {
        'success': true,
        'packageId': packageModel.packageId,
        'packageName': packageName,
        'processedFiles': processedFiles,
        'dietFiles': dietFiles,
      };

    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Create DietPackageModel from package data
  Future<DietPackageModel> _createDietPackageModel(
    Map<String, dynamic> packageData,
    String dietitianId,
  ) async {
    final packageName = packageData['name'] as String;
    final diets = packageData['diets'] as List<Map<String, dynamic>>;
    
    // Calculate total files and set reasonable defaults
    final totalFiles = diets.fold<int>(
      0, 
      (sum, diet) => sum + (diet['files'] as List).length
    );

    return DietPackageModel.create(
      packageId: 'pkg_${DateTime.now().millisecondsSinceEpoch}',
      title: packageName,
      description: 'Toplu yüklemeden oluşturulan paket: $packageName',
      dietitianId: dietitianId,
      durationDays: diets.length * 7, // Each diet for 7 days
      numberOfFiles: diets.length,
      daysPerFile: 7,
      targetWeightChangePerFile: -1.5, // Default weight loss target
      tags: ['bulk_upload', 'auto_generated'],
      specialNotes: 'Otomatik yükleme: ${diets.length} diyet türü, $totalFiles dosya',
      isActive: true,
    );
  }

  /// Create DietFileModel from file data
  DietFileModel _createDietFileModel({
    required DietPackageModel packageModel,
    required String dietName,
    required Map<String, dynamic> fileData,
    required String storedFilePath,
  }) {
    final bmiRange = fileData['bmiRange'] as String;
    final fileName = fileData['fileName'] as String;

    final dietFile = DietFileModel.create(
      fileId: 'file_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}',
      userId: packageModel.dietitianId, // Initially assigned to dietitian
      dietitianId: packageModel.dietitianId,
      title: fileName,
      fileName: fileName,
      fileUrl: storedFilePath,
      fileSizeBytes: fileData['fileSize'] as int,
      fileType: DietFileType.template.name,
      isActive: true,
      description: 'Bulk upload: $dietName for $bmiRange BMI range',
    );
    
    dietFile.tags = ['bulk_upload', bmiRange, dietName.toLowerCase().replaceAll(' ', '_')];
    
    return dietFile;
  }

  /// Copy file to organized storage structure
  Future<File> _copyFileToStorage(
    File originalFile,
    String packageName,
    String dietName,
    String bmiRange,
  ) async {
    // Create organized filename
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = path.extension(originalFile.path);
    final sanitizedPackageName = _sanitizeFileName(packageName);
    final sanitizedDietName = _sanitizeFileName(dietName);
    
    final newFileName = '${sanitizedPackageName}_${sanitizedDietName}_${bmiRange}_$timestamp$extension';
    
    // Save to diet templates folder
    return await LocalFileStorageService.saveDietTemplate(originalFile, newFileName);
  }

  /// Sanitize filename for safe storage
  String _sanitizeFileName(String fileName) {
    // Remove or replace problematic characters
    return fileName
        .replaceAll(RegExp(r'[^\w\s-]'), '')  // Remove special characters
        .replaceAll(RegExp(r'\s+'), '_')      // Replace spaces with underscores
        .toLowerCase();
  }

  /// Validate upload prerequisites
  Future<Map<String, dynamic>> validateUploadPrerequisites({
    required String folderPath,
    required String dietitianId,
  }) async {
    final issues = <String>[];
    final warnings = <String>[];

    // Check if folder exists
    final folder = Directory(folderPath);
    if (!await folder.exists()) {
      issues.add('Seçilen klasör bulunamadı');
    }

    // Check dietitian ID
    if (dietitianId.isEmpty) {
      issues.add('Diyetisyen kimliği geçersiz');
    }

    // Check storage availability
    try {
      await LocalFileStorageService.initializeStorage();
    } catch (e) {
      issues.add('Depolama sistemi hazırlanamadı: $e');
    }

    // Check disk space (basic check)
    try {
      final stats = await LocalFileStorageService.getStorageStats();
      if (stats['error'] != null) {
        warnings.add('Disk alanı kontrolü yapılamadı');
      }
    } catch (e) {
      warnings.add('Disk alanı kontrolü sırasında hata: $e');
    }

    return {
      'isValid': issues.isEmpty,
      'issues': issues,
      'warnings': warnings,
      'canProceed': issues.isEmpty,
    };
  }

  /// Get upload statistics
  Future<Map<String, dynamic>> getUploadStatistics(String dietitianId) async {
    try {
      final packages = await DriftService.getDietitianPackages(dietitianId);
      final bulkUploadedPackages = packages.where((pkg) => 
        pkg.tags.contains('bulk_upload')
      ).toList();

      int totalDiets = 0;
      int totalFiles = 0;

      for (final package in bulkUploadedPackages) {
        totalDiets += package.numberOfFiles;
        totalFiles += package.numberOfFiles; // Approximate, could be more precise
      }

      return {
        'totalPackages': bulkUploadedPackages.length,
        'totalDiets': totalDiets,
        'totalFiles': totalFiles,
        'lastUploadDate': bulkUploadedPackages.isNotEmpty 
          ? bulkUploadedPackages.first.createdAt
          : null,
        'packages': bulkUploadedPackages.map((pkg) => {
          'name': pkg.title,
          'dietCount': pkg.numberOfFiles,
          'createdAt': pkg.createdAt,
        }).toList(),
      };
    } catch (e) {
      return {
        'error': 'İstatistik alınamadı: $e',
      };
    }
  }

  /// Delete uploaded package and its files
  Future<bool> deleteUploadedPackage(String packageId) async {
    try {
      // Get package
      final package = await DriftService.getDietPackage(packageId);
      if (package == null) return false;

      // Get related diet files
      final allFiles = await LocalFileStorageService.getAllDietTemplates();
      final packageFiles = allFiles.where((file) {
        final fileName = path.basename(file.path);
        return fileName.contains(package.title.toLowerCase());
      }).toList();

      // Delete files from storage
      for (final file in packageFiles) {
        await LocalFileStorageService.deleteFile(file);
      }
      
      // Delete package from database
      await DriftService.deleteDietPackage(packageId);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Preview upload operation without actually uploading
  Future<Map<String, dynamic>> previewUpload(String folderPath) async {
    try {
      final analysis = await analyzeFolderStructure(folderPath);
      
      if (!analysis['isValid']) {
        return {
          'success': false,
          'error': 'Klasör yapısı geçersiz',
          'details': analysis,
        };
      }

      final packages = analysis['packages'] as List<Map<String, dynamic>>;
      final preview = <Map<String, dynamic>>[];

      for (final package in packages) {
        final diets = package['diets'] as List<Map<String, dynamic>>;
        final dietPreviews = <Map<String, dynamic>>[];

        for (final diet in diets) {
          final files = diet['files'] as List<Map<String, dynamic>>;
          dietPreviews.add({
            'name': diet['name'],
            'bmiRanges': diet['bmiRanges'],
            'fileCount': files.length,
            'files': files.map((file) => {
              'bmiRange': file['bmiRange'],
              'fileName': file['fileName'],
              'fileSize': LocalFileStorageService.getReadableFileSize(file['fileSize']),
            }).toList(),
          });
        }

        preview.add({
          'packageName': package['name'],
          'dietCount': diets.length,
          'totalFiles': package['totalFiles'],
          'diets': dietPreviews,
        });
      }

      return {
        'success': true,
        'preview': preview,
        'summary': {
          'totalPackages': packages.length,
          'totalDiets': analysis['totalDiets'],
          'totalFiles': analysis['totalFiles'],
        },
      };

    } catch (e) {
      return {
        'success': false,
        'error': 'Önizleme oluşturulamadı: $e',
      };
    }
  }
}