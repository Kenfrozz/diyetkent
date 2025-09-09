import '../models/user_model.dart';
import '../models/health_data_model.dart';

/// Comprehensive BMI calculation engine with range classification
class BMICalculationEngine {
  // BMI range constants for diet file selection
  static const double underweightThreshold = 18.5;
  static const double normalLowerThreshold = 21.0;
  static const double normalUpperThreshold = 25.0;
  static const double overweightLowerThreshold = 26.0;
  static const double overweightUpperThreshold = 29.0;
  static const double obeseLevel1LowerThreshold = 30.0;
  static const double obeseLevel1UpperThreshold = 33.0;
  static const double obeseLevel2LowerThreshold = 34.0;
  static const double obeseLevel2UpperThreshold = 37.0;
  static const double morbidObeseThreshold = 40.0;

  /// Calculate BMI from height (cm) and weight (kg)
  static double? calculateBMI({
    required double? heightCm,
    required double? weightKg,
  }) {
    if (heightCm == null || weightKg == null) return null;
    if (heightCm <= 0 || weightKg <= 0) return null;
    
    // Convert height from cm to meters
    final heightM = heightCm / 100;
    
    // BMI = weight (kg) / height² (m²)
    return weightKg / (heightM * heightM);
  }

  /// Calculate BMI from UserModel
  static double? calculateBMIFromUser(UserModel user) {
    return calculateBMI(
      heightCm: user.currentHeight,
      weightKg: user.currentWeight,
    );
  }

  /// Calculate BMI from HealthDataModel
  static double? calculateBMIFromHealthData(HealthDataModel healthData) {
    return calculateBMI(
      heightCm: healthData.height,
      weightKg: healthData.weight,
    );
  }

  /// Get BMI range for diet file selection (matches folder naming convention)
  static String? getBMIRangeForDietSelection(double? bmi) {
    if (bmi == null) return null;

    if (bmi >= normalLowerThreshold && bmi <= normalUpperThreshold) {
      return '21_25bmi';
    } else if (bmi >= overweightLowerThreshold && bmi <= overweightUpperThreshold) {
      return '26_29bmi';
    } else if (bmi >= obeseLevel1LowerThreshold && bmi <= obeseLevel1UpperThreshold) {
      return '30_33bmi';
    } else if (bmi >= obeseLevel2LowerThreshold && bmi <= obeseLevel2UpperThreshold) {
      return '34_37bmi';
    }

    // Handle edge cases
    if (bmi < normalLowerThreshold) {
      return '21_25bmi'; // Underweight users get normal range diet
    } else if (bmi > obeseLevel2UpperThreshold) {
      return '34_37bmi'; // Severe obesity gets highest range diet
    }

    return null;
  }

  /// Get detailed BMI classification
  static BMIClassification getBMIClassification(double? bmi) {
    if (bmi == null) return BMIClassification.unknown;

    if (bmi < underweightThreshold) {
      return BMIClassification.underweight;
    } else if (bmi >= normalLowerThreshold && bmi <= normalUpperThreshold) {
      return BMIClassification.normal;
    } else if (bmi >= overweightLowerThreshold && bmi <= overweightUpperThreshold) {
      return BMIClassification.overweight;
    } else if (bmi >= obeseLevel1LowerThreshold && bmi <= obeseLevel1UpperThreshold) {
      return BMIClassification.obeseLevel1;
    } else if (bmi >= obeseLevel2LowerThreshold && bmi <= obeseLevel2UpperThreshold) {
      return BMIClassification.obeseLevel2;
    } else if (bmi >= morbidObeseThreshold) {
      return BMIClassification.morbidObese;
    }

    // Edge cases
    if (bmi > underweightThreshold && bmi < normalLowerThreshold) {
      return BMIClassification.borderlineNormal;
    } else if (bmi > normalUpperThreshold && bmi < overweightLowerThreshold) {
      return BMIClassification.borderlineOverweight;
    } else if (bmi > overweightUpperThreshold && bmi < obeseLevel1LowerThreshold) {
      return BMIClassification.borderlineObese;
    }

    return BMIClassification.unknown;
  }

  /// Calculate ideal weight based on age and height (from PRD requirements)
  static double? calculateIdealWeight({
    required double? heightCm,
    required int? age,
  }) {
    if (heightCm == null || age == null || heightCm <= 0 || age <= 0) {
      return null;
    }

    final heightM = heightCm / 100;
    double idealBMI;

    if (age < 35) {
      idealBMI = 21.0;
    } else if (age <= 45) {
      idealBMI = 22.0;
    } else {
      idealBMI = 23.0;
    }

    return heightM * heightM * idealBMI;
  }

