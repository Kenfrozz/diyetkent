import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../database/drift_service.dart';
import '../models/user_model.dart';
import '../services/firebase_usage_tracker.dart';
import 'dart:async';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static Timer? _onlineTimer;

  // Kullanıcıyı çevrimiçi olarak işaretle
  static Future<void> setUserOnline() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'isOnline': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Lokal kullanıcıyı güncelle
      try {
        final localUser = await DriftService.getUserByUserId(user.uid);
        if (localUser != null) {
          localUser.isOnline = true;
          localUser.lastSeen = DateTime.now();
          await DriftService.updateUser(localUser);
        }
      } catch (localUpdateError) {
        debugPrint('⚠️ Lokal user güncelleme hatası: $localUpdateError');
      }
    } catch (e) {
      debugPrint('Online status güncelleme hatası: $e');
    }
  }

  // Kullanıcıyı çevrimdışı olarak işaretle
  static Future<void> setUserOffline() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'isOnline': false,
        'lastSeen': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Lokal kullanıcıyı güncelle
      try {
        final localUser = await DriftService.getUserByUserId(user.uid);
        if (localUser != null) {
          localUser.isOnline = false;
          localUser.lastSeen = DateTime.now();
          await DriftService.updateUser(localUser);
        }
      } catch (localUpdateError) {
        debugPrint('⚠️ Lokal user güncelleme hatası: $localUpdateError');
      }
    } catch (e) {
      debugPrint('Offline status güncelleme hatası: $e');
    }
  }

  // Online status'u periyodik olarak güncelle
  static void startOnlineStatusUpdater() {
    // Zaten çalışıyorsa durdur
    stopOnlineStatusUpdater();

    // 🔥 MALIYET OPTIMIZASYONU: 5 dakika
    _onlineTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      setUserOnline();
    });

    // İlk güncellemeyi hemen yap
    setUserOnline();
  }

  // Online status güncelleyiciyi durdur
  static void stopOnlineStatusUpdater() {
    _onlineTimer?.cancel();
    _onlineTimer = null;
    // AppLifecycle zaten offline durumunu işleyeceği için burada yazma yapma
  }

  // Kullanıcının online status'unu dinle
  static Stream<DocumentSnapshot> getUserOnlineStatus(String userId) {
    return _firestore.collection('users').doc(userId).snapshots();
  }

  // Son görülme zamanını formatla
  static String formatLastSeen(DateTime? lastSeen, bool isOnline) {
    if (isOnline) return 'çevrimiçi';
    if (lastSeen == null) return 'son görülme bilinmiyor';

    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'az önce çevrimiçiydi';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} dakika önce çevrimiçiydi';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} saat önce çevrimiçiydi';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce çevrimiçiydi';
    } else {
      return 'uzun zaman önce çevrimiçiydi';
    }
  }

  // Kullanıcının online status bilgisini al (isOnline + lastSeen)
  static Stream<Map<String, dynamic>> getUserOnlineInfo(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) {
        return {'isOnline': false, 'lastSeen': null};
      }

      final isOnline = data['isOnline'] ?? false;
      final lastSeen = data['lastSeen'] as Timestamp?;

      return {
        'isOnline': isOnline,
        'lastSeen': lastSeen?.toDate(),
        'lastSeenText': formatLastSeen(lastSeen?.toDate(), isOnline),
      };
    });
  }

  // Kullanıcının anlık online durumunu kontrol et
  static Future<bool> isUserOnline(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      await FirebaseUsageTracker.incrementRead(1);
      final data = doc.data();
      return data?['isOnline'] ?? false;
    } catch (e) {
      return false;
    }
  }

  // Typing status güncelle
  static Future<void> updateTypingStatus(String chatId, bool isTyping) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('chats').doc(chatId).update({
        'typingUsers.${user.uid}':
            isTyping ? FieldValue.serverTimestamp() : FieldValue.delete(),
      });
    } catch (e) {
      // Typing status hatası önemli değil
    }
  }

  // Chat'te yazanları dinle
  static Stream<Map<String, bool>> getTypingUsersStream(String chatId) {
    return _firestore.collection('chats').doc(chatId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null || !data.containsKey('typingUsers')) {
        return <String, bool>{};
      }

      final typingUsersRaw = data['typingUsers'];
      if (typingUsersRaw == null) return <String, bool>{};
      
      // Type casting kontrolü
      Map<String, dynamic> typingUsers;
      if (typingUsersRaw is Map<String, dynamic>) {
        typingUsers = typingUsersRaw;
      } else if (typingUsersRaw is List) {
        // List olarak geliyorsa boş map döndür
        debugPrint('⚠️ TypingUsers beklenmedik şekilde List olarak geldi');
        return <String, bool>{};
      } else {
        debugPrint('⚠️ TypingUsers beklenmedik tip: ${typingUsersRaw.runtimeType}');
        return <String, bool>{};
      }
      final result = <String, bool>{};

      final now = DateTime.now();
      for (final entry in typingUsers.entries) {
        final userId = entry.key;
        final timestampValue = entry.value;
        
        // Null check ve güvenli casting
        if (timestampValue == null) continue;
        
        final Timestamp? timestamp = timestampValue is Timestamp ? timestampValue : null;
        if (timestamp == null) continue;
        
        final timestampDate = timestamp.toDate();

        // 2 saniyeden eski typing status'ları geçersiz sayalım
        final isTyping = now.difference(timestampDate).inSeconds < 2;
        result[userId] = isTyping;
      }

      return result;
    });
  }

  // Kullanıcıyı Firestore'dan çekip Isar'a kaydet
  static Future<UserModel?> _fetchUserFromFirestoreAndSave(
      String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      await FirebaseUsageTracker.incrementRead(1);
      if (!doc.exists) return null;

      final data = doc.data() ?? <String, dynamic>{};
      final userModel = UserModel.create(
        userId: data['userId'] ?? userId,
        name: data['name'] as String?,
        phoneNumber: data['phoneNumber'] as String?,
        profileImageUrl: data['profileImageUrl'] as String?,
        about: data['about'] as String?,
        isOnline: (data['isOnline'] as bool?) ?? false,
        lastSeen: (data['lastSeen'] is Timestamp)
            ? (data['lastSeen'] as Timestamp).toDate()
            : null,
      );
      await DriftService.saveUser(userModel);
      return userModel;
    } catch (e) {
      debugPrint('Kullanıcı bilgisi çekilemedi: $e');
      return null;
    }
  }

  // Yerel kullanıcıyı getir
  static Future<UserModel?> getLocalUser(String userId) async {
    try {
      return await DriftService.getUserByUserId(userId);
    } catch (e) {
      debugPrint('Yerel kullanıcı okunamadı: $e');
      return null;
    }
  }

  // Yerel kullanıcı yoksa Firestore'dan çekip Isar'a kaydet
  static Future<bool> ensureLocalUser(String userId) async {
    final local = await getLocalUser(userId);
    if (local != null) return true;
    final fetched = await _fetchUserFromFirestoreAndSave(userId);
    return fetched != null;
  }

  // Yerel kullanıcıyı getir; yoksa Firestore'dan çekip kaydet
  static Future<UserModel?> getOrFetchLocalUser(String userId) async {
    final local = await getLocalUser(userId);
    if (local != null) return local;
    return await _fetchUserFromFirestoreAndSave(userId);
  }

  // Tüm kullanıcıları Firestore'dan çekip Isar'a yazar (limitli)
  static Future<List<UserModel>> fetchUsersAndSaveToIsar(
      {int limit = 200}) async {
    try {
      final snap = await _firestore.collection('users').limit(limit).get();
      await FirebaseUsageTracker.incrementRead(snap.docs.length);
      final users = <UserModel>[];
      for (final doc in snap.docs) {
        final data = doc.data();
        final model = UserModel.create(
          userId: data['userId'] ?? doc.id,
          name: data['name'] as String?,
          phoneNumber: data['phoneNumber'] as String?,
          profileImageUrl: data['profileImageUrl'] as String?,
          about: data['about'] as String?,
          isOnline: (data['isOnline'] as bool?) ?? false,
          lastSeen: (data['lastSeen'] is Timestamp)
              ? (data['lastSeen'] as Timestamp).toDate()
              : null,
        );
        users.add(model);
      }
      if (users.isNotEmpty) {
        await DriftService.batchSaveUsers(users);
      }
      return users;
    } catch (e) {
      debugPrint('Kullanıcı listesi çekilemedi: $e');
      return [];
    }
  }

  // Kullanıcı profilini güncelle (Firestore + Isar)
  static Future<void> updateUserProfile({
    required String name,
    required String about,
    String? profileImageUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final updateData = <String, dynamic>{
        'name': name,
        'about': about,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (profileImageUrl != null) {
        updateData['profileImageUrl'] = profileImageUrl;
      }

      await _firestore.collection('users').doc(user.uid).set(
            updateData,
            SetOptions(merge: true),
          );
      await FirebaseUsageTracker.incrementWrite(1);

      // Drift'te güncelle
      final local = await DriftService.getUserByUserId(user.uid);
      if (local != null) {
        local.name = name;
        local.about = about;
        if (profileImageUrl != null) {
          local.profileImageUrl = profileImageUrl;
        }
        local.updatedAt = DateTime.now();
        await DriftService.updateUser(local);
      } else {
        final created = UserModel.create(
          userId: user.uid,
          name: name,
          about: about,
          profileImageUrl: profileImageUrl,
          isOnline: true,
        );
        await DriftService.saveUser(created);
      }
    } catch (e) {
      debugPrint('Profil güncelleme hatası: $e');
      rethrow;
    }
  }

  // =============== ROL YÖNETİMİ ===============

  // Kullanıcının Firestore'daki rolünü getir
  static Future<UserRoleType?> getUserRole(String userId) async {
    try {
      final doc = await _firestore.collection('userRoles').doc(userId).get();
      await FirebaseUsageTracker.incrementRead(1);
      
      if (!doc.exists) {
        // Rol tanımlanmamışsa varsayılan olarak normal kullanıcı kabul et
        await setUserRole(userId, UserRoleType.user);
        return UserRoleType.user;
      }

      final data = doc.data() ?? {};
      final roleString = data['role'] as String?;
      return UserRoleType.values.firstWhere(
        (role) => role.name == roleString,
        orElse: () => UserRoleType.user,
      );
    } catch (e) {
      debugPrint('Kullanıcı rolü getirilemedi: $e');
      return UserRoleType.user;
    }
  }

  // Kullanıcının rolünü Firestore'da ayarla
  static Future<void> setUserRole(String userId, UserRoleType role) async {
    try {
      await _firestore.collection('userRoles').doc(userId).set({
        'userId': userId,
        'role': role.name,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await FirebaseUsageTracker.incrementWrite(1);

      // Yerel Drift'te da güncelle
      final localUser = await DriftService.getUserByUserId(userId);
      if (localUser != null) {
        localUser.userRole = role;
        localUser.updatedAt = DateTime.now();
        await DriftService.updateUser(localUser);
      }

      debugPrint('✅ Kullanıcı rolü güncellendi: $userId -> ${role.name}');
    } catch (e) {
      debugPrint('❌ Kullanıcı rolü güncellenemedi: $e');
      rethrow;
    }
  }

  // Mevcut kullanıcının rolünü kontrol et ve gerekirse oluştur
  static Future<void> ensureCurrentUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final role = await getUserRole(user.uid);
      debugPrint('👤 Mevcut kullanıcı rolü: ${role?.name ?? 'belirtilmemiş'}');
    } catch (e) {
      debugPrint('❌ Kullanıcı rolü kontrol edilemedi: $e');
    }
  }

  // Kullanıcının diyetisyen olup olmadığını kontrol et
  static Future<bool> isCurrentUserDietitian() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final role = await getUserRole(user.uid);
    return role == UserRoleType.dietitian || role == UserRoleType.admin;
  }

  // Kullanıcının admin olup olmadığını kontrol et
  static Future<bool> isCurrentUserAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final role = await getUserRole(user.uid);
    return role == UserRoleType.admin;
  }

  // Tüm userRoles belgelerini senkronize et (geliştirme amaçlı)
  static Future<void> syncAllUserRoles() async {
    try {
      final users = await DriftService.getAllUsers();
      for (final user in users) {
        await setUserRole(user.userId, user.userRole);
      }
      debugPrint('✅ Tüm kullanıcı rolleri senkronize edildi (${users.length} kullanıcı)');
    } catch (e) {
      debugPrint('❌ Rol senkronizasyonu başarısız: $e');
    }
  }
}
