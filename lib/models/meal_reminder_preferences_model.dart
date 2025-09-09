import 'package:flutter/material.dart';

/// Öğün hatırlatma tercihlerini tutmak için model
class MealReminderPreferencesModel {

  
  late String userId;

  // Öğün zamanları
  int breakfastHour = 8;
  int breakfastMinute = 0;
  
  int lunchHour = 12;
  int lunchMinute = 30;
  
  int dinnerHour = 19;
  int dinnerMinute = 0;
  
  int snackHour = 15;
  int snackMinute = 30;

  // Hatırlatma günleri (1=Pazartesi, 7=Pazar)
  List<int> reminderDays = [1, 2, 3, 4, 5, 6, 7]; // Varsayılan: Her gün

  // Hatırlatma aktif/pasif durumları
  bool isBreakfastReminderEnabled = true;
  bool isLunchReminderEnabled = true;
  bool isDinnerReminderEnabled = true;
  bool isSnackReminderEnabled = true;

  // Genel hatırlatma açık/kapalı
  bool isReminderEnabled = true;

  // Ses ve titreşim ayarları
  bool isSoundEnabled = true;
  bool isVibrationEnabled = true;

  // Önceden hatırlatma (dakika)
  int beforeMealMinutes = 0; // 0=tam zamanında, 15=15dk önce

  // Otomatik snooze ayarları
  int autoSnoozeMinutes = 15;
  int maxSnoozeCount = 3;

  // Kişiselleştirilmiş mesajlar
  bool usePersonalizedMessages = true;
  String? customBreakfastMessage;
  String? customLunchMessage;
  String? customDinnerMessage;
  String? customSnackMessage;

  // Davranışsal öğrenme verileri
  int breakfastCompletionCount = 0;
  int lunchCompletionCount = 0;
  int dinnerCompletionCount = 0;
  int snackCompletionCount = 0;

  int breakfastSkipCount = 0;
  int lunchSkipCount = 0;
  int dinnerSkipCount = 0;
  int snackSkipCount = 0;

  // Son güncelleme zamanları
  DateTime? lastBreakfastTime;
  DateTime? lastLunchTime;
  DateTime? lastDinnerTime;
  DateTime? lastSnackTime;

  // Ortalama yemek saatleri (öğrenilmiş)
  double? learnedBreakfastHour;
  double? learnedLunchHour;
  double? learnedDinnerHour;
  double? learnedSnackHour;

  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();

  MealReminderPreferencesModel();

  MealReminderPreferencesModel.create({
    required this.userId,
    TimeOfDay? breakfastTime,
    TimeOfDay? lunchTime,
    TimeOfDay? dinnerTime,
    TimeOfDay? snackTime,
    this.reminderDays = const [1, 2, 3, 4, 5, 6, 7],
    this.isReminderEnabled = true,
    this.isSoundEnabled = true,
    this.isVibrationEnabled = true,
    this.beforeMealMinutes = 0,
    this.usePersonalizedMessages = true,
  }) {
    if (breakfastTime != null) {
      breakfastHour = breakfastTime.hour;
      breakfastMinute = breakfastTime.minute;
    }
    if (lunchTime != null) {
      lunchHour = lunchTime.hour;
      lunchMinute = lunchTime.minute;
    }
    if (dinnerTime != null) {
      dinnerHour = dinnerTime.hour;
      dinnerMinute = dinnerTime.minute;
    }
    if (snackTime != null) {
      snackHour = snackTime.hour;
      snackMinute = snackTime.minute;
    }
    
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
  }

  // TimeOfDay dönüşümleri
  TimeOfDay get breakfastTime => TimeOfDay(hour: breakfastHour, minute: breakfastMinute);
  TimeOfDay get lunchTime => TimeOfDay(hour: lunchHour, minute: lunchMinute);
  TimeOfDay get dinnerTime => TimeOfDay(hour: dinnerHour, minute: dinnerMinute);
  TimeOfDay get snackTime => TimeOfDay(hour: snackHour, minute: snackMinute);

  void setBreakfastTime(TimeOfDay time) {
    breakfastHour = time.hour;
    breakfastMinute = time.minute;
    updatedAt = DateTime.now();
  }

  void setLunchTime(TimeOfDay time) {
    lunchHour = time.hour;
    lunchMinute = time.minute;
    updatedAt = DateTime.now();
  }

