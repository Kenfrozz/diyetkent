
// Enum tanımlamaları
enum Gender {
  male,
  female,
  other,
}

enum ActivityLevel {
  sedentary, // Hareketsiz (oturarak çalışan)
  lightly, // Hafif aktif (haftada 1-3 gün egzersiz)
  moderately, // Orta düzeyde aktif (haftada 3-5 gün egzersiz)
  very, // Çok aktif (haftada 6-7 gün egzersiz)
  extremely, // Aşırı aktif (günde 2x egzersiz, ağır fiziksel iş)
}

enum DietaryRestriction {
  none,
  vegetarian,
  vegan,
  glutenFree,
  lactoseIntolerant,
  diabetic,
  lowSodium,
  lowFat,
  ketogenic,
  mediterranean,
  other,
}

enum HealthCondition {
  none,
  diabetes,
  hypertension,
  heartDisease,
  thyroidDisorders,
  kidneyDisease,
  liverDisease,
  gastrointestinalIssues,
  foodAllergies,
  eatingDisorders,
  other,
}

enum GoalType {
  weightLoss,
  weightGain,
  maintainWeight,
  muscleGain,
  improveHealth,
  manageCondition,
  improveEnergy,
  other,
}

// Embedded sınıflar

class PersonalInfo {
  String? firstName;
  String? lastName;
  String? email;
  late int age;
  DateTime? dateOfBirth;
  
  late Gender gender;
  late String occupation;
  double? height; // cm
  double? currentWeight; // kg
  double? weight; // kg - alias for currentWeight
  double? targetWeight; // kg
  String? phoneNumber;
  String? phone; // alias for phoneNumber
  String? emergencyContact;
  String? address;

  PersonalInfo();

  PersonalInfo.create({
    this.firstName,
    this.lastName,
    this.email,
    required this.age,
    this.dateOfBirth,
    required this.gender,
    required this.occupation,
    this.height,
    this.currentWeight,
    this.weight,
    this.targetWeight,
    this.phoneNumber,
    this.phone,
    this.emergencyContact,
    this.address,
  }) {
    // Sync weight and currentWeight
    if (weight != null && currentWeight == null) {
      currentWeight = weight;
    }
    if (currentWeight != null && weight == null) {
      weight = currentWeight;
    }
    
    // Sync phone and phoneNumber
    if (phone != null && phoneNumber == null) {
      phoneNumber = phone;
    }
    if (phoneNumber != null && phone == null) {
      phone = phoneNumber;
    }
  }

  // BMI hesaplama
  double? get bmi {
    if (height == null || currentWeight == null || height! <= 0) return null;
    double heightInMeters = height! / 100;
    return currentWeight! / (heightInMeters * heightInMeters);
  }

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'age': age,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender.name,
      'occupation': occupation,
      'height': height,
      'currentWeight': currentWeight,
      'weight': weight,
      'targetWeight': targetWeight,
      'phoneNumber': phoneNumber,
      'phone': phone,
      'emergencyContact': emergencyContact,
      'address': address,
    };
  }

  factory PersonalInfo.fromMap(Map<String, dynamic> map) {
    return PersonalInfo.create(
      firstName: map['firstName'],
      lastName: map['lastName'],
      email: map['email'],
      age: map['age'] ?? 0,
      dateOfBirth: map['dateOfBirth'] != null ? DateTime.tryParse(map['dateOfBirth']) : null,
      gender: Gender.values.firstWhere(
        (e) => e.name == map['gender'],
        orElse: () => Gender.other,
      ),
      occupation: map['occupation'] ?? '',
      height: map['height']?.toDouble(),
      currentWeight: map['currentWeight']?.toDouble(),
      weight: map['weight']?.toDouble(),
      targetWeight: map['targetWeight']?.toDouble(),
      phoneNumber: map['phoneNumber'],
      phone: map['phone'],
      emergencyContact: map['emergencyContact'],
      address: map['address'],
    );
  }
}
class MedicalHistory {
  List<String> conditions = <String>[];
  List<String> medications = <String>[];
  List<String> chronicDiseases = <String>[]; // alias for conditions
  List<String> currentMedications = <String>[]; // alias for medications
  List<String> allergies = <String>[];
  List<String> supplements = <String>[];
  String? familyHistory;
  String? previousDietHistory;
  bool hasChronicConditions = false;
  bool isTakingMedications = false;
  bool hasAllergies = false;
  bool isPregnant = false;
  bool isBreastfeeding = false;
  String? additionalNotes;

