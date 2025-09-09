import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/foundation.dart';
import '../models/message_model.dart';
import '../models/chat_model.dart';
import '../database/drift_service.dart';
import 'media_cache_manager.dart';
import 'firebase_usage_tracker.dart';
import 'contacts_service.dart';
import 'group_service.dart';
import 'dart:async';
import 'dart:io';

class MessageService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const int defaultPageSize = 50;
  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _chatDocsSubscription;

  // Aktif chat durumu için callback sistem
  static String? _activeChatId;
  static bool _isChatPageActive = false;

  // Chat aktif durumunu ayarla
  static void setActiveChatStatus(String? chatId, bool isActive) {
    _activeChatId = chatId;
    _isChatPageActive = isActive;
    debugPrint('🔥 Chat aktif durumu güncellendi: $chatId - Aktif: $isActive');

    // Aktif chat değiştiğinde, yeni gelen mesajlar otomatik okunsun
    debugPrint(
        'ℹ️ Aktif chat ayarlandı. Yeni gelen mesajlar otomatik okunacak');
  }

  // Durum get'leri (Provider vb. tarafların okuması için)
  static bool get isChatPageActive => _isChatPageActive;
  static String? get activeChatId => _activeChatId;

  // Kullanıcıya ait chat dokümanlarını canlı dinle ve Isar'a yansıt
  static Future<void> startChatDocsListener() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Mevcut dinleyiciyi kapat
    await _chatDocsSubscription?.cancel();

    _chatDocsSubscription = _firestore
        .collection('chats')
        .where('participants', arrayContains: user.uid)
        .snapshots()
        .listen((snapshot) async {
      try {
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final chatId = doc.id;

          // Eğer bu chat kullanıcı tarafından silinmişse, işleme alma
          final deletedFor = data['deletedFor'] as Map<String, dynamic>?;
          if (deletedFor != null && deletedFor[user.uid] == true) {
            debugPrint('⏩ Silinen chat atlandı: $chatId');
            continue;
          }

          final bool isGroup =
              (data['isGroup'] == true) || (data['type'] == 'group');

          // Per-user unread sayacı
          final dynamic perUser = data['unreadCountByUser'];
          final int perUserUnread = (perUser is Map<String, dynamic>)
              ? ((perUser[user.uid] as num?)?.toInt() ?? 0)
              : 0;

          // Yerel chat'i getir ve sadece gerekli alanları güncelle
          ChatModel? localChat = await DriftService.getChatById(chatId);
          ChatModel local;
          
          if (localChat == null) {
            // Yerel yoksa minimal bir model oluşturup kaydet
            final base = isGroup
                ? ChatModel.createGroup(
                    chatId: chatId,
                    groupId: (data['groupId'] as String?) ?? chatId,
                    groupName: data['groupName'] as String?,
                    groupImage: data['groupImage'] as String?,
                    groupDescription: data['groupDescription'] as String?,
                    lastMessage: data['lastMessage'] as String?,
                    isLastMessageFromMe:
                        (data['isLastMessageFromMe'] as bool?) ?? false,
                    isLastMessageRead:
                        (data['isLastMessageRead'] as bool?) ?? false,
                    unreadCount: perUserUnread,
                  )
                : await _createChatModelFromFirebaseData(
                    chatId: chatId,
                    data: data,
                    currentUserId: user.uid,
                    perUserUnread: perUserUnread,
                  );
            if (data['lastMessageTime'] is Timestamp) {
              base.lastMessageTime =
                  (data['lastMessageTime'] as Timestamp).toDate();
            }
            if (data['updatedAt'] is Timestamp) {
              base.updatedAt = (data['updatedAt'] as Timestamp).toDate();
            }
            await DriftService.saveChat(base);
            local = base; // Yeni oluşturulan chat'i local olarak set et
          } else {
            local = localChat; // Mevcut chat'i kullan
          }

          // Mevcut kaydı güncelle - null safety kontrolü
          if (local.lastMessage != null) {
            local.lastMessage = data['lastMessage'] as String? ?? local.lastMessage;
          }
          
          if (data['lastMessageTime'] is Timestamp) {
            local.lastMessageTime = (data['lastMessageTime'] as Timestamp).toDate();
          }
          
          local.isLastMessageFromMe = (data['isLastMessageFromMe'] as bool?) ?? local.isLastMessageFromMe;
          local.isLastMessageRead = (data['isLastMessageRead'] as bool?) ?? local.isLastMessageRead;
          local.unreadCount = perUserUnread;
          
          if (data['updatedAt'] is Timestamp) {
            local.updatedAt = (data['updatedAt'] as Timestamp).toDate();
          } else {
            local.updatedAt = DateTime.now();
          }
          
          // Update chat model
          await DriftService.updateChatModel(local);
        }
      } catch (e) {
        debugPrint('❌ Chat docs listener hata: $e');
      }
    });
  }

  static Future<void> stopChatDocsListener() async {
    await _chatDocsSubscription?.cancel();
    _chatDocsSubscription = null;
  }

  /// Firebase data'dan ChatModel oluştur ve kullanıcı bilgilerini çek
  static Future<ChatModel> _createChatModelFromFirebaseData({
    required String chatId,
    required Map<String, dynamic> data,
    required String currentUserId,
    required int perUserUnread,
  }) async {
    try {
      final participants = List<String>.from(data['participants'] ?? []);
      final otherUserId = participants.firstWhere(
        (id) => id != currentUserId,
        orElse: () => '',
      );

      // Diğer kullanıcının bilgilerini Firebase'den çek
      String? otherUserName;
      String? otherUserPhoneNumber;
      String? otherUserProfileImage;

      if (otherUserId.isNotEmpty) {
        try {
          final userDoc = await _firestore.collection('users').doc(otherUserId).get();
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            otherUserName = userData['displayName'] as String?;
            otherUserPhoneNumber = userData['phoneNumber'] as String?;
            otherUserProfileImage = userData['profileImageUrl'] as String?;
          }
        } catch (e) {
          debugPrint('⚠️ Kullanıcı bilgisi çekilemedi: $e');
        }
      }

      return ChatModel.create(
        chatId: chatId,
        otherUserId: otherUserId,
        otherUserName: otherUserName,
        otherUserPhoneNumber: otherUserPhoneNumber,
        otherUserProfileImage: otherUserProfileImage,
        lastMessage: data['lastMessage'] as String?,
        isLastMessageFromMe: (data['isLastMessageFromMe'] as bool?) ?? false,
        isLastMessageRead: (data['isLastMessageRead'] as bool?) ?? false,
        unreadCount: perUserUnread,
      );
    } catch (e) {
      debugPrint('❌ Chat model oluşturma hatası: $e');
      // Fallback olarak minimal chat oluştur
      final participants = List<String>.from(data['participants'] ?? []);
      final otherUserId = participants.firstWhere(
        (id) => id != currentUserId,
        orElse: () => '',
      );
      
      return ChatModel.create(
        chatId: chatId,
        otherUserId: otherUserId,
        lastMessage: data['lastMessage'] as String?,
        isLastMessageFromMe: (data['isLastMessageFromMe'] as bool?) ?? false,
        isLastMessageRead: (data['isLastMessageRead'] as bool?) ?? false,
        unreadCount: perUserUnread,
      );
    }
  }

  // Yeni mesaj geldiğinde okundu işaretleme (aktif chat için)
  static Future<void> handleIncomingMessageReadOptimization(
    MessageModel message,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      // Sadece aktif chat ve başkasından gelen mesajlar için okundu
      if (_isChatPageActive &&
          _activeChatId == message.chatId &&
          message.senderId != user.uid) {
        await markMessageAsRead(message.chatId, message.messageId);
        // Lokal unread sayacını güncelle
        final chat = await DriftService.getChatById(message.chatId);
        if (chat != null) {
          chat.unreadCount = 0;
          chat.isLastMessageRead = true;
          await DriftService.updateChatModel(chat);
        }
      }
    } catch (e) {
      debugPrint('❌ Otomatik okundu işaretleme hatası: $e');
    }
  }

  // Chat dokümanını oluştur veya güncelle
  static Future<void> ensureChatDocument({
    required String chatId,
    required List<String> participants,
    bool isGroup = false,
    String type = 'direct',
  }) async {
    try {
      final chatDocRef = _firestore.collection('chats').doc(chatId);
      
      try {
        // Önce chat'in var olup olmadığını kontrol et
        final docSnapshot = await chatDocRef.get();
        
        if (!docSnapshot.exists) {
          // Chat yoksa tüm alanlarla oluştur
          await _createNewChatDocument(chatDocRef, chatId, participants, isGroup, type);
        } else {
          // Chat varsa sadece updatedAt'i güncelle (izin verilen alanlar)
          await chatDocRef.update({
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        await FirebaseUsageTracker.incrementWrite(2);
      } catch (getError) {
        // Get işleminde izin hatası alırsak, chat'i yeniden oluşturmaya çalış
        if (getError.toString().contains('permission-denied')) {
          debugPrint('🔍 Chat get izin hatası, yeni chat oluşturuluyor...');
          await _createNewChatDocument(chatDocRef, chatId, participants, isGroup, type);
          await FirebaseUsageTracker.incrementWrite(1);
        } else {
          rethrow;
        }
      }
    } catch (e) {
      debugPrint('❌ Chat dokümanı hazırlama hatası: $e');
      debugPrint('🔍 DEBUG - Chat ID: $chatId');
      debugPrint('🔍 DEBUG - Participants: $participants');
      debugPrint('🔍 DEBUG - Current user: ${_auth.currentUser?.uid}');
    }
  }

  static Future<void> _createNewChatDocument(
    DocumentReference chatDocRef,
    String chatId,
    List<String> participants,
    bool isGroup,
    String type,
  ) async {
    await chatDocRef.set({
      'chatId': chatId,
      'participants': participants,
      'participantNames': <String>[],
      'lastMessage': '',
      'lastMessageTime': null,
      'isLastMessageFromMe': false,
      'isLastMessageRead': true,
      'unreadCount': 0,
      'unreadCountByUser': <String, int>{},
      'isPinned': false,
      'isMuted': false,
      'isArchived': false,
      'tags': <String>[],
      'typingUsers': <String>[],
      'pinnedMessageIds': <String>[],
      'isGroup': isGroup,
      'groupId': isGroup ? chatId : null,
      'groupName': isGroup ? '' : null,
      'groupImage': null,
      'groupDescription': isGroup ? '' : null,
      'type': type,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Mesaj yönlendirme: seçilen mesajları hedef sohbete yeniden ekler
  static Future<void> forwardMessages({
    required String fromChatId,
    required List<String> messageIds,
    required String toChatId,
    String? toRecipientId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Kullanıcı giriş yapmamış');

    // Hedef chat doğrulama
    final toChat = await DriftService.getChatById(toChatId);
    if (toChat == null) throw Exception('Hedef sohbet bulunamadı');

    // Kaynak mesajları yerelden oku (Isar), yoksa Firestore'dan getir
    for (final mid in messageIds) {
      MessageModel? m = await DriftService.getMessageById(mid);
      if (m == null) {
        try {
          final snap = await _firestore
              .collection('chats')
              .doc(fromChatId)
              .collection('messages')
              .doc(mid)
              .get();
          if (snap.exists) {
            final data = snap.data()!;
            final MessageType msgType =
                MessageType.values.byName(data['type'] ?? 'text');
            final String content = (msgType == MessageType.document &&
                    (data['fileName'] != null &&
                        (data['fileName'] as String).isNotEmpty))
                ? data['fileName'] as String
                : (data['text'] ?? '');
            m = MessageModel.create(
              messageId: data['messageId'] ?? mid,
              chatId: toChatId,
              senderId: user.uid,
              content: content,
              type: msgType,
              status: MessageStatus.sending,
            );
            m.mediaUrl = data['mediaUrl'];
            m.mediaDuration = (data['mediaDuration'] as num?)?.toInt();
            m.latitude = (data['latitude'] as num?)?.toDouble();
            m.longitude = (data['longitude'] as num?)?.toDouble();
            m.locationName = data['locationName'];
          }
        } catch (_) {}
      } else {
        // Yeni chat için alanları uyumla
        m = MessageModel.create(
          messageId: DateTime.now().millisecondsSinceEpoch.toString(),
          chatId: toChatId,
          senderId: user.uid,
          content: m.content,
          type: m.type,
          status: MessageStatus.sending,
          mediaUrl: m.mediaUrl,
          mediaDuration: m.mediaDuration,
          latitude: m.latitude,
          longitude: m.longitude,
          locationName: m.locationName,
        );
      }

      if (m == null) continue;

      // Hedef sohbete uygun şekilde gönder
      switch (m.type) {
        case MessageType.text:
          await sendMessage(
            chatId: toChatId,
            recipientId:
                toChat.isGroup ? null : (toRecipientId ?? toChat.otherUserId!),
            text: m.content,
          );
          break;
        case MessageType.image:
        case MessageType.video:
        case MessageType.audio:
          await sendMediaMessage(
            chatId: toChatId,
            recipientId:
                toChat.isGroup ? null : (toRecipientId ?? toChat.otherUserId!),
            mediaUrl: m.mediaUrl ?? '',
            messageType: m.type,
          );
          break;
        case MessageType.document:
          await sendMediaMessage(
            chatId: toChatId,
            recipientId:
                toChat.isGroup ? null : (toRecipientId ?? toChat.otherUserId!),
            mediaUrl: m.mediaUrl ?? '',
            messageType: m.type,
            fileName: (m.content.isNotEmpty ? m.content : null),
          );
          break;
        case MessageType.location:
          await sendLocationMessage(
            chatId: toChatId,
            recipientId:
                toChat.isGroup ? null : (toRecipientId ?? toChat.otherUserId!),
            latitude: m.latitude ?? 0,
            longitude: m.longitude ?? 0,
            locationName: m.locationName,
          );
          break;
        case MessageType.contact:
          final parts = m.content.split('\n');
          final name =
              parts.isNotEmpty ? parts[0].replaceAll('👤 ', '') : 'Kişi';
          final phone = parts.length > 1 ? parts[1].replaceAll('📞 ', '') : '';
          await sendContactMessage(
            chatId: toChatId,
            recipientId:
                toChat.isGroup ? null : (toRecipientId ?? toChat.otherUserId!),
            name: name,
            phoneNumber: phone,
          );
          break;
        default:
          await sendMessage(
            chatId: toChatId,
            recipientId:
                toChat.isGroup ? null : (toRecipientId ?? toChat.otherUserId!),
            text: m.content,
          );
      }
    }
  }

  // Mesaj gönder (çevrimdışı destekli) - bireysel ve grup sohbetleri destekler
  static Future<void> sendMessage({
    required String chatId,
    String? recipientId, // Bireysel sohbet için gerekli
    required String text,
    String? type = 'text',
    String? replyToMessageId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Kullanıcı giriş yapmamış');

    // Chat tipini kontrol et (bireysel mi grup mu?)
    final chat = await DriftService.getChatById(chatId);
    if (chat == null) throw Exception('Sohbet bulunamadı');

    // Grup sohbeti ise izin kontrolü yap
    if (chat.isGroup) {
      await _checkGroupMessagePermission(chatId, user.uid, text);
    } else {
      // Bireysel sohbet: recipientId null ise chat.otherUserId'yi kullan
      recipientId ??= chat.otherUserId;
      if (recipientId == null) {
        throw Exception('Bireysel sohbet için recipientId gerekli');
      }
    }

    // Mesaj ID oluştur
    final messageId = DateTime.now().millisecondsSinceEpoch.toString();
    final timestamp = DateTime.now();

    // Önce yerel veritabanına kaydet (çevrimdışı destek için)
    final localMessage = MessageModel.create(
      messageId: messageId,
      chatId: chatId,
      senderId: user.uid,
      content: text,
      type: MessageType.text,
      status: MessageStatus.sending,
      replyToMessageId: replyToMessageId,
    );
    localMessage.timestamp = timestamp;

    try {
      // Yerel veritabanına kaydet
      await DriftService.saveMessage(localMessage);
      // Aktif chate düşen mesajlar için otomatik okundu optimizasyonu
      unawaited(handleIncomingMessageReadOptimization(localMessage));

      // Firebase'e göndermeyi dene
      // Cevaplanan mesajın meta bilgisini (metin ve gönderici) yerelden al
      String? replyToText;
      String? replyToSenderId;
      if (replyToMessageId != null) {
        try {
          final replied = await DriftService.getMessageById(replyToMessageId);
          replyToText = replied?.content;
          replyToSenderId = replied?.senderId;
        } catch (_) {
          // Sessiz geç
        }
      }

      // Grup veya bireysel mesajı Firebase'e gönder
      if (chat.isGroup) {
        await _sendGroupMessageToFirebase(
          messageId: messageId,
          chatId: chatId,
          text: text,
          type: type,
          replyToMessageId: replyToMessageId,
          replyToText: replyToText,
          replyToSenderId: replyToSenderId,
          timestamp: timestamp,
        );
      } else {
        await _sendMessageToFirebase(
          messageId: messageId,
          chatId: chatId,
          recipientId: recipientId!,
          text: text,
          type: type,
          replyToMessageId: replyToMessageId,
          replyToText: replyToText,
          replyToSenderId: replyToSenderId,
          timestamp: timestamp,
        );
      }

      // Başarılı ise durumu güncelle
      localMessage.status = MessageStatus.delivered;
      await DriftService.updateMessage(localMessage);
    } catch (e) {
      debugPrint('❌ Firebase mesaj gönderme hatası: $e');
      // Mesaj yerel veritabanında kalır ve durum güncellenir
      localMessage.status = MessageStatus.failed;
      await DriftService.updateMessage(localMessage);

      // Sadece gerçek ağ hatalarında offline mesajını göster
      if (_isNetworkError(e)) {
        throw Exception(
          'Mesaj çevrimdışı olarak kaydedildi. Çevrimiçi olduğunuzda gönderilecek.',
        );
      }

      // Diğer hatalarda gerçek hata mesajını ilet
      final String errorMessage =
          (e is FirebaseException) ? (e.message ?? e.code) : e.toString();
      throw Exception('Mesaj gönderilemedi: $errorMessage');
    }
  }

  // Ağ hatasını tespit etmek için yardımcı fonksiyon
  static bool _isNetworkError(Object e) {
    if (e is SocketException) return true;
    if (e is FirebaseException) {
      // Firestore/Firebase yaygın ağ hata kodları
      const networkCodes = {
        'unavailable',
        'network-request-failed',
        'deadline-exceeded',
      };
      if (networkCodes.contains(e.code)) return true;
    }
    final msg = e.toString().toLowerCase();
    return msg.contains('network') ||
        msg.contains('socket') ||
        msg.contains('timeout') ||
        msg.contains('unavailable') ||
        msg.contains('failed to connect');
  }

  // Kullanıcı presence güncelle
  static Future<void> updatePresence({required bool isOnline}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'isOnline': isOnline,
        if (!isOnline) 'lastSeen': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Sessiz geç
    }
  }

  // Firebase'e mesaj gönder
  static Future<void> _sendMessageToFirebase({
    required String messageId,
    required String chatId,
    required String recipientId,
    required String text,
    String? type = 'text',
    String? replyToMessageId,
    String? replyToText,
    String? replyToSenderId,
    required DateTime timestamp,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Kullanıcı giriş yapmamış');

    // Parent chat dokümanını oluştur veya güncelle
    try {
      final chatDocRef = _firestore.collection('chats').doc(chatId);
      
      try {
        // Önce chat'in var olup olmadığını kontrol et
        final docSnapshot = await chatDocRef.get();
        
        if (!docSnapshot.exists) {
          // Chat yoksa tüm alanlarla oluştur
          await _createNewChatDocument(chatDocRef, chatId, [user.uid, recipientId], false, 'direct');
        }
        // Chat varsa güncelleme yapmaya gerek yok, mesaj gönderme sırasında zaten güncellenecek
      } catch (getError) {
        // Get işleminde izin hatası alırsak, chat'i yeniden oluşturmaya çalış
        if (getError.toString().contains('permission-denied')) {
          debugPrint('🔍 Chat get izin hatası, yeni chat oluşturuluyor...');
          await _createNewChatDocument(chatDocRef, chatId, [user.uid, recipientId], false, 'direct');
        } else {
          rethrow;
        }
      }
    } catch (e) {
      debugPrint('❌ Chat dokümanı hazırlama hatası: $e');
      debugPrint('🔍 DEBUG - Chat ID: $chatId');
      debugPrint('🔍 DEBUG - Current user: ${user.uid}');
      debugPrint('🔍 DEBUG - Recipient: $recipientId');
    }

    // Mesaj oluştur - Artık chat'in alt koleksiyonu olarak
    final messageDoc = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId);

    final messageData = {
      'messageId': messageId,
      'chatId': chatId,
      'senderId': user.uid,
      'recipientId': recipientId,
      'text': text,
      'type': type,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': false,
      'isDelivered': false,
      'isEdited': false,
      'createdAt': FieldValue.serverTimestamp(),
      if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
      if (replyToText != null) 'replyToText': replyToText,
      if (replyToSenderId != null) 'replyToSenderId': replyToSenderId,
    };

    // Firestore'a kaydet
    await messageDoc.set(messageData);

    // Gönderen kullanıcının adını al - önce rehberden sonra Firebase'den
    String senderName = 'Bilinmeyen Kullanıcı';
    try {
      // Önce rehberdeki adını kontrol et
      final contactName = await ContactsService.getContactNameByUid(user.uid);
      if (contactName != null) {
        senderName = contactName;
        debugPrint('✅ Rehberdeki ad kullanıldı: $senderName');
      } else {
        // Rehberde yoksa Firebase'den al
        final senderDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (senderDoc.exists) {
          final userData = senderDoc.data()!;
          senderName = userData['name'] ??
              userData['displayName'] ??
              userData['username'] ??
              userData['email']?.split('@')[0] ??
              'Bilinmeyen Kullanıcı';
          debugPrint('✅ Firebase adı kullanıldı: $senderName');
        }
      }
    } catch (e) {
      debugPrint('❌ Gönderen kullanıcı adı alma hatası: $e');
    }

    // Push notification gönder (rehberdeki isim öncelikli)
    // TODO: Push notification implementasyonu için contactName kullanılacak
    

    // Chat'in son mesajını güncelle (async olarak)
    unawaited(_updateChatLastMessage(chatId, text, true, recipientId));

    // Alıcı için chat'i güncelle (okunmamış olarak)
    unawaited(_updateRecipientChat(chatId, recipientId, text));

    // Mesajı iletildi olarak işaretle (async olarak)
    unawaited(markMessageAsDelivered(chatId, messageId));
  }

  // Grup mesajı izin kontrolü
  static Future<void> _checkGroupMessagePermission(
    String chatId,
    String userId,
    String text,
  ) async {
    try {
      final group = await GroupService.getGroup(chatId);
      if (group == null) {
        throw Exception('Grup bulunamadı');
      }

      // Kullanıcının grup üyesi olup olmadığını kontrol et
      if (!group.isMember(userId)) {
        throw Exception('Bu grubun üyesi değilsiniz');
      }

      // Mesaj gönderme iznini kontrol et
      if (!group.canSendMessage(userId)) {
        throw Exception('Bu grupta mesaj gönderme yetkiniz yok');
      }

      debugPrint('✅ Grup mesaj izni onaylandı: $userId -> $chatId');
    } catch (e) {
      debugPrint('❌ Grup mesaj izin hatası: $e');
      throw Exception('Grup mesajı gönderme izni hatası: $e');
    }
  }

  // Grup mesajını Firebase'e gönder
  static Future<void> _sendGroupMessageToFirebase({
    required String messageId,
    required String chatId,
    required String text,
    String? type = 'text',
    String? replyToMessageId,
    String? replyToText,
    String? replyToSenderId,
    required DateTime timestamp,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Kullanıcı giriş yapmamış');

    try {
      // Grup bilgisini al
      final group = await GroupService.getGroup(chatId);
      if (group == null) throw Exception('Grup bulunamadı');

      // Mesaj oluştur - Chat'in alt koleksiyonu olarak
      final messageDoc = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId);

      final messageData = {
        'messageId': messageId,
        'chatId': chatId,
        'senderId': user.uid,
        'text': text,
        'type': type,
        'timestamp': Timestamp.fromDate(timestamp),
        'isRead': false,
        'isDelivered': false,
        'isEdited': false,
        'isGroupMessage': true,
        'groupId': group.groupId,
        'groupMembers': group.members, // Mesaj zamanındaki üye listesi
        'createdAt': FieldValue.serverTimestamp(),
        if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
        if (replyToText != null) 'replyToText': replyToText,
        if (replyToSenderId != null) 'replyToSenderId': replyToSenderId,
      };

      // Firestore'a kaydet
      await messageDoc.set(messageData);

      // TODO: Gönderen kullanıcının adını al ve grup bildirimlerinde kullan
      
      // Grup üyelerine push notification gönder (gönderen hariç)
      for (final memberId in group.members) {
        if (memberId != user.uid) {
          // TODO: Kişiselleştirilmiş bildirim implementasyonu
          
        }
      }

      // Chat'in son mesajını güncelle (async olarak)
      unawaited(_updateGroupChatLastMessage(chatId, text, group.members));

      // Mesajı iletildi olarak işaretle (async olarak)
      unawaited(markMessageAsDelivered(chatId, messageId));

      debugPrint('✅ Grup mesajı gönderildi: $messageId -> $chatId');
    } catch (e) {
      debugPrint('❌ Grup mesajı gönderme hatası: $e');
      throw Exception('Grup mesajı gönderilemedi: $e');
    }
  }

  // Grup chat'inin son mesajını güncelle
  static Future<void> _updateGroupChatLastMessage(
    String chatId,
    String lastMessage,
    List<String> groupMembers,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Chat'i güncelle
      Map<String, dynamic> chatData = {
        'lastMessage': lastMessage,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'isLastMessageFromMe': true,
        'lastMessageSenderId': user.uid,
        // Alıcılar okumadıkça false kalmalı; okuyan taraf bunu true yapar
        'isLastMessageRead': false,
        'updatedAt': FieldValue.serverTimestamp(),
        'participants': groupMembers,
        'type': 'group',
      };

      await _firestore
          .collection('chats')
          .doc(chatId)
          .set(chatData, SetOptions(merge: true));

      // Her üye için unread count'u güncelle
      final batch = _firestore.batch();
      final chatRef = _firestore.collection('chats').doc(chatId);

      for (final memberId in groupMembers) {
        if (memberId != user.uid) {
          // Diğer üyeler için unread count artır
          batch.update(chatRef, {
            'unreadCountByUser.$memberId': FieldValue.increment(1),
          });
        } else {
          // Gönderen için unread count sıfırla
          batch.update(chatRef, {
            'unreadCountByUser.$memberId': 0,
          });
        }
      }

      await batch.commit();

      // Lokal chat'i güncelle
      final chat = await DriftService.getChatById(chatId);
      if (chat != null) {
        chat.lastMessage = lastMessage;
        chat.lastMessageTime = DateTime.now();
        chat.isLastMessageFromMe = true;
        chat.isLastMessageRead = true;
        chat.updatedAt = DateTime.now();
        await DriftService.updateChatModel(chat);
      }

      debugPrint('✅ Grup chat son mesajı güncellendi: $chatId');
    } catch (e) {
      debugPrint('❌ Grup chat güncelleme hatası: $e');
    }
  }

  // Çevrimdışı mesajları gönder (çevrimiçi olduğunda çağrılır)
  static Future<void> sendOfflineMessages() async {
    try {
      // Yerel veritabanındaki başarısız mesajları al
      final failedMessages = await DriftService.getFailedMessages();

      if (failedMessages.isEmpty) {
        debugPrint('ℹ️ Gönderilecek çevrimdışı mesaj yok');
        return;
      }

      debugPrint(
          '📤 ${failedMessages.length} çevrimdışı mesaj gönderiliyor...');

      for (final message in failedMessages) {
        try {
          // Hedef kullanıcının ID'sini chat üzerinden bul
          final chat = await DriftService.getChatById(message.chatId);
          final resolvedRecipientId = chat?.otherUserId ?? '';
          // Firebase'e gönder
          await _sendMessageToFirebase(
            messageId: message.messageId,
            chatId: message.chatId,
            recipientId: resolvedRecipientId,
            text: message.content,
            type: message.type.name,
            replyToMessageId: message.replyToMessageId,
            timestamp: message.timestamp,
          );

          // Başarılı ise durumu güncelle
          message.status = MessageStatus.delivered;
          await DriftService.updateMessage(message);

          debugPrint('✅ Çevrimdışı mesaj gönderildi: ${message.messageId}');
        } catch (e) {
          debugPrint(
            '❌ Çevrimdışı mesaj gönderme hatası: ${message.messageId} - $e',
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Çevrimdışı mesaj gönderme hatası: $e');
    }
  }

  // Medya mesajı gönder
  static Future<void> sendMediaMessage({
    required String chatId,
    String? recipientId, // Bireysel sohbet için gerekli
    required String mediaUrl,
    required MessageType messageType,
    String? fileName,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Kullanıcı giriş yapmamış');

    // Chat tipini kontrol et (bireysel mi grup mu?)
    final chat = await DriftService.getChatById(chatId);
    if (chat == null) throw Exception('Sohbet bulunamadı');

    // Grup sohbeti ise izin kontrolü yap
    if (chat.isGroup) {
      await _checkGroupMessagePermission(chatId, user.uid, 'Medya');
    } else {
      // Bireysel sohbet: recipientId null ise chat.otherUserId'yi kullan
      recipientId ??= chat.otherUserId;
      if (recipientId == null) {
        throw Exception('Bireysel sohbet için recipientId gerekli');
      }
    }

    try {
      // Mesaj içeriğini oluştur
      String content = '';
      switch (messageType) {
        case MessageType.image:
          content = '📷 Fotoğraf';
          break;
        case MessageType.video:
          content = '🎥 Video';
          break;
        case MessageType.audio:
          content = '🎙️ Ses kaydı';
          break;
        case MessageType.document:
          content = fileName != null ? '📄 $fileName' : '📄 Belge';
          break;
        default:
          content = 'Medya';
      }

      // Mesaj oluştur
      final messageDoc = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc();

      final messageData = {
        'messageId': messageDoc.id,
        'chatId': chatId,
        'senderId': user.uid,
        'recipientId': recipientId,
        'text': content,
        'type': messageType.name,
        'mediaUrl': mediaUrl,
        'fileName': fileName,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'isDelivered': false,
        'isEdited': false,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Firestore'a kaydet
      await messageDoc.set(messageData);

      // Grup veya bireysel için notification gönder
      if (chat.isGroup) {
        // Grup mesajı - üyelere bildirim gönder
        final group = await GroupService.getGroup(chatId);
        if (group != null) {
          // TODO: Grup bildirim sistemi implementasyonu

          // Grup üyelerine push notification gönder (gönderen hariç)
          for (final memberId in group.members) {
            if (memberId != user.uid) {
              
            }
          }

          // Grup chat son mesajını güncelle
          unawaited(
              _updateGroupChatLastMessage(chatId, content, group.members));
        }
      } else if (recipientId != null) {
        // Bireysel sohbet: parent chat dokümanını garanti altına al
        try {
          final chatRef = _firestore.collection('chats').doc(chatId);
          final exists = await chatRef.get();
          if (!exists.exists) {
            await chatRef.set({
              'chatId': chatId,
              'participants': [user.uid, recipientId],
              'isGroup': false,
              'type': 'direct',
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        } catch (_) {}
        // Bireysel mesaj - normal bildirim gönder
        // TODO: Push notification sistemi implementasyonu

        

        // Chat'in son mesajını güncelle (bireysel)
        unawaited(_updateChatLastMessage(chatId, content, true, recipientId));
        unawaited(_updateRecipientChat(chatId, recipientId, content));
      }

      // Lokal Isar veritabanına da kaydet (async olarak)
      unawaited(
        _saveLocalMediaMessage(
          messageDoc.id,
          chatId,
          user.uid,
          content,
          mediaUrl,
          messageType,
        ),
      );

      // Mesajı iletildi olarak işaretle (async olarak)
      unawaited(markMessageAsDelivered(chatId, messageDoc.id));
    } catch (e) {
      throw Exception('Medya mesajı gönderme hatası: $e');
    }
  }

  // Konum mesajı gönder
  static Future<void> sendLocationMessage({
    required String chatId,
    String? recipientId, // Bireysel sohbet için gerekli
    required double latitude,
    required double longitude,
    String? locationName,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Kullanıcı giriş yapmamış');

    // Chat tipini kontrol et (bireysel mi grup mu?)
    final chat = await DriftService.getChatById(chatId);
    if (chat == null) throw Exception('Sohbet bulunamadı');

    // Grup sohbeti ise izin kontrolü yap
    if (chat.isGroup) {
      await _checkGroupMessagePermission(
          chatId, user.uid, '📍 Konum paylaşıldı');
    } else {
      // Bireysel sohbet: recipientId null ise chat.otherUserId'yi kullan
      recipientId ??= chat.otherUserId;
      if (recipientId == null) {
        throw Exception('Bireysel sohbet için recipientId gerekli');
      }
    }

    try {
      // Bireysel sohbet: parent chat dokümanını garanti altına al
      if (!chat.isGroup && recipientId != null) {
        try {
          final chatRef = _firestore.collection('chats').doc(chatId);
          final exists = await chatRef.get();
          if (!exists.exists) {
            await chatRef.set({
              'chatId': chatId,
              'participants': [user.uid, recipientId],
              'isGroup': false,
              'type': 'direct',
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        } catch (_) {}
      }
      final messageDoc = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc();

      final messageData = {
        'messageId': messageDoc.id,
        'chatId': chatId,
        'senderId': user.uid,
        'recipientId': recipientId,
        'text': '📍 Konum paylaşıldı',
        'type': MessageType.location.name,
        'latitude': latitude,
        'longitude': longitude,
        if (locationName != null) 'locationName': locationName,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'isDelivered': false,
        'isEdited': false,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await messageDoc.set(messageData);

      // Grup veya bireysel için farklı güncelleme
      if (chat.isGroup) {
        final group = await GroupService.getGroup(chatId);
        if (group != null) {
          unawaited(_updateGroupChatLastMessage(
              chatId, '📍 Konum paylaşıldı', group.members));
        }
      } else if (recipientId != null) {
        unawaited(_updateChatLastMessage(
            chatId, '📍 Konum paylaşıldı', true, recipientId));
        unawaited(
            _updateRecipientChat(chatId, recipientId, '📍 Konum paylaşıldı'));
      }

      unawaited(markMessageAsDelivered(chatId, messageDoc.id));
    } catch (e) {
      throw Exception('Konum mesajı gönderme hatası: $e');
    }
  }

  // Kişi mesajı gönder
  static Future<void> sendContactMessage({
    required String chatId,
    String? recipientId, // Bireysel sohbet için gerekli
    required String name,
    required String phoneNumber,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Kullanıcı giriş yapmamış');

    // Chat tipini kontrol et (bireysel mi grup mu?)
    final chat = await DriftService.getChatById(chatId);
    if (chat == null) throw Exception('Sohbet bulunamadı');

    // Grup sohbeti ise izin kontrolü yap
    if (chat.isGroup) {
      await _checkGroupMessagePermission(
          chatId, user.uid, '👤 Kişi paylaşıldı');
    } else {
      // Bireysel sohbet: recipientId null ise chat.otherUserId'yi kullan
      recipientId ??= chat.otherUserId;
      if (recipientId == null) {
        throw Exception('Bireysel sohbet için recipientId gerekli');
      }
    }

    try {
      // Bireysel sohbet: parent chat dokümanını garanti altına al
      if (!chat.isGroup && recipientId != null) {
        try {
          final chatRef = _firestore.collection('chats').doc(chatId);
          final exists = await chatRef.get();
          if (!exists.exists) {
            await chatRef.set({
              'chatId': chatId,
              'participants': [user.uid, recipientId],
              'isGroup': false,
              'type': 'direct',
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        } catch (_) {}
      }
      final messageDoc = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc();

      final content = '👤 $name\n📞 $phoneNumber';
      final messageData = {
        'messageId': messageDoc.id,
        'chatId': chatId,
        'senderId': user.uid,
        'recipientId': recipientId,
        'text': content,
        'type': MessageType.contact.name,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'isDelivered': false,
        'isEdited': false,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await messageDoc.set(messageData);

      // Grup veya bireysel için farklı güncelleme
      if (chat.isGroup) {
        final group = await GroupService.getGroup(chatId);
        if (group != null) {
          unawaited(_updateGroupChatLastMessage(
              chatId, '👤 Kişi paylaşıldı', group.members));
        }
      } else if (recipientId != null) {
        unawaited(_updateChatLastMessage(
            chatId, '👤 Kişi paylaşıldı', true, recipientId));
        unawaited(
            _updateRecipientChat(chatId, recipientId, '👤 Kişi paylaşıldı'));
      }

      unawaited(markMessageAsDelivered(chatId, messageDoc.id));
    } catch (e) {
      throw Exception('Kişi mesajı gönderme hatası: $e');
    }
  }

  // Alıcı için chat'i güncelle
  static Future<void> _updateRecipientChat(
    String chatId,
    String recipientId,
    String lastMessage,
  ) async {
    try {
      // Tekil chat dokümanı üzerinde alıcı için unread sayısını artır
      await _firestore.collection('chats').doc(chatId).set({
        'lastMessage': lastMessage,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'isLastMessageFromMe': false,
        'isLastMessageRead': false,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Per-user unread sayacı (unreadCountByUser.<recipientId>)
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCountByUser.$recipientId': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Alıcı chat güncelleme hatası: $e');
    }
  }

  // Lokal mesaj kaydetme için ayrı fonksiyon
  // (Kaldırıldı) _saveLocalMessage kullanılmıyordu

  // Lokal medya mesajı kaydet
  static Future<void> _saveLocalMediaMessage(
    String messageId,
    String chatId,
    String senderId,
    String content,
    String mediaUrl,
    MessageType messageType,
  ) async {
    try {
      final message = MessageModel.create(
        messageId: messageId,
        chatId: chatId,
        senderId: senderId,
        content: content,
        type: messageType,
        status: MessageStatus.delivered,
        mediaUrl: mediaUrl,
      );
      await DriftService.saveMessage(message);
    } catch (e) {
      // Lokal kaydetme hatası kritik değil, logla
      debugPrint('Lokal medya mesajı kaydetme hatası: $e');
    }
  }

  // Chat'in son mesajını güncelle
  static Future<void> _updateChatLastMessage(
    String chatId,
    String lastMessage,
    bool isFromMe,
    String recipientId,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Önce mevcut chat'i kontrol et
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();

      // Participants listesini doğru şekilde oluştur
      List<String> participants = [user.uid, recipientId];

      // Firestore'daki chat'i güncelle veya oluştur
      Map<String, dynamic> chatData = {
        'chatId': chatId,
        'lastMessage': lastMessage,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'isLastMessageFromMe': isFromMe,
        'lastMessageSenderId': user.uid,
        // Karşı taraf okumadıkça false kalmalı
        'isLastMessageRead': false,
        'updatedAt': FieldValue.serverTimestamp(),
        'participants': participants,
      };

      // Eğer chat zaten varsa ve mesaj bizden değilse unreadCount'u artır
      if (chatDoc.exists && !isFromMe) {
        chatData['unreadCount'] = FieldValue.increment(1);
      } else if (!chatDoc.exists) {
        // Yeni chat ise unreadCount'u başlat
        chatData['unreadCount'] = isFromMe ? 0 : 1;
        chatData['createdAt'] = FieldValue.serverTimestamp();
      }

      final chatRef = _firestore.collection('chats').doc(chatId);
      await chatRef.set(chatData, SetOptions(merge: true));

      // Gönderen için unread sayacını sıfırla (per-user)
      await chatRef.set({
        'unreadCountByUser': {user.uid: 0},
      }, SetOptions(merge: true));

      // Lokal chat'i güncelle (UI sadece Isar'ı kullanır)
      final chat = await DriftService.getChatById(chatId);
      if (chat != null) {
        chat.lastMessage = lastMessage;
        chat.lastMessageTime = DateTime.now();
        chat.isLastMessageFromMe = isFromMe;

        // Eğer mesaj bizden ise, okunmuş olarak işaretle
        // Eğer mesaj bizden değilse, okunmamış bırak
        if (isFromMe) {
          chat.isLastMessageRead = true; // Kendi mesajlarımız otomatik okunmuş
        } else {
          chat.isLastMessageRead = false; // Gelen mesajlar okunmamış
        }

        chat.updatedAt = DateTime.now();

        // Eğer mesaj bizden değilse yerelde unread count'u artır
        if (!isFromMe) chat.unreadCount = chat.unreadCount + 1;

        await DriftService.updateChatModel(chat);
      }
    } catch (e) {
      throw Exception('Chat güncelleme hatası: $e');
    }
  }

  // Arka plan: sohbet listesini Firebase'den çek ve Isar'a yaz (UI dokunmaz)
  static Future<void> backgroundSyncChats({int days = 7}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      final since = DateTime.now().subtract(Duration(days: days));
      final snap = await _firestore
          .collection('chats')
          .where('participants', arrayContains: user.uid)
          .where('updatedAt', isGreaterThan: Timestamp.fromDate(since))
          .orderBy('updatedAt', descending: true)
          .get();
      for (final doc in snap.docs) {
        final data = doc.data();
        final chatId = doc.id;
        // Isar ChatModel'e dönüştürme
        final isGroup = (data['isGroup'] == true) || (data['type'] == 'group');
        ChatModel model;
        if (isGroup) {
          // Yalnızca kullanıcıya özel unread sayacını kullan; global 'unreadCount' asla kullanılmasın
          final dynamic perUser = data['unreadCountByUser'];
          final int perUserUnread = (perUser is Map<String, dynamic>)
              ? ((perUser[user.uid] as num?)?.toInt() ?? 0)
              : 0;

          model = ChatModel.createGroup(
            chatId: chatId,
            groupId: (data['groupId'] as String?) ?? chatId,
            groupName: data['groupName'] as String?,
            groupImage: data['groupImage'] as String?,
            groupDescription: data['groupDescription'] as String?,
            lastMessage: data['lastMessage'] as String?,
            isLastMessageFromMe:
                (data['isLastMessageFromMe'] as bool?) ?? false,
            isLastMessageRead: (data['isLastMessageRead'] as bool?) ?? false,
            unreadCount: perUserUnread,
          );
        } else {
          final participants = List<String>.from(data['participants'] ?? []);
          final otherUserId = participants.firstWhere(
            (id) => id != user.uid,
            orElse: () => '',
          );
          // Yalnızca kullanıcıya özel unread sayacını kullan; global 'unreadCount' asla kullanılmasın
          final dynamic perUser = data['unreadCountByUser'];
          final int perUserUnread = (perUser is Map<String, dynamic>)
              ? ((perUser[user.uid] as num?)?.toInt() ?? 0)
              : 0;

          model = ChatModel.create(
            chatId: chatId,
            otherUserId: otherUserId,
            lastMessage: data['lastMessage'] as String?,
            isLastMessageFromMe:
                (data['isLastMessageFromMe'] as bool?) ?? false,
            isLastMessageRead: (data['isLastMessageRead'] as bool?) ?? false,
            unreadCount: perUserUnread,
          );
        }
        if (data['lastMessageTime'] is Timestamp) {
          model.lastMessageTime =
              (data['lastMessageTime'] as Timestamp).toDate();
        }
        if (data['createdAt'] is Timestamp) {
          model.createdAt = (data['createdAt'] as Timestamp).toDate();
        }
        if (data['updatedAt'] is Timestamp) {
          model.updatedAt = (data['updatedAt'] as Timestamp).toDate();
        }
        await DriftService.saveChat(model);
      }
    } catch (e) {
      debugPrint('❌ Arka plan sohbet senkronizasyonu hatası: $e');
    }
  }

  // Arka plan: bir sohbetin yeni mesajlarını Isar'a yaz (UI dokunmaz)
  static Future<void> backgroundSyncMessages(
    String chatId, {
    DateTime? since,
    int limit = 100,
  }) async {
    try {
      Query<Map<String, dynamic>> q = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(limit);
      if (since != null) {
        q = q.startAfter([Timestamp.fromDate(since)]);
      }
      final snap = await q.get();
      for (final doc in snap.docs) {
        final data = doc.data();
        final msg = _mapDataToMessage(data);
        await DriftService.saveMessage(msg);
      }
    } catch (e) {
      debugPrint('❌ Arka plan mesaj senkronizasyonu hatası: $e');
    }
  }

  // Mesajları dinle (gerçek zamanlı) - Artık chat'in alt koleksiyonundan
  static Stream<List<MessageModel>> getMessagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .asyncMap((snapshot) async {
      // Chat ekranı açık ve bu chat aktifse gelen mesajları otomatik okundu işaretle
      final user = _auth.currentUser;
      if (user != null) {
        // Kullanıcı bu chat'i daha önce sildiyse, o tarihten önceki mesajları filtrele
        DateTime? deletedAt;
        try {
          final chatDoc =
              await _firestore.collection('chats').doc(chatId).get();
          final data = chatDoc.data();
          final deletedAtByUser = data?['deletedAtByUser'];
          if (deletedAtByUser is Map<String, dynamic>) {
            final ts = deletedAtByUser[user.uid];
            if (ts is Timestamp) deletedAt = ts.toDate();
          }
        } catch (_) {}

        // Import hatası olmasın diye string literal ile karşılaştır
        // Bu kısmı daha sonra düzgün bir şekilde implement edeceğiz
        // Şimdilik gelen her yeni mesajı stream'de işleyelim
        final DateTime? userDeletedAt = deletedAt;
        final messages = snapshot.docs
            // 'Benden Sil' yapılan mesajları gizle
            .where((doc) {
          final data = doc.data();
          final deletedFor = data['deletedFor'];
          if (deletedFor is Map<String, dynamic>) {
            return deletedFor[user.uid] != true;
          }
          return true;
        }).where((doc) {
          // deletedAt sonrası mesajları göster
          if (userDeletedAt == null) return true;
          final data = doc.data();
          final ts = data['timestamp'];
          final dt = ts is Timestamp ? ts.toDate() : null;
          if (dt == null) return true;
          return !dt.isBefore(userDeletedAt);
        }).map((doc) {
          final data = doc.data();

          // Mesaj durumunu belirle
          MessageStatus status = MessageStatus.sent;
          if (data['isRead'] == true) {
            status = MessageStatus.read;
          } else if (data['isDelivered'] == true) {
            status = MessageStatus.delivered;
            debugPrint('📩 Mesaj iletildi: ${data['messageId']}');
          } else {
            debugPrint('📤 Mesaj gönderildi: ${data['messageId']}');
          }

          final msg = MessageModel.create(
            messageId: data['messageId'] ?? '',
            chatId: data['chatId'] ?? '',
            senderId: data['senderId'] ?? '',
            content: (data['type'] == 'document' && (data['fileName'] != null))
                ? (data['fileName'] as String)
                : (data['text'] ?? ''),
            type: MessageType.values.firstWhere(
              (e) => e.name == (data['type'] ?? 'text'),
              orElse: () => MessageType.text,
            ),
            status: status,
          )
            ..timestamp =
                (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now()
            ..readAt = (data['readAt'] as Timestamp?)?.toDate()
            ..deliveredAt = (data['deliveredAt'] as Timestamp?)?.toDate()
            ..isEdited = (data['isEdited'] == true)
            ..editedAt = (data['editedAt'] as Timestamp?)?.toDate()
            ..replyToMessageId = data['replyToMessageId']
            ..replyToContent = data['replyToText']
            ..replyToSenderId = data['replyToSenderId']
            ..mediaUrl = data['mediaUrl'] as String?
            ..mediaLocalPath = data['mediaLocalPath'] as String?
            ..mediaDuration = (data['mediaDuration'] as num?)?.toInt()
            ..latitude = (data['latitude'] as num?)?.toDouble()
            ..longitude = (data['longitude'] as num?)?.toDouble()
            ..locationName = data['locationName'] as String?;

          // Gelen medya için: ilk kez görülüyorsa cihaz hafızasına önbelleğe indir
          unawaited(_maybePrefetchMedia(msg));
          return msg;
        }).toList();

        // Bu chat'e gelen yeni mesajları kontrol et ve otomatik okundu işaretle
        // EĞER ChatPage aktifse ve bu chat açıksa
        await _autoMarkMessagesAsReadIfChatActive(chatId, snapshot);

        return messages;
      }

      return snapshot.docs.map((doc) {
        final data = doc.data();

        // Mesaj durumunu belirle
        MessageStatus status = MessageStatus.sent;
        if (data['isRead'] == true) {
          status = MessageStatus.read;
        } else if (data['isDelivered'] == true) {
          status = MessageStatus.delivered;
          debugPrint('📩 Mesaj iletildi: ${data['messageId']}');
        } else {
          debugPrint('📤 Mesaj gönderildi: ${data['messageId']}');
        }

        final msg = MessageModel.create(
          messageId: data['messageId'] ?? '',
          chatId: data['chatId'] ?? '',
          senderId: data['senderId'] ?? '',
          content: (data['type'] == 'document' && (data['fileName'] != null))
              ? (data['fileName'] as String)
              : (data['text'] ?? ''),
          type: MessageType.values.firstWhere(
            (e) => e.name == (data['type'] ?? 'text'),
            orElse: () => MessageType.text,
          ),
          status: status,
        )
          ..timestamp =
              (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now()
          ..readAt = (data['readAt'] as Timestamp?)?.toDate()
          ..deliveredAt = (data['deliveredAt'] as Timestamp?)?.toDate()
          ..isEdited = (data['isEdited'] == true)
          ..editedAt = (data['editedAt'] as Timestamp?)?.toDate()
          ..replyToMessageId = data['replyToMessageId']
          ..replyToContent = data['replyToText']
          ..replyToSenderId = data['replyToSenderId']
          ..mediaUrl = data['mediaUrl'] as String?
          ..mediaLocalPath = data['mediaLocalPath'] as String?
          ..mediaDuration = (data['mediaDuration'] as num?)?.toInt()
          ..latitude = (data['latitude'] as num?)?.toDouble()
          ..longitude = (data['longitude'] as num?)?.toDouble()
          ..locationName = data['locationName'] as String?;
        unawaited(_maybePrefetchMedia(msg));
        return msg;
      }).toList();
    });
  }

  static Future<void> _maybePrefetchMedia(MessageModel msg) async {
    try {
      final String? url = msg.mediaUrl;
      if (url == null || url.isEmpty) return;

      // Daha önce yerel path yazılmışsa (kullanıcı sonradan silmiş olsa bile) otomatik yeniden indirme YAPMA
      if (msg.mediaLocalPath != null && msg.mediaLocalPath!.isNotEmpty) {
        return;
      }

      // İlk kez görülen medya: arka planda indir ve Isar'a path yaz
      final cached = await MediaCacheManager.getCachedPathIfExists(url);
      String? path = cached;
      if (path == null) {
        // indir
        path = await MediaCacheManager.downloadToCache(url);
      }
      if (path != null && path.isNotEmpty) {
        await DriftService.updateMessageLocalMediaPath(msg.messageId, path);
      }
    } catch (e) {
      // Sessiz geç; indirme başarısız olabilir
    }
  }

  // Yardımcı: Firestore dökümanını MessageModel'e dönüştür
  static MessageModel _mapDataToMessage(Map<String, dynamic> data) {
    MessageStatus status = MessageStatus.sent;
    if (data['isRead'] == true) {
      status = MessageStatus.read;
    } else if (data['isDelivered'] == true) {
      status = MessageStatus.delivered;
    }

    final msg = MessageModel.create(
      messageId: data['messageId'] ?? '',
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      content: (data['type'] == 'document' && (data['fileName'] != null))
          ? (data['fileName'] as String)
          : (data['text'] ?? ''),
      type: MessageType.values.firstWhere(
        (e) => e.name == (data['type'] ?? 'text'),
        orElse: () => MessageType.text,
      ),
      status: status,
    )
      ..timestamp = (data['timestamp'] is Timestamp)
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now()
      ..readAt = (data['readAt'] as Timestamp?)?.toDate()
      ..deliveredAt = (data['deliveredAt'] as Timestamp?)?.toDate()
      ..isEdited = (data['isEdited'] == true)
      ..editedAt = (data['editedAt'] as Timestamp?)?.toDate()
      ..replyToMessageId = data['replyToMessageId']
      ..replyToContent = data['replyToText']
      ..replyToSenderId = data['replyToSenderId']
      ..mediaUrl = data['mediaUrl'] as String?
      ..mediaLocalPath = data['mediaLocalPath'] as String?;
    return msg;
  }

  // Eski mesajları sayfalı getir ve Isar'a kaydet (UI için geri döndür)
  static Future<List<MessageModel>> fetchOlderMessagesAndSaveToIsar({
    required String chatId,
    required DateTime startAfterTimestamp,
    int limit = defaultPageSize,
  }) async {
    try {
      final query = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .startAfter([Timestamp.fromDate(startAfterTimestamp)]).limit(limit);

      final snap = await query.get();
      final results = <MessageModel>[];
      for (final doc in snap.docs) {
        final data = doc.data();
        final msg = _mapDataToMessage(data);
        results.add(msg);
        // Isar'a kaydet
        await DriftService.saveMessage(msg);
      }
      return results;
    } catch (e) {
      debugPrint('❌ Eski mesajları getirme hatası: $e');
      return [];
    }
  }

  // Bir sohbetin son N mesajını önceden getirip Isar'a kaydet
  static Future<void> prefetchLastMessagesToIsar({
    required String chatId,
    int limit = 100,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Soft-delete tarihi: kullanıcı bu tarihten önceki mesajları görmemeli
      DateTime? deletedAt;
      try {
        final chatDoc = await _firestore.collection('chats').doc(chatId).get();
        final data = chatDoc.data();
        final deletedAtByUser = data?['deletedAtByUser'];
        if (deletedAtByUser is Map<String, dynamic>) {
          final ts = deletedAtByUser[user.uid];
          if (ts is Timestamp) deletedAt = ts.toDate();
        }
      } catch (_) {}

      Query<Map<String, dynamic>> q = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(limit);

      final snap = await q.get();

      for (final doc in snap.docs) {
        final data = doc.data();
        // Eğer kullanıcı chat'i silmişse, o tarihten eski mesajları atla
        if (deletedAt != null) {
          final ts = data['timestamp'];
          final dt = ts is Timestamp ? ts.toDate() : null;
          if (dt != null && dt.isBefore(deletedAt)) {
            continue;
          }
        }
        final msg = _mapDataToMessage(data);
        await DriftService.saveMessage(msg);
      }
    } catch (e) {
      debugPrint('❌ Prefetch mesaj hatası ($chatId): $e');
    }
  }

  // Sabitli mesajlar stream
  static Stream<List<MessageModel>> getPinnedMessagesStream(String chatId) {
    return _firestore.collection('chats').doc(chatId).snapshots().asyncMap((
      chatSnap,
    ) async {
      final data = chatSnap.data();
      if (data == null) return <MessageModel>[];
      final pinnedIdsDynamic = data['pinnedMessageIds'];
      if (pinnedIdsDynamic == null) return <MessageModel>[];
      final List<String> pinnedIds = List<String>.from(
        pinnedIdsDynamic.whereType<String>(),
      );
      if (pinnedIds.isEmpty) return <MessageModel>[];

      // Firestore whereIn 10 sınırı için parçalara böl
      final chunks = <List<String>>[];
      for (var i = 0; i < pinnedIds.length; i += 10) {
        chunks.add(
          pinnedIds.sublist(
            i,
            i + 10 > pinnedIds.length ? pinnedIds.length : i + 10,
          ),
        );
      }

      final List<MessageModel> results = [];
      for (final chunk in chunks) {
        final q = await _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .where('messageId', whereIn: chunk)
            .get();
        for (final doc in q.docs) {
          final d = doc.data();
          MessageStatus status = MessageStatus.sent;
          if (d['isRead'] == true) {
            status = MessageStatus.read;
          } else if (d['isDelivered'] == true) {
            status = MessageStatus.delivered;
          }
          final m = MessageModel.create(
            messageId: d['messageId'] ?? '',
            chatId: d['chatId'] ?? chatId,
            senderId: d['senderId'] ?? '',
            content: (d['type'] == 'document' && (d['fileName'] != null))
                ? (d['fileName'] as String)
                : (d['text'] ?? ''),
            type: MessageType.values.firstWhere(
              (e) => e.name == (d['type'] ?? 'text'),
              orElse: () => MessageType.text,
            ),
            status: status,
          )
            ..timestamp =
                (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now()
            ..replyToMessageId = d['replyToMessageId']
            ..replyToContent = d['replyToText']
            ..replyToSenderId = d['replyToSenderId']
            ..isEdited = (d['isEdited'] == true)
            ..editedAt = (d['editedAt'] as Timestamp?)?.toDate()
            ..mediaUrl = d['mediaUrl'] as String?
            ..mediaLocalPath = d['mediaLocalPath'] as String?;
          results.add(m);
        }
      }

      // Zamanına göre (yeni üste) sırala
      results.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return results;
    });
  }

  // Mesajları okundu olarak işaretle
  static Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      final batch = _firestore.batch();

      // Okunmamış mesajları bul - YENİ SUBCOLLECTION YAPISI
      final unreadMessages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('recipientId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      // Hepsini okundu olarak işaretle
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      // Chat'in unread sayacını (per-user) sıfırla ve last message'ı okundu yap
      try {
        await _firestore.collection('chats').doc(chatId).set({
          'isLastMessageRead': true,
          'unreadCountByUser.$userId': 0,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}

      // Lokal unread count'u sıfırla
      final chat = await DriftService.getChatById(chatId);
      if (chat != null) {
        chat.unreadCount = 0;
        await DriftService.updateChatModel(chat);
      }
    } catch (e) {
      throw Exception('Mesaj okuma hatası: $e');
    }
  }

  // Mesajı sil
  static Future<void> deleteMessage(String messageId) async {
    try {
      // Chat alt koleksiyonundan silmek için önce chatId'yi bul
      final localMessage = await DriftService.getMessageById(messageId);
      if (localMessage == null) {
        throw Exception('Mesaj bulunamadı: $messageId');
      }
      await _firestore
          .collection('chats')
          .doc(localMessage.chatId)
          .collection('messages')
          .doc(messageId)
          .delete();

      // Lokalden de silinmesi gerekiyorsa burada ele alınabilir (opsiyonel)
    } catch (e) {
      throw Exception('Mesaj silme hatası: $e');
    }
  }

  // Çoklu: Herkesten sil (sadece kendi mesajları ve 24 saat içinde)
  static Future<void> deleteMessagesForEveryone(List<String> messageIds) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Kullanıcı giriş yapmamış');

    try {
      for (final messageId in messageIds) {
        final localMessage = await DriftService.getMessageById(messageId);
        if (localMessage == null) continue;

        // Yetki ve süre kontrolünü Firestore'daki gerçek veriye göre yap
        final msgRef = _firestore
            .collection('chats')
            .doc(localMessage.chatId)
            .collection('messages')
            .doc(messageId);
        final snap = await msgRef.get();
        if (!snap.exists) continue;
        final data = snap.data() as Map<String, dynamic>;
        final senderId = data['senderId'] as String?;
        final ts = data['timestamp'];
        final sentAt = ts is Timestamp ? ts.toDate() : localMessage.timestamp;

        final isMine = senderId == user.uid;
        final within24h = DateTime.now().difference(sentAt).inHours <= 24;
        if (!isMine || !within24h) continue; // Kuralı sağlamayanları atla

        await msgRef.delete();
      }
    } catch (e) {
      throw Exception('Herkesten silme hatası: $e');
    }
  }

  // Çoklu: Benden sil (Firestore'da kullanıcıya özel işaretle)
  static Future<void> deleteMessagesForMe(
    String chatId,
    List<String> messageIds,
  ) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Kullanıcı giriş yapmamış');

    try {
      final batch = _firestore.batch();
      for (final messageId in messageIds) {
        final ref = _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .doc(messageId);
        batch.set(
            ref,
            {
              'deletedFor': {user.uid: true},
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true));
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Benden silme hatası: $e');
    }
  }

  // Mesajı düzenle
  static Future<void> editMessage(String messageId, String newText) async {
    try {
      // Chat alt koleksiyonundan güncellemek için chatId'yi bul
      final localMessage = await DriftService.getMessageById(messageId);
      if (localMessage == null) {
        throw Exception('Mesaj bulunamadı: $messageId');
      }
      await _firestore
          .collection('chats')
          .doc(localMessage.chatId)
          .collection('messages')
          .doc(messageId)
          .update({
        'text': newText,
        'isEdited': true,
        'editedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Mesaj düzenleme hatası: $e');
    }
  }

  // Typing indicator güncelle
  static Timer? _typingDebounce;
  static bool _lastTyping = false;

  static Future<void> updateTypingStatus(String chatId, bool isTyping) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Fazla yazma operasyonlarını azaltmak için debounce uygula
      _typingDebounce?.cancel();
      _typingDebounce = Timer(const Duration(milliseconds: 750), () async {
        // Aynı durumu tekrar yazmayalım
        if (_lastTyping == isTyping) return;
        _lastTyping = isTyping;
        await _firestore.collection('chats').doc(chatId).update({
          'typingUsers.${user.uid}':
              isTyping ? FieldValue.serverTimestamp() : FieldValue.delete(),
        });
      });
    } catch (e) {
      // Typing status hatası önemli değil, sessizce geç
    }
  }

  // Mesajı iletildi olarak işaretle
  static Future<void> markMessageAsDelivered(
    String chatId,
    String messageId,
  ) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
        'isDelivered': true,
        'deliveredAt': FieldValue.serverTimestamp(),
      });

      // Lokal mesajı güncelle
      final message = await DriftService.getMessageById(messageId);
      if (message != null) {
        message.status = MessageStatus.delivered;
        message.deliveredAt = DateTime.now();
        await DriftService.updateMessage(message);
      }
    } catch (e) {
      throw Exception('Mesaj iletildi güncelleme hatası: $e');
    }
  }

  // Mesajı okundu olarak işaretle
  static Future<void> markMessageAsRead(String chatId, String messageId) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({'isRead': true, 'readAt': FieldValue.serverTimestamp()});

      // Lokal mesajı güncelle
      final message = await DriftService.getMessageById(messageId);
      if (message != null) {
        message.status = MessageStatus.read;
        message.readAt = DateTime.now();
        await DriftService.updateMessage(message);
      }
    } catch (e) {
      throw Exception('Mesaj okundu güncelleme hatası: $e');
    }
  }

  // Mesajı güncelle
  static Future<void> updateMessage(MessageModel message) async {
    try {
      // Firebase'i güncelle
      await _firestore
          .collection('chats')
          .doc(message.chatId)
          .collection('messages')
          .doc(message.messageId)
          .update({
        'text': message.content,
        'isEdited': true,
        'editedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Yerel veritabanını güncelle
      await DriftService.updateMessage(message);

      debugPrint('✅ Mesaj güncellendi: ${message.messageId}');
    } catch (e) {
      debugPrint('❌ Mesaj güncelleme hatası: $e');
      throw Exception('Mesaj güncellenirken hata oluştu: $e');
    }
  }

  // Mesajları sabitle (chat seviyesinde pinnedMessageIds alanında tut)
  static Future<void> pinMessages(
    String chatId,
    List<String> messageIds,
  ) async {
    try {
      await _firestore.collection('chats').doc(chatId).set({
        'pinnedMessageIds': FieldValue.arrayUnion(messageIds),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Mesaj sabitleme hatası: $e');
    }
  }

  // Tek bir mesajın sabitliğini kaldır
  static Future<void> unpinMessage(String chatId, String messageId) async {
    try {
      await _firestore.collection('chats').doc(chatId).set({
        'pinnedMessageIds': FieldValue.arrayRemove([messageId]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Mesajı sabitten kaldırma hatası: $e');
    }
  }

  // Chat mesajları okundu olarak işaretle - Eğer ChatPage aktifse otomatik
  static Future<void> _autoMarkMessagesAsReadIfChatActive(
    String chatId,
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // ChatPage aktif mi ve bu chat mı kontrol et
      if (!_isChatPageActive || _activeChatId != chatId) {
        debugPrint(
          '⏸️ Chat aktif değil ($chatId != $_activeChatId), otomatik okuma yapılmıyor',
        );
        return; // Bu chat aktif değil, otomatik okuma yapma
      }

      // Yeni gelen mesajları kontrol et (sadece DocumentChangeType.added olanlar)
      final newMessages = snapshot.docChanges
          .where((change) => change.type == DocumentChangeType.added)
          .map((change) => change.doc.data())
          .where(
            (data) =>
                data != null &&
                data['senderId'] != user.uid && // Bizim mesajımız değil
                data['isRead'] != true, // Henüz okunmamış
          )
          .toList();

      if (newMessages.isNotEmpty) {
        debugPrint(
          '🔥 ${newMessages.length} yeni mesaj geldi, chat aktif olduğu için otomatik okundu işaretleniyor... (ChatID: $chatId)',
        );

        // Bu chat için otomatik mesaj okuma yap
        // Kısa bir gecikme ile (çok hızlı işaretlememek için)
        await Future.delayed(const Duration(milliseconds: 500));
        await markChatMessagesAsRead(chatId);
      }
    } catch (e) {
      debugPrint('❌ Otomatik mesaj okuma hatası: $e');
      // Hata önemli değil, sessizce geç
    }
  }

  // Chat'teki tüm mesajları okundu olarak işaretle
  static Future<void> markChatMessagesAsRead(String chatId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      debugPrint(
        '🔵 Mesajları okundu işaretliyorum - ChatID: $chatId, UserID: ${user.uid}',
      );

      // Sadece diğer kullanıcının gönderdiği okunmamış mesajları güncelle
      // Yalnızca bu kullanıcının alıcı olduğu mesajları hedefle (direct)
      final messagesQuery = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('recipientId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get();

      debugPrint('🔵 Okunacak mesaj sayısı: ${messagesQuery.docs.length}');

      final batch = _firestore.batch();
      for (final doc in messagesQuery.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      // Chat'in last message'ını okundu yap ve per-user unread sayacını sıfırla
      await _firestore.collection('chats').doc(chatId).set({
        'isLastMessageRead': true,
        'unreadCountByUser.${user.uid}': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Güçlü senkron: mevcut per-user map'i çekip bizim kaydı 0'a güncelle
      try {
        final chatRef = _firestore.collection('chats').doc(chatId);
        final snap = await chatRef.get();
        final data = snap.data();
        if (data != null) {
          final dynamic perUserAny = data['unreadCountByUser'];
          final Map<String, dynamic> perUserMap =
              perUserAny is Map<String, dynamic>
                  ? Map<String, dynamic>.from(perUserAny)
                  : <String, dynamic>{};
          perUserMap[user.uid] = 0;
          await chatRef.set({
            'unreadCountByUser': perUserMap,
            'isLastMessageRead': true,
            'unreadCount':
                0, // Eski alanı da sıfırla (artık okunmuyoruz ama güvenli)
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      } catch (_) {}

      debugPrint('✅ Mesajlar başarıyla okundu işaretlendi!');

      // Lokal chat'i güncelle
      final chat = await DriftService.getChatById(chatId);
      if (chat != null) {
        chat.isLastMessageRead = true;
        chat.unreadCount = 0;
        // Son mesaj bizden değilse, son mesajı okundu olarak işaretli
        if (chat.isLastMessageFromMe == false) {
          chat.isLastMessageRead = true;
        }
        await DriftService.updateChatModel(chat);
      }

      // Lokal mesajları güncelle
      final messages = await DriftService.getUnreadMessagesByChatId(chatId);
      for (final message in messages) {
        if (message.senderId != user.uid) {
          message.status = MessageStatus.read;
          message.readAt = DateTime.now();
          await DriftService.updateMessage(message);
        }
      }
    } catch (e) {
      throw Exception('Chat mesajları okundu güncelleme hatası: $e');
    }
  }
}
