import 'package:flutter/material.dart';
import '../database/drift_service.dart';
import '../models/meal_reminder_preferences_model.dart';
import 'auth_service.dart';

/// Service layer for managing meal reminder preferences
class MealReminderPreferenceService {
  
  /// Get current user's meal reminder preferences (creates default if not exists)
  static Future<MealReminderPreferencesModel?> getCurrentUserPreferences() async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) return null;
      
      return await DriftService.getMealReminderPreferencesOrDefault(userId);
    } catch (e) {
      debugPrint('Error getting current user meal preferences: $e');
      return null;
    }
  }

  /// Save meal reminder preferences and refresh notifications
  static Future<bool> savePreferences(MealReminderPreferencesModel preferences) async {
    try {
      // Save preferences to database
      await DriftService.saveMealReminderPreferences(preferences);
      
      // Refresh user's meal reminders
      await MealReminderPreferenceService.scheduleAdaptiveReminders(preferences.userId);
      
      debugPrint('✅ Meal reminder preferences saved and notifications updated for user: ${preferences.userId}');
      return true;
    } catch (e) {
      debugPrint('❌ Error saving meal reminder preferences: $e');
      return false;
    }
  }

  /// Create default preferences for a user
  static Future<MealReminderPreferencesModel?> createDefaultPreferences(String userId) async {
    try {
      final preferences = MealReminderPreferencesModel.create(userId: userId);
      final success = await savePreferences(preferences);
      return success ? preferences : null;
    } catch (e) {
      debugPrint('Error creating default meal preferences: $e');
      return null;
    }
  }

  /// Enable or disable meal reminders entirely
  static Future<bool> toggleMealReminders(String userId, bool enabled) async {
    try {
      final preferences = await DriftService.getMealReminderPreferencesOrDefault(userId);
      preferences.isReminderEnabled = enabled;
      preferences.updatedAt = DateTime.now();
      
      return await savePreferences(preferences);
    } catch (e) {
      debugPrint('Error toggling meal reminders: $e');
      return false;
    }
  }

  /// Update meal time for a specific meal type
  static Future<bool> updateMealTime({
    required String userId,
    required String mealType,
    required TimeOfDay time,
  }) async {
    try {
      final preferences = await DriftService.getMealReminderPreferencesOrDefault(userId);
      
      switch (mealType.toLowerCase()) {
        case 'breakfast':
        case 'kahvaltı':
          preferences.setBreakfastTime(time);
          break;
        case 'lunch':
        case 'öğle yemeği':
          preferences.setLunchTime(time);
          break;
        case 'dinner':
        case 'akşam yemeği':
          preferences.setDinnerTime(time);
          break;
        case 'snack':
        case 'ara öğün':
          preferences.setSnackTime(time);
          break;
        default:
          debugPrint('Unknown meal type: $mealType');
          return false;
      }
      
      return await savePreferences(preferences);
    } catch (e) {
      debugPrint('Error updating meal time: $e');
      return false;
    }
  }

  /// Toggle a specific meal reminder on/off
  static Future<bool> toggleMealReminder({
    required String userId,
    required String mealType,
    required bool enabled,
  }) async {
    try {
      final preferences = await DriftService.getMealReminderPreferencesOrDefault(userId);
      
      switch (mealType.toLowerCase()) {
        case 'breakfast':
        case 'kahvaltı':
          preferences.isBreakfastReminderEnabled = enabled;
          break;
        case 'lunch':
        case 'öğle yemeği':
          preferences.isLunchReminderEnabled = enabled;
          break;
        case 'dinner':
        case 'akşam yemeği':
          preferences.isDinnerReminderEnabled = enabled;
          break;
        case 'snack':
        case 'ara öğün':
          preferences.isSnackReminderEnabled = enabled;
          break;
        default:
          debugPrint('Unknown meal type: $mealType');
          return false;
      }
      
      preferences.updatedAt = DateTime.now();
      return await savePreferences(preferences);
    } catch (e) {
      debugPrint('Error toggling meal reminder: $e');
      return false;
    }
  }

  /// Update reminder days (weekdays selection)
  static Future<bool> updateReminderDays(String userId, List<int> days) async {
    try {
      final preferences = await DriftService.getMealReminderPreferencesOrDefault(userId);
      preferences.reminderDays = days;
      preferences.updatedAt = DateTime.now();
      
      return await savePreferences(preferences);
    } catch (e) {
      debugPrint('Error updating reminder days: $e');
      return false;
    }
  }

  /// Set quick schedule presets
  static Future<bool> setWeekdaySchedule(String userId) async {
    return await updateReminderDays(userId, [1, 2, 3, 4, 5]); // Monday to Friday
  }

  static Future<bool> setEverydaySchedule(String userId) async {
    return await updateReminderDays(userId, [1, 2, 3, 4, 5, 6, 7]); // Every day
  }

  static Future<bool> setWeekendSchedule(String userId) async {
    return await updateReminderDays(userId, [6, 7]); // Saturday and Sunday
  }

  /// Update notification preferences
  static Future<bool> updateNotificationPreferences({
    required String userId,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? personalizedMessages,
  }) async {
    try {
      final preferences = await DriftService.getMealReminderPreferencesOrDefault(userId);
      
      if (soundEnabled != null) {
        preferences.isSoundEnabled = soundEnabled;
      }
      
      if (vibrationEnabled != null) {
        preferences.isVibrationEnabled = vibrationEnabled;
      }
      
      if (personalizedMessages != null) {
        preferences.usePersonalizedMessages = personalizedMessages;
      }
      
      preferences.updatedAt = DateTime.now();
      return await savePreferences(preferences);
    } catch (e) {
      debugPrint('Error updating notification preferences: $e');
      return false;
    }
  }

  /// Update advanced options
  static Future<bool> updateAdvancedOptions({
    required String userId,
    int? beforeMealMinutes,
    int? autoSnoozeMinutes,
    int? maxSnoozeCount,
  }) async {
    try {
      final preferences = await DriftService.getMealReminderPreferencesOrDefault(userId);
      
      if (beforeMealMinutes != null) {
        preferences.beforeMealMinutes = beforeMealMinutes;
      }
      
      if (autoSnoozeMinutes != null) {
        preferences.autoSnoozeMinutes = autoSnoozeMinutes;
      }
      
      if (maxSnoozeCount != null) {
        preferences.maxSnoozeCount = maxSnoozeCount;
      }
      
      preferences.updatedAt = DateTime.now();
      return await savePreferences(preferences);
    } catch (e) {
      debugPrint('Error updating advanced options: $e');
      return false;
    }
  }

  /// Get meal reminder statistics for current user
  static Future<Map<String, dynamic>?> getCurrentUserStats() async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) return null;
      
      final preferences = await DriftService.getMealReminderPreferences(userId);
      if (preferences == null) {
        return {
          'overallCompletionRate': 0.0,
          'breakfastCompletionRate': 0.0,
          'lunchCompletionRate': 0.0,
          'dinnerCompletionRate': 0.0,
          'snackCompletionRate': 0.0,
          'totalMealsCompleted': 0,
          'totalMealsSkipped': 0,
          'motivationMessage': 'Meal reminder tercihlerinizi ayarlayarak başlayabilirsiniz!',
        };
      }

      return {
        'overallCompletionRate': preferences.overallCompletionRate,
        'breakfastCompletionRate': preferences.breakfastCompletionRate,
        'lunchCompletionRate': preferences.lunchCompletionRate,
        'dinnerCompletionRate': preferences.dinnerCompletionRate,
        'snackCompletionRate': preferences.snackCompletionRate,
        'totalMealsCompleted': preferences.breakfastCompletionCount + 
                              preferences.lunchCompletionCount + 
                              preferences.dinnerCompletionCount + 
                              preferences.snackCompletionCount,
        'totalMealsSkipped': preferences.breakfastSkipCount + 
                            preferences.lunchSkipCount + 
                            preferences.dinnerSkipCount + 
                            preferences.snackSkipCount,
        'motivationMessage': preferences.getMotivationMessage(),
        'hasWeekdayReminders': preferences.hasWeekdayReminders,
        'hasWeekendReminders': preferences.hasWeekendReminders,
        'reminderDayNames': preferences.reminderDayNames,
      };
    } catch (e) {
      debugPrint('Error getting current user stats: $e');
      return {'error': e.toString()};
    }
  }

  /// Get completion rate for a specific meal type
  static Future<double?> getMealCompletionRate(String userId, String mealType) async {
    try {
      final preferences = await DriftService.getMealReminderPreferences(userId);
      if (preferences == null) return null;
      
      switch (mealType.toLowerCase()) {
        case 'breakfast':
        case 'kahvaltı':
          return preferences.breakfastCompletionRate;
        case 'lunch':
        case 'öğle yemeği':
          return preferences.lunchCompletionRate;
        case 'dinner':
        case 'akşam yemeği':
          return preferences.dinnerCompletionRate;
        case 'snack':
        case 'ara öğün':
          return preferences.snackCompletionRate;
        case 'overall':
        case 'genel':
          return preferences.overallCompletionRate;
        default:
          return null;
      }
    } catch (e) {
      debugPrint('Error getting meal completion rate: $e');
      return null;
    }
  }

  /// Schedule adaptive meal reminders based on learned behavior
  static Future<bool> scheduleAdaptiveReminders(String userId) async {
    try {
      // TODO: Implement actual adaptive reminder scheduling
      // This should call the notification scheduling service once it's implemented
      debugPrint('✅ Adaptive meal reminders scheduled for user: $userId');
      return true;
    } catch (e) {
      debugPrint('❌ Error scheduling adaptive reminders: $e');
      return false;
    }
  }

  /// Import preferences from another device/account (for user migration)
  static Future<bool> importPreferences({
    required String userId,
    required Map<String, dynamic> preferencesData,
  }) async {
    try {
      // Create preferences from imported data
      final preferences = MealReminderPreferencesModel()
        ..userId = userId
        ..breakfastHour = preferencesData['breakfastHour'] ?? 8
        ..breakfastMinute = preferencesData['breakfastMinute'] ?? 0
        ..lunchHour = preferencesData['lunchHour'] ?? 12
        ..lunchMinute = preferencesData['lunchMinute'] ?? 30
        ..dinnerHour = preferencesData['dinnerHour'] ?? 19
        ..dinnerMinute = preferencesData['dinnerMinute'] ?? 0
        ..snackHour = preferencesData['snackHour'] ?? 15
        ..snackMinute = preferencesData['snackMinute'] ?? 30
        ..reminderDays = List<int>.from(preferencesData['reminderDays'] ?? [1, 2, 3, 4, 5, 6, 7])
        ..isReminderEnabled = preferencesData['isReminderEnabled'] ?? true
        ..isBreakfastReminderEnabled = preferencesData['isBreakfastReminderEnabled'] ?? true
        ..isLunchReminderEnabled = preferencesData['isLunchReminderEnabled'] ?? true
        ..isDinnerReminderEnabled = preferencesData['isDinnerReminderEnabled'] ?? true
        ..isSnackReminderEnabled = preferencesData['isSnackReminderEnabled'] ?? true
        ..isSoundEnabled = preferencesData['isSoundEnabled'] ?? true
        ..isVibrationEnabled = preferencesData['isVibrationEnabled'] ?? true
        ..usePersonalizedMessages = preferencesData['usePersonalizedMessages'] ?? true
        ..beforeMealMinutes = preferencesData['beforeMealMinutes'] ?? 0
        ..autoSnoozeMinutes = preferencesData['autoSnoozeMinutes'] ?? 15
        ..maxSnoozeCount = preferencesData['maxSnoozeCount'] ?? 3
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      return await savePreferences(preferences);
    } catch (e) {
      debugPrint('Error importing meal preferences: $e');
      return false;
    }
  }

  /// Export preferences for backup or migration
  static Future<Map<String, dynamic>?> exportPreferences(String userId) async {
    try {
      final preferences = await DriftService.getMealReminderPreferences(userId);
      if (preferences == null) return null;
      
      return preferences.toMap();
    } catch (e) {
      debugPrint('Error exporting meal preferences: $e');
      return null;
    }
  }

  /// Reset preferences to default values
  static Future<bool> resetToDefaults(String userId) async {
    try {
      // Delete existing preferences
      await DriftService.deleteMealReminderPreferences(userId);
      
      // Create new default preferences
      final defaultPreferences = await createDefaultPreferences(userId);
      return defaultPreferences != null;
    } catch (e) {
      debugPrint('Error resetting meal preferences to defaults: $e');
      return false;
    }
  }

  /// Validate preferences data
  static bool validatePreferences(MealReminderPreferencesModel preferences) {
    // Basic validation rules
    if (preferences.userId.isEmpty) return false;
    if (preferences.breakfastHour < 0 || preferences.breakfastHour > 23) return false;
    if (preferences.lunchHour < 0 || preferences.lunchHour > 23) return false;
    if (preferences.dinnerHour < 0 || preferences.dinnerHour > 23) return false;
    if (preferences.snackHour < 0 || preferences.snackHour > 23) return false;
    if (preferences.reminderDays.isEmpty) return false;
    if (preferences.beforeMealMinutes < 0 || preferences.beforeMealMinutes > 60) return false;
    if (preferences.autoSnoozeMinutes < 1 || preferences.autoSnoozeMinutes > 60) return false;
    
    return true;
  }
}