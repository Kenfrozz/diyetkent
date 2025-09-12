import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/story_model.dart';
import '../database/drift_service.dart';
import 'contacts_service.dart';
import 'dart:async';
import 'firebase_usage_tracker.dart';

class StoryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Story oluştur
  static Future<String?> createStory({
    required StoryType type,
    required String content,
    String? mediaUrl,
    String? thumbnailUrl,
    String? backgroundColor,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Kullanıcı giriş yapmamış');

    try {
      // Kullanıcı bilgilerini al
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      await FirebaseUsageTracker.incrementRead(1);
      final userData = userDoc.data() ?? {};

      // Story ID oluştur
      final storyId = DateTime.now().millisecondsSinceEpoch.toString();

      // Kullanıcının gizlilik ayarlarını al
      final privacy = await getPrivacySettings(user.uid);
      final String visibilityMode = privacy['mode'] ?? 'contacts';
      final List<String> visibilityAllowed =
          List<String>.from(privacy['allowedIds'] ?? const <String>[]);
      final List<String> visibilityExcluded =
          List<String>.from(privacy['excludedIds'] ?? const <String>[]);

      final now = DateTime.now();
      final storyData = {
        'storyId': storyId,
        'userId': user.uid,
        'userPhone': user.phoneNumber ?? '',
        'userName': userData['name'] ?? userData['displayName'] ?? 'Bilinmeyen',
        'userProfileImage':
            userData['profileImageUrl'] ?? userData['photoURL'] ?? '',
        'type': type.toString().split('.').last,
        // Mesaj şeması ile uyum için "text" de ekleyelim
        'text': content,
        'content': content,
        'mediaUrl': mediaUrl,
        'thumbnailUrl': thumbnailUrl,
        'backgroundColor': backgroundColor ?? '#FF4CAF50',
        'createdAt': FieldValue.serverTimestamp(),
        // expiresAt: now + 24 saat (TTL veya sorgu filtresi için net değer)
        'expiresAt': Timestamp.fromDate(now.add(const Duration(hours: 24))),
        'isViewed': false,
        'viewerIds': [],
        'repliedUserIds': [],
        'isActive': true,
        // Gizlilik snapshot'ı
        'visibilityMode': visibilityMode,
        'visibilityAllowed': visibilityAllowed,
        'visibilityExcluded': visibilityExcluded,
      };

      // Firebase'e kaydet
      await _firestore.collection('stories').doc(storyId).set(storyData);
      await FirebaseUsageTracker.incrementWrite(1);

      // Yerel veritabanına kaydet
      final story = StoryModel.fromMap({
        ...storyData,
        // UI için tahmini zamanlar; server tarafında da timestamp yazıyoruz
        'createdAt': now,
        'expiresAt': now.add(const Duration(hours: 24)),
      });
      story.isFromCurrentUser = true;

      await DriftService.saveStory(story);

      debugPrint('📖 Story oluşturuldu: $storyId');
      return storyId;
    } catch (e) {
      debugPrint('❌ Story oluşturma hatası: $e');
      throw Exception('Story oluşturulamadı: $e');
    }
  }

  // Story'leri dinle
  static StreamSubscription<QuerySnapshot>? _storiesSubscription;

  static void startListeningStories(
    Function(List<StoryModel>)? onStoriesUpdated,
  ) {
    final user = _auth.currentUser;
    if (user == null) return;

    debugPrint('👂 Story dinleme başlatıldı');

    // Mevcut subscription'ı iptal et
    _storiesSubscription?.cancel();

    // Aktif story'leri dinle
    final nowTs = Timestamp.fromDate(DateTime.now());
    _storiesSubscription = _firestore
        .collection('stories')
        .where('isActive', isEqualTo: true)
        .where('expiresAt', isGreaterThan: nowTs)
        .orderBy('expiresAt', descending: true)
        .limit(200)
        .snapshots()
        .listen((snapshot) async {
      debugPrint('📖 ${snapshot.docs.length} story alındı');
      await FirebaseUsageTracker.incrementRead(snapshot.docs.length);

      List<StoryModel> stories = [];

      for (var doc in snapshot.docs) {
        try {
          final storyData = doc.data();
          // Görünürlük kontrolü
          final mode = storyData['visibilityMode'] as String?;
          final List<dynamic>? allowedAny = storyData['visibilityAllowed'];
          final List<dynamic>? excludedAny = storyData['visibilityExcluded'];
          final List<String> allowed =
              allowedAny?.whereType<String>().toList() ?? const <String>[];
          final List<String> excluded =
              excludedAny?.whereType<String>().toList() ?? const <String>[];

          bool visible = true;
          if (mode == 'only') {
            visible = allowed.contains(user.uid);
          } else if (mode == 'except') {
            visible = !excluded.contains(user.uid);
          } // 'contacts' veya null -> görünür (rehber filtresi UI seviyesinde)

          if (!visible && (storyData['userId'] != user.uid)) {
            continue;
          }

          final story = StoryModel.fromMap(storyData);

          // Kendi story'imiz mi kontrol et
          story.isFromCurrentUser = story.userId == user.uid;

          // Rehberden kullanıcı bilgilerini al
          if (!story.isFromCurrentUser) {
            final contact = await ContactsService.getContactByPhone(
              story.userPhone,
            );
            if (contact != null) {
              story.userName = contact.displayName;
            }
          }

          // Yerel veritabanına kaydet
          await DriftService.saveStory(story);
          stories.add(story);
        } catch (e) {
          debugPrint('❌ Story parse hatası: $e');
        }
      }

      // Callback'i çağır (eğer varsa)
      onStoriesUpdated?.call(stories);
    });
  }

  // Isar üstünden story akışını (UI için) sunan yardımcı
  static Stream<List<StoryModel>> watchActiveStoriesFromIsar() {
    return DriftService.watchAllActiveStories();
  }

  static void stopListeningStories() {
    _storiesSubscription?.cancel();
    _storiesSubscription = null;
    debugPrint('🔇 Story dinleme durduruldu');
  }

  // Story görüntüle
  static Future<void> viewStory(String storyId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Önce yerel veritabanından kontrol et - zaten görüntülenmişse Firebase'e yazma
      final localStory = await DriftService.getStoryById(storyId);
      if (localStory?.isViewed == true) {
        debugPrint('👁️ Story zaten görüntülenmiş: $storyId');
        return;
      }

      // Firebase'de viewer listesine ekle ve zaman damgası yaz
      await _firestore.collection('stories').doc(storyId).set({
        'viewerIds': FieldValue.arrayUnion([user.uid]),
        'viewers': {user.uid: FieldValue.serverTimestamp()},
      }, SetOptions(merge: true));

      // Yerel veritabanında güncelle
      await DriftService.markStoryAsViewed(storyId, user.uid);

      debugPrint('👁️ Story görüntülendi: $storyId');
    } catch (e) {
      debugPrint('❌ Story görüntüleme hatası: $e');
    }
  }

  // Story'e yanıt ver
  static Future<void> replyToStory(String storyId, String message) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Story sahibinin bilgilerini al
      final storyDoc =
          await _firestore.collection('stories').doc(storyId).get();
      final storyData = storyDoc.data();
      if (storyData == null) return;

      final storyOwnerId = storyData['userId'];

      // Chat ID oluştur
      final chatId = _generateChatId(user.uid, storyOwnerId);

      // Mesaj gönder
      final messageData = {
        'messageId': DateTime.now().millisecondsSinceEpoch.toString(),
        'chatId': chatId,
        'senderId': user.uid,
        'recipientId': storyOwnerId,
        // Mesaj şeması ve Cloud Function ile uyum için "text" alanı kullan
        'text': message,
        'type': 'story_reply',
        'storyId': storyId,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'sent',
        'isEdited': false,
      };

      // Chat alt koleksiyonuna ekle
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(messageData);

      // Reply listesine ekle
      await _firestore.collection('stories').doc(storyId).update({
        'repliedUserIds': FieldValue.arrayUnion([user.uid]),
      });

      debugPrint('💬 Story yanıtlandı: $storyId');
    } catch (e) {
      debugPrint('❌ Story yanıtlama hatası: $e');
    }
  }

  // Story sil
  static Future<void> deleteStory(String storyId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Firebase'de pasifleştir
      await _firestore.collection('stories').doc(storyId).set({
        'isActive': false,
      }, SetOptions(merge: true));

      // Yerel veritabanından sil
      await DriftService.deleteStory(storyId);

      debugPrint('🗑️ Story silindi: $storyId');
    } catch (e) {
      debugPrint('❌ Story silme hatası: $e');
    }
  }

  // Gizlilik ayarları: kullanıcı profiline kaydet/oku (users/{uid}/settings/storyPrivacy)
  static Future<void> savePrivacySettings({
    required String mode, // 'contacts' | 'only' | 'except'
    List<String>? allowedIds,
    List<String>? excludedIds,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('storyPrivacy')
          .set({
        'mode': mode,
        if (allowedIds != null) 'allowedIds': allowedIds,
        if (excludedIds != null) 'excludedIds': excludedIds,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('❌ Gizlilik ayarı kaydetme hatası: $e');
    }
  }

  static Future<Map<String, dynamic>> getPrivacySettings(String uid) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('storyPrivacy')
          .get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        return {
          'mode': data['mode'] ?? 'contacts',
          'allowedIds': List<String>.from(data['allowedIds'] ?? const []),
          'excludedIds': List<String>.from(data['excludedIds'] ?? const []),
        };
      }
    } catch (e) {
      debugPrint('❌ Gizlilik ayarı okuma hatası: $e');
    }
    return {
      'mode': 'contacts',
      'allowedIds': const <String>[],
      'excludedIds': const <String>[]
    };
  }

  // Görüntüleyen bilgisi (isim ve zaman)
  static Future<Map<String, dynamic>?> getViewerInfo(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final data = userDoc.data();
      if (data == null) return null;
      return {
        'name': data['name'] ?? data['displayName'] ?? 'Kullanıcı',
      };
    } catch (e) {
      debugPrint('❌ Viewer info hatası: $e');
      return null;
    }
  }

  // Süresi dolan story'leri temizle
  static Future<void> cleanExpiredStories() async {
    try {
      final expiredStories = await DriftService.getExpiredStories();

      for (var story in expiredStories) {
        await DriftService.deleteStory(story.storyId);
      }

      debugPrint('🧹 ${expiredStories.length} süresi dolan story temizlendi');
    } catch (e) {
      debugPrint('❌ Story temizleme hatası: $e');
    }
  }

  // Yardımcı fonksiyonlar
  static String _generateChatId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort();
    return '${ids[0]}_${ids[1]}';
  }

  // Rehber tabanlı story'leri al
  static Future<List<StoryModel>> getContactStories() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      // Tüm aktif story'leri al (artık StoryModel döndürüyor)
      final stories = await DriftService.getAllActiveStories();

      // Rehber kontrolü yap
      final contactStories = <StoryModel>[];

      for (var story in stories) {
        
        if (story.isFromCurrentUser) {
          contactStories.add(story);
        } else {
          // Rehberde var mı kontrol et
          final contact = await ContactsService.getContactByPhone(
            story.userPhone,
          );
          if (contact != null) {
            // Yeni bir StoryModel oluştur (immutable değil)
            final updatedStory = StoryModel();
            updatedStory.storyId = story.storyId;
            updatedStory.userId = story.userId;
            updatedStory.type = story.type;
            updatedStory.content = story.content;
            updatedStory.mediaUrl = story.mediaUrl;
            updatedStory.backgroundColor = story.backgroundColor;
            updatedStory.createdAt = story.createdAt;
            updatedStory.expiresAt = story.expiresAt;
            updatedStory.viewCount = story.viewCount;
            updatedStory.isFromCurrentUser = story.isFromCurrentUser;
            updatedStory.userName = contact.displayName;
            contactStories.add(updatedStory);
          }
        }
      }

      // Kullanıcıya göre grupla ve sırala
      final Map<String, List<StoryModel>> userStories = {};
      for (var story in contactStories) {
        final key = story.userId;
        if (!userStories.containsKey(key)) {
          userStories[key] = [];
        }
        userStories[key]!.add(story);
      }

      // Her kullanıcının story'lerini zamanına göre sırala
      final sortedStories = <StoryModel>[];
      for (var userStoriesList in userStories.values) {
        userStoriesList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        sortedStories.addAll(userStoriesList);
      }

      return sortedStories;
    } catch (e) {
      debugPrint('❌ Contact story alma hatası: $e');
      return [];
    }
  }
}
