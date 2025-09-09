import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import '../database/drift_service.dart';
import '../models/progress_reminder_model.dart';
import '../services/auth_service.dart';

class ProgressReminderService {
  static const String _channelId = 'progress_reminders';

  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  // Progress check-in bildirim kanal ID'leri
  static const Map<ProgressReminderType, String> _channelIds = {
    ProgressReminderType.weightUpdate: 'weight_updates',
    ProgressReminderType.dietAdherence: 'diet_adherence',
    ProgressReminderType.milestone: 'milestones',
    ProgressReminderType.weeklyProgress: 'weekly_progress',
    ProgressReminderType.monthlyAssessment: 'monthly_assessment',
    ProgressReminderType.waterIntake: 'water_intake',
    ProgressReminderType.exerciseLog: 'exercise_log',
    ProgressReminderType.moodTracker: 'mood_tracker',
  };

  static Future<void> initialize() async {
    try {
      debugPrint('🔔 Progress Reminder servisi başlatılıyor...');
      
      // Notification kanallarını oluştur
      await _createNotificationChannels();
      
      // Mevcut aktif hatırlatmaları kontrol et ve planla
      await _scheduleActiveReminders();
      
      debugPrint('✅ Progress Reminder servisi başlatıldı');
    } catch (e) {
      debugPrint('❌ Progress Reminder servisi başlatma hatası: $e');
    }
  }

