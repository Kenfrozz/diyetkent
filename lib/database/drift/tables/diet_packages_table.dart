import 'package:drift/drift.dart';

@DataClassName('DietPackageData')
class DietPackagesTable extends Table {
  @override
  String get tableName => 'diet_packages';

  // Primary key
  IntColumn get id => integer().autoIncrement()();

  // Unique identifier
  TextColumn get packageId => text().unique()();

  // Creator reference
  TextColumn get dietitianId => text()(); // creating dietitian

  // Basic information
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get imageUrl => text().nullable()();

  // Package type - stored as string
  TextColumn get type => text().withDefault(const Constant('custom'))(); // weightLoss, weightGain, maintenance, diabetic, sports, custom

  // Package parameters
  IntColumn get durationDays => integer().withDefault(const Constant(30))(); // default 30 days
  RealColumn get price => real().withDefault(const Constant(0.0))();

  // Package calculation parameters
  IntColumn get numberOfFiles => integer().withDefault(const Constant(4))(); // how many diet files in package
  IntColumn get daysPerFile => integer().withDefault(const Constant(7))(); // how many days each file will last
  RealColumn get targetWeightChangePerFile => real().withDefault(const Constant(-2.0))(); // target weight change per file

  // General nutrition targets (stored as JSON string)
  TextColumn get nutritionTargets => text().withDefault(const Constant('{}'))(); // {"calories": 1500, "protein": 100, "carbs": 150, "fat": 50}

  // General meal plans template (stored as JSON array string)
  TextColumn get mealPlans => text().withDefault(const Constant('[]'))(); // [{"type": "breakfast", "foods": ["egg", "bread"], "calories": 300}]

  // Allowed/forbidden foods - stored as JSON strings
  TextColumn get allowedFoods => text().withDefault(const Constant('[]'))(); // List<String> as JSON
  TextColumn get forbiddenFoods => text().withDefault(const Constant('[]'))(); // List<String> as JSON

  // Additional information
  TextColumn get exercisePlan => text().nullable()(); // exercise recommendations
  TextColumn get specialNotes => text().nullable()(); // special notes
  TextColumn get tags => text().withDefault(const Constant('[]'))(); // List<String> as JSON

  // Status information
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get isPublic => boolean().withDefault(const Constant(false))(); // for other dietitians to see

  // Statistics
  IntColumn get assignedCount => integer().withDefault(const Constant(0))(); // how many users assigned
  RealColumn get averageRating => real().withDefault(const Constant(0.0))(); // average rating
  IntColumn get reviewCount => integer().withDefault(const Constant(0))(); // review count

  // Timestamps
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}