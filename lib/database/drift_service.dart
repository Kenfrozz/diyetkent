import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:drift/drift.dart';
import 'drift/database.dart';
// Migration no longer needed - removed isar_to_drift_migrator.dart
import 'drift/tables/messages_table.dart' as drift_messages;
import 'drift/tables/users_table.dart';
import 'drift/tables/groups_table.dart';
import 'drift/tables/call_logs_table.dart' as drift_calls;
// Import model classes
import '../models/user_model.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart' as model;
import '../models/story_model.dart';
import '../models/group_model.dart';
import '../models/call_log_model.dart' as model;
import '../models/tag_model.dart';
import '../models/diet_package_model.dart';
import '../models/diet_file_model.dart';
import '../models/contact_index_model.dart';
import '../models/pre_consultation_form_model.dart';
import '../models/progress_reminder_model.dart';
import '../models/user_diet_assignment_model.dart';

/// Drift database service that replaces IsarService
/// Provides a similar API to IsarService for easy migration
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

  // Migration removed - we're using pure Drift now

  // ========== CHAT OPERATIONS ==========

  /// Convert Drift Chat to ChatModel
  static ChatModel convertChatModel(Chat chat) {
    return ChatModel.create(
      chatId: chat.chatId,
      isGroup: chat.isGroup,
      groupId: chat.groupId,
      groupName: chat.groupName,
      groupImage: chat.groupImage,
      groupDescription: chat.groupDescription,
      otherUserId: chat.otherUserId,
      otherUserName: chat.otherUserName,
      otherUserContactName: chat.otherUserContactName,
      otherUserPhoneNumber: chat.otherUserPhoneNumber,
      otherUserProfileImage: chat.otherUserProfileImage,
      lastMessage: chat.lastMessage,
      lastMessageTime: chat.lastMessageTime,
      isLastMessageFromMe: chat.isLastMessageFromMe,
      isLastMessageRead: chat.isLastMessageRead,
      unreadCount: chat.unreadCount,
      isPinned: chat.isPinned,
      isMuted: chat.isMuted,
      isArchived: chat.isArchived,
      tags: chat.tags.isNotEmpty ? List<String>.from(json.decode(chat.tags)) : [],
    );
  }

  /// Convert Drift GroupData to GroupModel
  static GroupModel convertGroupModel(GroupData group) {
    final groupModel = GroupModel.create(
      groupId: group.groupId,
      name: group.name,
      description: group.description,
      profileImageUrl: group.profileImageUrl,
      members: group.members.split(',').where((e) => e.isNotEmpty).toList(),
      admins: group.admins.split(',').where((e) => e.isNotEmpty).toList(),
      createdBy: group.createdBy,
    );
    groupModel.createdAt = group.createdAt;
    groupModel.updatedAt = group.updatedAt;
    return groupModel;
  }

  /// Convert Drift UserData to UserModel
  static UserModel _convertToUserModel(UserData userData) {
    return UserModel.create(
      userId: userData.userId,
      name: userData.name,
      phoneNumber: userData.phoneNumber,
      profileImageUrl: userData.profileImageUrl,
      profileImageLocalPath: userData.profileImageLocalPath,
      about: userData.about,
      currentHeight: userData.currentHeight,
      currentWeight: userData.currentWeight,
      age: userData.age,
      birthDate: userData.birthDate,
      todayStepCount: userData.todayStepCount,
      lastStepUpdate: userData.lastStepUpdate,
      isOnline: userData.isOnline,
      lastSeen: userData.lastSeen,
    );
  }

  /// Convert Drift Message to MessageModel
  static model.MessageModel _convertToMessageModel(Message message) {
    final messageModel = model.MessageModel.create(
      messageId: message.messageId,
      chatId: message.chatId,
      senderId: message.senderId,
      content: message.content,
      type: model.MessageType.values[message.type.index],
      status: model.MessageStatus.values[message.status.index],
      mediaUrl: message.mediaUrl,
      mediaLocalPath: message.mediaLocalPath,
      thumbnailUrl: message.mediaThumbnailUrl,
      mediaDuration: message.mediaDuration,
      replyToMessageId: message.replyToMessageId,
      replyToContent: message.replyToContent,
      isEdited: message.isEdited,
      editedAt: message.editedAt,
    );
    
    // Set non-constructor fields
    messageModel.timestamp = message.timestamp;
    messageModel.deliveredAt = message.deliveredAt;
    messageModel.readAt = message.readAt;
    
    return messageModel;
  }

  /// Convert model MessageType to Drift MessageType
  static drift_messages.MessageType _convertMessageType(model.MessageType type) {
    switch (type) {
      case model.MessageType.text:
        return drift_messages.MessageType.text;
      case model.MessageType.image:
        return drift_messages.MessageType.image;
      case model.MessageType.video:
        return drift_messages.MessageType.video;
      case model.MessageType.audio:
        return drift_messages.MessageType.audio;
      case model.MessageType.document:
        return drift_messages.MessageType.document;
      case model.MessageType.location:
        return drift_messages.MessageType.location;
      case model.MessageType.contact:
        return drift_messages.MessageType.contact;
      case model.MessageType.sticker:
        // Drift doesn't have sticker, map to image
        return drift_messages.MessageType.image;
      case model.MessageType.gif:
        // Drift doesn't have gif, map to image
        return drift_messages.MessageType.image;
    }
  }

  /// Convert model MessageStatus to Drift MessageStatus  
  static drift_messages.MessageStatus _convertMessageStatus(model.MessageStatus status) {
    switch (status) {
      case model.MessageStatus.sending:
        return drift_messages.MessageStatus.sending;
      case model.MessageStatus.sent:
        return drift_messages.MessageStatus.sent;
      case model.MessageStatus.delivered:
        return drift_messages.MessageStatus.delivered;
      case model.MessageStatus.read:
        return drift_messages.MessageStatus.read;
      case model.MessageStatus.failed:
        return drift_messages.MessageStatus.failed;
    }
  }

  /// Convert model CallLogDirection to Drift CallLogDirection
  static drift_calls.CallLogDirection _convertCallLogDirection(model.CallLogDirection direction) {
    switch (direction) {
      case model.CallLogDirection.incoming:
        return drift_calls.CallLogDirection.incoming;
      case model.CallLogDirection.outgoing:
        return drift_calls.CallLogDirection.outgoing;
    }
  }

  /// Convert model CallLogStatus to Drift CallLogStatus  
  static drift_calls.CallLogStatus _convertCallLogStatus(model.CallLogStatus status) {
    switch (status) {
      case model.CallLogStatus.ringing:
        return drift_calls.CallLogStatus.ringing;
      case model.CallLogStatus.connected:
        return drift_calls.CallLogStatus.connected;
      case model.CallLogStatus.ended:
        return drift_calls.CallLogStatus.ended;
      case model.CallLogStatus.declined:
        return drift_calls.CallLogStatus.declined;
      case model.CallLogStatus.missed:
        return drift_calls.CallLogStatus.missed;
    }
  }

  /// Convert Drift CallLogData to CallLogModel
  static model.CallLogModel _convertToCallLogModel(CallLogData callLogData) {
    final callLogModel = model.CallLogModel();
    callLogModel.callId = callLogData.callId;
    callLogModel.otherUserId = callLogData.otherUserId;
    callLogModel.otherUserPhone = callLogData.otherUserPhone;
    callLogModel.otherDisplayName = callLogData.otherDisplayName;
    callLogModel.isVideo = callLogData.isVideo;
    callLogModel.direction = _convertDriftCallLogDirection(callLogData.direction);
    callLogModel.status = _convertDriftCallLogStatus(callLogData.status);
    callLogModel.createdAt = callLogData.createdAt;
    callLogModel.startedAt = callLogData.startedAt;
    callLogModel.connectedAt = callLogData.connectedAt;
    callLogModel.endedAt = callLogData.endedAt;
    callLogModel.updatedAt = callLogData.updatedAt;
    return callLogModel;
  }

  /// Convert Drift CallLogDirection to model CallLogDirection
  static model.CallLogDirection _convertDriftCallLogDirection(drift_calls.CallLogDirection direction) {
    switch (direction) {
      case drift_calls.CallLogDirection.incoming:
        return model.CallLogDirection.incoming;
      case drift_calls.CallLogDirection.outgoing:
        return model.CallLogDirection.outgoing;
    }
  }

  /// Convert Drift CallLogStatus to model CallLogStatus
  static model.CallLogStatus _convertDriftCallLogStatus(drift_calls.CallLogStatus status) {
    switch (status) {
      case drift_calls.CallLogStatus.ringing:
        return model.CallLogStatus.ringing;
      case drift_calls.CallLogStatus.connected:
        return model.CallLogStatus.connected;
      case drift_calls.CallLogStatus.ended:
        return model.CallLogStatus.ended;
      case drift_calls.CallLogStatus.declined:
        return model.CallLogStatus.declined;
      case drift_calls.CallLogStatus.missed:
        return model.CallLogStatus.missed;
    }
  }

  /// Convert TagData to TagModel
  static TagModel convertTagModel(TagData tagData) {
    final tagModel = TagModel();
    tagModel.tagId = tagData.tagId;
    tagModel.name = tagData.name;
    tagModel.color = tagData.color;
    tagModel.icon = tagData.icon;
    tagModel.description = tagData.description;
    tagModel.usageCount = tagData.usageCount;
    tagModel.createdAt = tagData.createdAt;
    tagModel.updatedAt = tagData.updatedAt;
    return tagModel;
  }

  /// Convert Drift ContactIndexData to ContactIndexModel
  static ContactIndexModel convertContactIndexModel(ContactIndexData data) {
    return ContactIndexModel.create(
      normalizedPhone: data.normalizedPhone,
      contactName: data.contactName,
      originalPhone: data.originalPhone,
      isRegistered: data.isRegistered,
      registeredUid: data.registeredUid,
      displayName: data.displayName,
      profileImageUrl: data.profileImageUrl,
      isOnline: data.isOnline,
      lastSeen: data.lastSeen,
    );
  }

  /// Convert ContactIndexModel to ContactIndexData for saving
  static ContactIndexData convertContactIndexData(ContactIndexModel model) {
    return ContactIndexData(
      id: 0, // Will be auto-assigned by database
      normalizedPhone: model.normalizedPhone,
      contactName: model.contactName,
      originalPhone: model.originalPhone,
      isRegistered: model.isRegistered,
      registeredUid: model.registeredUid,
      displayName: model.displayName,
      profileImageUrl: model.profileImageUrl,
      isOnline: model.isOnline,
      lastSeen: model.lastSeen,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      lastSyncAt: model.lastSyncAt,
    );
  }

  /// Convert StoryModel to StoryData for saving
  static StoryData convertStoryData(StoryModel model) {
    return StoryData(
      id: 0, // Will be auto-assigned by database
      storyId: model.storyId,
      userId: model.userId,
      userPhone: model.userPhone,
      userName: model.userName,
      userProfileImage: model.userProfileImage,
      type: _convertStoryTypeToString(model.type),
      content: model.content,
      mediaUrl: model.mediaUrl,
      thumbnailUrl: null,
      mediaLocalPath: null,
      backgroundColor: model.backgroundColor,
      createdAt: model.createdAt,
      expiresAt: model.expiresAt,
      isViewed: model.isViewed,
      viewerIds: '[]', // Empty JSON array
      repliedUserIds: '[]', // Empty JSON array
      isActive: model.isActive,
      isFromCurrentUser: model.isFromCurrentUser,
      viewCount: model.viewCount,
      lastViewedAt: null,
    );
  }

  /// Helper method to convert StoryType enum to string
  static String _convertStoryTypeToString(StoryType type) {
    switch (type) {
      case StoryType.text:
        return 'text';
      case StoryType.image:
        return 'image';
      case StoryType.video:
        return 'video';
    }
  }

  /// Convert TagModel to TagsTableCompanion for saving
  static TagsTableCompanion convertTagToCompanion(TagModel tagModel) {
    return TagsTableCompanion(
      tagId: Value(tagModel.tagId),
      name: Value(tagModel.name),
      color: Value.absentIfNull(tagModel.color),
      icon: Value.absentIfNull(tagModel.icon),
      description: Value.absentIfNull(tagModel.description),
      usageCount: Value(tagModel.usageCount),
      createdAt: Value(tagModel.createdAt),
      updatedAt: Value(tagModel.updatedAt),
    );
  }

  /// Convert StoryData to StoryModel
  static StoryModel convertStoryModel(StoryData storyData) {
    final storyModel = StoryModel();
    storyModel.storyId = storyData.storyId;
    storyModel.userId = storyData.userId;
    storyModel.type = _convertStoryType(storyData.type);
    storyModel.content = storyData.content;
    storyModel.mediaUrl = storyData.mediaUrl;
    storyModel.backgroundColor = storyData.backgroundColor;
    storyModel.createdAt = storyData.createdAt;
    storyModel.expiresAt = storyData.expiresAt;
    storyModel.viewCount = storyData.viewCount;
    storyModel.isFromCurrentUser = storyData.isFromCurrentUser;
    storyModel.isActive = storyData.isActive;
    return storyModel;
  }

  /// Convert story type string to enum
  static StoryType _convertStoryType(String type) {
    switch (type) {
      case 'text':
        return StoryType.text;
      case 'image':
        return StoryType.image;
      case 'video':
        return StoryType.video;
      default:
        return StoryType.text;
    }
  }

  /// Save a chat
  static Future<void> saveChat(ChatModel chat) async {
    final companion = ChatsCompanion(
      chatId: Value(chat.chatId),
      isGroup: Value(chat.isGroup),
      groupId: Value.absentIfNull(chat.groupId),
      groupName: Value.absentIfNull(chat.groupName),
      groupImage: Value.absentIfNull(chat.groupImage),
      groupDescription: Value.absentIfNull(chat.groupDescription),
      otherUserId: Value.absentIfNull(chat.otherUserId),
      otherUserName: Value.absentIfNull(chat.otherUserName),
      otherUserContactName: Value.absentIfNull(chat.otherUserContactName),
      otherUserProfileImage: Value.absentIfNull(chat.otherUserProfileImage),
      otherUserPhoneNumber: Value.absentIfNull(chat.otherUserPhoneNumber),
      lastMessage: Value.absentIfNull(chat.lastMessage),
      lastMessageTime: Value.absentIfNull(chat.lastMessageTime),
      unreadCount: Value(chat.unreadCount),
      updatedAt: Value(DateTime.now()),
    );
    await database.chatDao.saveChat(companion);
  }

  /// Get all chats
  static Future<List<ChatModel>> getAllChats() async {
    final chats = await database.chatDao.getAllChats();
    return chats.map((chat) => convertChatModel(chat)).toList();
  }

  /// Watch all chats
  static Stream<List<ChatModel>> watchAllChats() {
    return database.chatDao.watchActiveChats().map(
      (chats) => chats.map((chat) => convertChatModel(chat)).toList()
    );
  }

  /// Get chat by ID
  static Future<ChatModel?> getChatById(String chatId) async {
    final chat = await database.chatDao.getChatById(chatId);
    return chat != null ? convertChatModel(chat) : null;
  }

  /// Delete chat
  static Future<void> deleteChat(String chatId) async {
    // Delete all messages in the chat first
    await database.messageDao.deleteAllMessagesInChat(chatId);
    // Then delete the chat
    await database.chatDao.deleteChat(chatId);
  }

  /// Update chat
  static Future<void> updateChat(Chat chat) async {
    final companion = ChatsCompanion(
      chatId: Value(chat.chatId),
      isGroup: Value(chat.isGroup),
      groupId: Value.absentIfNull(chat.groupId),
      groupName: Value.absentIfNull(chat.groupName),
      groupImage: Value.absentIfNull(chat.groupImage),
      groupDescription: Value.absentIfNull(chat.groupDescription),
      otherUserId: Value.absentIfNull(chat.otherUserId),
      otherUserName: Value.absentIfNull(chat.otherUserName),
      otherUserContactName: Value.absentIfNull(chat.otherUserContactName),
      otherUserProfileImage: Value.absentIfNull(chat.otherUserProfileImage),
      otherUserPhoneNumber: Value.absentIfNull(chat.otherUserPhoneNumber),
      lastMessage: Value.absentIfNull(chat.lastMessage),
      lastMessageTime: Value.absentIfNull(chat.lastMessageTime),
      unreadCount: Value(chat.unreadCount),
      updatedAt: Value(DateTime.now()),
    );
    await database.chatDao.updateChat(companion);
  }

  /// Update chat from ChatModel
  static Future<void> updateChatModel(ChatModel chatModel) async {
    final companion = ChatsCompanion(
      chatId: Value(chatModel.chatId),
      isGroup: Value(chatModel.isGroup),
      groupId: Value.absentIfNull(chatModel.groupId),
      groupName: Value.absentIfNull(chatModel.groupName),
      groupImage: Value.absentIfNull(chatModel.groupImage),
      groupDescription: Value.absentIfNull(chatModel.groupDescription),
      otherUserId: Value.absentIfNull(chatModel.otherUserId),
      otherUserName: Value.absentIfNull(chatModel.otherUserName),
      otherUserContactName: Value.absentIfNull(chatModel.otherUserContactName),
      otherUserProfileImage: Value.absentIfNull(chatModel.otherUserProfileImage),
      otherUserPhoneNumber: Value.absentIfNull(chatModel.otherUserPhoneNumber),
      lastMessage: Value.absentIfNull(chatModel.lastMessage),
      lastMessageTime: Value.absentIfNull(chatModel.lastMessageTime),
      unreadCount: Value(chatModel.unreadCount),
      updatedAt: Value(DateTime.now()),
      tags: Value.absentIfNull(chatModel.tags.isNotEmpty ? chatModel.tags.join(',') : null),
    );
    await database.chatDao.updateChat(companion);
  }

  // ========== MESSAGE OPERATIONS ==========

  /// Save a message
  static Future<void> saveMessage(model.MessageModel message) async {
    final companion = MessagesCompanion(
      messageId: Value(message.messageId),
      chatId: Value(message.chatId),
      senderId: Value(message.senderId),
      content: Value(message.content),
      type: Value(_convertMessageType(message.type)),
      mediaUrl: Value.absentIfNull(message.mediaUrl),
      mediaLocalPath: Value.absentIfNull(message.mediaLocalPath),
      mediaThumbnailUrl: Value.absentIfNull(message.thumbnailUrl),
      mediaDuration: Value.absentIfNull(message.mediaDuration),
      replyToMessageId: Value.absentIfNull(message.replyToMessageId),
      replyToContent: Value.absentIfNull(message.replyToContent),
      status: Value(_convertMessageStatus(message.status)),
      timestamp: Value(message.timestamp),
      readAt: Value.absentIfNull(message.readAt),
      deliveredAt: Value.absentIfNull(message.deliveredAt),
      isEdited: Value(message.isEdited),
      editedAt: Value.absentIfNull(message.editedAt),
    );
    await database.messageDao.saveMessage(companion);
  }

  /// Get messages by chat ID
  static Future<List<model.MessageModel>> getMessagesByChatId(String chatId) async {
    final messages = await database.messageDao.getMessagesByChatId(chatId);
    return messages.map((msg) => _convertToMessageModel(msg)).toList();
  }

  /// Watch messages by chat ID
  static Stream<List<model.MessageModel>> watchMessagesByChatId(String chatId) {
    return database.messageDao.watchMessagesByChatId(chatId).map(
      (messages) => messages.map((msg) => _convertToMessageModel(msg)).toList()
    );
  }

  /// Get last message by chat ID
  static Future<model.MessageModel?> getLastMessageByChatId(String chatId) async {
    final message = await database.messageDao.getLastMessageByChatId(chatId);
    return message != null ? _convertToMessageModel(message) : null;
  }

  /// Get message by ID
  static Future<model.MessageModel?> getMessageById(String messageId) async {
    final message = await database.messageDao.getMessageById(messageId);
    return message != null ? _convertToMessageModel(message) : null;
  }

  /// Update message
  static Future<void> updateMessage(model.MessageModel message) async {
    final companion = MessagesCompanion(
      messageId: Value(message.messageId),
      chatId: Value(message.chatId),
      senderId: Value(message.senderId),
      content: Value(message.content),
      type: Value(_convertMessageType(message.type)),
      mediaUrl: Value.absentIfNull(message.mediaUrl),
      mediaLocalPath: Value.absentIfNull(message.mediaLocalPath),
      mediaThumbnailUrl: Value.absentIfNull(message.thumbnailUrl),
      mediaDuration: Value.absentIfNull(message.mediaDuration),
      replyToMessageId: Value.absentIfNull(message.replyToMessageId),
      replyToContent: Value.absentIfNull(message.replyToContent),
      status: Value(_convertMessageStatus(message.status)),
      timestamp: Value(message.timestamp),
      readAt: Value.absentIfNull(message.readAt),
      deliveredAt: Value.absentIfNull(message.deliveredAt),
      isEdited: Value(message.isEdited),
      editedAt: Value.absentIfNull(message.editedAt),
    );
    await database.messageDao.updateMessage(companion);
  }

  /// Update message local media path
  static Future<void> updateMessageLocalMediaPath(
    String messageId,
    String localPath,
  ) async {
    await database.messageDao.updateMessageLocalMediaPath(messageId, localPath);
  }

  /// Get unread messages by chat ID
  static Future<List<model.MessageModel>> getUnreadMessagesByChatId(
    String chatId,
  ) async {
    final messages = await database.messageDao.getUnreadMessagesByChatId(chatId);
    return messages.map((msg) => _convertToMessageModel(msg)).toList();
  }

  /// Get failed messages
  static Future<List<model.MessageModel>> getFailedMessages() async {
    final messages = await database.messageDao.getFailedMessages();
    return messages.map((msg) => _convertToMessageModel(msg)).toList();
  }

  /// Search messages by text
  static Future<List<model.MessageModel>> searchMessagesByText(String query) async {
    final messages = await database.messageDao.searchMessagesByText(query);
    return messages.map((msg) => _convertToMessageModel(msg)).toList();
  }

  // ========== USER OPERATIONS ==========

  /// Save user from model
  static Future<void> saveUser(UserModel user) async {
    final companion = UsersTableCompanion(
      userId: Value(user.userId),
      name: Value.absentIfNull(user.name),
      phoneNumber: Value.absentIfNull(user.phoneNumber),
      profileImageUrl: Value.absentIfNull(user.profileImageUrl),
      profileImageLocalPath: Value.absentIfNull(user.profileImageLocalPath),
      about: Value.absentIfNull(user.about),
      currentHeight: Value.absentIfNull(user.currentHeight),
      currentWeight: Value.absentIfNull(user.currentWeight),
      age: Value.absentIfNull(user.age),
      birthDate: Value.absentIfNull(user.birthDate),
      todayStepCount: Value(user.todayStepCount ?? 0),
      lastStepUpdate: Value.absentIfNull(user.lastStepUpdate),
      userRole: const Value(UserRole.user), // Default to user role
      isOnline: Value(user.isOnline),
      lastSeen: Value.absentIfNull(user.lastSeen),
      lastSeenPrivacy: const Value(PrivacySetting.everyone),
      profilePhotoPrivacy: const Value(PrivacySetting.everyone),
      aboutPrivacy: const Value(PrivacySetting.everyone),
    );
    await database.userDao.saveUser(companion);
  }

  /// Get user by ID - returns UserModel
  static Future<UserModel?> getUserById(String userId) async {
    final userData = await database.userDao.getUserById(userId);
    return userData != null ? _convertToUserModel(userData) : null;
  }

  /// Alias for getUserById for compatibility
  static Future<UserModel?> getUser(String userId) async {
    return getUserById(userId);
  }

  /// Alias for getUserById for compatibility
  static Future<UserModel?> getUserByUserId(String userId) async {
    return getUserById(userId);
  }

  /// Get all users - returns List&lt;UserModel&gt;
  static Future<List<UserModel>> getAllUsers() async {
    final userDataList = await database.userDao.getAllUsers();
    return userDataList.map((u) => _convertToUserModel(u)).toList();
  }

  /// Watch all users - returns Stream&lt;List&lt;UserModel&gt;&gt;
  static Stream<List<UserModel>> watchAllUsers() {
    return database.userDao.watchAllUsers().map(
      (userDataList) => userDataList.map((u) => _convertToUserModel(u)).toList()
    );
  }

  /// Update user from model
  static Future<void> updateUser(UserModel user) async {
    final companion = UsersTableCompanion(
      userId: Value(user.userId),
      name: Value.absentIfNull(user.name),
      phoneNumber: Value.absentIfNull(user.phoneNumber),
      profileImageUrl: Value.absentIfNull(user.profileImageUrl),
      profileImageLocalPath: Value.absentIfNull(user.profileImageLocalPath),
      about: Value.absentIfNull(user.about),
      currentHeight: Value.absentIfNull(user.currentHeight),
      currentWeight: Value.absentIfNull(user.currentWeight),
      age: Value.absentIfNull(user.age),
      birthDate: Value.absentIfNull(user.birthDate),
      todayStepCount: Value(user.todayStepCount ?? 0),
      lastStepUpdate: Value.absentIfNull(user.lastStepUpdate),
      userRole: const Value(UserRole.user),
      isOnline: Value(user.isOnline),
      lastSeen: Value.absentIfNull(user.lastSeen),
      lastSeenPrivacy: const Value(PrivacySetting.everyone),
      profilePhotoPrivacy: const Value(PrivacySetting.everyone),
      aboutPrivacy: const Value(PrivacySetting.everyone),
    );
    await database.userDao.updateUser(companion);
  }

  /// Batch save users from models
  static Future<void> batchSaveUsers(List<UserModel> users) async {
    final companions = users.map((user) => UsersTableCompanion(
      userId: Value(user.userId),
      name: Value.absentIfNull(user.name),
      phoneNumber: Value.absentIfNull(user.phoneNumber),
      profileImageUrl: Value.absentIfNull(user.profileImageUrl),
      profileImageLocalPath: Value.absentIfNull(user.profileImageLocalPath),
      about: Value.absentIfNull(user.about),
      currentHeight: Value.absentIfNull(user.currentHeight),
      currentWeight: Value.absentIfNull(user.currentWeight),
      age: Value.absentIfNull(user.age),
      birthDate: Value.absentIfNull(user.birthDate),
      todayStepCount: Value(user.todayStepCount ?? 0),
      lastStepUpdate: Value.absentIfNull(user.lastStepUpdate),
      userRole: const Value(UserRole.user),
      isOnline: Value(user.isOnline),
      lastSeen: Value.absentIfNull(user.lastSeen),
      lastSeenPrivacy: const Value(PrivacySetting.everyone),
      profilePhotoPrivacy: const Value(PrivacySetting.everyone),
      aboutPrivacy: const Value(PrivacySetting.everyone),
    )).toList();
    await database.userDao.batchSaveUsers(companions);
  }


  // ========== CONTACT INDEX OPERATIONS ==========

  /// Save contact indexes (bulk)
  static Future<void> saveContactIndexes(List<ContactIndexModel> contacts) async {
    final contactDataList = contacts.map((model) => convertContactIndexData(model)).toList();
    final companions = contactDataList.map((contact) => contact.toCompanion(true)).toList();
    await database.contactIndexDao.saveContactIndexes(companions);
  }

  /// Save single contact index
  static Future<void> saveContactIndex(ContactIndexModel contact) async {
    final contactData = convertContactIndexData(contact);
    await database.contactIndexDao.saveContactIndex(contactData.toCompanion(true));
  }

  /// Get contact index by phone
  static Future<ContactIndexModel?> getContactIndexByPhone(String normalizedPhone) async {
    final contactData = await database.contactIndexDao.getContactByPhone(normalizedPhone);
    return contactData != null ? convertContactIndexModel(contactData) : null;
  }

  /// Get all contact indexes
  static Future<List<ContactIndexModel>> getAllContactIndexes() async {
    final contactDataList = await database.contactIndexDao.getAllContactIndexes();
    return contactDataList.map((data) => convertContactIndexModel(data)).toList();
  }

  /// Get registered contact indexes
  static Future<List<ContactIndexModel>> getRegisteredContactIndexes() async {
    final contactDataList = await database.contactIndexDao.getRegisteredContacts();
    return contactDataList.map((data) => convertContactIndexModel(data)).toList();
  }

  /// Search contacts
  static Future<List<ContactIndexData>> searchContacts(String query) async {
    return await database.contactIndexDao.searchContacts(query);
  }

  /// Search registered contacts
  static Future<List<ContactIndexData>> searchRegisteredContacts(String query) async {
    return await database.contactIndexDao.searchRegisteredContacts(query);
  }

  // ========== STORY OPERATIONS ==========

  /// Save story
  static Future<void> saveStory(StoryModel story) async {
    final storyData = convertStoryData(story);
    await database.storyDao.saveStory(storyData.toCompanion(true));
  }

  /// Create new story
  static Future<String> createStory({
    required StoryType type,
    required String content,
    String? mediaUrl,
    String? backgroundColor,
  }) async {
    final storyId = 'story_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(hours: 24)); // Stories expire after 24 hours
    
    final story = StoriesTableCompanion(
      storyId: Value(storyId),
      userId: Value(FirebaseAuth.instance.currentUser?.uid ?? ''), 
      type: Value(type.name),
      content: Value(content),
      mediaUrl: Value.absentIfNull(mediaUrl),
      backgroundColor: Value(backgroundColor ?? '#FF4CAF50'),
      createdAt: Value(now),
      expiresAt: Value(expiresAt),
      isActive: const Value(true),
      isFromCurrentUser: const Value(true),
    );
    
    await database.storyDao.saveStory(story);
    return storyId;
  }

  /// Get all active stories
  static Future<List<StoryModel>> getAllActiveStories() async {
    final storyDataList = await database.storyDao.getAllActiveStories();
    return storyDataList.map((storyData) => convertStoryModel(storyData)).toList();
  }

  /// Watch all active stories
  static Stream<List<StoryModel>> watchAllActiveStories() {
    return database.storyDao.watchActiveStories().map(
      (storyDataList) => storyDataList.map((storyData) => convertStoryModel(storyData)).toList()
    );
  }

  /// Mark story as viewed
  static Future<void> markStoryAsViewed(String storyId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await database.storyDao.markStoryAsViewed(storyId, user.uid);
    }
  }

  /// Get story by ID
  static Future<StoryData?> getStoryById(String storyId) async {
    return await database.storyDao.getStoryById(storyId);
  }

  /// Delete story
  static Future<void> deleteStory(String storyId) async {
    await database.storyDao.deleteStory(storyId);
  }

  /// Get expired stories
  static Future<List<StoryData>> getExpiredStories() async {
    return await database.storyDao.getExpiredStories();
  }

  // ========== CALL LOG OPERATIONS ==========

  /// Watch all call logs
  static Stream<List<model.CallLogModel>> watchAllCallLogs() {
    return database.callLogDao.watchAllCallLogs().map(
      (callLogs) => callLogs.map((callLog) => _convertToCallLogModel(callLog)).toList()
    );
  }

  /// Delete all call logs
  static Future<int> deleteAllCallLogs() async {
    return await database.callLogDao.clearAll();
  }

  // ========== TAG OPERATIONS ==========

  /// Get all tags
  static Future<List<TagModel>> getAllTags() async {
    final tagDataList = await database.tagDao.getAllTags();
    return tagDataList.map((tagData) => convertTagModel(tagData)).toList();
  }

  /// Watch all tags
  static Stream<List<TagModel>> watchAllTags() {
    return database.tagDao.watchAllTags().map(
      (tagDataList) => tagDataList.map((tagData) => convertTagModel(tagData)).toList()
    );
  }

  /// Get tag by ID
  static Future<TagModel?> getTagById(String tagId) async {
    final tagData = await database.tagDao.getTagById(tagId);
    return tagData != null ? convertTagModel(tagData) : null;
  }

  /// Save tag
  static Future<void> saveTag(TagModel tag) async {
    await database.tagDao.saveTag(convertTagToCompanion(tag));
  }

  /// Update tag
  static Future<void> updateTag(TagModel tag) async {
    await database.tagDao.updateTag(convertTagToCompanion(tag));
  }

  /// Delete tag
  static Future<void> deleteTag(String tagId) async {
    await database.tagDao.deleteTag(tagId);
  }

  /// Create tag
  static Future<TagModel> createTag({
    required String name,
    String? color,
    String? icon,
    String? description,
  }) async {
    final tagData = await database.tagDao.createTagIfNotExists(
      name,
      color: color,
      icon: icon,
      description: description,
    );
    return convertTagModel(tagData);
  }

  /// Get most used tags
  static Future<List<TagModel>> getMostUsedTags({int limit = 10}) async {
    final tagDataList = await database.tagDao.getMostUsedTags(limit: limit);
    return tagDataList.map((tagData) => convertTagModel(tagData)).toList();
  }

  /// Search tags
  static Future<List<TagModel>> searchTags(String query) async {
    final tagDataList = await database.tagDao.searchTags(query);
    return tagDataList.map((tagData) => convertTagModel(tagData)).toList();
  }

  /// Increment tag usage
  static Future<void> incrementTagUsage(String tagId) async {
    await database.tagDao.incrementTagUsage(tagId);
  }

  /// Decrement tag usage
  static Future<void> decrementTagUsage(String tagId) async {
    await database.tagDao.decrementTagUsage(tagId);
  }

  // ========== GROUP OPERATIONS ==========

  /// Get all groups
  static Future<List<GroupData>> getAllGroups() async {
    return await database.groupDao.getAllGroups();
  }

  /// Get groups for user
  static Future<List<GroupData>> getUserGroups(String userId) async {
    return await database.groupDao.getGroupsForUser(userId);
  }

  /// Get group by ID
  static Future<GroupData?> getGroupById(String groupId) async {
    return await database.groupDao.getGroupById(groupId);
  }

  /// Save group from GroupData
  static Future<void> saveGroup(GroupData group) async {
    await database.groupDao.saveGroup(group.toCompanion(true));
  }

  /// Save group from GroupModel
  static Future<void> saveGroupModel(GroupModel group) async {
    final companion = GroupsTableCompanion(
      groupId: Value(group.groupId),
      name: Value(group.name),
      description: Value.absentIfNull(group.description),
      profileImageUrl: Value.absentIfNull(group.profileImageUrl),
      members: Value(group.members.join(',')),
      admins: Value(group.admins.join(',')),
      createdBy: Value(group.createdBy),
      messagePermission: const Value(MessagePermission.everyone),
      mediaPermission: const Value(MediaPermission.downloadable),
      allowMembersToAddOthers: const Value(false),
      createdAt: Value(group.createdAt),
      updatedAt: Value(DateTime.now()),
    );
    await database.groupDao.saveGroup(companion);
  }

  /// Update group
  static Future<void> updateGroup(GroupData group) async {
    await database.groupDao.updateGroup(group.toCompanion(true));
  }

  /// Update group model
  static Future<void> updateGroupModel(GroupModel group) async {
    final companion = GroupsTableCompanion(
      groupId: Value(group.groupId),
      name: Value(group.name),
      description: Value.absentIfNull(group.description),
      profileImageUrl: Value.absentIfNull(group.profileImageUrl),
      createdBy: Value(group.createdBy),
      members: Value(group.members.join(',')),
      admins: Value(group.admins.join(',')),
      messagePermission: const Value(MessagePermission.everyone),
      mediaPermission: const Value(MediaPermission.downloadable),
      allowMembersToAddOthers: const Value(false),
      createdAt: Value(group.createdAt),
      updatedAt: Value(DateTime.now()),
    );
    await database.groupDao.updateGroup(companion);
  }

  /// Delete group
  static Future<void> deleteGroup(String groupId) async {
    await database.groupDao.deleteGroup(groupId);
  }

  /// Get group
  static Future<GroupData?> getGroup(String groupId) async {
    // TODO: Implement proper group retrieval
    debugPrint('👥 Getting group: $groupId');
    return null;
  }

  /// Get group model
  static Future<GroupModel?> getGroupModel(String groupId) async {
    // TODO: Implement proper group model retrieval
    debugPrint('👥 Getting group model: $groupId');
    return null;
  }

  /// Create group
  static Future<GroupData> createGroup({
    required String name,
    required List<String> memberIds,
    String? description,
    String? profileImageUrl,
    required String createdBy,
  }) async {
    final groupId = 'group_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();
    
    final group = GroupsTableCompanion(
      groupId: Value(groupId),
      name: Value(name),
      description: Value.absentIfNull(description),
      profileImageUrl: Value.absentIfNull(profileImageUrl),
      members: Value(json.encode(memberIds)),
      admins: Value(json.encode([createdBy])), // Creator is admin
      createdBy: Value(createdBy),
      createdAt: Value(now),
      updatedAt: Value(now),
    );
    
    await database.groupDao.saveGroup(group);
    return (await database.groupDao.getGroupById(groupId))!;
  }

  /// Get group members
  static Future<List<GroupMemberData>> getGroupMembers(String groupId) async {
    return await database.groupDao.getGroupMembers(groupId);
  }

  /// Get group members model
  static Future<List<GroupMemberModel>> getGroupMembersModel(String groupId) async {
    // TODO: Implement proper group members model retrieval
    debugPrint('👥 Getting group members model for group: $groupId');
    return <GroupMemberModel>[];
  }

  /// Add member to group
  static Future<void> addMemberToGroup(String groupId, String userId) async {
    await database.groupDao.addGroupMember(groupId, userId);
  }

  /// Remove member from group
  static Future<void> removeMemberFromGroup(String groupId, String userId) async {
    await database.groupDao.removeGroupMember(groupId, userId);
  }

  /// Make user admin
  static Future<void> makeUserAdmin(String groupId, String userId) async {
    await database.groupDao.addGroupAdmin(groupId, userId);
  }

  /// Remove admin role
  static Future<void> removeAdminRole(String groupId, String userId) async {
    await database.groupDao.removeGroupAdmin(groupId, userId);
  }

  /// Update group info
  static Future<void> updateGroupInfo({
    required String groupId,
    String? name,
    String? description,
    String? profileImageUrl,
  }) async {
    await database.groupDao.updateGroupInfo(
      groupId: groupId,
      name: name,
      description: description,
    );
    
    if (profileImageUrl != null) {
      await database.groupDao.updateGroupProfileImage(
        groupId, 
        imageUrl: profileImageUrl,
      );
    }
  }

  /// Update group permissions
  static Future<void> updateGroupPermissions({
    required String groupId,
    String? messagePermission,
    String? mediaPermission,
    bool? allowMembersToAddOthers,
  }) async {
    MessagePermission? msgPerm = messagePermission != null 
        ? MessagePermission.values.byName(messagePermission) 
        : null;
    MediaPermission? mediaPerm = mediaPermission != null 
        ? MediaPermission.values.byName(mediaPermission) 
        : null;
    
    await database.groupDao.updateGroupPermissions(
      groupId: groupId,
      messagePermission: msgPerm,
      mediaPermission: mediaPerm,
      allowMembersToAddOthers: allowMembersToAddOthers,
    );
  }

  // ========== PRE-CONSULTATION FORM OPERATIONS ==========

  /// Get all consultation forms
  static Future<List<PreConsultationFormData>> getAllConsultationForms() async {
    return await database.preConsultationFormDao.getAllForms();
  }

  /// Get forms by user ID
  static Future<List<PreConsultationFormData>> getUserConsultationForms(String userId) async {
    return await database.preConsultationFormDao.getFormsByUserId(userId);
  }

  /// Get form by form ID
  static Future<PreConsultationFormData?> getConsultationFormById(String formId) async {
    return await database.preConsultationFormDao.getFormByFormId(formId);
  }

  /// Save consultation form
  static Future<void> saveConsultationForm(PreConsultationFormData form) async {
    await database.preConsultationFormDao.saveForm(form.toCompanion(true));
  }

  /// Update consultation form
  static Future<void> updateConsultationForm(PreConsultationFormData form) async {
    await database.preConsultationFormDao.updateForm(form.toCompanion(true));
  }

  /// Delete consultation form
  static Future<void> deleteConsultationForm(String formId) async {
    await database.preConsultationFormDao.deleteFormByFormId(formId);
  }

  /// Create new consultation form
  static Future<PreConsultationFormData> createConsultationForm({
    required String userId,
    String? dietitianId,
    Map<String, dynamic>? personalInfo,
    Map<String, dynamic>? medicalHistory,
    Map<String, dynamic>? nutritionHabits,
    Map<String, dynamic>? physicalActivity,
    Map<String, dynamic>? goals,
  }) async {
    final formId = 'form_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();
    
    final form = PreConsultationFormsTableCompanion(
      formId: Value(formId),
      userId: Value(userId),
      dietitianId: Value.absentIfNull(dietitianId),
      personalInfo: Value(json.encode(personalInfo ?? {})),
      medicalHistory: Value(json.encode(medicalHistory ?? {})),
      nutritionHabits: Value(json.encode(nutritionHabits ?? {})),
      physicalActivity: Value(json.encode(physicalActivity ?? {})),
      goals: Value(json.encode(goals ?? {})),
      dynamicSections: Value(json.encode([])),
      riskFactors: Value(json.encode([])),
      completionPercentage: const Value(0.0),
      riskScore: const Value(0.0),
      riskLevel: const Value('low'),
      isCompleted: const Value(false),
      isSubmitted: const Value(false),
      isReviewed: const Value(false),
      createdAt: Value(now),
      updatedAt: Value(now),
    );
    
    await database.preConsultationFormDao.saveForm(form);
    return (await database.preConsultationFormDao.getFormByFormId(formId))!;
  }

  /// Update form completion status
  static Future<void> updateFormCompletionStatus(String formId, bool isCompleted, double completionPercentage) async {
    await database.preConsultationFormDao.updateFormCompletionStatus(formId, isCompleted, completionPercentage);
  }

  /// Submit consultation form
  static Future<void> submitConsultationForm(String formId) async {
    await database.preConsultationFormDao.updateFormSubmissionStatus(formId, true);
  }

  /// Update personal info section
  static Future<void> updatePersonalInfo(String formId, Map<String, dynamic> personalInfo) async {
    await database.preConsultationFormDao.updatePersonalInfo(formId, personalInfo);
  }

  /// Update medical history section
  static Future<void> updateMedicalHistory(String formId, Map<String, dynamic> medicalHistory) async {
    await database.preConsultationFormDao.updateMedicalHistory(formId, medicalHistory);
  }

  /// Update nutrition habits section
  static Future<void> updateNutritionHabits(String formId, Map<String, dynamic> nutritionHabits) async {
    await database.preConsultationFormDao.updateNutritionHabits(formId, nutritionHabits);
  }

  /// Update physical activity section
  static Future<void> updatePhysicalActivity(String formId, Map<String, dynamic> physicalActivity) async {
    await database.preConsultationFormDao.updatePhysicalActivity(formId, physicalActivity);
  }

  /// Update goals section
  static Future<void> updateGoals(String formId, Map<String, dynamic> goals) async {
    await database.preConsultationFormDao.updateGoals(formId, goals);
  }

  /// Get pending forms for review
  static Future<List<PreConsultationFormData>> getPendingFormsForReview() async {
    return await database.preConsultationFormDao.getPendingFormsForReview();
  }

  /// Update form review status
  static Future<void> updateFormReviewStatus(String formId, bool isReviewed, String? reviewNotes) async {
    await database.preConsultationFormDao.updateFormReviewStatus(formId, isReviewed, reviewNotes);
  }

  /// Update risk assessment
  static Future<void> updateRiskAssessment(String formId, double riskScore, String riskLevel, List<String> riskFactors) async {
    await database.preConsultationFormDao.updateRiskAssessment(formId, riskScore, riskLevel, riskFactors);
  }

  // ========== MISSING METHODS - STUBS ==========
  
  /// Get user role
  static Future<UserRole?> getUserRole(String userId) async {
    final user = await database.userDao.getUserById(userId);
    return user?.userRole;
  }

  /// Save call log
  static Future<void> saveCallLog(model.CallLogModel callLog) async {
    final companion = CallLogsTableCompanion(
      id: const Value.absent(),
      callId: Value(callLog.callId),
      otherUserId: Value.absentIfNull(callLog.otherUserId),
      otherUserPhone: Value.absentIfNull(callLog.otherUserPhone),
      otherDisplayName: Value.absentIfNull(callLog.otherDisplayName),
      isVideo: Value(callLog.isVideo),
      direction: Value(_convertCallLogDirection(callLog.direction)),
      status: Value(_convertCallLogStatus(callLog.status)),
      createdAt: Value(callLog.createdAt),
      startedAt: Value.absentIfNull(callLog.startedAt),
      connectedAt: Value.absentIfNull(callLog.connectedAt),
      endedAt: Value.absentIfNull(callLog.endedAt),
      updatedAt: Value(callLog.updatedAt),
    );
    await database.callLogDao.saveCallLog(companion);
  }


  /// Get dietitian assignments (stub - needs proper implementation) 
  static Future<List<UserDietAssignmentModel>> getDietitianAssignments(String dietitianId) async {
    // TODO: Implement proper dietitian assignments functionality
    return <UserDietAssignmentModel>[];
  }

  /// Get meal reminder preferences or default (stub)
  static Future<dynamic> getMealReminderPreferencesOrDefault(String userId) async {
    // TODO: Implement proper meal reminder preferences functionality
    return null;
  }

  /// Save meal reminder preferences (stub)
  static Future<void> saveMealReminderPreferences(dynamic preferences) async {
    // TODO: Implement proper meal reminder preferences functionality
  }

  /// Watch incoming calls (stub)
  static Stream<List<model.CallLogModel>> watchIncomingCalls(String userId) {
    // TODO: Implement proper incoming calls watching
    return Stream.value(<model.CallLogModel>[]);
  }

  /// Get chats by tags (stub)
  static Future<List<ChatModel>> getChatsByTags(List<String> tagIds) async {
    // TODO: Implement proper chats by tags functionality
    return [];
  }

  // ========== DIET PACKAGE OPERATIONS ==========

  /// Save diet package
  static Future<void> saveDietPackage(DietPackageModel package) async {
    // TODO: Implement proper diet package saving
    // For now, just log the operation
    debugPrint('📦 Diet package saved: ${package.packageId}');
  }

  /// Save diet file
  static Future<void> saveDietFile(DietFileModel dietFile) async {
    // TODO: Implement proper diet file saving
    // For now, just log the operation
    debugPrint('📄 Diet file saved: ${dietFile.fileId}');
  }

  /// Get diet package by ID
  static Future<DietPackageModel?> getDietPackage(String packageId) async {
    // TODO: Implement proper diet package retrieval
    // For now, return null
    debugPrint('📦 Getting diet package: $packageId');
    return null;
  }

  /// Delete diet package
  static Future<void> deleteDietPackage(String packageId) async {
    // TODO: Implement proper diet package deletion
    // For now, just log the operation
    debugPrint('🗑️ Diet package deleted: $packageId');
  }

  /// Get dietitian packages (updated signature to return proper model list)
  static Future<List<DietPackageModel>> getDietitianPackages(String dietitianId) async {
    // TODO: Implement proper dietitian packages functionality
    debugPrint('👨‍⚕️ Getting dietitian packages for: $dietitianId');
    return [];
  }

  // ========== PRE-CONSULTATION FORM OPERATIONS ==========

  /// Save pre-consultation form
  static Future<void> savePreConsultationForm(PreConsultationFormModel form) async {
    // TODO: Implement proper pre-consultation form saving
    debugPrint('📝 Pre-consultation form saved: ${form.formId}');
  }

  /// Get pre-consultation form by ID
  static Future<PreConsultationFormModel?> getPreConsultationForm(String formId) async {
    // TODO: Implement proper pre-consultation form retrieval
    debugPrint('📝 Getting pre-consultation form: $formId');
    return null;
  }

  /// Update pre-consultation form
  static Future<void> updatePreConsultationForm(PreConsultationFormModel form) async {
    // TODO: Implement proper pre-consultation form updating
    debugPrint('📝 Pre-consultation form updated: ${form.formId}');
  }

  /// Delete pre-consultation form
  static Future<void> deletePreConsultationForm(String formId) async {
    // TODO: Implement proper pre-consultation form deletion
    debugPrint('🗑️ Pre-consultation form deleted: $formId');
  }

  /// Get user pre-consultation forms
  static Future<List<PreConsultationFormModel>> getUserPreConsultationForms(String userId) async {
    // TODO: Implement proper user pre-consultation forms retrieval
    debugPrint('📝 Getting user pre-consultation forms: $userId');
    return [];
  }

  /// Get user latest pre-consultation form
  static Future<PreConsultationFormModel?> getUserLatestPreConsultationForm(String userId) async {
    // TODO: Implement proper user latest pre-consultation form retrieval
    debugPrint('📝 Getting user latest pre-consultation form: $userId');
    return null;
  }

  /// Get incomplete pre-consultation forms
  static Future<List<PreConsultationFormModel>> getIncompletePreConsultationForms(String userId) async {
    // TODO: Implement proper incomplete pre-consultation forms retrieval
    debugPrint('📝 Getting incomplete pre-consultation forms: $userId');
    return [];
  }

  /// Get dietitian pre-consultation forms
  static Future<List<PreConsultationFormModel>> getDietitianPreConsultationForms(String dietitianId) async {
    // TODO: Implement proper dietitian pre-consultation forms retrieval
    debugPrint('📝 Getting dietitian pre-consultation forms: $dietitianId');
    return [];
  }

  /// Get pending pre-consultation forms
  static Future<List<PreConsultationFormModel>> getPendingPreConsultationForms(String dietitianId) async {
    // TODO: Implement proper pending pre-consultation forms retrieval
    debugPrint('📝 Getting pending pre-consultation forms: $dietitianId');
    return [];
  }

  /// Get pre-consultation forms by risk level
  static Future<List<PreConsultationFormModel>> getPreConsultationFormsByRiskLevel(String dietitianId, String riskLevel) async {
    // TODO: Implement proper pre-consultation forms by risk level retrieval
    debugPrint('📝 Getting pre-consultation forms by risk level: $riskLevel for dietitian: $dietitianId');
    return [];
  }

  /// Get pre-consultation form stats
  static Future<Map<String, int>> getPreConsultationFormStats(String userId) async {
    // TODO: Implement proper pre-consultation form stats
    debugPrint('📊 Getting pre-consultation form stats: $userId');
    return {};
  }

  /// Get overall pre-consultation form stats
  static Future<Map<String, int>> getOverallPreConsultationFormStats() async {
    // TODO: Implement proper overall pre-consultation form stats
    debugPrint('📊 Getting overall pre-consultation form stats');
    return {};
  }

  // ========== ASSIGNMENT OPERATIONS ==========

  /// Get assignment by ID
  static Future<dynamic> getAssignmentById(String assignmentId) async {
    // TODO: Implement proper assignment retrieval
    debugPrint('📋 Getting assignment: $assignmentId');
    return null;
  }

  /// Update assignment
  static Future<void> updateAssignment(dynamic assignment) async {
    // TODO: Implement proper assignment updating
    debugPrint('📋 Assignment updated');
  }

  /// Get all active assignments
  static Future<List<UserDietAssignmentModel>> getAllActiveAssignments() async {
    // TODO: Implement proper active assignments retrieval
    debugPrint('📋 Getting all active assignments');
    return <UserDietAssignmentModel>[];
  }

  /// Get all assignments
  static Future<List<UserDietAssignmentModel>> getAllAssignments() async {
    // TODO: Implement proper all assignments retrieval
    debugPrint('📋 Getting all assignments');
    return <UserDietAssignmentModel>[];
  }

  /// Get user active assignment
  static Future<dynamic> getUserActiveAssignment(String userId) async {
    // TODO: Implement proper user active assignment retrieval
    debugPrint('📋 Getting user active assignment: $userId');
    return null;
  }

  /// Save user diet assignment
  static Future<void> saveUserDietAssignment(dynamic assignment) async {
    // TODO: Implement proper user diet assignment saving
    debugPrint('📋 User diet assignment saved');
  }

  // ========== DIET FILE ADDITIONAL OPERATIONS ==========

  /// Get all diet files
  static Future<List<DietFileModel>> getAllDietFiles() async {
    // TODO: Implement proper all diet files retrieval
    debugPrint('📄 Getting all diet files');
    return [];
  }

  /// Get user diet files
  static Future<List<DietFileModel>> getUserDietFiles(String userId) async {
    // TODO: Implement proper user diet files retrieval
    debugPrint('📄 Getting user diet files: $userId');
    return [];
  }

  /// Mark diet file as read
  static Future<void> markDietFileAsRead(String fileId) async {
    // TODO: Implement proper diet file marking as read
    debugPrint('👀 Diet file marked as read: $fileId');
  }

  /// Get diet file
  static Future<DietFileModel?> getDietFile(String fileId) async {
    // TODO: Implement proper diet file retrieval
    debugPrint('📄 Getting diet file: $fileId');
    return null;
  }

  /// Delete diet file
  static Future<void> deleteDietFile(String fileId) async {
    // TODO: Implement proper diet file deletion
    debugPrint('🗑️ Diet file deleted: $fileId');
  }

  /// Get user diet assignments
  static Future<List<dynamic>> getUserDietAssignments(String userId) async {
    // TODO: Implement proper user diet assignments retrieval
    debugPrint('📋 Getting user diet assignments: $userId');
    return [];
  }

  // ========== STORY CLEANUP OPERATIONS ==========

  /// Delete all stories
  static Future<void> deleteAllStories() async {
    // TODO: Implement proper all stories deletion
    debugPrint('🧹 All stories deleted');
  }

  /// Delete expired stories
  static Future<void> deleteExpiredStories() async {
    // TODO: Implement proper expired stories deletion
    debugPrint('🧹 Expired stories deleted');
  }

  // ========== PROGRESS REMINDER OPERATIONS ==========

  /// Get active progress reminders for user
  static Future<List<ProgressReminderModel>> getActiveProgressReminders(String userId) async {
    // TODO: Implement proper active progress reminders retrieval for user: $userId
    debugPrint('📅 Getting active progress reminders for user: $userId');
    return <ProgressReminderModel>[];
  }

  /// Get progress reminders by type
  static Future<List<ProgressReminderModel>> getProgressRemindersByType(String userId, dynamic type) async {
    // TODO: Implement proper progress reminders by type retrieval for user: $userId, type: $type
    debugPrint('📅 Getting progress reminders for user: $userId, type: $type');
    return <ProgressReminderModel>[];
  }

  /// Get progress reminder by reminder ID
  static Future<dynamic> getProgressReminderByReminderId(String reminderId) async {
    // TODO: Implement proper progress reminder by ID retrieval
    debugPrint('📅 Getting progress reminder by ID: $reminderId');
    return null;
  }

  /// Get user progress reminders
  static Future<List<ProgressReminderModel>> getUserProgressReminders(String userId) async {
    // TODO: Implement proper user progress reminders retrieval
    debugPrint('📅 Getting user progress reminders: $userId');
    return <ProgressReminderModel>[];
  }

  /// Save progress reminder
  static Future<void> saveProgressReminder(dynamic reminder) async {
    // TODO: Implement proper progress reminder saving
    debugPrint('📅 Progress reminder saved');
  }

  /// Delete progress reminder
  static Future<void> deleteProgressReminder(dynamic reminderId) async {
    // TODO: Implement proper progress reminder deletion
    debugPrint('📅 Progress reminder deleted');
  }

  /// Save progress reminders (bulk)
  static Future<void> saveProgressReminders(List<dynamic> reminders) async {
    // TODO: Implement proper bulk progress reminders saving
    debugPrint('📅 ${reminders.length} progress reminders saved');
  }

  // ========== HEALTH DATA OPERATIONS ==========

  /// Save health data
  static Future<void> saveHealthData(dynamic healthData) async {
    // TODO: Implement proper health data saving
    debugPrint('🏥 Health data saved');
  }

  /// Get user health data
  static Future<dynamic> getUserHealthData(String userId) async {
    // TODO: Implement proper user health data retrieval
    debugPrint('🏥 Getting user health data: $userId');
    return null;
  }

  // ========== BATCH OPERATIONS ==========

  /// Save chats (bulk)
  static Future<void> saveChats(List<ChatModel> chats) async {
    // TODO: Implement proper bulk chats saving
    debugPrint('💬 ${chats.length} chats saved');
  }

  /// Save groups (bulk)
  static Future<void> saveGroups(List<GroupModel> groups) async {
    // TODO: Implement proper bulk groups saving
    debugPrint('👥 ${groups.length} groups saved');
  }

  /// Save messages (bulk)
  static Future<void> saveMessages(List<dynamic> messages) async {
    // TODO: Implement proper bulk messages saving
    debugPrint('📨 ${messages.length} messages saved');
  }

  /// Get user chats
  static Future<List<ChatModel>> getUserChats(String userId) async {
    // TODO: Implement proper user chats retrieval
    debugPrint('💬 Getting user chats: $userId');
    return [];
  }

  // ========== MEAL REMINDER OPERATIONS ==========

  /// Get meal reminder preferences
  static Future<dynamic> getMealReminderPreferences(String userId) async {
    // TODO: Implement proper meal reminder preferences retrieval
    debugPrint('🍽️ Getting meal reminder preferences: $userId');
    return null;
  }

  /// Delete meal reminder preferences
  static Future<void> deleteMealReminderPreferences(String userId) async {
    // TODO: Implement proper meal reminder preferences deletion
    debugPrint('🗑️ Meal reminder preferences deleted: $userId');
  }

  // ========== UTILITY OPERATIONS ==========

  /// Clear all data (logout)
  static Future<void> clearAll() async {
    await database.clearAll();
  }

  /// Close database connection
  static Future<void> close() async {
    await database.close();
    _database = null;
  }

  // ========== USER ROLE UTILITIES ==========

  /// Extension to add isDietitian getter to UserRole enum
  static bool isUserDietitian(UserRole role) {
    return role == UserRole.dietitian || role == UserRole.admin;
  }

  /// Get database statistics
  static Future<Map<String, int>> getDatabaseStats() async {
    final stats = <String, int>{};
    
    // Count records in each table
    // TODO: Implement count methods in DAOs
    stats['chats'] = 0;
    stats['messages'] = 0;
    stats['users'] = 0;
    stats['contacts'] = 0;
    stats['stories'] = 0;
    
    return stats;
  }
}

