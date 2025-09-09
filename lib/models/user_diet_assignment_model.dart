import 'package:flutter/material.dart';
import 'delivery_schedule_model.dart';

enum AssignmentStatus {
  active,       // aktif
  paused,       // durdurulmuş
  completed,    // tamamlanmış
  cancelled,    // iptal edilmiş
  expired,      // süresi dolmuş
}
class UserDietAssignmentModel {
  

  
  late String assignmentId;

  
  late String userId; // atanan kullanıcı

  
  late String packageId; // diyet paketi ID

  
  late String dietitianId; // atayan diyetisyen

  // Tarih bilgileri
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();
  
  
  AssignmentStatus status = AssignmentStatus.active;

  // İlerleme takibi
  double progress = 0.0; // 0.0 - 1.0 arası
  int completedDays = 0;
  int totalDays = 0;

  // Kişiye özel ayarlar (JSON string olarak saklanacak)
  String customSettings = '{}'; // {"dailyCalories": 1800, "waterGoal": 2.5}

  // Notlar ve geri bildirimler
  String? dietitianNotes; // diyetisyenin notları
  String? userNotes;      // kullanıcının notları
  
  // İstatistikler
  double weightStart = 0.0; // başlangıç kilosu
  double weightCurrent = 0.0; // güncel kilo
  double weightTarget = 0.0;  // hedef kilo
  
  // Uyum skorları
  int adherenceScore = 0; // 0-100 arası uyum skoru
  int missedDays = 0;     // kaçırılan gün sayısı
  
  // Değerlendirme
  double userRating = 0.0; // kullanıcının pakete verdiği puan
  String? userReview;      // kullanıcı yorumu
  bool isReviewed = false;
  
  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
  DateTime? lastActivityAt; // son aktivite tarihi
  
  // PDF ve kontrol tarihleri
  DateTime? nextCheckDate; // bir sonraki kontrol tarihi
  String? generatedPdfPath; // oluşturulan PDF dosya yolu
  DateTime? pdfGeneratedAt; // PDF oluşturulma tarihi
  
  // Otomatik teslimat zamanlaması
  late DeliverySchedule deliverySchedule;

  UserDietAssignmentModel() {
    deliverySchedule = DeliverySchedule.weekly(days: [WeekDay.monday, WeekDay.wednesday, WeekDay.friday]);
  }

  UserDietAssignmentModel.create({
    required this.assignmentId,
    required this.userId,
    required this.packageId,
    required this.dietitianId,
    required this.startDate,
    required this.endDate,
    this.status = AssignmentStatus.active,
    this.progress = 0.0,
    this.customSettings = '{}',
    this.dietitianNotes,
    this.userNotes,
    this.weightStart = 0.0,
    this.weightCurrent = 0.0,
    this.weightTarget = 0.0,
    this.adherenceScore = 0,
    DeliverySchedule? schedule,
  }) {
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
    totalDays = endDate.difference(startDate).inDays;
    deliverySchedule = schedule ?? DeliverySchedule.weekly(days: [WeekDay.monday, WeekDay.wednesday, WeekDay.friday]);
    _calculateProgress();
  }

  // İlerlemeyi hesapla
  void _calculateProgress() {
    final now = DateTime.now();
    if (now.isBefore(startDate)) {
      progress = 0.0;
      completedDays = 0;
    } else if (now.isAfter(endDate)) {
      progress = 1.0;
      completedDays = totalDays;
      if (status == AssignmentStatus.active) {
        status = AssignmentStatus.expired;
      }
    } else {
      completedDays = now.difference(startDate).inDays;
      progress = totalDays > 0 ? completedDays / totalDays : 0.0;
    }
  }

  // Firestore için Map dönüşümü
  Map<String, dynamic> toMap() {
    _calculateProgress(); // güncel ilerlemeyi hesapla
    
    return {
      'assignmentId': assignmentId,
      'userId': userId,
      'packageId': packageId,
      'dietitianId': dietitianId,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'status': status.name,
      'progress': progress,
      'completedDays': completedDays,
      'totalDays': totalDays,
      'customSettings': customSettings,
      'dietitianNotes': dietitianNotes,
      'userNotes': userNotes,
      'weightStart': weightStart,
      'weightCurrent': weightCurrent,
      'weightTarget': weightTarget,
      'adherenceScore': adherenceScore,
      'missedDays': missedDays,
      'userRating': userRating,
      'userReview': userReview,
      'isReviewed': isReviewed,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'lastActivityAt': lastActivityAt?.millisecondsSinceEpoch,
      'nextCheckDate': nextCheckDate?.millisecondsSinceEpoch,
      'generatedPdfPath': generatedPdfPath,
      'pdfGeneratedAt': pdfGeneratedAt?.millisecondsSinceEpoch,
      'deliverySchedule': deliverySchedule.toMap(),
    };
  }

