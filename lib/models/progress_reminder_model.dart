import 'dart:convert';
import 'package:uuid/uuid.dart';

enum ProgressReminderType {
  weightUpdate,      // Kilo güncellemesi
  dietAdherence,     // Diyet uyum kontrolü
  milestone,         // Kilometre taşı
  weeklyProgress,    // Haftalık ilerleme
  monthlyAssessment, // Aylık değerlendirme
  waterIntake,       // Su tüketimi
  exerciseLog,       // Egzersiz kaydı
  moodTracker,       // Ruh hali takibi
}

enum ProgressReminderFrequency {
  daily,       // Günlük
  weekly,      // Haftalık
  biweekly,    // İki haftada bir
  monthly,     // Aylık
  custom,      // Özel periyot
}

enum ProgressReminderStatus {
  scheduled,   // Zamanlanmış
  delivered,   // Teslim edilmiş
  completed,   // Kullanıcı tarafından tamamlanmış
  dismissed,   // Göz ardı edilmiş
  missed,      // Kaçırılmış
  cancelled,   // İptal edilmiş
}

class ProgressReminderModel {
  late String reminderId;
  late String userId;
  String? dietitianId; // Diyetisyen tarafından belirlenmişse

  // Hatırlatma tipi ve sıklığı
  late ProgressReminderType type;
  ProgressReminderFrequency frequency = ProgressReminderFrequency.weekly;

  // İçerik ve mesaj
  String title = '';
  String message = '';
  String description = '';

  // Zamanlama bilgileri
  DateTime scheduledTime = DateTime.now();
  DateTime? deliveredAt;
  DateTime? completedAt;
  DateTime? dismissedAt;

  // Durum bilgisi
  ProgressReminderStatus status = ProgressReminderStatus.scheduled;

  // Ayarlar
  bool isEnabled = true;
  int notificationId = 0; // Local notification ID
  
  // Tekrar ayarları
  int? customIntervalDays; // Özel periyot için gün sayısı
  List<int> reminderDays = <int>[]; // Hangi günlerde hatırlatılacak (1=Pazartesi, 7=Pazar)
  
  // Öncelik ve kategoriler
  int priority = 1; // 1 = düşük, 2 = orta, 3 = yüksek
  List<String> tags = <String>[];

  // İlişkili veriler
  String? assignmentId; // Diyet ataması ID'si
  String? packageId;    // Diyet paketi ID'si
  
  // Hedef değerler (kilo hedefi, su tüketimi vb.) - JSON string olarak saklanan
  String targetValuesJson = '{}';
  
  // Kullanıcı etkileşimi
  int reminderCount = 0; // Kaç kez hatırlatıldı
  int maxReminders = 3;  // Maksimum hatırlatma sayısı
  
  // Analitik veriler
  String? userResponse; // Kullanıcı yanıtı
  double? progressValue; // İlerleme değeri (0.0-1.0)
  
  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();

  // UUID generator (static)
  static final _uuid = const Uuid();

  ProgressReminderModel();

  ProgressReminderModel.create({
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.dietitianId,
    this.frequency = ProgressReminderFrequency.weekly,
    this.description = '',
    DateTime? scheduledTime,
    this.isEnabled = true,
    this.customIntervalDays,
    this.reminderDays = const <int>[],
    this.priority = 1,
    this.tags = const <String>[],
    this.assignmentId,
    this.packageId,
    this.maxReminders = 3,
    Map<String, String>? targetValues,
  }) {
    reminderId = _uuid.v4();
    this.scheduledTime = scheduledTime ?? DateTime.now().add(const Duration(hours: 1));
    targetValuesJson = jsonEncode(targetValues ?? <String, String>{});
    notificationId = DateTime.now().millisecondsSinceEpoch % 2147483647; // Int32 max
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
  }

