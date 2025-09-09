import 'dart:async';
import 'package:flutter/foundation.dart';

enum NotificationCategory {
  delivery,
  reminder,
  appointment,
  progress,
  alert,
  general,
}

class NotificationData {
  final String id;
  final String title;
  final String body;
  final NotificationCategory category;
  final Map<String, dynamic> payload;
  final DateTime? scheduledTime;

  NotificationData({
    required this.id,
    required this.title,
    required this.body,
    this.category = NotificationCategory.general,
    this.payload = const {},
    this.scheduledTime,
  });
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  StreamController<NotificationData>? _notificationController;
  static Function(String, String, Map<String, dynamic>)? _newMessageCallback;
  
  Stream<NotificationData>? get onNotificationReceived => 
      _notificationController?.stream;

  Future<bool> initialize() async {
    try {
      _notificationController = StreamController<NotificationData>.broadcast();
      debugPrint('✅ Notification service başlatıldı');
      return true;
    } catch (e) {
      debugPrint('❌ Notification service başlatma hatası: $e');
      return false;
    }
  }

  static void setNewMessageCallback(Function(String, String, Map<String, dynamic>) callback) {
    _newMessageCallback = callback;
  }

  static void onNewMessage(String chatId, String messageId, Map<String, dynamic> messageData) {
    _newMessageCallback?.call(chatId, messageId, messageData);
  }

  Future<void> showDeliveryNotification({
    required String assignmentId,
    required String title,
    required String body,
    DateTime? scheduledTime,
  }) async {
    final data = NotificationData(
      id: 'delivery_$assignmentId',
      title: title,
      body: body,
      category: NotificationCategory.delivery,
      payload: {'type': 'delivery', 'assignmentId': assignmentId},
      scheduledTime: scheduledTime,
    );

    debugPrint('🔔 Notification: ${data.title}');
    _notificationController?.add(data);
  }
}