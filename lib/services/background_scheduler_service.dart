import 'dart:isolate';
import 'dart:async';
import 'package:flutter/foundation.dart';
// import '../models/user_diet_assignment_model.dart'; // Removed - diet assignment feature removed

enum SchedulerStatus {
  stopped,
  running,
  paused,
  error,
}

class BackgroundSchedulerService {
  static final BackgroundSchedulerService _instance = BackgroundSchedulerService._internal();
  factory BackgroundSchedulerService() => _instance;
  BackgroundSchedulerService._internal();

  Isolate? _schedulerIsolate;
  ReceivePort? _receivePort;
  SendPort? _sendPort;
  
  SchedulerStatus _status = SchedulerStatus.stopped;
  Timer? _heartbeatTimer;
  StreamController<SchedulerEvent>? _eventController;
  
  SchedulerStatus get status => _status;
  Stream<SchedulerEvent>? get eventStream => _eventController?.stream;

  Future<void> startScheduler() async {
    if (_status == SchedulerStatus.running) return;

    try {
      _receivePort = ReceivePort();
      _eventController = StreamController<SchedulerEvent>.broadcast();

      _receivePort!.listen((message) {
        _handleIsolateMessage(message);
      });

      _schedulerIsolate = await Isolate.spawn(
        _schedulerIsolateEntry,
        _receivePort!.sendPort,
      );

      _status = SchedulerStatus.running;
      _startHeartbeat();
      
      _eventController?.add(SchedulerEvent.started());
      
      debugPrint('✅ Background scheduler başlatıldı');
    } catch (e) {
      _status = SchedulerStatus.error;
      _eventController?.add(SchedulerEvent.error(e.toString()));
      debugPrint('❌ Scheduler başlatma hatası: $e');
    }
  }

  Future<void> stopScheduler() async {
    if (_status == SchedulerStatus.stopped) return;

    _schedulerIsolate?.kill(priority: Isolate.immediate);
    _schedulerIsolate = null;
    
    _receivePort?.close();
    _receivePort = null;
    
    _sendPort = null;
    _heartbeatTimer?.cancel();
    
    _status = SchedulerStatus.stopped;
    _eventController?.add(SchedulerEvent.stopped());
    
    await _eventController?.close();
    _eventController = null;
    
    debugPrint('⏹️ Background scheduler durduruldu');
  }

  Future<void> pauseScheduler() async {
    if (_status != SchedulerStatus.running) return;
    
    _sendPort?.send({'action': 'pause'});
    _status = SchedulerStatus.paused;
    _eventController?.add(SchedulerEvent.paused());
  }

  Future<void> resumeScheduler() async {
    if (_status != SchedulerStatus.paused) return;
    
    _sendPort?.send({'action': 'resume'});
    _status = SchedulerStatus.running;
    _eventController?.add(SchedulerEvent.resumed());
  }

  Future<void> refreshSchedules() async {
    if (_status == SchedulerStatus.stopped) return;
    
    _sendPort?.send({'action': 'refresh'});
  }

  void _handleIsolateMessage(dynamic message) {
    if (message is Map<String, dynamic>) {
      switch (message['type']) {
        case 'ready':
          _sendPort = message['sendPort'] as SendPort;
          debugPrint('🔗 Isolate ile bağlantı kuruldu');
          break;
          
        case 'heartbeat':
          // Isolate sağlık durumu kontrolü
          break;
          
        case 'delivery_triggered':
          final assignmentId = message['assignmentId'] as String;
          _eventController?.add(SchedulerEvent.deliveryTriggered(assignmentId));
          debugPrint('📦 Teslimat tetiklendi: $assignmentId');
          break;
          
        case 'error':
          final error = message['error'] as String;
          _status = SchedulerStatus.error;
          _eventController?.add(SchedulerEvent.error(error));
          debugPrint('❌ Isolate hatası: $error');
          break;
      }
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(
      const Duration(minutes: 1),
      (timer) {
        _sendPort?.send({'action': 'ping'});
      },
    );
  }

  // Public interface for updating individual schedules
  Future<void> updateSchedule(String assignmentId) async {
    _sendPort?.send({
      'action': 'update_schedule',
      'assignmentId': assignmentId,
    });
  }

  Future<void> removeSchedule(String assignmentId) async {
    _sendPort?.send({
      'action': 'remove_schedule', 
      'assignmentId': assignmentId,
    });
  }
}

// Isolate entry point - static method
void _schedulerIsolateEntry(SendPort mainSendPort) async {
  final isolateReceivePort = ReceivePort();
  
  // Ana isolate'e sendPort'u gönder
  mainSendPort.send({
    'type': 'ready',
    'sendPort': isolateReceivePort.sendPort,
  });

  final schedulerWorker = _SchedulerWorker(mainSendPort);
  
  isolateReceivePort.listen((message) async {
    if (message is Map<String, dynamic>) {
      await schedulerWorker.handleMessage(message);
    }
  });
}

// Worker class that runs inside the isolate
class _SchedulerWorker {
  final SendPort _mainSendPort;
  Timer? _mainTimer;
  bool _isPaused = false;
  final Map<String, Map<String, dynamic>> _activeSchedules = {}; // Changed from UserDietAssignmentModel
  
  _SchedulerWorker(this._mainSendPort);

