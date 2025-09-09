import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../database/drift_service.dart';
import '../services/notification_service.dart';
import '../services/message_service.dart';
import '../services/tag_service.dart';
import '../services/contacts_service.dart';
import 'dart:async';

enum ChatFilter { all, unread, groups }

class ChatProvider extends ChangeNotifier {
  List<ChatModel> _chats = [];
  List<ChatModel> _filteredChats = [];
  ChatFilter _currentFilter = ChatFilter.all;
  bool _isLoading = false;
  String _searchQuery = '';

  // Çoklu seçim modu için yeni state'ler
  bool _isSelectionMode = false;
  List<String> _selectedChatIds = [];

  // Drift stream subscription for real-time UI updates
  StreamSubscription? _driftChatsSubscription;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Getters
  List<ChatModel> get chats => _filteredChats;
  List<ChatModel> get archivedChats =>
      _chats.where((chat) => chat.isArchived).toList();
  ChatFilter get currentFilter => _currentFilter;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  // Çoklu seçim modu getters
  bool get isSelectionMode => _isSelectionMode;
  List<String> get selectedChatIds => _selectedChatIds;
  int get selectedCount => _selectedChatIds.length;

  // Constructor - Yeni mimari: sadece Drift dinle
  ChatProvider() {
    _initializeChatProvider();
  }

  // Chat provider'ı başlat
  Future<void> _initializeChatProvider() async {
    final user = _auth.currentUser;
    if (user == null) return;

    debugPrint('🚀 ChatProvider baslatiliyor - Yeni mimari');

    // 1. Notification service callback'ini ayarla
    _setupNotificationCallback();

    // 2. İlk açılışta Firebase senkronizasyonunu arka plana al
    unawaited(_performInitialSyncFromFirebase());

    // 3. Drift'ten real-time chat listesi dinle
    _startListeningToLocalChats();

    // 4. İlk chat listesini yükle
    await loadChats();
  }

  // Notification service callback'ini ayarla
  void _setupNotificationCallback() {
    NotificationService.setNewMessageCallback(
      _handleNewMessageFromNotification,
    );
  }

  // Push notification'dan gelen yeni mesajı işle
  Future<void> _handleNewMessageFromNotification(
    String chatId,
    String messageId,
    Map<String, dynamic> messageData,
  ) async {
    await handleNewMessageNotification(
      chatId: chatId,
      messageId: messageId,
      messageData: messageData,
    );
  }

  // İlk açılışta Firebase'den tüm chatleri Isar'a senkronize et
  Future<void> _performInitialSyncFromFirebase() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      debugPrint('🔄 Firebase ilk senkronizasyon baslatiliyor...');

      // Eğer daha önce senkronize edildiyse ağır full fetch yerine sadece güncellenenleri çek
      final lastLocalUpdate = _chats.isEmpty
          ? null
          : (_chats
              .map((c) => c.updatedAt)
              .whereType<DateTime>()
              .fold<DateTime?>(
                null,
                (p, e) => p == null || e.isAfter(p) ? e : p,
              ));

      Query<Map<String, dynamic>> query = _firestore
          .collection('chats')
          .where('participants', arrayContains: user.uid);

      if (lastLocalUpdate != null) {
        query = query.where('updatedAt',
            isGreaterThan: Timestamp.fromDate(lastLocalUpdate));
      }

      QuerySnapshot<Map<String, dynamic>> chatsSnapshot;
      try {
        chatsSnapshot = await query.get();
      } catch (e) {
        // Çevrimdışıysa sessizce yerel veriye düş
        debugPrint(
            '⚠️ Firebase erişilemedi, yerel Drift verisi kullanılacak: $e');
        _chats = await DriftService.getAllChats();
        _applyFilter();
        notifyListeners();
        return;
      }

      debugPrint('📦 Firebase ${chatsSnapshot.docs.length} chat bulundu');

      // Her chat'i Drift'e kaydet
      for (final doc in chatsSnapshot.docs) {
        await _syncSingleChatToDrift(doc.id, doc.data());
      }