  /// Calculate maximum allowed weight based on age and height (from PRD requirements)
  static double? calculateMaximumWeight({
    required double? heightCm,
    required int? age,
  }) {
    if (heightCm == null || age == null || heightCm <= 0 || age <= 0) {
      return null;
    }

    final heightM = heightCm / 100;
    double maxBMI;

    if (age < 35) {
      maxBMI = 27.0;
    } else if (age <= 45) {
      maxBMI = 28.0;
    } else {
      maxBMI = 30.0;
    }

    return heightM * heightM * maxBMI;
  }

  /// Get weight status relative to ideal and maximum weights
  static WeightStatus getWeightStatus({
    required double? currentWeight,
    required double? heightCm,
    required int? age,
  }) {
    if (currentWeight == null) return WeightStatus.unknown;

    final idealWeight = calculateIdealWeight(heightCm: heightCm, age: age);
    final maxWeight = calculateMaximumWeight(heightCm: heightCm, age: age);

    if (idealWeight == null || maxWeight == null) {
      return WeightStatus.unknown;
    }

    if (currentWeight <= idealWeight) {
      return WeightStatus.atIdeal;
    } else if (currentWeight <= maxWeight) {
      return WeightStatus.aboveIdeal;
    } else {
      return WeightStatus.aboveMaximum;
    }
  }

  /// Calculate weight difference from ideal
  static double? getWeightDifferenceFromIdeal({
    required double? currentWeight,
    required double? heightCm,
    required int? age,
  }) {
    if (currentWeight == null) return null;

    final idealWeight = calculateIdealWeight(heightCm: heightCm, age: age);
    if (idealWeight == null) return null;

    return currentWeight - idealWeight;
  }

  /// Get BMI range display name in Turkish
  static String getBMIRangeDisplayName(String bmiRange) {
    switch (bmiRange) {
      case '21_25bmi':
        return 'Normal Kilo (BMI 21-25)';
      case '26_29bmi':
        return 'Fazla Kilolu (BMI 26-29)';
      case '30_33bmi':
        return 'Obez 1. Derece (BMI 30-33)';
      case '34_37bmi':
        return 'Obez 2. Derece (BMI 34-37)';
      default:
        return 'Bilinmeyen Aralık';
    }
  }

  /// Get classification display name in Turkish
  static String getClassificationDisplayName(BMIClassification classification) {
    switch (classification) {
      case BMIClassification.underweight:
        return 'Zayıf';
      case BMIClassification.borderlineNormal:
        return 'Normal Sınırında';
      case BMIClassification.normal:
        return 'Normal';
      case BMIClassification.borderlineOverweight:
        return 'Fazla Kilo Sınırında';
      case BMIClassification.overweight:
        return 'Fazla Kilolu';
      case BMIClassification.borderlineObese:
        return 'Obezite Sınırında';
      case BMIClassification.obeseLevel1:
        return 'Obez (1. Derece)';
      case BMIClassification.obeseLevel2:
        return 'Obez (2. Derece)';
      case BMIClassification.morbidObese:
        return 'Morbid Obez';
      case BMIClassification.unknown:
        return 'Bilinmiyor';
    }
  }

  /// Get health recommendation based on BMI
  static String getHealthRecommendation(BMIClassification classification) {
    switch (classification) {
      case BMIClassification.underweight:
        return 'Kilo alma programı önerilir. Beslenme uzmanına başvurunuz.';
      case BMIClassification.borderlineNormal:
      case BMIClassification.normal:
        return 'Mevcut kilonuzu koruyun. Dengeli beslenmeye devam edin.';
      case BMIClassification.borderlineOverweight:
        return 'Dikkatli olun. Dengeli beslenme ve egzersiz önerilir.';
      case BMIClassification.overweight:
        return 'Kilo verme programı önerilir. Diyet ve egzersiz planı yapın.';
      case BMIClassification.borderlineObese:
        return 'Kilo verme önemli. Beslenme uzmanı desteği alın.';
      case BMIClassification.obeseLevel1:
        return 'Ciddi kilo verme gerekli. Tıbbi destek önerilir.';
      case BMIClassification.obeseLevel2:
        return 'Acil kilo verme gerekli. Mutlaka tıbbi takip altında olun.';
      case BMIClassification.morbidObese:
        return 'Kritik durum. Acil tıbbi müdahale gerekli.';
      case BMIClassification.unknown:
        return 'Değerlendirme için yeterli veri yok.';
    }
  }

