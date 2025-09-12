import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../database/drift_service.dart';

import '../models/user_model.dart';
import '../models/message_model.dart';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class BulkMessageService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const _uuid = Uuid();

  // Tüm kullanıcılara toplu mesaj gönder (sadece diyetisyenler)
  static Future<bool> sendMessageToAllUsers({
    required String message,
    String? mediaUrl,
    String? fileName,
    MessageType messageType = MessageType.text,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Diyetisyen yetkisi kontrolü (role system basitleştirildi)
      final userRole = await DriftService.getUserRole(currentUser.uid);
      if (userRole != 'dietitian') {
        debugPrint('❌ Sadece diyetisyenler toplu mesaj gönderebilir');
        return false;
      }

      // Tüm kullanıcıları getir
      final allUsersQuery = await _firestore
          .collection('users')
          .get();

      final users = allUsersQuery.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .where((user) => user.userId != currentUser.uid) // Kendisini hariç tut
          .toList();

      if (users.isEmpty) {
        debugPrint('❌ Mesaj gönderilecek kullanıcı bulunamadı');
        return false;
      }

      // Batch işlemi için
      WriteBatch batch = _firestore.batch();
      int batchCount = 0;
      const maxBatchSize = 500; // Firestore batch limiti

      for (final user in users) {
        await _addMessageToBatch(
          batch: batch,
          senderId: currentUser.uid,
          recipientId: user.userId,
          message: message,
          mediaUrl: mediaUrl,
          fileName: fileName,
          messageType: messageType,
        );

        batchCount++;

        // Batch limiti dolduğunda commit et
        if (batchCount >= maxBatchSize) {
          await batch.commit();
          batch = _firestore.batch();
          batchCount = 0;
        }
      }

      // Kalan batch'i commit et
      if (batchCount > 0) {
        await batch.commit();
      }

      debugPrint('✅ ${users.length} kullanıcıya toplu mesaj gönderildi');
      return true;
    } catch (e) {
      debugPrint('❌ Toplu mesaj gönderme hatası: $e');
      return false;
    }
  }

  // Belirli etiketlerdeki kullanıcılara mesaj gönder
  static Future<bool> sendMessageToTaggedUsers({
    required List<String> tags,
    required String message,
    String? mediaUrl,
    String? fileName,
    MessageType messageType = MessageType.text,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Diyetisyen yetkisi kontrolü (role system basitleştirildi)
      final userRole = await DriftService.getUserRole(currentUser.uid);
      if (userRole != 'dietitian') {
        debugPrint('❌ Sadece diyetisyenler toplu mesaj gönderebilir');
        return false;
      }

      if (tags.isEmpty) {
        debugPrint('❌ En az bir etiket seçilmelidir');
        return false;
      }

      // Etiketli sohbetleri getir
      final taggedChats = await DriftService.getChatsByTags(tags);
      
      if (taggedChats.isEmpty) {
        debugPrint('❌ Belirtilen etiketlerde sohbet bulunamadı');
        return false;
      }

      // Benzersiz kullanıcı ID'lerini topla
      final recipientIds = taggedChats
          .where((chat) => !chat.isGroup && chat.otherUserId != null)
          .map((chat) => chat.otherUserId!)
          .toSet()
          .toList();

      if (recipientIds.isEmpty) {
        debugPrint('❌ Mesaj gönderilecek kullanıcı bulunamadı');
        return false;
      }

      // Batch işlemi için
      WriteBatch batch = _firestore.batch();
      int batchCount = 0;
      const maxBatchSize = 500;

      for (final recipientId in recipientIds) {
        await _addMessageToBatch(
          batch: batch,
          senderId: currentUser.uid,
          recipientId: recipientId,
          message: message,
          mediaUrl: mediaUrl,
          fileName: fileName,
          messageType: messageType,
        );

        batchCount++;

        if (batchCount >= maxBatchSize) {
          await batch.commit();
          batch = _firestore.batch();
          batchCount = 0;
        }
      }

      if (batchCount > 0) {
        await batch.commit();
      }

      debugPrint('✅ ${recipientIds.length} etiketli kullanıcıya mesaj gönderildi');
      return true;
    } catch (e) {
      debugPrint('❌ Etiketli kullanıcılara mesaj gönderme hatası: $e');
      return false;
    }
  }

  // Belirli kullanıcı listesine mesaj gönder
  static Future<bool> sendMessageToUsers({
    required List<String> userIds,
    required String message,
    String? mediaUrl,
    String? fileName,
    MessageType messageType = MessageType.text,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Diyetisyen yetkisi kontrolü (role system basitleştirildi)
      final userRole = await DriftService.getUserRole(currentUser.uid);
      if (userRole != 'dietitian') {
        debugPrint('❌ Sadece diyetisyenler toplu mesaj gönderebilir');
        return false;
      }

      if (userIds.isEmpty) {
        debugPrint('❌ En az bir kullanıcı seçilmelidir');
        return false;
      }

      // Batch işlemi için
      WriteBatch batch = _firestore.batch();
      int batchCount = 0;
      const maxBatchSize = 500;

      for (final userId in userIds) {
        if (userId == currentUser.uid) continue; // Kendisini hariç tut

        await _addMessageToBatch(
          batch: batch,
          senderId: currentUser.uid,
          recipientId: userId,
          message: message,
          mediaUrl: mediaUrl,
          fileName: fileName,
          messageType: messageType,
        );

        batchCount++;

        if (batchCount >= maxBatchSize) {
          await batch.commit();
          batch = _firestore.batch();
          batchCount = 0;
        }
      }

      if (batchCount > 0) {
        await batch.commit();
      }

      debugPrint('✅ ${userIds.length} kullanıcıya mesaj gönderildi');
      return true;
    } catch (e) {
      debugPrint('❌ Kullanıcılara mesaj gönderme hatası: $e');
      return false;
    }
  }

  // Batch'e mesaj ekleme yardımcı fonksiyonu
  static Future<void> _addMessageToBatch({
    required WriteBatch batch,
    required String senderId,
    required String recipientId,
    required String message,
    String? mediaUrl,
    String? fileName,
    MessageType messageType = MessageType.text,
  }) async {
    try {
      // Chat ID oluştur (küçük ID önce gelir)
      final chatId = senderId.compareTo(recipientId) < 0
          ? '${senderId}_$recipientId'
          : '${recipientId}_$senderId';

      final messageId = _uuid.v4();
  

      // Message modelini oluştur
      final messageModel = MessageModel.create(
        messageId: messageId,
        chatId: chatId,
        senderId: senderId,
        content: message,
        type: messageType,
        mediaUrl: mediaUrl,
      );

      // Message'ı Firestore'a ekle
      final messageRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId);

      batch.set(messageRef, messageModel.toMap());

      // Chat belgesini güncelle
      final chatRef = _firestore.collection('chats').doc(chatId);

      batch.set(chatRef, {
        'chatId': chatId,
        'participants': [senderId, recipientId],
        'lastMessage': message,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'isLastMessageFromMe': true, // Gönderen için
        'updatedAt': FieldValue.serverTimestamp(),
        'unreadCount': FieldValue.increment(1),
      }, SetOptions(merge: true));

    } catch (e) {
      debugPrint('❌ Batch mesaj ekleme hatası: $e');
    }
  }

  // Diyetisyen istatistikleri getir
  static Future<Map<String, dynamic>> getDietitianStats() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return {};

      // Diyetisyen yetkisi kontrolü
      final userRole = await DriftService.getUserRole(currentUser.uid);
      if (userRole != 'dietitian') {
        return {};
      }

      // Toplam kullanıcı sayısı
      final allUsersQuery = await _firestore.collection('users').get();
      final totalUsers = allUsersQuery.docs.length - 1; // Kendisini hariç tut

      // Aktif sohbet sayısı (diyetisyenin dahil olduğu)
      final activeChats = await DriftService.getAllChats();
      final dietitianChats = activeChats
          .where((chat) => !chat.isGroup && chat.otherUserId != null)
          .length;

      // Bu ay gönderilen mesaj sayısı
      final thisMonth = DateTime.now();
      final startOfMonth = DateTime(thisMonth.year, thisMonth.month, 1);
      
      final monthlyMessagesQuery = await _firestore
          .collectionGroup('messages')
          .where('senderId', isEqualTo: currentUser.uid)
          .where('timestamp', isGreaterThanOrEqualTo: startOfMonth.millisecondsSinceEpoch)
          .get();

      final monthlyMessageCount = monthlyMessagesQuery.docs.length;

      // Bugün gönderilen mesaj sayısı
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      
      final todayMessagesQuery = await _firestore
          .collectionGroup('messages')
          .where('senderId', isEqualTo: currentUser.uid)
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay.millisecondsSinceEpoch)
          .get();

      final todayMessageCount = todayMessagesQuery.docs.length;

      return {
        'totalUsers': totalUsers,
        'activeChats': dietitianChats,
        'monthlyMessages': monthlyMessageCount,
        'todayMessages': todayMessageCount,
      };
    } catch (e) {
      debugPrint('❌ Diyetisyen istatistikleri getirme hatası: $e');
      return {};
    }
  }

  // Tüm kullanıcıların sağlık verilerini getir (diyetisyen için)
  static Future<List<Map<String, dynamic>>> getAllUsersHealthData() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      // Diyetisyen yetkisi kontrolü
      final userRole = await DriftService.getUserRole(currentUser.uid);
      if (userRole != 'dietitian') {
        debugPrint('❌ Sadece diyetisyenler kullanıcı sağlık verilerini görebilir');
        return [];
      }

      // Tüm kullanıcıları getir
      final allUsersQuery = await _firestore.collection('users').get();
      final usersHealthData = <Map<String, dynamic>>[];

      for (final userDoc in allUsersQuery.docs) {
        final userData = UserModel.fromMap(userDoc.data());
        
        if (userData.userId == currentUser.uid) continue; // Kendisini hariç tut

        // Kullanıcının en son sağlık verilerini getir
        final healthQuery = await _firestore
            .collection('users')
            .doc(userData.userId)
            .collection('healthData')
            .orderBy('recordDate', descending: true)
            .limit(1)
            .get();

        Map<String, dynamic>? latestHealthData;
        if (healthQuery.docs.isNotEmpty) {
          latestHealthData = healthQuery.docs.first.data();
        }

        usersHealthData.add({
          'user': userData.toMap(),
          'healthData': latestHealthData,
        });
      }

      return usersHealthData;
    } catch (e) {
      debugPrint('❌ Kullanıcı sağlık verileri getirme hatası: $e');
      return [];
    }
  }
}
