import '../models/user_model.dart';
import '../models/diet_package_model.dart';
import '../models/diet_file_model.dart';
import '../models/user_role_model.dart';
import '../database/drift_service.dart';
import 'bmi_calculation_engine.dart';

/// Algorithm for selecting appropriate diet files based on user profile and package parameters
class DietFileSelectionAlgorithm {
  
  /// Select appropriate diet files for a user from a specific package
  static Future<DietFileSelectionResult> selectDietFilesForUser({
    required UserModel user,
    required DietPackageModel package,
    int? fileSequenceNumber,
    DateTime? startDate,
  }) async {
    try {
      // Analyze user BMI
      final bmiAnalysis = BMICalculationEngine.analyzeBMI(user);
      if (!bmiAnalysis.isValid) {
        return DietFileSelectionResult.error(
          'Kullanıcı BMI analizi başarısız: ${bmiAnalysis.errors.join(', ')}',
          bmiAnalysis.errors,
          bmiAnalysis.warnings,
        );
      }

      final targetBMIRange = bmiAnalysis.bmiRangeForDiet;
      if (targetBMIRange == null) {
        return DietFileSelectionResult.error(
          'BMI aralığı belirlenemedi',
          ['BMI değeri geçersiz: ${bmiAnalysis.formattedBMI}'],
        );
      }

      // Get available diet files for this package
      final availableFiles = await _getPackageDietFiles(package.packageId);
      if (availableFiles.isEmpty) {
        return DietFileSelectionResult.error(
          'Paket için diyet dosyası bulunamadı',
          ['Paket ID: ${package.packageId}'],
        );
      }

      // Filter files by BMI range
      final compatibleFiles = availableFiles.where((file) {
        final fileTags = file.tags;
        return fileTags.contains(targetBMIRange);
      }).toList();

      if (compatibleFiles.isEmpty) {
        return DietFileSelectionResult.error(
          'BMI aralığı için uygun dosya bulunamadı',
          ['Aranan BMI aralığı: $targetBMIRange', 'Mevcut dosya sayısı: ${availableFiles.length}'],
        );
      }

      // Apply selection strategy based on package parameters
      final selectedFiles = await _applySelectionStrategy(
        availableFiles: compatibleFiles,
        package: package,
        user: user,
        fileSequenceNumber: fileSequenceNumber,
        startDate: startDate ?? DateTime.now(),
      );

      return DietFileSelectionResult.success(
        selectedFiles: selectedFiles,
        bmiAnalysis: bmiAnalysis,
        targetBMIRange: targetBMIRange,
        totalAvailableFiles: availableFiles.length,
        compatibleFiles: compatibleFiles.length,
      );

    } catch (e) {
      return DietFileSelectionResult.error(
        'Diyet dosyası seçimi sırasında hata: $e',
        ['Sistem hatası: $e'],
      );
    }
  }

  /// Get all diet files associated with a package
  static Future<List<DietFileModel>> _getPackageDietFiles(String packageId) async {
    // Get all diet files and filter by package
    // Note: This might need optimization with a proper package-file relation in the future
    final allFiles = await DriftService.getAllDietFiles(); // Assuming this method exists
    return allFiles.where((file) {
      final tags = file.tags;
      return tags.any((tag) => tag.contains(packageId.toLowerCase()));
    }).toList();
  }

  /// Apply selection strategy based on package configuration
  static Future<List<SelectedDietFile>> _applySelectionStrategy({
    required List<DietFileModel> availableFiles,
    required DietPackageModel package,
    required UserModel user,
    int? fileSequenceNumber,
    required DateTime startDate,
  }) async {
    final selectedFiles = <SelectedDietFile>[];
    
    // Determine how many files to select based on sequence
    final sequenceNumber = fileSequenceNumber ?? 1;
    final filesToSelect = _calculateFilesToSelect(package, sequenceNumber);
    
    if (filesToSelect <= 0) {
      return selectedFiles;
    }

    // Sort available files by preference
    final sortedFiles = _sortFilesByPreference(availableFiles, user);
    
    // Select the required number of files
    final selectedFileModels = sortedFiles.take(filesToSelect).toList();
    
    // Convert to SelectedDietFile with scheduling information
    for (int i = 0; i < selectedFileModels.length; i++) {
      final file = selectedFileModels[i];
      final scheduleInfo = _calculateScheduleInfo(
        package: package,
        fileIndex: i,
        sequenceNumber: sequenceNumber,
        startDate: startDate,
      );

      selectedFiles.add(SelectedDietFile(
        dietFile: file,
        scheduleInfo: scheduleInfo,
        selectionReason: _getSelectionReason(file, user, i),
        priority: i + 1,
      ));
    }

    return selectedFiles;
  }

  /// Calculate how many files to select for the current sequence
  static int _calculateFilesToSelect(DietPackageModel package, int sequenceNumber) {
    // For most packages, select 1 file per sequence
    // This could be made more sophisticated based on package type
    if (sequenceNumber <= package.numberOfFiles) {
      return 1;
    }
    return 0; // No more files available for this sequence
  }