      // İlk giriş optimizasyonu: son 7 güne ait sohbetler ve her sohbetin son 100 mesajını önceden indir
      try {
        final cutoff = DateTime.now().subtract(const Duration(days: 7));
        QuerySnapshot<Map<String, dynamic>>? recentChatsSnap;
        try {
          recentChatsSnap = await _firestore
              .collection('chats')
              .where('participants', arrayContains: user.uid)
              .where('updatedAt', isGreaterThan: Timestamp.fromDate(cutoff))
              .orderBy('updatedAt', descending: true)
              .get();
        } catch (e) {
          debugPrint('⚠️ Prefetch çevrimdışı: $e');
          recentChatsSnap = null;
        }
        if (recentChatsSnap != null) {
          for (final chatDoc in recentChatsSnap.docs) {
            final chatId = chatDoc.id;
            await MessageService.prefetchLastMessagesToIsar(
              chatId: chatId,
              limit: 100,
            );
          }
        }
        debugPrint('✅ Son 7 gün sohbetleri ve son 100 mesaj önbelleğe alındı');
      } catch (e) {
        debugPrint('❌ Prefetch sohbet/mesaj hatası: $e');
      }

      debugPrint('✅ İlk senkronizasyon tamamlandı');
    } catch (e) {
      debugPrint('❌ İlk senkronizasyon hatası: $e');
      // Tamamıyla başarısızsa yine de yerel veriyi göster
      _chats = await DriftService.getAllChats();
      _applyFilter();
      notifyListeners();
    }
  }

  // Tek bir chat'i Firebase'den Drift'e senkronize et
  Future<void> _syncSingleChatToDrift(
    String chatId,
    Map<String, dynamic> chatData,
  ) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      final bool isGroup =
          (chatData['isGroup'] == true) || (chatData['type'] == 'group');

      ChatModel chat;
      if (isGroup) {
        // Grup chat modeli
        final dynamic perUser = chatData['unreadCountByUser'];
        final int perUserUnread = (perUser is Map<String, dynamic>)
            ? ((perUser[currentUserId] as num?)?.toInt() ?? 0)
            : 0;

        chat = ChatModel.createGroup(
          chatId: chatId,
          groupId: (chatData['groupId'] as String?) ?? chatId,
          groupName: (chatData['groupName'] as String?) ?? 'Grup',
          groupImage: chatData['groupImage'] as String?,
          groupDescription: chatData['groupDescription'] as String?,
          lastMessage: chatData['lastMessage'] as String?,
          isLastMessageFromMe:
              (chatData['isLastMessageFromMe'] as bool?) ?? false,
          isLastMessageRead: (chatData['isLastMessageRead'] as bool?) ?? false,
          unreadCount: perUserUnread,
        );

        // Timestamp'leri dönüştür
        if (chatData['lastMessageTime'] is Timestamp) {
          chat.lastMessageTime =
              (chatData['lastMessageTime'] as Timestamp).toDate();
        }
        if (chatData['createdAt'] is Timestamp) {
          chat.createdAt = (chatData['createdAt'] as Timestamp).toDate();
        }
        if (chatData['updatedAt'] is Timestamp) {
          chat.updatedAt = (chatData['updatedAt'] as Timestamp).toDate();
        }
      } else {
        // Bireysel chat modeli
        final participants = List<String>.from(chatData['participants'] ?? []);
        final otherUserId = participants.firstWhere(
          (id) => id != currentUserId,
          orElse: () => '',
        );
        if (otherUserId.isEmpty) return;

        final dynamic perUser = chatData['unreadCountByUser'];
        final int perUserUnread = (perUser is Map<String, dynamic>)
            ? ((perUser[currentUserId] as num?)?.toInt() ?? 0)
            : 0;

        chat = ChatModel.create(
          chatId: chatId,
          otherUserId: otherUserId,
          lastMessage: chatData['lastMessage'] ?? '',
          isLastMessageFromMe: chatData['isLastMessageFromMe'] ?? false,
          isLastMessageRead: chatData['isLastMessageRead'] ?? false,
          unreadCount: perUserUnread,
        );

        // Timestamp'leri dönüştür
        if (chatData['lastMessageTime'] is Timestamp) {
          chat.lastMessageTime =
              (chatData['lastMessageTime'] as Timestamp).toDate();
        }
        if (chatData['createdAt'] is Timestamp) {
          chat.createdAt = (chatData['createdAt'] as Timestamp).toDate();
        }
        if (chatData['updatedAt'] is Timestamp) {
          chat.updatedAt = (chatData['updatedAt'] as Timestamp).toDate();
        }

        // Sadece bireysel sohbetlerde kullanıcı bilgisi çek
        await _fetchAndSetUserInfo(chat, otherUserId);
      }

      // Yerel verilerle birleştir
      final existingLocal = await DriftService.getChatById(chatId);
      if (existingLocal != null) {
        chat.tags = List<String>.from(existingLocal.tags);
        chat.isPinned = existingLocal.isPinned;
        chat.isMuted = existingLocal.isMuted;
        chat.isArchived = existingLocal.isArchived;
        if (!chat.isGroup) {
          if (existingLocal.otherUserContactName != null &&
              existingLocal.otherUserContactName!.isNotEmpty) {
            chat.otherUserContactName = existingLocal.otherUserContactName;
          }
          // Profil ismi/telefonu/fotoğrafı boş gelirse yereldekini koru
          if ((chat.otherUserProfileImage == null ||
                  chat.otherUserProfileImage!.isEmpty) &&
              (existingLocal.otherUserProfileImage != null &&
                  existingLocal.otherUserProfileImage!.isNotEmpty)) {
            chat.otherUserProfileImage = existingLocal.otherUserProfileImage;
          }
          if ((chat.otherUserName == null || chat.otherUserName!.isEmpty) &&
              (existingLocal.otherUserName != null &&
                  existingLocal.otherUserName!.isNotEmpty)) {
            chat.otherUserName = existingLocal.otherUserName;
          }
          if ((chat.otherUserPhoneNumber == null ||
                  chat.otherUserPhoneNumber!.isEmpty) &&
              (existingLocal.otherUserPhoneNumber != null &&
                  existingLocal.otherUserPhoneNumber!.isNotEmpty)) {
            chat.otherUserPhoneNumber = existingLocal.otherUserPhoneNumber;
          }
        }
        // Grup adı ve görseli Firebase'den güncel geliyorsa üzerine yaz, boşsa yereldekini koru
        if (chat.isGroup) {
          if ((chat.groupName == null || chat.groupName!.isEmpty) &&
              (existingLocal.groupName != null &&
                  existingLocal.groupName!.isNotEmpty)) {
            chat.groupName = existingLocal.groupName;
          }
          if ((chat.groupImage == null || chat.groupImage!.isEmpty) &&
              (existingLocal.groupImage != null &&
                  existingLocal.groupImage!.isNotEmpty)) {
            chat.groupImage = existingLocal.groupImage;
          }
        }
      }

      await DriftService.saveChat(chat);
      debugPrint('💾 Chat Drift e kaydedildi: $chatId');
    } catch (e) {
      debugPrint('❌ Chat senkronizasyon hatası ($chatId): $e');
    }
  }

  // Kullanıcı bilgilerini Firebase'den alıp chat'e ata
  Future<void> _fetchAndSetUserInfo(ChatModel chat, String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null) {
          chat.otherUserName = userData['name'] ??
              userData['displayName'] ??
              'Firebase Kullanıcısı';
          chat.otherUserPhoneNumber = userData['phoneNumber'];
          chat.otherUserProfileImage =
              userData['profileImageUrl'] ?? userData['photoURL'];
          debugPrint('👤 Kullanıcı bilgileri alındı: ${chat.otherUserName}');
        }
      } else {
        // Firebase'de kullanıcı bulunamadıysa varsayılan ad ata
        chat.otherUserName = 'Kullanıcı ($userId)';
        debugPrint('⚠️ Firebase\'de kullanıcı bulunamadı: $userId');
      }
    } catch (e) {
      debugPrint('❌ Kullanıcı bilgisi alma hatası: $e');
      chat.otherUserName = 'Bilinmeyen Kullanıcı';
    }
  }

  // Lokal Drift veritabanını dinle (gerçek zamanlı UI güncellemesi)
  void _startListeningToLocalChats() {
    debugPrint('👂 Drift chat dinleyicisi baslatiliyor...');

    _driftChatsSubscription?.cancel();
    _driftChatsSubscription = DriftService.watchAllChats().listen(
      (chats) {
        debugPrint('🔄 Drift ten ${chats.length} chat guncellendi');
        _chats = chats;
        _applyFilter();
        notifyListeners();
      },
      onError: (error) {
        debugPrint('❌ Drift chat dinleyici hatası: $error');
      },
    );
  }

  @override
  void dispose() {
    _driftChatsSubscription?.cancel();
    super.dispose();
  }

  // Manuel yenileme kaldırıldı (Isar akışı otomatik günceller)

  // Chat'leri veritabanından yükle (sadece ilk açılışta)
  Future<void> loadChats() async {
    if (_chats.isNotEmpty) {
      // Zaten yüklü, Isar listener otomatik güncelleyecek
      return;
    }

    _isLoading = true;
    // Build frame içindeyken notifyListeners çağırmayı engelle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      _chats = await DriftService.getAllChats();

      // Chat'lerdeki rehber isimlerini güncelle
      await _updateContactNames();

      _applyFilter();
      debugPrint('🔄 Chat listesi ilk yukleme: ${_chats.length} chat');
    } catch (e) {
      debugPrint('Chat yukleme hatasi: $e');
    } finally {
      _isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  // Push notification ile yeni mesaj geldiğinde çağrılacak
  Future<void> handleNewMessageNotification({
    required String chatId,
    required String messageId,
    required Map<String, dynamic> messageData,
  }) async {
    try {
      debugPrint('🔔 Push notification: Yeni mesaj $messageId, Chat: $chatId');

      // Önce mesajı Isar'a kaydet
      await _saveMessageToIsar(messageId, messageData);

      // Chat'i güncelle ve kullanıcı bilgilerini al
      await _updateChatFromNewMessage(chatId, messageData);

      // Chat'in kullanıcı bilgilerini güncelle
      await _updateChatUserInfo(chatId, messageData['senderId']);

      debugPrint('✅ Push notification işlendi');
    } catch (e) {
      debugPrint('❌ Push notification işleme hatası: $e');
    }
  }

  // Mesajı Isar'a kaydet
  Future<void> _saveMessageToIsar(
    String messageId,
    Map<String, dynamic> messageData,
  ) async {
    try {
      final message = MessageModel.create(
        messageId: messageId,
        chatId: messageData['chatId'] ?? '',
        senderId: messageData['senderId'] ?? '',
        content: messageData['text'] ?? '',
        type: MessageType.text,
        status: MessageStatus.delivered,
      );

      if (messageData['timestamp'] != null) {
        message.timestamp = (messageData['timestamp'] as Timestamp).toDate();
      }

      await DriftService.saveMessage(message);
      debugPrint('💾 Mesaj Drift e kaydedildi: $messageId');
    } catch (e) {
      debugPrint('❌ Mesaj Drift kayit hatasi: $e');
    }
  }

  // Chat'i yeni mesajla güncelle
  Future<void> _updateChatFromNewMessage(
    String chatId,
    Map<String, dynamic> messageData,
  ) async {
    try {
      ChatModel? chat = await DriftService.getChatById(chatId);
      if (chat == null) {
        // Firestore'dan chat'i getir ve Isar'a senkronize et
        try {
          final chatDoc =
              await _firestore.collection('chats').doc(chatId).get();
          if (chatDoc.exists) {
            await _syncSingleChatToDrift(chatId, chatDoc.data()!);
            chat = await DriftService.getChatById(chatId);
          }
        } catch (e) {
          debugPrint(
              '⚠️ Push ile gelen mesajda chat senkronizasyon hatası: $e');
        }
        if (chat == null) {
          debugPrint('⚠️ Chat bulunamadi: $chatId');
          return;
        }
      }

      final currentUserId = _auth.currentUser?.uid;
      final isFromCurrentUser = messageData['senderId'] == currentUserId;

      // Chat'i güncelle
      chat.lastMessage = messageData['text'] ?? '';
      chat.isLastMessageFromMe = isFromCurrentUser;
      // Kendi mesajlarımız için okunmuş kabul; karşı tarafın mesajıysa aktif ekranda ise okunmuş say
      final bool isActiveThisChat = MessageService.isChatPageActive &&
          MessageService.activeChatId == chatId;
      chat.isLastMessageRead = isFromCurrentUser || isActiveThisChat;

      if (messageData['timestamp'] != null) {
        chat.lastMessageTime = (messageData['timestamp'] as Timestamp).toDate();
      }

      // Eğer mesaj başkasından ise ve bu chat aktif değilse unread count'u artır
      if (!isFromCurrentUser) {
        if (isActiveThisChat) {
          chat.unreadCount = 0; // aktif ekranda: okunmuş kabul
        } else {
          chat.unreadCount = chat.unreadCount + 1;
        }
      }

      chat.updatedAt = DateTime.now();

      await DriftService.updateChatModel(chat);

      // Aktif ekranda gelen mesaj ise, per-user unread'ı ve mesajları da okundu yap (arka planda)
      if (!isFromCurrentUser && isActiveThisChat) {
        try {
          await MessageService.markChatMessagesAsRead(chatId);
        } catch (_) {}
      }
      debugPrint('📊 Chat guncellendi: ${chat.chatId}');
    } catch (e) {
      debugPrint('❌ Chat guncelleme hatasi: $e');
    }
  }

  // Sadece belirli bir chat'i Firebase'den sync et (push notification ile)
  Future<void> syncSingleChatFromFirebase(String chatId) async {
    try {
      debugPrint('🔄 Tek chat sync: $chatId');

      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (chatDoc.exists) {
        await _syncSingleChatToDrift(chatId, chatDoc.data()!);
        debugPrint('✅ Chat sync tamamlandi: $chatId');
      }
    } catch (e) {
      debugPrint('❌ Chat sync hatasi: $e');
    }
  }

  // Chat'lere filtre uygula
  void _applyFilter() {
    switch (_currentFilter) {
      case ChatFilter.all:
        _filteredChats = _chats
            .where((chat) => !chat.isArchived)
            .where(
              (chat) =>
                  _searchQuery.isEmpty ||
                  (chat.otherUserContactName?.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ) ==
                      true) ||
                  (chat.lastMessage?.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ) ==
                      true),
            )
            .toList();
        break;
      case ChatFilter.unread:
        _filteredChats = _chats
            .where((chat) => !chat.isArchived && chat.unreadCount > 0)
            .where(
              (chat) =>
                  _searchQuery.isEmpty ||
                  (chat.otherUserContactName?.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ) ==
                      true) ||
                  (chat.lastMessage?.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ) ==
                      true),
            )
            .toList();
        break;
      case ChatFilter.groups:
        // Sadece grup chatlerini göster
        _filteredChats = _chats
            .where((chat) => !chat.isArchived && chat.isGroup)
            .where(
              (chat) =>
                  _searchQuery.isEmpty ||
                  (chat.groupName?.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ) ==
                      true) ||
                  (chat.lastMessage?.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ) ==
                      true),
            )
            .toList();
        break;
    }
  }

  // Filter değiştir
  void setFilter(ChatFilter filter) {
    _currentFilter = filter;
    _applyFilter();
    notifyListeners();
  }

  // Arama
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilter();
    notifyListeners();
  }

  // Chat'i okundu olarak işaretle
  Future<void> markChatAsRead(String chatId) async {
    try {
      final chat = await DriftService.getChatById(chatId);
      if (chat != null && chat.unreadCount > 0) {
        chat.unreadCount = 0;
        chat.isLastMessageRead = true;
        await DriftService.updateChatModel(chat);
      }
    } catch (e) {
      debugPrint('❌ Chat okuma hatası: $e');
    }
  }

  // Chat'in kullanıcı bilgilerini güncelle
  Future<void> _updateChatUserInfo(String chatId, String senderId) async {
    try {
      final chat = await DriftService.getChatById(chatId);
      if (chat == null) return;

      // Eğer gönderen ID'si chat'teki other user ID'si değilse güncelle
      if (chat.otherUserId != senderId) {
        chat.otherUserId = senderId;
      }

      // Eğer kullanıcı adı eksik, boş veya "Bilinmeyen" ise Firebase'den al
      bool needsUpdate = chat.otherUserName == null ||
          chat.otherUserName!.isEmpty ||
          chat.otherUserName == 'Bilinmeyen' ||
          chat.otherUserName == 'Bilinmeyen Kullanıcı';

      if (needsUpdate) {
        // Kullanıcı bilgilerini Firebase'den al
        final userDoc =
            await _firestore.collection('users').doc(senderId).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData != null) {
            // Kullanıcı bilgilerini güncelle
            chat.otherUserName = userData['name'] ??
                userData['displayName'] ??
                'Firebase Kullanıcısı';
            chat.otherUserPhoneNumber = userData['phoneNumber'];
            chat.otherUserProfileImage =
                userData['profileImageUrl'] ?? userData['photoURL'];

            await DriftService.updateChatModel(chat);
            debugPrint(
              '👤 Chat kullanıcı bilgileri güncellendi: ${chat.otherUserName}',
            );
          }
        } else {
          // Firebase'de de kullanıcı bulunamadıysa varsayılan ad ata
          if (chat.otherUserName == null || chat.otherUserName!.isEmpty) {
            chat.otherUserName = 'Kullanıcı ($senderId)';
            await DriftService.updateChatModel(chat);
            debugPrint(
                '👤 Varsayılan kullanıcı adı atandı: ${chat.otherUserName}');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Chat kullanıcı bilgisi güncelleme hatası: $e');
    }
  }

  // Rehber isimlerini güncelle
  Future<void> _updateContactNames() async {
    try {
      for (final chat in _chats) {
        final phone = chat.otherUserPhoneNumber;
        if (phone != null && phone.isNotEmpty) {
          final contactName = await ContactsService.getContactNameByPhone(
            phone,
          );
          if (contactName != null && contactName.isNotEmpty) {
            if (chat.otherUserContactName != contactName) {
              chat.otherUserContactName = contactName;
              await DriftService.updateChatModel(chat);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Rehber güncelleme hatası: $e');
    }
  }

  // Chat'leri yenile (manuel)
  Future<void> refreshChats() async {
    await loadChats();
  }

  // Chat'leri hemen yükle (eski API uyumluluğu için)
  Future<void> loadChatsImmediately() async {
    await loadChats();
  }

  // Chat ekle veya güncelle
  Future<void> addOrUpdateChat(ChatModel chat) async {
    try {
      await DriftService.saveChat(chat);
      debugPrint('💾 Chat eklendi/güncellendi: ${chat.chatId}');
    } catch (e) {
      debugPrint('❌ Chat ekleme/güncelleme hatası: $e');
    }
  }

  // Chat'i sabitle/sabitlemeyi kaldır
  Future<void> togglePin(String chatId) async {
    try {
      final chat = await DriftService.getChatById(chatId);
      if (chat != null) {
        chat.isPinned = !chat.isPinned;
        await DriftService.updateChatModel(chat);

        // Firebase'e de güncelle
        await _firestore.collection('chats').doc(chatId).update({
          'isPinned': chat.isPinned,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        debugPrint(
          '📌 Chat pin durumu değiştirildi: ${chat.chatId} -> ${chat.isPinned}',
        );
      }
    } catch (e) {
      debugPrint('❌ Chat pin hatası: $e');
    }
  }

  // Chat'i sustur/susturmayı kaldır
  Future<void> toggleMute(String chatId) async {
    try {
      final chat = await DriftService.getChatById(chatId);
      if (chat != null) {
        chat.isMuted = !chat.isMuted;
        await DriftService.updateChatModel(chat);

        // Firebase'e de güncelle
        await _firestore.collection('chats').doc(chatId).update({
          'isMuted': chat.isMuted,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        debugPrint(
          '🔇 Chat mute durumu değiştirildi: ${chat.chatId} -> ${chat.isMuted}',
        );
      }
    } catch (e) {
      debugPrint('❌ Chat mute hatası: $e');
    }
  }

  // Chat'i arşivle/arşivden çıkar
  Future<void> toggleArchive(String chatId) async {
    try {
      final chat = await DriftService.getChatById(chatId);
      if (chat != null) {
        chat.isArchived = !chat.isArchived;
        await DriftService.updateChatModel(chat);

        // Firebase'e de güncelle
        await _firestore.collection('chats').doc(chatId).update({
          'isArchived': chat.isArchived,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        debugPrint(
          '📦 Chat arşiv durumu değiştirildi: ${chat.chatId} -> ${chat.isArchived}',
        );
      }
    } catch (e) {
      debugPrint('❌ Chat arşiv hatası: $e');
    }
  }

  // Chat'i benden gizle (soft-delete) - Firestore kuralları gereği tüm chati silme yok
  Future<void> deleteChat(String chatId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Yerelde chat'i kaldır
      await DriftService.deleteChat(chatId);

      // Firestore'da kullanıcıya özel işaretle
      await _firestore.collection('chats').doc(chatId).set({
        'deletedFor': {user.uid: true},
        'deletedAtByUser': {user.uid: FieldValue.serverTimestamp()},
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('🗑️ Chat benden gizlendi: $chatId');
    } catch (e) {
      debugPrint('❌ Chat silme hatası: $e');
    }
  }

  // Tüm etiketleri getir
  List<String> getAllTags() {
    final tags = <String>{};
    for (final chat in _chats) {
      tags.addAll(chat.tags);
    }
    return tags.toList()..sort();
  }

  // Belirli etikete sahip chat'leri getir
  List<ChatModel> getChatsWithTag(String tag) {
    return _chats.where((chat) => chat.tags.contains(tag)).toList();
  }

  // Birden çok etikete göre filtrele (hepsini içeren)
  List<ChatModel> getChatsWithTags(List<String> tagIds,
      {bool anyMatch = true}) {
    if (tagIds.isEmpty) return _chats;
    return _chats.where((chat) {
      if (anyMatch) {
        return chat.tags.any((t) => tagIds.contains(t));
      } else {
        // hepsini içersin
        return tagIds.every((t) => chat.tags.contains(t));
      }
    }).toList();
  }

  // Tüm chat'lerden etiketi kaldır
  Future<void> removeTagFromAllChats(String tag) async {
    try {
      for (final chat in _chats) {
        if (chat.tags.contains(tag)) {
          chat.tags.remove(tag);
          await DriftService.updateChatModel(chat);

          // Firebase'e de güncelle
          await _firestore.collection('chats').doc(chat.chatId).update({
            'tags': chat.tags,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
      debugPrint('🏷️ Etiket tüm chat\'lerden kaldırıldı: $tag');
    } catch (e) {
      debugPrint('❌ Etiket kaldırma hatası: $e');
    }
  }

  // ==================== ÇOKLU SEÇİM MODU FONKSİYONLARI ====================

  // Çoklu seçim modunu başlat
  void enterSelectionMode(String chatId) {
    _isSelectionMode = true;
    _selectedChatIds = [chatId];
    notifyListeners();
  }

  // Çoklu seçim modundan çık
  void exitSelectionMode() {
    _isSelectionMode = false;
    _selectedChatIds.clear();
    notifyListeners();
  }

  // Chat'i seçime ekle/çıkar
  void toggleChatSelection(String chatId) {
    if (_selectedChatIds.contains(chatId)) {
      _selectedChatIds.remove(chatId);
      // Eğer hiç seçili chat kalmadıysa seçim modundan çık
      if (_selectedChatIds.isEmpty) {
        exitSelectionMode();
      }
    } else {
      _selectedChatIds.add(chatId);
    }
    notifyListeners();
  }

  // Chat seçili mi kontrol et
  bool isChatSelected(String chatId) {
    return _selectedChatIds.contains(chatId);
  }

  // Tüm chat'leri seç
  void selectAllChats() {
    _selectedChatIds = _filteredChats.map((chat) => chat.chatId).toList();
    notifyListeners();
  }

  // ==================== TOPLU İŞLEMLER ====================

  // Seçili chat'leri sabitle/sabitlemeyi kaldır
  Future<void> togglePinForSelected() async {
    try {
      for (final chatId in _selectedChatIds) {
        await togglePin(chatId);
      }
      exitSelectionMode();
    } catch (e) {
      debugPrint('❌ Toplu sabitleme hatası: $e');
    }
  }

  // Seçili chat'leri sessizle/sesini aç
  Future<void> toggleMuteForSelected() async {
    try {
      for (final chatId in _selectedChatIds) {
        await toggleMute(chatId);
      }
      exitSelectionMode();
    } catch (e) {
      debugPrint('❌ Toplu sessizlik hatası: $e');
    }
  }

  // Seçili chat'leri arşivle/arşivden çıkar
  Future<void> toggleArchiveForSelected() async {
    try {
      for (final chatId in _selectedChatIds) {
        await toggleArchive(chatId);
      }
      exitSelectionMode();
      debugPrint(
        '📦 Toplu arşiv işlemi tamamlandı: ${_selectedChatIds.length} sohbet',
      );
    } catch (e) {
      debugPrint('❌ Toplu arşiv hatası: $e');
    }
  }

  // Seçili chat'leri sil
  Future<void> deleteSelectedChats() async {
    try {
      final List<String> chatsToDelete = List.from(_selectedChatIds);
      for (final chatId in chatsToDelete) {
        await deleteChat(chatId);
      }
      exitSelectionMode();
    } catch (e) {
      debugPrint('❌ Toplu silme hatası: $e');
    }
  }

  // Seçili chat'lere etiket ekle
  Future<void> addTagToSelected(List<String> tagIds) async {
    try {
      final tagService = TagService();

      for (final chatId in _selectedChatIds) {
        for (final tagId in tagIds) {
          await tagService.addTagToChat(chatId, tagId);
        }
      }

      // Local cache'i güncelle
      await loadChats();
      exitSelectionMode();
      debugPrint(
        '🏷️ Etiketler eklendi: ${tagIds.length} etiket, ${_selectedChatIds.length} sohbet',
      );
    } catch (e) {
      debugPrint('❌ Toplu etiket ekleme hatası: $e');
    }
  }

  // Seçili chat'lerden etiket kaldır
  Future<void> removeTagFromSelected(String tagId) async {
    try {
      final tagService = TagService();

      for (final chatId in _selectedChatIds) {
        await tagService.removeTagFromChat(chatId, tagId);
      }

      // Local cache'i güncelle
      await loadChats();
      exitSelectionMode();
      debugPrint('🏷️ Etiket kaldırıldı: $tagId');
    } catch (e) {
      debugPrint('❌ Toplu etiket kaldırma hatası: $e');
    }
  }

  // Tek chat'e etiket ekle
  Future<void> addTagToChat(String chatId, String tagId) async {
    try {
      final tagService = TagService();
      await tagService.addTagToChat(chatId, tagId);

      // Local cache'i güncelle
      await loadChats();
      debugPrint('🏷️ Etiket eklendi: $tagId -> $chatId');
    } catch (e) {
      debugPrint('❌ Etiket ekleme hatası: $e');
    }
  }

  // Tek chat'den etiket kaldır
  Future<void> removeTagFromChat(String chatId, String tagId) async {
    try {
      final tagService = TagService();
      await tagService.removeTagFromChat(chatId, tagId);

      // Local cache'i güncelle
      await loadChats();
      debugPrint('🏷️ Etiket kaldırıldı: $tagId <- $chatId');
    } catch (e) {
      debugPrint('❌ Etiket kaldırma hatası: $e');
    }
  }

  // Seçili chat'leri okundu/okunmadı olarak işaretle
  Future<void> markSelectedAsRead(bool isRead) async {
    try {
      for (final chatId in _selectedChatIds) {
        final chat = _chats.firstWhere((c) => c.chatId == chatId);
        if (isRead) {
          chat.unreadCount = 0;
          chat.isLastMessageRead = true;
        } else {
          chat.unreadCount = 1;
          chat.isLastMessageRead = false;
        }
        await DriftService.updateChatModel(chat);
      }
      exitSelectionMode();
    } catch (e) {
      debugPrint('❌ Toplu okuma durumu hatası: $e');
    }
  }
}
