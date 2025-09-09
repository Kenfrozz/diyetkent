import 'dart:convert';
import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/meal_reminder_preferences_table.dart';
import '../tables/meal_reminder_behaviors_table.dart';

part 'meal_reminder_dao.g.dart';

@DriftAccessor(tables: [MealReminderPreferencesTable, MealReminderBehaviorsTable, UserBehaviorAnalyticsTable])
class MealReminderDao extends DatabaseAccessor<AppDatabase> with _$MealReminderDaoMixin {
  MealReminderDao(super.db);

  // ============ MEAL REMINDER PREFERENCES ============

  // Get meal reminder preferences by user ID
  Future<MealReminderPreferencesData?> getMealReminderPreferences(String userId) {
    return (select(mealReminderPreferencesTable)..where((t) => t.userId.equals(userId))).getSingleOrNull();
  }

  // Watch meal reminder preferences by user ID
  Stream<MealReminderPreferencesData?> watchMealReminderPreferences(String userId) {
    return (select(mealReminderPreferencesTable)..where((t) => t.userId.equals(userId))).watchSingleOrNull();
  }

  // Save or update meal reminder preferences
  Future<int> saveMealReminderPreferences(MealReminderPreferencesTableCompanion preferences) {
    return into(mealReminderPreferencesTable).insertOnConflictUpdate(preferences);
  }

  // Update meal reminder preferences
  Future<bool> updateMealReminderPreferences(MealReminderPreferencesTableCompanion preferences) {
    return update(mealReminderPreferencesTable).replace(preferences);
  }

