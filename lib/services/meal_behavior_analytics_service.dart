// import 'package:uuid/uuid.dart'; // TODO: Uncomment when MealReminderBehaviorModel creation is implemented
import '../models/meal_reminder_behavior_model.dart';
// import '../database/drift_service.dart'; // Removed - methods are commented out
import '../services/auth_service.dart';

/// Service for analyzing meal reminder behavior and optimizing timing
class MealBehaviorAnalyticsService {
  static const int _minDataPointsForAnalysis = 10;
  // static final _uuid = const Uuid(); // TODO: Uncomment when MealReminderBehaviorModel creation is implemented

  /// Record a user's interaction with a meal reminder
  static Future<void> recordBehaviorInteraction({
    required ReminderActionType actionType,
    required MealType mealType,
    required DateTime reminderTime,
    DateTime? interactionTime,
    Map<String, dynamic>? contextualData,
  }) async {
    final userId = AuthService.currentUserId;
    if (userId == null) return;

    // TODO: Create and save meal reminder behavior model with response delay calculation
    // final responseDelay = interactionTime != null
    //     ? interactionTime.difference(reminderTime).inMinutes
    //     : 0;
    // 
    // final behavior = MealReminderBehaviorModel.create(
    //   userId: userId,
    //   behaviorId: _uuid.v4(),
    //   sessionId: 'session_${DateTime.now().millisecondsSinceEpoch}',
    //   mealType: mealType,
    //   reminderTime: reminderTime,
    //   actionType: actionType,
    //   interactionTime: interactionTime ?? DateTime.now(),
    //   responseDelayMinutes: responseDelay,
    //   wasOnTime: responseDelay >= -5 && responseDelay <= 15,
    //   wasEarly: responseDelay < -5,
    //   wasLate: responseDelay > 15,
    // );
    // await DriftService.saveMealReminderBehavior(behavior);

    // Update analytics after recording behavior
    await _updateUserAnalytics(userId);
  }

  /// Analyze user behavior patterns and generate insights
  static Future<BehaviorAnalysisResult> analyzeUserBehavior(String userId) async {
    // final recentBehaviors = await DriftService.getRecentMealReminderBehaviors(
    //   userId,
    //   _analysisWindowDays,
    // ); // TODO: Implement recent meal reminder behaviors retrieval
    final recentBehaviors = <MealReminderBehaviorModel>[];

    if (recentBehaviors.length < _minDataPointsForAnalysis) {
      return BehaviorAnalysisResult(
        hasEnoughData: false,
        totalInteractions: recentBehaviors.length,
        insights: ['Yeterli veri yok. Daha fazla hatırlatıcı ile etkileşim gerekli.'],
      );
    }

    // Calculate response patterns
    final responsePatterns = _analyzeResponsePatterns(recentBehaviors);
    final timePatterns = _analyzeOptimalTimes(recentBehaviors);
    final engagementTrends = _analyzeEngagementTrends(recentBehaviors);

    // Generate personalized insights
    final insights = _generatePersonalizedInsights(
      responsePatterns,
      timePatterns,
      engagementTrends,
    );

    return BehaviorAnalysisResult(
      hasEnoughData: true,
      totalInteractions: recentBehaviors.length,
      responsePatterns: responsePatterns,
      optimalTimes: timePatterns,
      engagementTrends: engagementTrends,
      insights: insights,
    );
  }

  /// Get optimized reminder times based on user behavior
  static Future<List<OptimizedReminderTime>> getOptimizedReminderTimes(
    String userId,
    MealType mealType,
  ) async {
    // final behaviors = await DriftService.getMealReminderBehaviorsByAction(
    //   userId,
    //   ReminderActionType.completed,
    // ); // TODO: Implement meal reminder behaviors by action retrieval
    final behaviors = <MealReminderBehaviorModel>[];

    final mealSpecificBehaviors =
        behaviors.where((b) => b.mealType == mealType).toList();

    if (mealSpecificBehaviors.length < 5) {
      // Return default times if not enough data
      return _getDefaultOptimizedTimes(mealType);
    }

    // Analyze successful completion times
    final timeFrequency = <int, int>{};
    for (final behavior in mealSpecificBehaviors) {
      final hour = behavior.reminderTime.hour;
      timeFrequency[hour] = (timeFrequency[hour] ?? 0) + 1;
    }

    // Get top 3 most successful times
    final sortedTimes = timeFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedTimes
        .take(3)
        .map((entry) => OptimizedReminderTime(
              hour: entry.key,
              minute: 0, // Can be refined based on minute-level analysis
              successRate: entry.value / mealSpecificBehaviors.length,
              confidence: _calculateConfidence(
                  entry.value, mealSpecificBehaviors.length),
            ))
        .toList();
  }

