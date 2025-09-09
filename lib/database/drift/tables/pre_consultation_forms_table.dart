import 'package:drift/drift.dart';

@DataClassName('PreConsultationFormData')
class PreConsultationFormsTable extends Table {
  @override
  String get tableName => 'pre_consultation_forms';

  // Primary key
  IntColumn get id => integer().autoIncrement()();

  // Unique identifier
  TextColumn get formId => text().unique()();

  // References
  TextColumn get userId => text()();
  TextColumn get dietitianId => text()();

  // Embedded data sections - stored as JSON strings
  TextColumn get personalInfo => text().withDefault(const Constant('{}'))(); // PersonalInfo object as JSON
  TextColumn get medicalHistory => text().withDefault(const Constant('{}'))(); // MedicalHistory object as JSON
  TextColumn get nutritionHabits => text().withDefault(const Constant('{}'))(); // NutritionHabits object as JSON
  TextColumn get physicalActivity => text().withDefault(const Constant('{}'))(); // PhysicalActivity object as JSON
  TextColumn get goals => text().withDefault(const Constant('{}'))(); // Goals object as JSON

  // Dynamic form sections for extensibility - stored as JSON array
  TextColumn get dynamicSections => text().withDefault(const Constant('[]'))(); // List<FormSection> as JSON

  // Form metadata
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  BoolColumn get isSubmitted => boolean().withDefault(const Constant(false))();
  BoolColumn get isReviewed => boolean().withDefault(const Constant(false))();
  TextColumn get reviewNotes => text().nullable()();
  RealColumn get completionPercentage => real().withDefault(const Constant(0.0))();
  RealColumn get riskScore => real().withDefault(const Constant(0.0))();
  TextColumn get riskLevel => text().withDefault(const Constant('low'))(); // low, medium, high
  TextColumn get riskFactors => text().withDefault(const Constant('[]'))(); // List<String> as JSON

  // Timestamps
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get submittedAt => dateTime().nullable()();
  DateTimeColumn get reviewedAt => dateTime().nullable()();
}