  Future<void> handleMessage(Map<String, dynamic> message) async {
    switch (message['action']) {
      case 'pause':
        _isPaused = true;
        break;
        
      case 'resume':
        _isPaused = false;
        break;
        
      case 'refresh':
        await _loadActiveSchedules();
        break;
        
      case 'ping':
        _mainSendPort.send({'type': 'heartbeat'});
        break;
        
      case 'update_schedule':
        await _updateSingleSchedule(message['assignmentId']);
        break;
        
      case 'remove_schedule':
        _removeSchedule(message['assignmentId']);
        break;
    }
    
    _startMainTimer();
  }

  void _startMainTimer() {
    _mainTimer?.cancel();
    
    _mainTimer = Timer.periodic(
      const Duration(minutes: 1), // Her dakika kontrol et
      (timer) async {
        if (!_isPaused) {
          await _checkSchedules();
        }
      },
    );
  }

  Future<void> _checkSchedules() async {
    try {
      final now = DateTime.now();
      
      for (final schedule in _activeSchedules.values) {
        final isDeliveryActive = schedule['isDeliveryActive'] as bool? ?? false;
        final nextDeliveryTimeStr = schedule['nextDeliveryTime'] as String?;
        DateTime? nextDeliveryTime;
        
        if (nextDeliveryTimeStr != null) {
          try {
            nextDeliveryTime = DateTime.parse(nextDeliveryTimeStr);
          } catch (e) {
            // Invalid date format, skip this schedule
            continue;
          }
        }
        
        if (isDeliveryActive && 
            nextDeliveryTime != null &&
            nextDeliveryTime.isBefore(now.add(const Duration(minutes: 1)))) {
          
          // Teslimatı tetikle
          _mainSendPort.send({
            'type': 'delivery_triggered',
            'assignmentId': schedule['assignmentId'],
          });
          
          // Bir sonraki teslimat zamanını hesapla
          schedule['nextDeliveryTime'] = DateTime.now().add(const Duration(days: 1)).toIso8601String();
          
          // Veritabanını güncelle (isolate içinde Isar kullanımı dikkatli olmalı)
          await _updateScheduleInDatabase(schedule);
        }
      }
    } catch (e) {
      _mainSendPort.send({
        'type': 'error',
        'error': e.toString(),
      });
    }
  }

  Future<void> _loadActiveSchedules() async {
    try {
      // Not: Isolate içinde Isar kullanımı için özel yaklaşım gerekli
      // Bu örnek için basit bir implementation
      _activeSchedules.clear();
      
      // Ana isolate'den veri alınması gerekebilir
      // Şimdilik boş implementation
      
    } catch (e) {
      _mainSendPort.send({
        'type': 'error',
        'error': 'Schedule yükleme hatası: $e',
      });
    }
  }

  Future<void> _updateSingleSchedule(String assignmentId) async {
    try {
      // Tek bir schedule'ı güncelle
      // Implementation database erişimi gerektirir
    } catch (e) {
      _mainSendPort.send({
        'type': 'error',
        'error': 'Schedule güncelleme hatası: $e',
      });
    }
  }

  void _removeSchedule(String assignmentId) {
    _activeSchedules.remove(assignmentId);
  }

  Future<void> _updateScheduleInDatabase(Map<String, dynamic> schedule) async {
    try {
      // Isolate içinde veritabanı güncellemesi
      // Bu karmaşık bir konu - ana isolate ile koordinasyon gerekli
    } catch (e) {
      _mainSendPort.send({
        'type': 'error', 
        'error': 'Database güncelleme hatası: $e',
      });
    }
  }
}

// Event classes for scheduler communication
class SchedulerEvent {
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  SchedulerEvent(this.type, this.data) : timestamp = DateTime.now();

  factory SchedulerEvent.started() => SchedulerEvent('started', {});
  factory SchedulerEvent.stopped() => SchedulerEvent('stopped', {});
  factory SchedulerEvent.paused() => SchedulerEvent('paused', {});
  factory SchedulerEvent.resumed() => SchedulerEvent('resumed', {});
  factory SchedulerEvent.error(String error) => SchedulerEvent('error', {'error': error});
  factory SchedulerEvent.deliveryTriggered(String assignmentId) => 
    SchedulerEvent('delivery_triggered', {'assignmentId': assignmentId});

  @override
  String toString() => 'SchedulerEvent($type, $data)';
}

// Timer coordination service
class ScheduledTimerService {
  static final ScheduledTimerService _instance = ScheduledTimerService._internal();
  factory ScheduledTimerService() => _instance;
  ScheduledTimerService._internal();

  final Map<String, Timer> _activeTimers = {};

  void scheduleDelivery(String assignmentId, DateTime deliveryTime, VoidCallback callback) {
    // Mevcut timer'ı iptal et
    _activeTimers[assignmentId]?.cancel();
    
    final delay = deliveryTime.difference(DateTime.now());
    
    if (delay.isNegative) return; // Geçmiş bir zaman
    
    _activeTimers[assignmentId] = Timer(delay, () {
      callback();
      _activeTimers.remove(assignmentId);
    });
  }

  void cancelDelivery(String assignmentId) {
    _activeTimers[assignmentId]?.cancel();
    _activeTimers.remove(assignmentId);
  }

  void cancelAllDeliveries() {
    for (final timer in _activeTimers.values) {
      timer.cancel();
    }
    _activeTimers.clear();
  }

  int get activeDeliveryCount => _activeTimers.length;
  
  List<String> get activeDeliveryIds => _activeTimers.keys.toList();
}