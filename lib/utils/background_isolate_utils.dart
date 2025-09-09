import 'dart:isolate';
import 'dart:async';
import 'package:flutter/foundation.dart';

// Isolate message types
enum IsolateMessageType {
  initialize,
  terminate,
  scheduleTask,
  cancelTask,
  updateTask,
  heartbeat,
  error,
  result,
}

// Base message structure for isolate communication
class IsolateMessage {
  final IsolateMessageType type;
  final String id;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  IsolateMessage({
    required this.type,
    required this.id,
    required this.data,
  }) : timestamp = DateTime.now();

  Map<String, dynamic> toMap() => {
    'type': type.name,
    'id': id,
    'data': data,
    'timestamp': timestamp.toIso8601String(),
  };

  factory IsolateMessage.fromMap(Map<String, dynamic> map) => IsolateMessage(
    type: IsolateMessageType.values.firstWhere(
      (e) => e.name == map['type'],
      orElse: () => IsolateMessageType.error,
    ),
    id: map['id'] ?? '',
    data: Map<String, dynamic>.from(map['data'] ?? {}),
  );
}

// Task data for scheduling
class ScheduledTask {
  final String id;
  final DateTime scheduleTime;
  final Map<String, dynamic> taskData;
  final Duration? interval; // null for one-time tasks
  bool isActive;

  ScheduledTask({
    required this.id,
    required this.scheduleTime,
    required this.taskData,
    this.interval,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'scheduleTime': scheduleTime.toIso8601String(),
    'taskData': taskData,
    'interval': interval?.inMilliseconds,
    'isActive': isActive,
  };

  factory ScheduledTask.fromMap(Map<String, dynamic> map) => ScheduledTask(
    id: map['id'],
    scheduleTime: DateTime.parse(map['scheduleTime']),
    taskData: Map<String, dynamic>.from(map['taskData']),
    interval: map['interval'] != null 
        ? Duration(milliseconds: map['interval'])
        : null,
    isActive: map['isActive'] ?? true,
  );
  
  // Next execution time for recurring tasks
  DateTime? getNextExecution() {
    if (interval == null) return null;
    
    final now = DateTime.now();
    var next = scheduleTime;
    
    while (next.isBefore(now)) {
      next = next.add(interval!);
    }
    
    return next;
  }
}

// Isolate manager for background tasks
class BackgroundIsolateManager {
  static final BackgroundIsolateManager _instance = BackgroundIsolateManager._internal();
  factory BackgroundIsolateManager() => _instance;
  BackgroundIsolateManager._internal();

  Isolate? _isolate;
  ReceivePort? _receivePort;
  SendPort? _sendPort;
  
  final Map<String, Completer<dynamic>> _pendingRequests = {};
  final StreamController<IsolateMessage> _messageController = 
      StreamController<IsolateMessage>.broadcast();
  
  Timer? _heartbeatTimer;
  bool _isInitialized = false;

  Stream<IsolateMessage> get messageStream => _messageController.stream;
  bool get isInitialized => _isInitialized;

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _receivePort = ReceivePort();
      _receivePort!.listen(_handleMessage);

      _isolate = await Isolate.spawn(_isolateEntryPoint, _receivePort!.sendPort);
      
      // Wait for isolate to send back its SendPort
      final initCompleter = Completer<SendPort>();
      _pendingRequests['init'] = initCompleter;
      
      _sendPort = await initCompleter.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Isolate initialization timeout'),
      );
      
      _startHeartbeat();
      _isInitialized = true;
      
