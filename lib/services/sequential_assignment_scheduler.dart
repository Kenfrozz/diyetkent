import '../models/diet_package_model.dart';
import 'dart:async';
import '../models/user_diet_assignment_model.dart';
import '../database/drift_service.dart';
import 'diet_assignment_integration_service.dart';
import 'diet_file_selection_algorithm.dart';

/// Service for managing sequential diet file assignments and automatic scheduling
class SequentialAssignmentScheduler {
  
  /// Check all active assignments and process any that need sequence updates
  static Future<SchedulerProcessResult> processAllActiveAssignments() async {
    final results = SchedulerProcessResult();
    
    try {
      final activeAssignments = await DriftService.getAllActiveAssignments();
      
      for (final assignment in activeAssignments) {
        final processResult = await processAssignmentScheduling(assignment.assignmentId);
        results.addResult(assignment.assignmentId, processResult);
      }
      
      return results;
      
    } catch (e) {
      results.addError('Genel işleme hatası: $e');
      return results;
    }
  }
  
  /// Process scheduling for a specific assignment
  static Future<AssignmentProcessResult> processAssignmentScheduling(String assignmentId) async {
    try {
      final assignment = await _getAssignmentById(assignmentId);
      if (assignment == null) {
        return AssignmentProcessResult.error('Atama bulunamadı');
      }
      
      if (!assignment.isActive) {
        return AssignmentProcessResult.noAction('Atama aktif değil');
      }
      
      // Get package information
      final package = await DriftService.getDietPackage(assignment.packageId);
      if (package == null) {
        return AssignmentProcessResult.error('Paket bulunamadı');
      }
      
      // Calculate current sequence number based on elapsed days
      final currentSequence = _calculateCurrentSequence(assignment, package);
      
      // Check if we need to transition to next sequence
      final shouldTransition = _shouldTransitionToNextSequence(assignment, package, currentSequence);
      
      if (shouldTransition) {
        return await _transitionToNextSequence(assignment, package, currentSequence + 1);
      }
      
      // Check if assignment should be completed
      final shouldComplete = _shouldCompleteAssignment(assignment, package);
      if (shouldComplete) {
        return await _completeAssignment(assignment);
      }
      
      // Check if assignment should expire
      final shouldExpire = _shouldExpireAssignment(assignment);
      if (shouldExpire) {
        return await _expireAssignment(assignment);
      }
      
      return AssignmentProcessResult.noAction('Herhangi bir eylem gerekmiyor');
      
    } catch (e) {
      return AssignmentProcessResult.error('İşleme hatası: $e');
    }
  }
  
  /// Schedule next diet sequence for an assignment
  static Future<SequenceScheduleResult> scheduleNextSequence({
    required String assignmentId,
    bool forceTransition = false,
  }) async {
    try {
      final assignment = await _getAssignmentById(assignmentId);
      if (assignment == null) {
        return SequenceScheduleResult.error('Atama bulunamadı');
      }
      
      final package = await DriftService.getDietPackage(assignment.packageId);
      if (package == null) {
        return SequenceScheduleResult.error('Paket bulunamadı');
      }
      
      final currentSequence = _calculateCurrentSequence(assignment, package);
      final nextSequence = currentSequence + 1;
      
      // Check if next sequence is available
      if (nextSequence > package.numberOfFiles) {
        return SequenceScheduleResult.error('Tüm diziler tamamlandı');
      }
      
      // Check if ready for transition (unless forced)
      if (!forceTransition && !_shouldTransitionToNextSequence(assignment, package, currentSequence)) {
        return SequenceScheduleResult.waiting(
          'Henüz geçiş zamanı gelmedi',
          currentSequence,
          _calculateSequenceEndDate(assignment, package, currentSequence),
        );
      }
      
      // Get next sequence files
      final sequenceResult = await DietAssignmentIntegrationService.getNextDietSequence(
        assignmentId: assignmentId,
        nextSequenceNumber: nextSequence,
      );
      
      if (!sequenceResult.isSuccess) {
        return SequenceScheduleResult.error(sequenceResult.error ?? 'Sonraki dizi bulunamadı');
      }
      
      // Update assignment with new sequence information
      await _updateAssignmentSequence(assignment, nextSequence, sequenceResult);
      
      return SequenceScheduleResult.success(
        sequenceNumber: nextSequence,
        selectionResult: sequenceResult.selectionResult!,
        startDate: sequenceResult.startDate!,
        endDate: _calculateSequenceEndDate(assignment, package, nextSequence),
      );
      
    } catch (e) {
      return SequenceScheduleResult.error('Zamanlama hatası: $e');
    }
  }
  
