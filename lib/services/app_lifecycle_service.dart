import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'background_scheduler_service.dart';
import 'delivery_executor_service.dart';


class AppLifecycleService with WidgetsBindingObserver {
  static final AppLifecycleService _instance = AppLifecycleService._internal();
  factory AppLifecycleService() => _instance;
  AppLifecycleService._internal();

  final BackgroundSchedulerService _schedulerService = BackgroundSchedulerService();
  final DeliveryExecutorService _deliveryExecutorService = DeliveryExecutorService();
  
  AppLifecycleState _currentState = AppLifecycleState.resumed;
  Timer? _backgroundTimer;
  StreamController<AppLifecycleState>? _stateController;
  
  AppLifecycleState get currentState => _currentState;
  Stream<AppLifecycleState>? get stateStream => _stateController?.stream;

  Future<void> initialize() async {
    _stateController = StreamController<AppLifecycleState>.broadcast();
    WidgetsBinding.instance.addObserver(this);
    
    // Delivery executor'ı başlat
    await _deliveryExecutorService.initialize();
    
    debugPrint('🔄 App Lifecycle Service başlatıldı');
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    _backgroundTimer?.cancel();
    await _stateController?.close();
    await _deliveryExecutorService.dispose();
    
    debugPrint('⏹️ App Lifecycle Service durduruldu');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    
    _currentState = state;
    _stateController?.add(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        _onAppResumed();
        break;
      case AppLifecycleState.paused:
        _onAppPaused();
        break;
      case AppLifecycleState.inactive:
        _onAppInactive();
        break;
      case AppLifecycleState.detached:
        _onAppDetached();
        break;
      case AppLifecycleState.hidden:
        _onAppHidden();
        break;
    }
    
    debugPrint('🔄 App state değişti: $state');
  }


  void _onAppResumed() {
    // App ön plana geldiğinde
    _backgroundTimer?.cancel();
    
    // Scheduler'ı devam ettir
    _schedulerService.resumeScheduler();
    
    // Zamanlamayı yenile
    _schedulerService.refreshSchedules();
  }

  void _onAppPaused() {
    // App arka plana geçtiğinde
    _startBackgroundTimer();
    
    // Scheduler'ı duraklat (opsiyonel - background'da çalışmaya devam edebilir)
    // _schedulerService.pauseScheduler();
  }

  void _onAppInactive() {
    // App geçici olarak inaktif (örn: telefon geldiğinde)
    // Kritik olmayan işlemleri durdur
  }

  void _onAppDetached() {
    // App tamamen kapatıldı
    _backgroundTimer?.cancel();
    _schedulerService.stopScheduler();
  }

  void _onAppHidden() {
    // App gizlendi (iOS için)
    _onAppPaused();
  }

  void _startBackgroundTimer() {
    _backgroundTimer?.cancel();
    
    // Background'da 30 saniyede bir kontrol et
    _backgroundTimer = Timer.periodic(
      const Duration(seconds: 30),
      (timer) {
        _handleBackgroundTick();
      },
    );
  }

  void _handleBackgroundTick() {
    // Background'da yapılacak işlemler
    debugPrint('⏰ Background tick - ${DateTime.now()}');
    
    // Scheduler durumunu kontrol et
    if (_schedulerService.status == SchedulerStatus.stopped) {
      _schedulerService.startScheduler();
    }
  }

  // Manuel state değişikliklerini test etmek için
  void simulateStateChange(AppLifecycleState state) {
    didChangeAppLifecycleState(state);
  }
}

// Platform channel'ları için native kod entegrasyonu
class BackgroundTaskManager {
  static const MethodChannel _channel = MethodChannel('diet_scheduler/background');
  
  // iOS için background app refresh
  static Future<bool> requestBackgroundRefresh() async {
    try {
      final result = await _channel.invokeMethod('requestBackgroundRefresh');
      return result ?? false;
    } catch (e) {
      debugPrint('Background refresh request hatası: $e');
      return false;
    }
  }
  
  // Android için foreground service
  static Future<bool> startForegroundService() async {
    try {
      final result = await _channel.invokeMethod('startForegroundService');
      return result ?? false;
    } catch (e) {
      debugPrint('Foreground service başlatma hatası: $e');
      return false;
    }
  }
  
  static Future<bool> stopForegroundService() async {
    try {
      final result = await _channel.invokeMethod('stopForegroundService');
      return result ?? false;
    } catch (e) {
      debugPrint('Foreground service durdurma hatası: $e');
      return false;
    }
  }
}

// Platform-specific background handling
class PlatformBackgroundHandler {
  static Future<void> setupBackgroundHandling() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _setupiOSBackgroundHandling();
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      await _setupAndroidBackgroundHandling();
    }
  }
  
  static Future<void> _setupiOSBackgroundHandling() async {
    // iOS için background app refresh
    await BackgroundTaskManager.requestBackgroundRefresh();
  }
  
  static Future<void> _setupAndroidBackgroundHandling() async {
    // Android için foreground service
    await BackgroundTaskManager.startForegroundService();
  }
}