  MedicalHistory();

  MedicalHistory.create({
    List<String>? conditions,
    List<String>? medications,
    List<String>? chronicDiseases,
    List<String>? currentMedications,
    List<String>? allergies,
    List<String>? supplements,
    this.familyHistory,
    this.previousDietHistory,
    this.hasChronicConditions = false,
    this.isTakingMedications = false,
    this.hasAllergies = false,
    this.isPregnant = false,
    this.isBreastfeeding = false,
    this.additionalNotes,
  }) {
    this.conditions = conditions ?? <String>[];
    this.medications = medications ?? <String>[];
    this.chronicDiseases = chronicDiseases ?? this.conditions;
    this.currentMedications = currentMedications ?? this.medications;
    this.allergies = allergies ?? <String>[];
    this.supplements = supplements ?? <String>[];
    
    // Sync conditions and chronicDiseases
    if (this.chronicDiseases.isEmpty && this.conditions.isNotEmpty) {
      this.chronicDiseases = List.from(this.conditions);
    }
    if (this.conditions.isEmpty && this.chronicDiseases.isNotEmpty) {
      this.conditions = List.from(this.chronicDiseases);
    }
    
    // Sync medications and currentMedications
    if (this.currentMedications.isEmpty && this.medications.isNotEmpty) {
      this.currentMedications = List.from(this.medications);
    }
    if (this.medications.isEmpty && this.currentMedications.isNotEmpty) {
      this.medications = List.from(this.currentMedications);
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'conditions': conditions,
      'medications': medications,
      'chronicDiseases': chronicDiseases,
      'currentMedications': currentMedications,
      'allergies': allergies,
      'supplements': supplements,
      'familyHistory': familyHistory,
      'previousDietHistory': previousDietHistory,
      'hasChronicConditions': hasChronicConditions,
      'isTakingMedications': isTakingMedications,
      'hasAllergies': hasAllergies,
      'isPregnant': isPregnant,
      'isBreastfeeding': isBreastfeeding,
      'additionalNotes': additionalNotes,
    };
  }

  factory MedicalHistory.fromMap(Map<String, dynamic> map) {
    return MedicalHistory.create(
      conditions: List<String>.from(map['conditions'] ?? []),
      medications: List<String>.from(map['medications'] ?? []),
      chronicDiseases: List<String>.from(map['chronicDiseases'] ?? []),
      currentMedications: List<String>.from(map['currentMedications'] ?? []),
      allergies: List<String>.from(map['allergies'] ?? []),
      supplements: List<String>.from(map['supplements'] ?? []),
      familyHistory: map['familyHistory'],
      previousDietHistory: map['previousDietHistory'],
      hasChronicConditions: map['hasChronicConditions'] ?? false,
      isTakingMedications: map['isTakingMedications'] ?? false,
      hasAllergies: map['hasAllergies'] ?? false,
      isPregnant: map['isPregnant'] ?? false,
      isBreastfeeding: map['isBreastfeeding'] ?? false,
      additionalNotes: map['additionalNotes'],
    );
  }
}
class NutritionHabits {
  int mealsPerDay = 3;
  int snacksPerDay = 0;
  double waterIntakePerDay = 2.0; // liters
  double? waterIntake; // alias for waterIntakePerDay
  List<String> foodPreferences = <String>[];
  List<String> dislikedFoods = <String>[];
  
