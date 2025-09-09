import 'dart:async';
import '../models/diet_package_model.dart';
import '../models/user_diet_assignment_model.dart';
import '../database/drift_service.dart';
import 'bmi_calculation_engine.dart';
import 'diet_file_selection_algorithm.dart';
import 'diet_assignment_integration_service.dart';
import 'sequential_assignment_scheduler.dart';

/// Main engine for automated diet file assignment system
/// Coordinates all components and provides unified API for diet management
class DietAssignmentEngine {
  
  // Singleton pattern for global access
  static final DietAssignmentEngine _instance = DietAssignmentEngine._internal();
  factory DietAssignmentEngine() => _instance;
  DietAssignmentEngine._internal();
  
  Timer? _schedulerTimer;
  bool _isInitialized = false;
  
  /// Initialize the assignment engine with automatic scheduling
  Future<void> initialize({
    Duration schedulerInterval = const Duration(hours: 1),
    bool enableAutoScheduling = true,
  }) async {
    if (_isInitialized) return;
    
    try {
      // Isar zaten başlatıldıysa tekrar başlatmaya çalışma
      // await DriftService.initialize(); // Bu satırı kaldırıyoruz
      
      // Start automatic scheduler if enabled
      if (enableAutoScheduling) {
        await startAutomaticScheduler(schedulerInterval);
      }
      
      _isInitialized = true;
      
    } catch (e) {
      throw Exception('Diet Assignment Engine başlatılamadı: $e');
    }
  }
  
  /// Start automatic scheduler for processing assignments
  Future<void> startAutomaticScheduler(Duration interval) async {
    await stopAutomaticScheduler(); // Stop existing timer if any
    
    _schedulerTimer = Timer.periodic(interval, (timer) async {
      await _runSchedulerCycle();
    });
  }
  
  /// Stop automatic scheduler
  Future<void> stopAutomaticScheduler() async {
    _schedulerTimer?.cancel();
    _schedulerTimer = null;
  }
  
  /// Create automatic diet assignment for a user
  Future<DietAssignmentEngineResult> createAssignment({
    required String userId,
    required String dietitianId,
    String? packageId,
    DateTime? startDate,
    Duration? totalDuration,
    Map<String, dynamic>? customSettings,
    String? dietitianNotes,
    bool allowMultipleActive = false,
  }) async {
    try {
      _ensureInitialized();
      
      // If no package specified, find best compatible package
      String targetPackageId;
      if (packageId != null) {
        targetPackageId = packageId;
      } else {
        final bestPackage = await findBestPackageForUser(userId, dietitianId);
        if (!bestPackage.isSuccess || bestPackage.package == null) {
          return DietAssignmentEngineResult.error(
            'Kullanıcı için uygun paket bulunamadı: ${bestPackage.error}'
          );
        }
        targetPackageId = bestPackage.package!.packageId;
      }
      
      // Check for existing active assignments
      if (!allowMultipleActive) {
        final existingAssignment = await DriftService.getUserActiveAssignment(userId);
        if (existingAssignment != null) {
          return DietAssignmentEngineResult.error(
            'Kullanıcının zaten aktif ataması var: ${existingAssignment.assignmentId}',
            existingAssignmentId: existingAssignment.assignmentId,
          );
        }
      }
      
      // Create assignment using integration service
      final assignmentResult = await DietAssignmentIntegrationService.createAutomaticAssignment(
        userId: userId,
        packageId: targetPackageId,
        dietitianId: dietitianId,
        startDate: startDate,
        totalDuration: totalDuration,
        customSettings: customSettings,
        dietitianNotes: dietitianNotes,
      );
      
      if (!assignmentResult.isSuccess) {
        return DietAssignmentEngineResult.error(assignmentResult.error!);
      }
      
      return DietAssignmentEngineResult.success(
        assignment: assignmentResult.assignment!,
        message: 'Otomatik diyet ataması başarıyla oluşturuldu',
        bmiAnalysis: assignmentResult.bmiAnalysis,
        selectedFiles: assignmentResult.selectionResult?.selectedFiles ?? [],
      );
      
    } catch (e) {
      return DietAssignmentEngineResult.error('Atama oluşturma hatası: $e');
    }
  }
  
