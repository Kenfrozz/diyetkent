import '../models/user_model.dart';
import '../models/diet_package_model.dart';
import '../models/user_diet_assignment_model.dart';
import '../database/drift_service.dart';
import 'diet_file_selection_algorithm.dart';
import 'bmi_calculation_engine.dart';

/// Service for integrating diet file selection with user assignments
class DietAssignmentIntegrationService {
  
  /// Create a new diet assignment with automatic file selection
  static Future<DietAssignmentResult> createAutomaticAssignment({
    required String userId,
    required String packageId,
    required String dietitianId,
    DateTime? startDate,
    Duration? totalDuration,
    Map<String, dynamic>? customSettings,
    String? dietitianNotes,
  }) async {
    try {
      // Get user and package information
      final user = await DriftService.getUserById(userId);
      final package = await DriftService.getDietPackage(packageId);
      
      if (user == null) {
        return DietAssignmentResult.error('Kullanıcı bulunamadı');
      }
      
      if (package == null) {
        return DietAssignmentResult.error('Diyet paketi bulunamadı');
      }
      
      // Validate user data for BMI calculation
      final validationResult = BMICalculationEngine.validateUserDataForBMI(user);
      if (!validationResult.isValid) {
        return DietAssignmentResult.error(
          'Kullanıcı verileri eksik: ${validationResult.errors.join(', ')}'
        );
      }
      
      // Check if user already has an active assignment
      final existingAssignment = await DriftService.getUserActiveAssignment(userId);
      if (existingAssignment != null) {
        return DietAssignmentResult.error(
          'Kullanıcı zaten aktif bir diyet atamasına sahip',
          existingAssignmentId: existingAssignment.assignmentId,
        );
      }
      
      // Calculate assignment dates
      final assignmentStartDate = startDate ?? DateTime.now();
      final assignmentDuration = totalDuration ?? Duration(days: package.durationDays);
      final assignmentEndDate = assignmentStartDate.add(assignmentDuration);
      
      // Select diet files using our algorithm
      final selectionResult = await DietFileSelectionAlgorithm.selectDietFilesForUser(
        user: user,
        package: package,
        fileSequenceNumber: 1, // Start with first sequence
        startDate: assignmentStartDate,
      );
      
      if (!selectionResult.isSuccess) {
        return DietAssignmentResult.error(
          'Uygun diyet dosyası bulunamadı: ${selectionResult.error}'
        );
      }
      
      // Calculate target weight based on BMI analysis
      final bmiAnalysis = selectionResult.bmiAnalysis!;
      final targetWeight = await _calculateTargetWeight(user, bmiAnalysis, package);
      
      // Create assignment
      final assignmentId = 'assignment_${DateTime.now().millisecondsSinceEpoch}';
      final assignment = UserDietAssignmentModel.create(
        assignmentId: assignmentId,
        userId: userId,
        packageId: packageId,
        dietitianId: dietitianId,
        startDate: assignmentStartDate,
        endDate: assignmentEndDate,
        customSettings: customSettings != null ? 
          _encodeCustomSettings(customSettings) : '{}',
        dietitianNotes: dietitianNotes,
        weightStart: user.currentWeight ?? 0.0,
        weightCurrent: user.currentWeight ?? 0.0,
        weightTarget: targetWeight,
      );
      
      // Save assignment to database
      await DriftService.saveUserDietAssignment(assignment);
      
      return DietAssignmentResult.success(
        assignment: assignment,
        selectionResult: selectionResult,
        bmiAnalysis: bmiAnalysis,
        targetWeight: targetWeight,
      );
      
    } catch (e) {
      return DietAssignmentResult.error('Atama oluşturma hatası: $e');
    }
  }
  
  /// Get next diet file sequence for an existing assignment
  static Future<DietFileSequenceResult> getNextDietSequence({
    required String assignmentId,
    required int nextSequenceNumber,
  }) async {
    try {
      final assignment = await _getAssignmentById(assignmentId);
      if (assignment == null) {
        return DietFileSequenceResult.error('Atama bulunamadı');
      }
      
      if (!assignment.isActive) {
        return DietFileSequenceResult.error('Atama aktif değil');
      }
      
      final user = await DriftService.getUserById(assignment.userId);
      final package = await DriftService.getDietPackage(assignment.packageId);
      
      if (user == null || package == null) {
        return DietFileSequenceResult.error('Kullanıcı veya paket bulunamadı');
      }
      
      // Calculate next sequence start date
      final sequenceStartDate = assignment.startDate.add(
        Duration(days: (nextSequenceNumber - 1) * package.daysPerFile)
      );
      
      // Select files for next sequence
      final selectionResult = await DietFileSelectionAlgorithm.selectDietFilesForUser(
        user: user,
        package: package,
        fileSequenceNumber: nextSequenceNumber,
        startDate: sequenceStartDate,
      );
      
      if (!selectionResult.isSuccess) {
        return DietFileSequenceResult.error(
          'Sonraki sıra için dosya bulunamadı: ${selectionResult.error}'
        );
      }
      
      return DietFileSequenceResult.success(
        sequenceNumber: nextSequenceNumber,
        selectionResult: selectionResult,
        startDate: sequenceStartDate,
        assignment: assignment,
      );
      
    } catch (e) {
      return DietFileSequenceResult.error('Sıra alma hatası: $e');
    }
  }
  