  DietaryRestriction dietaryRestriction = DietaryRestriction.none;
  String? dietType; // string representation of dietaryRestriction
  bool cookAtHome = true;
  bool eatOut = false;
  int eatOutFrequencyPerWeek = 0;
  bool skipBreakfast = false;
  bool lateNightEating = false;
  bool emotionalEating = false;
  String? typicalDay;
  String? additionalNotes;

  NutritionHabits();

  NutritionHabits.create({
    this.mealsPerDay = 3,
    this.snacksPerDay = 0,
    this.waterIntakePerDay = 2.0,
    this.waterIntake,
    List<String>? foodPreferences,
    List<String>? dislikedFoods,
    this.dietaryRestriction = DietaryRestriction.none,
    this.dietType,
    this.cookAtHome = true,
    this.eatOut = false,
    this.eatOutFrequencyPerWeek = 0,
    this.skipBreakfast = false,
    this.lateNightEating = false,
    this.emotionalEating = false,
    this.typicalDay,
    this.additionalNotes,
  }) {
    this.foodPreferences = foodPreferences ?? <String>[];
    this.dislikedFoods = dislikedFoods ?? <String>[];
    
    // Sync waterIntake and waterIntakePerDay
    if (waterIntake != null && waterIntakePerDay == 2.0) {
      waterIntakePerDay = waterIntake!;
    }
    waterIntake ??= waterIntakePerDay;
    
    // Sync dietType and dietaryRestriction  
    dietType ??= dietaryRestriction.name;
  }

  Map<String, dynamic> toMap() {
    return {
      'mealsPerDay': mealsPerDay,
      'snacksPerDay': snacksPerDay,
      'waterIntakePerDay': waterIntakePerDay,
      'foodPreferences': foodPreferences,
      'dislikedFoods': dislikedFoods,
      'dietaryRestriction': dietaryRestriction.name,
      'cookAtHome': cookAtHome,
      'eatOut': eatOut,
      'eatOutFrequencyPerWeek': eatOutFrequencyPerWeek,
      'skipBreakfast': skipBreakfast,
      'lateNightEating': lateNightEating,
      'emotionalEating': emotionalEating,
      'typicalDay': typicalDay,
      'additionalNotes': additionalNotes,
    };
  }

  factory NutritionHabits.fromMap(Map<String, dynamic> map) {
    return NutritionHabits.create(
      mealsPerDay: map['mealsPerDay'] ?? 3,
      snacksPerDay: map['snacksPerDay'] ?? 0,
      waterIntakePerDay: map['waterIntakePerDay']?.toDouble() ?? 2.0,
      foodPreferences: List<String>.from(map['foodPreferences'] ?? []),
      dislikedFoods: List<String>.from(map['dislikedFoods'] ?? []),
      dietaryRestriction: DietaryRestriction.values.firstWhere(
        (e) => e.name == map['dietaryRestriction'],
        orElse: () => DietaryRestriction.none,
      ),
      cookAtHome: map['cookAtHome'] ?? true,
      eatOut: map['eatOut'] ?? false,
      eatOutFrequencyPerWeek: map['eatOutFrequencyPerWeek'] ?? 0,
      skipBreakfast: map['skipBreakfast'] ?? false,
      lateNightEating: map['lateNightEating'] ?? false,
      emotionalEating: map['emotionalEating'] ?? false,
      typicalDay: map['typicalDay'],
      additionalNotes: map['additionalNotes'],
    );
  }
}
class PhysicalActivity {
  
  ActivityLevel activityLevel = ActivityLevel.sedentary;
  int exerciseFrequencyPerWeek = 0;
  int? exerciseFrequency; // alias for exerciseFrequencyPerWeek
  int exerciseDurationMinutes = 0;
  List<String> preferredActivities = <String>[];
  List<String> dislikedActivities = <String>[];
  bool hasPhysicalLimitations = false;
  List<String> physicalLimitations = <String>[];
  int dailySteps = 0;
  String? workType; // desk job, physical job, etc.
  bool usesFitnessTracker = false;
  String? additionalNotes;

  PhysicalActivity();

