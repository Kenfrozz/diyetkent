import 'package:drift/drift.dart';

@DataClassName('DietFileData')
class DietFilesTable extends Table {
  @override
  String get tableName => 'diet_files';

  // Primary key
  IntColumn get id => integer().autoIncrement()();

  // Unique identifier
  TextColumn get fileId => text().unique()();

  // References
  TextColumn get userId => text()(); // diet file owner
  TextColumn get dietitianId => text()(); // dietitian who created the file

  // Basic information
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get description => text().withDefault(const Constant(''))();

  // File information
  TextColumn get fileUrl => text().nullable()(); // Firebase Storage URL
  TextColumn get fileName => text().nullable()();
  TextColumn get fileType => text().nullable()(); // pdf, doc, image, etc.
  IntColumn get fileSizeBytes => integer().nullable()();

  // Diet plan details
  TextColumn get mealPlan => text().nullable()(); // meal plan
  TextColumn get restrictions => text().nullable()(); // restrictions
  TextColumn get recommendations => text().nullable()(); // recommendations
  TextColumn get targetWeight => text().nullable()(); // target weight
  TextColumn get duration => text().nullable()(); // duration

  // Dietitian notes
  TextColumn get dietitianNotes => text().nullable()();

  // Tags and categories - stored as JSON string
  TextColumn get tags => text().withDefault(const Constant('[]'))(); // List<String> as JSON

  // Status information
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))(); // user has read
  DateTimeColumn get readAt => dateTime().nullable()();

  // Timestamps
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}