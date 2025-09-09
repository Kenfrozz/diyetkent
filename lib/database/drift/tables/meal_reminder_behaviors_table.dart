import 'package:drift/drift.dart';

@DataClassName('MealReminderBehaviorData')
class MealReminderBehaviorsTable extends Table {
  @override
  String get tableName => 'meal_reminder_behaviors';

  // Primary key
  IntColumn get id => integer().autoIncrement()();

  // User reference
  TextColumn get userId => text()();

  // Unique behavior identifier
  TextColumn get behaviorId => text()();

  // Session identifier for grouping interactions
  TextColumn get sessionId => text()();

  // Reminder details
  TextColumn get mealType => text()(); // breakfast, lunch, dinner, snack

  DateTimeColumn get reminderTime => dateTime().withDefault(currentDateAndTime)(); // when reminder was sent
  DateTimeColumn get interactionTime => dateTime().nullable()(); // when user interacted

  TextColumn get actionType => text().withDefault(const Constant('ignored'))(); // completed, dismissed, snoozed, ignored

  // Context information
  IntColumn get dayOfWeek => integer().withDefault(const Constant(1))(); // 1=Monday, 7=Sunday
  IntColumn get hourOfDay => integer().withDefault(const Constant(12))(); // 0-23
  BoolColumn get isWeekend => boolean().withDefault(const Constant(false))();

  // Behavioral insights
  IntColumn get responseDelayMinutes => integer().withDefault(const Constant(0))(); // how long to respond
  BoolColumn get wasOnTime => boolean().withDefault(const Constant(false))(); // completed at expected time
  BoolColumn get wasEarly => boolean().withDefault(const Constant(false))(); // completed before reminder
  BoolColumn get wasLate => boolean().withDefault(const Constant(false))(); // completed after reminder

  // Effectiveness metrics
  RealColumn get engagementScore => real().withDefault(const Constant(0.0))(); // 0.0 to 1.0 based on interaction quality
  RealColumn get satisfactionScore => real().withDefault(const Constant(0.0))(); // inferred satisfaction

  // Device/context information
  TextColumn get deviceType => text().nullable()(); // phone, tablet, etc.
  TextColumn get appVersion => text().nullable()();
  BoolColumn get wasAppInForeground => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('UserBehaviorAnalyticsData')
class UserBehaviorAnalyticsTable extends Table {
  @override
  String get tableName => 'user_behavior_analytics';

  // Primary key
  IntColumn get id => integer().autoIncrement()();

  // Unique identifier
  TextColumn get userId => text().unique()();

  // Time period for this analysis
  DateTimeColumn get periodStart => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get periodEnd => dateTime().withDefault(currentDateAndTime)();

  // Overall engagement metrics
  RealColumn get overallEngagementScore => real().withDefault(const Constant(0.0))();
  IntColumn get totalReminders => integer().withDefault(const Constant(0))();
  IntColumn get totalInteractions => integer().withDefault(const Constant(0))();
  RealColumn get interactionRate => real().withDefault(const Constant(0.0))(); // percentage of reminders that got interaction

  // Per-meal analytics
  RealColumn get breakfastEngagement => real().withDefault(const Constant(0.0))();
  RealColumn get lunchEngagement => real().withDefault(const Constant(0.0))();
  RealColumn get dinnerEngagement => real().withDefault(const Constant(0.0))();
  RealColumn get snackEngagement => real().withDefault(const Constant(0.0))();

  IntColumn get breakfastCount => integer().withDefault(const Constant(0))();
  IntColumn get lunchCount => integer().withDefault(const Constant(0))();
  IntColumn get dinnerCount => integer().withDefault(const Constant(0))();
  IntColumn get snackCount => integer().withDefault(const Constant(0))();

  // Timing patterns (stored as JSON strings for compatibility)
  TextColumn get hourlyEngagementJson => text().withDefault(const Constant('{}'))(); // hour -> engagement score
  TextColumn get dailyEngagementJson => text().withDefault(const Constant('{}'))(); // day of week -> engagement score

  // Behavioral insights
  RealColumn get averageResponseTime => real().withDefault(const Constant(0.0))(); // minutes
  RealColumn get onTimeRate => real().withDefault(const Constant(0.0))(); // percentage of meals completed on time
  RealColumn get skipRate => real().withDefault(const Constant(0.0))(); // percentage of meals skipped
  RealColumn get snoozeRate => real().withDefault(const Constant(0.0))(); // percentage of reminders snoozed

  // Predicted optimal times (learned) - stored as total minutes from midnight
  IntColumn get breakfastTimeMinutes => integer().withDefault(const Constant(0))(); // 0 means no optimal time learned
  IntColumn get lunchTimeMinutes => integer().withDefault(const Constant(0))();
  IntColumn get dinnerTimeMinutes => integer().withDefault(const Constant(0))();
  IntColumn get snackTimeMinutes => integer().withDefault(const Constant(0))();

  // Confidence scores for predictions (0.0 to 1.0)
  RealColumn get breakfastPredictionConfidence => real().withDefault(const Constant(0.0))();
  RealColumn get lunchPredictionConfidence => real().withDefault(const Constant(0.0))();
  RealColumn get dinnerPredictionConfidence => real().withDefault(const Constant(0.0))();
  RealColumn get snackPredictionConfidence => real().withDefault(const Constant(0.0))();

  // Timestamps
  DateTimeColumn get lastAnalyzedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  // Learning parameters
  RealColumn get currentTrend => real().withDefault(const Constant(0.0))(); // trend direction: positive = improving, negative = declining
  RealColumn get consistency => real().withDefault(const Constant(0.0))(); // how consistent the user is (0.0 to 1.0)
}