  PhysicalActivity.create({
    this.activityLevel = ActivityLevel.sedentary,
    this.exerciseFrequencyPerWeek = 0,
    this.exerciseFrequency,
    this.exerciseDurationMinutes = 0,
    List<String>? preferredActivities,
    List<String>? dislikedActivities,
    this.hasPhysicalLimitations = false,
    List<String>? physicalLimitations,
    this.dailySteps = 0,
    this.workType,
    this.usesFitnessTracker = false,
    this.additionalNotes,
  }) {
    this.preferredActivities = preferredActivities ?? <String>[];
    this.dislikedActivities = dislikedActivities ?? <String>[];
    this.physicalLimitations = physicalLimitations ?? <String>[];
    
    // Sync exerciseFrequency and exerciseFrequencyPerWeek
    if (exerciseFrequency != null && exerciseFrequencyPerWeek == 0) {
      exerciseFrequencyPerWeek = exerciseFrequency!;
    }
    exerciseFrequency ??= exerciseFrequencyPerWeek;
  }

  Map<String, dynamic> toMap() {
    return {
      'activityLevel': activityLevel.name,
      'exerciseFrequencyPerWeek': exerciseFrequencyPerWeek,
      'exerciseFrequency': exerciseFrequency,
      'exerciseDurationMinutes': exerciseDurationMinutes,
      'preferredActivities': preferredActivities,
      'dislikedActivities': dislikedActivities,
      'hasPhysicalLimitations': hasPhysicalLimitations,
      'physicalLimitations': physicalLimitations,
      'dailySteps': dailySteps,
      'workType': workType,
      'usesFitnessTracker': usesFitnessTracker,
      'additionalNotes': additionalNotes,
    };
  }

  factory PhysicalActivity.fromMap(Map<String, dynamic> map) {
    return PhysicalActivity.create(
      activityLevel: ActivityLevel.values.firstWhere(
        (e) => e.name == map['activityLevel'],
        orElse: () => ActivityLevel.sedentary,
      ),
      exerciseFrequencyPerWeek: map['exerciseFrequencyPerWeek'] ?? 0,
      exerciseFrequency: map['exerciseFrequency'],
      exerciseDurationMinutes: map['exerciseDurationMinutes'] ?? 0,
      preferredActivities: List<String>.from(map['preferredActivities'] ?? []),
      dislikedActivities: List<String>.from(map['dislikedActivities'] ?? []),
      hasPhysicalLimitations: map['hasPhysicalLimitations'] ?? false,
      physicalLimitations: List<String>.from(map['physicalLimitations'] ?? []),
      dailySteps: map['dailySteps'] ?? 0,
      workType: map['workType'],
      usesFitnessTracker: map['usesFitnessTracker'] ?? false,
      additionalNotes: map['additionalNotes'],
    );
  }
}
class Goals {
  
  GoalType primaryGoal = GoalType.improveHealth;
  List<String> secondaryGoals = <String>[];
  double? targetWeightLoss; // kg
  double? targetWeightGain; // kg
  double? targetWeight; // combined target weight
  int timeframeWeeks = 12;
  int? timeFrame; // alias for timeframeWeeks
  String? specificMotivation;
  List<String> previousAttempts = <String>[];
  String? biggestChallenge;
  String? supportSystem;
  int motivationLevel = 5; // 1-10 scale
  bool willingToMakeChanges = true;
  String? additionalNotes;

  Goals();