  /// Predict user engagement likelihood for a given time
  static Future<double> predictEngagementLikelihood(
    String userId,
    DateTime proposedTime,
    MealType mealType,
  ) async {
    // final analytics = await DriftService.getUserBehaviorAnalytics(userId); // TODO: Implement user behavior analytics retrieval
    final analytics = null;
    if (analytics == null) return 0.5; // Default probability

    // final behaviors =
    //     await DriftService.getRecentMealReminderBehaviors(userId, 14); // TODO: Implement recent meal reminder behaviors
    final behaviors = <MealReminderBehaviorModel>[];

    // Time-based prediction
    final hourScore = _calculateHourScore(proposedTime.hour, behaviors, mealType);
    final dayScore = _calculateDayScore(proposedTime.weekday, behaviors);
    final trendScore = analytics.currentTrend;

    // Weighted combination
    final prediction =
        (hourScore * 0.4) + (dayScore * 0.3) + (trendScore * 0.3);
    return prediction.clamp(0.0, 1.0);
  }

  /// Update user analytics based on recent behavior
  static Future<void> _updateUserAnalytics(String userId) async {
    // final allBehaviors = await DriftService.getUserMealReminderBehaviors(userId); // TODO: Implement user meal reminder behaviors
    final allBehaviors = <MealReminderBehaviorModel>[];
    if (allBehaviors.isEmpty) return;

    // Get or create analytics model
    // var analytics = await DriftService.getUserBehaviorAnalytics(userId); // TODO: Implement user behavior analytics
    var analytics = null;

    final now = DateTime.now();
    final periodStart = allBehaviors.map((b) => b.createdAt).reduce((a,b) => a.isBefore(b) ? a : b);


    if (analytics == null) {
      analytics = UserBehaviorAnalyticsModel.create(
        userId: userId,
        periodStart: periodStart,
        periodEnd: now,
      );
    }
    
    // Update the analytics with the latest data
    analytics.updateAnalytics(allBehaviors);

    // await DriftService.saveUserBehaviorAnalytics(analytics); // TODO: Implement user behavior analytics saving
  }

  /// Analyze response patterns from behavior data
  static ResponsePatterns _analyzeResponsePatterns(
      List<MealReminderBehaviorModel> behaviors) {
    final totalBehaviors = behaviors.length;
    if (totalBehaviors == 0) {
      return ResponsePatterns(
        completionRate: 0,
        dismissalRate: 0,
        snoozeRate: 0,
        averageResponseTime: Duration.zero,
      );
    }

    final completedCount = behaviors
        .where((b) => b.actionType == ReminderActionType.completed)
        .length;
    final dismissedCount = behaviors
        .where((b) => b.actionType == ReminderActionType.dismissed)
        .length;
    final snoozedCount = behaviors
        .where((b) => b.actionType == ReminderActionType.snoozed)
        .length;

    final responseTimes = behaviors.map((b) => b.responseDelayMinutes).toList();
    final avgResponseTime = responseTimes.isNotEmpty
        ? responseTimes.reduce((a, b) => a + b) / totalBehaviors
        : 0.0;

    return ResponsePatterns(
      completionRate: completedCount / totalBehaviors,
      dismissalRate: dismissedCount / totalBehaviors,
      snoozeRate: snoozedCount / totalBehaviors,
      averageResponseTime: Duration(minutes: avgResponseTime.round()),
    );
  }

  /// Analyze optimal times from behavior data
  static Map<MealType, List<TimeSlot>> _analyzeOptimalTimes(
      List<MealReminderBehaviorModel> behaviors) {
    final mealTimeMap = <MealType, List<TimeSlot>>{};

    for (final mealType in MealType.values) {
      final mealBehaviors =
          behaviors.where((b) => b.mealType == mealType).toList();
      if (mealBehaviors.isEmpty) continue;

      final timeSlots = <TimeSlot>[];
      final hourFrequency = <int, List<int>>{};

      // Group behaviors by hour
      for (final behavior in mealBehaviors) {
        final hour = behavior.reminderTime.hour;
        hourFrequency[hour] ??= [];
        if (behavior.actionType == ReminderActionType.completed) {
          hourFrequency[hour]!.add(1);
        } else {
          hourFrequency[hour]!.add(0);
        }
      }

      // Calculate success rates for each hour
      for (final entry in hourFrequency.entries) {
        final hour = entry.key;
        final responses = entry.value;
        final successRate =
            responses.where((r) => r == 1).length / responses.length;

        if (successRate > 0.5) {
          // Only include hours with >50% success rate
          timeSlots.add(TimeSlot(
            startHour: hour,
            endHour: hour + 1,
            successRate: successRate,
            sampleSize: responses.length,
          ));
        }
      }

      timeSlots.sort((a, b) => b.successRate.compareTo(a.successRate));
      mealTimeMap[mealType] = timeSlots.take(3).toList(); // Top 3 time slots
    }

    return mealTimeMap;
  }

