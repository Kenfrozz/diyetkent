import 'dart:io';
import 'package:path/path.dart' as path;
import '../services/directory_parser_service.dart';
import '../services/local_file_storage_service.dart';
import '../database/drift_service.dart';

/// Service for validating and managing diet package uploads
class UploadValidationService {
  // File size limits (in bytes)
  static const int maxFileSize = 10 * 1024 * 1024; // 10 MB
  static const int maxTotalUploadSize = 100 * 1024 * 1024; // 100 MB

  // File count limits
  static const int maxFilesPerPackage = 100;
  static const int maxDietsPerPackage = 20;

  /// Comprehensive validation of upload requirements
  static Future<Map<String, dynamic>> validateCompleteUpload({
    required String folderPath,
    required String dietitianId,
    Map<String, dynamic>? existingAnalysis,
  }) async {
    final validationResult = {
      'isValid': false,
      'canProceed': false,
      'errors': <String>[],
      'warnings': <String>[],
      'criticalIssues': <String>[],
      'suggestions': <String>[],
      'statistics': <String, dynamic>{},
      'recommendation': '',
    };

    final List<String> errors = validationResult['errors'] as List<String>;
    final List<String> warnings = validationResult['warnings'] as List<String>;
    final List<String> criticalIssues = validationResult['criticalIssues'] as List<String>;
    final List<String> suggestions = validationResult['suggestions'] as List<String>;

    try {
      // 1. Basic Prerequisites
      final prerequisites = await _validatePrerequisites(folderPath, dietitianId);
      if (!(prerequisites['isValid'] as bool)) {
        errors.addAll(prerequisites['errors'] as List<String>);
        criticalIssues.addAll(prerequisites['criticalIssues'] as List<String>);
        return validationResult;
      }

      // 2. Directory Structure Analysis
      Map<String, dynamic> analysis;
      if (existingAnalysis != null) {
        analysis = existingAnalysis;
      } else {
        analysis = await DirectoryParserService.parseDirectory(folderPath);
      }

      if (!(analysis['isValid'] as bool)) {
        errors.addAll(analysis['errors'] as List<String>);
        return validationResult;
      }

      warnings.addAll(analysis['warnings'] as List<String>);

      // 3. File Size and Count Validation
      final fileSizeValidation = await _validateFileSizes(analysis);
      if (!(fileSizeValidation['isValid'] as bool)) {
        errors.addAll(fileSizeValidation['errors'] as List<String>);
      }
      warnings.addAll(fileSizeValidation['warnings'] as List<String>);

      // 4. Content Quality Validation
      final contentValidation = await _validateFileContent(analysis);
      warnings.addAll(contentValidation['warnings'] as List<String>);
      suggestions.addAll(contentValidation['suggestions'] as List<String>);

      // 5. Duplicate Package Check
      final duplicateCheck = await _checkDuplicatePackages(analysis, dietitianId);
      if (!(duplicateCheck['isValid'] as bool)) {
        warnings.addAll(duplicateCheck['warnings'] as List<String>);
      }

      // 6. Storage Space Check
      final storageCheck = await _validateStorageSpace(analysis);
      if (!(storageCheck['isValid'] as bool)) {
        errors.addAll(storageCheck['errors'] as List<String>);
      }
      warnings.addAll(storageCheck['warnings'] as List<String>);

      // 7. System Performance Impact
      final performanceCheck = _validatePerformanceImpact(analysis);
      warnings.addAll(performanceCheck['warnings'] as List<String>);
      suggestions.addAll(performanceCheck['suggestions'] as List<String>);

      // Collect statistics
      validationResult['statistics'] = {
        'totalPackages': analysis['totalPackages'] ?? 0,
        'totalDiets': analysis['totalDiets'] ?? 0,
        'totalFiles': analysis['totalFiles'] ?? 0,
        'estimatedUploadTime': _estimateUploadTime(analysis),
        'estimatedStorageUsage': fileSizeValidation['totalSize'] ?? 0,
        'estimatedStorageUsageReadable': fileSizeValidation['totalSizeReadable'] ?? '0 B',
      };

      // Final validation decision
      final hasBlockingErrors = errors.isNotEmpty;
      final hasCriticalIssues = criticalIssues.isNotEmpty;

      validationResult['isValid'] = !hasBlockingErrors && !hasCriticalIssues;
      validationResult['canProceed'] = validationResult['isValid'] as bool;

      // Add overall recommendation
      validationResult['recommendation'] = _generateRecommendation(validationResult);

      return validationResult;

    } catch (e) {
      criticalIssues.add('Validation system error: $e');
      return validationResult;
    }
  }

