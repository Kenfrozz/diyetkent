import 'package:drift/drift.dart';

@DataClassName('UserRoleData')
class UserRolesTable extends Table {
  @override
  String get tableName => 'user_roles';

  // Primary key
  IntColumn get id => integer().autoIncrement()();

  // Unique identifier
  TextColumn get userId => text().unique()();

  // Role - stored as string
  TextColumn get role => text().withDefault(const Constant('user'))(); // user, dietitian, admin

  // Dietitian special information
  TextColumn get licenseNumber => text().nullable()(); // diploma/license number
  TextColumn get specialization => text().nullable()(); // specialization area
  TextColumn get clinicName => text().nullable()(); // clinic/hospital name
  TextColumn get clinicAddress => text().nullable()(); // clinic address
  IntColumn get experienceYears => integer().nullable()(); // years of experience

  // Permissions
  BoolColumn get canSendBulkMessages => boolean().withDefault(const Constant(false))();
  BoolColumn get canViewAllUsers => boolean().withDefault(const Constant(false))();
  BoolColumn get canCreateDietFiles => boolean().withDefault(const Constant(false))();
  BoolColumn get canViewUserHealth => boolean().withDefault(const Constant(false))();

  // Statistics
  IntColumn get totalPatientsCount => integer().withDefault(const Constant(0))();
  IntColumn get activePatientsCount => integer().withDefault(const Constant(0))();
  IntColumn get dietFilesCreatedCount => integer().withDefault(const Constant(0))();

  // Timestamps
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}