  /// Analyze engagement trends over time
  static EngagementTrends _analyzeEngagementTrends(
      List<MealReminderBehaviorModel> behaviors) {
    final sortedBehaviors = List<MealReminderBehaviorModel>.from(behaviors)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final weeklyEngagement = <int, double>{};
    final now = DateTime.now();

    for (int week = 0; week < 4; week++) {
      final weekStart = now.subtract(Duration(days: (week + 1) * 7));
      final weekEnd = now.subtract(Duration(days: week * 7));

      final weekBehaviors = sortedBehaviors
          .where((b) =>
              b.createdAt.isAfter(weekStart) && b.createdAt.isBefore(weekEnd))
          .toList();

      if (weekBehaviors.isNotEmpty) {
        final completionRate = weekBehaviors
                .where((b) => b.actionType == ReminderActionType.completed)
                .length /
            weekBehaviors.length;
        weeklyEngagement[week] = completionRate;
      }
    }

    double trend = 0.0;
    if (weeklyEngagement.length >= 2) {
      final values = weeklyEngagement.values.toList();
      trend = (values.last - values.first) / values.length;
    }

    return EngagementTrends(
      weeklyEngagement: weeklyEngagement,
      overallTrend: trend,
      isImproving: trend > 0.05,
      isDecreasing: trend < -0.05,
    );
  }

  /// Generate personalized insights based on analysis
  static List<String> _generatePersonalizedInsights(
    ResponsePatterns responsePatterns,
    Map<MealType, List<TimeSlot>> timePatterns,
    EngagementTrends engagementTrends,
  ) {
    final insights = <String>[];

    // Completion rate insights
    if (responsePatterns.completionRate > 0.8) {
      insights.add(
          'Mükemmel! Hatırlatıcılara %${(responsePatterns.completionRate * 100).toStringAsFixed(0)} oranında yanıt veriyorsunuz.');
    } else if (responsePatterns.completionRate > 0.6) {
      insights.add(
          'İyi gidiyorsunuz! Hatırlatıcı yanıt oranınız %${(responsePatterns.completionRate * 100).toStringAsFixed(0)}.');
    } else {
      insights.add(
          'Hatırlatıcılara daha sık yanıt vermeye çalışın. Şu anki oran: %${(responsePatterns.completionRate * 100).toStringAsFixed(0)}');
    }

    // Response time insights
    if (responsePatterns.averageResponseTime.inMinutes < 5) {
      insights.add(
          'Hatırlatıcılara çok hızlı yanıt veriyorsunuz! (Ortalama ${responsePatterns.averageResponseTime.inMinutes} dakika)');
    } else if (responsePatterns.averageResponseTime.inMinutes > 30) {
      insights.add(
          'Hatırlatıcılara yanıt verme sürenizi kısaltmaya çalışın. (Ortalama ${responsePatterns.averageResponseTime.inMinutes} dakika)');
    }

    // Time pattern insights
    for (final entry in timePatterns.entries) {
      final mealType = entry.key;
      final timeSlots = entry.value;

      if (timeSlots.isNotEmpty) {
        final bestTime = timeSlots.first;
        insights.add(
            '${_getMealTypeName(mealType)} için en iyi zamanınız ${bestTime.startHour}:00 - ${bestTime.endHour}:00 arası.');
      }
    }

    // Trend insights
    if (engagementTrends.isImproving) {
      insights.add('Harika! Hatırlatıcılarla etkileşiminiz giderek artıyor.');
    } else if (engagementTrends.isDecreasing) {
      insights.add(
          'Son zamanlarda hatırlatıcılarla etkileşiminiz azalmış. Motivasyonunuzu tekrar bulun!');
    }

    // Snooze insights
    if (responsePatterns.snoozeRate > 0.3) {
      insights.add(
          'Çok fazla erteleme yapıyorsunuz. Hatırlatıcı zamanlarını gözden geçirmeyi deneyin.');
    }

    return insights;
  }

  /// Calculate engagement score from behaviors
  static double _calculateEngagementScore(
      List<MealReminderBehaviorModel> behaviors) {
    if (behaviors.isEmpty) return 0.0;

    double totalScore =
        behaviors.map((b) => b.engagementScore).reduce((a, b) => a + b);
    return totalScore / behaviors.length;
  }


