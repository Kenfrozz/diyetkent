import 'dart:io';
import 'package:path/path.dart' as path;

/// Service for parsing directory structures for bulk diet package uploads
class DirectoryParserService {
  static const List<String> _validBmiRanges = [
    '21_25bmi',
    '26_29bmi', 
    '30_33bmi',
    '34_37bmi'
  ];

  static const List<String> _validFileExtensions = ['.docx'];

  /// Parse a directory structure and analyze diet packages
  static Future<Map<String, dynamic>> parseDirectory(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        return _createErrorResult(['Seçilen klasör bulunamadı: $directoryPath']);
      }

      final packageName = path.basename(directoryPath);
      final packages = <Map<String, dynamic>>[];
      final errors = <String>[];
      final warnings = <String>[];

      // Get all subdirectories (diet folders)
      final entities = await directory.list().toList();
      final dietDirectories = entities
          .whereType<Directory>()
          .toList();

      if (dietDirectories.isEmpty) {
        errors.add('Ana klasörde diyet klasörleri bulunamadı');
        return _createResult(packages, errors, warnings);
      }

      // Parse each diet directory
      final dietResults = await Future.wait(
        dietDirectories.map((dietDir) => _parseDietDirectory(dietDir))
      );

      int totalFiles = 0;
      for (final dietResult in dietResults) {
        if (dietResult['isValid']) {
          final dietData = dietResult['diet'] as Map<String, dynamic>;
          dietData['packageName'] = packageName;
          
          final bmiRanges = dietData['bmiRanges'] as List<String>;
          totalFiles += bmiRanges.length;
        }
        
        errors.addAll(dietResult['errors'] as List<String>);
        warnings.addAll(dietResult['warnings'] as List<String>);
      }

      final validDiets = dietResults
          .where((result) => result['isValid'])
          .map((result) => result['diet'] as Map<String, dynamic>)
          .toList();

      if (validDiets.isNotEmpty) {
        packages.add({
          'name': packageName,
          'path': directoryPath,
          'diets': validDiets,
          'totalFiles': totalFiles,
        });
      }

