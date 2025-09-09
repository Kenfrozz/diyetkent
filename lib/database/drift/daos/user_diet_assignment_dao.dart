import 'dart:convert';
import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/user_diet_assignments_table.dart';

part 'user_diet_assignment_dao.g.dart';

@DriftAccessor(tables: [UserDietAssignmentsTable])
class UserDietAssignmentDao extends DatabaseAccessor<AppDatabase> with _$UserDietAssignmentDaoMixin {
  UserDietAssignmentDao(super.db);

  // Get all user diet assignments
  Future<List<UserDietAssignmentData>> getAllUserDietAssignments() {
    return (select(userDietAssignmentsTable)
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Watch all user diet assignments
  Stream<List<UserDietAssignmentData>> watchAllUserDietAssignments() {
    return (select(userDietAssignmentsTable)
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .watch();
  }

  // Get assignment by ID
  Future<UserDietAssignmentData?> getAssignmentById(String assignmentId) {
    return (select(userDietAssignmentsTable)..where((t) => t.assignmentId.equals(assignmentId))).getSingleOrNull();
  }

  // Watch assignment by ID
  Stream<UserDietAssignmentData?> watchAssignmentById(String assignmentId) {
    return (select(userDietAssignmentsTable)..where((t) => t.assignmentId.equals(assignmentId))).watchSingleOrNull();
  }

  // Get assignments by user ID
  Future<List<UserDietAssignmentData>> getAssignmentsByUserId(String userId) {
    return (select(userDietAssignmentsTable)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Watch assignments by user ID
  Stream<List<UserDietAssignmentData>> watchAssignmentsByUserId(String userId) {
    return (select(userDietAssignmentsTable)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .watch();
  }

  // Get active assignments by user ID
  Future<List<UserDietAssignmentData>> getActiveAssignmentsByUserId(String userId) {
    return (select(userDietAssignmentsTable)
          ..where((t) => t.userId.equals(userId) & t.status.equals('active'))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Watch active assignments by user ID
  Stream<List<UserDietAssignmentData>> watchActiveAssignmentsByUserId(String userId) {
    return (select(userDietAssignmentsTable)
          ..where((t) => t.userId.equals(userId) & t.status.equals('active'))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .watch();
  }

  // Get assignments by dietitian ID
  Future<List<UserDietAssignmentData>> getAssignmentsByDietitianId(String dietitianId) {
    return (select(userDietAssignmentsTable)
          ..where((t) => t.dietitianId.equals(dietitianId))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Watch assignments by dietitian ID
  Stream<List<UserDietAssignmentData>> watchAssignmentsByDietitianId(String dietitianId) {
    return (select(userDietAssignmentsTable)
          ..where((t) => t.dietitianId.equals(dietitianId))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .watch();
  }

  // Get assignments by package ID
  Future<List<UserDietAssignmentData>> getAssignmentsByPackageId(String packageId) {
    return (select(userDietAssignmentsTable)
          ..where((t) => t.packageId.equals(packageId))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Save or update assignment (upsert)
  Future<int> saveAssignment(UserDietAssignmentsTableCompanion assignment) {
    return into(userDietAssignmentsTable).insertOnConflictUpdate(assignment);
  }

  // Batch save assignments
  Future<void> saveAssignments(List<UserDietAssignmentsTableCompanion> assignmentList) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(userDietAssignmentsTable, assignmentList);
    });
  }

  // Update assignment
  Future<bool> updateAssignment(UserDietAssignmentsTableCompanion assignment) {
    return update(userDietAssignmentsTable).replace(assignment);
  }

  // Delete assignment
  Future<int> deleteAssignment(String assignmentId) {
    return (delete(userDietAssignmentsTable)..where((t) => t.assignmentId.equals(assignmentId))).go();
  }

  // Update assignment status
  Future<int> updateAssignmentStatus(String assignmentId, String status) {
    return (update(userDietAssignmentsTable)..where((t) => t.assignmentId.equals(assignmentId)))
        .write(UserDietAssignmentsTableCompanion(
      status: Value(status),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update assignment progress
  Future<int> updateAssignmentProgress({
    required String assignmentId,
    double? progress,
    int? completedDays,
  }) {
    return (update(userDietAssignmentsTable)..where((t) => t.assignmentId.equals(assignmentId)))
        .write(UserDietAssignmentsTableCompanion(
      progress: Value.absentIfNull(progress),
      completedDays: Value.absentIfNull(completedDays),
      lastActivityAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update weight tracking
  Future<int> updateWeightTracking({
    required String assignmentId,
    double? weightStart,
    double? weightCurrent,
    double? weightTarget,
  }) {
    return (update(userDietAssignmentsTable)..where((t) => t.assignmentId.equals(assignmentId)))
        .write(UserDietAssignmentsTableCompanion(
      weightStart: Value.absentIfNull(weightStart),
      weightCurrent: Value.absentIfNull(weightCurrent),
      weightTarget: Value.absentIfNull(weightTarget),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update adherence score
  Future<int> updateAdherenceScore({
    required String assignmentId,
    int? adherenceScore,
    int? missedDays,
  }) {
    return (update(userDietAssignmentsTable)..where((t) => t.assignmentId.equals(assignmentId)))
        .write(UserDietAssignmentsTableCompanion(
      adherenceScore: Value.absentIfNull(adherenceScore),
      missedDays: Value.absentIfNull(missedDays),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update custom settings (JSON)
  Future<int> updateCustomSettings(String assignmentId, Map<String, dynamic> customSettings) {
    return (update(userDietAssignmentsTable)..where((t) => t.assignmentId.equals(assignmentId)))
        .write(UserDietAssignmentsTableCompanion(
      customSettings: Value(jsonEncode(customSettings)),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update dietitian notes
  Future<int> updateDietitianNotes(String assignmentId, String notes) {
    return (update(userDietAssignmentsTable)..where((t) => t.assignmentId.equals(assignmentId)))
        .write(UserDietAssignmentsTableCompanion(
      dietitianNotes: Value(notes),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update user notes
  Future<int> updateUserNotes(String assignmentId, String notes) {
    return (update(userDietAssignmentsTable)..where((t) => t.assignmentId.equals(assignmentId)))
        .write(UserDietAssignmentsTableCompanion(
      userNotes: Value(notes),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update user review and rating
  Future<int> updateUserReview({
    required String assignmentId,
    double? userRating,
    String? userReview,
  }) {
    return (update(userDietAssignmentsTable)..where((t) => t.assignmentId.equals(assignmentId)))
        .write(UserDietAssignmentsTableCompanion(
      userRating: Value.absentIfNull(userRating),
      userReview: Value.absentIfNull(userReview),
      isReviewed: const Value(true),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update next check date
  Future<int> updateNextCheckDate(String assignmentId, DateTime nextCheckDate) {
    return (update(userDietAssignmentsTable)..where((t) => t.assignmentId.equals(assignmentId)))
        .write(UserDietAssignmentsTableCompanion(
      nextCheckDate: Value(nextCheckDate),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update PDF information
  Future<int> updatePdfInfo({
    required String assignmentId,
    String? pdfPath,
    DateTime? pdfGeneratedAt,
  }) {
    return (update(userDietAssignmentsTable)..where((t) => t.assignmentId.equals(assignmentId)))
        .write(UserDietAssignmentsTableCompanion(
      generatedPdfPath: Value.absentIfNull(pdfPath),
      pdfGeneratedAt: Value.absentIfNull(pdfGeneratedAt ?? DateTime.now()),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update delivery schedule (JSON)
  Future<int> updateDeliverySchedule(String assignmentId, Map<String, dynamic> deliverySchedule) {
    return (update(userDietAssignmentsTable)..where((t) => t.assignmentId.equals(assignmentId)))
        .write(UserDietAssignmentsTableCompanion(
      deliverySchedule: Value(jsonEncode(deliverySchedule)),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Get assignments by status
  Future<List<UserDietAssignmentData>> getAssignmentsByStatus(String status) {
    return (select(userDietAssignmentsTable)
          ..where((t) => t.status.equals(status))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Watch assignments by status
  Stream<List<UserDietAssignmentData>> watchAssignmentsByStatus(String status) {
    return (select(userDietAssignmentsTable)
          ..where((t) => t.status.equals(status))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .watch();
  }

  // Get active assignments
  Future<List<UserDietAssignmentData>> getActiveAssignments() {
    return getAssignmentsByStatus('active');
  }

  // Watch active assignments
  Stream<List<UserDietAssignmentData>> watchActiveAssignments() {
    return watchAssignmentsByStatus('active');
  }

  // Get completed assignments
  Future<List<UserDietAssignmentData>> getCompletedAssignments() {
    return getAssignmentsByStatus('completed');
  }

  // Get expired assignments
  Future<List<UserDietAssignmentData>> getExpiredAssignments() {
    final now = DateTime.now();
    return (select(userDietAssignmentsTable)
          ..where((t) => t.endDate.isSmallerThanValue(now) & 
                        (t.status.equals('active') | t.status.equals('paused')))
          ..orderBy([(t) => OrderingTerm(expression: t.endDate, mode: OrderingMode.desc)]))
        .get();
  }

  // Get assignments due for check
  Future<List<UserDietAssignmentData>> getAssignmentsDueForCheck() {
    final now = DateTime.now();
    return (select(userDietAssignmentsTable)
          ..where((t) => t.nextCheckDate.isSmallerOrEqualValue(now) & 
                        t.status.equals('active'))
          ..orderBy([(t) => OrderingTerm(expression: t.nextCheckDate, mode: OrderingMode.asc)]))
        .get();
  }

  // Get assignments in date range
  Future<List<UserDietAssignmentData>> getAssignmentsInDateRange(DateTime from, DateTime to) {
    return (select(userDietAssignmentsTable)
          ..where((t) => t.createdAt.isBetweenValues(from, to))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Get current active assignment for user
  Future<UserDietAssignmentData?> getCurrentActiveAssignment(String userId) {
    return (select(userDietAssignmentsTable)
          ..where((t) => t.userId.equals(userId) & t.status.equals('active'))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])
          ..limit(1))
        .getSingleOrNull();
  }

  // Watch current active assignment for user
  Stream<UserDietAssignmentData?> watchCurrentActiveAssignment(String userId) {
    return (select(userDietAssignmentsTable)
          ..where((t) => t.userId.equals(userId) & t.status.equals('active'))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])
          ..limit(1))
        .watchSingleOrNull();
  }

  // Get assignments with high adherence score
  Future<List<UserDietAssignmentData>> getHighPerformingAssignments({int minScore = 80}) {
    return (select(userDietAssignmentsTable)
          ..where((t) => t.adherenceScore.isBiggerOrEqualValue(minScore))
          ..orderBy([(t) => OrderingTerm(expression: t.adherenceScore, mode: OrderingMode.desc)]))
        .get();
  }

  // Get assignments needing attention (low adherence or many missed days)
  Future<List<UserDietAssignmentData>> getAssignmentsNeedingAttention({
    int maxAdherenceScore = 60,
    int maxMissedDays = 5,
  }) {
    return (select(userDietAssignmentsTable)
          ..where((t) => t.status.equals('active') &
                        (t.adherenceScore.isSmallerOrEqualValue(maxAdherenceScore) |
                         t.missedDays.isBiggerOrEqualValue(maxMissedDays)))
          ..orderBy([(t) => OrderingTerm(expression: t.adherenceScore, mode: OrderingMode.asc)]))
        .get();
  }

  // Get assignments with pagination
  Future<List<UserDietAssignmentData>> getAssignmentsPaginated({
    String? userId,
    String? dietitianId,
    String? packageId,
    String? status,
    required int limit,
    int? offset,
    String? orderBy = 'createdAt',
    bool ascending = false,
  }) {
    var query = select(userDietAssignmentsTable);
    
    // Add filters
    if (userId != null) {
      query = query..where((t) => t.userId.equals(userId));
    }
    
    if (dietitianId != null) {
      query = query..where((t) => t.dietitianId.equals(dietitianId));
    }
    
    if (packageId != null) {
      query = query..where((t) => t.packageId.equals(packageId));
    }
    
    if (status != null) {
      query = query..where((t) => t.status.equals(status));
    }
    
    // Add ordering
    switch (orderBy) {
      case 'createdAt':
        query = query..orderBy([(t) => OrderingTerm(
          expression: t.createdAt, 
          mode: ascending ? OrderingMode.asc : OrderingMode.desc
        )]);
        break;
      case 'progress':
        query = query..orderBy([(t) => OrderingTerm(
          expression: t.progress, 
          mode: ascending ? OrderingMode.asc : OrderingMode.desc
        )]);
        break;
      case 'adherenceScore':
        query = query..orderBy([(t) => OrderingTerm(
          expression: t.adherenceScore, 
          mode: ascending ? OrderingMode.asc : OrderingMode.desc
        )]);
        break;
      case 'endDate':
        query = query..orderBy([(t) => OrderingTerm(
          expression: t.endDate, 
          mode: ascending ? OrderingMode.asc : OrderingMode.desc
        )]);
        break;
      case 'lastActivityAt':
        query = query..orderBy([(t) => OrderingTerm(
          expression: t.lastActivityAt, 
          mode: ascending ? OrderingMode.asc : OrderingMode.desc
        )]);
        break;
    }
    
    // Add pagination
    query = query..limit(limit);
    if (offset != null && offset > 0) {
      query = query..limit(limit, offset: offset);
    }
    
    return query.get();
  }

  // Count assignments
  Future<int> countAssignments({
    String? userId,
    String? dietitianId,
    String? packageId,
    String? status,
  }) {
    var query = selectOnly(userDietAssignmentsTable);
    
    if (userId != null) {
      query = query..where(userDietAssignmentsTable.userId.equals(userId));
    }
    
    if (dietitianId != null) {
      query = query..where(userDietAssignmentsTable.dietitianId.equals(dietitianId));
    }
    
    if (packageId != null) {
      query = query..where(userDietAssignmentsTable.packageId.equals(packageId));
    }
    
    if (status != null) {
      query = query..where(userDietAssignmentsTable.status.equals(status));
    }
    
    query = query..addColumns([userDietAssignmentsTable.id.count()]);
    return query.map((row) => row.read(userDietAssignmentsTable.id.count()) ?? 0).getSingle();
  }

  // Get assignment statistics for dietitian
  Future<Map<String, dynamic>> getDietitianAssignmentStatistics(String dietitianId) async {
    final totalAssignments = await countAssignments(dietitianId: dietitianId);
    final activeAssignments = await countAssignments(dietitianId: dietitianId, status: 'active');
    final completedAssignments = await countAssignments(dietitianId: dietitianId, status: 'completed');
    
    final allAssignments = await getAssignmentsByDietitianId(dietitianId);
    final averageAdherence = allAssignments.isEmpty 
        ? 0.0 
        : allAssignments.map((a) => a.adherenceScore).reduce((a, b) => a + b) / allAssignments.length;
    
    return {
      'total': totalAssignments,
      'active': activeAssignments,
      'completed': completedAssignments,
      'averageAdherence': averageAdherence,
    };
  }

  // Get assignment statistics for user
  Future<Map<String, dynamic>> getUserAssignmentStatistics(String userId) async {
    final totalAssignments = await countAssignments(userId: userId);
    final activeAssignments = await countAssignments(userId: userId, status: 'active');
    final completedAssignments = await countAssignments(userId: userId, status: 'completed');
    
    final userAssignments = await getAssignmentsByUserId(userId);
    final averageAdherence = userAssignments.isEmpty 
        ? 0.0 
        : userAssignments.map((a) => a.adherenceScore).reduce((a, b) => a + b) / userAssignments.length;
    
    return {
      'total': totalAssignments,
      'active': activeAssignments,
      'completed': completedAssignments,
      'averageAdherence': averageAdherence,
    };
  }

  // Get custom settings from JSON
  Future<Map<String, dynamic>> getCustomSettings(String assignmentId) async {
    final assignment = await getAssignmentById(assignmentId);
    if (assignment != null) {
      return jsonDecode(assignment.customSettings) as Map<String, dynamic>;
    }
    return {};
  }

  // Get delivery schedule from JSON
  Future<Map<String, dynamic>> getDeliverySchedule(String assignmentId) async {
    final assignment = await getAssignmentById(assignmentId);
    if (assignment != null) {
      return jsonDecode(assignment.deliverySchedule) as Map<String, dynamic>;
    }
    return {};
  }

  // Increment completed days and update progress
  Future<int> incrementCompletedDays(String assignmentId) async {
    final assignment = await getAssignmentById(assignmentId);
    if (assignment != null) {
      final newCompletedDays = assignment.completedDays + 1;
      final newProgress = assignment.totalDays > 0 
          ? (newCompletedDays / assignment.totalDays).clamp(0.0, 1.0)
          : 0.0;
      
      return updateAssignmentProgress(
        assignmentId: assignmentId,
        progress: newProgress,
        completedDays: newCompletedDays,
      );
    }
    return 0;
  }

  // Mark day as missed
  Future<int> markDayAsMissed(String assignmentId) async {
    final assignment = await getAssignmentById(assignmentId);
    if (assignment != null) {
      return updateAdherenceScore(
        assignmentId: assignmentId,
        missedDays: assignment.missedDays + 1,
      );
    }
    return 0;
  }

  // Auto-expire assignments
  Future<int> autoExpireAssignments() {
    final now = DateTime.now();
    return (update(userDietAssignmentsTable)
          ..where((t) => t.endDate.isSmallerThanValue(now) & 
                        (t.status.equals('active') | t.status.equals('paused'))))
        .write(UserDietAssignmentsTableCompanion(
      status: const Value('expired'),
      updatedAt: Value(now),
    ));
  }

  // Delete assignments for user
  Future<int> deleteAssignmentsForUser(String userId) {
    return (delete(userDietAssignmentsTable)..where((t) => t.userId.equals(userId))).go();
  }

  // Delete assignments by dietitian
  Future<int> deleteAssignmentsByDietitian(String dietitianId) {
    return (delete(userDietAssignmentsTable)..where((t) => t.dietitianId.equals(dietitianId))).go();
  }

  // Delete assignments by package
  Future<int> deleteAssignmentsByPackage(String packageId) {
    return (delete(userDietAssignmentsTable)..where((t) => t.packageId.equals(packageId))).go();
  }

  // Clear old assignments
  Future<int> clearOldAssignments({Duration? olderThan}) {
    final thresholdTime = olderThan != null 
        ? DateTime.now().subtract(olderThan)
        : DateTime.now().subtract(const Duration(days: 365));
        
    return (delete(userDietAssignmentsTable)
          ..where((t) => t.createdAt.isSmallerThanValue(thresholdTime) & 
                        (t.status.equals('completed') | t.status.equals('cancelled'))))
        .go();
  }

  // Clear all assignments
  Future<int> clearAll() {
    return delete(userDietAssignmentsTable).go();
  }
}