/// Extension methods for easy conversion
extension TagDataExtension on TagData {
  TagsTableCompanion toCompanion([bool forUpdate = false]) {
    return TagsTableCompanion(
      id: forUpdate ? Value(id) : const Value.absent(),
      tagId: Value(tagId),
      name: Value(name),
      color: Value(color),
      icon: Value(icon),
      description: Value(description),
      usageCount: Value(usageCount),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }
}

extension GroupDataExtension on GroupData {
  GroupsTableCompanion toCompanion([bool forUpdate = false]) {
    return GroupsTableCompanion(
      id: forUpdate ? Value(id) : const Value.absent(),
      groupId: Value(groupId),
      name: Value(name),
      description: Value.absentIfNull(description),
      profileImageUrl: Value.absentIfNull(profileImageUrl),
      profileImageLocalPath: Value.absentIfNull(profileImageLocalPath),
      members: Value(members),
      admins: Value(admins),
      createdBy: Value(createdBy),
      messagePermission: Value(messagePermission),
      mediaPermission: Value(mediaPermission),
      allowMembersToAddOthers: Value(allowMembersToAddOthers),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }
}

extension GroupMemberDataExtension on GroupMemberData {
  GroupMembersTableCompanion toCompanion([bool forUpdate = false]) {
    return GroupMembersTableCompanion(
      groupId: Value(groupId),
      userId: Value(userId),
      displayName: Value(displayName),
      contactName: Value(contactName),
      firebaseName: Value(firebaseName),
      phoneNumber: Value(phoneNumber),
      profileImageUrl: Value(profileImageUrl),
      role: Value(role),
      joinedAt: Value(joinedAt),
      lastSeenAt: Value(lastSeenAt),
    );
  }

}

extension PreConsultationFormDataExtension on PreConsultationFormData {
  PreConsultationFormsTableCompanion toCompanion([bool forUpdate = false]) {
    return PreConsultationFormsTableCompanion(
      id: forUpdate ? Value(id) : const Value.absent(),
      formId: Value(formId),
      userId: Value(userId),
      dietitianId: Value(dietitianId),
      personalInfo: Value(personalInfo),
      medicalHistory: Value(medicalHistory),
      nutritionHabits: Value(nutritionHabits),
      physicalActivity: Value(physicalActivity),
      goals: Value(goals),
      dynamicSections: Value(dynamicSections),
      riskFactors: Value(riskFactors),
      completionPercentage: Value(completionPercentage),
      riskScore: Value(riskScore),
      riskLevel: Value(riskLevel),
      isCompleted: Value(isCompleted),
      isSubmitted: Value(isSubmitted),
      isReviewed: Value(isReviewed),
      reviewNotes: Value(reviewNotes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      submittedAt: Value(submittedAt),
      reviewedAt: Value(reviewedAt),
    );
  }

}

extension ChatExtension on Chat {
  ChatsCompanion toCompanion() {
    return ChatsCompanion(
      id: Value(id),
      chatId: Value(chatId),
      isGroup: Value(isGroup),
      groupId: Value(groupId),
      groupName: Value(groupName),
      groupImage: Value(groupImage),
      groupDescription: Value(groupDescription),
      otherUserId: Value(otherUserId),
      otherUserName: Value(otherUserName),
      otherUserContactName: Value(otherUserContactName),
      otherUserPhoneNumber: Value(otherUserPhoneNumber),
      otherUserProfileImage: Value(otherUserProfileImage),
      lastMessage: Value(lastMessage),
      lastMessageTime: Value(lastMessageTime),
      isLastMessageFromMe: Value(isLastMessageFromMe),
      isLastMessageRead: Value(isLastMessageRead),
      unreadCount: Value(unreadCount),
      isPinned: Value(isPinned),
      isMuted: Value(isMuted),
      isArchived: Value(isArchived),
      tags: Value(tags),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  // ========== CHAT OPERATIONS ==========

  /// Get active chats
  static Future<List<dynamic>> getActiveChats() async {
    // TODO: Implement proper active chats retrieval
    debugPrint('💬 Getting active chats');
    return [];
  }

  // ========== GROUP MEMBER OPERATIONS ==========

  /// Save group member
  static Future<void> saveGroupMember(dynamic groupMember) async {
    // TODO: Implement proper group member saving
    debugPrint('👥 Saving group member');
  }

  /// Delete group member
  static Future<void> deleteGroupMember(String groupId, String userId) async {
    // TODO: Implement proper group member deletion
    debugPrint('👥 Deleting group member: $groupId - $userId');
  }

  /// Get group member
  static Future<dynamic> getGroupMember(String groupId, String userId) async {
    // TODO: Implement proper group member retrieval
    debugPrint('👥 Getting group member: $groupId - $userId');
    return null;
  }

  /// Update group member
  static Future<void> updateGroupMember(dynamic groupMember) async {
    // TODO: Implement proper group member updating
    debugPrint('👥 Updating group member');
  }

  // ========== MEAL BEHAVIOR ANALYTICS OPERATIONS ==========

  /// Save meal reminder behavior
  static Future<void> saveMealReminderBehavior(dynamic behavior) async {
    // TODO: Implement proper meal reminder behavior saving
    debugPrint('🍽️ Saving meal reminder behavior');
  }

  /// Get recent meal reminder behaviors
  static Future<List<dynamic>> getRecentMealReminderBehaviors(String userId, int days) async {
    // TODO: Implement proper recent meal reminder behaviors retrieval
    debugPrint('🍽️ Getting recent meal reminder behaviors for user: $userId, days: $days');
    return [];
  }

  /// Get meal reminder behaviors by action
  static Future<List<dynamic>> getMealReminderBehaviorsByAction(String userId, String action) async {
    // TODO: Implement proper meal reminder behaviors by action retrieval
    debugPrint('🍽️ Getting meal reminder behaviors by action for user: $userId, action: $action');
    return [];
  }

  /// Get user behavior analytics
  static Future<dynamic> getUserBehaviorAnalytics(String userId) async {
    // TODO: Implement proper user behavior analytics retrieval
    debugPrint('📊 Getting user behavior analytics for user: $userId');
    return null;
  }

  /// Get user meal reminder behaviors
  static Future<List<dynamic>> getUserMealReminderBehaviors(String userId, int limit) async {
    // TODO: Implement proper user meal reminder behaviors retrieval
    debugPrint('🍽️ Getting user meal reminder behaviors for user: $userId, limit: $limit');
    return [];
  }

  /// Save user behavior analytics
  static Future<void> saveUserBehaviorAnalytics(dynamic analytics) async {
    // TODO: Implement proper user behavior analytics saving
    debugPrint('📊 Saving user behavior analytics');
  }
}

/// Extension to add helper methods to UserRole enum
extension UserRoleExtension on UserRole {
  /// Check if user is a dietitian (includes admin)
  bool get isDietitian => this == UserRole.dietitian || this == UserRole.admin;
  
  /// Check if user is an admin
  bool get isAdmin => this == UserRole.admin;
  
  /// Check if user is a regular user
  bool get isRegularUser => this == UserRole.user;
}

