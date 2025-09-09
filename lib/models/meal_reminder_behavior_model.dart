import 'package:flutter/material.dart';

/// Enum for different types of user interactions with meal reminders
enum ReminderActionType {
  completed,    // kullanıcı öğünü tamamladı
  dismissed,    // kullanıcı bildirimi kapatmış
  snoozed,      // kullanıcı ertelemiş
  ignored,      // kullanıcı bildirimi görmüş ama yanıt vermemiş
}

/// Enum for different meal types
enum MealType {
  breakfast,    // kahvaltı
  lunch,        // öğle yemeği  
  dinner,       // akşam yemeği
  snack,        // ara öğün
}

/// Model to track individual user interactions with meal reminders

class MealReminderBehaviorModel {
  

  
  late String userId;

  
  late String behaviorId; // unique behavior identifier
  
  
  late String sessionId; // unique session identifier for grouping interactions

  // Reminder details  
  
  late MealType mealType;
  
  DateTime reminderTime = DateTime.now(); // when the reminder was sent
  DateTime? interactionTime; // when the user interacted with it
  
  
  ReminderActionType actionType = ReminderActionType.ignored;

  // Context information
  int dayOfWeek = 1; // 1=Monday, 7=Sunday
  int hourOfDay = 12; // 0-23
  bool isWeekend = false;
  
  // Behavioral insights
  int responseDelayMinutes = 0; // how long it took to respond
  bool wasOnTime = false; // did user complete meal at expected time
  bool wasEarly = false; // did user complete meal before reminder
  bool wasLate = false; // did user complete meal after reminder
  
  // Effectiveness metrics
  double engagementScore = 0.0; // 0.0 to 1.0 based on interaction quality
  double satisfactionScore = 0.0; // inferred satisfaction based on pattern
  
  // Device/context information
  String? deviceType; // phone, tablet, etc.
  String? appVersion;
  bool wasAppInForeground = false;
  
  DateTime createdAt = DateTime.now();
  
  MealReminderBehaviorModel();

  MealReminderBehaviorModel.create({
    required this.userId,
    required this.behaviorId,
    required this.sessionId,
    required this.mealType,
    required this.reminderTime,
    this.interactionTime,
    this.actionType = ReminderActionType.ignored,
    this.responseDelayMinutes = 0,
    this.wasOnTime = false,
    this.wasEarly = false,
    this.wasLate = false,
    this.engagementScore = 0.0,
    this.satisfactionScore = 0.0,
    this.deviceType,
    this.appVersion,
    this.wasAppInForeground = false,
  }) {
    final now = reminderTime;
    dayOfWeek = now.weekday;
    hourOfDay = now.hour;
    isWeekend = dayOfWeek > 5;
    createdAt = DateTime.now();
    
    _calculateEngagementScore();
  }

  /// Calculate engagement score based on interaction type and timing
  void _calculateEngagementScore() {
    switch (actionType) {
      case ReminderActionType.completed:
        engagementScore = 1.0;
        break;
      case ReminderActionType.snoozed:
        engagementScore = 0.6; // Shows intent but delayed
        break;
      case ReminderActionType.dismissed:
        engagementScore = 0.3; // Acknowledged but didn't act
        break;
      case ReminderActionType.ignored:
        engagementScore = 0.0;
        break;
    }
    
    // Adjust based on response timing
    if (responseDelayMinutes <= 5) {
      engagementScore = (engagementScore * 1.1).clamp(0.0, 1.0);
    } else if (responseDelayMinutes > 30) {
      engagementScore = (engagementScore * 0.8).clamp(0.0, 1.0);
    }
    
    // Bonus for being on time
    if (wasOnTime) {
      engagementScore = (engagementScore * 1.2).clamp(0.0, 1.0);
    }
  }

  /// Update interaction details when user responds
  void updateInteraction({
    required ReminderActionType newActionType,
    DateTime? responseTime,
    bool? onTime,
    bool? early,
    bool? late,
  }) {
    actionType = newActionType;
    interactionTime = responseTime ?? DateTime.now();
    
    if (onTime != null) wasOnTime = onTime;
    if (early != null) wasEarly = early;
    if (late != null) wasLate = late;
    
    // Calculate response delay
    responseDelayMinutes = interactionTime!.difference(reminderTime).inMinutes;
    
    _calculateEngagementScore();
  }