  /// Sort available files by preference for the user
  static List<DietFileModel> _sortFilesByPreference(
    List<DietFileModel> files,
    UserModel user,
  ) {
    // Create a copy and sort by multiple criteria
    final sortedFiles = List<DietFileModel>.from(files);
    
    sortedFiles.sort((a, b) {
      // Priority 1: Prefer files with more recent creation dates (newer diets)
      int dateComparison = b.createdAt.compareTo(a.createdAt);
      if (dateComparison != 0) return dateComparison;
      
      // Priority 2: Prefer files with larger size (more content)
      int sizeComparison = (b.fileSize ?? 0).compareTo(a.fileSize ?? 0);
      if (sizeComparison != 0) return sizeComparison;
      
      // Priority 3: Alphabetical by name for consistency
      return (a.fileName ?? '').compareTo(b.fileName ?? '');
    });
    
    return sortedFiles;
  }

  /// Calculate schedule information for a selected file
  static DietFileScheduleInfo _calculateScheduleInfo({
    required DietPackageModel package,
    required int fileIndex,
    required int sequenceNumber,
    required DateTime startDate,
  }) {
    // Calculate start date for this specific file
    final daysOffset = (sequenceNumber - 1) * package.daysPerFile;
    final fileStartDate = startDate.add(Duration(days: daysOffset));
    final fileEndDate = fileStartDate.add(Duration(days: package.daysPerFile - 1));
    
    // Calculate control date (typically a few days after end date)
    final controlDate = fileEndDate.add(const Duration(days: 3));
    
    return DietFileScheduleInfo(
      startDate: fileStartDate,
      endDate: fileEndDate,
      controlDate: controlDate,
      duration: package.daysPerFile,
      sequenceNumber: sequenceNumber,
      expectedWeightChange: package.targetWeightChangePerFile,
    );
  }

  /// Get reason for why this file was selected
  static String _getSelectionReason(DietFileModel file, UserModel user, int index) {
    final reasons = <String>[];
    
    // BMI compatibility
    final bmiAnalysis = BMICalculationEngine.analyzeBMI(user);
    if (bmiAnalysis.isValid && bmiAnalysis.bmiRangeForDiet != null) {
      reasons.add('BMI aralığı uyumlu (${bmiAnalysis.bmiRangeForDiet})');
    }
    
    // File recency
    final daysSinceCreation = DateTime.now().difference(file.createdAt).inDays;
    if (daysSinceCreation < 30) {
      reasons.add('Güncel diyet dosyası');
    }
    
    // Selection order
    if (index == 0) {
      reasons.add('En uygun seçenek');
    } else {
      reasons.add('Alternatif seçenek #${index + 1}');
    }
    
    return reasons.join(', ');
  }

  /// Get available diet packages for a user based on their profile
  static Future<List<DietPackageModel>> getCompatiblePackagesForUser(
    UserModel user,
    String dietitianId,
  ) async {
    try {
      // Get all packages from the dietitian
      final allPackages = await DriftService.getDietitianPackages(dietitianId);
      
      // Filter active packages only
      final activePackages = allPackages.where((pkg) => pkg.isActive).toList();
      
      // Analyze user BMI to determine compatibility
      final bmiAnalysis = BMICalculationEngine.analyzeBMI(user);
      if (!bmiAnalysis.isValid) {
        return activePackages; // Return all if BMI analysis fails
      }
      
      // For now, return all active packages
      // Could add more sophisticated filtering based on package type, user goals, etc.
      return activePackages;
      
    } catch (e) {
      return [];
    }
  }

  /// Preview diet file selection without creating assignments
  static Future<DietFileSelectionPreview> previewDietFileSelection({
    required UserModel user,
    required DietPackageModel package,
    int maxSequences = 3,
  }) async {
    final preview = DietFileSelectionPreview(
      user: user,
      package: package,
      sequences: [],
    );

    try {
      for (int i = 1; i <= maxSequences && i <= package.numberOfFiles; i++) {
        final selectionResult = await selectDietFilesForUser(
          user: user,
          package: package,
          fileSequenceNumber: i,
          startDate: DateTime.now(),
        );

        if (selectionResult.isSuccess) {
          preview.sequences.add(DietSequencePreview(
            sequenceNumber: i,
            selectedFiles: selectionResult.selectedFiles,
            startDate: selectionResult.selectedFiles.isNotEmpty 
                ? selectionResult.selectedFiles.first.scheduleInfo.startDate
                : DateTime.now(),
            duration: package.daysPerFile,
          ));
        }
      }

      preview.isValid = preview.sequences.isNotEmpty;
      return preview;

    } catch (e) {
      preview.error = 'Preview oluşturma hatası: $e';
      return preview;
    }
  }