  /// Validate basic prerequisites
  static Future<Map<String, dynamic>> _validatePrerequisites(
    String folderPath,
    String dietitianId,
  ) async {
    final errors = <String>[];
    final criticalIssues = <String>[];

    // Check folder existence
    final folder = Directory(folderPath);
    if (!await folder.exists()) {
      criticalIssues.add('Selected folder does not exist: $folderPath');
    }

    // Check folder permissions
    try {
      await folder.list().take(1).toList();
    } catch (e) {
      criticalIssues.add('Cannot access folder contents. Check permissions.');
    }

    // Check dietitian ID
    if (dietitianId.isEmpty) {
      criticalIssues.add('Dietitian ID is required for upload');
    } else {
      // Validate dietitian exists in database
      final dietitian = await DriftService.getUserById(dietitianId);
      if (dietitian == null || !dietitian.isDietitian) {
        errors.add('Invalid dietitian credentials');
      }
    }

    // Check storage system initialization
    try {
      await LocalFileStorageService.initializeStorage();
    } catch (e) {
      criticalIssues.add('Storage system not available: $e');
    }

    return {
      'isValid': errors.isEmpty && criticalIssues.isEmpty,
      'errors': errors,
      'criticalIssues': criticalIssues,
    };
  }

  /// Validate file sizes and counts
  static Future<Map<String, dynamic>> _validateFileSizes(
    Map<String, dynamic> analysis,
  ) async {
    final errors = <String>[];
    final warnings = <String>[];
    final packages = analysis['packages'] as List<Map<String, dynamic>>? ?? [];

    int totalSize = 0;
    int totalFiles = 0;

    for (final package in packages) {
      final diets = package['diets'] as List<Map<String, dynamic>>? ?? [];
      
      if (diets.length > maxDietsPerPackage) {
        errors.add('${package['name']}: Too many diets (${diets.length}), maximum is $maxDietsPerPackage');
      }

      for (final diet in diets) {
        final files = diet['files'] as List<Map<String, dynamic>>? ?? [];
        
        for (final file in files) {
          final fileSize = file['fileSize'] as int? ?? 0;
          totalSize += fileSize;
          totalFiles++;

          if (fileSize > maxFileSize) {
            errors.add('${file['fileName']}: File too large (${LocalFileStorageService.getReadableFileSize(fileSize)}), maximum is ${LocalFileStorageService.getReadableFileSize(maxFileSize)}');
          }

          if (fileSize == 0) {
            warnings.add('${file['fileName']}: File appears to be empty');
          }
        }
      }
    }

    if (totalFiles > maxFilesPerPackage) {
      errors.add('Total files ($totalFiles) exceeds limit ($maxFilesPerPackage)');
    }

    if (totalSize > maxTotalUploadSize) {
      errors.add('Total upload size (${LocalFileStorageService.getReadableFileSize(totalSize)}) exceeds limit (${LocalFileStorageService.getReadableFileSize(maxTotalUploadSize)})');
    }

    if (totalSize > maxTotalUploadSize * 0.8) {
      warnings.add('Upload size is approaching the limit');
    }

    return {
      'isValid': errors.isEmpty,
      'errors': errors,
      'warnings': warnings,
      'totalSize': totalSize,
      'totalSizeReadable': LocalFileStorageService.getReadableFileSize(totalSize),
      'totalFiles': totalFiles,
    };
  }