  // Notification kanallarını oluştur
  static Future<void> _createNotificationChannels() async {
    const androidSettings = AndroidNotificationChannelGroup(
      'progress_reminders_group',
      'İlerleme Hatırlatmaları',
      description: 'Diyet ve sağlık ilerlemesi için hatırlatmalar',
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannelGroup(androidSettings);

    // Her tip için ayrı kanal oluştur
    for (final entry in _channelIds.entries) {
      final type = entry.key;
      final channelId = entry.value;
      
      const importance = Importance.high;
      
      final androidChannel = AndroidNotificationChannel(
        channelId,
        _getChannelName(type),
        description: _getChannelDescription(type),
        importance: importance,
        groupId: 'progress_reminders_group',
        enableVibration: true,
        playSound: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
    }
  }

  // Kanal adını al
  static String _getChannelName(ProgressReminderType type) {
    switch (type) {
      case ProgressReminderType.weightUpdate:
        return 'Kilo Güncellemeleri';
      case ProgressReminderType.dietAdherence:
        return 'Diyet Uyum Kontrolleri';
      case ProgressReminderType.milestone:
        return 'Kilometre Taşları';
      case ProgressReminderType.weeklyProgress:
        return 'Haftalık İlerleme';
      case ProgressReminderType.monthlyAssessment:
        return 'Aylık Değerlendirme';
      case ProgressReminderType.waterIntake:
        return 'Su Tüketimi';
      case ProgressReminderType.exerciseLog:
        return 'Egzersiz Kayıtları';
      case ProgressReminderType.moodTracker:
        return 'Ruh Hali Takibi';
    }
  }

  // Kanal açıklamasını al
  static String _getChannelDescription(ProgressReminderType type) {
    switch (type) {
      case ProgressReminderType.weightUpdate:
        return 'Kilo güncellemesi hatırlatmaları';
      case ProgressReminderType.dietAdherence:
        return 'Diyet uyum kontrolü hatırlatmaları';
      case ProgressReminderType.milestone:
        return 'Önemli kilometre taşı bildirimleri';
      case ProgressReminderType.weeklyProgress:
        return 'Haftalık ilerleme değerlendirmeleri';
      case ProgressReminderType.monthlyAssessment:
        return 'Aylık sağlık değerlendirmeleri';
      case ProgressReminderType.waterIntake:
        return 'Su tüketimi takip hatırlatmaları';
      case ProgressReminderType.exerciseLog:
        return 'Egzersiz kayıt hatırlatmaları';
      case ProgressReminderType.moodTracker:
        return 'Ruh hali takip hatırlatmaları';
    }
  }

  // Yeni progress reminder oluştur
  static Future<ProgressReminderModel> createProgressReminder({
    required String userId,
    required ProgressReminderType type,
    required String title,
    required String message,
    String? dietitianId,
    ProgressReminderFrequency frequency = ProgressReminderFrequency.weekly,
    String description = '',
    DateTime? scheduledTime,
    bool isEnabled = true,
    int? customIntervalDays,
    List<int> reminderDays = const <int>[],
    int priority = 1,
    List<String> tags = const <String>[],
    String? assignmentId,
    String? packageId,
    Map<String, String>? targetValues,
    int maxReminders = 3,
  }) async {
    try {
      final reminder = ProgressReminderModel.create(
        userId: userId,
        type: type,
        title: title,
        message: message,
        dietitianId: dietitianId,
        frequency: frequency,
        description: description,
        scheduledTime: scheduledTime,
        isEnabled: isEnabled,
        customIntervalDays: customIntervalDays,
        reminderDays: reminderDays,
        priority: priority,
        tags: tags,
        assignmentId: assignmentId,
        packageId: packageId,
        targetValues: targetValues,
        maxReminders: maxReminders,
      );

      // Veritabanına kaydet
      await DriftService.saveProgressReminder(reminder);

      // Bildirimi zamanla
      if (isEnabled) {
        await _scheduleNotification(reminder);
      }

      debugPrint('✅ Progress reminder oluşturuldu: ${reminder.reminderId}');
      return reminder;
    } catch (e) {
      debugPrint('❌ Progress reminder oluşturma hatası: $e');
      rethrow;
    }
  }

  // Hatırlatmayı zamanla
  static Future<void> _scheduleNotification(ProgressReminderModel reminder) async {
    if (!reminder.isEnabled || !reminder.isActive) {
      return;
    }

    try {
      // Notification iznini kontrol et
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        debugPrint('⚠️ Notification izni verilmemiş');
        return;
      }

      final channelId = _channelIds[reminder.type] ?? _channelId;
      final scheduledDate = tz.TZDateTime.from(reminder.scheduledTime, tz.local);
      // Eğer zamanlanacak saat geçmişse, bir sonraki periyoda ayarla
      if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
        final nextTime = reminder.nextReminderTime;
        if (nextTime == null) {
          debugPrint('⚠️ Sonraki hatırlatma zamanı hesaplanamadı: ${reminder.reminderId}');
          return;
        }
        
        final nextScheduledDate = tz.TZDateTime.from(nextTime, tz.local);
        await _scheduleNotificationAtTime(reminder, nextScheduledDate, channelId);
      } else {
        await _scheduleNotificationAtTime(reminder, scheduledDate, channelId);
      }
      
      debugPrint('📅 Notification zamanlandı: ${reminder.reminderId} -> ${reminder.scheduledTime}');
    } catch (e) {
      debugPrint('❌ Notification zamanlama hatası: $e');
    }
  }