  // Firebase için Map dönüşümü
  Map<String, dynamic> toMap() {
    return {
      'reminderId': reminderId,
      'userId': userId,
      'dietitianId': dietitianId,
      'type': type.name,
      'frequency': frequency.name,
      'title': title,
      'message': message,
      'description': description,
      'scheduledTime': scheduledTime.millisecondsSinceEpoch,
      'deliveredAt': deliveredAt?.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'dismissedAt': dismissedAt?.millisecondsSinceEpoch,
      'status': status.name,
      'isEnabled': isEnabled,
      'notificationId': notificationId,
      'customIntervalDays': customIntervalDays,
      'reminderDays': reminderDays,
      'priority': priority,
      'tags': tags,
      'assignmentId': assignmentId,
      'packageId': packageId,
      'targetValues': jsonDecode(targetValuesJson),
      'reminderCount': reminderCount,
      'maxReminders': maxReminders,
      'userResponse': userResponse,
      'progressValue': progressValue,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  // Firebase'den Map dönüşümü
  factory ProgressReminderModel.fromMap(Map<String, dynamic> map) {
    return ProgressReminderModel.create(
      userId: map['userId'] ?? '',
      type: ProgressReminderType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ProgressReminderType.weightUpdate,
      ),
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      dietitianId: map['dietitianId'],
      frequency: ProgressReminderFrequency.values.firstWhere(
        (e) => e.name == map['frequency'],
        orElse: () => ProgressReminderFrequency.weekly,
      ),
      description: map['description'] ?? '',
      scheduledTime: map['scheduledTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['scheduledTime'])
          : DateTime.now(),
      isEnabled: map['isEnabled'] ?? true,
      customIntervalDays: map['customIntervalDays'],
      reminderDays: List<int>.from(map['reminderDays'] ?? []),
      priority: map['priority'] ?? 1,
      tags: List<String>.from(map['tags'] ?? []),
      assignmentId: map['assignmentId'],
      packageId: map['packageId'],
      maxReminders: map['maxReminders'] ?? 3,
      targetValues: Map<String, String>.from(map['targetValues'] ?? {}),
    )
      ..reminderId = map['reminderId'] ?? _uuid.v4()
      ..deliveredAt = map['deliveredAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['deliveredAt'])
          : null
      ..completedAt = map['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'])
          : null
      ..dismissedAt = map['dismissedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['dismissedAt'])
          : null
      ..status = ProgressReminderStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ProgressReminderStatus.scheduled,
      )
      ..notificationId = map['notificationId'] ?? 0
      ..reminderCount = map['reminderCount'] ?? 0
      ..userResponse = map['userResponse']
      ..progressValue = map['progressValue']?.toDouble()
      ..targetValuesJson = jsonEncode(map['targetValues'] ?? {})
      ..createdAt = DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      )
      ..updatedAt = DateTime.fromMillisecondsSinceEpoch(
        map['updatedAt'] ?? DateTime.now().millisecondsSinceEpoch,
      );
  }

  // Hatırlatma tipi görüntüleme adı
  String get typeDisplayName {
    switch (type) {
      case ProgressReminderType.weightUpdate:
        return 'Kilo Güncellemesi';
      case ProgressReminderType.dietAdherence:
        return 'Diyet Uyum Kontrolü';
      case ProgressReminderType.milestone:
        return 'Kilometre Taşı';
      case ProgressReminderType.weeklyProgress:
        return 'Haftalık İlerleme';
      case ProgressReminderType.monthlyAssessment:
        return 'Aylık Değerlendirme';
      case ProgressReminderType.waterIntake:
        return 'Su Tüketimi';
      case ProgressReminderType.exerciseLog:
        return 'Egzersiz Kaydı';
      case ProgressReminderType.moodTracker:
        return 'Ruh Hali Takibi';
    }
  }

  // Sıklık görüntüleme adı
  String get frequencyDisplayName {
    switch (frequency) {
      case ProgressReminderFrequency.daily:
        return 'Günlük';
      case ProgressReminderFrequency.weekly:
        return 'Haftalık';
      case ProgressReminderFrequency.biweekly:
        return 'İki Haftada Bir';
      case ProgressReminderFrequency.monthly:
        return 'Aylık';
      case ProgressReminderFrequency.custom:
        return customIntervalDays != null
            ? '$customIntervalDays Günde Bir'
            : 'Özel';
    }
  }

  // Durum görüntüleme adı
  String get statusDisplayName {
    switch (status) {
      case ProgressReminderStatus.scheduled:
        return 'Zamanlanmış';
      case ProgressReminderStatus.delivered:
        return 'Teslim Edilmiş';
      case ProgressReminderStatus.completed:
        return 'Tamamlanmış';
      case ProgressReminderStatus.dismissed:
        return 'Göz Ardı Edilmiş';
      case ProgressReminderStatus.missed:
        return 'Kaçırılmış';
      case ProgressReminderStatus.cancelled:
        return 'İptal Edilmiş';
    }
  }

  // Öncelik seviye adı
  String get priorityLevelName {
    switch (priority) {
      case 1:
        return 'Düşük';
      case 2:
        return 'Orta';
      case 3:
        return 'Yüksek';
      default:
        return 'Bilinmiyor';
    }
  }

  // Aktif hatırlatma mı kontrol et
  bool get isActive {
    return isEnabled && 
           status == ProgressReminderStatus.scheduled &&
           reminderCount < maxReminders &&
           scheduledTime.isAfter(DateTime.now().subtract(const Duration(days: 1)));
  }

  // Hatırlatma zamanının geçip geçmediği
  bool get isOverdue {
    return status == ProgressReminderStatus.scheduled && 
           scheduledTime.isBefore(DateTime.now());
  }

  // Bir sonraki hatırlatma zamanını hesapla
  DateTime? get nextReminderTime {
    if (!isEnabled || reminderCount >= maxReminders) return null;

    DateTime base = completedAt ?? deliveredAt ?? scheduledTime;
    
    switch (frequency) {
      case ProgressReminderFrequency.daily:
        return base.add(const Duration(days: 1));
      case ProgressReminderFrequency.weekly:
        return base.add(const Duration(days: 7));
      case ProgressReminderFrequency.biweekly:
        return base.add(const Duration(days: 14));
      case ProgressReminderFrequency.monthly:
        return DateTime(base.year, base.month + 1, base.day);
      case ProgressReminderFrequency.custom:
        if (customIntervalDays != null) {
          return base.add(Duration(days: customIntervalDays!));
        }
        return null;
    }
  }

  // Hatırlatma ikonunu al
  String get iconEmoji {
    switch (type) {
      case ProgressReminderType.weightUpdate:
        return '⚖️';
      case ProgressReminderType.dietAdherence:
        return '🥗';
      case ProgressReminderType.milestone:
        return '🎯';
      case ProgressReminderType.weeklyProgress:
        return '📊';
      case ProgressReminderType.monthlyAssessment:
        return '📈';
      case ProgressReminderType.waterIntake:
        return '💧';
      case ProgressReminderType.exerciseLog:
        return '🏃‍♀️';
      case ProgressReminderType.moodTracker:
        return '😊';
    }
  }

  // Hedef değerleri Map olarak al
  Map<String, String> get targetValues {
    try {
      return Map<String, String>.from(jsonDecode(targetValuesJson));
    } catch (e) {
      return <String, String>{};
    }
  }

  // Hedef değerleri Map olarak ayarla
  set targetValues(Map<String, String> values) {
    targetValuesJson = jsonEncode(values);
    updatedAt = DateTime.now();
  }

  // Hedef değer alma
  String? getTargetValue(String key) {
    return targetValues[key];
  }

  // Hedef değer ayarlama
  void setTargetValue(String key, String value) {
    final current = targetValues;
    current[key] = value;
    targetValuesJson = jsonEncode(current);
    updatedAt = DateTime.now();
  }

  // Hatırlatmayı tamamla
  void markAsCompleted(String? response) {
    status = ProgressReminderStatus.completed;
    completedAt = DateTime.now();
    userResponse = response;
    updatedAt = DateTime.now();
  }

  // Hatırlatmayı göz ardı et
  void markAsDismissed() {
    status = ProgressReminderStatus.dismissed;
    dismissedAt = DateTime.now();
    updatedAt = DateTime.now();
  }

  // Hatırlatmayı kaçırılmış olarak işaretle
  void markAsMissed() {
    status = ProgressReminderStatus.missed;
    updatedAt = DateTime.now();
  }

  // Hatırlatma sayacını artır
  void incrementReminderCount() {
    reminderCount++;
    updatedAt = DateTime.now();
    
    if (reminderCount >= maxReminders) {
      status = ProgressReminderStatus.missed;
    }
  }
}