  Goals.create({
    this.primaryGoal = GoalType.improveHealth,
    List<String>? secondaryGoals,
    this.targetWeightLoss,
    this.targetWeightGain,
    this.targetWeight,
    this.timeframeWeeks = 12,
    this.timeFrame,
    this.specificMotivation,
    List<String>? previousAttempts,
    this.biggestChallenge,
    this.supportSystem,
    this.motivationLevel = 5,
    this.willingToMakeChanges = true,
    this.additionalNotes,
  }) {
    this.secondaryGoals = secondaryGoals ?? <String>[];
    this.previousAttempts = previousAttempts ?? <String>[];
    
    // Sync timeFrame and timeframeWeeks
    if (timeFrame != null && timeframeWeeks == 12) {
      timeframeWeeks = timeFrame!;
    }
    timeFrame ??= timeframeWeeks;
    
    // Set targetWeight based on goal type
    if (targetWeight == null) {
      if (primaryGoal == GoalType.weightLoss && targetWeightLoss != null) {
        targetWeight = targetWeightLoss;
      } else if (primaryGoal == GoalType.weightGain && targetWeightGain != null) {
        targetWeight = targetWeightGain;
      }
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'primaryGoal': primaryGoal.name,
      'secondaryGoals': secondaryGoals,
      'targetWeightLoss': targetWeightLoss,
      'targetWeightGain': targetWeightGain,
      'targetWeight': targetWeight,
      'timeframeWeeks': timeframeWeeks,
      'timeFrame': timeFrame,
      'specificMotivation': specificMotivation,
      'previousAttempts': previousAttempts,
      'biggestChallenge': biggestChallenge,
      'supportSystem': supportSystem,
      'motivationLevel': motivationLevel,
      'willingToMakeChanges': willingToMakeChanges,
      'additionalNotes': additionalNotes,
    };
  }

  factory Goals.fromMap(Map<String, dynamic> map) {
    return Goals.create(
      primaryGoal: GoalType.values.firstWhere(
        (e) => e.name == map['primaryGoal'],
        orElse: () => GoalType.improveHealth,
      ),
      secondaryGoals: List<String>.from(map['secondaryGoals'] ?? []),
      targetWeightLoss: map['targetWeightLoss']?.toDouble(),
      targetWeightGain: map['targetWeightGain']?.toDouble(),
      targetWeight: map['targetWeight']?.toDouble(),
      timeframeWeeks: map['timeframeWeeks'] ?? 12,
      timeFrame: map['timeFrame'],
      specificMotivation: map['specificMotivation'],
      previousAttempts: List<String>.from(map['previousAttempts'] ?? []),
      biggestChallenge: map['biggestChallenge'],
      supportSystem: map['supportSystem'],
      motivationLevel: map['motivationLevel'] ?? 5,
      willingToMakeChanges: map['willingToMakeChanges'] ?? true,
      additionalNotes: map['additionalNotes'],
    );
  }
}

// Dinamik form rendering için yardımcı sınıflar

class FormField {
  late String fieldId;
  late String fieldType; // text, number, select, multiselect, boolean, date
  late String label;
  String? placeholder;
  bool isRequired = false;
  String? validationPattern;
  String? errorMessage;
  List<String> options = <String>[];
  String? value;
  int order = 0;

  FormField();

  FormField.create({
    required this.fieldId,
    required this.fieldType,
    required this.label,
    this.placeholder,
    this.isRequired = false,
    this.validationPattern,
    this.errorMessage,
    List<String>? options,
    this.value,
    this.order = 0,
  }) {
    this.options = options ?? <String>[];
  }

  Map<String, dynamic> toMap() {
    return {
      'fieldId': fieldId,
      'fieldType': fieldType,
      'label': label,
      'placeholder': placeholder,
      'isRequired': isRequired,
      'validationPattern': validationPattern,
      'errorMessage': errorMessage,
      'options': options,
      'value': value,
      'order': order,
    };
  }

  factory FormField.fromMap(Map<String, dynamic> map) {
    return FormField.create(
      fieldId: map['fieldId'] ?? '',
      fieldType: map['fieldType'] ?? 'text',
      label: map['label'] ?? '',
      placeholder: map['placeholder'],
      isRequired: map['isRequired'] ?? false,
      validationPattern: map['validationPattern'],
      errorMessage: map['errorMessage'],
      options: List<String>.from(map['options'] ?? []),
      value: map['value'],
      order: map['order'] ?? 0,
    );
  }
}
class FormSection {
  late String sectionId;
  late String title;
  String? description;
  List<FormField> fields = <FormField>[];
  int order = 0;
  bool isCollapsible = false;
  bool isExpanded = true;