  /// Validate selection algorithm inputs
  static SelectionValidationResult validateSelectionInputs({
    required UserModel user,
    required DietPackageModel package,
  }) {
    final errors = <String>[];
    final warnings = <String>[];

    // Validate user data
    final bmiValidation = BMICalculationEngine.validateUserDataForBMI(user);
    errors.addAll(bmiValidation.errors);
    warnings.addAll(bmiValidation.warnings);

    // Validate package data
    if (!package.isActive) {
      errors.add('Diyet paketi aktif değil');
    }

    if (package.numberOfFiles <= 0) {
      errors.add('Pakette dosya sayısı geçersiz');
    }

    if (package.daysPerFile <= 0) {
      errors.add('Dosya başına gün sayısı geçersiz');
    }

    // Check if user has required role permissions
    if (user.userRole == UserRoleType.admin || user.userRole == UserRoleType.dietitian) {
      warnings.add('Yönetici hesabı için diyet ataması yapılıyor');
    }

    return SelectionValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }
}

/// Result of diet file selection process
class DietFileSelectionResult {
  final bool isSuccess;
  final List<SelectedDietFile> selectedFiles;
  final BMIAnalysisResult? bmiAnalysis;
  final String? targetBMIRange;
  final int totalAvailableFiles;
  final int compatibleFiles;
  final String? error;
  final List<String> errors;
  final List<String> warnings;

  DietFileSelectionResult._({
    required this.isSuccess,
    this.selectedFiles = const [],
    this.bmiAnalysis,
    this.targetBMIRange,
    this.totalAvailableFiles = 0,
    this.compatibleFiles = 0,
    this.error,
    this.errors = const [],
    this.warnings = const [],
  });

  factory DietFileSelectionResult.success({
    required List<SelectedDietFile> selectedFiles,
    BMIAnalysisResult? bmiAnalysis,
    String? targetBMIRange,
    int totalAvailableFiles = 0,
    int compatibleFiles = 0,
    List<String> warnings = const [],
  }) {
    return DietFileSelectionResult._(
      isSuccess: true,
      selectedFiles: selectedFiles,
      bmiAnalysis: bmiAnalysis,
      targetBMIRange: targetBMIRange,
      totalAvailableFiles: totalAvailableFiles,
      compatibleFiles: compatibleFiles,
      warnings: warnings,
    );
  }

  factory DietFileSelectionResult.error(
    String error,
    List<String> errors, [
    List<String> warnings = const [],
  ]) {
    return DietFileSelectionResult._(
      isSuccess: false,
      error: error,
      errors: errors,
      warnings: warnings,
    );
  }
}

/// Selected diet file with additional metadata
class SelectedDietFile {
  final DietFileModel dietFile;
  final DietFileScheduleInfo scheduleInfo;
  final String selectionReason;
  final int priority;

  SelectedDietFile({
    required this.dietFile,
    required this.scheduleInfo,
    required this.selectionReason,
    required this.priority,
  });
}

/// Schedule information for a diet file
class DietFileScheduleInfo {
  final DateTime startDate;
  final DateTime endDate;
  final DateTime controlDate;
  final int duration;
  final int sequenceNumber;
  final double expectedWeightChange;

  DietFileScheduleInfo({
    required this.startDate,
    required this.endDate,
    required this.controlDate,
    required this.duration,
    required this.sequenceNumber,
    required this.expectedWeightChange,
  });

  String get formattedDateRange {
    return '${startDate.day}/${startDate.month}/${startDate.year} - ${endDate.day}/${endDate.month}/${endDate.year}';
  }

  String get formattedDuration {
    if (duration == 7) return '1 hafta';
    return '$duration gün';
  }

  String get formattedWeightChange {
    if (expectedWeightChange > 0) {
      return '+${expectedWeightChange.toStringAsFixed(1)} kg';
    } else if (expectedWeightChange < 0) {
      return '${expectedWeightChange.toStringAsFixed(1)} kg';
    } else {
      return 'Koruma';
    }
  }
}

/// Preview of diet file selection for multiple sequences
class DietFileSelectionPreview {
  final UserModel user;
  final DietPackageModel package;
  final List<DietSequencePreview> sequences;
  bool isValid = false;
  String? error;

  DietFileSelectionPreview({
    required this.user,
    required this.package,
    required this.sequences,
  });

  int get totalDuration {
    return sequences.fold(0, (sum, seq) => sum + seq.duration);
  }

  double get totalExpectedWeightChange {
    return sequences.fold(0.0, (sum, seq) => sum + package.targetWeightChangePerFile);
  }
}

/// Preview of a single diet sequence
class DietSequencePreview {
  final int sequenceNumber;
  final List<SelectedDietFile> selectedFiles;
  final DateTime startDate;
  final int duration;

  DietSequencePreview({
    required this.sequenceNumber,
    required this.selectedFiles,
    required this.startDate,
    required this.duration,
  });

  DateTime get endDate => startDate.add(Duration(days: duration - 1));
}

/// Validation result for selection algorithm inputs
class SelectionValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  SelectionValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });
}