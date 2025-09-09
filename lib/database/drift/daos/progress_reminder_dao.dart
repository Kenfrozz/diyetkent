import 'dart:convert';
import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/progress_reminders_table.dart';

part 'progress_reminder_dao.g.dart';

@DriftAccessor(tables: [ProgressRemindersTable])
class ProgressReminderDao extends DatabaseAccessor<AppDatabase> with _$ProgressReminderDaoMixin {
  ProgressReminderDao(super.db);

  // Get all progress reminders
  Future<List<ProgressReminderData>> getAllProgressReminders() {
    return (select(progressRemindersTable)
          ..orderBy([(t) => OrderingTerm(expression: t.scheduledTime, mode: OrderingMode.desc)]))
        .get();
  }

  // Watch all progress reminders
  Stream<List<ProgressReminderData>> watchAllProgressReminders() {
    return (select(progressRemindersTable)
          ..orderBy([(t) => OrderingTerm(expression: t.scheduledTime, mode: OrderingMode.desc)]))
        .watch();
  }

  // Get progress reminder by ID
  Future<ProgressReminderData?> getProgressReminderById(String reminderId) {
    return (select(progressRemindersTable)..where((t) => t.reminderId.equals(reminderId))).getSingleOrNull();
  }

  // Watch progress reminder by ID
  Stream<ProgressReminderData?> watchProgressReminderById(String reminderId) {
    return (select(progressRemindersTable)..where((t) => t.reminderId.equals(reminderId))).watchSingleOrNull();
  }

