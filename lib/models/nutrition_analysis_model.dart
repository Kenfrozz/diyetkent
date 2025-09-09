class NutritionAnalysisModel {
  late String userId;

  
  late String nutritionAnalysisId;

  // Current Diet Type and Pattern
  
  DietType currentDietType = DietType.mixed;
  String? customDietDescription;

  // Meal Patterns
  int mealsPerDay = 3;
  int snacksPerDay = 1;
  
  MealTiming breakfastTime = MealTiming.morning;
  
  MealTiming lunchTime = MealTiming.midday;
  
  MealTiming dinnerTime = MealTiming.evening;
  bool hasLateNightSnacks = false;
  String? mealPatternNotes;

  // Food Preferences
  List<String> favoriteMainFoods = [];
  List<String> favoriteFruits = [];
  List<String> favoriteVegetables = [];
  List<String> favoriteProteins = [];
  List<String> favoriteGrains = [];
  List<String> favoriteDairy = [];
  List<String> favoriteSnacks = [];
  String? cuisinePreferences; // Turkish, Italian, Asian, etc.

  // Food Restrictions and Dislikes
  List<String> dislikedFoods = [];
  List<String> avoidedFoods = [];
  List<String> religiousRestrictions = [];
  List<String> culturalRestrictions = [];
  bool isVegetarian = false;
  bool isVegan = false;
  bool isGlutenFree = false;
  bool isLactoseIntolerant = false;
  String? restrictionNotes;

  // Eating Habits and Behaviors
  
  EatingSpeed eatingSpeed = EatingSpeed.normal;
  
  PortionSize portionSize = PortionSize.normal;
  bool eatsWhenStressed = false;
  bool eatsWhenBored = false;
  bool eatsWhenHappy = false;
  bool skipsBreakfast = false;
  bool skipsLunch = false;
  bool skipsDinner = false;
  String? eatingHabitsNotes;

  // Hydration
  int waterGlassesPerDay = 8;
  int teaCupsPerDay = 2;
  int coffeeCupsPerDay = 1;
  int alcoholicDrinksPerWeek = 0;
  int sugarySodaPerWeek = 0;
  List<String> preferredBeverages = [];
  String? hydrationNotes;

  // Cooking and Food Preparation
  
  CookingFrequency cookingFrequency = CookingFrequency.sometimes;
  
  CookingSkill cookingSkill = CookingSkill.intermediate;
  List<String> cookingMethods = []; // grilling, baking, frying, steaming
  int mealPrepHoursPerWeek = 0;
  bool prefersReadyMeals = false;
  String? cookingNotes;

  // Eating Out and Delivery
  int restaurantMealsPerWeek = 2;
  int takeawayMealsPerWeek = 1;
  int fastFoodMealsPerWeek = 1;
  List<String> preferredRestaurantTypes = [];
  
  OrderingFrequency foodDeliveryFrequency = OrderingFrequency.rarely;
  String? eatingOutNotes;

  // Nutrition Knowledge and Awareness
  
  NutritionKnowledge nutritionKnowledge = NutritionKnowledge.basic;
  bool readsNutritionLabels = false;
  bool countsCalories = false;
  bool tracksNutrients = false;
  bool usesFoodApps = false;
  String? nutritionAwarenessNotes;

  // Previous Diet Experiences
  List<String> previousDiets = [];
  List<String> successfulDietAspects = [];
  List<String> challengingDietAspects = [];
  String? dietHistoryNotes;

  // Current Challenges
  List<String> currentNutritionChallenges = [];
  List<String> barriersTohealthyEating = [];
  String? challengesNotes;

  // Form completion tracking
  bool isComplete = false;
  DateTime? completedAt;

  // Metadata
  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();

  NutritionAnalysisModel();

  NutritionAnalysisModel.create({
    required this.userId,
    required this.nutritionAnalysisId,
    this.currentDietType = DietType.mixed,
    this.customDietDescription,
    this.mealsPerDay = 3,
    this.snacksPerDay = 1,
    this.breakfastTime = MealTiming.morning,
    this.lunchTime = MealTiming.midday,
    this.dinnerTime = MealTiming.evening,
    this.hasLateNightSnacks = false,
    this.mealPatternNotes,
    this.favoriteMainFoods = const [],
    this.favoriteFruits = const [],
    this.favoriteVegetables = const [],
    this.favoriteProteins = const [],
    this.favoriteGrains = const [],
    this.favoriteDairy = const [],
    this.favoriteSnacks = const [],
    this.cuisinePreferences,
    this.dislikedFoods = const [],
    this.avoidedFoods = const [],
    this.religiousRestrictions = const [],
    this.culturalRestrictions = const [],
    this.isVegetarian = false,
    this.isVegan = false,
    this.isGlutenFree = false,
    this.isLactoseIntolerant = false,
    this.restrictionNotes,
    this.eatingSpeed = EatingSpeed.normal,
    this.portionSize = PortionSize.normal,
    this.eatsWhenStressed = false,
    this.eatsWhenBored = false,
    this.eatsWhenHappy = false,
    this.skipsBreakfast = false,
    this.skipsLunch = false,
    this.skipsDinner = false,
    this.eatingHabitsNotes,
    this.waterGlassesPerDay = 8,
    this.teaCupsPerDay = 2,
    this.coffeeCupsPerDay = 1,
    this.alcoholicDrinksPerWeek = 0,
    this.sugarySodaPerWeek = 0,
    this.preferredBeverages = const [],
    this.hydrationNotes,
    this.cookingFrequency = CookingFrequency.sometimes,
    this.cookingSkill = CookingSkill.intermediate,
    this.cookingMethods = const [],
    this.mealPrepHoursPerWeek = 0,
    this.prefersReadyMeals = false,
    this.cookingNotes,
    this.restaurantMealsPerWeek = 2,
    this.takeawayMealsPerWeek = 1,
    this.fastFoodMealsPerWeek = 1,
    this.preferredRestaurantTypes = const [],
    this.foodDeliveryFrequency = OrderingFrequency.rarely,
    this.eatingOutNotes,
    this.nutritionKnowledge = NutritionKnowledge.basic,
    this.readsNutritionLabels = false,
    this.countsCalories = false,
    this.tracksNutrients = false,
    this.usesFoodApps = false,
    this.nutritionAwarenessNotes,
    this.previousDiets = const [],
    this.successfulDietAspects = const [],
    this.challengingDietAspects = const [],
    this.dietHistoryNotes,
    this.currentNutritionChallenges = const [],
    this.barriersTohealthyEating = const [],
    this.challengesNotes,
    this.isComplete = false,
    this.completedAt,
  }) {
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
  }

  // Calculate nutrition risk score (higher = more risk)
  int get nutritionRiskScore {
    int score = 0;

    // Meal skipping
    if (skipsBreakfast) score += 2;
    if (skipsLunch) score += 1;
    if (skipsDinner) score += 2;

    // Fast food consumption
    if (fastFoodMealsPerWeek > 3) {
      score += 3;
    } else if (fastFoodMealsPerWeek > 1) {
      score += 1;
    }

    // Hydration
    if (waterGlassesPerDay < 6) score += 2;

    // Alcohol and sugary drinks
    if (alcoholicDrinksPerWeek > 7) score += 2;
    if (sugarySodaPerWeek > 3) score += 2;

    // Portion size
    if (portionSize == PortionSize.large) score += 1;
    if (portionSize == PortionSize.extraLarge) score += 2;

    // Emotional eating
    if (eatsWhenStressed) score += 1;
    if (eatsWhenBored) score += 1;

    // Late night eating
    if (hasLateNightSnacks) score += 1;

    // Lack of cooking
    if (cookingFrequency == CookingFrequency.never) score += 2;
    if (prefersReadyMeals) score += 1;

    return score;
  }

  // Get nutrition risk level
  String get nutritionRiskLevel {
    int score = nutritionRiskScore;
    if (score <= 3) return 'low';
    if (score <= 7) return 'moderate';
    if (score <= 12) return 'high';
    return 'veryHigh';
  }

  // Calculate completion percentage
  double get completionPercentage {
    int completedSections = 0;
    int totalSections = 10;

    if (favoriteMainFoods.isNotEmpty || mealPatternNotes != null) completedSections++;
    if (favoriteProteins.isNotEmpty || favoriteFruits.isNotEmpty) completedSections++;
    if (dislikedFoods.isNotEmpty || restrictionNotes != null) completedSections++;
    if (eatingHabitsNotes != null || eatingSpeed != EatingSpeed.normal) completedSections++;
    if (waterGlassesPerDay != 8 || hydrationNotes != null) completedSections++;
    if (cookingFrequency != CookingFrequency.sometimes || cookingNotes != null) completedSections++;
    if (restaurantMealsPerWeek != 2 || eatingOutNotes != null) completedSections++;
    if (nutritionKnowledge != NutritionKnowledge.basic || nutritionAwarenessNotes != null) completedSections++;
    if (previousDiets.isNotEmpty || dietHistoryNotes != null) completedSections++;
    if (currentNutritionChallenges.isNotEmpty || challengesNotes != null) completedSections++;

    return completedSections / totalSections;
  }

  // Firebase conversion methods
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'nutritionAnalysisId': nutritionAnalysisId,
      'currentDietType': currentDietType.name,
      'customDietDescription': customDietDescription,
      'mealsPerDay': mealsPerDay,
      'snacksPerDay': snacksPerDay,
      'breakfastTime': breakfastTime.name,
      'lunchTime': lunchTime.name,
      'dinnerTime': dinnerTime.name,
      'hasLateNightSnacks': hasLateNightSnacks,
      'mealPatternNotes': mealPatternNotes,
      'favoriteMainFoods': favoriteMainFoods,
      'favoriteFruits': favoriteFruits,
      'favoriteVegetables': favoriteVegetables,
      'favoriteProteins': favoriteProteins,
      'favoriteGrains': favoriteGrains,
      'favoriteDairy': favoriteDairy,
      'favoriteSnacks': favoriteSnacks,
      'cuisinePreferences': cuisinePreferences,
      'dislikedFoods': dislikedFoods,
      'avoidedFoods': avoidedFoods,
      'religiousRestrictions': religiousRestrictions,
      'culturalRestrictions': culturalRestrictions,
      'isVegetarian': isVegetarian,
      'isVegan': isVegan,
      'isGlutenFree': isGlutenFree,
      'isLactoseIntolerant': isLactoseIntolerant,
      'restrictionNotes': restrictionNotes,
      'eatingSpeed': eatingSpeed.name,
      'portionSize': portionSize.name,
      'eatsWhenStressed': eatsWhenStressed,
      'eatsWhenBored': eatsWhenBored,
      'eatsWhenHappy': eatsWhenHappy,
      'skipsBreakfast': skipsBreakfast,
      'skipsLunch': skipsLunch,
      'skipsDinner': skipsDinner,
      'eatingHabitsNotes': eatingHabitsNotes,
      'waterGlassesPerDay': waterGlassesPerDay,
      'teaCupsPerDay': teaCupsPerDay,
      'coffeeCupsPerDay': coffeeCupsPerDay,
      'alcoholicDrinksPerWeek': alcoholicDrinksPerWeek,
      'sugarySodaPerWeek': sugarySodaPerWeek,
      'preferredBeverages': preferredBeverages,
      'hydrationNotes': hydrationNotes,
      'cookingFrequency': cookingFrequency.name,
      'cookingSkill': cookingSkill.name,
      'cookingMethods': cookingMethods,
      'mealPrepHoursPerWeek': mealPrepHoursPerWeek,
      'prefersReadyMeals': prefersReadyMeals,
      'cookingNotes': cookingNotes,
      'restaurantMealsPerWeek': restaurantMealsPerWeek,
      'takeawayMealsPerWeek': takeawayMealsPerWeek,
      'fastFoodMealsPerWeek': fastFoodMealsPerWeek,
      'preferredRestaurantTypes': preferredRestaurantTypes,
      'foodDeliveryFrequency': foodDeliveryFrequency.name,
      'eatingOutNotes': eatingOutNotes,
      'nutritionKnowledge': nutritionKnowledge.name,
      'readsNutritionLabels': readsNutritionLabels,
      'countsCalories': countsCalories,
      'tracksNutrients': tracksNutrients,
      'usesFoodApps': usesFoodApps,
      'nutritionAwarenessNotes': nutritionAwarenessNotes,
      'previousDiets': previousDiets,
      'successfulDietAspects': successfulDietAspects,
      'challengingDietAspects': challengingDietAspects,
      'dietHistoryNotes': dietHistoryNotes,
      'currentNutritionChallenges': currentNutritionChallenges,
      'barriersTohealthyEating': barriersTohealthyEating,
      'challengesNotes': challengesNotes,
      'isComplete': isComplete,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory NutritionAnalysisModel.fromMap(Map<String, dynamic> map) {
    return NutritionAnalysisModel.create(
      userId: map['userId'] ?? '',
      nutritionAnalysisId: map['nutritionAnalysisId'] ?? '',
      currentDietType: DietType.values.firstWhere(
        (e) => e.name == map['currentDietType'],
        orElse: () => DietType.mixed,
      ),
      customDietDescription: map['customDietDescription'],
      mealsPerDay: map['mealsPerDay'] ?? 3,
      snacksPerDay: map['snacksPerDay'] ?? 1,
      breakfastTime: MealTiming.values.firstWhere(
        (e) => e.name == map['breakfastTime'],
        orElse: () => MealTiming.morning,
      ),
      lunchTime: MealTiming.values.firstWhere(
        (e) => e.name == map['lunchTime'],
        orElse: () => MealTiming.midday,
      ),
      dinnerTime: MealTiming.values.firstWhere(
        (e) => e.name == map['dinnerTime'],
        orElse: () => MealTiming.evening,
      ),
      hasLateNightSnacks: map['hasLateNightSnacks'] ?? false,
      mealPatternNotes: map['mealPatternNotes'],
      favoriteMainFoods: List<String>.from(map['favoriteMainFoods'] ?? []),
      favoriteFruits: List<String>.from(map['favoriteFruits'] ?? []),
      favoriteVegetables: List<String>.from(map['favoriteVegetables'] ?? []),
      favoriteProteins: List<String>.from(map['favoriteProteins'] ?? []),
      favoriteGrains: List<String>.from(map['favoriteGrains'] ?? []),
      favoriteDairy: List<String>.from(map['favoriteDairy'] ?? []),
      favoriteSnacks: List<String>.from(map['favoriteSnacks'] ?? []),
      cuisinePreferences: map['cuisinePreferences'],
      dislikedFoods: List<String>.from(map['dislikedFoods'] ?? []),
      avoidedFoods: List<String>.from(map['avoidedFoods'] ?? []),
      religiousRestrictions: List<String>.from(map['religiousRestrictions'] ?? []),
      culturalRestrictions: List<String>.from(map['culturalRestrictions'] ?? []),
      isVegetarian: map['isVegetarian'] ?? false,
      isVegan: map['isVegan'] ?? false,
      isGlutenFree: map['isGlutenFree'] ?? false,
      isLactoseIntolerant: map['isLactoseIntolerant'] ?? false,
      restrictionNotes: map['restrictionNotes'],
      eatingSpeed: EatingSpeed.values.firstWhere(
        (e) => e.name == map['eatingSpeed'],
        orElse: () => EatingSpeed.normal,
      ),
      portionSize: PortionSize.values.firstWhere(
        (e) => e.name == map['portionSize'],
        orElse: () => PortionSize.normal,
      ),
      eatsWhenStressed: map['eatsWhenStressed'] ?? false,
      eatsWhenBored: map['eatsWhenBored'] ?? false,
      eatsWhenHappy: map['eatsWhenHappy'] ?? false,
      skipsBreakfast: map['skipsBreakfast'] ?? false,
      skipsLunch: map['skipsLunch'] ?? false,
      skipsDinner: map['skipsDinner'] ?? false,
      eatingHabitsNotes: map['eatingHabitsNotes'],
      waterGlassesPerDay: map['waterGlassesPerDay'] ?? 8,
      teaCupsPerDay: map['teaCupsPerDay'] ?? 2,
      coffeeCupsPerDay: map['coffeeCupsPerDay'] ?? 1,
      alcoholicDrinksPerWeek: map['alcoholicDrinksPerWeek'] ?? 0,
      sugarySodaPerWeek: map['sugarySodaPerWeek'] ?? 0,
      preferredBeverages: List<String>.from(map['preferredBeverages'] ?? []),
      hydrationNotes: map['hydrationNotes'],
      cookingFrequency: CookingFrequency.values.firstWhere(
        (e) => e.name == map['cookingFrequency'],
        orElse: () => CookingFrequency.sometimes,
      ),
      cookingSkill: CookingSkill.values.firstWhere(
        (e) => e.name == map['cookingSkill'],
        orElse: () => CookingSkill.intermediate,
      ),
      cookingMethods: List<String>.from(map['cookingMethods'] ?? []),
      mealPrepHoursPerWeek: map['mealPrepHoursPerWeek'] ?? 0,
      prefersReadyMeals: map['prefersReadyMeals'] ?? false,
      cookingNotes: map['cookingNotes'],
      restaurantMealsPerWeek: map['restaurantMealsPerWeek'] ?? 2,
      takeawayMealsPerWeek: map['takeawayMealsPerWeek'] ?? 1,
      fastFoodMealsPerWeek: map['fastFoodMealsPerWeek'] ?? 1,
      preferredRestaurantTypes: List<String>.from(map['preferredRestaurantTypes'] ?? []),
      foodDeliveryFrequency: OrderingFrequency.values.firstWhere(
        (e) => e.name == map['foodDeliveryFrequency'],
        orElse: () => OrderingFrequency.rarely,
      ),
      eatingOutNotes: map['eatingOutNotes'],
      nutritionKnowledge: NutritionKnowledge.values.firstWhere(
        (e) => e.name == map['nutritionKnowledge'],
        orElse: () => NutritionKnowledge.basic,
      ),
      readsNutritionLabels: map['readsNutritionLabels'] ?? false,
      countsCalories: map['countsCalories'] ?? false,
      tracksNutrients: map['tracksNutrients'] ?? false,
      usesFoodApps: map['usesFoodApps'] ?? false,
      nutritionAwarenessNotes: map['nutritionAwarenessNotes'],
      previousDiets: List<String>.from(map['previousDiets'] ?? []),
      successfulDietAspects: List<String>.from(map['successfulDietAspects'] ?? []),
      challengingDietAspects: List<String>.from(map['challengingDietAspects'] ?? []),
      dietHistoryNotes: map['dietHistoryNotes'],
      currentNutritionChallenges: List<String>.from(map['currentNutritionChallenges'] ?? []),
      barriersTohealthyEating: List<String>.from(map['barriersTohealthyEating'] ?? []),
      challengesNotes: map['challengesNotes'],
      isComplete: map['isComplete'] ?? false,
      completedAt: map['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'])
          : null,
    );
  }
}

// Enums
enum DietType { mixed, vegetarian, vegan, keto, paleo, mediterranean, lowCarb, lowFat, glutenFree, other }

enum MealTiming { earlyMorning, morning, lateMorning, midday, afternoon, evening, lateEvening }

enum EatingSpeed { slow, normal, fast }

enum PortionSize { small, normal, large, extraLarge }

enum CookingFrequency { never, rarely, sometimes, often, daily }

enum CookingSkill { beginner, intermediate, advanced, expert }

enum OrderingFrequency { never, rarely, sometimes, often, daily }

enum NutritionKnowledge { none, basic, intermediate, advanced, expert }