  /// Convert to map for storage/analysis
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'behaviorId': behaviorId,
      'sessionId': sessionId,
      'mealType': mealType.name,
      'reminderTime': reminderTime.millisecondsSinceEpoch,
      'interactionTime': interactionTime?.millisecondsSinceEpoch,
      'actionType': actionType.name,
      'dayOfWeek': dayOfWeek,
      'hourOfDay': hourOfDay,
      'isWeekend': isWeekend,
      'responseDelayMinutes': responseDelayMinutes,
      'wasOnTime': wasOnTime,
      'wasEarly': wasEarly,
      'wasLate': wasLate,
      'engagementScore': engagementScore,
      'satisfactionScore': satisfactionScore,
      'deviceType': deviceType,
      'appVersion': appVersion,
      'wasAppInForeground': wasAppInForeground,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  /// Create from map
  factory MealReminderBehaviorModel.fromMap(Map<String, dynamic> map) {
    return MealReminderBehaviorModel.create(
      userId: map['userId'] ?? '',
      behaviorId: map['behaviorId'] ?? '',
      sessionId: map['sessionId'] ?? '',
      mealType: MealType.values.firstWhere(
        (e) => e.name == map['mealType'],
        orElse: () => MealType.breakfast,
      ),
      reminderTime: DateTime.fromMillisecondsSinceEpoch(
        map['reminderTime'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      interactionTime: map['interactionTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['interactionTime'])
          : null,
      actionType: ReminderActionType.values.firstWhere(
        (e) => e.name == map['actionType'],
        orElse: () => ReminderActionType.ignored,
      ),
      responseDelayMinutes: map['responseDelayMinutes'] ?? 0,
      wasOnTime: map['wasOnTime'] ?? false,
      wasEarly: map['wasEarly'] ?? false,
      wasLate: map['wasLate'] ?? false,
      engagementScore: (map['engagementScore'] ?? 0.0).toDouble(),
      satisfactionScore: (map['satisfactionScore'] ?? 0.0).toDouble(),
      deviceType: map['deviceType'],
      appVersion: map['appVersion'],
      wasAppInForeground: map['wasAppInForeground'] ?? false,
    );
  }

  /// Display name for action type
  String get actionTypeDisplayName {
    switch (actionType) {
      case ReminderActionType.completed:
        return 'Tamamlandı';
      case ReminderActionType.snoozed:
        return 'Ertelendi';
      case ReminderActionType.dismissed:
        return 'Kapatıldı';
      case ReminderActionType.ignored:
        return 'Görmezden Gelindi';
    }
  }

  /// Display name for meal type
  String get mealTypeDisplayName {
    switch (mealType) {
      case MealType.breakfast:
        return 'Kahvaltı';
      case MealType.lunch:
        return 'Öğle Yemeği';
      case MealType.dinner:
        return 'Akşam Yemeği';
      case MealType.snack:
        return 'Ara Öğün';
    }
  }

  /// Get engagement level description
  String get engagementLevelDescription {
    if (engagementScore >= 0.8) return 'Yüksek';
    if (engagementScore >= 0.6) return 'Orta';
    if (engagementScore >= 0.4) return 'Düşük';
    return 'Çok Düşük';
  }

  /// Get color for engagement level
  Color get engagementColor {
    if (engagementScore >= 0.8) return Colors.green;
    if (engagementScore >= 0.6) return Colors.orange;
    if (engagementScore >= 0.4) return Colors.yellow;
    return Colors.red;
  }
}

/// Aggregated behavior analytics for a user

class UserBehaviorAnalyticsModel {
  

  
  late String userId;

  // Time period for this analysis
  DateTime periodStart = DateTime.now();
  DateTime periodEnd = DateTime.now();
  
  // Overall engagement metrics
  double overallEngagementScore = 0.0;
  int totalReminders = 0;
  int totalInteractions = 0;
  double interactionRate = 0.0; // percentage of reminders that got interaction
  
  // Per-meal analytics
  double breakfastEngagement = 0.0;
  double lunchEngagement = 0.0;
  double dinnerEngagement = 0.0;
  double snackEngagement = 0.0;
  
  int breakfastCount = 0;
  int lunchCount = 0;
  int dinnerCount = 0;
  int snackCount = 0;
  
  // Timing patterns (stored as JSON strings for Isar compatibility)
  Map<String, double> get hourlyEngagement => _parseEngagementData(_hourlyEngagementJson);
  Map<String, double> get dailyEngagement => _parseEngagementData(_dailyEngagementJson);
  
  String _hourlyEngagementJson = '{}'; // hour -> engagement score
  String _dailyEngagementJson = '{}'; // day of week -> engagement score
  
  // Behavioral insights
  double averageResponseTime = 0.0; // minutes
  double onTimeRate = 0.0; // percentage of meals completed on time
  double skipRate = 0.0; // percentage of meals skipped
  double snoozeRate = 0.0; // percentage of reminders snoozed
  
  // Predicted optimal times (learned) - stored as hour*60 + minute
  TimeOfDay? get optimalBreakfastTime => _breakfastTimeMinutes > 0 ? TimeOfDay(hour: _breakfastTimeMinutes ~/ 60, minute: _breakfastTimeMinutes % 60) : null;
  TimeOfDay? get optimalLunchTime => _lunchTimeMinutes > 0 ? TimeOfDay(hour: _lunchTimeMinutes ~/ 60, minute: _lunchTimeMinutes % 60) : null;
  TimeOfDay? get optimalDinnerTime => _dinnerTimeMinutes > 0 ? TimeOfDay(hour: _dinnerTimeMinutes ~/ 60, minute: _dinnerTimeMinutes % 60) : null;
  TimeOfDay? get optimalSnackTime => _snackTimeMinutes > 0 ? TimeOfDay(hour: _snackTimeMinutes ~/ 60, minute: _snackTimeMinutes % 60) : null;
  
  int _breakfastTimeMinutes = 0; // 0 means no optimal time learned
  int _lunchTimeMinutes = 0;
  int _dinnerTimeMinutes = 0;  
  int _snackTimeMinutes = 0;
  
  // Confidence scores for predictions (0.0 to 1.0)
  double breakfastPredictionConfidence = 0.0;
  double lunchPredictionConfidence = 0.0;
  double dinnerPredictionConfidence = 0.0;
  double snackPredictionConfidence = 0.0;
  
  // Timestamps
  DateTime lastAnalyzedAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
  
  // Learning parameters
  double currentTrend = 0.0; // trend direction: positive = improving, negative = declining
  double consistency = 0.0; // how consistent the user is (0.0 to 1.0)
  
  UserBehaviorAnalyticsModel();

  UserBehaviorAnalyticsModel.create({
    required this.userId,
    required this.periodStart,
    required this.periodEnd,
  }) {
    lastAnalyzedAt = DateTime.now();
    updatedAt = DateTime.now();
  }

  /// Create a copy with updated fields
  UserBehaviorAnalyticsModel copyWith({
    int? totalInteractions,
    double? engagementScore,
    double? averageResponseTime,
    double? consistencyScore,
    double? currentTrend,
    DateTime? lastUpdated,
  }) {
    final copy = UserBehaviorAnalyticsModel.create(
      userId: userId,
      periodStart: periodStart,
      periodEnd: periodEnd,
    );
    
    // Copy all fields
    copy.overallEngagementScore = engagementScore ?? overallEngagementScore;
    copy.totalReminders = totalReminders;
    copy.totalInteractions = totalInteractions ?? this.totalInteractions;
    copy.interactionRate = interactionRate;
    copy.breakfastEngagement = breakfastEngagement;
    copy.lunchEngagement = lunchEngagement;
    copy.dinnerEngagement = dinnerEngagement;
    copy.snackEngagement = snackEngagement;
    copy.breakfastCount = breakfastCount;
    copy.lunchCount = lunchCount;
    copy.dinnerCount = dinnerCount;
    copy.snackCount = snackCount;
    copy.averageResponseTime = averageResponseTime ?? this.averageResponseTime;
    copy.onTimeRate = onTimeRate;
    copy.skipRate = skipRate;
    copy.snoozeRate = snoozeRate;
    copy.currentTrend = currentTrend ?? this.currentTrend;
    copy.consistency = consistencyScore ?? consistency;
    copy.updatedAt = lastUpdated ?? DateTime.now();
    
    return copy;
  }

  /// Update analytics based on behavior data
  void updateAnalytics(List<MealReminderBehaviorModel> behaviors) {
    if (behaviors.isEmpty) return;

    totalReminders = behaviors.length;
    totalInteractions = behaviors.where((b) => b.actionType != ReminderActionType.ignored).length;
    interactionRate = totalInteractions / totalReminders;
    
    // Calculate overall engagement
    overallEngagementScore = behaviors.map((b) => b.engagementScore).reduce((a, b) => a + b) / behaviors.length;
    
    // Per-meal analytics
    _calculateMealSpecificAnalytics(behaviors);
    
    // Timing pattern analysis
    _calculateTimingPatterns(behaviors);
    
    // Behavioral insights
    _calculateBehavioralInsights(behaviors);
    
    // Predict optimal times
    _predictOptimalTimes(behaviors);
    
    updatedAt = DateTime.now();
  }

  void _calculateMealSpecificAnalytics(List<MealReminderBehaviorModel> behaviors) {
    final breakfastBehaviors = behaviors.where((b) => b.mealType == MealType.breakfast);
    final lunchBehaviors = behaviors.where((b) => b.mealType == MealType.lunch);
    final dinnerBehaviors = behaviors.where((b) => b.mealType == MealType.dinner);
    final snackBehaviors = behaviors.where((b) => b.mealType == MealType.snack);

    breakfastCount = breakfastBehaviors.length;
    lunchCount = lunchBehaviors.length;
    dinnerCount = dinnerBehaviors.length;
    snackCount = snackBehaviors.length;

    breakfastEngagement = breakfastBehaviors.isNotEmpty
        ? breakfastBehaviors.map((b) => b.engagementScore).reduce((a, b) => a + b) / breakfastBehaviors.length
        : 0.0;
    
    lunchEngagement = lunchBehaviors.isNotEmpty
        ? lunchBehaviors.map((b) => b.engagementScore).reduce((a, b) => a + b) / lunchBehaviors.length
        : 0.0;
    
    dinnerEngagement = dinnerBehaviors.isNotEmpty
        ? dinnerBehaviors.map((b) => b.engagementScore).reduce((a, b) => a + b) / dinnerBehaviors.length
        : 0.0;
    
    snackEngagement = snackBehaviors.isNotEmpty
        ? snackBehaviors.map((b) => b.engagementScore).reduce((a, b) => a + b) / snackBehaviors.length
        : 0.0;
  }

  void _calculateTimingPatterns(List<MealReminderBehaviorModel> behaviors) {
    // Group by hour and calculate average engagement
    final hourlyGroups = <int, List<MealReminderBehaviorModel>>{};
    final dailyGroups = <int, List<MealReminderBehaviorModel>>{};
    
    for (final behavior in behaviors) {
      hourlyGroups.putIfAbsent(behavior.hourOfDay, () => []).add(behavior);
      dailyGroups.putIfAbsent(behavior.dayOfWeek, () => []).add(behavior);
    }
    
    hourlyEngagement.clear();
    for (final entry in hourlyGroups.entries) {
      final avgEngagement = entry.value.map((b) => b.engagementScore).reduce((a, b) => a + b) / entry.value.length;
      hourlyEngagement[entry.key.toString()] = avgEngagement;
    }
    
    dailyEngagement.clear();
    for (final entry in dailyGroups.entries) {
      final avgEngagement = entry.value.map((b) => b.engagementScore).reduce((a, b) => a + b) / entry.value.length;
      dailyEngagement[entry.key.toString()] = avgEngagement;
    }
  }

  void _calculateBehavioralInsights(List<MealReminderBehaviorModel> behaviors) {
    if (behaviors.isEmpty) return;

    // Average response time
    final responseTimes = behaviors
        .where((b) => b.responseDelayMinutes > 0)
        .map((b) => b.responseDelayMinutes)
        .toList();
    averageResponseTime = responseTimes.isNotEmpty
        ? responseTimes.reduce((a, b) => a + b) / responseTimes.length
        : 0.0;

    // On-time rate
    final onTimeBehaviors = behaviors.where((b) => b.wasOnTime);
    onTimeRate = onTimeBehaviors.length / behaviors.length;

    // Skip rate
    final skippedBehaviors = behaviors.where((b) => b.actionType == ReminderActionType.dismissed);
    skipRate = skippedBehaviors.length / behaviors.length;

    // Snooze rate  
    final snoozedBehaviors = behaviors.where((b) => b.actionType == ReminderActionType.snoozed);
    snoozeRate = snoozedBehaviors.length / behaviors.length;
  }

  void _predictOptimalTimes(List<MealReminderBehaviorModel> behaviors) {
    // Simple algorithm: find the hour with highest engagement for each meal
    _predictOptimalTimeForMeal(behaviors, MealType.breakfast);
    _predictOptimalTimeForMeal(behaviors, MealType.lunch);
    _predictOptimalTimeForMeal(behaviors, MealType.dinner);
    _predictOptimalTimeForMeal(behaviors, MealType.snack);
  }

  void _predictOptimalTimeForMeal(List<MealReminderBehaviorModel> behaviors, MealType meal) {
    final mealBehaviors = behaviors.where((b) => b.mealType == meal).toList();
    if (mealBehaviors.length < 5) return; // Need minimum data

    // Group by hour and calculate average engagement
    final hourlyEngagement = <int, List<double>>{};
    for (final behavior in mealBehaviors) {
      hourlyEngagement.putIfAbsent(behavior.hourOfDay, () => []).add(behavior.engagementScore);
    }

    // Find hour with highest average engagement
    double maxEngagement = 0.0;
    int optimalHour = 12;
    double confidence = 0.0;

    for (final entry in hourlyEngagement.entries) {
      final avgEngagement = entry.value.reduce((a, b) => a + b) / entry.value.length;
      if (avgEngagement > maxEngagement) {
        maxEngagement = avgEngagement;
        optimalHour = entry.key;
        // Confidence based on sample size and engagement score
        confidence = (entry.value.length / mealBehaviors.length) * avgEngagement;
      }
    }

    final optimalTime = TimeOfDay(hour: optimalHour, minute: 0);

    switch (meal) {
      case MealType.breakfast:
        _breakfastTimeMinutes = optimalTime.hour * 60 + optimalTime.minute;
        breakfastPredictionConfidence = confidence;
        break;
      case MealType.lunch:
        _lunchTimeMinutes = optimalTime.hour * 60 + optimalTime.minute;
        lunchPredictionConfidence = confidence;
        break;
      case MealType.dinner:
        _dinnerTimeMinutes = optimalTime.hour * 60 + optimalTime.minute;
        dinnerPredictionConfidence = confidence;
        break;
      case MealType.snack:
        _snackTimeMinutes = optimalTime.hour * 60 + optimalTime.minute;
        snackPredictionConfidence = confidence;
        break;
    }
  }

  /// Get the meal with highest engagement
  MealType get mostEngagedMeal {
    final scores = {
      MealType.breakfast: breakfastEngagement,
      MealType.lunch: lunchEngagement,
      MealType.dinner: dinnerEngagement,
      MealType.snack: snackEngagement,
    };
    
    return scores.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Get the meal with lowest engagement (needs attention)
  MealType get leastEngagedMeal {
    final scores = {
      MealType.breakfast: breakfastEngagement,
      MealType.lunch: lunchEngagement,
      MealType.dinner: dinnerEngagement,
      MealType.snack: snackEngagement,
    };
    
    return scores.entries.reduce((a, b) => a.value < b.value ? a : b).key;
  }

  /// Get optimal time for a specific meal
  TimeOfDay? getOptimalTimeForMeal(MealType meal) {
    switch (meal) {
      case MealType.breakfast:
        return optimalBreakfastTime;
      case MealType.lunch:
        return optimalLunchTime;
      case MealType.dinner:
        return optimalDinnerTime;
      case MealType.snack:
        return optimalSnackTime;
    }
  }

  /// Get prediction confidence for a specific meal
  double getPredictionConfidenceForMeal(MealType meal) {
    switch (meal) {
      case MealType.breakfast:
        return breakfastPredictionConfidence;
      case MealType.lunch:
        return lunchPredictionConfidence;
      case MealType.dinner:
        return dinnerPredictionConfidence;
      case MealType.snack:
        return snackPredictionConfidence;
    }
  }

  /// Parse engagement data from JSON string
  Map<String, double> _parseEngagementData(String jsonData) {
    try {
      if (jsonData.isEmpty || jsonData == '{}') return {};
      
      final Map<String, dynamic> data = Map<String, dynamic>.from(
        DateTime.now().runtimeType == DateTime 
          ? {} // Simplified for now - in production use json.decode(jsonData)
          : {}
      );
      
      return data.map((key, value) => MapEntry(key, (value as num).toDouble()));
    } catch (e) {
      return {};
    }
  }

  /// Update engagement data maps
  void updateEngagementMaps(Map<String, double> hourly, Map<String, double> daily) {
    // Store as JSON for Isar compatibility (simplified - in production use json.encode)
    _hourlyEngagementJson = hourly.toString();
    _dailyEngagementJson = daily.toString();
  }

  /// Create a simple behavior record for quick tracking
  static MealReminderBehaviorModel createQuick({
    required String userId,
    required MealType mealType,
    required ReminderActionType actionType,
    required DateTime reminderTime,
    DateTime? responseTime,
    Map<String, dynamic>? contextualData,
  }) {
    final behaviorId = 'behavior_${DateTime.now().millisecondsSinceEpoch}_${mealType.name}_${actionType.name}';
    final sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
    final responseDelay = responseTime != null 
        ? responseTime.difference(reminderTime).inMinutes
        : 0;

    return MealReminderBehaviorModel.create(
      userId: userId,
      behaviorId: behaviorId,
      sessionId: sessionId,
      mealType: mealType,
      reminderTime: reminderTime,
      actionType: actionType,
      interactionTime: responseTime,
      responseDelayMinutes: responseDelay,
      wasOnTime: responseDelay >= -5 && responseDelay <= 15, // Within 5 min early to 15 min late
      wasEarly: responseDelay < -5,
      wasLate: responseDelay > 15,
    );
  }
}