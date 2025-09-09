import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class TestDataService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> seedTestUsers() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Test kullanıcıları
      final testUsers = [
        {
          'uid': 'test_user_1',
          'displayName': 'Ahmet Yılmaz',
          'phoneNumber': '+90 555 123 4567',
          'photoURL': null,
          'isOnline': true,
          'lastSeen': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'uid': 'test_user_2',
          'displayName': 'Fatma Demir',
          'phoneNumber': '+90 555 987 6543',
          'photoURL': null,
          'isOnline': false,
          'lastSeen': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(hours: 2)),
          ),
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'uid': 'test_user_3',
          'displayName': 'Mehmet Kaya',
          'phoneNumber': '+90 555 555 5555',
          'photoURL': null,
          'isOnline': false,
          'lastSeen': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 1)),
          ),
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'uid': 'test_user_4',
          'displayName': 'Ayşe Çelik',
          'phoneNumber': '+90 555 111 2222',
          'photoURL': null,
          'isOnline': true,
          'lastSeen': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'uid': 'test_user_5',
          'displayName': 'Ali Özkan',
          'phoneNumber': '+90 555 999 8888',
          'photoURL': null,
          'isOnline': false,
          'lastSeen': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(minutes: 30)),
          ),
          'createdAt': FieldValue.serverTimestamp(),
        },
      ];

      // Test kullanıcılarını Firestore'a ekle
      for (final user in testUsers) {
        await _firestore
            .collection('users')
            .doc(user['uid'] as String)
            .set(user);
      }

      debugPrint('Test kullanıcıları başarıyla eklendi!');
    } catch (e) {
      debugPrint('Test kullanıcıları eklenirken hata: $e');
    }
  }

  static Future<void> createSampleChat(
    String otherUserId,
    String otherUserName,
  ) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Chat ID oluştur
      final userIds = [currentUser.uid, otherUserId];
      userIds.sort();
      final chatId = userIds.join('_');

      // Chat oluştur
      await _firestore.collection('chats').doc(chatId).set({
        'chatId': chatId,
        'participants': [currentUser.uid, otherUserId],
        'participantNames': {
          currentUser.uid: currentUser.displayName ?? 'İsimsiz',
          otherUserId: otherUserName,
        },
        'lastMessage': 'Merhaba! Nasılsın?',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': otherUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Örnek mesaj ekle
      await _firestore.collection('messages').add({
        'messageId': DateTime.now().millisecondsSinceEpoch.toString(),
        'chatId': chatId,
        'senderId': otherUserId,
        'recipientId': currentUser.uid,
        'text': 'Merhaba! Nasılsın?',
        'type': 'text',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'isDelivered': true,
        'isEdited': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Örnek chat oluşturuldu: $chatId');
    } catch (e) {
      debugPrint('Örnek chat oluşturulurken hata: $e');
    }
  }

  static Future<void> seedTestData() async {
    await seedTestUsers();

    // Örnek chat'ler oluştur
    await createSampleChat('test_user_1', 'Ahmet Yılmaz');
    await createSampleChat('test_user_2', 'Fatma Demir');
  }
}
