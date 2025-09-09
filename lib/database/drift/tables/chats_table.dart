import 'package:drift/drift.dart';

class Chats extends Table {
  IntColumn get id => integer().autoIncrement()();
  
  // Unique chat identifier
  TextColumn get chatId => text().unique()();
  
  // Group chat support
  BoolColumn get isGroup => boolean().withDefault(const Constant(false))();
  TextColumn get groupId => text().nullable()();
  TextColumn get groupName => text().nullable()();
  TextColumn get groupImage => text().nullable()();
  TextColumn get groupDescription => text().nullable()();
  
  // Individual chat (if not a group)
  TextColumn get otherUserId => text().nullable()();
  TextColumn get otherUserName => text().nullable()();
  TextColumn get otherUserContactName => text().nullable()(); // Name in contacts
  TextColumn get otherUserPhoneNumber => text().nullable()();
  TextColumn get otherUserProfileImage => text().nullable()();
  
  // Last message info
  TextColumn get lastMessage => text().nullable()();
  DateTimeColumn get lastMessageTime => dateTime().nullable()();
  BoolColumn get isLastMessageFromMe => boolean().withDefault(const Constant(false))();
  BoolColumn get isLastMessageRead => boolean().withDefault(const Constant(false))();
  
  // Chat status
  IntColumn get unreadCount => integer().withDefault(const Constant(0))();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  BoolColumn get isMuted => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  
  // Tags (stored as JSON array string)
  TextColumn get tags => text().withDefault(const Constant('[]'))();
  
  // Timestamps
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  
  // primaryKey is automatically handled by autoIncrement()
  // Remove duplicate unique constraint since chatId is already unique()
}