      debugPrint('✅ Background isolate başlatıldı');
      return true;
      
    } catch (e) {
      debugPrint('❌ Background isolate başlatma hatası: $e');
      await dispose();
      return false;
    }
  }

  Future<void> dispose() async {
    _heartbeatTimer?.cancel();
    _isolate?.kill(priority: Isolate.immediate);
    _receivePort?.close();
    
    _isolate = null;
    _receivePort = null;
    _sendPort = null;
    _isInitialized = false;
    
    // Complete pending requests with error
    for (final completer in _pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.completeError('Isolate disposed');
      }
    }
    _pendingRequests.clear();
    
    await _messageController.close();
    debugPrint('⏹️ Background isolate durduruldu');
  }

  void _handleMessage(dynamic message) {
    try {
      if (message is SendPort) {
        // Initial SendPort from isolate
        final completer = _pendingRequests.remove('init');
        completer?.complete(message);
        return;
      }
      
      if (message is Map<String, dynamic>) {
        final isolateMessage = IsolateMessage.fromMap(message);
        
        switch (isolateMessage.type) {
          case IsolateMessageType.result:
          case IsolateMessageType.error:
            final completer = _pendingRequests.remove(isolateMessage.id);
            if (completer != null && !completer.isCompleted) {
              if (isolateMessage.type == IsolateMessageType.error) {
                completer.completeError(isolateMessage.data['error'] ?? 'Unknown error');
              } else {
                completer.complete(isolateMessage.data['result']);
              }
            }
            break;
          case IsolateMessageType.heartbeat:
            // Isolate is alive
            break;
          default:
            _messageController.add(isolateMessage);
            break;
        }
      }
    } catch (e) {
      debugPrint('❌ Message handling hatası: $e');
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(
      const Duration(minutes: 1),
      (timer) async {
        try {
          await sendMessage(IsolateMessageType.heartbeat, 'heartbeat', {});
        } catch (e) {
          debugPrint('⚠️ Heartbeat hatası: $e');
          // Isolate might be dead, try to restart
          _tryRestart();
        }
      },
    );
  }

  void _tryRestart() async {
    debugPrint('🔄 Isolate yeniden başlatılıyor...');
    await dispose();
    await Future.delayed(const Duration(seconds: 2));
    await initialize();
  }

  Future<T?> sendMessage<T>(
    IsolateMessageType type,
    String id,
    Map<String, dynamic> data, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (!_isInitialized || _sendPort == null) {
      throw StateError('Isolate not initialized');
    }

    final message = IsolateMessage(type: type, id: id, data: data);
    final completer = Completer<T>();
    _pendingRequests[id] = completer;

    try {
      _sendPort!.send(message.toMap());
      return await completer.future.timeout(timeout);
    } catch (e) {
      _pendingRequests.remove(id);
      rethrow;
    }
  }

  // Convenience methods for common operations
  Future<bool> scheduleTask(ScheduledTask task) async {
    try {
      await sendMessage<bool>(
        IsolateMessageType.scheduleTask,
        'schedule_${task.id}',
        task.toMap(),
      );
      return true;
    } catch (e) {
      debugPrint('❌ Task schedule hatası: $e');
      return false;
    }
  }

  Future<bool> cancelTask(String taskId) async {
    try {
      await sendMessage<bool>(
        IsolateMessageType.cancelTask,
        'cancel_$taskId',
        {'taskId': taskId},
      );
      return true;
    } catch (e) {
      debugPrint('❌ Task cancel hatası: $e');
      return false;
    }
  }

  Future<bool> updateTask(ScheduledTask task) async {
    try {
      await sendMessage<bool>(
        IsolateMessageType.updateTask,
        'update_${task.id}',
        task.toMap(),
      );
      return true;
    } catch (e) {
      debugPrint('❌ Task update hatası: $e');
      return false;
    }
  }
}

// Entry point for the background isolate
void _isolateEntryPoint(SendPort mainSendPort) async {
  final isolateReceivePort = ReceivePort();
  
  // Send the isolate's SendPort back to main
  mainSendPort.send(isolateReceivePort.sendPort);
  
  final worker = _IsolateWorker(mainSendPort);
  
  await for (final message in isolateReceivePort) {
    if (message is Map<String, dynamic>) {
      final isolateMessage = IsolateMessage.fromMap(message);
      await worker.handleMessage(isolateMessage);
    }
  }
}

// Worker class that runs inside the isolate
class _IsolateWorker {
  final SendPort _mainSendPort;
  final Map<String, Timer> _activeTimers = {};
  final Map<String, ScheduledTask> _scheduledTasks = {};
  
