import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/messages_table.dart';

part 'message_dao.g.dart';

@DriftAccessor(tables: [Messages])
class MessageDao extends DatabaseAccessor<AppDatabase> with _$MessageDaoMixin {
  MessageDao(super.db);

  // Get all messages for a chat
  Future<List<Message>> getMessagesByChatId(String chatId) {
    return (select(messages)
          ..where((t) => t.chatId.equals(chatId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.asc)
          ]))
        .get();
  }

  // Watch messages for a chat (real-time)
  Stream<List<Message>> watchMessagesByChatId(String chatId) {
    return (select(messages)
          ..where((t) => t.chatId.equals(chatId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  // Get message by ID
  Future<Message?> getMessageById(String messageId) {
    return (select(messages)..where((t) => t.messageId.equals(messageId)))
        .getSingleOrNull();
  }

  // Save message
  Future<int> saveMessage(MessagesCompanion message) {
    return into(messages).insertOnConflictUpdate(message);
  }

  // Batch save messages
  Future<void> saveMessages(List<MessagesCompanion> messageList) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(messages, messageList);
    });
  }

  // Update message
  Future<bool> updateMessage(MessagesCompanion message) {
    return update(messages).replace(message);
  }

  // Update message status
  Future<int> updateMessageStatus(String messageId, MessageStatus status) {
    return (update(messages)..where((t) => t.messageId.equals(messageId)))
        .write(MessagesCompanion(
      status: Value(status),
      deliveredAt: status == MessageStatus.delivered
          ? Value(DateTime.now())
          : const Value.absent(),
      readAt: status == MessageStatus.read
          ? Value(DateTime.now())
          : const Value.absent(),
    ));
  }

  // Mark message as read
  Future<int> markMessageAsRead(String messageId) {
    return (update(messages)..where((t) => t.messageId.equals(messageId)))
        .write(MessagesCompanion(
      status: const Value(MessageStatus.read),
      readAt: Value(DateTime.now()),
    ));
  }

  // Mark all messages in chat as read
  Future<int> markAllMessagesAsRead(String chatId) {
    return (update(messages)
          ..where((t) => t.chatId.equals(chatId) & t.readAt.isNull()))
        .write(MessagesCompanion(
      status: const Value(MessageStatus.read),
      readAt: Value(DateTime.now()),
    ));
  }

  // Update message local media path
  Future<int> updateMessageLocalMediaPath(String messageId, String localPath) {
    return (update(messages)..where((t) => t.messageId.equals(messageId)))
        .write(MessagesCompanion(
      mediaLocalPath: Value(localPath),
    ));
  }

  // Get last message for a chat
  Future<Message?> getLastMessageByChatId(String chatId) {
    return (select(messages)
          ..where((t) => t.chatId.equals(chatId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  // Get unread messages for a chat
  Future<List<Message>> getUnreadMessagesByChatId(String chatId) {
    return (select(messages)
          ..where((t) => t.chatId.equals(chatId) & t.readAt.isNull()))
        .get();
  }

  // Get failed messages
  Future<List<Message>> getFailedMessages() {
    return (select(messages)
          ..where((t) => t.status.equals(MessageStatus.failed.index))
          ..orderBy([
            (t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.asc)
          ]))
        .get();
  }

  // Search messages by text
  Future<List<Message>> searchMessagesByText(String query) {
    final lowerQuery = query.toLowerCase();
    return (select(messages)
          ..where((t) => t.content.lower().contains(lowerQuery)))
        .get();
  }

  // Delete message
  Future<int> deleteMessage(String messageId) {
    return (delete(messages)..where((t) => t.messageId.equals(messageId))).go();
  }

  // Soft delete message (mark as deleted)
  Future<int> softDeleteMessage(String messageId, {bool forEveryone = false}) {
    return (update(messages)..where((t) => t.messageId.equals(messageId)))
        .write(MessagesCompanion(
      isDeleted: const Value(true),
      isDeletedForEveryone: Value(forEveryone),
    ));
  }

  // Edit message
  Future<int> editMessage(String messageId, String newContent) {
    return (update(messages)..where((t) => t.messageId.equals(messageId)))
        .write(MessagesCompanion(
      content: Value(newContent),
      isEdited: const Value(true),
      editedAt: Value(DateTime.now()),
    ));
  }

  // Star/unstar message
  Future<int> toggleStarMessage(String messageId, bool isStarred) {
    return (update(messages)..where((t) => t.messageId.equals(messageId)))
        .write(MessagesCompanion(
      isStarred: Value(isStarred),
    ));
  }

  // Get starred messages
  Future<List<Message>> getStarredMessages({String? chatId}) {
    var query = select(messages)..where((t) => t.isStarred.equals(true));

    if (chatId != null) {
      query = query..where((t) => t.chatId.equals(chatId));
    }

    return (query
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)
          ]))
        .get();
  }

  // Get media messages
  Future<List<Message>> getMediaMessages(String chatId) {
    return (select(messages)
          ..where((t) =>
              t.chatId.equals(chatId) &
              (t.type.equals(MessageType.image.index) |
                  t.type.equals(MessageType.video.index) |
                  t.type.equals(MessageType.audio.index)))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)
          ]))
        .get();
  }

  // Get messages with pagination
  Future<List<Message>> getMessagesPaginated({
    required String chatId,
    required int limit,
    DateTime? before,
  }) {
    var query = select(messages)..where((t) => t.chatId.equals(chatId));

    if (before != null) {
      query = query..where((t) => t.timestamp.isSmallerThanValue(before));
    }

    return (query
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)
          ])
          ..limit(limit))
        .get();
  }

  // Count messages in chat
  Future<int> countMessages(String chatId) {
    final query = selectOnly(messages)
      ..where(messages.chatId.equals(chatId))
      ..addColumns([messages.id.count()]);
    return query.map((row) => row.read(messages.id.count()) ?? 0).getSingle();
  }

  // Delete all messages in chat
  Future<int> deleteAllMessagesInChat(String chatId) {
    return (delete(messages)..where((t) => t.chatId.equals(chatId))).go();
  }

  // Clear all messages
  Future<int> clearAll() {
    return delete(messages).go();
  }
}