  void setDinnerTime(TimeOfDay time) {
    dinnerHour = time.hour;
    dinnerMinute = time.minute;
    updatedAt = DateTime.now();
  }

  void setSnackTime(TimeOfDay time) {
    snackHour = time.hour;
    snackMinute = time.minute;
    updatedAt = DateTime.now();
  }

  // Öğün tamamlanma oranları
  double get breakfastCompletionRate {
    final total = breakfastCompletionCount + breakfastSkipCount;
    return total > 0 ? breakfastCompletionCount / total : 0.0;
  }

  double get lunchCompletionRate {
    final total = lunchCompletionCount + lunchSkipCount;
    return total > 0 ? lunchCompletionCount / total : 0.0;
  }

  double get dinnerCompletionRate {
    final total = dinnerCompletionCount + dinnerSkipCount;
    return total > 0 ? dinnerCompletionCount / total : 0.0;
  }

  double get snackCompletionRate {
    final total = snackCompletionCount + snackSkipCount;
    return total > 0 ? snackCompletionCount / total : 0.0;
  }

  double get overallCompletionRate {
    final totalCompletion = breakfastCompletionCount + lunchCompletionCount + 
                           dinnerCompletionCount + snackCompletionCount;
    final totalSkip = breakfastSkipCount + lunchSkipCount + 
                     dinnerSkipCount + snackSkipCount;
    final total = totalCompletion + totalSkip;
    return total > 0 ? totalCompletion / total : 0.0;
  }

  // Öğün tamamlandı kaydet
  void markMealCompleted(String mealType, DateTime completedTime) {
    switch (mealType.toLowerCase()) {
      case 'kahvaltı':
      case 'breakfast':
        breakfastCompletionCount++;
        lastBreakfastTime = completedTime;
        _updateLearnedTime('breakfast', completedTime);
        break;
      case 'öğle yemeği':
      case 'lunch':
        lunchCompletionCount++;
        lastLunchTime = completedTime;
        _updateLearnedTime('lunch', completedTime);
        break;
      case 'akşam yemeği':
      case 'dinner':
        dinnerCompletionCount++;
        lastDinnerTime = completedTime;
        _updateLearnedTime('dinner', completedTime);
        break;
      case 'ara öğün':
      case 'snack':
        snackCompletionCount++;
        lastSnackTime = completedTime;
        _updateLearnedTime('snack', completedTime);
        break;
    }
    updatedAt = DateTime.now();
  }

