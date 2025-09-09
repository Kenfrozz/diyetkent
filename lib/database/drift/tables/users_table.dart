import 'package:drift/drift.dart';

// Privacy settings enum
enum PrivacySetting { everyone, contacts, nobody }

// User role enum
enum UserRole { user, admin, dietitian, moderator }

@DataClassName('UserData')
class UsersTable extends Table {
  @override
  String get tableName => 'users';

  // Primary key
  IntColumn get id => integer().autoIncrement()();

  // Unique identifier
  TextColumn get userId => text().unique()();

  // Basic user information
  TextColumn get name => text().nullable()();
  TextColumn get phoneNumber => text().nullable()();
  TextColumn get profileImageUrl => text().nullable()();
  TextColumn get profileImageLocalPath => text().nullable()();
  TextColumn get about => text().nullable()();

  // Health information (basic)
  RealColumn get currentHeight => real().nullable()(); // cm
  RealColumn get currentWeight => real().nullable()(); // kg
  IntColumn get age => integer().nullable()();
  DateTimeColumn get birthDate => dateTime().nullable()();

  // Daily activity
  IntColumn get todayStepCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastStepUpdate => dateTime().nullable()();

  // User role - stored as enum
  IntColumn get userRole => intEnum<UserRole>().withDefault(Constant(UserRole.user.index))();

  // Online status
  BoolColumn get isOnline => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastSeen => dateTime().nullable()();

  // Privacy settings - stored as enums
  IntColumn get lastSeenPrivacy => intEnum<PrivacySetting>().withDefault(Constant(PrivacySetting.everyone.index))();
  IntColumn get profilePhotoPrivacy => intEnum<PrivacySetting>().withDefault(Constant(PrivacySetting.everyone.index))();
  IntColumn get aboutPrivacy => intEnum<PrivacySetting>().withDefault(Constant(PrivacySetting.everyone.index))();

  // Timestamps
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}