  /// Calculate hour-based score for prediction
  static double _calculateHourScore(
      int hour, List<MealReminderBehaviorModel> behaviors, MealType mealType) {
    final mealBehaviors = behaviors
        .where((b) => b.mealType == mealType && b.reminderTime.hour == hour)
        .toList();

    if (mealBehaviors.isEmpty) return 0.5; // Default

    final completedCount = mealBehaviors
        .where((b) => b.actionType == ReminderActionType.completed)
        .length;
    return completedCount / mealBehaviors.length;
  }

  /// Calculate day-based score for prediction
  static double _calculateDayScore(
      int weekday, List<MealReminderBehaviorModel> behaviors) {
    final dayBehaviors =
        behaviors.where((b) => b.reminderTime.weekday == weekday).toList();

    if (dayBehaviors.isEmpty) return 0.5; // Default

    return _calculateEngagementScore(dayBehaviors);
  }

  /// Calculate confidence level for optimization
  static double _calculateConfidence(int successCount, int totalCount) {
    if (totalCount < 5) return 0.3; // Low confidence
    if (totalCount < 10) return 0.6; // Medium confidence
    return 0.9; // High confidence
  }

  /// Get default optimized times when not enough data
  static List<OptimizedReminderTime> _getDefaultOptimizedTimes(
      MealType mealType) {
    switch (mealType) {
      case MealType.breakfast:
        return [
          OptimizedReminderTime(
              hour: 7, minute: 30, successRate: 0.5, confidence: 0.3),
          OptimizedReminderTime(
              hour: 8, minute: 0, successRate: 0.5, confidence: 0.3),
          OptimizedReminderTime(
              hour: 8, minute: 30, successRate: 0.5, confidence: 0.3),
        ];
      case MealType.lunch:
        return [
          OptimizedReminderTime(
              hour: 12, minute: 0, successRate: 0.5, confidence: 0.3),
          OptimizedReminderTime(
              hour: 12, minute: 30, successRate: 0.5, confidence: 0.3),
          OptimizedReminderTime(
              hour: 13, minute: 0, successRate: 0.5, confidence: 0.3),
        ];
      case MealType.dinner:
        return [
          OptimizedReminderTime(
              hour: 19, minute: 0, successRate: 0.5, confidence: 0.3),
          OptimizedReminderTime(
              hour: 19, minute: 30, successRate: 0.5, confidence: 0.3),
          OptimizedReminderTime(
              hour: 20, minute: 0, successRate: 0.5, confidence: 0.3),
        ];
      case MealType.snack:
        return [
          OptimizedReminderTime(
              hour: 15, minute: 0, successRate: 0.5, confidence: 0.3),
          OptimizedReminderTime(
              hour: 21, minute: 0, successRate: 0.5, confidence: 0.3),
        ];
    }
  }

  /// Get localized meal type name
  static String _getMealTypeName(MealType mealType) {
    switch (mealType) {
      case MealType.breakfast:
        return 'Kahvaltı';
      case MealType.lunch:
        return 'Öğle yemeği';
      case MealType.dinner:
        return 'Akşam yemeği';
      case MealType.snack:
        return 'Ara öğün';
    }
  }
}

/// Result of behavior analysis
class BehaviorAnalysisResult {
  final bool hasEnoughData;
  final int totalInteractions;
  final ResponsePatterns? responsePatterns;
  final Map<MealType, List<TimeSlot>>? optimalTimes;
  final EngagementTrends? engagementTrends;
  final List<String> insights;

  BehaviorAnalysisResult({
    required this.hasEnoughData,
    required this.totalInteractions,
    this.responsePatterns,
    this.optimalTimes,
    this.engagementTrends,
    required this.insights,
  });
}

/// Response patterns analysis
class ResponsePatterns {
  final double completionRate;
  final double dismissalRate;
  final double snoozeRate;
  final Duration averageResponseTime;

  ResponsePatterns({
    required this.completionRate,
    required this.dismissalRate,
    required this.snoozeRate,
    required this.averageResponseTime,
  });
}

/// Time slot with success rate
class TimeSlot {
  final int startHour;
  final int endHour;
  final double successRate;
  final int sampleSize;

  TimeSlot({
    required this.startHour,
    required this.endHour,
    required this.successRate,
    required this.sampleSize,
  });
}

/// Engagement trends over time
class EngagementTrends {
  final Map<int, double> weeklyEngagement;
  final double overallTrend;
  final bool isImproving;
  final bool isDecreasing;

  EngagementTrends({
    required this.weeklyEngagement,
    required this.overallTrend,
    required this.isImproving,
    required this.isDecreasing,
  });
}

/// Optimized reminder time with metrics
class OptimizedReminderTime {
  final int hour;
  final int minute;
  final double successRate;
  final double confidence;

  OptimizedReminderTime({
    required this.hour,
    required this.minute,
    required this.successRate,
    required this.confidence,
  });

  DateTime toDateTime() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  String get formattedTime {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}
