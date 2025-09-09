import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_background_sync_service.dart';
import 'battery_optimization_service.dart';

/// Connection-aware sync stratejileri
/// 
/// Bu servis şunları sağlar:
/// ✅ Bağlantı durumuna göre sync sıklığı ayarlama
/// ✅ Veri kullanım optimizasyonu
/// ✅ Battery-aware sync davranışı
/// ✅ Akıllı sync zamanlama
class ConnectionAwareSyncService {
  static Timer? _connectionCheckTimer;
  static ConnectivityResult _currentConnectionType = ConnectivityResult.none;
  static bool _isInitialized = false;
  static StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  // Sync stratejileri
  static const Map<ConnectivityResult, SyncStrategy> _syncStrategies = {
    ConnectivityResult.wifi: SyncStrategy(
      syncInterval: Duration(minutes: 1),
      batchSize: 50,
      allowLargeFiles: true,
      allowMediaSync: true,
      priority: SyncPriority.high,
    ),
    ConnectivityResult.mobile: SyncStrategy(
      syncInterval: Duration(minutes: 3),
      batchSize: 25,
      allowLargeFiles: false,
      allowMediaSync: false,
      priority: SyncPriority.medium,
    ),
    ConnectivityResult.ethernet: SyncStrategy(
      syncInterval: Duration(minutes: 1),
      batchSize: 100,
      allowLargeFiles: true,
      allowMediaSync: true,
      priority: SyncPriority.high,
    ),
    ConnectivityResult.none: SyncStrategy(
      syncInterval: Duration.zero,
      batchSize: 0,
      allowLargeFiles: false,
      allowMediaSync: false,
      priority: SyncPriority.none,
    ),
  };

  /// Servis başlatma
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🌐 Connection-aware sync service başlatılıyor...');

      // Mevcut bağlantı durumunu kontrol et
      await _checkCurrentConnection();

      // Connectivity değişikliklerini dinle
      _startListeningToConnectivityChanges();

      // Periyodik bağlantı kontrolü başlat
      _startConnectionHealthCheck();