  FormSection();

  FormSection.create({
    required this.sectionId,
    required this.title,
    this.description,
    List<FormField>? fields,
    this.order = 0,
    this.isCollapsible = false,
    this.isExpanded = true,
  }) {
    this.fields = fields ?? <FormField>[];
  }

  Map<String, dynamic> toMap() {
    return {
      'sectionId': sectionId,
      'title': title,
      'description': description,
      'fields': fields.map((field) => field.toMap()).toList(),
      'order': order,
      'isCollapsible': isCollapsible,
      'isExpanded': isExpanded,
    };
  }

  factory FormSection.fromMap(Map<String, dynamic> map) {
    return FormSection.create(
      sectionId: map['sectionId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      fields: (map['fields'] as List<dynamic>?)
          ?.map((fieldMap) => FormField.fromMap(fieldMap as Map<String, dynamic>))
          .toList() ?? <FormField>[],
      order: map['order'] ?? 0,
      isCollapsible: map['isCollapsible'] ?? false,
      isExpanded: map['isExpanded'] ?? true,
    );
  }
}

// Ana collection

class PreConsultationFormModel {
  

  
  late String formId;

  
  late String userId;

  late String dietitianId;

  // Embedded data sections
  late PersonalInfo personalInfo;
  late MedicalHistory medicalHistory;
  late NutritionHabits nutritionHabits;
  late PhysicalActivity physicalActivity;
  late Goals goals;

  // Dynamic form sections for extensibility
  List<FormSection> dynamicSections = <FormSection>[];

  // Form metadata
  bool isCompleted = false;
  bool isSubmitted = false;
  bool isReviewed = false;
  String? reviewNotes;
  double completionPercentage = 0.0;
  double riskScore = 0.0;
  String riskLevel = 'low'; // low, medium, high
  List<String> riskFactors = <String>[];

  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
  DateTime? submittedAt;
  DateTime? reviewedAt;

  PreConsultationFormModel();

  PreConsultationFormModel.create({
    required this.formId,
    required this.userId,
    required this.dietitianId,
    required this.personalInfo,
    required this.medicalHistory,
    required this.nutritionHabits,
    required this.physicalActivity,
    required this.goals,
    List<FormSection>? dynamicSections,
    this.isCompleted = false,
    this.isSubmitted = false,
    this.isReviewed = false,
    this.reviewNotes,
    this.completionPercentage = 0.0,
    this.riskScore = 0.0,
    this.riskLevel = 'low',
    List<String>? riskFactors,
  }) {
    this.dynamicSections = dynamicSections ?? <FormSection>[];
    this.riskFactors = riskFactors ?? <String>[];
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
  }

