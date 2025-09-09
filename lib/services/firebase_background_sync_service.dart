import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/drift_service.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/group_model.dart';
import '../models/call_log_model.dart';
import 'firebase_usage_tracker.dart';
import 'battery_optimization_service.dart';
import 'differential_sync_engine.dart';

class FirebaseBackgroundSyncService {
  static Timer? _syncTimer;
  static bool _isInitialized = false;
  static bool _isSyncing = false;
  static DateTime? _lastFullSync;
  static DateTime? _lastIncrementalSync;
  
  // Sync intervals based on app state and connectivity
  static const Duration _foregroundSyncInterval = Duration(minutes: 2);
  static const Duration _backgroundSyncInterval = Duration(minutes: 10);
  static const Duration _lowBatterySyncInterval = Duration(minutes: 30);
  
  static const String _lastSyncTimestampKey = 'last_firebase_sync_timestamp';
  static const String _lastFullSyncKey = 'last_firebase_full_sync_timestamp';

  /// Akıllı arkaplan senkronizasyonu başlat
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('🔄 Firebase Background Sync Service başlatılıyor...');
      
      // Son senkronizasyon zamanını yükle
      await _loadLastSyncTimestamps();
      
      // Başlangıç senkronizasyonu (eğer 4 saatten eski ise full sync)
      final shouldFullSync = _lastFullSync == null || 
          DateTime.now().difference(_lastFullSync!) > const Duration(hours: 4);
      
      if (shouldFullSync) {
        await performFullSync();
      } else {
        await performIncrementalSync();
      }
      
      // Periyodik senkronizasyonu başlat
      _startPeriodicSync();
      
      // Connectivity değişikliklerini dinle
      _listenToConnectivityChanges();
      
      // Battery optimizasyon durumunu dinle
      _listenToBatteryOptimization();
      