  /// Validate user data for BMI calculation
  static ValidationResult validateUserDataForBMI(UserModel user) {
    final errors = <String>[];
    final warnings = <String>[];

    if (user.currentHeight == null || user.currentHeight! <= 0) {
      errors.add('Boy bilgisi geçersiz veya eksik');
    } else {
      if (user.currentHeight! < 100 || user.currentHeight! > 250) {
        warnings.add('Boy değeri olağan dışı görünüyor');
      }
    }

    if (user.currentWeight == null || user.currentWeight! <= 0) {
      errors.add('Kilo bilgisi geçersiz veya eksik');
    } else {
      if (user.currentWeight! < 30 || user.currentWeight! > 300) {
        warnings.add('Kilo değeri olağan dışı görünüyor');
      }
    }

    if (user.age == null || user.age! <= 0) {
      warnings.add('Yaş bilgisi eksik - ideal kilo hesaplanamayabilir');
    } else {
      if (user.age! < 12 || user.age! > 120) {
        warnings.add('Yaş değeri olağan dışı görünüyor');
      }
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Get comprehensive BMI analysis for a user
  static BMIAnalysisResult analyzeBMI(UserModel user) {
    final validation = validateUserDataForBMI(user);
    if (!validation.isValid) {
      return BMIAnalysisResult(
        isValid: false,
        errors: validation.errors,
        warnings: validation.warnings,
      );
    }

    final bmi = calculateBMIFromUser(user);
    final classification = getBMIClassification(bmi);
    final bmiRange = getBMIRangeForDietSelection(bmi);
    final idealWeight = calculateIdealWeight(
      heightCm: user.currentHeight,
      age: user.age,
    );
    final maxWeight = calculateMaximumWeight(
      heightCm: user.currentHeight,
      age: user.age,
    );
    final weightStatus = getWeightStatus(
      currentWeight: user.currentWeight,
      heightCm: user.currentHeight,
      age: user.age,
    );
    final weightDifference = getWeightDifferenceFromIdeal(
      currentWeight: user.currentWeight,
      heightCm: user.currentHeight,
      age: user.age,
    );

    return BMIAnalysisResult(
      isValid: true,
      bmi: bmi,
      classification: classification,
      bmiRangeForDiet: bmiRange,
      idealWeight: idealWeight,
      maximumWeight: maxWeight,
      weightStatus: weightStatus,
      weightDifferenceFromIdeal: weightDifference,
      classificationDisplayName: getClassificationDisplayName(classification),
      healthRecommendation: getHealthRecommendation(classification),
      warnings: validation.warnings,
    );
  }

  /// Get all available BMI ranges for diet files
  static List<String> getAllBMIRanges() {
    return ['21_25bmi', '26_29bmi', '30_33bmi', '34_37bmi'];
  }

  /// Check if BMI range is valid
  static bool isValidBMIRange(String range) {
    return getAllBMIRanges().contains(range);
  }
}

/// BMI Classification enumeration
enum BMIClassification {
  underweight,
  borderlineNormal,
  normal,
  borderlineOverweight,
  overweight,
  borderlineObese,
  obeseLevel1,
  obeseLevel2,
  morbidObese,
  unknown,
}

/// Weight status relative to ideal and maximum weights
enum WeightStatus {
  atIdeal,
  aboveIdeal,
  aboveMaximum,
  unknown,
}

/// Validation result for BMI calculation inputs
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });
}

/// Comprehensive BMI analysis result
class BMIAnalysisResult {
  final bool isValid;
  final double? bmi;
  final BMIClassification? classification;
  final String? bmiRangeForDiet;
  final double? idealWeight;
  final double? maximumWeight;
  final WeightStatus? weightStatus;
  final double? weightDifferenceFromIdeal;
  final String? classificationDisplayName;
  final String? healthRecommendation;
  final List<String> errors;
  final List<String> warnings;

  BMIAnalysisResult({
    required this.isValid,
    this.bmi,
    this.classification,
    this.bmiRangeForDiet,
    this.idealWeight,
    this.maximumWeight,
    this.weightStatus,
    this.weightDifferenceFromIdeal,
    this.classificationDisplayName,
    this.healthRecommendation,
    this.errors = const [],
    this.warnings = const [],
  });

  /// Get formatted BMI string
  String get formattedBMI {
    if (bmi == null) return 'N/A';
    return bmi!.toStringAsFixed(1);
  }

  /// Get formatted ideal weight string
  String get formattedIdealWeight {
    if (idealWeight == null) return 'N/A';
    return '${idealWeight!.toStringAsFixed(1)} kg';
  }

  /// Get formatted maximum weight string
  String get formattedMaximumWeight {
    if (maximumWeight == null) return 'N/A';
    return '${maximumWeight!.toStringAsFixed(1)} kg';
  }

  /// Get formatted weight difference string
  String get formattedWeightDifference {
    if (weightDifferenceFromIdeal == null) return 'N/A';
    final diff = weightDifferenceFromIdeal!;
    if (diff > 0) {
      return '+${diff.toStringAsFixed(1)} kg (ideal üzeri)';
    } else if (diff < 0) {
      return '${diff.toStringAsFixed(1)} kg (ideal altı)';
    } else {
      return 'İdeal kiloda';
    }
  }
}