  /// Preview all sequences for an assignment
  static Future<AssignmentPreviewResult> previewAssignmentSequences({
    required String userId,
    required String packageId,
    DateTime? startDate,
    int maxSequences = 5,
  }) async {
    try {
      final user = await DriftService.getUserById(userId);
      final package = await DriftService.getDietPackage(packageId);
      
      if (user == null || package == null) {
        return AssignmentPreviewResult.error('Kullanıcı veya paket bulunamadı');
      }
      
      // Get comprehensive preview from the selection algorithm
      final preview = await DietFileSelectionAlgorithm.previewDietFileSelection(
        user: user,
        package: package,
        maxSequences: maxSequences,
      );
      
      if (!preview.isValid) {
        return AssignmentPreviewResult.error(preview.error ?? 'Önizleme oluşturulamadı');
      }
      
      return AssignmentPreviewResult.success(
        user: user,
        package: package,
        preview: preview,
        totalDuration: preview.totalDuration,
        expectedWeightChange: preview.totalExpectedWeightChange,
      );
      
    } catch (e) {
      return AssignmentPreviewResult.error('Önizleme hatası: $e');
    }
  }
  
  /// Update assignment with progress and measurements
  static Future<bool> updateAssignmentProgress({
    required String assignmentId,
    double? currentWeight,
    int? completedDays,
    int? adherenceScore,
    int? missedDays,
    String? userNotes,
    DateTime? lastActivityAt,
  }) async {
    try {
      final assignment = await _getAssignmentById(assignmentId);
      if (assignment == null) return false;
      
      // Update fields
      if (currentWeight != null) assignment.weightCurrent = currentWeight;
      if (completedDays != null) assignment.completedDays = completedDays;
      if (adherenceScore != null) assignment.adherenceScore = adherenceScore;
      if (missedDays != null) assignment.missedDays = missedDays;
      if (userNotes != null) assignment.userNotes = userNotes;
      if (lastActivityAt != null) assignment.lastActivityAt = lastActivityAt;
      
      assignment.updatedAt = DateTime.now();
      
      // Progress is calculated automatically in the model
      
      await DriftService.saveUserDietAssignment(assignment);
      return true;
      
    } catch (e) {
      return false;
    }
  }
  
  /// Get compatible packages for a user with BMI analysis
  static Future<List<CompatiblePackage>> getCompatiblePackagesForUser(
    String userId,
    String dietitianId,
  ) async {
    try {
      final user = await DriftService.getUserById(userId);
      if (user == null) return [];
      
      // Get compatible packages from the selection algorithm
      final packages = await DietFileSelectionAlgorithm.getCompatiblePackagesForUser(
        user,
        dietitianId,
      );
      
      final compatiblePackages = <CompatiblePackage>[];
      
      for (final package in packages) {
        // Check if we can select files for this package
        final validationResult = DietFileSelectionAlgorithm.validateSelectionInputs(
          user: user,
          package: package,
        );
        
        // Get preview for this package
        final preview = await DietFileSelectionAlgorithm.previewDietFileSelection(
          user: user,
          package: package,
          maxSequences: 3,
        );
        
        compatiblePackages.add(CompatiblePackage(
          package: package,
          isCompatible: validationResult.isValid,
          validationErrors: validationResult.errors,
          validationWarnings: validationResult.warnings,
          availableSequences: preview.sequences.length,
          estimatedDuration: preview.isValid ? preview.totalDuration : 0,
          expectedWeightChange: preview.isValid ? preview.totalExpectedWeightChange : 0.0,
        ));
      }
      
      // Sort by compatibility and expected results
      compatiblePackages.sort((a, b) {
        if (a.isCompatible && !b.isCompatible) return -1;
        if (!a.isCompatible && b.isCompatible) return 1;
        return b.availableSequences.compareTo(a.availableSequences);
      });
      
      return compatiblePackages;
      
    } catch (e) {
      return [];
    }
  }
  
  /// Calculate target weight based on BMI analysis and package goals
  static Future<double> _calculateTargetWeight(
    UserModel user,
    BMIAnalysisResult bmiAnalysis,
    DietPackageModel package,
  ) async {
    if (user.currentWeight == null) return 0.0;
    
    final currentWeight = user.currentWeight!;
    final idealWeight = bmiAnalysis.idealWeight ?? currentWeight;
    
    // Calculate expected total weight change for the package
    final totalSequences = package.numberOfFiles;
    final totalExpectedChange = totalSequences * package.targetWeightChangePerFile;
    
    // Target weight is current weight plus expected change, but not below ideal weight
    final targetWeight = currentWeight + totalExpectedChange;
    
    // Ensure target doesn't go below healthy range
    if (totalExpectedChange < 0 && targetWeight < idealWeight) {
      return idealWeight;
    }
    
    return targetWeight;
  }
  