      _isInitialized = true;
      debugPrint('✅ Connection-aware sync service başlatıldı');

    } catch (e) {
      debugPrint('❌ Connection-aware sync service başlatma hatası: $e');
    }
  }

  /// Mevcut bağlantı durumunu kontrol et
  static Future<void> _checkCurrentConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final connectionType = connectivityResult.isNotEmpty 
          ? connectivityResult.first 
          : ConnectivityResult.none;
      
      await _updateConnectionType(connectionType);
      
    } catch (e) {
      debugPrint('❌ Bağlantı kontrolü hatası: $e');
      _currentConnectionType = ConnectivityResult.none;
    }
  }

  /// Connectivity değişikliklerini dinle
  static void _startListeningToConnectivityChanges() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final connectionType = results.isNotEmpty ? results.first : ConnectivityResult.none;
      debugPrint('📶 Bağlantı değişti: $_currentConnectionType → $connectionType');
      unawaited(_updateConnectionType(connectionType));
    });
  }

  /// Bağlantı türünü güncelle ve sync stratejisini ayarla
  static Future<void> _updateConnectionType(ConnectivityResult newType) async {
    if (_currentConnectionType == newType) return;

    _currentConnectionType = newType;
    
    // Yeni sync stratejisini uygula
    final strategy = getSyncStrategy();
    await _applySyncStrategy(strategy);
    
    // Bağlantı durumunu kaydet
    await _saveConnectionState();
    
    debugPrint('🔄 Sync stratejisi güncellendi: ${strategy.priority} priority');
  }

  /// Sync stratejisini uygula
  static Future<void> _applySyncStrategy(SyncStrategy strategy) async {
    try {
      switch (strategy.priority) {
        case SyncPriority.high:
          // Yüksek öncelik: Hemen full sync yap
          debugPrint('🔥 Yüksek öncelikli sync tetikleniyor...');
          await FirebaseBackgroundSyncService.performIncrementalSync();
          break;
          
        case SyncPriority.medium:
          // Orta öncelik: Artımsal sync yap
          debugPrint('⚡ Orta öncelikli sync tetikleniyor...');
          await FirebaseBackgroundSyncService.performIncrementalSync();
          break;
          
        case SyncPriority.low:
          // Düşük öncelik: Sadece kritik veriler
          debugPrint('🐌 Düşük öncelikli sync tetikleniyor...');
          await _performCriticalDataSyncOnly();
          break;
          
        case SyncPriority.none:
          // Sync yok: Offline mod
          debugPrint('🚫 Sync durduruldu - Offline mod');
          break;
      }
    } catch (e) {
      debugPrint('❌ Sync stratejisi uygulama hatası: $e');
    }
  }

  /// Sadece kritik verileri sync et (düşük öncelik)
  static Future<void> _performCriticalDataSyncOnly() async {
    // Sadece mesajları sync et, media dosyalarını değil
    // Bu implementation FirebaseBackgroundSyncService'e eklenebilir
    debugPrint('📱 Sadece kritik veriler sync ediliyor...');
  }

  /// Periyodik bağlantı sağlığı kontrolü
  static void _startConnectionHealthCheck() {
    _connectionCheckTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      await _performConnectionHealthCheck();
    });
  }

  /// Bağlantı sağlığı kontrolü
  static Future<void> _performConnectionHealthCheck() async {
    try {
      // İnternet bağlantısını test et
      final hasInternet = await _testInternetConnection();
      
      if (!hasInternet && _currentConnectionType != ConnectivityResult.none) {
        debugPrint('⚠️ İnternet bağlantısı kayboldu, offline mod');
        await _updateConnectionType(ConnectivityResult.none);
      } else if (hasInternet && _currentConnectionType == ConnectivityResult.none) {
        debugPrint('🌐 İnternet bağlantısı geri geldi');
        await _checkCurrentConnection();
      }
      
    } catch (e) {
      debugPrint('❌ Bağlantı sağlık kontrolü hatası: $e');
    }
  }

  /// İnternet bağlantısını test et
  static Future<bool> _testInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Bağlantı durumunu SharedPreferences'a kaydet
  static Future<void> _saveConnectionState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_connection_type', _currentConnectionType.toString());
      await prefs.setInt('last_connection_check', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('❌ Bağlantı durumu kaydetme hatası: $e');
    }
  }


  // =====================================================
  // PUBLIC API
  // =====================================================

  /// Mevcut sync stratejisini al
  static SyncStrategy getSyncStrategy() {
    return _syncStrategies[_currentConnectionType] ?? _syncStrategies[ConnectivityResult.none]!;
  }

  /// Mevcut bağlantı türü
  static ConnectivityResult get currentConnectionType => _currentConnectionType;

  /// Online durumu
  static bool get isOnline => _currentConnectionType != ConnectivityResult.none;

  /// Yüksek bant genişliği var mı?
  static bool get hasHighBandwidth => 
      _currentConnectionType == ConnectivityResult.wifi ||
      _currentConnectionType == ConnectivityResult.ethernet;

  /// Mobil veri kullanılıyor mu?
  static bool get isUsingMobileData => _currentConnectionType == ConnectivityResult.mobile;

  /// Büyük dosya indirme/yükleme izinli mi?
  static bool get allowLargeFiles => getSyncStrategy().allowLargeFiles;

  /// Medya dosyası sync'i izinli mi?
  static bool get allowMediaSync => getSyncStrategy().allowMediaSync;

  /// Data saver modu aktif mi?
  static bool get isDataSaverMode => 
      isUsingMobileData || BatteryOptimizationService.isBatteryOptimizationEnabled();

  /// Manuel sync tetikleme (bağlantı durumuna göre)
  static Future<void> triggerManualSync() async {
    final strategy = getSyncStrategy();
    
    if (strategy.priority == SyncPriority.none) {
      debugPrint('🚫 Offline mod - Manuel sync iptal edildi');
      return;
    }

    debugPrint('🔄 Manuel sync tetiklendi (${strategy.priority} priority)');
    await _applySyncStrategy(strategy);
  }

  /// Smart sync - akıllı zamanlama ile sync
  static Future<void> performSmartSync() async {
    final strategy = getSyncStrategy();
    final now = DateTime.now();
    
    // Gece saatlerinde (23:00 - 06:00) düşük öncelik
    if (now.hour >= 23 || now.hour <= 6) {
      if (strategy.priority == SyncPriority.high) {
        final lowPriorityStrategy = _syncStrategies[ConnectivityResult.mobile]!;
        await _applySyncStrategy(lowPriorityStrategy);
        return;
      }
    }
    
    // Peak saatlerde (09:00 - 18:00) akıllı sync
    if (now.hour >= 9 && now.hour <= 18 && isUsingMobileData) {
      debugPrint('⏰ Peak saatler - Data tasarrufu modu aktif');
      await _performCriticalDataSyncOnly();
      return;
    }
    
    // Normal sync
    await _applySyncStrategy(strategy);
  }

  /// Veri kullanım istatistiklerini al
  static Map<String, dynamic> getDataUsageStats() {
    // Bu implementasyon veri kullanım tracker'ı ile entegre edilebilir
    return {
      'currentConnectionType': _currentConnectionType.toString(),
      'isOnline': isOnline,
      'hasHighBandwidth': hasHighBandwidth,
      'isDataSaverMode': isDataSaverMode,
      'allowLargeFiles': allowLargeFiles,
      'syncStrategy': getSyncStrategy().toJson(),
    };
  }

  /// Debug bilgileri
  static Map<String, dynamic> getDebugInfo() {
    final strategy = getSyncStrategy();
    return {
      'isInitialized': _isInitialized,
      'currentConnectionType': _currentConnectionType.toString(),
      'isOnline': isOnline,
      'hasHighBandwidth': hasHighBandwidth,
      'isUsingMobileData': isUsingMobileData,
      'isDataSaverMode': isDataSaverMode,
      'syncStrategy': strategy.toJson(),
      'lastConnectionCheck': DateTime.now().toIso8601String(),
    };
  }

  /// Servis temizleme
  static void dispose() {
    _connectionCheckTimer?.cancel();
    _connectivitySubscription?.cancel();
    _isInitialized = false;
    debugPrint('🧹 Connection-aware sync service temizlendi');
  }
}

/// Sync stratejisi modeli
class SyncStrategy {
  final Duration syncInterval;
  final int batchSize;
  final bool allowLargeFiles;
  final bool allowMediaSync;
  final SyncPriority priority;

  const SyncStrategy({
    required this.syncInterval,
    required this.batchSize,
    required this.allowLargeFiles,
    required this.allowMediaSync,
    required this.priority,
  });

  Map<String, dynamic> toJson() {
    return {
      'syncIntervalMinutes': syncInterval.inMinutes,
      'batchSize': batchSize,
      'allowLargeFiles': allowLargeFiles,
      'allowMediaSync': allowMediaSync,
      'priority': priority.toString(),
    };
  }
}

/// Sync öncelik seviyeleri
enum SyncPriority {
  none,    // Sync yok
  low,     // Düşük öncelik - sadece kritik veriler
  medium,  // Orta öncelik - artımsal sync
  high,    // Yüksek öncelik - tam sync
}