  /// Get upcoming schedule for an assignment
  static Future<AssignmentSchedule> getAssignmentSchedule(String assignmentId) async {
    try {
      final assignment = await _getAssignmentById(assignmentId);
      if (assignment == null) {
        return AssignmentSchedule.error('Atama bulunamadı');
      }
      
      final package = await DriftService.getDietPackage(assignment.packageId);
      if (package == null) {
        return AssignmentSchedule.error('Paket bulunamadı');
      }
      
      final currentSequence = _calculateCurrentSequence(assignment, package);
      final scheduleItems = <ScheduleItem>[];
      
      // Create schedule items for all sequences
      for (int seq = 1; seq <= package.numberOfFiles; seq++) {
        final startDate = assignment.startDate.add(Duration(days: (seq - 1) * package.daysPerFile));
        final endDate = startDate.add(Duration(days: package.daysPerFile - 1));
        
        final status = _getSequenceStatus(seq, currentSequence, assignment, endDate);
        
        scheduleItems.add(ScheduleItem(
          sequenceNumber: seq,
          startDate: startDate,
          endDate: endDate,
          status: status,
          isCurrentSequence: seq == currentSequence,
          daysRemaining: status == SequenceStatus.active ? 
            endDate.difference(DateTime.now()).inDays : 0,
        ));
      }
      
      return AssignmentSchedule.success(
        assignment: assignment,
        package: package,
        currentSequence: currentSequence,
        scheduleItems: scheduleItems,
        totalSequences: package.numberOfFiles,
      );
      
    } catch (e) {
      return AssignmentSchedule.error('Program alma hatası: $e');
    }
  }
  
  /// Calculate current sequence number based on elapsed time
  static int _calculateCurrentSequence(UserDietAssignmentModel assignment, DietPackageModel package) {
    final now = DateTime.now();
    
    if (now.isBefore(assignment.startDate)) return 0;
    
    final daysPassed = now.difference(assignment.startDate).inDays;
    final sequence = (daysPassed / package.daysPerFile).floor() + 1;
    
    return sequence.clamp(1, package.numberOfFiles);
  }
  
  /// Check if should transition to next sequence
  static bool _shouldTransitionToNextSequence(
    UserDietAssignmentModel assignment,
    DietPackageModel package,
    int currentSequence,
  ) {
    if (currentSequence >= package.numberOfFiles) return false;
    
    final currentSequenceEndDate = _calculateSequenceEndDate(assignment, package, currentSequence);
    final now = DateTime.now();
    
    // Transition if current sequence period has ended
    return now.isAfter(currentSequenceEndDate);
  }
  
  /// Check if assignment should be completed
  static bool _shouldCompleteAssignment(UserDietAssignmentModel assignment, DietPackageModel package) {
    final lastSequenceEndDate = _calculateSequenceEndDate(assignment, package, package.numberOfFiles);
    return DateTime.now().isAfter(lastSequenceEndDate) && assignment.status == AssignmentStatus.active;
  }
  
  /// Check if assignment should expire
  static bool _shouldExpireAssignment(UserDietAssignmentModel assignment) {
    return DateTime.now().isAfter(assignment.endDate) && assignment.status == AssignmentStatus.active;
  }
  
  /// Calculate end date for a specific sequence
  static DateTime _calculateSequenceEndDate(
    UserDietAssignmentModel assignment,
    DietPackageModel package,
    int sequenceNumber,
  ) {
    final sequenceStartDate = assignment.startDate.add(
      Duration(days: (sequenceNumber - 1) * package.daysPerFile)
    );
    return sequenceStartDate.add(Duration(days: package.daysPerFile - 1));
  }
  
  /// Transition assignment to next sequence
  static Future<AssignmentProcessResult> _transitionToNextSequence(
    UserDietAssignmentModel assignment,
    DietPackageModel package,
    int nextSequence,
  ) async {
    try {
      // Schedule next sequence
      final scheduleResult = await scheduleNextSequence(
        assignmentId: assignment.assignmentId,
        forceTransition: true,
      );
      
      if (!scheduleResult.isSuccess) {
        return AssignmentProcessResult.error('Geçiş başarısız: ${scheduleResult.error}');
      }
      
      return AssignmentProcessResult.sequenceTransition(
        'Dizi $nextSequence\'e geçiş yapıldı',
        nextSequence,
        scheduleResult.startDate!,
      );
      
    } catch (e) {
      return AssignmentProcessResult.error('Geçiş hatası: $e');
    }
  }
  