  /// Find the best diet package for a user
  Future<BestPackageResult> findBestPackageForUser(String userId, String dietitianId) async {
    try {
      _ensureInitialized();
      
      final user = await DriftService.getUserById(userId);
      if (user == null) {
        return BestPackageResult.error('Kullanıcı bulunamadı');
      }
      
      // Get compatible packages with analysis
      final compatiblePackages = await DietAssignmentIntegrationService.getCompatiblePackagesForUser(
        userId,
        dietitianId,
      );
      
      if (compatiblePackages.isEmpty) {
        return BestPackageResult.error('Uyumlu paket bulunamadı');
      }
      
      // Sort by compatibility score and select the best
      compatiblePackages.sort((a, b) => b.compatibilityScore.compareTo(a.compatibilityScore));
      final bestPackage = compatiblePackages.first;
      
      if (!bestPackage.isCompatible) {
        return BestPackageResult.error(
          'En iyi paket bile uyumlu değil: ${bestPackage.validationErrors.join(', ')}'
        );
      }
      
      return BestPackageResult.success(
        package: bestPackage.package,
        compatibilityScore: bestPackage.compatibilityScore,
        availableSequences: bestPackage.availableSequences,
        estimatedDuration: bestPackage.estimatedDuration,
        expectedWeightChange: bestPackage.expectedWeightChange,
        allOptions: compatiblePackages,
      );
      
    } catch (e) {
      return BestPackageResult.error('Paket arama hatası: $e');
    }
  }
  
  /// Get user's assignment status and progress
  Future<AssignmentStatusResult> getUserAssignmentStatus(String userId) async {
    try {
      _ensureInitialized();
      
      final activeAssignment = await DriftService.getUserActiveAssignment(userId);
      if (activeAssignment == null) {
        return AssignmentStatusResult.noAssignment('Kullanıcının aktif ataması yok');
      }
      
      // Get detailed schedule
      final schedule = await SequentialAssignmentScheduler.getAssignmentSchedule(
        activeAssignment.assignmentId
      );
      
      // Get user BMI analysis
      final user = await DriftService.getUserById(userId);
      BMIAnalysisResult? bmiAnalysis;
      if (user != null) {
        bmiAnalysis = BMICalculationEngine.analyzeBMI(user);
      }
      
      return AssignmentStatusResult.active(
        assignment: activeAssignment,
        schedule: schedule,
        bmiAnalysis: bmiAnalysis,
        nextAction: _determineNextAction(activeAssignment, schedule),
      );
      
    } catch (e) {
      return AssignmentStatusResult.error('Durum alma hatası: $e');
    }
  }
  
  /// Process next diet sequence for a user
  Future<SequenceTransitionResult> processNextSequence(String userId, {bool forceTransition = false}) async {
    try {
      _ensureInitialized();
      
      final activeAssignment = await DriftService.getUserActiveAssignment(userId);
      if (activeAssignment == null) {
        return SequenceTransitionResult.error('Aktif atama bulunamadı');
      }
      
      // Schedule next sequence
      final scheduleResult = await SequentialAssignmentScheduler.scheduleNextSequence(
        assignmentId: activeAssignment.assignmentId,
        forceTransition: forceTransition,
      );
      
      if (!scheduleResult.isSuccess) {
        return SequenceTransitionResult.error(scheduleResult.error ?? 'Dizi geçişi başarısız');
      }
      
      return SequenceTransitionResult.success(
        sequenceNumber: scheduleResult.sequenceNumber!,
        startDate: scheduleResult.startDate!,
        endDate: scheduleResult.endDate!,
        selectedFiles: scheduleResult.selectionResult?.selectedFiles ?? [],
        assignmentId: activeAssignment.assignmentId,
      );
      
    } catch (e) {
      return SequenceTransitionResult.error('Dizi işleme hatası: $e');
    }
  }
  
  /// Update user progress and measurements
  Future<bool> updateUserProgress({
    required String userId,
    double? currentWeight,
    int? adherenceScore,
    String? userNotes,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      _ensureInitialized();
      
      final activeAssignment = await DriftService.getUserActiveAssignment(userId);
      if (activeAssignment == null) return false;
      
      // Update assignment progress
      final success = await DietAssignmentIntegrationService.updateAssignmentProgress(
        assignmentId: activeAssignment.assignmentId,
        currentWeight: currentWeight,
        adherenceScore: adherenceScore,
        userNotes: userNotes,
        lastActivityAt: DateTime.now(),
      );
      
      // If weight updated, also update user model
      if (success && currentWeight != null) {
        final user = await DriftService.getUserById(userId);
        if (user != null) {
          user.currentWeight = currentWeight;
          user.updatedAt = DateTime.now();
          await DriftService.saveUser(user);
        }
      }
      
      return success;
      
    } catch (e) {
      return false;
    }
  }
  