  /// Get assignment by ID from database
  static Future<UserDietAssignmentModel?> _getAssignmentById(String assignmentId) async {
    final assignments = await DriftService.getAllActiveAssignments();
    return assignments.where((a) => a.assignmentId == assignmentId).firstOrNull;
  }
  
  /// Encode custom settings to JSON string
  static String _encodeCustomSettings(Map<String, dynamic> settings) {
    try {
      return settings.toString(); // Simple toString for now, could use json.encode
    } catch (e) {
      return '{}';
    }
  }
}

/// Result of automatic diet assignment creation
class DietAssignmentResult {
  final bool isSuccess;
  final UserDietAssignmentModel? assignment;
  final DietFileSelectionResult? selectionResult;
  final BMIAnalysisResult? bmiAnalysis;
  final double? targetWeight;
  final String? error;
  final String? existingAssignmentId;

  DietAssignmentResult._({
    required this.isSuccess,
    this.assignment,
    this.selectionResult,
    this.bmiAnalysis,
    this.targetWeight,
    this.error,
    this.existingAssignmentId,
  });

  factory DietAssignmentResult.success({
    required UserDietAssignmentModel assignment,
    required DietFileSelectionResult selectionResult,
    required BMIAnalysisResult bmiAnalysis,
    required double targetWeight,
  }) {
    return DietAssignmentResult._(
      isSuccess: true,
      assignment: assignment,
      selectionResult: selectionResult,
      bmiAnalysis: bmiAnalysis,
      targetWeight: targetWeight,
    );
  }

  factory DietAssignmentResult.error(String error, {String? existingAssignmentId}) {
    return DietAssignmentResult._(
      isSuccess: false,
      error: error,
      existingAssignmentId: existingAssignmentId,
    );
  }
}

/// Result of diet file sequence selection
class DietFileSequenceResult {
  final bool isSuccess;
  final int? sequenceNumber;
  final DietFileSelectionResult? selectionResult;
  final DateTime? startDate;
  final UserDietAssignmentModel? assignment;
  final String? error;

  DietFileSequenceResult._({
    required this.isSuccess,
    this.sequenceNumber,
    this.selectionResult,
    this.startDate,
    this.assignment,
    this.error,
  });

  factory DietFileSequenceResult.success({
    required int sequenceNumber,
    required DietFileSelectionResult selectionResult,
    required DateTime startDate,
    required UserDietAssignmentModel assignment,
  }) {
    return DietFileSequenceResult._(
      isSuccess: true,
      sequenceNumber: sequenceNumber,
      selectionResult: selectionResult,
      startDate: startDate,
      assignment: assignment,
    );
  }

  factory DietFileSequenceResult.error(String error) {
    return DietFileSequenceResult._(
      isSuccess: false,
      error: error,
    );
  }
}

/// Result of assignment preview
class AssignmentPreviewResult {
  final bool isSuccess;
  final UserModel? user;
  final DietPackageModel? package;
  final DietFileSelectionPreview? preview;
  final int? totalDuration;
  final double? expectedWeightChange;
  final String? error;

  AssignmentPreviewResult._({
    required this.isSuccess,
    this.user,
    this.package,
    this.preview,
    this.totalDuration,
    this.expectedWeightChange,
    this.error,
  });

  factory AssignmentPreviewResult.success({
    required UserModel user,
    required DietPackageModel package,
    required DietFileSelectionPreview preview,
    required int totalDuration,
    required double expectedWeightChange,
  }) {
    return AssignmentPreviewResult._(
      isSuccess: true,
      user: user,
      package: package,
      preview: preview,
      totalDuration: totalDuration,
      expectedWeightChange: expectedWeightChange,
    );
  }

  factory AssignmentPreviewResult.error(String error) {
    return AssignmentPreviewResult._(
      isSuccess: false,
      error: error,
    );
  }
}

/// Compatible package with analysis
class CompatiblePackage {
  final DietPackageModel package;
  final bool isCompatible;
  final List<String> validationErrors;
  final List<String> validationWarnings;
  final int availableSequences;
  final int estimatedDuration;
  final double expectedWeightChange;

  CompatiblePackage({
    required this.package,
    required this.isCompatible,
    required this.validationErrors,
    required this.validationWarnings,
    required this.availableSequences,
    required this.estimatedDuration,
    required this.expectedWeightChange,
  });

  /// Get compatibility score (0-100)
  int get compatibilityScore {
    if (!isCompatible) return 0;
    
    int score = 50; // Base score
    score += availableSequences * 10; // More sequences = better
    score -= validationWarnings.length * 5; // Warnings reduce score
    
    return score.clamp(0, 100);
  }

  /// Get display summary
  String get compatibilitySummary {
    if (!isCompatible) {
      return 'Uyumlu değil: ${validationErrors.join(', ')}';
    }
    
    final warnings = validationWarnings.isNotEmpty 
        ? ' (${validationWarnings.length} uyarı)' 
        : '';
    
    return 'Uyumlu: $availableSequences sıra mevcut$warnings';
  }
}