  /// Complete an assignment
  static Future<AssignmentProcessResult> _completeAssignment(UserDietAssignmentModel assignment) async {
    try {
      assignment.status = AssignmentStatus.completed;
      assignment.progress = 1.0;
      assignment.updatedAt = DateTime.now();
      
      await DriftService.saveUserDietAssignment(assignment);
      
      return AssignmentProcessResult.completion('Atama başarıyla tamamlandı');
      
    } catch (e) {
      return AssignmentProcessResult.error('Tamamlama hatası: $e');
    }
  }
  
  /// Expire an assignment
  static Future<AssignmentProcessResult> _expireAssignment(UserDietAssignmentModel assignment) async {
    try {
      assignment.status = AssignmentStatus.expired;
      assignment.updatedAt = DateTime.now();
      
      await DriftService.saveUserDietAssignment(assignment);
      
      return AssignmentProcessResult.expiry('Atama süresi doldu');
      
    } catch (e) {
      return AssignmentProcessResult.error('Süre dolma hatası: $e');
    }
  }
  
  /// Update assignment with new sequence information
  static Future<void> _updateAssignmentSequence(
    UserDietAssignmentModel assignment,
    int sequenceNumber,
    DietFileSequenceResult sequenceResult,
  ) async {
    assignment.lastActivityAt = DateTime.now();
    assignment.updatedAt = DateTime.now();
    
    // Update custom settings to track current sequence
    final customSettings = {
      'currentSequence': sequenceNumber,
      'lastSequenceStart': sequenceResult.startDate!.millisecondsSinceEpoch,
    };
    assignment.customSettings = customSettings.toString();
    
    await DriftService.saveUserDietAssignment(assignment);
  }
  
  /// Get sequence status
  static SequenceStatus _getSequenceStatus(
    int sequenceNumber,
    int currentSequence,
    UserDietAssignmentModel assignment,
    DateTime sequenceEndDate,
  ) {
    final now = DateTime.now();
    
    if (sequenceNumber < currentSequence) return SequenceStatus.completed;
    if (sequenceNumber > currentSequence) return SequenceStatus.pending;
    
    // Current sequence
    if (now.isAfter(sequenceEndDate)) return SequenceStatus.completed;
    return SequenceStatus.active;
  }
  
  /// Get assignment by ID
  static Future<UserDietAssignmentModel?> _getAssignmentById(String assignmentId) async {
    final assignments = await DriftService.getAllActiveAssignments();
    return assignments.where((a) => a.assignmentId == assignmentId).firstOrNull;
  }
}

/// Result of scheduler processing for all assignments
class SchedulerProcessResult {
  final Map<String, AssignmentProcessResult> assignmentResults = {};
  final List<String> generalErrors = [];
  
  void addResult(String assignmentId, AssignmentProcessResult result) {
    assignmentResults[assignmentId] = result;
  }
  
  void addError(String error) {
    generalErrors.add(error);
  }
  
  bool get hasErrors => generalErrors.isNotEmpty || 
    assignmentResults.values.any((r) => r.resultType == ProcessResultType.error);
  
  int get processedCount => assignmentResults.length;
  
  int get transitionCount => assignmentResults.values
    .where((r) => r.resultType == ProcessResultType.sequenceTransition)
    .length;
    
  int get completionCount => assignmentResults.values
    .where((r) => r.resultType == ProcessResultType.completion)
    .length;
}

/// Result of processing a single assignment
class AssignmentProcessResult {
  final ProcessResultType resultType;
  final String message;
  final int? sequenceNumber;
  final DateTime? actionDate;

  AssignmentProcessResult._(this.resultType, this.message, {this.sequenceNumber, this.actionDate});

  factory AssignmentProcessResult.error(String message) {
    return AssignmentProcessResult._(ProcessResultType.error, message);
  }
  
  factory AssignmentProcessResult.noAction(String message) {
    return AssignmentProcessResult._(ProcessResultType.noAction, message);
  }
  
  factory AssignmentProcessResult.sequenceTransition(String message, int sequenceNumber, DateTime actionDate) {
    return AssignmentProcessResult._(
      ProcessResultType.sequenceTransition, 
      message, 
      sequenceNumber: sequenceNumber, 
      actionDate: actionDate
    );
  }
  
