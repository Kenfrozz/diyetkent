import 'package:drift/drift.dart';

@DataClassName('ContactIndexData')
class ContactIndexesTable extends Table {
  @override
  String get tableName => 'contact_indexes';

  // Primary key
  IntColumn get id => integer().autoIncrement()();

  // Unique identifier - normalized phone in E.164 format
  TextColumn get normalizedPhone => text().unique()();

  // Contact information
  TextColumn get contactName => text().nullable()(); // Name in contacts
  TextColumn get originalPhone => text().nullable()(); // Original phone format

  // User information
  BoolColumn get isRegistered => boolean().withDefault(const Constant(false))();
  TextColumn get registeredUid => text().nullable()(); // Matching user UID if registered
  TextColumn get displayName => text().nullable()(); // Registered user's name
  TextColumn get profileImageUrl => text().nullable()(); // Profile photo
  BoolColumn get isOnline => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastSeen => dateTime().nullable()();

  // Meta information
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastSyncAt => dateTime().nullable()(); // Last Firebase sync
}