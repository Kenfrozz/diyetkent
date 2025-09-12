import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:drift/drift.dart';
import 'drift/database.dart';
// Import model classes
import '../models/user_model.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart' as model;
import '../models/story_model.dart';
import '../models/group_model.dart';
import '../models/call_log_model.dart' as model;
import '../models/tag_model.dart';
import '../models/contact_index_model.dart';

/// Drift database service that provides a unified API for database operations
class DriftService {
  static AppDatabase? _database;
  
  static AppDatabase get database {
    _database ??= AppDatabase.instance;
    return _database!;
  }

  /// Initialize the Drift database
  static Future<void> initialize() async {
    try {
      _database = AppDatabase.instance;
      debugPrint('✅ Drift database initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize Drift database: $e');
      rethrow;
    }
  }

  // ========== CHAT OPERATIONS ==========

  /// Get all chats for the current user
  static Future<List<ChatModel>> getAllChats() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return [];

    final chatData = await database.chatDao.getAllChats();
    return chatData.map((data) => _chatFromDrift(data)).toList();
  }

  /// Save a chat to the database
  static Future<void> saveChat(ChatModel chat) async {
    final companion = _chatToDrift(chat);
    await database.chatDao.insertOrUpdateChat(companion);
  }

  /// Get a chat by ID
  static Future<ChatModel?> getChatById(String chatId) async {
    final chatData = await database.chatDao.getChatById(chatId);
    if (chatData == null) return null;
    return _chatFromDrift(chatData);
  }

  /// Delete a chat
  static Future<void> deleteChat(String chatId) async {
    await database.chatDao.deleteChat(chatId);
  }

  /// Watch chats stream
  static Stream<List<ChatModel>> watchChats() {
    return database.chatDao.watchAllChats().map((chatDataList) {
      return chatDataList.map((data) => _chatFromDrift(data)).toList();
    });
  }

  // ========== MESSAGE OPERATIONS ==========

  /// Get messages for a chat
  static Future<List<model.MessageModel>> getMessages(String chatId, [int? limit]) async {
    final messageData = await database.messageDao.getMessages(chatId, limit: limit);
    return messageData.map((data) => _messageFromDrift(data)).toList();
  }

  /// Save a message to the database
  static Future<void> saveMessage(model.MessageModel message) async {
    final companion = _messageToDrift(message);
    await database.messageDao.insertMessage(companion);
  }

  /// Delete a message
  static Future<void> deleteMessage(String messageId) async {
    await database.messageDao.deleteMessage(messageId);
  }

  /// Watch messages stream for a chat
  static Stream<List<model.MessageModel>> watchMessages(String chatId) {
    return database.messageDao.watchMessages(chatId).map((messageDataList) {
      return messageDataList.map((data) => _messageFromDrift(data)).toList();
    });
  }

  // ========== USER OPERATIONS ==========

  /// Save a user to the database
  static Future<void> saveUser(UserModel user) async {
    final companion = _userToDrift(user);
    await database.userDao.insertOrUpdateUser(companion);
  }

  /// Get a user by ID
  static Future<UserModel?> getUserById(String userId) async {
    final userData = await database.userDao.getUserById(userId);
    if (userData == null) return null;
    return _userFromDrift(userData);
  }

  /// Get all users
  static Future<List<UserModel>> getAllUsers() async {
    final userData = await database.userDao.getAllUsers();
    return userData.map((data) => _userFromDrift(data)).toList();
  }

  // ========== STORY OPERATIONS ==========

  /// Save a story to the database
  static Future<void> saveStory(StoryModel story) async {
    final companion = _storyToDrift(story);
    await database.storyDao.insertOrUpdateStory(companion);
  }

  /// Get stories by user ID
  static Future<List<StoryModel>> getStoriesByUserId(String userId) async {
    final storyData = await database.storyDao.getStoriesByUserId(userId);
    return storyData.map((data) => _storyFromDrift(data)).toList();
  }

  /// Get all active stories
  static Future<List<StoryModel>> getAllActiveStories() async {
    final storyData = await database.storyDao.getAllActiveStories();
    return storyData.map((data) => _storyFromDrift(data)).toList();
  }

  // ========== GROUP OPERATIONS ==========

  /// Save a group to the database
  static Future<void> saveGroup(GroupModel group) async {
    // Simplified group saving - actual implementation would need proper conversion
    debugPrint('Group saving functionality needs implementation');
  }

  /// Get group by ID
  static Future<GroupModel?> getGroupById(String groupId) async {
    // Simplified group retrieval - actual implementation would need proper conversion
    debugPrint('Group retrieval functionality needs implementation');
    return null;
  }

  // ========== TAG OPERATIONS ==========

  /// Save a tag to the database
  static Future<void> saveTag(TagModel tag) async {
    final companion = _tagToDrift(tag);
    await database.tagDao.insertOrUpdateTag(companion);
  }

  /// Get all tags
  static Future<List<TagModel>> getAllTags() async {
    final tagData = await database.tagDao.getAllTags();
    return tagData.map((data) => _tagFromDrift(data)).toList();
  }

  // ========== CALL LOG OPERATIONS ==========

  /// Save a call log to the database
  static Future<void> saveCallLog(model.CallLogModel callLog) async {
    final companion = _callLogToDrift(callLog);
    await database.callLogDao.insertCallLog(companion);
  }

  /// Get call logs
  static Future<List<model.CallLogModel>> getCallLogs([int? limit]) async {
    final callLogData = await database.callLogDao.getAllCallLogs(limit: limit);
    return callLogData.map((data) => _callLogFromDrift(data)).toList();
  }

  // ========== CONTACT INDEX OPERATIONS ==========

  /// Save a contact index to the database
  static Future<void> saveContactIndex(ContactIndexModel contactIndex) async {
    final companion = _contactIndexToDrift(contactIndex);
    await database.contactIndexDao.insertOrUpdateContactIndex(companion);
  }

  /// Get all contact indexes
  static Future<List<ContactIndexModel>> getAllContactIndexes() async {
    final contactIndexData = await database.contactIndexDao.getAllContactIndexes();
    return contactIndexData.map((data) => _contactIndexFromDrift(data)).toList();
  }

  // ========== HEALTH DATA OPERATIONS ==========

  /// Save health data
  static Future<void> saveHealthData(String userId, Map<String, dynamic> data) async {
    await database.healthDataDao.insertOrUpdateHealthData(userId, data);
  }

  /// Get health data by user ID
  static Future<Map<String, dynamic>?> getHealthData(String userId) async {
    return await database.healthDataDao.getHealthDataByUserId(userId);
  }

  // ========== UTILITY METHODS ==========

  /// Clear all data (for logout)
  static Future<void> clearAllData() async {
    await database.clearAll();
  }

  // ========== CONVERSION METHODS ==========

  static ChatModel _chatFromDrift(dynamic data) {
    return ChatModel(
      chatId: data.chatId ?? '',
      chatType: ChatType.values.firstWhere(
        (type) => type.toString() == 'ChatType.${data.chatType}',
        orElse: () => ChatType.individual,
      ),
      participants: (data.participants as String?)?.split(',') ?? [],
      lastMessage: data.lastMessage,
      lastMessageTime: data.lastMessageTime,
      unreadCount: data.unreadCount ?? 0,
      isArchived: data.isArchived ?? false,
      isMuted: data.isMuted ?? false,
      createdAt: data.createdAt ?? DateTime.now(),
      updatedAt: data.updatedAt ?? DateTime.now(),
    );
  }

  static ChatsCompanion _chatToDrift(ChatModel chat) {
    return ChatsCompanion(
      chatId: Value(chat.chatId),
      chatType: Value(chat.chatType.toString().split('.').last),
      participants: Value(chat.participants.join(',')),
      lastMessage: Value(chat.lastMessage),
      lastMessageTime: Value(chat.lastMessageTime),
      unreadCount: Value(chat.unreadCount),
      isArchived: Value(chat.isArchived),
      isMuted: Value(chat.isMuted),
      createdAt: Value(chat.createdAt),
      updatedAt: Value(chat.updatedAt),
    );
  }

  static model.MessageModel _messageFromDrift(dynamic data) {
    return model.MessageModel(
      messageId: data.messageId ?? '',
      chatId: data.chatId ?? '',
      senderId: data.senderId ?? '',
      content: data.content ?? '',
      messageType: model.MessageType.values.firstWhere(
        (type) => type.toString() == 'MessageType.${data.messageType}',
        orElse: () => model.MessageType.text,
      ),
      timestamp: data.timestamp ?? DateTime.now(),
      isRead: data.isRead ?? false,
      mediaUrl: data.mediaUrl,
      thumbnailUrl: data.thumbnailUrl,
    );
  }

  static MessagesCompanion _messageToDrift(model.MessageModel message) {
    return MessagesCompanion(
      messageId: Value(message.messageId),
      chatId: Value(message.chatId),
      senderId: Value(message.senderId),
      content: Value(message.content),
      messageType: Value(message.messageType.toString().split('.').last),
      timestamp: Value(message.timestamp),
      isRead: Value(message.isRead),
      mediaUrl: Value(message.mediaUrl),
      thumbnailUrl: Value(message.thumbnailUrl),
    );
  }

  static UserModel _userFromDrift(dynamic data) {
    return UserModel(
      userId: data.userId ?? '',
      name: data.name ?? '',
      phoneNumber: data.phoneNumber ?? '',
      profileImageUrl: data.profileImageUrl,
      isOnline: data.isOnline ?? false,
      lastSeen: data.lastSeen,
      createdAt: data.createdAt ?? DateTime.now(),
      updatedAt: data.updatedAt ?? DateTime.now(),
    );
  }

  static UsersTableCompanion _userToDrift(UserModel user) {
    return UsersTableCompanion(
      userId: Value(user.userId),
      name: Value(user.name),
      phoneNumber: Value(user.phoneNumber),
      profileImageUrl: Value(user.profileImageUrl),
      isOnline: Value(user.isOnline),
      lastSeen: Value(user.lastSeen),
      createdAt: Value(user.createdAt),
      updatedAt: Value(user.updatedAt),
    );
  }

  static StoryModel _storyFromDrift(dynamic data) {
    return StoryModel(
      storyId: data.storyId ?? '',
      userId: data.userId ?? '',
      userName: data.userName ?? '',
      userPhone: data.userPhone ?? '',
      userProfileImage: data.userProfileImage,
      type: StoryType.values.firstWhere(
        (type) => type.toString() == 'StoryType.${data.type}',
        orElse: () => StoryType.image,
      ),
      content: data.content ?? '',
      mediaUrl: data.mediaUrl,
      thumbnailUrl: data.thumbnailUrl,
      createdAt: data.createdAt ?? DateTime.now(),
      expiresAt: data.expiresAt ?? DateTime.now().add(const Duration(hours: 24)),
      isActive: data.isActive ?? true,
      viewerIds: (data.viewerIds as String?)?.split(',') ?? [],
    );
  }

  static StoriesTableCompanion _storyToDrift(StoryModel story) {
    return StoriesTableCompanion(
      storyId: Value(story.storyId),
      userId: Value(story.userId),
      userName: Value(story.userName),
      userPhone: Value(story.userPhone),
      userProfileImage: Value(story.userProfileImage),
      type: Value(story.type.toString().split('.').last),
      content: Value(story.content),
      mediaUrl: Value(story.mediaUrl),
      thumbnailUrl: Value(story.thumbnailUrl),
      createdAt: Value(story.createdAt),
      expiresAt: Value(story.expiresAt),
      isActive: Value(story.isActive),
      viewerIds: Value(story.viewerIds.join(',')),
    );
  }

  static TagModel _tagFromDrift(dynamic data) {
    return TagModel(
      tagId: data.tagId ?? '',
      name: data.name ?? '',
      color: data.color ?? '#00796B',
      chatIds: (data.chatIds as String?)?.split(',') ?? [],
      createdAt: data.createdAt ?? DateTime.now(),
      updatedAt: data.updatedAt ?? DateTime.now(),
    );
  }

  static TagsTableCompanion _tagToDrift(TagModel tag) {
    return TagsTableCompanion(
      tagId: Value(tag.tagId),
      name: Value(tag.name),
      color: Value(tag.color),
      chatIds: Value(tag.chatIds.join(',')),
      createdAt: Value(tag.createdAt),
      updatedAt: Value(tag.updatedAt),
    );
  }

  static model.CallLogModel _callLogFromDrift(dynamic data) {
    return model.CallLogModel(
      callId: data.callId ?? '',
      callerId: data.callerId ?? '',
      receiverId: data.receiverId ?? '',
      callType: model.CallType.values.firstWhere(
        (type) => type.toString() == 'CallType.${data.callType}',
        orElse: () => model.CallType.voice,
      ),
      callStatus: model.CallStatus.values.firstWhere(
        (status) => status.toString() == 'CallStatus.${data.callStatus}',
        orElse: () => model.CallStatus.missed,
      ),
      duration: Duration(seconds: data.duration ?? 0),
      timestamp: data.timestamp ?? DateTime.now(),
    );
  }

  static CallLogsTableCompanion _callLogToDrift(model.CallLogModel callLog) {
    return CallLogsTableCompanion(
      callId: Value(callLog.callId),
      callerId: Value(callLog.callerId),
      receiverId: Value(callLog.receiverId),
      callType: Value(callLog.callType.toString().split('.').last),
      callStatus: Value(callLog.callStatus.toString().split('.').last),
      duration: Value(callLog.duration.inSeconds),
      timestamp: Value(callLog.timestamp),
    );
  }

  static ContactIndexModel _contactIndexFromDrift(dynamic data) {
    return ContactIndexModel(
      id: data.id ?? '',
      userId: data.userId ?? '',
      phoneNumber: data.phoneNumber ?? '',
      name: data.name ?? '',
      isRegistered: data.isRegistered ?? false,
      lastUpdated: data.lastUpdated ?? DateTime.now(),
    );
  }

  static ContactIndexesTableCompanion _contactIndexToDrift(ContactIndexModel contactIndex) {
    return ContactIndexesTableCompanion(
      id: Value(contactIndex.id),
      userId: Value(contactIndex.userId),
      phoneNumber: Value(contactIndex.phoneNumber),
      name: Value(contactIndex.name),
      isRegistered: Value(contactIndex.isRegistered),
      lastUpdated: Value(contactIndex.lastUpdated),
    );
  }
}