      return _createResult(packages, errors, warnings, totalFiles: totalFiles);

    } catch (e) {
      return _createErrorResult(['Klasör analizi sırasında hata: $e']);
    }
  }

  /// Parse a single diet directory
  static Future<Map<String, dynamic>> _parseDietDirectory(Directory dietDirectory) async {
    final dietName = path.basename(dietDirectory.path);
    final errors = <String>[];
    final warnings = <String>[];

    try {
      // Get all BMI range directories
      final entities = await dietDirectory.list().toList();
      final bmiDirectories = entities
          .whereType<Directory>()
          .toList();

      if (bmiDirectories.isEmpty) {
        errors.add('$dietName: BMI klasörleri bulunamadı');
        return {'isValid': false, 'errors': errors, 'warnings': warnings};
      }

      final validBmiRanges = <String>[];
      final bmiFiles = <Map<String, dynamic>>[];

      for (final bmiDir in bmiDirectories) {
        final bmiRangeName = path.basename(bmiDir.path);
        
        // Validate BMI range name
        if (!_validBmiRanges.contains(bmiRangeName)) {
          warnings.add('$dietName: Geçersiz BMI klasörü adı: $bmiRangeName');
          continue;
        }

        // Check for DOCX files in BMI directory
        final bmiEntities = await bmiDir.list().toList();
        final docxFiles = bmiEntities
            .whereType<File>()
            .where((file) => _validFileExtensions.contains(path.extension(file.path).toLowerCase()))
            .toList();

        if (docxFiles.isEmpty) {
          errors.add('$dietName/$bmiRangeName: DOCX dosyası bulunamadı');
          continue;
        }

        if (docxFiles.length > 1) {
          warnings.add('$dietName/$bmiRangeName: Birden fazla DOCX dosyası bulundu, ilki kullanılacak');
        }

        validBmiRanges.add(bmiRangeName);
        bmiFiles.add({
          'bmiRange': bmiRangeName,
          'filePath': docxFiles.first.path,
          'fileName': path.basename(docxFiles.first.path),
          'fileSize': await docxFiles.first.length(),
        });
      }

      if (validBmiRanges.isEmpty) {
        errors.add('$dietName: Geçerli BMI klasörü bulunamadı');
        return {'isValid': false, 'errors': errors, 'warnings': warnings};
      }

      // Check if all BMI ranges are present
      final missingRanges = _validBmiRanges
          .where((range) => !validBmiRanges.contains(range))
          .toList();
      
      if (missingRanges.isNotEmpty) {
        warnings.add('$dietName: Eksik BMI aralıkları: ${missingRanges.join(', ')}');
      }

      return {
        'isValid': true,
        'diet': {
          'name': dietName,
          'path': dietDirectory.path,
          'bmiRanges': validBmiRanges,
          'files': bmiFiles,
        },
        'errors': errors,
        'warnings': warnings,
      };

    } catch (e) {
      errors.add('$dietName: Klasör analizi hatası: $e');
      return {'isValid': false, 'errors': errors, 'warnings': warnings};
    }
  }

  /// Create a successful analysis result
  static Map<String, dynamic> _createResult(
    List<Map<String, dynamic>> packages,
    List<String> errors,
    List<String> warnings, {
    int totalFiles = 0,
  }) {
    final totalDiets = packages.fold<int>(
      0,
      (sum, package) => sum + (package['diets'] as List).length,
    );

    return {
      'isValid': packages.isNotEmpty && errors.isEmpty,
      'packages': packages,
      'errors': errors,
      'warnings': warnings,
      'totalPackages': packages.length,
      'totalDiets': totalDiets,
      'totalFiles': totalFiles,
      'summary': _generateSummary(packages, errors, warnings),
    };
  }

  /// Create an error result
  static Map<String, dynamic> _createErrorResult(List<String> errors) {
    return {
      'isValid': false,
      'packages': <Map<String, dynamic>>[],
      'errors': errors,
      'warnings': <String>[],
      'totalPackages': 0,
      'totalDiets': 0,
      'totalFiles': 0,
    };
  }

  /// Generate a human-readable summary
  static String _generateSummary(
    List<Map<String, dynamic>> packages,
    List<String> errors,
    List<String> warnings,
  ) {
    if (errors.isNotEmpty) {
      return 'Klasör yapısında ${errors.length} hata bulundu. Lütfen düzeltin ve tekrar deneyin.';
    }

    if (packages.isEmpty) {
      return 'Geçerli diyet paketi bulunamadı.';
    }

    final totalDiets = packages.fold<int>(
      0,
      (sum, package) => sum + (package['diets'] as List).length,
    );

    String summary = '${packages.length} paket, $totalDiets diyet türü bulundu.';
    
    if (warnings.isNotEmpty) {
      summary += ' ${warnings.length} uyarı var.';
    } else {
      summary += ' Tümü yüklenmeye hazır!';
    }

    return summary;
  }

  /// Validate file path and name
  static bool isValidFilePath(String filePath) {
    try {
      final file = File(filePath);
      final extension = path.extension(filePath).toLowerCase();
      return _validFileExtensions.contains(extension) && file.existsSync();
    } catch (e) {
      return false;
    }
  }

  /// Extract diet package metadata from folder structure
  static Map<String, dynamic> extractPackageMetadata(String packagePath) {
    final packageName = path.basename(packagePath);
    final creationTime = DateTime.now();
    
    return {
      'name': packageName,
      'path': packagePath,
      'createdAt': creationTime,
      'extractedFrom': 'bulk_upload',
      'version': '1.0',
      'description': 'Toplu yüklemeden oluşturulan paket: $packageName',
    };
  }

  /// Get BMI range from folder name
  static String? getBmiRangeFromFolder(String folderName) {
    if (_validBmiRanges.contains(folderName)) {
      return folderName;
    }
    return null;
  }

  /// Convert BMI range string to human readable format
  static String getBmiRangeDisplayName(String bmiRange) {
    switch (bmiRange) {
      case '21_25bmi':
        return 'Normal Kilo (BMI 21-25)';
      case '26_29bmi':
        return 'Fazla Kilolu (BMI 26-29)';
      case '30_33bmi':
        return 'Obez 1. Derece (BMI 30-33)';
      case '34_37bmi':
        return 'Obez 2. Derece (BMI 34-37)';
      default:
        return bmiRange;
    }
  }

  /// Get all valid BMI ranges
  static List<String> getValidBmiRanges() {
    return List.from(_validBmiRanges);
  }

  /// Validate package folder structure without deep analysis
  static Future<Map<String, dynamic>> quickValidate(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        return {'isValid': false, 'error': 'Klasör bulunamadı'};
      }

      final entities = await directory.list().toList();
      final subdirectories = entities.whereType<Directory>().toList();

      if (subdirectories.isEmpty) {
        return {'isValid': false, 'error': 'Alt klasör bulunamadı'};
      }

      // Check if at least one subdirectory has BMI folders
      for (final subdir in subdirectories) {
        final subEntities = await subdir.list().toList();
        final bmiDirs = subEntities
            .whereType<Directory>()
            .where((dir) => _validBmiRanges.contains(path.basename(dir.path)))
            .toList();

        if (bmiDirs.isNotEmpty) {
          return {
            'isValid': true,
            'packageName': path.basename(directoryPath),
            'dietCount': subdirectories.length,
            'hasValidStructure': true,
          };
        }
      }

      return {'isValid': false, 'error': 'Geçerli BMI klasörleri bulunamadı'};

    } catch (e) {
      return {'isValid': false, 'error': 'Analiz hatası: $e'};
    }
  }
}