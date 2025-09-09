import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

// Doze mode ve App Standby durumları
enum PowerSaveMode {
  none,           // Herhangi bir güç tasarrufu modu yok
  doze,           // Android Doze modu
  appStandby,     // App Standby modu
  batteryOptimized, // Pil optimizasyonu etkin
  restrictedBackground, // Arka plan kısıtlandı
  unknown         // Durum bilinmiyor
}

// Bildirim güvenilirlik seviyesi
enum NotificationReliability {
  high,     // %90+ güvenilir teslimat
  medium,   // %60-90 güvenilir teslimat  
  low,      // %30-60 güvenilir teslimat
  unreliable // %30'dan az güvenilir teslimat
}

class BatteryOptimizationService {
  static const MethodChannel _channel = MethodChannel('diyetkent/battery_optimization');
  
  // Bilinen pil optimizasyonu sorunları olan markalar
  static const List<String> _problematicBrands = [
    'xiaomi', 'miui', 'redmi',
    'oppo', 'oneplus', 'realme',
    'vivo', 'funtouch',
    'huawei', 'honor', 'emui',
    'samsung', 'oneui',
    'asus', 'zenui',
    'meizu', 'flyme'
  ];

  static AndroidDeviceInfo? _deviceInfo;
  static bool _isInitialized = false;

