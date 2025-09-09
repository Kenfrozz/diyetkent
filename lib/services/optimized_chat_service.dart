import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_model.dart';

class OptimizedChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔥 MALIYET OPTIMIZASYONU: Pagination ile chat yükleme
  static Future<List<ChatModel>> getChatsWithPagination({
    DocumentSnapshot? lastDocument,
    int limit = 20,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];

      Query query = _firestore
          .collection('chats')
          .where('participants', arrayContains: user.uid)
          .orderBy('lastMessageTime', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      final chats = <ChatModel>[];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // ChatModel'e dönüştür
        final chat = ChatModel.create(
          chatId: data['chatId'] ?? doc.id,
          otherUserId: _getOtherUserId(data['participants'], user.uid),
          otherUserName: _getOtherUserName(data['participantNames'], user.uid),
          lastMessage: data['lastMessage'] ?? '',
          lastMessageTime: data['lastMessageTime'] != null
              ? (data['lastMessageTime'] as Timestamp).toDate()
              : DateTime.now(),
          isLastMessageFromMe: data['isLastMessageFromMe'] ?? false,
          isLastMessageRead: data['isLastMessageRead'] ?? true,
          unreadCount: data['unreadCount'] ?? 0,
        );

        chats.add(chat);
      }

      return chats;
    } catch (e) {
      debugPrint('❌ Paginated chat yükleme hatası: $e');
      return [];
    }
  }

  // 🔥 MALIYET OPTIMIZASYONU: Belirli zaman aralığındaki mesajları getir
  static Stream<QuerySnapshot> getRecentMessages(
    String chatId, {
    int days = 7,
    int limit = 50,
  }) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));

    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(cutoffDate))
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }

  // 🔥 MALIYET OPTIMIZASYONU: Batch ile çoklu mesaj işlemleri
  static Future<void> markMultipleMessagesAsRead(
    List<String> messageIds,
    String chatId,
  ) async {
    try {
      final batch = _firestore.batch();

      // Firestore batch limiti 500, güvenli olması için 400 kullan
      for (int i = 0; i < messageIds.length; i += 400) {
        final chunk = messageIds.skip(i).take(400).toList();

        for (final messageId in chunk) {
          final messageRef = _firestore
              .collection('chats')
              .doc(chatId)
              .collection('messages')
              .doc(messageId);

          batch.update(messageRef, {
            'isRead': true,
            'readAt': FieldValue.serverTimestamp(),
          });
        }

        await batch.commit();
      }

      debugPrint('✅ ${messageIds.length} mesaj okundu olarak işaretlendi');
    } catch (e) {
      debugPrint('❌ Batch mesaj güncelleme hatası: $e');
    }
  }

  // 🔥 MALIYET OPTIMIZASYONU: Smart sync - sadece değişen chatları al
  static Future<List<ChatModel>> getUpdatedChatsOnly(
    DateTime lastSyncTime,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: user.uid)
          .where('updatedAt', isGreaterThan: Timestamp.fromDate(lastSyncTime))
          .orderBy('updatedAt', descending: true)
          .get();

      final chats = <ChatModel>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();

        final chat = ChatModel.create(
          chatId: data['chatId'] ?? doc.id,
          otherUserId: _getOtherUserId(data['participants'], user.uid),
          otherUserName: _getOtherUserName(data['participantNames'], user.uid),
          lastMessage: data['lastMessage'] ?? '',
          lastMessageTime: data['lastMessageTime'] != null
              ? (data['lastMessageTime'] as Timestamp).toDate()
              : DateTime.now(),
          isLastMessageFromMe: data['isLastMessageFromMe'] ?? false,
          isLastMessageRead: data['isLastMessageRead'] ?? true,
          unreadCount: data['unreadCount'] ?? 0,
        );

        chats.add(chat);
      }

      return chats;
    } catch (e) {
      debugPrint('❌ Smart sync hatası: $e');
      return [];
    }
  }

  // Yardımcı metodlar
  static String _getOtherUserId(
    List<dynamic> participants,
    String currentUserId,
  ) {
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  static String _getOtherUserName(
    Map<String, dynamic>? participantNames,
    String currentUserId,
  ) {
    if (participantNames == null) return 'Bilinmeyen Kullanıcı';

    final otherUserIds = participantNames.keys.where(
      (id) => id != currentUserId,
    );
    if (otherUserIds.isEmpty) return 'Bilinmeyen Kullanıcı';

    return participantNames[otherUserIds.first] ?? 'Bilinmeyen Kullanıcı';
  }

  // 🔥 MALIYET OPTIMIZASYONU: Connection state management
  static bool _isOnline = true;
  static final List<Function> _pendingOperations = [];

  static void setConnectionState(bool isOnline) {
    final wasOffline = !_isOnline;
    _isOnline = isOnline;

    if (isOnline && wasOffline) {
      // Tekrar online olunca bekleyen işlemleri çalıştır
      for (final operation in _pendingOperations) {
        try {
          operation();
        } catch (e) {
          debugPrint('❌ Pending operation hatası: $e');
        }
      }
      _pendingOperations.clear();
    }
  }

  static void executeWhenOnline(Function operation) {
    if (_isOnline) {
      operation();
    } else {
      _pendingOperations.add(operation);
    }
  }
}