  /// Get analytics and statistics for dietitian
  Future<DietitianAnalytics> getDietitianAnalytics(String dietitianId) async {
    try {
      _ensureInitialized();
      
      final assignments = await DriftService.getDietitianAssignments(dietitianId);
      final activeCount = assignments.where((a) => a.isActive).length;
      final completedCount = assignments.where((a) => a.status == AssignmentStatus.completed).length;
      
      // Calculate average weight loss
      double totalWeightLoss = 0.0;
      int weightLossCount = 0;
      
      for (final assignment in assignments) {
        final weightChange = assignment.weightChange;
        if (weightChange < 0) { // Weight loss
          totalWeightLoss += weightChange.abs();
          weightLossCount++;
        }
      }
      
      final averageWeightLoss = weightLossCount > 0 ? totalWeightLoss / weightLossCount : 0.0;
      
      // Calculate average adherence score
      final totalAdherence = assignments.fold<int>(0, (sum, a) => sum + a.adherenceScore);
      final averageAdherence = assignments.isNotEmpty ? totalAdherence / assignments.length : 0.0;
      
      return DietitianAnalytics(
        totalAssignments: assignments.length,
        activeAssignments: activeCount,
        completedAssignments: completedCount,
        averageWeightLoss: averageWeightLoss,
        averageAdherenceScore: averageAdherence,
        assignments: assignments,
      );
      
    } catch (e) {
      return DietitianAnalytics.empty();
    }
  }
  
  /// Run automated scheduler cycle
  Future<void> _runSchedulerCycle() async {
    try {
      final result = await SequentialAssignmentScheduler.processAllActiveAssignments();
      
      // Log scheduler results if needed
      if (result.hasErrors) {
        print('Scheduler cycle completed with errors: ${result.generalErrors}');
      }
      
    } catch (e) {
      print('Scheduler cycle error: $e');
    }
  }
  
  /// Determine next recommended action for an assignment
  String _determineNextAction(UserDietAssignmentModel assignment, AssignmentSchedule schedule) {
    if (!schedule.isSuccess) return 'Program alınamadı';
    
    final activeSequence = schedule.activeSequence;
    final nextSequence = schedule.nextSequence;
    
    if (activeSequence != null) {
      if (activeSequence.daysRemaining <= 0) {
        return 'Sonraki diziye geçiş zamanı';
      } else {
        return '${activeSequence.daysRemaining} gün sonra dizi geçişi';
      }
    }
    
    if (nextSequence != null) {
      return 'Sonraki dizi: ${nextSequence.sequenceNumber}';
    }
    
    return 'Tüm diziler tamamlandı';
  }
  
  /// Ensure engine is initialized
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('Diet Assignment Engine henüz başlatılmamış. initialize() metodunu çağırın.');
    }
  }
  
  /// Dispose resources
  Future<void> dispose() async {
    await stopAutomaticScheduler();
    _isInitialized = false;
  }
}

/// Main result type for diet assignment engine operations
class DietAssignmentEngineResult {
  final bool isSuccess;
  final UserDietAssignmentModel? assignment;
  final String? message;
  final String? error;
  final BMIAnalysisResult? bmiAnalysis;
  final List<SelectedDietFile> selectedFiles;
  final String? existingAssignmentId;

  DietAssignmentEngineResult._({
    required this.isSuccess,
    this.assignment,
    this.message,
    this.error,
    this.bmiAnalysis,
    this.selectedFiles = const [],
    this.existingAssignmentId,
  });

  factory DietAssignmentEngineResult.success({
    required UserDietAssignmentModel assignment,
    required String message,
    BMIAnalysisResult? bmiAnalysis,
    List<SelectedDietFile> selectedFiles = const [],
  }) {
    return DietAssignmentEngineResult._(
      isSuccess: true,
      assignment: assignment,
      message: message,
      bmiAnalysis: bmiAnalysis,
      selectedFiles: selectedFiles,
    );
  }

  factory DietAssignmentEngineResult.error(String error, {String? existingAssignmentId}) {
    return DietAssignmentEngineResult._(
      isSuccess: false,
      error: error,
      existingAssignmentId: existingAssignmentId,
    );
  }
}

/// Result for finding best package for user
class BestPackageResult {
  final bool isSuccess;
  final DietPackageModel? package;
  final int? compatibilityScore;
  final int? availableSequences;
  final int? estimatedDuration;
  final double? expectedWeightChange;
  final List<CompatiblePackage>? allOptions;
  final String? error;