  // Öğün atlama kaydet
  void markMealSkipped(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'kahvaltı':
      case 'breakfast':
        breakfastSkipCount++;
        break;
      case 'öğle yemeği':
      case 'lunch':
        lunchSkipCount++;
        break;
      case 'akşam yemeği':
      case 'dinner':
        dinnerSkipCount++;
        break;
      case 'ara öğün':
      case 'snack':
        snackSkipCount++;
        break;
    }
    updatedAt = DateTime.now();
  }

  // Öğrenilmiş zamanları güncelle (basit ortalama)
  void _updateLearnedTime(String mealType, DateTime completedTime) {
    final hour = completedTime.hour + (completedTime.minute / 60.0);
    
    switch (mealType) {
      case 'breakfast':
        learnedBreakfastHour = learnedBreakfastHour == null 
            ? hour 
            : (learnedBreakfastHour! + hour) / 2;
        break;
      case 'lunch':
        learnedLunchHour = learnedLunchHour == null 
            ? hour 
            : (learnedLunchHour! + hour) / 2;
        break;
      case 'dinner':
        learnedDinnerHour = learnedDinnerHour == null 
            ? hour 
            : (learnedDinnerHour! + hour) / 2;
        break;
      case 'snack':
        learnedSnackHour = learnedSnackHour == null 
            ? hour 
            : (learnedSnackHour! + hour) / 2;
        break;
    }
  }

  // Öğrenilmiş zamanlara göre önerileri al
  TimeOfDay? getSuggestedBreakfastTime() {
    if (learnedBreakfastHour != null) {
      final hour = learnedBreakfastHour!.floor();
      final minute = ((learnedBreakfastHour! - hour) * 60).round();
      return TimeOfDay(hour: hour, minute: minute);
    }
    return null;
  }

  TimeOfDay? getSuggestedLunchTime() {
    if (learnedLunchHour != null) {
      final hour = learnedLunchHour!.floor();
      final minute = ((learnedLunchHour! - hour) * 60).round();
      return TimeOfDay(hour: hour, minute: minute);
    }
    return null;
  }

  TimeOfDay? getSuggestedDinnerTime() {
    if (learnedDinnerHour != null) {
      final hour = learnedDinnerHour!.floor();
      final minute = ((learnedDinnerHour! - hour) * 60).round();
      return TimeOfDay(hour: hour, minute: minute);
    }
    return null;
  }

  TimeOfDay? getSuggestedSnackTime() {
    if (learnedSnackHour != null) {
      final hour = learnedSnackHour!.floor();
      final minute = ((learnedSnackHour! - hour) * 60).round();
      return TimeOfDay(hour: hour, minute: minute);
    }
    return null;
  }

  // Hafta içi/hafta sonu ayrımı
  bool get hasWeekdayReminders => reminderDays.any((day) => day <= 5);
  bool get hasWeekendReminders => reminderDays.any((day) => day > 5);

  List<int> get weekdayReminders => reminderDays.where((day) => day <= 5).toList();
  List<int> get weekendReminders => reminderDays.where((day) => day > 5).toList();

  // Gün isimlerini döndür
  List<String> get reminderDayNames {
    const dayNames = ['', 'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
    return reminderDays.map((day) => dayNames[day]).toList();
  }

  // Öğün aktif/pasif kontrolü
  bool isMealReminderEnabled(String mealType) {
    if (!isReminderEnabled) return false;
    
    switch (mealType.toLowerCase()) {
      case 'kahvaltı':
      case 'breakfast':
        return isBreakfastReminderEnabled;
      case 'öğle yemeği':
      case 'lunch':
        return isLunchReminderEnabled;
      case 'akşam yemeği':
      case 'dinner':
        return isDinnerReminderEnabled;
      case 'ara öğün':
      case 'snack':
        return isSnackReminderEnabled;
      default:
        return false;
    }
  }

  // Kişiselleştirilmiş mesaj al
  String? getCustomMessage(String mealType) {
    if (!usePersonalizedMessages) return null;
    
    switch (mealType.toLowerCase()) {
      case 'kahvaltı':
      case 'breakfast':
        return customBreakfastMessage;
      case 'öğle yemeği':
      case 'lunch':
        return customLunchMessage;
      case 'akşam yemeği':
      case 'dinner':
        return customDinnerMessage;
      case 'ara öğün':
      case 'snack':
        return customSnackMessage;
      default:
        return null;
    }
  }

  // Motivasyon mesajları
  String getMotivationMessage() {
    final rate = overallCompletionRate;
    if (rate >= 0.9) {
      return 'Mükemmel! Diyet programınıza harika bir şekilde uyum sağlıyorsunuz! 🌟';
    } else if (rate >= 0.7) {
      return 'Çok iyi gidiyorsunuz! Bu tempo ile hedefinize ulaşacaksınız! 💪';
    } else if (rate >= 0.5) {
      return 'İyi bir başlangıç! Biraz daha tutarlı olursak harika sonuçlar alacağız! 📈';
    } else {
      return 'Hadi başlayalım! Her yeni gün yeni bir fırsat! Birlikte başarabiliriz! 🚀';
    }
  }

  // JSON için dönüşüm
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'breakfastHour': breakfastHour,
      'breakfastMinute': breakfastMinute,
      'lunchHour': lunchHour,
      'lunchMinute': lunchMinute,
      'dinnerHour': dinnerHour,
      'dinnerMinute': dinnerMinute,
      'snackHour': snackHour,
      'snackMinute': snackMinute,
      'reminderDays': reminderDays,
      'isReminderEnabled': isReminderEnabled,
      'isBreakfastReminderEnabled': isBreakfastReminderEnabled,
      'isLunchReminderEnabled': isLunchReminderEnabled,
      'isDinnerReminderEnabled': isDinnerReminderEnabled,
      'isSnackReminderEnabled': isSnackReminderEnabled,
      'isSoundEnabled': isSoundEnabled,
      'isVibrationEnabled': isVibrationEnabled,
      'beforeMealMinutes': beforeMealMinutes,
      'usePersonalizedMessages': usePersonalizedMessages,
      'overallCompletionRate': overallCompletionRate,
    };
  }
}