  // Update meal times
  Future<int> updateMealTimes({
    required String userId,
    int? breakfastHour,
    int? breakfastMinute,
    int? lunchHour,
    int? lunchMinute,
    int? dinnerHour,
    int? dinnerMinute,
    int? snackHour,
    int? snackMinute,
  }) {
    return (update(mealReminderPreferencesTable)..where((t) => t.userId.equals(userId)))
        .write(MealReminderPreferencesTableCompanion(
      breakfastHour: Value.absentIfNull(breakfastHour),
      breakfastMinute: Value.absentIfNull(breakfastMinute),
      lunchHour: Value.absentIfNull(lunchHour),
      lunchMinute: Value.absentIfNull(lunchMinute),
      dinnerHour: Value.absentIfNull(dinnerHour),
      dinnerMinute: Value.absentIfNull(dinnerMinute),
      snackHour: Value.absentIfNull(snackHour),
      snackMinute: Value.absentIfNull(snackMinute),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update reminder enabled status
  Future<int> updateReminderEnabled({
    required String userId,
    bool? isReminderEnabled,
    bool? isBreakfastReminderEnabled,
    bool? isLunchReminderEnabled,
    bool? isDinnerReminderEnabled,
    bool? isSnackReminderEnabled,
  }) {
    return (update(mealReminderPreferencesTable)..where((t) => t.userId.equals(userId)))
        .write(MealReminderPreferencesTableCompanion(
      isReminderEnabled: Value.absentIfNull(isReminderEnabled),
      isBreakfastReminderEnabled: Value.absentIfNull(isBreakfastReminderEnabled),
      isLunchReminderEnabled: Value.absentIfNull(isLunchReminderEnabled),
      isDinnerReminderEnabled: Value.absentIfNull(isDinnerReminderEnabled),
      isSnackReminderEnabled: Value.absentIfNull(isSnackReminderEnabled),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update reminder days
  Future<int> updateReminderDays(String userId, List<int> reminderDays) {
    return (update(mealReminderPreferencesTable)..where((t) => t.userId.equals(userId)))
        .write(MealReminderPreferencesTableCompanion(
      reminderDays: Value(jsonEncode(reminderDays)),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update sound and vibration settings
  Future<int> updateSoundAndVibration({
    required String userId,
    bool? isSoundEnabled,
    bool? isVibrationEnabled,
  }) {
    return (update(mealReminderPreferencesTable)..where((t) => t.userId.equals(userId)))
        .write(MealReminderPreferencesTableCompanion(
      isSoundEnabled: Value.absentIfNull(isSoundEnabled),
      isVibrationEnabled: Value.absentIfNull(isVibrationEnabled),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update advance reminder and snooze settings
  Future<int> updateAdvanceAndSnoozeSettings({
    required String userId,
    int? beforeMealMinutes,
    int? autoSnoozeMinutes,
    int? maxSnoozeCount,
  }) {
    return (update(mealReminderPreferencesTable)..where((t) => t.userId.equals(userId)))
        .write(MealReminderPreferencesTableCompanion(
      beforeMealMinutes: Value.absentIfNull(beforeMealMinutes),
      autoSnoozeMinutes: Value.absentIfNull(autoSnoozeMinutes),
      maxSnoozeCount: Value.absentIfNull(maxSnoozeCount),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update custom messages
  Future<int> updateCustomMessages({
    required String userId,
    bool? usePersonalizedMessages,
    String? customBreakfastMessage,
    String? customLunchMessage,
    String? customDinnerMessage,
    String? customSnackMessage,
  }) {
    return (update(mealReminderPreferencesTable)..where((t) => t.userId.equals(userId)))
        .write(MealReminderPreferencesTableCompanion(
      usePersonalizedMessages: Value.absentIfNull(usePersonalizedMessages),
      customBreakfastMessage: Value.absentIfNull(customBreakfastMessage),
      customLunchMessage: Value.absentIfNull(customLunchMessage),
      customDinnerMessage: Value.absentIfNull(customDinnerMessage),
      customSnackMessage: Value.absentIfNull(customSnackMessage),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update behavioral learning data
  Future<int> updateBehavioralLearningData({
    required String userId,
    int? breakfastCompletionCount,
    int? lunchCompletionCount,
    int? dinnerCompletionCount,
    int? snackCompletionCount,
    int? breakfastSkipCount,
    int? lunchSkipCount,
    int? dinnerSkipCount,
    int? snackSkipCount,
  }) {
    return (update(mealReminderPreferencesTable)..where((t) => t.userId.equals(userId)))
        .write(MealReminderPreferencesTableCompanion(
      breakfastCompletionCount: Value.absentIfNull(breakfastCompletionCount),
      lunchCompletionCount: Value.absentIfNull(lunchCompletionCount),
      dinnerCompletionCount: Value.absentIfNull(dinnerCompletionCount),
      snackCompletionCount: Value.absentIfNull(snackCompletionCount),
      breakfastSkipCount: Value.absentIfNull(breakfastSkipCount),
      lunchSkipCount: Value.absentIfNull(lunchSkipCount),
      dinnerSkipCount: Value.absentIfNull(dinnerSkipCount),
      snackSkipCount: Value.absentIfNull(snackSkipCount),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update last meal times
  Future<int> updateLastMealTimes({
    required String userId,
    DateTime? lastBreakfastTime,
    DateTime? lastLunchTime,
    DateTime? lastDinnerTime,
    DateTime? lastSnackTime,
  }) {
    return (update(mealReminderPreferencesTable)..where((t) => t.userId.equals(userId)))
        .write(MealReminderPreferencesTableCompanion(
      lastBreakfastTime: Value.absentIfNull(lastBreakfastTime),
      lastLunchTime: Value.absentIfNull(lastLunchTime),
      lastDinnerTime: Value.absentIfNull(lastDinnerTime),
      lastSnackTime: Value.absentIfNull(lastSnackTime),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update learned meal times
  Future<int> updateLearnedMealTimes({
    required String userId,
    double? learnedBreakfastHour,
    double? learnedLunchHour,
    double? learnedDinnerHour,
    double? learnedSnackHour,
  }) {
    return (update(mealReminderPreferencesTable)..where((t) => t.userId.equals(userId)))
        .write(MealReminderPreferencesTableCompanion(
      learnedBreakfastHour: Value.absentIfNull(learnedBreakfastHour),
      learnedLunchHour: Value.absentIfNull(learnedLunchHour),
      learnedDinnerHour: Value.absentIfNull(learnedDinnerHour),
      learnedSnackHour: Value.absentIfNull(learnedSnackHour),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Get reminder days from JSON
  Future<List<int>> getReminderDays(String userId) async {
    final preferences = await getMealReminderPreferences(userId);
    if (preferences != null) {
      return (jsonDecode(preferences.reminderDays) as List).cast<int>();
    }
    return [1, 2, 3, 4, 5, 6, 7]; // Default: all days
  }

  // Increment meal completion count
  Future<int> incrementMealCompletion(String userId, String mealType) async {
    final preferences = await getMealReminderPreferences(userId);
    if (preferences != null) {
      switch (mealType.toLowerCase()) {
        case 'breakfast':
          return updateBehavioralLearningData(
            userId: userId,
            breakfastCompletionCount: preferences.breakfastCompletionCount + 1,
          );
        case 'lunch':
          return updateBehavioralLearningData(
            userId: userId,
            lunchCompletionCount: preferences.lunchCompletionCount + 1,
          );
        case 'dinner':
          return updateBehavioralLearningData(
            userId: userId,
            dinnerCompletionCount: preferences.dinnerCompletionCount + 1,
          );
        case 'snack':
          return updateBehavioralLearningData(
            userId: userId,
            snackCompletionCount: preferences.snackCompletionCount + 1,
          );
      }
    }
    return 0;
  }

  // Increment meal skip count
  Future<int> incrementMealSkip(String userId, String mealType) async {
    final preferences = await getMealReminderPreferences(userId);
    if (preferences != null) {
      switch (mealType.toLowerCase()) {
        case 'breakfast':
          return updateBehavioralLearningData(
            userId: userId,
            breakfastSkipCount: preferences.breakfastSkipCount + 1,
          );
        case 'lunch':
          return updateBehavioralLearningData(
            userId: userId,
            lunchSkipCount: preferences.lunchSkipCount + 1,
          );
        case 'dinner':
          return updateBehavioralLearningData(
            userId: userId,
            dinnerSkipCount: preferences.dinnerSkipCount + 1,
          );
        case 'snack':
          return updateBehavioralLearningData(
            userId: userId,
            snackSkipCount: preferences.snackSkipCount + 1,
          );
      }
    }
    return 0;
  }

  // Create default meal reminder preferences
  Future<int> createDefaultMealReminderPreferences(String userId) {
    final companion = MealReminderPreferencesTableCompanion(
      userId: Value(userId),
      breakfastHour: const Value(8),
      breakfastMinute: const Value(0),
      lunchHour: const Value(12),
      lunchMinute: const Value(30),
      dinnerHour: const Value(19),
      dinnerMinute: const Value(0),
      snackHour: const Value(15),
      snackMinute: const Value(30),
      reminderDays: const Value('[1,2,3,4,5,6,7]'),
      isBreakfastReminderEnabled: const Value(true),
      isLunchReminderEnabled: const Value(true),
      isDinnerReminderEnabled: const Value(true),
      isSnackReminderEnabled: const Value(true),
      isReminderEnabled: const Value(true),
      isSoundEnabled: const Value(true),
      isVibrationEnabled: const Value(true),
      beforeMealMinutes: const Value(0),
      autoSnoozeMinutes: const Value(15),
      maxSnoozeCount: const Value(3),
      usePersonalizedMessages: const Value(true),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    );
    
    return saveMealReminderPreferences(companion);
  }

  // Delete meal reminder preferences
  Future<int> deleteMealReminderPreferences(String userId) {
    return (delete(mealReminderPreferencesTable)..where((t) => t.userId.equals(userId))).go();
  }

  // ============ MEAL REMINDER BEHAVIORS ============

  // Get all meal reminder behaviors
  Future<List<MealReminderBehaviorData>> getAllMealReminderBehaviors() {
    return (select(mealReminderBehaviorsTable)
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Get meal reminder behaviors by user ID
  Future<List<MealReminderBehaviorData>> getMealReminderBehaviorsByUserId(String userId) {
    return (select(mealReminderBehaviorsTable)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Get meal reminder behavior by ID
  Future<MealReminderBehaviorData?> getMealReminderBehaviorById(int id) {
    return (select(mealReminderBehaviorsTable)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  // Save meal reminder behavior
  Future<int> saveMealReminderBehavior(MealReminderBehaviorsTableCompanion behavior) {
    return into(mealReminderBehaviorsTable).insert(behavior);
  }

  // Batch save meal reminder behaviors
  Future<void> saveMealReminderBehaviors(List<MealReminderBehaviorsTableCompanion> behaviorList) async {
    await batch((batch) {
      batch.insertAll(mealReminderBehaviorsTable, behaviorList);
    });
  }

  // Update meal reminder behavior
  Future<bool> updateMealReminderBehavior(MealReminderBehaviorsTableCompanion behavior) {
    return update(mealReminderBehaviorsTable).replace(behavior);
  }

  // Delete meal reminder behavior
  Future<int> deleteMealReminderBehavior(int id) {
    return (delete(mealReminderBehaviorsTable)..where((t) => t.id.equals(id))).go();
  }

  // Get behaviors by meal type
  Future<List<MealReminderBehaviorData>> getBehaviorsByMealType(String userId, String mealType) {
    return (select(mealReminderBehaviorsTable)
          ..where((t) => t.userId.equals(userId) & t.mealType.equals(mealType))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Get behaviors by action type
  Future<List<MealReminderBehaviorData>> getBehaviorsByActionType(String userId, String actionType) {
    return (select(mealReminderBehaviorsTable)
          ..where((t) => t.userId.equals(userId) & t.actionType.equals(actionType))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Get behaviors in date range
  Future<List<MealReminderBehaviorData>> getBehaviorsInDateRange(
    String userId, 
    DateTime from, 
    DateTime to,
  ) {
    return (select(mealReminderBehaviorsTable)
          ..where((t) => t.userId.equals(userId) & 
                        t.reminderTime.isBetweenValues(from, to))
          ..orderBy([(t) => OrderingTerm(expression: t.reminderTime, mode: OrderingMode.desc)]))
        .get();
  }

  // Get recent behaviors
  Future<List<MealReminderBehaviorData>> getRecentBehaviors(String userId, {int days = 7}) {
    final since = DateTime.now().subtract(Duration(days: days));
    return getBehaviorsInDateRange(userId, since, DateTime.now());
  }

  // Delete old behaviors
  Future<int> deleteOldBehaviors({Duration? olderThan}) {
    final thresholdTime = olderThan != null 
        ? DateTime.now().subtract(olderThan)
        : DateTime.now().subtract(const Duration(days: 90));
        
    return (delete(mealReminderBehaviorsTable)
          ..where((t) => t.createdAt.isSmallerThanValue(thresholdTime)))
        .go();
  }

  // ============ USER BEHAVIOR ANALYTICS ============

  // Get user behavior analytics
  Future<UserBehaviorAnalyticsData?> getUserBehaviorAnalytics(String userId) {
    return (select(userBehaviorAnalyticsTable)..where((t) => t.userId.equals(userId))).getSingleOrNull();
  }

  // Watch user behavior analytics
  Stream<UserBehaviorAnalyticsData?> watchUserBehaviorAnalytics(String userId) {
    return (select(userBehaviorAnalyticsTable)..where((t) => t.userId.equals(userId))).watchSingleOrNull();
  }

  // Save or update user behavior analytics
  Future<int> saveUserBehaviorAnalytics(UserBehaviorAnalyticsTableCompanion analytics) {
    return into(userBehaviorAnalyticsTable).insertOnConflictUpdate(analytics);
  }

  // Update user behavior analytics
  Future<bool> updateUserBehaviorAnalytics(UserBehaviorAnalyticsTableCompanion analytics) {
    return update(userBehaviorAnalyticsTable).replace(analytics);
  }

  // Update overall engagement metrics
  Future<int> updateOverallEngagementMetrics({
    required String userId,
    double? overallEngagementScore,
    int? totalReminders,
    int? totalInteractions,
    double? interactionRate,
  }) {
    return (update(userBehaviorAnalyticsTable)..where((t) => t.userId.equals(userId)))
        .write(UserBehaviorAnalyticsTableCompanion(
      overallEngagementScore: Value.absentIfNull(overallEngagementScore),
      totalReminders: Value.absentIfNull(totalReminders),
      totalInteractions: Value.absentIfNull(totalInteractions),
      interactionRate: Value.absentIfNull(interactionRate),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update per-meal analytics
  Future<int> updatePerMealAnalytics({
    required String userId,
    double? breakfastEngagement,
    double? lunchEngagement,
    double? dinnerEngagement,
    double? snackEngagement,
    int? breakfastCount,
    int? lunchCount,
    int? dinnerCount,
    int? snackCount,
  }) {
    return (update(userBehaviorAnalyticsTable)..where((t) => t.userId.equals(userId)))
        .write(UserBehaviorAnalyticsTableCompanion(
      breakfastEngagement: Value.absentIfNull(breakfastEngagement),
      lunchEngagement: Value.absentIfNull(lunchEngagement),
      dinnerEngagement: Value.absentIfNull(dinnerEngagement),
      snackEngagement: Value.absentIfNull(snackEngagement),
      breakfastCount: Value.absentIfNull(breakfastCount),
      lunchCount: Value.absentIfNull(lunchCount),
      dinnerCount: Value.absentIfNull(dinnerCount),
      snackCount: Value.absentIfNull(snackCount),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update timing patterns (JSON)
  Future<int> updateTimingPatterns({
    required String userId,
    Map<String, dynamic>? hourlyEngagement,
    Map<String, dynamic>? dailyEngagement,
  }) {
    return (update(userBehaviorAnalyticsTable)..where((t) => t.userId.equals(userId)))
        .write(UserBehaviorAnalyticsTableCompanion(
      hourlyEngagementJson: hourlyEngagement != null ? Value(jsonEncode(hourlyEngagement)) : const Value.absent(),
      dailyEngagementJson: dailyEngagement != null ? Value(jsonEncode(dailyEngagement)) : const Value.absent(),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update behavioral insights
  Future<int> updateBehavioralInsights({
    required String userId,
    double? averageResponseTime,
    double? onTimeRate,
    double? skipRate,
    double? snoozeRate,
  }) {
    return (update(userBehaviorAnalyticsTable)..where((t) => t.userId.equals(userId)))
        .write(UserBehaviorAnalyticsTableCompanion(
      averageResponseTime: Value.absentIfNull(averageResponseTime),
      onTimeRate: Value.absentIfNull(onTimeRate),
      skipRate: Value.absentIfNull(skipRate),
      snoozeRate: Value.absentIfNull(snoozeRate),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update predicted optimal times
  Future<int> updateOptimalTimes({
    required String userId,
    int? breakfastTimeMinutes,
    int? lunchTimeMinutes,
    int? dinnerTimeMinutes,
    int? snackTimeMinutes,
    double? breakfastPredictionConfidence,
    double? lunchPredictionConfidence,
    double? dinnerPredictionConfidence,
    double? snackPredictionConfidence,
  }) {
    return (update(userBehaviorAnalyticsTable)..where((t) => t.userId.equals(userId)))
        .write(UserBehaviorAnalyticsTableCompanion(
      breakfastTimeMinutes: Value.absentIfNull(breakfastTimeMinutes),
      lunchTimeMinutes: Value.absentIfNull(lunchTimeMinutes),
      dinnerTimeMinutes: Value.absentIfNull(dinnerTimeMinutes),
      snackTimeMinutes: Value.absentIfNull(snackTimeMinutes),
      breakfastPredictionConfidence: Value.absentIfNull(breakfastPredictionConfidence),
      lunchPredictionConfidence: Value.absentIfNull(lunchPredictionConfidence),
      dinnerPredictionConfidence: Value.absentIfNull(dinnerPredictionConfidence),
      snackPredictionConfidence: Value.absentIfNull(snackPredictionConfidence),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update learning parameters
  Future<int> updateLearningParameters({
    required String userId,
    double? currentTrend,
    double? consistency,
  }) {
    return (update(userBehaviorAnalyticsTable)..where((t) => t.userId.equals(userId)))
        .write(UserBehaviorAnalyticsTableCompanion(
      currentTrend: Value.absentIfNull(currentTrend),
      consistency: Value.absentIfNull(consistency),
      lastAnalyzedAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Get hourly engagement from JSON
  Future<Map<String, dynamic>> getHourlyEngagement(String userId) async {
    final analytics = await getUserBehaviorAnalytics(userId);
    if (analytics != null) {
      return jsonDecode(analytics.hourlyEngagementJson) as Map<String, dynamic>;
    }
    return {};
  }

  // Get daily engagement from JSON
  Future<Map<String, dynamic>> getDailyEngagement(String userId) async {
    final analytics = await getUserBehaviorAnalytics(userId);
    if (analytics != null) {
      return jsonDecode(analytics.dailyEngagementJson) as Map<String, dynamic>;
    }
    return {};
  }

  // Create default user behavior analytics
  Future<int> createDefaultUserBehaviorAnalytics(String userId) {
    final now = DateTime.now();
    final companion = UserBehaviorAnalyticsTableCompanion(
      userId: Value(userId),
      periodStart: Value(now),
      periodEnd: Value(now.add(const Duration(days: 30))),
      overallEngagementScore: const Value(0.0),
      totalReminders: const Value(0),
      totalInteractions: const Value(0),
      interactionRate: const Value(0.0),
      breakfastEngagement: const Value(0.0),
      lunchEngagement: const Value(0.0),
      dinnerEngagement: const Value(0.0),
      snackEngagement: const Value(0.0),
      breakfastCount: const Value(0),
      lunchCount: const Value(0),
      dinnerCount: const Value(0),
      snackCount: const Value(0),
      hourlyEngagementJson: const Value('{}'),
      dailyEngagementJson: const Value('{}'),
      averageResponseTime: const Value(0.0),
      onTimeRate: const Value(0.0),
      skipRate: const Value(0.0),
      snoozeRate: const Value(0.0),
      breakfastTimeMinutes: const Value(0),
      lunchTimeMinutes: const Value(0),
      dinnerTimeMinutes: const Value(0),
      snackTimeMinutes: const Value(0),
      breakfastPredictionConfidence: const Value(0.0),
      lunchPredictionConfidence: const Value(0.0),
      dinnerPredictionConfidence: const Value(0.0),
      snackPredictionConfidence: const Value(0.0),
      lastAnalyzedAt: Value(now),
      updatedAt: Value(now),
      currentTrend: const Value(0.0),
      consistency: const Value(0.0),
    );
    
    return saveUserBehaviorAnalytics(companion);
  }

  // Delete user behavior analytics
  Future<int> deleteUserBehaviorAnalytics(String userId) {
    return (delete(userBehaviorAnalyticsTable)..where((t) => t.userId.equals(userId))).go();
  }

  // Delete meal reminder behaviors for user
  Future<int> deleteMealReminderBehaviorsForUser(String userId) {
    return (delete(mealReminderBehaviorsTable)..where((t) => t.userId.equals(userId))).go();
  }

  // Clear all data for user
  Future<void> clearAllDataForUser(String userId) async {
    await deleteMealReminderPreferences(userId);
    await deleteMealReminderBehaviorsForUser(userId);
    await deleteUserBehaviorAnalytics(userId);
  }

  // Clear all meal reminder data
  Future<void> clearAll() async {
    await delete(mealReminderPreferencesTable).go();
    await delete(mealReminderBehaviorsTable).go();
    await delete(userBehaviorAnalyticsTable).go();
  }
}