  // Belirli zamanda bildirim zamanla
  static Future<void> _scheduleNotificationAtTime(
    ProgressReminderModel reminder,
    tz.TZDateTime scheduledDate,
    String channelId,
  ) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      _getChannelName(reminder.type),
      channelDescription: _getChannelDescription(reminder.type),
      importance: _getImportance(reminder.priority),
      priority: _getPriority(reminder.priority),
      icon: 'ic_notification',
      enableVibration: true,
      playSound: true,
      styleInformation: BigTextStyleInformation(
        reminder.message,
        contentTitle: reminder.title,
        summaryText: reminder.description.isNotEmpty ? reminder.description : null,
      ),
      actions: _getNotificationActions(reminder.type),
    );

    const iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: 1,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    // Payload olarak reminder ID ve type gönder
    final payload = jsonEncode({
      'reminderId': reminder.reminderId,
      'type': reminder.type.name,
      'userId': reminder.userId,
    });

    await _localNotifications.zonedSchedule(
      reminder.notificationId,
      reminder.title,
      reminder.message,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.alarmClock, // exactAllowWhileIdle yerine alarmClock
      payload: payload,
    );
  }

  // Önem seviyesini al
  static Importance _getImportance(int priority) {
    switch (priority) {
      case 3:
        return Importance.max;
      case 2:
        return Importance.high;
      case 1:
      default:
        return Importance.defaultImportance;
    }
  }

  // Öncelik seviyesini al
  static Priority _getPriority(int priority) {
    switch (priority) {
      case 3:
        return Priority.max;
      case 2:
        return Priority.high;
      case 1:
      default:
        return Priority.defaultPriority;
    }
  }

  // Notification eylemlerini al
  static List<AndroidNotificationAction>? _getNotificationActions(ProgressReminderType type) {
    switch (type) {
      case ProgressReminderType.weightUpdate:
        return [
          const AndroidNotificationAction('update_weight', 'Kilo Güncelle'),
          const AndroidNotificationAction('remind_later', 'Daha Sonra'),
        ];
      case ProgressReminderType.dietAdherence:
        return [
          const AndroidNotificationAction('log_meals', 'Öğünleri Kaydet'),
          const AndroidNotificationAction('remind_later', 'Daha Sonra'),
        ];
      case ProgressReminderType.waterIntake:
        return [
          const AndroidNotificationAction('log_water', 'Su İç'),
          const AndroidNotificationAction('remind_later', 'Daha Sonra'),
        ];
      default:
        return [
          const AndroidNotificationAction('open_app', 'Uygulamayı Aç'),
          const AndroidNotificationAction('dismiss', 'Kapat'),
        ];
    }
  }

  // Aktif hatırlatmaları zamanla
  static Future<void> _scheduleActiveReminders() async {
    try {
      final currentUserId = AuthService.currentUserId;
      if (currentUserId == null) return;

      final activeReminders = await getActiveReminders(currentUserId);
      
      for (final reminder in activeReminders) {
        await _scheduleNotification(reminder);
      }
      
      debugPrint('🔄 ${activeReminders.length} aktif hatırlatma yeniden zamanlandı');
    } catch (e) {
      debugPrint('❌ Aktif hatırlatmaları zamanlama hatası: $e');
    }
  }

  // Kullanıcının aktif hatırlatmalarını al
  static Future<List<ProgressReminderModel>> getActiveReminders(String userId) async {
    try {
      return await DriftService.getActiveProgressReminders(userId);
    } catch (e) {
      debugPrint('❌ Aktif hatırlatmaları alma hatası: $e');
      return [];
    }
  }

  // Belirli tip hatırlatmaları al
  static Future<List<ProgressReminderModel>> getRemindersByType(
    String userId,
    ProgressReminderType type,
  ) async {
    try {
      return await DriftService.getProgressRemindersByType(userId, type);
    } catch (e) {
      debugPrint('❌ Tip hatırlatmaları alma hatası: $e');
      return [];
    }
  }

  // Hatırlatmayı güncelle
  static Future<void> updateReminder(ProgressReminderModel reminder) async {
    try {
      reminder.updatedAt = DateTime.now();
      
      await DriftService.saveProgressReminder(reminder);

      // Eğer etkinse, bildirimi yeniden zamanla
      if (reminder.isEnabled && reminder.isActive) {
        await _cancelNotification(reminder.notificationId);
        await _scheduleNotification(reminder);
      }
      
      debugPrint('✅ Progress reminder güncellendi: ${reminder.reminderId}');
    } catch (e) {
      debugPrint('❌ Progress reminder güncelleme hatası: $e');
    }
  }

  // Hatırlatmayı sil
  static Future<void> deleteReminder(String reminderId) async {
    try {
      final reminder = await DriftService.getProgressReminderByReminderId(reminderId);

      if (reminder == null) {
        debugPrint('⚠️ Silinecek hatırlatma bulunamadı: $reminderId');
        return;
      }

      // Bildirimi iptal et
      await _cancelNotification(reminder.notificationId);

      // Veritabanından sil
      await DriftService.deleteProgressReminder(reminder.id);

      debugPrint('✅ Progress reminder silindi: $reminderId');
    } catch (e) {
      debugPrint('❌ Progress reminder silme hatası: $e');
    }
  }

  // Bildirimi iptal et
  static Future<void> _cancelNotification(int notificationId) async {
    try {
      await _localNotifications.cancel(notificationId);
      debugPrint('🚫 Notification iptal edildi: $notificationId');
    } catch (e) {
      debugPrint('❌ Notification iptal etme hatası: $e');
    }
  }

  // Kullanıcının tüm hatırlatmalarını iptal et
  static Future<void> cancelAllReminders(String userId) async {
    try {
      final reminders = await DriftService.getUserProgressReminders(userId);

      for (final reminder in reminders) {
        await _cancelNotification(reminder.notificationId);
        reminder.isEnabled = false;
        reminder.status = ProgressReminderStatus.cancelled;
        reminder.updatedAt = DateTime.now();
      }

      await DriftService.saveProgressReminders(reminders);

      debugPrint('🚫 Kullanıcının tüm hatırlatmaları iptal edildi: $userId');
    } catch (e) {
      debugPrint('❌ Tüm hatırlatmaları iptal etme hatası: $e');
    }
  }

  // Hatırlatmayı tamamla
  static Future<void> completeReminder(String reminderId, String? userResponse) async {
    try {
      final reminder = await DriftService.getProgressReminderByReminderId(reminderId);

      if (reminder == null) {
        debugPrint('⚠️ Tamamlanacak hatırlatma bulunamadı: $reminderId');
        return;
      }

      reminder.markAsCompleted(userResponse);
      
      await DriftService.saveProgressReminder(reminder);

      // Sonraki hatırlatmayı zamanla (eğer tekrarlayan ise)
      await _scheduleNextReminder(reminder);

      debugPrint('✅ Progress reminder tamamlandı: $reminderId');
    } catch (e) {
      debugPrint('❌ Progress reminder tamamlama hatası: $e');
    }
  }

  // Sonraki hatırlatmayı zamanla
  static Future<void> _scheduleNextReminder(ProgressReminderModel completedReminder) async {
    try {
      final nextTime = completedReminder.nextReminderTime;
      if (nextTime == null || !completedReminder.isEnabled) {
        return;
      }

      // Yeni hatırlatma oluştur
      final nextReminder = ProgressReminderModel.create(
        userId: completedReminder.userId,
        type: completedReminder.type,
        title: completedReminder.title,
        message: completedReminder.message,
        dietitianId: completedReminder.dietitianId,
        frequency: completedReminder.frequency,
        description: completedReminder.description,
        scheduledTime: nextTime,
        isEnabled: completedReminder.isEnabled,
        customIntervalDays: completedReminder.customIntervalDays,
        reminderDays: completedReminder.reminderDays,
        priority: completedReminder.priority,
        tags: completedReminder.tags,
        assignmentId: completedReminder.assignmentId,
        packageId: completedReminder.packageId,
        targetValues: completedReminder.targetValues,
        maxReminders: completedReminder.maxReminders,
      );

      await DriftService.saveProgressReminder(nextReminder);

      await _scheduleNotification(nextReminder);

      debugPrint('📅 Sonraki hatırlatma zamanlandı: ${nextReminder.reminderId}');
    } catch (e) {
      debugPrint('❌ Sonraki hatırlatma zamanlama hatası: $e');
    }
  }

  // Otomatik progress reminderları oluştur
  static Future<void> createDefaultRemindersForUser(String userId, {String? assignmentId}) async {
    try {
      // Kilo güncellemesi - haftalık
      await createProgressReminder(
        userId: userId,
        type: ProgressReminderType.weightUpdate,
        title: '⚖️ Kilo Güncellemesi',
        message: 'Bu haftaki kilonuzu kaydetmeyi unutmayın!',
        frequency: ProgressReminderFrequency.weekly,
        description: 'Düzenli kilo takibi diyet başarınız için önemlidir.',
        scheduledTime: _getNextWeeklyTime([1]), // Pazartesi
        reminderDays: [1], // Pazartesi
        priority: 2,
        assignmentId: assignmentId,
        targetValues: {'target_weight': '0', 'current_weight': '0'},
      );

      // Diyet uyum kontrolü - haftalık
      await createProgressReminder(
        userId: userId,
        type: ProgressReminderType.dietAdherence,
        title: '🥗 Diyet Uyum Kontrolü',
        message: 'Bu hafta diyet planınıza ne kadar uyum gösterdiniz?',
        frequency: ProgressReminderFrequency.weekly,
        description: 'Diyet uyumunuzu değerlendirin ve hedeflerinizi gözden geçirin.',
        scheduledTime: _getNextWeeklyTime([7]), // Pazar
        reminderDays: [7], // Pazar
        priority: 2,
        assignmentId: assignmentId,
        targetValues: {'adherence_target': '80'},
      );

      // Aylık değerlendirme
      await createProgressReminder(
        userId: userId,
        type: ProgressReminderType.monthlyAssessment,
        title: '📈 Aylık Değerlendirme',
        message: 'Aylık sağlık değerlendirmesi zamanı!',
        frequency: ProgressReminderFrequency.monthly,
        description: 'Genel sağlık durumunuzu değerlendirin ve hedeflerinizi güncelleyin.',
        scheduledTime: _getNextMonthlyTime(),
        priority: 3,
        assignmentId: assignmentId,
      );

      debugPrint('✅ Kullanıcı için varsayılan progress reminderlar oluşturuldu: $userId');
    } catch (e) {
      debugPrint('❌ Varsayılan progress reminderlar oluşturma hatası: $e');
    }
  }

  // Sonraki haftalık zamanı hesapla
  static DateTime _getNextWeeklyTime(List<int> days) {
    final now = DateTime.now();
    final today = now.weekday;
    
    // İlk uygun günü bul
    for (final day in days) {
      if (day > today) {
        final daysToAdd = day - today;
        return DateTime(now.year, now.month, now.day + daysToAdd, 9, 0); // Sabah 9
      }
    }
    
    // Bu hafta uygun gün yoksa, gelecek haftanın ilk gününe ayarla
    final firstDay = days.first;
    final daysToAdd = (7 - today) + firstDay;
    return DateTime(now.year, now.month, now.day + daysToAdd, 9, 0);
  }

  // Sonraki aylık zamanı hesapla
  static DateTime _getNextMonthlyTime() {
    final now = DateTime.now();
    final nextMonth = DateTime(now.year, now.month + 1, 1, 10, 0); // Ayın ilk günü sabah 10
    return nextMonth;
  }

  // Battery optimization kontrolü
  static Future<bool> checkBatteryOptimization() async {
    try {
      // Android için battery optimization kontrolü yapılabilir
      if (defaultTargetPlatform == TargetPlatform.android) {
        final status = await Permission.ignoreBatteryOptimizations.status;
        return status.isGranted;
      }
      return true; // iOS için varsayılan olarak true
    } catch (e) {
      debugPrint('❌ Battery optimization kontrolü hatası: $e');
      return false;
    }
  }

  // Battery optimization ayarlarına git
  static Future<void> requestBatteryOptimizationDisabled() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    } catch (e) {
      debugPrint('❌ Battery optimization izni isteme hatası: $e');
    }
  }

  // İstatistik verileri
  static Future<Map<String, dynamic>> getUserReminderStats(String userId) async {
    try {
      final reminders = await DriftService.getUserProgressReminders(userId);

      final total = reminders.length;
      final active = reminders.where((r) => r.isActive).length;
      final completed = reminders.where((r) => r.status == ProgressReminderStatus.completed).length;
      final missed = reminders.where((r) => r.status == ProgressReminderStatus.missed).length;
      
      final completionRate = total > 0 ? (completed / total * 100).toInt() : 0;

      return {
        'total': total,
        'active': active,
        'completed': completed,
        'missed': missed,
        'completionRate': completionRate,
        'byType': _getReminderCountsByType(reminders),
      };
    } catch (e) {
      debugPrint('❌ Kullanıcı hatırlatma istatistikleri alma hatası: $e');
      return {};
    }
  }

  // Tip bazında hatırlatma sayıları
  static Map<String, int> _getReminderCountsByType(List<ProgressReminderModel> reminders) {
    final counts = <String, int>{};
    
    for (final type in ProgressReminderType.values) {
      counts[type.name] = reminders.where((r) => r.type == type).length;
    }
    
    return counts;
  }
}