import 'package:drift/drift.dart';

@DataClassName('MealReminderPreferencesData')
class MealReminderPreferencesTable extends Table {
  @override
  String get tableName => 'meal_reminder_preferences';

  // Primary key
  IntColumn get id => integer().autoIncrement()();

  // Unique identifier
  TextColumn get userId => text().unique()();

  // Meal times
  IntColumn get breakfastHour => integer().withDefault(const Constant(8))();
  IntColumn get breakfastMinute => integer().withDefault(const Constant(0))();
  IntColumn get lunchHour => integer().withDefault(const Constant(12))();
  IntColumn get lunchMinute => integer().withDefault(const Constant(30))();
  IntColumn get dinnerHour => integer().withDefault(const Constant(19))();
  IntColumn get dinnerMinute => integer().withDefault(const Constant(0))();
  IntColumn get snackHour => integer().withDefault(const Constant(15))();
  IntColumn get snackMinute => integer().withDefault(const Constant(30))();

  // Reminder days (1=Monday, 7=Sunday) - stored as JSON string
  TextColumn get reminderDays => text().withDefault(const Constant('[1,2,3,4,5,6,7]'))(); // List<int> as JSON

  // Reminder active/passive status
  BoolColumn get isBreakfastReminderEnabled => boolean().withDefault(const Constant(true))();
  BoolColumn get isLunchReminderEnabled => boolean().withDefault(const Constant(true))();
  BoolColumn get isDinnerReminderEnabled => boolean().withDefault(const Constant(true))();
  BoolColumn get isSnackReminderEnabled => boolean().withDefault(const Constant(true))();

  // General reminder on/off
  BoolColumn get isReminderEnabled => boolean().withDefault(const Constant(true))();

  // Sound and vibration settings
  BoolColumn get isSoundEnabled => boolean().withDefault(const Constant(true))();
  BoolColumn get isVibrationEnabled => boolean().withDefault(const Constant(true))();

  // Advance reminder (minutes)
  IntColumn get beforeMealMinutes => integer().withDefault(const Constant(0))(); // 0=on time, 15=15min before

  // Auto snooze settings
  IntColumn get autoSnoozeMinutes => integer().withDefault(const Constant(15))();
  IntColumn get maxSnoozeCount => integer().withDefault(const Constant(3))();

  // Personalized messages
  BoolColumn get usePersonalizedMessages => boolean().withDefault(const Constant(true))();
  TextColumn get customBreakfastMessage => text().nullable()();
  TextColumn get customLunchMessage => text().nullable()();
  TextColumn get customDinnerMessage => text().nullable()();
  TextColumn get customSnackMessage => text().nullable()();

  // Behavioral learning data
  IntColumn get breakfastCompletionCount => integer().withDefault(const Constant(0))();
  IntColumn get lunchCompletionCount => integer().withDefault(const Constant(0))();
  IntColumn get dinnerCompletionCount => integer().withDefault(const Constant(0))();
  IntColumn get snackCompletionCount => integer().withDefault(const Constant(0))();

  IntColumn get breakfastSkipCount => integer().withDefault(const Constant(0))();
  IntColumn get lunchSkipCount => integer().withDefault(const Constant(0))();
  IntColumn get dinnerSkipCount => integer().withDefault(const Constant(0))();
  IntColumn get snackSkipCount => integer().withDefault(const Constant(0))();

  // Last update times
  DateTimeColumn get lastBreakfastTime => dateTime().nullable()();
  DateTimeColumn get lastLunchTime => dateTime().nullable()();
  DateTimeColumn get lastDinnerTime => dateTime().nullable()();
  DateTimeColumn get lastSnackTime => dateTime().nullable()();

  // Average meal times (learned)
  RealColumn get learnedBreakfastHour => real().nullable()();
  RealColumn get learnedLunchHour => real().nullable()();
  RealColumn get learnedDinnerHour => real().nullable()();
  RealColumn get learnedSnackHour => real().nullable()();

  // Timestamps
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}