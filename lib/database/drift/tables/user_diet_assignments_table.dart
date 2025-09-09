import 'package:drift/drift.dart';

@DataClassName('UserDietAssignmentData')
class UserDietAssignmentsTable extends Table {
  @override
  String get tableName => 'user_diet_assignments';

  // Primary key
  IntColumn get id => integer().autoIncrement()();

  // Unique identifier
  TextColumn get assignmentId => text().unique()();

  // References
  TextColumn get userId => text()(); // assigned user
  TextColumn get packageId => text()(); // diet package ID
  TextColumn get dietitianId => text()(); // assigning dietitian

  // Date information
  DateTimeColumn get startDate => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get endDate => dateTime()();

  // Status - stored as string
  TextColumn get status => text().withDefault(const Constant('active'))(); // active, paused, completed, cancelled, expired

  // Progress tracking
  RealColumn get progress => real().withDefault(const Constant(0.0))(); // 0.0 - 1.0
  IntColumn get completedDays => integer().withDefault(const Constant(0))();
  IntColumn get totalDays => integer().withDefault(const Constant(0))();

  // Personal settings (stored as JSON string)
  TextColumn get customSettings => text().withDefault(const Constant('{}'))(); // {"dailyCalories": 1800, "waterGoal": 2.5}

  // Notes and feedback
  TextColumn get dietitianNotes => text().nullable()(); // dietitian's notes
  TextColumn get userNotes => text().nullable()(); // user's notes

  // Statistics
  RealColumn get weightStart => real().withDefault(const Constant(0.0))(); // starting weight
  RealColumn get weightCurrent => real().withDefault(const Constant(0.0))(); // current weight
  RealColumn get weightTarget => real().withDefault(const Constant(0.0))(); // target weight

  // Compliance scores
  IntColumn get adherenceScore => integer().withDefault(const Constant(0))(); // 0-100 compliance score
  IntColumn get missedDays => integer().withDefault(const Constant(0))(); // number of missed days

  // Evaluation
  RealColumn get userRating => real().withDefault(const Constant(0.0))(); // user's rating for the package
  TextColumn get userReview => text().nullable()(); // user review
  BoolColumn get isReviewed => boolean().withDefault(const Constant(false))();

  // Timestamps
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastActivityAt => dateTime().nullable()(); // last activity date

  // PDF and check dates
  DateTimeColumn get nextCheckDate => dateTime().nullable()(); // next check date
  TextColumn get generatedPdfPath => text().nullable()(); // generated PDF file path
  DateTimeColumn get pdfGeneratedAt => dateTime().nullable()(); // PDF generation date

  // Automatic delivery scheduling (stored as JSON string)
  TextColumn get deliverySchedule => text().withDefault(const Constant('{}'))(); // DeliverySchedule object as JSON
}