  // Risk scoring algoritması (gelişmiş)
  void calculateRiskScore() {
    // Import risk calculator - bu dosyanın en üstüne eklenecek
    // import '../utils/risk_calculator.dart';
    
    // Basit risk hesaplama (gelişmiş hesaplama için utils/risk_calculator.dart kullanın)
    double score = 0.0;
    List<String> factors = <String>[];

    // BMI riski
    final bmi = personalInfo.bmi;
    if (bmi != null) {
      if (bmi < 18.5) {
        score += 1.0;
        factors.add('Düşük BMI (${bmi.toStringAsFixed(1)})');
      } else if (bmi >= 30) {
        score += 2.0;
        factors.add('Yüksek BMI (${bmi.toStringAsFixed(1)})');
      } else if (bmi >= 25) {
        score += 1.0;
        factors.add('Fazla kilolu (BMI: ${bmi.toStringAsFixed(1)})');
      }
    }

    // Yaş riski
    if (personalInfo.age >= 65) {
      score += 1.0;
      factors.add('İleri yaş (${personalInfo.age})');
    }

    // Kronik hastalık riski
    if (medicalHistory.hasChronicConditions) {
      score += 2.0;
      factors.add('Kronik hastalık varlığı');
    }

    // İlaç kullanımı
    if (medicalHistory.isTakingMedications) {
      score += 0.5;
      factors.add('Düzenli ilaç kullanımı');
    }

    // Alerji riski
    if (medicalHistory.hasAllergies) {
      score += 0.5;
      factors.add('Besin alerjisi varlığı');
    }

    // Fiziksel aktivite eksikliği
    if (physicalActivity.activityLevel == ActivityLevel.sedentary) {
      score += 1.0;
      factors.add('Hareketsiz yaşam tarzı');
    }

    // Beslenme alışkanlıkları
    if (nutritionHabits.skipBreakfast) {
      score += 0.5;
      factors.add('Kahvaltı atlama alışkanlığı');
    }

    if (nutritionHabits.lateNightEating) {
      score += 0.5;
      factors.add('Gece geç yeme alışkanlığı');
    }

    if (nutritionHabits.emotionalEating) {
      score += 1.0;
      factors.add('Duygusal yeme bozukluğu');
    }

    // Su tüketimi eksikliği
    if (nutritionHabits.waterIntakePerDay < 2.0) {
      score += 0.5;
      factors.add('Yetersiz su tüketimi');
    }

    // Risk seviyesi belirleme
    riskScore = score;
    riskFactors = factors;

    if (score <= 1.0) {
      riskLevel = 'low';
    } else if (score <= 3.0) {
      riskLevel = 'medium';
    } else {
      riskLevel = 'high';
    }

    updatedAt = DateTime.now();
  }
  
  // Gelişmiş risk hesaplama (RiskCalculator kullanarak)
  void calculateAdvancedRiskScore() {
    // Bu metod service katmanından çağrılacak
    // RiskCalculator.calculateRisk(this) kullanılarak
    updatedAt = DateTime.now();
  }

  // Form tamamlanma yüzdesini hesapla
  void calculateCompletionPercentage() {
    int totalFields = 0;
    int completedFields = 0;

    // PersonalInfo kontrolü
    totalFields += 6; // age, gender, occupation, height, currentWeight, targetWeight
    if (personalInfo.age > 0) completedFields++;
    if (personalInfo.occupation.isNotEmpty) completedFields++;
    if (personalInfo.height != null && personalInfo.height! > 0) completedFields++;
    if (personalInfo.currentWeight != null && personalInfo.currentWeight! > 0) completedFields++;
    if (personalInfo.targetWeight != null && personalInfo.targetWeight! > 0) completedFields++;
    if (personalInfo.phoneNumber?.isNotEmpty == true) completedFields++;

    // MedicalHistory kontrolü
    totalFields += 4; // hasChronicConditions, isTakingMedications, hasAllergies, previousDietHistory
    if (medicalHistory.previousDietHistory?.isNotEmpty == true) completedFields++;
    completedFields++; // hasChronicConditions boolean değeri her zaman sayılır
    completedFields++; // isTakingMedications boolean değeri her zaman sayılır
    completedFields++; // hasAllergies boolean değeri her zaman sayılır

    // NutritionHabits kontrolü
    totalFields += 5; // mealsPerDay, waterIntakePerDay, dietaryRestriction, cookAtHome, typicalDay
    if (nutritionHabits.mealsPerDay > 0) completedFields++;
    if (nutritionHabits.waterIntakePerDay > 0) completedFields++;
    completedFields++; // dietaryRestriction enum her zaman sayılır
    completedFields++; // cookAtHome boolean her zaman sayılır
    if (nutritionHabits.typicalDay?.isNotEmpty == true) completedFields++;

    // PhysicalActivity kontrolü
    totalFields += 4; // activityLevel, exerciseFrequencyPerWeek, workType, dailySteps
    completedFields++; // activityLevel enum her zaman sayılır
    if (physicalActivity.exerciseFrequencyPerWeek >= 0) completedFields++;
    if (physicalActivity.workType?.isNotEmpty == true) completedFields++;
    if (physicalActivity.dailySteps >= 0) completedFields++;

    // Goals kontrolü
    totalFields += 4; // primaryGoal, timeframeWeeks, motivationLevel, specificMotivation
    completedFields++; // primaryGoal enum her zaman sayılır
    if (goals.timeframeWeeks > 0) completedFields++;
    if (goals.motivationLevel >= 1 && goals.motivationLevel <= 10) completedFields++;
    if (goals.specificMotivation?.isNotEmpty == true) completedFields++;

    completionPercentage = totalFields > 0 ? (completedFields / totalFields) * 100 : 0.0;
    
    // Form tamamlanma durumunu güncelle
    isCompleted = completionPercentage >= 80.0;
    updatedAt = DateTime.now();
  }

