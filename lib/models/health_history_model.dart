class HealthHistoryModel {
  late String userId;
  late String healthHistoryId;

  // Medical Conditions
  List<String> currentMedicalConditions = [];
  List<String> pastMedicalConditions = [];
  List<String> chronicDiseases = [];
  String? medicalConditionsNotes;

  // Allergies
  List<String> foodAllergies = [];
  List<String> drugAllergies = [];
  List<String> environmentalAllergies = [];
  AllergySeverity foodAllergySeverity = AllergySeverity.none;
  AllergySeverity drugAllergySeverity = AllergySeverity.none;
  String? allergyNotes;

  // Medications & Supplements
  List<String> currentMedications = [];
  List<String> currentSupplements = [];
  List<String> vitaminDeficiencies = [];
  String? medicationNotes;

  // Family Medical History
  List<String> familyDiabetes = [];
  List<String> familyHeartDisease = [];
  List<String> familyObesity = [];
  List<String> familyCancer = [];
  List<String> familyOtherConditions = [];
  String? familyHistoryNotes;

  // Surgical History
  List<String> previousSurgeries = [];
  List<String> hospitalizations = [];
  String? surgicalNotes;

  // Mental Health
  MentalHealthStatus mentalHealthStatus = MentalHealthStatus.good;
  List<String> mentalHealthConditions = [];
  bool takingMentalHealthMedication = false;
  String? mentalHealthNotes;

  // Reproductive Health (if applicable)
  String? menstrualCycleInfo;
  bool isPregnant = false;
  bool isBreastfeeding = false;
  int? numberOfPregnancies;
  String? reproductiveHealthNotes;

  // Form completion tracking
  bool isComplete = false;
  DateTime? completedAt;

  // Metadata
  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();

  HealthHistoryModel();

  HealthHistoryModel.create({
    required this.userId,
    required this.healthHistoryId,
    this.currentMedicalConditions = const [],
    this.pastMedicalConditions = const [],
    this.chronicDiseases = const [],
    this.medicalConditionsNotes,
    this.foodAllergies = const [],
    this.drugAllergies = const [],
    this.environmentalAllergies = const [],
    this.foodAllergySeverity = AllergySeverity.none,
    this.drugAllergySeverity = AllergySeverity.none,
    this.allergyNotes,
    this.currentMedications = const [],
    this.currentSupplements = const [],
    this.vitaminDeficiencies = const [],
    this.medicationNotes,
    this.familyDiabetes = const [],
    this.familyHeartDisease = const [],
    this.familyObesity = const [],
    this.familyCancer = const [],
    this.familyOtherConditions = const [],
    this.familyHistoryNotes,
    this.previousSurgeries = const [],
    this.hospitalizations = const [],
    this.surgicalNotes,
    this.mentalHealthStatus = MentalHealthStatus.good,
    this.mentalHealthConditions = const [],
    this.takingMentalHealthMedication = false,
    this.mentalHealthNotes,
    this.menstrualCycleInfo,
    this.isPregnant = false,
    this.isBreastfeeding = false,
    this.numberOfPregnancies,
    this.reproductiveHealthNotes,
    this.isComplete = false,
    this.completedAt,
  }) {
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
  }

  // Check if health history has any risk factors
  bool get hasHighRiskFactors {
    return chronicDiseases.isNotEmpty ||
           foodAllergySeverity == AllergySeverity.severe ||
           drugAllergySeverity == AllergySeverity.severe ||
           familyDiabetes.isNotEmpty ||
           familyHeartDisease.isNotEmpty ||
           mentalHealthStatus == MentalHealthStatus.poor ||
           currentMedications.length > 3;
  }

  // Get risk factor count
  int get riskFactorCount {
    int count = 0;
    if (chronicDiseases.isNotEmpty) count++;
    if (foodAllergySeverity == AllergySeverity.severe) count++;
    if (drugAllergySeverity == AllergySeverity.severe) count++;
    if (familyDiabetes.isNotEmpty) count++;
    if (familyHeartDisease.isNotEmpty) count++;
    if (familyObesity.isNotEmpty) count++;
    if (mentalHealthStatus == MentalHealthStatus.poor) count++;
    if (currentMedications.length > 3) count++;
    return count;
  }

  // Calculate completion percentage
  double get completionPercentage {
    int completedSections = 0;
    int totalSections = 7;

    // Medical conditions section
    if (currentMedicalConditions.isNotEmpty || pastMedicalConditions.isNotEmpty || medicalConditionsNotes != null) {
      completedSections++;
    }

    // Allergies section
    if (foodAllergies.isNotEmpty || drugAllergies.isNotEmpty || allergyNotes != null) {
      completedSections++;
    }

    // Medications section
    if (currentMedications.isNotEmpty || currentSupplements.isNotEmpty || medicationNotes != null) {
      completedSections++;
    }

    // Family history section
    if (familyDiabetes.isNotEmpty || familyHeartDisease.isNotEmpty || familyHistoryNotes != null) {
      completedSections++;
    }

    // Surgical history section
    if (previousSurgeries.isNotEmpty || hospitalizations.isNotEmpty || surgicalNotes != null) {
      completedSections++;
    }

    // Mental health section
    if (mentalHealthStatus != MentalHealthStatus.good || mentalHealthNotes != null) {
      completedSections++;
    }

    // Reproductive health section (optional)
    if (menstrualCycleInfo != null || reproductiveHealthNotes != null) {
      completedSections++;
    }

    return completedSections / totalSections;
  }

  // Firebase conversion methods
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'healthHistoryId': healthHistoryId,
      'currentMedicalConditions': currentMedicalConditions,
      'pastMedicalConditions': pastMedicalConditions,
      'chronicDiseases': chronicDiseases,
      'medicalConditionsNotes': medicalConditionsNotes,
      'foodAllergies': foodAllergies,
      'drugAllergies': drugAllergies,
      'environmentalAllergies': environmentalAllergies,
      'foodAllergySeverity': foodAllergySeverity.name,
      'drugAllergySeverity': drugAllergySeverity.name,
      'allergyNotes': allergyNotes,
      'currentMedications': currentMedications,
      'currentSupplements': currentSupplements,
      'vitaminDeficiencies': vitaminDeficiencies,
      'medicationNotes': medicationNotes,
      'familyDiabetes': familyDiabetes,
      'familyHeartDisease': familyHeartDisease,
      'familyObesity': familyObesity,
      'familyCancer': familyCancer,
      'familyOtherConditions': familyOtherConditions,
      'familyHistoryNotes': familyHistoryNotes,
      'previousSurgeries': previousSurgeries,
      'hospitalizations': hospitalizations,
      'surgicalNotes': surgicalNotes,
      'mentalHealthStatus': mentalHealthStatus.name,
      'mentalHealthConditions': mentalHealthConditions,
      'takingMentalHealthMedication': takingMentalHealthMedication,
      'mentalHealthNotes': mentalHealthNotes,
      'menstrualCycleInfo': menstrualCycleInfo,
      'isPregnant': isPregnant,
      'isBreastfeeding': isBreastfeeding,
      'numberOfPregnancies': numberOfPregnancies,
      'reproductiveHealthNotes': reproductiveHealthNotes,
      'isComplete': isComplete,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory HealthHistoryModel.fromMap(Map<String, dynamic> map) {
    return HealthHistoryModel.create(
      userId: map['userId'] ?? '',
      healthHistoryId: map['healthHistoryId'] ?? '',
      currentMedicalConditions: List<String>.from(map['currentMedicalConditions'] ?? []),
      pastMedicalConditions: List<String>.from(map['pastMedicalConditions'] ?? []),
      chronicDiseases: List<String>.from(map['chronicDiseases'] ?? []),
      medicalConditionsNotes: map['medicalConditionsNotes'],
      foodAllergies: List<String>.from(map['foodAllergies'] ?? []),
      drugAllergies: List<String>.from(map['drugAllergies'] ?? []),
      environmentalAllergies: List<String>.from(map['environmentalAllergies'] ?? []),
      foodAllergySeverity: AllergySeverity.values.firstWhere(
        (e) => e.name == map['foodAllergySeverity'],
        orElse: () => AllergySeverity.none,
      ),
      drugAllergySeverity: AllergySeverity.values.firstWhere(
        (e) => e.name == map['drugAllergySeverity'],
        orElse: () => AllergySeverity.none,
      ),
      allergyNotes: map['allergyNotes'],
      currentMedications: List<String>.from(map['currentMedications'] ?? []),
      currentSupplements: List<String>.from(map['currentSupplements'] ?? []),
      vitaminDeficiencies: List<String>.from(map['vitaminDeficiencies'] ?? []),
      medicationNotes: map['medicationNotes'],
      familyDiabetes: List<String>.from(map['familyDiabetes'] ?? []),
      familyHeartDisease: List<String>.from(map['familyHeartDisease'] ?? []),
      familyObesity: List<String>.from(map['familyObesity'] ?? []),
      familyCancer: List<String>.from(map['familyCancer'] ?? []),
      familyOtherConditions: List<String>.from(map['familyOtherConditions'] ?? []),
      familyHistoryNotes: map['familyHistoryNotes'],
      previousSurgeries: List<String>.from(map['previousSurgeries'] ?? []),
      hospitalizations: List<String>.from(map['hospitalizations'] ?? []),
      surgicalNotes: map['surgicalNotes'],
      mentalHealthStatus: MentalHealthStatus.values.firstWhere(
        (e) => e.name == map['mentalHealthStatus'],
        orElse: () => MentalHealthStatus.good,
      ),
      mentalHealthConditions: List<String>.from(map['mentalHealthConditions'] ?? []),
      takingMentalHealthMedication: map['takingMentalHealthMedication'] ?? false,
      mentalHealthNotes: map['mentalHealthNotes'],
      menstrualCycleInfo: map['menstrualCycleInfo'],
      isPregnant: map['isPregnant'] ?? false,
      isBreastfeeding: map['isBreastfeeding'] ?? false,
      numberOfPregnancies: map['numberOfPregnancies'],
      reproductiveHealthNotes: map['reproductiveHealthNotes'],
      isComplete: map['isComplete'] ?? false,
      completedAt: map['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'])
          : null,
    );
  }
}

enum AllergySeverity { none, mild, moderate, severe }

enum MentalHealthStatus { excellent, good, fair, poor }