  // Get progress reminders by user ID
  Future<List<ProgressReminderData>> getProgressRemindersByUserId(String userId) {
    return (select(progressRemindersTable)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm(expression: t.scheduledTime, mode: OrderingMode.desc)]))
        .get();
  }

  // Watch progress reminders by user ID
  Stream<List<ProgressReminderData>> watchProgressRemindersByUserId(String userId) {
    return (select(progressRemindersTable)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm(expression: t.scheduledTime, mode: OrderingMode.desc)]))
        .watch();
  }

  // Get active progress reminders by user ID
  Future<List<ProgressReminderData>> getActiveProgressRemindersByUserId(String userId) {
    return (select(progressRemindersTable)
          ..where((t) => t.userId.equals(userId) & 
                        t.isEnabled.equals(true) &
                        (t.status.equals('scheduled') | t.status.equals('delivered')))
          ..orderBy([(t) => OrderingTerm(expression: t.scheduledTime, mode: OrderingMode.asc)]))
        .get();
  }

  // Watch active progress reminders by user ID
  Stream<List<ProgressReminderData>> watchActiveProgressRemindersByUserId(String userId) {
    return (select(progressRemindersTable)
          ..where((t) => t.userId.equals(userId) & 
                        t.isEnabled.equals(true) &
                        (t.status.equals('scheduled') | t.status.equals('delivered')))
          ..orderBy([(t) => OrderingTerm(expression: t.scheduledTime, mode: OrderingMode.asc)]))
        .watch();
  }

  // Get progress reminders by dietitian ID
  Future<List<ProgressReminderData>> getProgressRemindersByDietitianId(String dietitianId) {
    return (select(progressRemindersTable)
          ..where((t) => t.dietitianId.equals(dietitianId))
          ..orderBy([(t) => OrderingTerm(expression: t.scheduledTime, mode: OrderingMode.desc)]))
        .get();
  }

  // Watch progress reminders by dietitian ID
  Stream<List<ProgressReminderData>> watchProgressRemindersByDietitianId(String dietitianId) {
    return (select(progressRemindersTable)
          ..where((t) => t.dietitianId.equals(dietitianId))
          ..orderBy([(t) => OrderingTerm(expression: t.scheduledTime, mode: OrderingMode.desc)]))
        .watch();
  }

  // Save or update progress reminder (upsert)
  Future<int> saveProgressReminder(ProgressRemindersTableCompanion reminder) {
    return into(progressRemindersTable).insertOnConflictUpdate(reminder);
  }

  // Batch save progress reminders
  Future<void> saveProgressReminders(List<ProgressRemindersTableCompanion> reminderList) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(progressRemindersTable, reminderList);
    });
  }

  // Update progress reminder
  Future<bool> updateProgressReminder(ProgressRemindersTableCompanion reminder) {
    return update(progressRemindersTable).replace(reminder);
  }

  // Delete progress reminder
  Future<int> deleteProgressReminder(String reminderId) {
    return (delete(progressRemindersTable)..where((t) => t.reminderId.equals(reminderId))).go();
  }

  // Update progress reminder status
  Future<int> updateProgressReminderStatus(String reminderId, String status, {DateTime? timestamp}) {
    return (update(progressRemindersTable)..where((t) => t.reminderId.equals(reminderId)))
        .write(ProgressRemindersTableCompanion(
      status: Value(status),
      deliveredAt: status == 'delivered' ? Value(timestamp ?? DateTime.now()) : const Value.absent(),
      completedAt: status == 'completed' ? Value(timestamp ?? DateTime.now()) : const Value.absent(),
      dismissedAt: status == 'dismissed' ? Value(timestamp ?? DateTime.now()) : const Value.absent(),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update progress reminder basic info
  Future<int> updateProgressReminderInfo({
    required String reminderId,
    String? title,
    String? message,
    String? description,
  }) {
    return (update(progressRemindersTable)..where((t) => t.reminderId.equals(reminderId)))
        .write(ProgressRemindersTableCompanion(
      title: Value.absentIfNull(title),
      message: Value.absentIfNull(message),
      description: Value.absentIfNull(description),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update progress reminder schedule
  Future<int> updateProgressReminderSchedule({
    required String reminderId,
    DateTime? scheduledTime,
    String? frequency,
    int? customIntervalDays,
  }) {
    return (update(progressRemindersTable)..where((t) => t.reminderId.equals(reminderId)))
        .write(ProgressRemindersTableCompanion(
      scheduledTime: Value.absentIfNull(scheduledTime),
      frequency: Value.absentIfNull(frequency),
      customIntervalDays: Value.absentIfNull(customIntervalDays),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update progress reminder settings
  Future<int> updateProgressReminderSettings({
    required String reminderId,
    bool? isEnabled,
    int? notificationId,
    int? priority,
    int? maxReminders,
  }) {
    return (update(progressRemindersTable)..where((t) => t.reminderId.equals(reminderId)))
        .write(ProgressRemindersTableCompanion(
      isEnabled: Value.absentIfNull(isEnabled),
      notificationId: Value.absentIfNull(notificationId),
      priority: Value.absentIfNull(priority),
      maxReminders: Value.absentIfNull(maxReminders),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update reminder days
  Future<int> updateReminderDays(String reminderId, List<int> reminderDays) {
    return (update(progressRemindersTable)..where((t) => t.reminderId.equals(reminderId)))
        .write(ProgressRemindersTableCompanion(
      reminderDays: Value(jsonEncode(reminderDays)),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update target values (JSON)
  Future<int> updateTargetValues(String reminderId, Map<String, dynamic> targetValues) {
    return (update(progressRemindersTable)..where((t) => t.reminderId.equals(reminderId)))
        .write(ProgressRemindersTableCompanion(
      targetValuesJson: Value(jsonEncode(targetValues)),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Add tags to progress reminder
  Future<int> addTagsToProgressReminder(String reminderId, List<String> newTags) async {
    final reminder = await getProgressReminderById(reminderId);
    if (reminder != null) {
      final existingTags = (jsonDecode(reminder.tags) as List).cast<String>();
      final updatedTags = {...existingTags, ...newTags}.toList();
      
      return (update(progressRemindersTable)..where((t) => t.reminderId.equals(reminderId)))
          .write(ProgressRemindersTableCompanion(
        tags: Value(jsonEncode(updatedTags)),
        updatedAt: Value(DateTime.now()),
      ));
    }
    return 0;
  }

  // Remove tags from progress reminder
  Future<int> removeTagsFromProgressReminder(String reminderId, List<String> tagsToRemove) async {
    final reminder = await getProgressReminderById(reminderId);
    if (reminder != null) {
      final existingTags = (jsonDecode(reminder.tags) as List).cast<String>();
      final updatedTags = existingTags.where((tag) => !tagsToRemove.contains(tag)).toList();
      
      return (update(progressRemindersTable)..where((t) => t.reminderId.equals(reminderId)))
          .write(ProgressRemindersTableCompanion(
        tags: Value(jsonEncode(updatedTags)),
        updatedAt: Value(DateTime.now()),
      ));
    }
    return 0;
  }

  // Update user response and progress
  Future<int> updateUserResponseAndProgress({
    required String reminderId,
    String? userResponse,
    double? progressValue,
  }) {
    return (update(progressRemindersTable)..where((t) => t.reminderId.equals(reminderId)))
        .write(ProgressRemindersTableCompanion(
      userResponse: Value.absentIfNull(userResponse),
      progressValue: Value.absentIfNull(progressValue),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Increment reminder count
  Future<int> incrementReminderCount(String reminderId) async {
    final reminder = await getProgressReminderById(reminderId);
    if (reminder != null) {
      return (update(progressRemindersTable)..where((t) => t.reminderId.equals(reminderId)))
          .write(ProgressRemindersTableCompanion(
        reminderCount: Value(reminder.reminderCount + 1),
        updatedAt: Value(DateTime.now()),
      ));
    }
    return 0;
  }

  // Get progress reminders by type
  Future<List<ProgressReminderData>> getProgressRemindersByType(String type) {
    return (select(progressRemindersTable)
          ..where((t) => t.type.equals(type))
          ..orderBy([(t) => OrderingTerm(expression: t.scheduledTime, mode: OrderingMode.desc)]))
        .get();
  }

  // Get progress reminders by type for user
  Future<List<ProgressReminderData>> getProgressRemindersByTypeForUser(String userId, String type) {
    return (select(progressRemindersTable)
          ..where((t) => t.userId.equals(userId) & t.type.equals(type))
          ..orderBy([(t) => OrderingTerm(expression: t.scheduledTime, mode: OrderingMode.desc)]))
        .get();
  }

  // Get progress reminders by status
  Future<List<ProgressReminderData>> getProgressRemindersByStatus(String status) {
    return (select(progressRemindersTable)
          ..where((t) => t.status.equals(status))
          ..orderBy([(t) => OrderingTerm(expression: t.scheduledTime, mode: OrderingMode.desc)]))
        .get();
  }

  // Watch progress reminders by status
  Stream<List<ProgressReminderData>> watchProgressRemindersByStatus(String status) {
    return (select(progressRemindersTable)
          ..where((t) => t.status.equals(status))
          ..orderBy([(t) => OrderingTerm(expression: t.scheduledTime, mode: OrderingMode.desc)]))
        .watch();
  }

  // Get scheduled progress reminders
  Future<List<ProgressReminderData>> getScheduledProgressReminders() {
    return getProgressRemindersByStatus('scheduled');
  }

  // Watch scheduled progress reminders
  Stream<List<ProgressReminderData>> watchScheduledProgressReminders() {
    return watchProgressRemindersByStatus('scheduled');
  }

  // Get completed progress reminders
  Future<List<ProgressReminderData>> getCompletedProgressReminders() {
    return getProgressRemindersByStatus('completed');
  }

  // Get missed progress reminders
  Future<List<ProgressReminderData>> getMissedProgressReminders() {
    return getProgressRemindersByStatus('missed');
  }

  // Get progress reminders by frequency
  Future<List<ProgressReminderData>> getProgressRemindersByFrequency(String frequency) {
    return (select(progressRemindersTable)
          ..where((t) => t.frequency.equals(frequency))
          ..orderBy([(t) => OrderingTerm(expression: t.scheduledTime, mode: OrderingMode.desc)]))
        .get();
  }

  // Get progress reminders by priority
  Future<List<ProgressReminderData>> getProgressRemindersByPriority(int priority) {
    return (select(progressRemindersTable)
          ..where((t) => t.priority.equals(priority))
          ..orderBy([(t) => OrderingTerm(expression: t.scheduledTime, mode: OrderingMode.desc)]))
        .get();
  }

  // Get high priority progress reminders
  Future<List<ProgressReminderData>> getHighPriorityProgressReminders() {
    return getProgressRemindersByPriority(3);
  }

  // Get progress reminders by assignment ID
  Future<List<ProgressReminderData>> getProgressRemindersByAssignmentId(String assignmentId) {
    return (select(progressRemindersTable)
          ..where((t) => t.assignmentId.equals(assignmentId))
          ..orderBy([(t) => OrderingTerm(expression: t.scheduledTime, mode: OrderingMode.desc)]))
        .get();
  }

  // Get progress reminders by package ID
  Future<List<ProgressReminderData>> getProgressRemindersByPackageId(String packageId) {
    return (select(progressRemindersTable)
          ..where((t) => t.packageId.equals(packageId))
          ..orderBy([(t) => OrderingTerm(expression: t.scheduledTime, mode: OrderingMode.desc)]))
        .get();
  }

  // Get progress reminders by tags
  Future<List<ProgressReminderData>> getProgressRemindersByTags(List<String> tags) async {
    final allReminders = await getAllProgressReminders();
    return allReminders.where((reminder) {
      final reminderTags = (jsonDecode(reminder.tags) as List).cast<String>();
      return tags.any((tag) => reminderTags.contains(tag));
    }).toList();
  }

  // Get due progress reminders
  Future<List<ProgressReminderData>> getDueProgressReminders() {
    final now = DateTime.now();
    return (select(progressRemindersTable)
          ..where((t) => t.scheduledTime.isSmallerOrEqualValue(now) & 
                        t.status.equals('scheduled') &
                        t.isEnabled.equals(true))
          ..orderBy([(t) => OrderingTerm(expression: t.scheduledTime, mode: OrderingMode.asc)]))
        .get();
  }

  // Watch due progress reminders
  Stream<List<ProgressReminderData>> watchDueProgressReminders() {
    final now = DateTime.now();
    return (select(progressRemindersTable)
          ..where((t) => t.scheduledTime.isSmallerOrEqualValue(now) & 
                        t.status.equals('scheduled') &
                        t.isEnabled.equals(true))
          ..orderBy([(t) => OrderingTerm(expression: t.scheduledTime, mode: OrderingMode.asc)]))
        .watch();
  }

  // Get upcoming progress reminders
  Future<List<ProgressReminderData>> getUpcomingProgressReminders({int hours = 24}) {
    final now = DateTime.now();
    final futureTime = now.add(Duration(hours: hours));
    
    return (select(progressRemindersTable)
          ..where((t) => t.scheduledTime.isBetweenValues(now, futureTime) & 
                        t.status.equals('scheduled') &
                        t.isEnabled.equals(true))
          ..orderBy([(t) => OrderingTerm(expression: t.scheduledTime, mode: OrderingMode.asc)]))
        .get();
  }

  // Get progress reminders in date range
  Future<List<ProgressReminderData>> getProgressRemindersInDateRange(DateTime from, DateTime to) {
    return (select(progressRemindersTable)
          ..where((t) => t.scheduledTime.isBetweenValues(from, to))
          ..orderBy([(t) => OrderingTerm(expression: t.scheduledTime, mode: OrderingMode.desc)]))
        .get();
  }

  // Search progress reminders
  Future<List<ProgressReminderData>> searchProgressReminders(String query) {
    final lowerQuery = query.toLowerCase();
    return (select(progressRemindersTable)
          ..where((t) => t.title.lower().contains(lowerQuery) |
              t.message.lower().contains(lowerQuery) |
              t.description.lower().contains(lowerQuery) |
              t.type.lower().contains(lowerQuery)))
        .get();
  }

  // Search progress reminders for user
  Future<List<ProgressReminderData>> searchProgressRemindersForUser(String userId, String query) {
    final lowerQuery = query.toLowerCase();
    return (select(progressRemindersTable)
          ..where((t) => t.userId.equals(userId) & 
                        (t.title.lower().contains(lowerQuery) |
                         t.message.lower().contains(lowerQuery) |
                         t.description.lower().contains(lowerQuery))))
        .get();
  }

  // Get progress reminders with pagination
  Future<List<ProgressReminderData>> getProgressRemindersPaginated({
    String? userId,
    String? dietitianId,
    String? type,
    String? status,
    String? frequency,
    int? priority,
    required int limit,
    int? offset,
    String? orderBy = 'scheduledTime',
    bool ascending = false,
  }) {
    var query = select(progressRemindersTable);
    
    // Add filters
    if (userId != null) {
      query = query..where((t) => t.userId.equals(userId));
    }
    
    if (dietitianId != null) {
      query = query..where((t) => t.dietitianId.equals(dietitianId));
    }
    
    if (type != null) {
      query = query..where((t) => t.type.equals(type));
    }
    
    if (status != null) {
      query = query..where((t) => t.status.equals(status));
    }
    
    if (frequency != null) {
      query = query..where((t) => t.frequency.equals(frequency));
    }
    
    if (priority != null) {
      query = query..where((t) => t.priority.equals(priority));
    }
    
    // Add ordering
    switch (orderBy) {
      case 'scheduledTime':
        query = query..orderBy([(t) => OrderingTerm(
          expression: t.scheduledTime, 
          mode: ascending ? OrderingMode.asc : OrderingMode.desc
        )]);
        break;
      case 'createdAt':
        query = query..orderBy([(t) => OrderingTerm(
          expression: t.createdAt, 
          mode: ascending ? OrderingMode.asc : OrderingMode.desc
        )]);
        break;
      case 'priority':
        query = query..orderBy([(t) => OrderingTerm(
          expression: t.priority, 
          mode: ascending ? OrderingMode.asc : OrderingMode.desc
        )]);
        break;
      case 'title':
        query = query..orderBy([(t) => OrderingTerm(
          expression: t.title, 
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

  // Count progress reminders
  Future<int> countProgressReminders({
    String? userId,
    String? dietitianId,
    String? type,
    String? status,
    String? frequency,
    int? priority,
  }) {
    var query = selectOnly(progressRemindersTable);
    
    if (userId != null) {
      query = query..where(progressRemindersTable.userId.equals(userId));
    }
    
    if (dietitianId != null) {
      query = query..where(progressRemindersTable.dietitianId.equals(dietitianId));
    }
    
    if (type != null) {
      query = query..where(progressRemindersTable.type.equals(type));
    }
    
    if (status != null) {
      query = query..where(progressRemindersTable.status.equals(status));
    }
    
    if (frequency != null) {
      query = query..where(progressRemindersTable.frequency.equals(frequency));
    }
    
    if (priority != null) {
      query = query..where(progressRemindersTable.priority.equals(priority));
    }
    
    query = query..addColumns([progressRemindersTable.id.count()]);
    return query.map((row) => row.read(progressRemindersTable.id.count()) ?? 0).getSingle();
  }

  // Get reminder days from JSON
  Future<List<int>> getReminderDays(String reminderId) async {
    final reminder = await getProgressReminderById(reminderId);
    if (reminder != null) {
      return (jsonDecode(reminder.reminderDays) as List).cast<int>();
    }
    return [];
  }

  // Get target values from JSON
  Future<Map<String, dynamic>> getTargetValues(String reminderId) async {
    final reminder = await getProgressReminderById(reminderId);
    if (reminder != null) {
      return jsonDecode(reminder.targetValuesJson) as Map<String, dynamic>;
    }
    return {};
  }

  // Get progress reminder statistics for user
  Future<Map<String, int>> getUserProgressReminderStatistics(String userId) async {
    final totalReminders = await countProgressReminders(userId: userId);
    final scheduledReminders = await countProgressReminders(userId: userId, status: 'scheduled');
    final completedReminders = await countProgressReminders(userId: userId, status: 'completed');
    final missedReminders = await countProgressReminders(userId: userId, status: 'missed');
    
    return {
      'total': totalReminders,
      'scheduled': scheduledReminders,
      'completed': completedReminders,
      'missed': missedReminders,
    };
  }

  // Get progress reminder statistics for dietitian
  Future<Map<String, int>> getDietitianProgressReminderStatistics(String dietitianId) async {
    final totalReminders = await countProgressReminders(dietitianId: dietitianId);
    final activeReminders = await countProgressReminders(dietitianId: dietitianId, status: 'scheduled');
    final completedReminders = await countProgressReminders(dietitianId: dietitianId, status: 'completed');
    
    return {
      'total': totalReminders,
      'active': activeReminders,
      'completed': completedReminders,
    };
  }

  // Mark reminders as missed if overdue
  Future<int> markOverdueRemindersAsMissed({Duration? overdueThreshold}) {
    final threshold = overdueThreshold ?? const Duration(hours: 24);
    final overdueTime = DateTime.now().subtract(threshold);
    
    return (update(progressRemindersTable)
          ..where((t) => t.status.equals('scheduled') & 
                        t.scheduledTime.isSmallerThanValue(overdueTime)))
        .write(ProgressRemindersTableCompanion(
      status: const Value('missed'),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Auto-cancel reminders that exceeded max reminder count
  Future<int> autoCancelExcessiveReminders() {
    return (update(progressRemindersTable)
          ..where((t) => const CustomExpression<bool>('reminder_count >= max_reminders')))
        .write(ProgressRemindersTableCompanion(
      status: const Value('cancelled'),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Delete progress reminders for user
  Future<int> deleteProgressRemindersForUser(String userId) {
    return (delete(progressRemindersTable)..where((t) => t.userId.equals(userId))).go();
  }

  // Delete progress reminders by dietitian
  Future<int> deleteProgressRemindersByDietitian(String dietitianId) {
    return (delete(progressRemindersTable)..where((t) => t.dietitianId.equals(dietitianId))).go();
  }

  // Delete progress reminders by assignment
  Future<int> deleteProgressRemindersByAssignment(String assignmentId) {
    return (delete(progressRemindersTable)..where((t) => t.assignmentId.equals(assignmentId))).go();
  }

  // Delete progress reminders by package
  Future<int> deleteProgressRemindersByPackage(String packageId) {
    return (delete(progressRemindersTable)..where((t) => t.packageId.equals(packageId))).go();
  }

  // Clear old progress reminders
  Future<int> clearOldProgressReminders({Duration? olderThan}) {
    final thresholdTime = olderThan != null 
        ? DateTime.now().subtract(olderThan)
        : DateTime.now().subtract(const Duration(days: 90));
        
    return (delete(progressRemindersTable)
          ..where((t) => t.createdAt.isSmallerThanValue(thresholdTime) & 
                        (t.status.equals('completed') | t.status.equals('cancelled'))))
        .go();
  }

  // Clear all progress reminders
  Future<int> clearAll() {
    return delete(progressRemindersTable).go();
  }
}