  // Form gönderim işlemi
  void submitForm() {
    calculateCompletionPercentage();
    calculateRiskScore();
    
    if (isCompleted) {
      isSubmitted = true;
      submittedAt = DateTime.now();
      updatedAt = DateTime.now();
    }
  }

  // Diyetisyen inceleme işlemi
  void reviewForm({required String notes}) {
    reviewNotes = notes;
    isReviewed = true;
    reviewedAt = DateTime.now();
    updatedAt = DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'formId': formId,
      'userId': userId,
      'dietitianId': dietitianId,
      'personalInfo': personalInfo.toMap(),
      'medicalHistory': medicalHistory.toMap(),
      'nutritionHabits': nutritionHabits.toMap(),
      'physicalActivity': physicalActivity.toMap(),
      'goals': goals.toMap(),
      'dynamicSections': dynamicSections.map((section) => section.toMap()).toList(),
      'isCompleted': isCompleted,
      'isSubmitted': isSubmitted,
      'isReviewed': isReviewed,
      'reviewNotes': reviewNotes,
      'completionPercentage': completionPercentage,
      'riskScore': riskScore,
      'riskLevel': riskLevel,
      'riskFactors': riskFactors,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'submittedAt': submittedAt?.millisecondsSinceEpoch,
      'reviewedAt': reviewedAt?.millisecondsSinceEpoch,
    };
  }

  factory PreConsultationFormModel.fromMap(Map<String, dynamic> map) {
    return PreConsultationFormModel.create(
      formId: map['formId'] ?? '',
      userId: map['userId'] ?? '',
      dietitianId: map['dietitianId'] ?? '',
      personalInfo: PersonalInfo.fromMap(map['personalInfo'] ?? {}),
      medicalHistory: MedicalHistory.fromMap(map['medicalHistory'] ?? {}),
      nutritionHabits: NutritionHabits.fromMap(map['nutritionHabits'] ?? {}),
      physicalActivity: PhysicalActivity.fromMap(map['physicalActivity'] ?? {}),
      goals: Goals.fromMap(map['goals'] ?? {}),
      dynamicSections: (map['dynamicSections'] as List<dynamic>?)
          ?.map((sectionMap) => FormSection.fromMap(sectionMap as Map<String, dynamic>))
          .toList() ?? <FormSection>[],
      isCompleted: map['isCompleted'] ?? false,
      isSubmitted: map['isSubmitted'] ?? false,
      isReviewed: map['isReviewed'] ?? false,
      reviewNotes: map['reviewNotes'],
      completionPercentage: map['completionPercentage']?.toDouble() ?? 0.0,
      riskScore: map['riskScore']?.toDouble() ?? 0.0,
      riskLevel: map['riskLevel'] ?? 'low',
      riskFactors: List<String>.from(map['riskFactors'] ?? []),
    );
  }

  // Yardımcı metodlar
  String get statusText {
    if (isReviewed) return 'İncelendi';
    if (isSubmitted) return 'Gönderildi';
    if (isCompleted) return 'Tamamlandı';
    return 'Devam Ediyor';
  }

  String get riskLevelText {
    switch (riskLevel) {
      case 'low':
        return 'Düşük Risk';
      case 'medium':
        return 'Orta Risk';
      case 'high':
        return 'Yüksek Risk';
      default:
        return 'Bilinmiyor';
    }
  }

  String get completionPercentageText {
    return '${completionPercentage.toStringAsFixed(1)}%';
  }
}