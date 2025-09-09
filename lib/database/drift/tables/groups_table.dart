import 'package:drift/drift.dart';

// Group message permission enum
enum MessagePermission { everyone, adminsOnly }

// Group media permission enum
enum MediaPermission { downloadable, viewOnly, disabled }

// Group member role enum
enum GroupMemberRole { member, admin }

@DataClassName('GroupData')
class GroupsTable extends Table {
  @override
  String get tableName => 'groups';

  // Primary key
  IntColumn get id => integer().autoIncrement()();

  // Unique identifier
  TextColumn get groupId => text().unique()();

  // Basic group information
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get profileImageUrl => text().nullable()();
  TextColumn get profileImageLocalPath => text().nullable()();

  // Member lists - stored as JSON strings
  TextColumn get members => text().withDefault(const Constant('[]'))(); // List<String>
  TextColumn get admins => text().withDefault(const Constant('[]'))(); // List<String>
  TextColumn get createdBy => text()();

  // Group permissions - stored as enums
  IntColumn get messagePermission => intEnum<MessagePermission>().withDefault(Constant(MessagePermission.everyone.index))();
  IntColumn get mediaPermission => intEnum<MediaPermission>().withDefault(Constant(MediaPermission.downloadable.index))();
  BoolColumn get allowMembersToAddOthers => boolean().withDefault(const Constant(false))();

  // Timestamps
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('GroupMemberData')
class GroupMembersTable extends Table {
  @override
  String get tableName => 'group_members';

  // References
  TextColumn get groupId => text()();
  TextColumn get userId => text()();

  // Display names
  TextColumn get displayName => text().nullable()();
  TextColumn get contactName => text().nullable()();
  TextColumn get firebaseName => text().nullable()();
  TextColumn get phoneNumber => text().nullable()();
  TextColumn get profileImageUrl => text().nullable()();

  // Role - stored as enum
  IntColumn get role => intEnum<GroupMemberRole>().withDefault(Constant(GroupMemberRole.member.index))();

  // Timestamps
  DateTimeColumn get joinedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastSeenAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {groupId, userId};
}