  /// Validate file content quality
  static Future<Map<String, dynamic>> _validateFileContent(
    Map<String, dynamic> analysis,
  ) async {
    final warnings = <String>[];
    final suggestions = <String>[];
    final packages = analysis['packages'] as List<Map<String, dynamic>>? ?? [];

    for (final package in packages) {
      final diets = package['diets'] as List<Map<String, dynamic>>? ?? [];
      
      // Check BMI coverage
      final allBmiRanges = DirectoryParserService.getValidBmiRanges();
      for (final diet in diets) {
        final bmiRanges = diet['bmiRanges'] as List<String>? ?? [];
        final missingRanges = allBmiRanges.where((range) => !bmiRanges.contains(range)).toList();
        
        if (missingRanges.isNotEmpty) {
          suggestions.add('${diet['name']}: Consider adding files for missing BMI ranges: ${missingRanges.join(', ')}');
        }
      }

      // Check file naming consistency
      bool hasInconsistentNaming = false;
      for (final diet in diets) {
        final files = diet['files'] as List<Map<String, dynamic>>? ?? [];
        final fileNames = files.map((f) => f['fileName'] as String).toList();
        
        // Check if all files follow a consistent naming pattern
        if (fileNames.length > 1) {
          final extensions = fileNames.map((name) => path.extension(name)).toSet();
          if (extensions.length > 1) {
            warnings.add('${diet['name']}: Mixed file extensions found: ${extensions.join(', ')}');
            hasInconsistentNaming = true;
          }
        }
      }

      if (hasInconsistentNaming) {
        suggestions.add('${package['name']}: Consider using consistent file naming conventions');
      }
    }

    return {
      'warnings': warnings,
      'suggestions': suggestions,
    };
  }

  /// Check for duplicate packages
  static Future<Map<String, dynamic>> _checkDuplicatePackages(
    Map<String, dynamic> analysis,
    String dietitianId,
  ) async {
    final warnings = <String>[];
    final packages = analysis['packages'] as List<Map<String, dynamic>>? ?? [];

    try {
      final existingPackages = await DriftService.getDietitianPackages(dietitianId);
      final existingNames = existingPackages.map((p) => p.title.toLowerCase()).toSet();

      for (final package in packages) {
        final packageName = package['name'] as String;
        if (existingNames.contains(packageName.toLowerCase())) {
          warnings.add('Package "$packageName" already exists. Upload will create a new version.');
        }
      }
    } catch (e) {
      warnings.add('Could not check for duplicate packages: $e');
    }

    return {
      'isValid': true,
      'warnings': warnings,
    };
  }

  /// Validate available storage space
  static Future<Map<String, dynamic>> _validateStorageSpace(
    Map<String, dynamic> analysis,
  ) async {
    final errors = <String>[];
    final warnings = <String>[];

    try {
      final storageStats = await LocalFileStorageService.getStorageStats();
      
      if (storageStats['error'] != null) {
        warnings.add('Could not determine storage space: ${storageStats['error']}');
        return {'isValid': true, 'warnings': warnings, 'errors': errors};
      }

      final totalSize = analysis['totalFiles'] as int? ?? 0;
      
      // This is a basic check - in a real implementation you would check actual disk space
      if (totalSize > 50) { // Arbitrary limit for demonstration
        warnings.add('Large number of files may impact device storage');
      }

      if (totalSize > 100) {
        errors.add('Too many files for device storage capacity');
      }

    } catch (e) {
      warnings.add('Storage space validation failed: $e');
    }

    return {
      'isValid': errors.isEmpty,
      'errors': errors,
      'warnings': warnings,
    };
  }