  // Firestore'dan Map dönüşümü
  factory UserDietAssignmentModel.fromMap(Map<String, dynamic> map) {
    return UserDietAssignmentModel.create(
      assignmentId: map['assignmentId'] ?? '',
      userId: map['userId'] ?? '',
      packageId: map['packageId'] ?? '',
      dietitianId: map['dietitianId'] ?? '',
      startDate: DateTime.fromMillisecondsSinceEpoch(
        map['startDate'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      endDate: DateTime.fromMillisecondsSinceEpoch(
        map['endDate'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      status: AssignmentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => AssignmentStatus.active,
      ),
      customSettings: map['customSettings'] ?? '{}',
      dietitianNotes: map['dietitianNotes'],
      userNotes: map['userNotes'],
      weightStart: (map['weightStart'] ?? 0.0).toDouble(),
      weightCurrent: (map['weightCurrent'] ?? 0.0).toDouble(),
      weightTarget: (map['weightTarget'] ?? 0.0).toDouble(),
      adherenceScore: map['adherenceScore'] ?? 0,
      schedule: map['deliverySchedule'] != null 
          ? DeliverySchedule.fromMap(map['deliverySchedule'])
          : null,
    )
      ..progress = (map['progress'] ?? 0.0).toDouble()
      ..completedDays = map['completedDays'] ?? 0
      ..totalDays = map['totalDays'] ?? 0
      ..missedDays = map['missedDays'] ?? 0
      ..userRating = (map['userRating'] ?? 0.0).toDouble()
      ..userReview = map['userReview']
      ..isReviewed = map['isReviewed'] ?? false
      ..createdAt = DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      )
      ..updatedAt = DateTime.fromMillisecondsSinceEpoch(
        map['updatedAt'] ?? DateTime.now().millisecondsSinceEpoch,
      )
      ..lastActivityAt = map['lastActivityAt'] != null
        ? DateTime.fromMillisecondsSinceEpoch(map['lastActivityAt'])
        : null
      ..nextCheckDate = map['nextCheckDate'] != null
        ? DateTime.fromMillisecondsSinceEpoch(map['nextCheckDate'])
        : null
      ..generatedPdfPath = map['generatedPdfPath']
      ..pdfGeneratedAt = map['pdfGeneratedAt'] != null
        ? DateTime.fromMillisecondsSinceEpoch(map['pdfGeneratedAt'])
        : null;
  }

  // Durum görüntüleme adı
  String get statusDisplayName {
    switch (status) {
      case AssignmentStatus.active:
        return 'Aktif';
      case AssignmentStatus.paused:
        return 'Durdurulmuş';
      case AssignmentStatus.completed:
        return 'Tamamlandı';
      case AssignmentStatus.cancelled:
        return 'İptal Edildi';
      case AssignmentStatus.expired:
        return 'Süresi Doldu';
    }
  }

  // Kalan gün sayısı
  int get remainingDays {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays;
  }

  // İlerleme yüzdesi
  String get progressPercentage {
    return '${(progress * 100).toStringAsFixed(0)}%';
  }

  // Aktif mi kontrol et
  bool get isActive {
    return status == AssignmentStatus.active && 
           DateTime.now().isBefore(endDate);
  }

  // Kilo değişimi
  double get weightChange {
    if (weightStart == 0.0 || weightCurrent == 0.0) return 0.0;
    return weightCurrent - weightStart;
  }

  // Kilo değişimi metni
  String get weightChangeText {
    final change = weightChange;
    if (change == 0.0) return 'Değişim yok';
    if (change > 0) return '+${change.toStringAsFixed(1)} kg';
    return '${change.toStringAsFixed(1)} kg';
  }

  // Hedefe ne kadar kaldı
  double get remainingToTarget {
    if (weightTarget == 0.0 || weightCurrent == 0.0) return 0.0;
    return weightTarget - weightCurrent;
  }

  // Uyum skoru rengi
  Color get adherenceScoreColor {
    if (adherenceScore >= 80) return Colors.green;
    if (adherenceScore >= 60) return Colors.orange;
    return Colors.red;
  }
  
  // Delivery Schedule helper methods
  
  // Bir sonraki teslimat zamanı
  DateTime? get nextDeliveryTime {
    return deliverySchedule.nextDeliveryTime;
  }
  
  // Teslimat zamanlaması aktif mi
  bool get isDeliveryActive {
    return deliverySchedule.status == ScheduleStatus.active && isActive;
  }
  
  // Teslimat zamanlamasını güncelle
  void updateDeliverySchedule() {
    if (isActive) {
      deliverySchedule.nextDeliveryTime = deliverySchedule.calculateNextDelivery();
      updatedAt = DateTime.now();
    }
  }
  
  // Teslimat zamanlamasını duraklat
  void pauseDeliverySchedule() {
    deliverySchedule.pause();
    updatedAt = DateTime.now();
  }
  
  // Teslimat zamanlamasını devam ettir
  void resumeDeliverySchedule() {
    deliverySchedule.resume();
    updatedAt = DateTime.now();
  }
  
  // Teslimat tamamlandığını kaydet
  void recordDelivery({bool success = true}) {
    deliverySchedule.recordDelivery(success: success);
    lastActivityAt = DateTime.now();
    updatedAt = DateTime.now();
    
    // Başarısız teslimatları missed days'e ekle
    if (!success) {
      missedDays++;
      // Uyum skorunu güncelle
      _updateAdherenceScore();
    }
  }
  
  // Uyum skorunu güncelle
  void _updateAdherenceScore() {
    final successRate = deliverySchedule.successRate;
    adherenceScore = (successRate * 100).round();
  }
  
  // Teslimat istatistikleri
  Map<String, dynamic> get deliveryStats {
    return {
      'totalDeliveries': deliverySchedule.totalDeliveries,
      'failedDeliveries': deliverySchedule.failedDeliveries,
      'successRate': deliverySchedule.successRate,
      'nextDeliveryTime': nextDeliveryTime?.toIso8601String(),
      'lastDeliveryTime': deliverySchedule.lastDeliveryTime?.toIso8601String(),
      'scheduleDisplayText': deliverySchedule.displayText,
      'isActive': isDeliveryActive,
    };
  }
}