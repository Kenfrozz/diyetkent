import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'health_service.dart';

class StepCounterService {
  static StreamSubscription<StepCount>? _stepCountStream;
  static StreamSubscription<PedestrianStatus>? _pedestrianStatusStream;
  static int _todayStepCount = 0;
  static DateTime? _lastStepDate;
  static bool _isInitialized = false;

  // Adım sayar servisini başlat
  static Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // İzin kontrolü
      final hasPermission = await _requestPermissions();
      if (!hasPermission) {
        debugPrint('❌ Adım sayar izinleri reddedildi');
        return false;
      }

      // Önceki günün verilerini yükle
      await _loadPreviousData();

      // Adım sayar stream'ini başlat
      await _initStepCountStream();
      
      // Pedestrian status stream'ini başlat
      await _initPedestrianStatusStream();

      _isInitialized = true;
      debugPrint('✅ Adım sayar servisi başlatıldı');
      return true;
    } catch (e) {
      debugPrint('❌ Adım sayar servisi başlatma hatası: $e');
      return false;
    }
  }

  // İzinleri iste
  static Future<bool> _requestPermissions() async {
    try {
      // Android için activity recognition izni
      if (defaultTargetPlatform == TargetPlatform.android) {
        final permission = Permission.activityRecognition;
        final status = await permission.status;
        
        debugPrint('🔍 Adım sayar izin durumu: $status');
        
        if (status == PermissionStatus.granted) {
          debugPrint('✅ Adım sayar izni zaten verilmiş');
          return true;
        }
        
        if (status == PermissionStatus.denied) {
          debugPrint('⚠️ Adım sayar izni reddedilmiş, izin isteniyor...');
          final result = await permission.request();
          debugPrint('📋 İzin isteği sonucu: $result');
          return result == PermissionStatus.granted;
        }
        
        if (status == PermissionStatus.permanentlyDenied) {
          debugPrint('🚫 Adım sayar izni kalıcı olarak reddedilmiş');
          return false;
        }
        
        // Diğer durumlar için izin iste
        final result = await permission.request();
        debugPrint('📋 İzin isteği sonucu: $result');
        return result == PermissionStatus.granted;
      }

      // iOS için motion ve fitness izni
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        // iOS'ta pedometer paketi otomatik olarak izin ister
        debugPrint('📱 iOS platformu - pedometer paketi otomatik izin isteyecek');
        return true;
      }

      return true;
    } catch (e) {
      debugPrint('❌ İzin isteme hatası: $e');
      return false;
    }
  }

  // Önceki verileri yükle
  static Future<void> _loadPreviousData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _todayStepCount = prefs.getInt('today_step_count') ?? 0;
      
      final lastDateString = prefs.getString('last_step_date');
      if (lastDateString != null) {
        _lastStepDate = DateTime.parse(lastDateString);
        
        // Eğer son güncelleme bugün değilse, adım sayısını sıfırla
        final today = DateTime.now();
        if (_lastStepDate == null || 
            _lastStepDate!.day != today.day ||
            _lastStepDate!.month != today.month ||
            _lastStepDate!.year != today.year) {
          _todayStepCount = 0;
          await _saveTodayData();
        }
      }

      debugPrint('📱 Önceki adım verisi yüklendi: $_todayStepCount');
    } catch (e) {
      debugPrint('❌ Önceki veri yükleme hatası: $e');
    }
  }

  // Bugünkü verileri kaydet
  static Future<void> _saveTodayData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('today_step_count', _todayStepCount);
      await prefs.setString('last_step_date', DateTime.now().toIso8601String());
      _lastStepDate = DateTime.now();
    } catch (e) {
      debugPrint('❌ Bugünkü veri kaydetme hatası: $e');
    }
  }

  // Adım sayar stream'ini başlat
  static Future<void> _initStepCountStream() async {
    try {
      _stepCountStream = Pedometer.stepCountStream.listen(
        (StepCount event) async {
          await _onStepCountChanged(event);
        },
        onError: (error) {
          debugPrint('❌ Adım sayar stream hatası: $error');
        },
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('❌ Adım sayar stream başlatma hatası: $e');
    }
  }

  // Pedestrian status stream'ini başlat
  static Future<void> _initPedestrianStatusStream() async {
    try {
      _pedestrianStatusStream = Pedometer.pedestrianStatusStream.listen(
        (PedestrianStatus event) {
          debugPrint('🚶 Pedestrian status: ${event.status}');
        },
        onError: (error) {
          debugPrint('❌ Pedestrian status stream hatası: $error');
        },
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('❌ Pedestrian status stream başlatma hatası: $e');
    }
  }

  // Adım sayısı değiştiğinde çağrılır
  static Future<void> _onStepCountChanged(StepCount stepCount) async {
    try {
      final today = DateTime.now();
      final stepDate = stepCount.timeStamp;

      // Eğer adım bugünden değilse, görmezden gel
      if (stepDate.day != today.day ||
          stepDate.month != today.month ||
          stepDate.year != today.year) {
        return;
      }

      // İlk kez başlatıldığında, mevcut adım sayısını base olarak al
      if (_lastStepDate == null) {
        _todayStepCount = 0; // Günlük adım sayısını sıfırla
        await _saveTodayData();
      }

      // Günlük adım sayısını güncelle
      // Not: Pedometer genellikle cihaz açıldığından beri toplam adım sayısını verir
      // Bu yüzden günlük hesaplama yapmak için özel mantık gerekir
      
      debugPrint('📱 Adım sayısı güncellendi: ${stepCount.steps}');
      
      // Health service ile senkronize et
      await HealthService.updateStepCount(stepCount.steps);
      
    } catch (e) {
      debugPrint('❌ Adım sayısı işleme hatası: $e');
    }
  }

  // Manuel adım sayısı güncelleme
  static Future<bool> updateStepCount(int stepCount) async {
    try {
      _todayStepCount = stepCount;
      await _saveTodayData();
      
      // Health service ile senkronize et
      await HealthService.updateStepCount(stepCount);
      
      debugPrint('📱 Manuel adım sayısı güncellendi: $stepCount');
      return true;
    } catch (e) {
      debugPrint('❌ Manuel adım sayısı güncelleme hatası: $e');
      return false;
    }
  }

  // Mevcut adım sayısını getir
  static int get todayStepCount => _todayStepCount;

  // Servisin aktif olup olmadığını kontrol et
  static bool get isActive => _isInitialized && _stepCountStream != null;

  // Servisi durdur
  static Future<void> stop() async {
    try {
      await _stepCountStream?.cancel();
      await _pedestrianStatusStream?.cancel();
      _stepCountStream = null;
      _pedestrianStatusStream = null;
      _isInitialized = false;
      debugPrint('🛑 Adım sayar servisi durduruldu');
    } catch (e) {
      debugPrint('❌ Adım sayar servisi durdurma hatası: $e');
    }
  }

  // Servisi yeniden başlat
  static Future<bool> restart() async {
    await stop();
    return await initialize();
  }

  // Adım sayar desteği var mı kontrolü
  static Future<bool> isSupported() async {
    try {
      // Test stream'i başlatarak destek kontrolü yap
      final testStream = Pedometer.stepCountStream.listen(null);
      await testStream.cancel();
      return true;
    } catch (e) {
      debugPrint('❌ Adım sayar desteklenmiyor: $e');
      return false;
    }
  }

  // Günlük adım hedefine ulaşıp ulaşmadığını kontrol et
  static bool hasReachedDailyGoal({int dailyGoal = 10000}) {
    return _todayStepCount >= dailyGoal;
  }

  // Günlük hedef yüzdesini hesapla
  static double getDailyGoalProgress({int dailyGoal = 10000}) {
    if (dailyGoal <= 0) return 0.0;
    final progress = _todayStepCount / dailyGoal;
    return progress > 1.0 ? 1.0 : progress;
  }

  // Adım sayısını kalori yakımına çevir (yaklaşık)
  static double getCaloriesBurned({double weightKg = 70.0}) {
    // Ortalama: 1000 adım = yaklaşık 40-50 kalori (70kg için)
    const caloriesPerThousandSteps = 45.0;
    return (_todayStepCount / 1000) * caloriesPerThousandSteps * (weightKg / 70.0);
  }

  // Adım sayısını mesafe çevir (yaklaşık)
  static double getDistanceKm({double stepLengthCm = 75.0}) {
    // Ortalama adım uzunluğu: 75cm
    final totalDistanceCm = _todayStepCount * stepLengthCm;
    return totalDistanceCm / 100000; // km'ye çevir
  }

  // İzin durumunu kontrol et
  static Future<PermissionStatus> getPermissionStatus() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return await Permission.activityRecognition.status;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        // iOS'ta pedometer için özel kontrol gerekebilir
        return PermissionStatus.granted; // iOS genelde otomatik
      }
      return PermissionStatus.denied;
    } catch (e) {
      debugPrint('❌ İzin durumu kontrol hatası: $e');
      return PermissionStatus.denied;
    }
  }

  // Manuel izin isteği
  static Future<bool> requestPermission() async {
    return await _requestPermissions();
  }

  // Ayarlara yönlendir
  static Future<bool> openSettings() async {
    try {
      return await openAppSettings();
    } catch (e) {
      debugPrint('❌ Ayarlara yönlendirme hatası: $e');
      return false;
    }
  }

  // İzin durum mesajı
  static String getPermissionStatusMessage() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'Adım sayımı için "Fiziksel Aktivite" izni gereklidir.\n\nBu izin cihazınızın adım sensörüne erişim sağlar ve günlük adım sayınızı takip eder.';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'Adım sayımı için "Hareket ve Fitness" izni gereklidir.\n\nBu izin cihazınızın hareket sensörlerine erişim sağlar.';
    }
    return 'Adım sayımı için gerekli izinler alınamadı.';
  }
}