  /// Validate performance impact
  static Map<String, dynamic> _validatePerformanceImpact(
    Map<String, dynamic> analysis,
  ) {
    final warnings = <String>[];
    final suggestions = <String>[];

    final totalFiles = analysis['totalFiles'] as int? ?? 0;
    final totalPackages = analysis['totalPackages'] as int? ?? 0;

    if (totalFiles > 50) {
      warnings.add('Large upload may take significant time to complete');
      suggestions.add('Consider uploading packages in smaller batches');
    }

    if (totalPackages > 5) {
      suggestions.add('Consider organizing similar diets into fewer packages for better management');
    }

    if (totalFiles > 20) {
      suggestions.add('Ensure stable internet connection for large uploads');
    }

    return {
      'warnings': warnings,
      'suggestions': suggestions,
    };
  }

  /// Estimate upload time based on file count and size
  static String _estimateUploadTime(Map<String, dynamic> analysis) {
    final totalFiles = analysis['totalFiles'] as int? ?? 0;
    
    // Rough estimation: 2 seconds per file for processing
    final estimatedSeconds = totalFiles * 2;
    
    if (estimatedSeconds < 60) {
      return '${estimatedSeconds}s';
    } else if (estimatedSeconds < 3600) {
      return '${(estimatedSeconds / 60).ceil()}m';
    } else {
      return '${(estimatedSeconds / 3600).ceil()}h';
    }
  }

  /// Generate overall recommendation
  static String _generateRecommendation(Map<String, dynamic> validationResult) {
    final errors = validationResult['errors'] as List<String>;
    final warnings = validationResult['warnings'] as List<String>;
    final criticalIssues = validationResult['criticalIssues'] as List<String>;

    if (criticalIssues.isNotEmpty) {
      return 'Critical issues must be resolved before upload can proceed.';
    }

    if (errors.isNotEmpty) {
      return 'Please fix ${errors.length} error(s) before uploading.';
    }

    if (warnings.isEmpty) {
      return 'Upload is ready to proceed. All validation checks passed.';
    } else if (warnings.length <= 2) {
      return 'Upload is ready with ${warnings.length} minor warning(s).';
    } else {
      return 'Upload is ready but consider reviewing ${warnings.length} warnings for optimal results.';
    }
  }

  /// Quick validation for immediate feedback
  static Future<Map<String, dynamic>> quickValidation(String folderPath) async {
    try {
      final quickCheck = await DirectoryParserService.quickValidate(folderPath);
      
      if (!quickCheck['isValid']) {
        return {
          'isValid': false,
          'message': quickCheck['error'] ?? 'Invalid folder structure',
          'canProceed': false,
        };
      }

      return {
        'isValid': true,
        'message': 'Folder structure looks good. Click "Analyze" for detailed validation.',
        'canProceed': false, // Still need full analysis
        'preview': quickCheck,
      };

    } catch (e) {
      return {
        'isValid': false,
        'message': 'Validation failed: $e',
        'canProceed': false,
      };
    }
  }

  /// Error recovery suggestions
  static Map<String, List<String>> getErrorRecoverySuggestions() {
    return {
      'folder_not_found': [
        'Ensure the selected folder exists',
        'Check folder permissions',
        'Try selecting a different folder',
      ],
      'invalid_structure': [
        'Review the folder structure requirements',
        'Ensure BMI folders are named correctly (21_25bmi, 26_29bmi, etc.)',
        'Check that DOCX files are in the correct BMI subfolders',
      ],
      'file_too_large': [
        'Compress large DOCX files',
        'Split large files into smaller ones',
        'Remove unnecessary images or content from DOCX files',
      ],
      'storage_full': [
        'Free up device storage space',
        'Clean up old diet files',
        'Consider uploading fewer packages at once',
      ],
      'permission_denied': [
        'Check app storage permissions',
        'Try restarting the app',
        'Select a folder in a different location',
      ],
    };
  }
}