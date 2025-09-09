import 'package:drift/drift.dart';

@DataClassName('ProgressReminderData')
class ProgressRemindersTable extends Table {
  @override
  String get tableName => 'progress_reminders';

  // Primary key
  IntColumn get id => integer().autoIncrement()();

  // Unique identifier
  TextColumn get reminderId => text().unique()();

  // User reference
  TextColumn get userId => text()();

  // Dietitian reference (if set by dietitian)
  TextColumn get dietitianId => text().nullable()();

  // Reminder type and frequency - stored as strings
  TextColumn get type => text()(); // weightUpdate, dietAdherence, milestone, weeklyProgress, monthlyAssessment, waterIntake, exerciseLog, moodTracker
  TextColumn get frequency => text().withDefault(const Constant('weekly'))(); // daily, weekly, biweekly, monthly, custom

  // Content and message
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get message => text().withDefault(const Constant(''))();
  TextColumn get description => text().withDefault(const Constant(''))();

  // Scheduling information
  DateTimeColumn get scheduledTime => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deliveredAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get dismissedAt => dateTime().nullable()();

  // Status information - stored as string
  TextColumn get status => text().withDefault(const Constant('scheduled'))(); // scheduled, delivered, completed, dismissed, missed, cancelled

  // Settings
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
  IntColumn get notificationId => integer().withDefault(const Constant(0))(); // Local notification ID

  // Repeat settings
  IntColumn get customIntervalDays => integer().nullable()(); // Custom period days count
  TextColumn get reminderDays => text().withDefault(const Constant('[]'))(); // Which days to remind (1=Monday, 7=Sunday) - List<int> as JSON

  // Priority and categories
  IntColumn get priority => integer().withDefault(const Constant(1))(); // 1 = low, 2 = medium, 3 = high
  TextColumn get tags => text().withDefault(const Constant('[]'))(); // List<String> as JSON

  // Related data
  TextColumn get assignmentId => text().nullable()(); // Diet assignment ID
  TextColumn get packageId => text().nullable()(); // Diet package ID

  // Target values (weight target, water intake etc.) - stored as JSON string
  TextColumn get targetValuesJson => text().withDefault(const Constant('{}'))();

  // User interaction
  IntColumn get reminderCount => integer().withDefault(const Constant(0))(); // How many times reminded
  IntColumn get maxReminders => integer().withDefault(const Constant(3))(); // Maximum reminder count

  // Analytics data
  TextColumn get userResponse => text().nullable()(); // User response
  RealColumn get progressValue => real().nullable()(); // Progress value (0.0-1.0)

  // Timestamps
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}