  factory AssignmentProcessResult.completion(String message) {
    return AssignmentProcessResult._(ProcessResultType.completion, message, actionDate: DateTime.now());
  }
  
  factory AssignmentProcessResult.expiry(String message) {
    return AssignmentProcessResult._(ProcessResultType.expiry, message, actionDate: DateTime.now());
  }
}

/// Types of process results
enum ProcessResultType {
  error,
  noAction,
  sequenceTransition,
  completion,
  expiry,
}

/// Result of scheduling next sequence
class SequenceScheduleResult {
  final bool isSuccess;
  final int? sequenceNumber;
  final DietFileSelectionResult? selectionResult;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? error;
  final String? waitingReason;

  SequenceScheduleResult._({
    required this.isSuccess,
    this.sequenceNumber,
    this.selectionResult,
    this.startDate,
    this.endDate,
    this.error,
    this.waitingReason,
  });

  factory SequenceScheduleResult.success({
    required int sequenceNumber,
    required DietFileSelectionResult selectionResult,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return SequenceScheduleResult._(
      isSuccess: true,
      sequenceNumber: sequenceNumber,
      selectionResult: selectionResult,
      startDate: startDate,
      endDate: endDate,
    );
  }

  factory SequenceScheduleResult.error(String error) {
    return SequenceScheduleResult._(
      isSuccess: false,
      error: error,
    );
  }
  
  factory SequenceScheduleResult.waiting(String reason, int currentSequence, DateTime currentEndDate) {
    return SequenceScheduleResult._(
      isSuccess: false,
      waitingReason: reason,
      sequenceNumber: currentSequence,
      endDate: currentEndDate,
    );
  }
}

/// Assignment schedule with all sequence information
class AssignmentSchedule {
  final bool isSuccess;
  final UserDietAssignmentModel? assignment;
  final DietPackageModel? package;
  final int? currentSequence;
  final List<ScheduleItem> scheduleItems;
  final int? totalSequences;
  final String? error;

  AssignmentSchedule._({
    required this.isSuccess,
    this.assignment,
    this.package,
    this.currentSequence,
    this.scheduleItems = const [],
    this.totalSequences,
    this.error,
  });

  factory AssignmentSchedule.success({
    required UserDietAssignmentModel assignment,
    required DietPackageModel package,
    required int currentSequence,
    required List<ScheduleItem> scheduleItems,
    required int totalSequences,
  }) {
    return AssignmentSchedule._(
      isSuccess: true,
      assignment: assignment,
      package: package,
      currentSequence: currentSequence,
      scheduleItems: scheduleItems,
      totalSequences: totalSequences,
    );
  }

  factory AssignmentSchedule.error(String error) {
    return AssignmentSchedule._(
      isSuccess: false,
      error: error,
    );
  }
  
  /// Get next sequence to be activated
  ScheduleItem? get nextSequence {
    return scheduleItems.where((item) => item.status == SequenceStatus.pending).firstOrNull;
  }
  
  /// Get current active sequence
  ScheduleItem? get activeSequence {
    return scheduleItems.where((item) => item.status == SequenceStatus.active).firstOrNull;
  }
  
  /// Get completed sequences count
  int get completedSequencesCount {
    return scheduleItems.where((item) => item.status == SequenceStatus.completed).length;
  }
}

/// Individual schedule item for a sequence
class ScheduleItem {
  final int sequenceNumber;
  final DateTime startDate;
  final DateTime endDate;
  final SequenceStatus status;
  final bool isCurrentSequence;
  final int daysRemaining;

  ScheduleItem({
    required this.sequenceNumber,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.isCurrentSequence,
    required this.daysRemaining,
  });

  /// Get duration in days
  int get durationDays => endDate.difference(startDate).inDays + 1;
  
  /// Get formatted date range
  String get dateRange {
    return '${startDate.day}/${startDate.month}/${startDate.year} - ${endDate.day}/${endDate.month}/${endDate.year}';
  }
  
  /// Get status display name
  String get statusDisplayName {
    switch (status) {
      case SequenceStatus.pending:
        return 'Bekliyor';
      case SequenceStatus.active:
        return 'Aktif';
      case SequenceStatus.completed:
        return 'Tamamlandı';
    }
  }
}

/// Status of a sequence in the schedule
enum SequenceStatus {
  pending,
  active,
  completed,
}