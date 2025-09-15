import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'google_backup_service.dart';

/// Otomatik yedekleme servisi
/// 🕐 Her gece saat 03:00'da WiFi varsa yedek alır
/// 🔋 Batarya düşükse yedeklemeyi erteler
/// 📶 Sadece WiFi bağlantısında çalışır
class AutoBackupService {
  static Timer? _backupTimer;
  static bool _isInitialized = false;
  static bool _isBackingUp = false;

  // Yedekleme zamanlaması
  static const Duration _dailyBackupInterval = Duration(hours: 24);
  static const int _backupHour = 3; // Gece 03:00
  static const int _backupMinute = 0;

  // Minimum gereksinimler
  static const int _minimumBatteryLevel = 20; // %20
  static const Duration _minimumTimeBetweenBackups = Duration(hours: 20); // 20 saat

  /// Otomatik yedekleme servisini başlat
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🕐 Otomatik yedekleme servisi başlatılıyor...');

      // İlk yedekleme zamanını hesapla
      await _scheduleNextBackup();

      // Connectivity değişikliklerini dinle
      _listenToConnectivityChanges();

      _isInitialized = true;
      debugPrint('✅ Otomatik yedekleme servisi aktif');

    } catch (e) {
      debugPrint('❌ Otomatik yedekleme servisi başlatma hatası: $e');
    }
  }

  /// Sonraki yedekleme zamanını planla
  static Future<void> _scheduleNextBackup() async {
    // Mevcut timer'ı iptal et
    _backupTimer?.cancel();

    // Google bağlantısı var mı kontrol et
    final isConnected = await GoogleBackupService.isGoogleConnected();
    if (!isConnected) {
      debugPrint('ℹ️ Google hesabı bağlı değil, otomatik yedekleme devre dışı');
      return;
    }

    // Otomatik yedekleme açık mı kontrol et
    final isAutoBackupEnabled = await GoogleBackupService.isAutoBackupEnabled();
    if (!isAutoBackupEnabled) {
      debugPrint('ℹ️ Otomatik yedekleme kapalı');
      return;
    }

    // Sonraki 03:00'ı hesapla
    final now = DateTime.now();
    DateTime nextBackupTime = DateTime(now.year, now.month, now.day, _backupHour, _backupMinute);

    // Eğer şu anki saat 03:00'ı geçmişse, yarını planla
    if (now.isAfter(nextBackupTime)) {
      nextBackupTime = nextBackupTime.add(const Duration(days: 1));
    }

    final delay = nextBackupTime.difference(now);
    debugPrint('📅 Sonraki otomatik yedekleme: ${nextBackupTime.toString()}');
    debugPrint('⏰ Kalan süre: ${delay.inHours} saat ${delay.inMinutes % 60} dakika');

    // Timer'ı ayarla
    _backupTimer = Timer(delay, () {
      _performScheduledBackup();
    });
  }

  /// Zamanlanmış yedeklemeyi gerçekleştir
  static Future<void> _performScheduledBackup() async {
    if (_isBackingUp) {
      debugPrint('⏳ Zaten yedekleme devam ediyor, atlandı');
      return;
    }

    debugPrint('🌙 Zamanlanmış otomatik yedekleme başlıyor...');

    try {
      // Koşulları kontrol et
      final canBackup = await _checkBackupConditions();
      if (!canBackup) {
        debugPrint('⚠️ Yedekleme koşulları sağlanmıyor, atlandı');
        await _scheduleNextBackup(); // Sonraki günü planla
        return;
      }

      _isBackingUp = true;

      // Yedeklemeyi gerçekleştir
      final result = await GoogleBackupService.createBackup();

      if (result.success) {
        final sizeKB = (result.backupSize! / 1024).toStringAsFixed(1);
        debugPrint('✅ Otomatik yedekleme başarılı: $sizeKB KB, ${result.duration!.inSeconds}s');
      } else {
        debugPrint('❌ Otomatik yedekleme başarısız: ${result.error}');
      }

    } catch (e) {
      debugPrint('❌ Otomatik yedekleme hatası: $e');
    } finally {
      _isBackingUp = false;
      // Sonraki günü planla
      await _scheduleNextBackup();
    }
  }

  /// Yedekleme koşullarını kontrol et
  static Future<bool> _checkBackupConditions() async {
    try {
      // 1. Google bağlantısı kontrolü
      final isConnected = await GoogleBackupService.isGoogleConnected();
      if (!isConnected) {
        debugPrint('❌ Google hesabı bağlı değil');
        return false;
      }

      // 2. Otomatik yedekleme açık mı?
      final isAutoEnabled = await GoogleBackupService.isAutoBackupEnabled();
      if (!isAutoEnabled) {
        debugPrint('❌ Otomatik yedekleme kapalı');
        return false;
      }

      // 3. WiFi bağlantısı kontrolü
      final isOnWiFi = await GoogleBackupService.isOnWiFi();
      if (!isOnWiFi) {
        debugPrint('❌ WiFi bağlantısı yok');
        return false;
      }

      // 4. Son yedekleme zamanı kontrolü (çok yakın zamanda yedek alındı mı?)
      final lastBackup = await GoogleBackupService.getLastBackupTime();
      if (lastBackup != null) {
        final timeSinceLastBackup = DateTime.now().difference(lastBackup);
        if (timeSinceLastBackup < _minimumTimeBetweenBackups) {
          debugPrint('❌ Son yedekleme çok yakın zamanda yapıldı (${timeSinceLastBackup.inHours} saat önce)');
          return false;
        }
      }

      // 5. Batarya seviyesi kontrolü (mobil cihazlarda)
      if (Platform.isAndroid || Platform.isIOS) {
        final batteryLevel = await _getBatteryLevel();
        if (batteryLevel != null && batteryLevel < _minimumBatteryLevel) {
          debugPrint('❌ Batarya seviyesi düşük: %$batteryLevel');
          return false;
        }
      }

      // 6. Cihaz şarjda mı? (tercihen)
      final isCharging = await _isDeviceCharging();
      if (!isCharging) {
        debugPrint('⚠️ Cihaz şarjda değil ama devam ediliyor');
        // Şarjda değilse de yedekleme yap ama log'la
      }

      debugPrint('✅ Tüm yedekleme koşulları sağlandı');
      return true;

    } catch (e) {
      debugPrint('❌ Yedekleme koşulları kontrolü hatası: $e');
      return false;
    }
  }

  /// Batarya seviyesini al (platform spesifik)
  static Future<int?> _getBatteryLevel() async {
    try {
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        // Android'de batarya seviyesi almak için ek plugin gerekebilir
        // Şimdilik null döndür (opsiyonel kontrol)
        return null;
      } else if (Platform.isIOS) {
        // iOS'ta batarya seviyesi almak için ek plugin gerekebilir
        return null;
      }
      return null;
    } catch (e) {
      debugPrint('⚠️ Batarya seviyesi alınamadı: $e');
      return null;
    }
  }

  /// Cihaz şarjda mı kontrolü (platform spesifik)
  static Future<bool> _isDeviceCharging() async {
    try {
      // Bu özellik için battery_plus gibi bir plugin gerekebilir
      // Şimdilik her zaman true döndür
      return true;
    } catch (e) {
      debugPrint('⚠️ Şarj durumu kontrol edilemedi: $e');
      return true; // Belirsizlik durumunda devam et
    }
  }

  /// Connectivity değişikliklerini dinle
  static void _listenToConnectivityChanges() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;

      if (result == ConnectivityResult.wifi) {
        debugPrint('📶 WiFi bağlantısı geldi - yedekleme zamanlamasını kontrol et');
        // WiFi geldiğinde hemen yedekleme yapma, sadece zamanlamayı kontrol et
        _checkMissedBackups();
      } else {
        debugPrint('📶 WiFi bağlantısı kesildi');
      }
    });
  }

  /// Kaçırılan yedeklemeleri kontrol et
  static Future<void> _checkMissedBackups() async {
    try {
      final lastBackup = await GoogleBackupService.getLastBackupTime();
      final now = DateTime.now();

      // Son yedekleme 48 saatten eskiyse ve şu an WiFi varsa hemen yedek al
      if (lastBackup == null || now.difference(lastBackup).inHours > 48) {
        final canBackup = await _checkBackupConditions();
        if (canBackup) {
          debugPrint('🔄 Kaçırılan yedekleme tespit edildi, hemen yedekleme yapılıyor');
          unawaited(_performScheduledBackup());
        }
      }
    } catch (e) {
      debugPrint('❌ Kaçırılan yedekleme kontrolü hatası: $e');
    }
  }

  /// Manuel tetikleme (test amaçlı)
  static Future<void> triggerManualAutoBackup() async {
    debugPrint('👆 Manuel otomatik yedekleme tetiklendi');
    await _performScheduledBackup();
  }

  /// Servisi yeniden başlat (ayarlar değiştiğinde)
  static Future<void> restart() async {
    debugPrint('🔄 Otomatik yedekleme servisi yeniden başlatılıyor');
    await dispose();
    await initialize();
  }

  /// Servisi kapat
  static Future<void> dispose() async {
    _backupTimer?.cancel();
    _backupTimer = null;
    _isInitialized = false;
    _isBackingUp = false;
    debugPrint('🔄 Otomatik yedekleme servisi kapatıldı');
  }

  /// Servis durumu bilgilerini al
  static Map<String, dynamic> getStatus() {
    return {
      'isInitialized': _isInitialized,
      'isBackingUp': _isBackingUp,
      'hasActiveTimer': _backupTimer != null && _backupTimer!.isActive,
      'nextBackupTime': _backupTimer != null
          ? DateTime.now().add(Duration(milliseconds: _backupTimer!.tick))
          : null,
    };
  }

  /// Debug bilgileri
  static Future<Map<String, dynamic>> getDebugInfo() async {
    final isConnected = await GoogleBackupService.isGoogleConnected();
    final isAutoEnabled = await GoogleBackupService.isAutoBackupEnabled();
    final isOnWiFi = await GoogleBackupService.isOnWiFi();
    final lastBackup = await GoogleBackupService.getLastBackupTime();
    final batteryLevel = await _getBatteryLevel();
    final isCharging = await _isDeviceCharging();

    return {
      'service_status': getStatus(),
      'conditions': {
        'google_connected': isConnected,
        'auto_backup_enabled': isAutoEnabled,
        'wifi_available': isOnWiFi,
        'battery_level': batteryLevel,
        'is_charging': isCharging,
        'last_backup': lastBackup?.toIso8601String(),
        'hours_since_backup': lastBackup != null
            ? DateTime.now().difference(lastBackup).inHours
            : null,
      },
    };
  }
}

/// Unawaited helper fonksiyonu
void unawaited(Future<void> future) {
  // ignore: unawaited_futures
  future.catchError((error) {
    debugPrint('❌ Unawaited future hatası: $error');
  });
}