  _IsolateWorker(this._mainSendPort);

  Future<void> handleMessage(IsolateMessage message) async {
    try {
      switch (message.type) {
        case IsolateMessageType.scheduleTask:
          await _handleScheduleTask(message);
          break;
        case IsolateMessageType.cancelTask:
          await _handleCancelTask(message);
          break;
        case IsolateMessageType.updateTask:
          await _handleUpdateTask(message);
          break;
        case IsolateMessageType.heartbeat:
          _handleHeartbeat(message);
          break;
        case IsolateMessageType.terminate:
          _handleTerminate(message);
          break;
        default:
          _sendError(message.id, 'Unknown message type: ${message.type}');
      }
    } catch (e) {
      _sendError(message.id, e.toString());
    }
  }

  Future<void> _handleScheduleTask(IsolateMessage message) async {
    final task = ScheduledTask.fromMap(message.data);
    _scheduledTasks[task.id] = task;
    
    _scheduleTaskTimer(task);
    _sendResult(message.id, true);
  }

  Future<void> _handleCancelTask(IsolateMessage message) async {
    final taskId = message.data['taskId'] as String;
    
    _activeTimers[taskId]?.cancel();
    _activeTimers.remove(taskId);
    _scheduledTasks.remove(taskId);
    
    _sendResult(message.id, true);
  }

  Future<void> _handleUpdateTask(IsolateMessage message) async {
    final task = ScheduledTask.fromMap(message.data);
    
    // Cancel existing timer
    _activeTimers[task.id]?.cancel();
    
    // Update and reschedule
    _scheduledTasks[task.id] = task;
    _scheduleTaskTimer(task);
    
    _sendResult(message.id, true);
  }

  void _handleHeartbeat(IsolateMessage message) {
    _mainSendPort.send(IsolateMessage(
      type: IsolateMessageType.heartbeat,
      id: message.id,
      data: {'timestamp': DateTime.now().toIso8601String()},
    ).toMap());
  }

  void _handleTerminate(IsolateMessage message) {
    // Clean up all timers
    for (final timer in _activeTimers.values) {
      timer.cancel();
    }
    _activeTimers.clear();
    _scheduledTasks.clear();
    
    _sendResult(message.id, true);
  }

  void _scheduleTaskTimer(ScheduledTask task) {
    if (!task.isActive) return;
    
    final now = DateTime.now();
    final delay = task.scheduleTime.difference(now);
    
    if (delay.isNegative && task.interval == null) {
      // One-time task in the past, skip
      return;
    }
    
    final actualDelay = delay.isNegative ? Duration.zero : delay;
    
    _activeTimers[task.id] = Timer(actualDelay, () {
      _executeTask(task);
      
      // Schedule next execution for recurring tasks
      if (task.interval != null) {
        final nextExecution = task.getNextExecution();
        if (nextExecution != null) {
          final updatedTask = ScheduledTask(
            id: task.id,
            scheduleTime: nextExecution,
            taskData: task.taskData,
            interval: task.interval,
            isActive: task.isActive,
          );
          _scheduledTasks[task.id] = updatedTask;
          _scheduleTaskTimer(updatedTask);
        }
      } else {
        // One-time task completed
        _scheduledTasks.remove(task.id);
      }
    });
  }

  void _executeTask(ScheduledTask task) {
    // Send task execution notification to main isolate
    _mainSendPort.send(IsolateMessage(
      type: IsolateMessageType.result,
      id: 'task_executed',
      data: {
        'taskId': task.id,
        'executionTime': DateTime.now().toIso8601String(),
        'taskData': task.taskData,
      },
    ).toMap());
  }

  void _sendResult(String id, dynamic result) {
    _mainSendPort.send(IsolateMessage(
      type: IsolateMessageType.result,
      id: id,
      data: {'result': result},
    ).toMap());
  }

  void _sendError(String id, String error) {
    _mainSendPort.send(IsolateMessage(
      type: IsolateMessageType.error,
      id: id,
      data: {'error': error},
    ).toMap());
  }
}