  BestPackageResult._({
    required this.isSuccess,
    this.package,
    this.compatibilityScore,
    this.availableSequences,
    this.estimatedDuration,
    this.expectedWeightChange,
    this.allOptions,
    this.error,
  });

  factory BestPackageResult.success({
    required DietPackageModel package,
    required int compatibilityScore,
    required int availableSequences,
    required int estimatedDuration,
    required double expectedWeightChange,
    List<CompatiblePackage>? allOptions,
  }) {
    return BestPackageResult._(
      isSuccess: true,
      package: package,
      compatibilityScore: compatibilityScore,
      availableSequences: availableSequences,
      estimatedDuration: estimatedDuration,
      expectedWeightChange: expectedWeightChange,
      allOptions: allOptions,
    );
  }

  factory BestPackageResult.error(String error) {
    return BestPackageResult._(
      isSuccess: false,
      error: error,
    );
  }
}

/// Result for user assignment status
class AssignmentStatusResult {
  final AssignmentStatus status;
  final UserDietAssignmentModel? assignment;
  final AssignmentSchedule? schedule;
  final BMIAnalysisResult? bmiAnalysis;
  final String? message;
  final String? error;
  final String? nextAction;

  AssignmentStatusResult._({
    required this.status,
    this.assignment,
    this.schedule,
    this.bmiAnalysis,
    this.message,
    this.error,
    this.nextAction,
  });

  factory AssignmentStatusResult.active({
    required UserDietAssignmentModel assignment,
    AssignmentSchedule? schedule,
    BMIAnalysisResult? bmiAnalysis,
    String? nextAction,
  }) {
    return AssignmentStatusResult._(
      status: assignment.status,
      assignment: assignment,
      schedule: schedule,
      bmiAnalysis: bmiAnalysis,
      nextAction: nextAction,
    );
  }

  factory AssignmentStatusResult.noAssignment(String message) {
    return AssignmentStatusResult._(
      status: AssignmentStatus.cancelled, // Use as "no assignment" status
      message: message,
    );
  }

  factory AssignmentStatusResult.error(String error) {
    return AssignmentStatusResult._(
      status: AssignmentStatus.cancelled, // Use as error status
      error: error,
    );
  }
}

/// Result for sequence transition
class SequenceTransitionResult {
  final bool isSuccess;
  final int? sequenceNumber;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<SelectedDietFile> selectedFiles;
  final String? assignmentId;
  final String? error;

  SequenceTransitionResult._({
    required this.isSuccess,
    this.sequenceNumber,
    this.startDate,
    this.endDate,
    this.selectedFiles = const [],
    this.assignmentId,
    this.error,
  });

  factory SequenceTransitionResult.success({
    required int sequenceNumber,
    required DateTime startDate,
    required DateTime endDate,
    List<SelectedDietFile> selectedFiles = const [],
    String? assignmentId,
  }) {
    return SequenceTransitionResult._(
      isSuccess: true,
      sequenceNumber: sequenceNumber,
      startDate: startDate,
      endDate: endDate,
      selectedFiles: selectedFiles,
      assignmentId: assignmentId,
    );
  }

  factory SequenceTransitionResult.error(String error) {
    return SequenceTransitionResult._(
      isSuccess: false,
      error: error,
    );
  }
}

/// Analytics for dietitian
class DietitianAnalytics {
  final int totalAssignments;
  final int activeAssignments;
  final int completedAssignments;
  final double averageWeightLoss;
  final double averageAdherenceScore;
  final List<UserDietAssignmentModel> assignments;

  DietitianAnalytics({
    required this.totalAssignments,
    required this.activeAssignments,
    required this.completedAssignments,
    required this.averageWeightLoss,
    required this.averageAdherenceScore,
    required this.assignments,
  });

  factory DietitianAnalytics.empty() {
    return DietitianAnalytics(
      totalAssignments: 0,
      activeAssignments: 0,
      completedAssignments: 0,
      averageWeightLoss: 0.0,
      averageAdherenceScore: 0.0,
      assignments: [],
    );
  }

  /// Success rate percentage
  double get successRate {
    if (totalAssignments == 0) return 0.0;
    return (completedAssignments / totalAssignments) * 100;
  }

  /// Get formatted weight loss
  String get formattedAverageWeightLoss {
    if (averageWeightLoss == 0.0) return 'Veri yok';
    return '${averageWeightLoss.toStringAsFixed(1)} kg ortalama';
  }

  /// Get formatted adherence score
  String get formattedAverageAdherence {
    return '${averageAdherenceScore.toStringAsFixed(0)}%';
  }
}