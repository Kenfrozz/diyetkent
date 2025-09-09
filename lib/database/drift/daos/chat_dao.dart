import 'dart:convert';
import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/chats_table.dart';

part 'chat_dao.g.dart';

@DriftAccessor(tables: [Chats])
class ChatDao extends DatabaseAccessor<AppDatabase> with _$ChatDaoMixin {
  ChatDao(super.db);

  // Get all chats
  Future<List<Chat>> getAllChats() {
    return select(chats).get();
  }

  // Watch all chats sorted by last message time
  Stream<List<Chat>> watchAllChats() {
    return (select(chats)
          ..orderBy([(t) => OrderingTerm(expression: t.lastMessageTime, mode: OrderingMode.desc)]))
        .watch();
  }

  // Watch active chats (not archived)
  Stream<List<Chat>> watchActiveChats() {
    return (select(chats)
          ..where((t) => t.isArchived.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.lastMessageTime, mode: OrderingMode.desc)]))
        .watch();
  }

  // Watch archived chats
  Stream<List<Chat>> watchArchivedChats() {
    return (select(chats)
          ..where((t) => t.isArchived.equals(true))
          ..orderBy([(t) => OrderingTerm(expression: t.lastMessageTime, mode: OrderingMode.desc)]))
        .watch();
  }

  // Get chat by ID
  Future<Chat?> getChatById(String chatId) {
    return (select(chats)..where((t) => t.chatId.equals(chatId))).getSingleOrNull();
  }

  // Watch chat by ID
  Stream<Chat?> watchChatById(String chatId) {
    return (select(chats)..where((t) => t.chatId.equals(chatId))).watchSingleOrNull();
  }

  // Save or update chat (upsert)
  Future<int> saveChat(ChatsCompanion chat) {
    return into(chats).insertOnConflictUpdate(chat);
  }

  // Batch save chats
  Future<void> saveChats(List<ChatsCompanion> chatList) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(chats, chatList);
    });
  }

  // Update chat
  Future<bool> updateChat(ChatsCompanion chat) {
    return update(chats).replace(chat);
  }

  // Delete chat
  Future<int> deleteChat(String chatId) {
    return (delete(chats)..where((t) => t.chatId.equals(chatId))).go();
  }

  // Update chat archive status
  Future<int> updateChatArchiveStatus(String chatId, bool isArchived) {
    return (update(chats)..where((t) => t.chatId.equals(chatId)))
        .write(ChatsCompanion(
      isArchived: Value(isArchived),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update chat mute status
  Future<int> updateChatMuteStatus(String chatId, bool isMuted) {
    return (update(chats)..where((t) => t.chatId.equals(chatId)))
        .write(ChatsCompanion(
      isMuted: Value(isMuted),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update chat pin status
  Future<int> updateChatPinStatus(String chatId, bool isPinned) {
    return (update(chats)..where((t) => t.chatId.equals(chatId)))
        .write(ChatsCompanion(
      isPinned: Value(isPinned),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Mark chat as read
  Future<int> markChatAsRead(String chatId) {
    return (update(chats)..where((t) => t.chatId.equals(chatId)))
        .write(ChatsCompanion(
      unreadCount: const Value(0),
      isLastMessageRead: const Value(true),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Mark chat as unread
  Future<int> markChatAsUnread(String chatId) {
    return (update(chats)..where((t) => t.chatId.equals(chatId)))
        .write(ChatsCompanion(
      unreadCount: const Value(1),
      isLastMessageRead: const Value(false),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Increment unread count
  Future<void> incrementUnreadCount(String chatId) async {
    final chat = await getChatById(chatId);
    if (chat != null) {
      await (update(chats)..where((t) => t.chatId.equals(chatId)))
          .write(ChatsCompanion(
        unreadCount: Value(chat.unreadCount + 1),
        isLastMessageRead: const Value(false),
        updatedAt: Value(DateTime.now()),
      ));
    }
  }

  // Get chats by tags
  Future<List<Chat>> getChatsByTags(List<String> tagList) async {
    final allChats = await getAllChats();
    return allChats.where((chat) {
      final chatTags = (jsonDecode(chat.tags) as List).cast<String>();
      return chatTags.any((tag) => tagList.contains(tag));
    }).toList();
  }

  // Watch chats by tags
  Stream<List<Chat>> watchChatsByTags(List<String> tagList) {
    return watchAllChats().map((chatList) {
      return chatList.where((chat) {
        final chatTags = (jsonDecode(chat.tags) as List).cast<String>();
        return chatTags.any((tag) => tagList.contains(tag));
      }).toList();
    });
  }

  // Search chats
  Future<List<Chat>> searchChats(String query) {
    final lowerQuery = query.toLowerCase();
    return (select(chats)
          ..where((t) => t.otherUserName.lower().contains(lowerQuery) |
              t.otherUserContactName.lower().contains(lowerQuery) |
              t.groupName.lower().contains(lowerQuery) |
              t.lastMessage.lower().contains(lowerQuery)))
        .get();
  }

  // Get pinned chats
  Stream<List<Chat>> watchPinnedChats() {
    return (select(chats)
          ..where((t) => t.isPinned.equals(true))
          ..orderBy([(t) => OrderingTerm(expression: t.lastMessageTime, mode: OrderingMode.desc)]))
        .watch();
  }

  // Get muted chats
  Stream<List<Chat>> watchMutedChats() {
    return (select(chats)
          ..where((t) => t.isMuted.equals(true))
          ..orderBy([(t) => OrderingTerm(expression: t.lastMessageTime, mode: OrderingMode.desc)]))
        .watch();
  }

  // Get unread chats
  Stream<List<Chat>> watchUnreadChats() {
    return (select(chats)
          ..where((t) => t.unreadCount.isBiggerThanValue(0))
          ..orderBy([(t) => OrderingTerm(expression: t.lastMessageTime, mode: OrderingMode.desc)]))
        .watch();
  }

  // Get total unread count
  Stream<int> watchTotalUnreadCount() {
    final query = selectOnly(chats)..addColumns([chats.unreadCount.sum()]);
    return query.map((row) => row.read(chats.unreadCount.sum()) ?? 0).watchSingle();
  }

  // Update last message info
  Future<int> updateLastMessage({
    required String chatId,
    required String lastMessage,
    required DateTime lastMessageTime,
    required bool isFromMe,
  }) {
    return (update(chats)..where((t) => t.chatId.equals(chatId)))
        .write(ChatsCompanion(
      lastMessage: Value(lastMessage),
      lastMessageTime: Value(lastMessageTime),
      isLastMessageFromMe: Value(isFromMe),
      isLastMessageRead: Value(isFromMe), // If from me, it's read
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Clear all chats
  Future<int> clearAll() {
    return delete(chats).go();
  }
}