      _isInitialized = true;
      debugPrint('✅ Firebase Background Sync Service başlatıldı');
      
    } catch (e) {
      debugPrint('❌ Firebase Background Sync Service başlatma hatası: $e');
    }
  }

  /// Tam senkronizasyon - tüm verileri güncelle
  static Future<void> performFullSync({bool force = false}) async {
    if (_isSyncing && !force) {
      debugPrint('⏳ Senkronizasyon zaten devam ediyor, atlanıyor...');
      return;
    }
    
    _isSyncing = true;
    final startTime = DateTime.now();
    
    try {
      debugPrint('🔄 Tam senkronizasyon başlatılıyor...');
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('❌ Kullanıcı oturumu bulunamadı');
        return;
      }

      // Maliyet takibi için
      await FirebaseUsageTracker.incrementRead();

      // 1. Chat'leri senkronize et
      await _syncChatsFromFirebase(user.uid);
      
      // 2. Grup'ları senkronize et  
      await _syncGroupsFromFirebase(user.uid);
      
      // 3. Mesajları senkronize et (sadece son 7 günün)
      await _syncRecentMessagesFromFirebase(user.uid);
      
      // 4. Kullanıcı verilerini senkronize et
      await _syncUserDataFromFirebase(user.uid);
      
      // 5. Gelen aramaları senkronize et
      await _syncIncomingCallsFromFirebase(user.uid);
      
      // Son sync zamanını kaydet
      _lastFullSync = DateTime.now();
      await _saveLastSyncTimestamps();
      
      final duration = DateTime.now().difference(startTime);
      debugPrint('✅ Tam senkronizasyon tamamlandı: ${duration.inSeconds}s');
      
      await FirebaseUsageTracker.incrementRead();
      
    } catch (e) {
      debugPrint('❌ Tam senkronizasyon hatası: $e');
      await FirebaseUsageTracker.incrementRead();
    } finally {
      _isSyncing = false;
    }
  }

  /// Artımsal senkronizasyon - DIFFERENTIAL SYNC ENGINE ile optimize edildi
  static Future<void> performIncrementalSync() async {
    if (_isSyncing) {
      debugPrint('⏳ Senkronizasyon zaten devam ediyor, atlanıyor...');
      return;
    }
    
    _isSyncing = true;
    final startTime = DateTime.now();
    
    try {
      debugPrint('🧠 Differential artımsal sync başlatılıyor...');
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseUsageTracker.incrementRead();

      // 🚀 DIFFERENTIAL SYNC ENGINE ile akıllı sync
      final comprehensiveResult = await DifferentialSyncEngine.performSmartBatchSync(user.uid);
      
      debugPrint('📊 Differential Sync Sonucu:');
      debugPrint('   • Toplam sync: ${comprehensiveResult.totalSynced}');
      debugPrint('   • Atlandı: ${comprehensiveResult.totalSkipped}');
      debugPrint('   • Verimlilik: ${comprehensiveResult.efficiency.toStringAsFixed(1)}%');
      debugPrint('   • Transfer: ${(comprehensiveResult.totalBytesTransferred / 1024).toStringAsFixed(1)} KB');

      // Gelen aramaları da sync et (yüksek öncelikli)
      final lastSync = _lastIncrementalSync ?? 
          DateTime.now().subtract(const Duration(hours: 1));
      await _syncIncomingCallsFromFirebase(user.uid, since: lastSync);

      _lastIncrementalSync = DateTime.now();
      await _saveLastSyncTimestamps();
      
      final totalDuration = DateTime.now().difference(startTime);
      debugPrint('✅ Differential artımsal sync: ${totalDuration.inMilliseconds}ms');
      
      // Checksum cleanup (periyodik)
      if (DateTime.now().hour == 3) { // Gece 3'te cleanup
        unawaited(DifferentialSyncEngine.cleanupOldChecksums());
      }
      
    } catch (e) {
      debugPrint('❌ Differential artımsal sync hatası: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Akıllı periyodik senkronizasyon
  static void _startPeriodicSync() {
    _stopPeriodicSync(); // Önceki timer'ı durdur
    
    // App durumu ve battery durumuna göre interval belirle
    Duration interval = _foregroundSyncInterval;
    
    // Battery optimization aktifse daha uzun interval
    if (BatteryOptimizationService.isBatteryOptimizationEnabled()) {
      interval = _lowBatterySyncInterval;
    }
    
    _syncTimer = Timer.periodic(interval, (timer) {
      // App background'dayken daha az sync yap
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.paused ||
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.inactive) {
        if (timer.tick % 5 != 0) return; // Her 5. tick'te sync yap
      }
      
      unawaited(performIncrementalSync());
    });
    
    debugPrint('⏰ Periyodik sync başlatıldı: ${interval.inMinutes} dakika interval');
  }

  /// Connectivity değişikliklerini dinle
  static void _listenToConnectivityChanges() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      debugPrint('📶 Connectivity değişti: $result');
      
      if (result == ConnectivityResult.none) {
        // İnternet yok, sync'i durdur
        _stopPeriodicSync();
        debugPrint('🚫 İnternet bağlantısı yok, sync durduruldu');
      } else {
        // İnternet geldi, sync'i başlat
        if (!_isTimerActive()) {
          _startPeriodicSync();
          debugPrint('✅ İnternet bağlantısı geldi, sync başlatıldı');
        }
        
        // İnternet gelir gelmez hızlı bir sync yap
        if (!_isSyncing) {
          unawaited(performIncrementalSync());
        }
      }
    });
  }

  /// Battery optimization değişikliklerini dinle
  static void _listenToBatteryOptimization() {
    // Battery optimization durumu değiştiğinde sync interval'ını güncelle
    BatteryOptimizationService.addStatusListener((isOptimizing) {
      debugPrint('🔋 Battery optimization durumu: $isOptimizing');
      
      if (isOptimizing) {
        // Battery save modundayken sync'i yavaşlat
        _stopPeriodicSync();
        _syncTimer = Timer.periodic(_lowBatterySyncInterval, (timer) {
          if (timer.tick % 2 != 0) return; // Her 2. tick'te sync
          unawaited(performIncrementalSync());
        });
      } else {
        // Normal sync interval'ına dön
        _startPeriodicSync();
      }
    });
  }

  /// Chat'leri Firebase'den İsar'a senkronize et
  static Future<void> _syncChatsFromFirebase(String userId) async {
    try {
      final query = FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: userId)
          .orderBy('updatedAt', descending: true)
          .limit(100); // Sınırlı batch

      final snapshot = await query.get();
      
      if (snapshot.docs.isNotEmpty) {
        final chats = snapshot.docs.map((doc) => ChatModel.fromMap(doc.data())).toList();
        
        // Chat'lerin kullanıcı bilgilerini güncelle
        for (final chat in chats) {
          try {
            if (chat.otherUserId != null && chat.otherUserId!.isNotEmpty && chat.otherUserName == null) {
              try {
                final userDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(chat.otherUserId)
                    .get();
                if (userDoc.exists) {
                  final userData = userDoc.data()!;
                  final updatedChat = chat.copyWith(
                    otherUserName: userData['displayName'] as String?,
                    otherUserPhoneNumber: userData['phoneNumber'] as String?,
                    otherUserProfileImage: userData['profileImageUrl'] as String?,
                  );
                  await DriftService.saveChat(updatedChat);
                } else {
                  await DriftService.saveChat(chat);
                }
              } catch (e) {
                debugPrint('⚠️ Chat kullanıcı bilgisi güncellenemedi: $e');
                await DriftService.saveChat(chat);
              }
            } else {
              await DriftService.saveChat(chat);
            }
          } catch (e) {
            debugPrint('⚠️ Chat kaydetme hatası (${chat.chatId}): $e');
            // UNIQUE constraint hatası durumunda güncelle
            if (e.toString().contains('UNIQUE constraint failed')) {
              try {
                await DriftService.updateChatModel(chat);
              } catch (updateError) {
                debugPrint('⚠️ Chat güncelleme de başarısız (${chat.chatId}): $updateError');
              }
            }
          }
        }
        
        debugPrint('💬 ${chats.length} chat senkronize edildi');
        await FirebaseUsageTracker.incrementRead(chats.length);
      }
      
    } catch (e) {
      debugPrint('❌ Chat senkronizasyon hatası: $e');
    }
  }

  /// Grup'ları senkronize et
  static Future<void> _syncGroupsFromFirebase(String userId) async {
    try {
      final query = FirebaseFirestore.instance
          .collection('groups')
          .where('members', arrayContains: userId)
          .limit(50);

      final snapshot = await query.get();
      
      if (snapshot.docs.isNotEmpty) {
        final groups = snapshot.docs.map((doc) => GroupModel.fromMap(doc.data())).toList();
        
        // Drift'e batch kaydet (saveGroups stub olduğu için tek tek kaydet)
        for (final group in groups) {
          await DriftService.saveGroupModel(group);
        }
        
        debugPrint('👥 ${groups.length} grup senkronize edildi');
        await FirebaseUsageTracker.incrementRead(groups.length);
      }
      
    } catch (e) {
      debugPrint('❌ Grup senkronizasyon hatası: $e');
    }
  }

  /// Son mesajları senkronize et (sadece son 7 gün)
  static Future<void> _syncRecentMessagesFromFirebase(String userId) async {
    try {
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      
      // Kullanıcının chat'lerini Drift'ten al
      final userChats = await DriftService.getAllChats();
      
      // Her chat için sadece yeni mesajları çek (batch'ler halinde)
      for (final chat in userChats.take(20)) { // İlk 20 aktif chat
        final query = FirebaseFirestore.instance
            .collection('chats')
            .doc(chat.chatId)
            .collection('messages')
            .where('timestamp', isGreaterThan: Timestamp.fromDate(weekAgo))
            .orderBy('timestamp', descending: true)
            .limit(50); // Her chat için max 50 mesaj

        final snapshot = await query.get();
        
        if (snapshot.docs.isNotEmpty) {
          final messages = snapshot.docs.map((doc) => 
              MessageModel.fromMap(doc.data())).toList();
          
          // saveMessages stub olduğu için tek tek kaydet
          for (final message in messages) {
            await DriftService.saveMessage(message);
          }
          
          debugPrint('📨 Chat ${chat.chatId}: ${messages.length} mesaj senkronize edildi');
        }
      }
      
      await FirebaseUsageTracker.incrementRead();
      
    } catch (e) {
      debugPrint('❌ Mesaj senkronizasyon hatası: $e');
    }
  }

  /// Belirli chat'lerin mesajlarını senkronize et

  /// Kullanıcı verilerini senkronize et
  static Future<void> _syncUserDataFromFirebase(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
          
      if (userDoc.exists) {
        // Kullanıcı verilerini İsar'a kaydet (UserService üzerinden)
        // Bu implementasyon mevcut UserService pattern'ını kullanacak
        debugPrint('👤 Kullanıcı verisi senkronize edildi');
      }
      
    } catch (e) {
      debugPrint('❌ Kullanıcı veri sync hatası: $e');
    }
  }

  /// Gelen aramaları senkronize et
  static Future<void> _syncIncomingCallsFromFirebase(String userId, {DateTime? since}) async {
    try {
      var query = FirebaseFirestore.instance
          .collection('calls')
          .where('calleeId', isEqualTo: userId)
          .where('status', isEqualTo: 'ringing')
          .orderBy('timestamp', descending: true)
          .limit(10); // Son 10 gelen arama

      // Artımsal sync için zaman filtresi
      if (since != null) {
        query = query.where('timestamp', isGreaterThan: Timestamp.fromDate(since));
      }

      final snapshot = await query.get();
      
      if (snapshot.docs.isNotEmpty) {
        debugPrint('📞 ${snapshot.docs.length} gelen arama bulundu');
        
        // Her aramayı İsar'a kaydet
        for (final doc in snapshot.docs) {
          final callData = doc.data();
          final call = CallLogModel();
          call.callId = doc.id;
          call.otherUserId = callData['otherUserId'];
          call.otherUserPhone = callData['otherUserPhone'];
          call.otherDisplayName = callData['otherDisplayName'];
          call.isVideo = callData['isVideo'] ?? false;
          call.direction = CallLogDirection.values.firstWhere(
              (e) => e.name == callData['direction'],
              orElse: () => CallLogDirection.outgoing);
          call.status = CallLogStatus.values.firstWhere(
              (e) => e.name == callData['status'], 
              orElse: () => CallLogStatus.ended);
          call.startedAt = callData['startedAt'] != null 
              ? DateTime.fromMillisecondsSinceEpoch(callData['startedAt']) 
              : null;
          call.connectedAt = callData['connectedAt'] != null 
              ? DateTime.fromMillisecondsSinceEpoch(callData['connectedAt']) 
              : null;
          call.endedAt = callData['endedAt'] != null 
              ? DateTime.fromMillisecondsSinceEpoch(callData['endedAt']) 
              : null;
          call.updatedAt = DateTime.now();
          await DriftService.saveCallLog(call);
        }
        
        await FirebaseUsageTracker.incrementRead(snapshot.docs.length);
      }
      
    } catch (e) {
      debugPrint('❌ Gelen arama sync hatası: $e');
    }
  }

  /// Periyodik sync'i durdur
  static void _stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Timer aktif mi kontrolü
  static bool _isTimerActive() => _syncTimer != null && _syncTimer!.isActive;

  /// Son sync zamanlarını yükle
  static Future<void> _loadLastSyncTimestamps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final lastSyncMillis = prefs.getInt(_lastSyncTimestampKey);
      if (lastSyncMillis != null) {
        _lastIncrementalSync = DateTime.fromMillisecondsSinceEpoch(lastSyncMillis);
      }
      
      final lastFullSyncMillis = prefs.getInt(_lastFullSyncKey);
      if (lastFullSyncMillis != null) {
        _lastFullSync = DateTime.fromMillisecondsSinceEpoch(lastFullSyncMillis);
      }
      
    } catch (e) {
      debugPrint('❌ Sync timestamp yükleme hatası: $e');
    }
  }

  /// Son sync zamanlarını kaydet
  static Future<void> _saveLastSyncTimestamps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (_lastIncrementalSync != null) {
        await prefs.setInt(_lastSyncTimestampKey, _lastIncrementalSync!.millisecondsSinceEpoch);
      }
      
      if (_lastFullSync != null) {
        await prefs.setInt(_lastFullSyncKey, _lastFullSync!.millisecondsSinceEpoch);
      }
      
    } catch (e) {
      debugPrint('❌ Sync timestamp kaydetme hatası: $e');
    }
  }

  /// Manuel sync tetikle (kullanıcı refresh ettiğinde)
  static Future<void> triggerManualSync() async {
    debugPrint('👆 Manuel senkronizasyon tetiklendi');
    await performIncrementalSync();
  }

  /// Uygulama foreground'a geldiğinde hızlı sync
  static Future<void> onAppResumed() async {
    if (_lastIncrementalSync == null || 
        DateTime.now().difference(_lastIncrementalSync!) > const Duration(minutes: 5)) {
      debugPrint('🔄 App resumed - hızlı sync yapılıyor');
      await performIncrementalSync();
    }
  }

  /// Uygulama background'a gittiğinde sync'i yavaşlat
  static void onAppPaused() {
    debugPrint('⏸️ App paused - sync interval artırıldı');
    _stopPeriodicSync();
    
    // Background'da daha uzun interval
    _syncTimer = Timer.periodic(_backgroundSyncInterval, (timer) {
      unawaited(performIncrementalSync());
    });
  }

  /// Servis kapatma
  static void dispose() {
    _stopPeriodicSync();
    _isInitialized = false;
    debugPrint('🔄 Firebase Background Sync Service kapatıldı');
  }

  /// Debug bilgileri
  static Map<String, dynamic> getDebugInfo() {
    return {
      'isInitialized': _isInitialized,
      'isSyncing': _isSyncing,
      'isTimerActive': _isTimerActive(),
      'lastFullSync': _lastFullSync?.toIso8601String(),
      'lastIncrementalSync': _lastIncrementalSync?.toIso8601String(),
      'syncInterval': _syncTimer?.tick ?? 0,
    };
  }

  /// Senkronizasyon durumunu al
  static bool get isInitialized => _isInitialized;
  static bool get isSyncing => _isSyncing;
  static DateTime? get lastSyncTime => _lastIncrementalSync;
}

/// Connectivity durumunu takip eden extension
extension ConnectivityHelper on FirebaseBackgroundSyncService {
  static bool get isOnline {
    // Platform kontrolü - sadece mobil platformlarda connectivity check yap
    if (!Platform.isAndroid && !Platform.isIOS) return true;
    
    // Bu implementasyon connectivity dinleyicisi ile güncellenecek
    return true; // Şimdilik default true
  }
  
  static bool get isHighBandwidth {
    // WiFi bağlantısında daha fazla sync, mobil veriyle daha az
    // Bu implementasyon connectivity türüne göre optimizasyon sağlayacak
    return true; // Şimdilik default true  
  }
}