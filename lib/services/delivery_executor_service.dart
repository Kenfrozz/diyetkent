import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/user_diet_assignment_model.dart';
import '../database/drift_service.dart';
import 'background_scheduler_service.dart';
import 'notification_service.dart';
import 'cloud_functions_service.dart';

enum DeliveryResult {
  success,
  failed,
  skipped,
  rescheduled,
}

class DeliveryExecutorService {
  static final DeliveryExecutorService _instance = DeliveryExecutorService._internal();
  factory DeliveryExecutorService() => _instance;
  DeliveryExecutorService._internal();

  final BackgroundSchedulerService _schedulerService = BackgroundSchedulerService();
  final NotificationService _notificationService = NotificationService();
  final CloudFunctionsService _cloudService = CloudFunctionsService();
  
  StreamSubscription<SchedulerEvent>? _schedulerEventSubscription;

  Future<void> initialize() async {
    _schedulerEventSubscription = _schedulerService.eventStream?.listen(
      _handleSchedulerEvent,
    );
    
    await _notificationService.initialize();
    await _cloudService.initialize(enabled: true);
    await _schedulerService.startScheduler();
    await _loadActiveAssignments();
  }

  Future<void> dispose() async {
    await _schedulerEventSubscription?.cancel();
    await _schedulerService.stopScheduler();
  }

  void _handleSchedulerEvent(SchedulerEvent event) {
    switch (event.type) {
      case 'delivery_triggered':
        final assignmentId = event.data['assignmentId'] as String;
        _executeDelivery(assignmentId);
        break;
        
      case 'error':
        final error = event.data['error'] as String;
        debugPrint('⚠️ Scheduler hatası: $error');
        break;
    }
  }

  Future<void> _executeDelivery(String assignmentId) async {
    try {
      debugPrint('🚀 Teslimat yürütülüyor: $assignmentId');
      
      final assignment = await DriftService.getAssignmentById(assignmentId);
      if (assignment == null) {
        debugPrint('❌ Assignment bulunamadı: $assignmentId');
        return;
      }

      final result = await _performDelivery(assignment);
      
      // Sonucu kaydet
      assignment.recordDelivery(success: result == DeliveryResult.success);
      
      // Veritabanını güncelle
      await DriftService.updateAssignment(assignment);
      
      // Scheduler'ı bilgilendir
      if (result == DeliveryResult.success || result == DeliveryResult.rescheduled) {
        await _schedulerService.updateSchedule(assignmentId);
      }
      
      debugPrint('✅ Teslimat tamamlandı: $assignmentId - $result');
      
    } catch (e) {
      debugPrint('❌ Teslimat hatası: $assignmentId - $e');
    }
  }

  Future<DeliveryResult> _performDelivery(UserDietAssignmentModel assignment) async {
    try {
      // Teslimat önkoşullarını kontrol et
      if (!assignment.isActive) {
        return DeliveryResult.skipped;
      }

      if (assignment.nextDeliveryTime == null) {
        return DeliveryResult.skipped;
      }

      // Teslimat mantığı - bu kısım business logic'e göre özelleştirilmeli
      final deliveryData = await _prepareDeliveryData(assignment);
      
      // Cloud function ile teslimat schedule et
      if (_cloudService.isEnabled) {
        final cloudResult = await _cloudService.scheduleDelivery(
          assignmentId: assignment.assignmentId,
          deliveryTime: DateTime.now(),
          deliveryData: deliveryData,
        );
        
        if (!cloudResult.success) {
          debugPrint('⚠️ Cloud delivery failed, using local fallback');
        }
      }
      
      // Notification gönder
      await _notificationService.showDeliveryNotification(
        assignmentId: assignment.assignmentId,
        title: 'Diyet Teslimatı',
        body: 'Günlük diyet planınız hazır!',
      );
      
      // Gerçek teslimat işlemi (örn: PDF oluşturma, e-posta gönderme, push notification)
      final success = await _sendDelivery(assignment, deliveryData);
      
      return success ? DeliveryResult.success : DeliveryResult.failed;
      
    } catch (e) {
      debugPrint('Teslimat işlemi hatası: $e');
      return DeliveryResult.failed;
    }
  }

  Future<Map<String, dynamic>> _prepareDeliveryData(UserDietAssignmentModel assignment) async {
    // Teslimat için gerekli verileri hazırla
    return {
      'assignmentId': assignment.assignmentId,
      'userId': assignment.userId,
      'packageId': assignment.packageId,
      'deliveryTime': DateTime.now().toIso8601String(),
      'progress': assignment.progress,
      'customSettings': assignment.customSettings,
      'deliveryType': assignment.deliverySchedule.rule.name,
    };
  }

