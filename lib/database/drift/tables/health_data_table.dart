import 'package:drift/drift.dart';

@DataClassName('HealthData')
class HealthDataTable extends Table {
  @override
  String get tableName => 'health_data';

  // Primary key
  IntColumn get id => integer().autoIncrement()();

  // User reference
  TextColumn get userId => text()();

  // Physical measurements
  RealColumn get height => real().nullable()(); // cm
  RealColumn get weight => real().nullable()(); // kg
  RealColumn get bmi => real().nullable()(); // BMI calculated value

  // Daily activity data
  IntColumn get stepCount => integer().nullable()(); // daily step count
  DateTimeColumn get recordDate => dateTime().withDefault(currentDateAndTime)();

  // Additional health information
  RealColumn get bodyFat => real().nullable()(); // body fat percentage
  RealColumn get muscleMass => real().nullable()(); // muscle mass
  RealColumn get waterPercentage => real().nullable()(); // water percentage

  // Notes
  TextColumn get notes => text().nullable()();

  // Timestamps
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}