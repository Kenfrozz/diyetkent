import 'package:drift/drift.dart';

// Message status enum (matches Isar model)
enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

// Message type enum
enum MessageType {
  text,
  image,
  video,
  audio,
  document,
  location,
  contact,
}

class Messages extends Table {
  IntColumn get id => integer().autoIncrement()();
  
  // Unique message identifier
  TextColumn get messageId => text().unique()();
  
  // Chat association
  TextColumn get chatId => text()();
  
  // Sender info
  TextColumn get senderId => text()();
  TextColumn get senderName => text().nullable()();
  
  // Message content
  TextColumn get content => text()();
  IntColumn get type => intEnum<MessageType>()();
  
  // Media info
  TextColumn get mediaUrl => text().nullable()();
  TextColumn get mediaLocalPath => text().nullable()();
  TextColumn get mediaThumbnailUrl => text().nullable()();
  IntColumn get mediaDuration => integer().nullable()(); // For audio/video
  RealColumn get mediaSize => real().nullable()(); // File size in MB
  
  // Reply info
  TextColumn get replyToMessageId => text().nullable()();
  TextColumn get replyToContent => text().nullable()();
  
  // Status
  IntColumn get status => intEnum<MessageStatus>().withDefault(Constant(MessageStatus.sending.index))();
  
  // Timestamps
  DateTimeColumn get timestamp => dateTime()();
  DateTimeColumn get readAt => dateTime().nullable()();
  DateTimeColumn get deliveredAt => dateTime().nullable()();
  
  // Edit info
  BoolColumn get isEdited => boolean().withDefault(const Constant(false))();
  DateTimeColumn get editedAt => dateTime().nullable()();
  
  // Delete info
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeletedForEveryone => boolean().withDefault(const Constant(false))();
  
  // Additional flags
  BoolColumn get isForwarded => boolean().withDefault(const Constant(false))();
  BoolColumn get isStarred => boolean().withDefault(const Constant(false))();
  
  // primaryKey is automatically handled by autoIncrement()
  // Remove duplicate unique constraint since messageId is already unique()
}