  Future<bool> _sendDelivery(UserDietAssignmentModel assignment, Map<String, dynamic> data) async {
    try {
      // Burada gerçek teslimat işlemleri yapılır:
      // 1. Push notification gönderme
      // 2. E-posta gönderme  
      // 3. PDF oluşturma
      // 4. SMS gönderme vb.
      
      // Şimdilik simüle edilmiş başarılı teslimat
      await Future.delayed(const Duration(seconds: 2));
      
      // %95 başarı oranı simülasyonu
      return DateTime.now().millisecond % 100 > 5;
      
    } catch (e) {
      debugPrint('Teslimat gönderimi hatası: $e');
      return false;
    }
  }

  Future<void> _loadActiveAssignments() async {
    try {
      final activeAssignments = await DriftService.getAllActiveAssignments();
      
      debugPrint('📋 ${activeAssignments.length} aktif assignment yüklendi');
      
      // Scheduler'ı güncel verilerle bilgilendir
      await _schedulerService.refreshSchedules();
      
    } catch (e) {
      debugPrint('❌ Aktif assignment yükleme hatası: $e');
    }
  }

  // Manuel teslimat tetikleme
  Future<DeliveryResult> triggerManualDelivery(String assignmentId) async {
    try {
      final assignment = await DriftService.getAssignmentById(assignmentId);
      if (assignment == null) {
        return DeliveryResult.failed;
      }

      final result = await _performDelivery(assignment);
      
      // Manuel tetiklenen teslimatları da kaydet
      assignment.recordDelivery(success: result == DeliveryResult.success);
      assignment.lastActivityAt = DateTime.now();
      
      await DriftService.updateAssignment(assignment);
      
      return result;
      
    } catch (e) {
      debugPrint('Manuel teslimat hatası: $e');
      return DeliveryResult.failed;
    }
  }

  // Toplu teslimat işlemleri
  Future<Map<String, DeliveryResult>> triggerBulkDelivery(List<String> assignmentIds) async {
    final results = <String, DeliveryResult>{};
    
    for (final assignmentId in assignmentIds) {
      results[assignmentId] = await triggerManualDelivery(assignmentId);
      
      // Bulk işlemlerde kısa gecikme ekle
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    return results;
  }

  // Teslimat zamanlamasını yeniden hesapla
  Future<void> recalculateSchedules() async {
    try {
      final activeAssignments = await DriftService.getAllActiveAssignments();
      
      for (final assignment in activeAssignments) {
        assignment.updateDeliverySchedule();
        await DriftService.updateAssignment(assignment);
        await _schedulerService.updateSchedule(assignment.assignmentId);
      }
      
      debugPrint('♻️ ${activeAssignments.length} schedule yeniden hesaplandı');
      
    } catch (e) {
      debugPrint('❌ Schedule yeniden hesaplama hatası: $e');
    }
  }

  // İstatistikler ve raporlama
  Future<DeliveryStats> getDeliveryStats() async {
    try {
      final allAssignments = await DriftService.getAllAssignments();
      
      int totalDeliveries = 0;
      int successfulDeliveries = 0;
      int failedDeliveries = 0;
      
      for (final assignment in allAssignments) {
        totalDeliveries += assignment.deliverySchedule.totalDeliveries;
        successfulDeliveries += (assignment.deliverySchedule.totalDeliveries - assignment.deliverySchedule.failedDeliveries);
        failedDeliveries += assignment.deliverySchedule.failedDeliveries;
      }
      
      return DeliveryStats(
        totalDeliveries: totalDeliveries,
        successfulDeliveries: successfulDeliveries,
        failedDeliveries: failedDeliveries,
        activeSchedules: allAssignments.where((a) => a.isDeliveryActive).length,
        totalSchedules: allAssignments.length,
      );
      
    } catch (e) {
      debugPrint('❌ İstatistik hesaplama hatası: $e');
      return DeliveryStats.empty();
    }
  }
}

// İstatistik veri sınıfı
class DeliveryStats {
  final int totalDeliveries;
  final int successfulDeliveries;  
  final int failedDeliveries;
  final int activeSchedules;
  final int totalSchedules;

  DeliveryStats({
    required this.totalDeliveries,
    required this.successfulDeliveries,
    required this.failedDeliveries,
    required this.activeSchedules,
    required this.totalSchedules,
  });

  factory DeliveryStats.empty() => DeliveryStats(
    totalDeliveries: 0,
    successfulDeliveries: 0,
    failedDeliveries: 0,
    activeSchedules: 0,
    totalSchedules: 0,
  );

  double get successRate => totalDeliveries > 0 ? successfulDeliveries / totalDeliveries : 0.0;
  double get failureRate => totalDeliveries > 0 ? failedDeliveries / totalDeliveries : 0.0;

  Map<String, dynamic> toMap() => {
    'totalDeliveries': totalDeliveries,
    'successfulDeliveries': successfulDeliveries,
    'failedDeliveries': failedDeliveries,
    'activeSchedules': activeSchedules,
    'totalSchedules': totalSchedules,
    'successRate': successRate,
    'failureRate': failureRate,
  };

  @override
  String toString() => 'DeliveryStats(total: $totalDeliveries, success: $successfulDeliveries, failed: $failedDeliveries, active: $activeSchedules)';
}