  // Servisi başlat
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('🔋 Battery Optimization servisi başlatılıyor...');
      
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        _deviceInfo = await deviceInfo.androidInfo;
        debugPrint('📱 Cihaz: ${_deviceInfo?.brand} ${_deviceInfo?.model} - Android ${_deviceInfo?.version.release}');
      }
      
      _isInitialized = true;
      debugPrint('✅ Battery Optimization servisi başlatıldı');
    } catch (e) {
      debugPrint('❌ Battery Optimization servisi başlatma hatası: $e');
    }
  }

  // Cihazın pil optimizasyonu durumunu kontrol et
  static Future<Map<String, dynamic>> checkBatteryOptimizationStatus() async {
    final result = <String, dynamic>{
      'isOptimized': true,
      'hasIgnorePermission': false,
      'powerSaveMode': PowerSaveMode.unknown.name,
      'reliability': NotificationReliability.unreliable.name,
      'brand': 'unknown',
      'recommendations': <String>[],
      'canRequest': false,
    };

    try {
      if (!Platform.isAndroid) {
        // iOS için pil optimizasyonu sorunu yok
        result['isOptimized'] = false;
        result['reliability'] = NotificationReliability.high.name;
        result['powerSaveMode'] = PowerSaveMode.none.name;
        return result;
      }

      await initialize();
      
      // Cihaz markası kontrolü
      final brand = _deviceInfo?.brand.toLowerCase() ?? 'unknown';
      result['brand'] = brand;
      
      // Ignore battery optimizations izni kontrolü
      final ignoreOptimizationsStatus = await Permission.ignoreBatteryOptimizations.status;
      result['hasIgnorePermission'] = ignoreOptimizationsStatus.isGranted;
      result['canRequest'] = !ignoreOptimizationsStatus.isPermanentlyDenied;

      // Notification izni kontrolü
      final notificationStatus = await Permission.notification.status;
      
      // Native method ile detaylı durum kontrolü
      try {
        final nativeStatus = await _channel.invokeMethod<Map>('getBatteryOptimizationStatus') ?? {};
        
        result['isOptimized'] = nativeStatus['isOptimized'] ?? true;
        result['powerSaveMode'] = _getPowerSaveMode(nativeStatus).name;
        result['isDozing'] = nativeStatus['isDozing'] ?? false;
        result['isAppStandby'] = nativeStatus['isAppStandby'] ?? false;
      } catch (e) {
        debugPrint('⚠️ Native battery status kontrolü başarısız: $e');
        // Fallback: izin durumuna göre tahmin et
        result['isOptimized'] = !ignoreOptimizationsStatus.isGranted;
      }

      // Güvenilirlik seviyesini hesapla
      result['reliability'] = _calculateReliability(
        isOptimized: result['isOptimized'],
        hasIgnorePermission: result['hasIgnorePermission'],
        hasNotificationPermission: notificationStatus.isGranted,
        brand: brand,
        androidVersion: _deviceInfo?.version.sdkInt ?? 0,
      ).name;

      // Öneriler oluştur
      result['recommendations'] = _generateRecommendations(result);

      debugPrint('🔋 Battery optimization durumu: $result');
      return result;
      
    } catch (e) {
      debugPrint('❌ Battery optimization durum kontrolü hatası: $e');
      return result;
    }
  }

  // Power save mode'u belirle
  static PowerSaveMode _getPowerSaveMode(Map nativeStatus) {
    if (nativeStatus['isDozing'] == true) return PowerSaveMode.doze;
    if (nativeStatus['isAppStandby'] == true) return PowerSaveMode.appStandby;
    if (nativeStatus['isOptimized'] == true) return PowerSaveMode.batteryOptimized;
    if (nativeStatus['backgroundRestricted'] == true) return PowerSaveMode.restrictedBackground;
    return PowerSaveMode.none;
  }

  // Notification güvenilirlik seviyesini hesapla
  static NotificationReliability _calculateReliability({
    required bool isOptimized,
    required bool hasIgnorePermission,
    required bool hasNotificationPermission,
    required String brand,
    required int androidVersion,
  }) {
    if (!hasNotificationPermission) {
      return NotificationReliability.unreliable;
    }

    // Android 6.0+ için Doze mode etkisi
    if (androidVersion >= 23) {
      if (hasIgnorePermission) {
        // Problematik markalarda bile yüksek güvenilirlik
        if (_problematicBrands.contains(brand)) {
          return NotificationReliability.medium;
        }
        return NotificationReliability.high;
      }
      
      if (isOptimized) {
        if (_problematicBrands.contains(brand)) {
          return NotificationReliability.unreliable;
        }
        return NotificationReliability.low;
      }
    }

    // Eski Android sürümleri daha güvenilir
    if (androidVersion < 23) {
      return NotificationReliability.high;
    }

    return NotificationReliability.medium;
  }

  // Önerileri oluştur
  static List<String> _generateRecommendations(Map<String, dynamic> status) {
    final recommendations = <String>[];
    
    final brand = status['brand'] as String;
    final isOptimized = status['isOptimized'] as bool;
    final hasIgnorePermission = status['hasIgnorePermission'] as bool;
    final reliability = status['reliability'] as String;

    if (!hasIgnorePermission && isOptimized) {
      recommendations.add('Pil optimizasyonunu devre dışı bırakın');
    }

    if (_problematicBrands.contains(brand)) {
      recommendations.addAll(_getBrandSpecificRecommendations(brand));
    }

    if (reliability == NotificationReliability.low.name || 
        reliability == NotificationReliability.unreliable.name) {
      recommendations.add('Uygulamayı otomatik başlatma listesine ekleyin');
      recommendations.add('Bildirimler için yüksek öncelik ayarlayın');
    }

    return recommendations;
  }

  // Marka-spesifik öneriler
  static List<String> _getBrandSpecificRecommendations(String brand) {
    switch (brand) {
      case 'xiaomi':
      case 'miui':
      case 'redmi':
        return [
          'MIUI\'de Güvenlik > Uygulamalar > İzinler > Otomatik başlatma\'dan uygulamayı etkinleştirin',
          'MIUI\'de Güvenlik > Uygulamalar > İzinler > Pil tasarrufu\'ndan "Sınırlama yok" seçin',
          'Geliştirici seçeneklerinde MIUI optimizasyonunu kapatın'
        ];
      case 'oppo':
      case 'oneplus':
      case 'realme':
        return [
          'Ayarlar > Pil > Uygulamalar\'dan uygulamayı "Optimize etme" listesinden çıkarın',
          'Ayarlar > Uygulamalar > Özel > Otomatik başlatma yönetimi\'nden etkinleştirin',
          'ColorOS/OxygenOS\'te arka plan uygulama limiti ayarlarını kontrol edin'
        ];
      case 'vivo':
      case 'funtouch':
        return [
          'Ayarlar > Pil > Arka plan uygulama yenileme > Uygulamayı "İzin ver" konumuna getirin',
          'Ayarlar > Daha fazla ayar > Uygulamalar > Otomatik başlat > Etkinleştir',
          'FuntouchOS\'te Yüksek performans modunu etkinleştirin'
        ];
      case 'huawei':
      case 'honor':
      case 'emui':
        return [
          'Ayarlar > Uygulamalar > Uygulama başlatma > El ile yönet > Etkinleştir',
          'Ayarlar > Pil > Uygulamalar\'dan "Optimize etme"',
          'EMUI\'de telefon yöneticisini devre dışı bırakın'
        ];
      case 'samsung':
      case 'oneui':
        return [
          'Ayarlar > Uygulamalar > Özel erişim > Pil optimizasyonu > Optimize edilmeyen',
          'Ayarlar > Cihaz bakımı > Pil > Arka plan uygulama limitleri',
          'OneUI\'da Adaptif pil ayarlarını kontrol edin'
        ];
      default:
        return [
          'Cihaz ayarlarında uygulamayı korumalı uygulamalar listesine ekleyin',
          'Arka plan uygulama kısıtlamalarını kontrol edin'
        ];
    }
  }

  // Pil optimizasyonu iznini iste
  static Future<bool> requestIgnoreBatteryOptimizations() async {
    try {
      if (!Platform.isAndroid) return true;

      final status = await Permission.ignoreBatteryOptimizations.request();
      
      if (status.isDenied || status.isPermanentlyDenied) {
        debugPrint('⚠️ Battery optimization izni reddedildi');
        // Kullanıcıyı manuel ayarlara yönlendir
        await _showBatteryOptimizationDialog();
        return false;
      }

      debugPrint('✅ Battery optimization izni verildi');
      return status.isGranted;
    } catch (e) {
      debugPrint('❌ Battery optimization izni isteme hatası: $e');
      return false;
    }
  }

  // Battery optimization dialog göster
  static Future<void> _showBatteryOptimizationDialog() async {
    // Bu method UI context'i olmadan çalışacak şekilde tasarlandı
    // Uygulamanın ana context'inde kullanılmalı
    debugPrint('📱 Battery optimization ayarları dialog\'u gösterilmeli');
  }

  // Battery optimization ayarlarına yönlendir
  static Future<void> openBatteryOptimizationSettings() async {
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('openBatteryOptimizationSettings');
        debugPrint('🔧 Battery optimization ayarları açıldı');
      }
    } catch (e) {
      debugPrint('❌ Battery optimization ayarları açma hatası: $e');
      // Fallback: genel ayarlar
      await openSystemSettings();
    }
  }

  // Sistem ayarlarını aç
  static Future<void> openSystemSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      debugPrint('❌ Sistem ayarları açma hatası: $e');
    }
  }

  // Auto-start ayarlarına yönlendir (marka-spesifik)
  static Future<void> openAutoStartSettings() async {
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('openAutoStartSettings');
        debugPrint('🚀 Auto-start ayarları açıldı');
      }
    } catch (e) {
      debugPrint('❌ Auto-start ayarları açma hatası: $e');
    }
  }

  // Fallback notification stratejileri
  static Map<String, dynamic> getFallbackStrategies(NotificationReliability reliability) {
    switch (reliability) {
      case NotificationReliability.unreliable:
        return {
          'multiple_channels': true,
          'repeat_interval': 300, // 5 dakika
          'max_retries': 5,
          'use_high_priority': true,
          'use_sound_vibration': true,
          'backup_methods': ['sms', 'email', 'in_app'],
          'schedule_ahead': true,
          'persistent_notification': true,
        };
      case NotificationReliability.low:
        return {
          'multiple_channels': true,
          'repeat_interval': 600, // 10 dakika
          'max_retries': 3,
          'use_high_priority': true,
          'use_sound_vibration': true,
          'backup_methods': ['in_app'],
          'schedule_ahead': true,
          'persistent_notification': false,
        };
      case NotificationReliability.medium:
        return {
          'multiple_channels': false,
          'repeat_interval': 1800, // 30 dakika
          'max_retries': 2,
          'use_high_priority': false,
          'use_sound_vibration': true,
          'backup_methods': [],
          'schedule_ahead': false,
          'persistent_notification': false,
        };
      case NotificationReliability.high:
        return {
          'multiple_channels': false,
          'repeat_interval': 0,
          'max_retries': 1,
          'use_high_priority': false,
          'use_sound_vibration': true,
          'backup_methods': [],
          'schedule_ahead': false,
          'persistent_notification': false,
        };
    }
  }

  // Cihaz pil durumu bilgilerini al
  static Future<Map<String, dynamic>> getDeviceBatteryInfo() async {
    final result = <String, dynamic>{
      'level': 100,
      'isCharging': false,
      'powerSaveMode': false,
      'batteryOptimizationEnabled': false,
    };

    try {
      if (Platform.isAndroid) {
        final batteryInfo = await _channel.invokeMethod<Map>('getBatteryInfo') ?? {};
        result.addAll(Map<String, dynamic>.from(batteryInfo));
      }
    } catch (e) {
      debugPrint('❌ Pil durumu bilgisi alma hatası: $e');
    }

    return result;
  }

  // Notification delivery raporu oluştur
  static Future<Map<String, dynamic>> generateDeliveryReport(String userId) async {
    final status = await checkBatteryOptimizationStatus();
    final batteryInfo = await getDeviceBatteryInfo();
    
    return {
      'userId': userId,
      'timestamp': DateTime.now().toIso8601String(),
      'device': {
        'brand': _deviceInfo?.brand ?? 'unknown',
        'model': _deviceInfo?.model ?? 'unknown',
        'androidVersion': _deviceInfo?.version.release ?? 'unknown',
        'sdkVersion': _deviceInfo?.version.sdkInt ?? 0,
      },
      'batteryOptimization': status,
      'batteryInfo': batteryInfo,
      'recommendations': status['recommendations'],
      'fallbackStrategies': getFallbackStrategies(
        NotificationReliability.values.firstWhere(
          (e) => e.name == status['reliability'],
          orElse: () => NotificationReliability.unreliable,
        ),
      ),
    };
  }

  // Hafif bildirim test et
  static Future<bool> testNotificationDelivery() async {
    try {
      if (Platform.isAndroid) {
        final result = await _channel.invokeMethod<bool>('testNotification') ?? false;
        debugPrint('🧪 Test bildirimi gönderildi: $result');
        return result;
      }
      return true;
    } catch (e) {
      debugPrint('❌ Test bildirimi hatası: $e');
      return false;
    }
  }

  // Bildirim geçmişi ve istatistikleri
  static Future<Map<String, dynamic>> getNotificationStats() async {
    try {
      if (Platform.isAndroid) {
        final stats = await _channel.invokeMethod<Map>('getNotificationStats') ?? {};
        return Map<String, dynamic>.from(stats);
      }
      return {};
    } catch (e) {
      debugPrint('❌ Bildirim istatistikleri alma hatası: $e');
      return {};
    }
  }

  /// Battery optimization etkin mi kontrolü (eksik method)
  static bool isBatteryOptimizationEnabled() {
    // Basit implementasyon - daha detaylı kontrol gerekirse checkBatteryOptimizationStatus kullan
    return false; // Şimdilik false dön
  }

  /// Status listener'ları için callback listesi
  static final List<Function(bool)> _statusListeners = [];

  /// Battery optimization status değişikliklerini dinle
  static void addStatusListener(Function(bool) listener) {
    _statusListeners.add(listener);
  }

  /// Status listener'ı kaldır
  static void removeStatusListener(Function(bool) listener) {
    _statusListeners.remove(listener);
  }

}