import '../models/pre_consultation_form_model.dart';

// Risk calculation result
class RiskCalculationResult {
  final double score;
  final String level; // 'low', 'medium', 'high'
  final List<RiskFactor> factors;
  final Map<String, double> categoryScores;
  
  const RiskCalculationResult({
    required this.score,
    required this.level,
    required this.factors,
    required this.categoryScores,
  });
  
  /// Get the severity based on the level
  String get severity => level;
  
  /// Get risk severity enum
  RiskSeverity get riskSeverity {
    switch (level.toLowerCase()) {
      case 'düşük':
      case 'low':
        return RiskSeverity.low;
      case 'orta':
      case 'medium':
        return RiskSeverity.medium;
      case 'yüksek':
      case 'high':
        return RiskSeverity.high;
      case 'kritik':
      case 'critical':
        return RiskSeverity.critical;
      default:
        return RiskSeverity.low;
    }
  }
}

// Individual risk factor
class RiskFactor {
  final String category;
  final String description;
  final double score;
  final RiskSeverity severity;
  
  const RiskFactor({
    required this.category,
    required this.description,
    required this.score,
    required this.severity,
  });
}

enum RiskSeverity {
  low,
  medium,
  high,
  critical,
}

// Advanced risk calculator
class RiskCalculator {
  // Ana risk skorlama fonksiyonu
  static RiskCalculationResult calculateRisk(PreConsultationFormModel form) {
    final List<RiskFactor> factors = [];
    final Map<String, double> categoryScores = {};
    
    // 1. Demografik risk faktörleri
    final demographicScore = _calculateDemographicRisk(form.personalInfo, factors);
    categoryScores['demographic'] = demographicScore;
    
    // 2. BMI risk faktörleri
    final bmiScore = _calculateBMIRisk(form.personalInfo, factors);
    categoryScores['bmi'] = bmiScore;
    
    // 3. Tıbbi geçmiş risk faktörleri
    final medicalScore = _calculateMedicalHistoryRisk(form.medicalHistory, factors);
    categoryScores['medical'] = medicalScore;
    
    // 4. Beslenme alışkanlıkları risk faktörleri
    final nutritionScore = _calculateNutritionRisk(form.nutritionHabits, factors);
    categoryScores['nutrition'] = nutritionScore;
    
    // 5. Fiziksel aktivite risk faktörleri
    final activityScore = _calculatePhysicalActivityRisk(form.physicalActivity, factors);
    categoryScores['activity'] = activityScore;
    
    // 6. Hedef ve motivasyon risk faktörleri
    final goalScore = _calculateGoalRisk(form.goals, factors);
    categoryScores['goals'] = goalScore;
    
    // Toplam skor hesaplama (ağırlıklı ortalama)
    final totalScore = (demographicScore * 0.15) +
                      (bmiScore * 0.25) +
                      (medicalScore * 0.30) +
                      (nutritionScore * 0.15) +
                      (activityScore * 0.10) +
                      (goalScore * 0.05);
    
    // Risk seviyesi belirleme
    final riskLevel = _determineRiskLevel(totalScore);
    
    return RiskCalculationResult(
      score: totalScore,
      level: riskLevel,
      factors: factors,
      categoryScores: categoryScores,
    );
  }

  // Demografik risk hesaplama
  static double _calculateDemographicRisk(PersonalInfo personalInfo, List<RiskFactor> factors) {
    double score = 0.0;
    
    // Yaş riski
    if (personalInfo.age >= 65) {
      score += 8.0;
      factors.add(RiskFactor(
        category: 'Demografik',
        description: 'İleri yaş (${personalInfo.age})',
        score: 8.0,
        severity: RiskSeverity.medium,
      ));
    } else if (personalInfo.age >= 50) {
      score += 4.0;
      factors.add(RiskFactor(
        category: 'Demografik',
        description: 'Orta yaş (${personalInfo.age})',
        score: 4.0,
        severity: RiskSeverity.low,
      ));
    } else if (personalInfo.age < 25) {
      score += 2.0;
      factors.add(RiskFactor(
        category: 'Demografik',
        description: 'Genç yaş (${personalInfo.age})',
        score: 2.0,
        severity: RiskSeverity.low,
      ));
    }
    
    // Cinsiyet riski (kadınlarda bazı durumlar için farklı risk profili)
    if (personalInfo.gender == Gender.female && personalInfo.age >= 45) {
      score += 2.0;
      factors.add(const RiskFactor(
        category: 'Demografik',
        description: 'Menopoz yaş aralığında kadın',
        score: 2.0,
        severity: RiskSeverity.low,
      ));
    }
    
    return score;
  }

  // BMI risk hesaplama
  static double _calculateBMIRisk(PersonalInfo personalInfo, List<RiskFactor> factors) {
    double score = 0.0;
    
    final bmi = personalInfo.bmi;
    if (bmi == null) {
      score += 5.0;
      factors.add(const RiskFactor(
        category: 'BMI',
        description: 'BMI hesaplanamadı (eksik veri)',
        score: 5.0,
        severity: RiskSeverity.medium,
      ));
      return score;
    }
    
    if (bmi < 16.0) {
      score += 15.0;
      factors.add(RiskFactor(
        category: 'BMI',
        description: 'Ciddi zayıflık (BMI: ${bmi.toStringAsFixed(1)})',
        score: 15.0,
        severity: RiskSeverity.critical,
      ));
    } else if (bmi < 18.5) {
      score += 8.0;
      factors.add(RiskFactor(
        category: 'BMI',
        description: 'Zayıflık (BMI: ${bmi.toStringAsFixed(1)})',
        score: 8.0,
        severity: RiskSeverity.medium,
      ));
    } else if (bmi >= 35.0) {
      score += 20.0;
      factors.add(RiskFactor(
        category: 'BMI',
        description: 'Morbid obezite (BMI: ${bmi.toStringAsFixed(1)})',
        score: 20.0,
        severity: RiskSeverity.critical,
      ));
    } else if (bmi >= 30.0) {
      score += 12.0;
      factors.add(RiskFactor(
        category: 'BMI',
        description: 'Obezite (BMI: ${bmi.toStringAsFixed(1)})',
        score: 12.0,
        severity: RiskSeverity.high,
      ));
    } else if (bmi >= 25.0) {
      score += 5.0;
      factors.add(RiskFactor(
        category: 'BMI',
        description: 'Fazla kilolu (BMI: ${bmi.toStringAsFixed(1)})',
        score: 5.0,
        severity: RiskSeverity.low,
      ));
    }
    
    // Hedef kilo ile mevcut kilo arasındaki fark
    if (personalInfo.targetWeight != null && personalInfo.currentWeight != null) {
      final weightDifference = (personalInfo.currentWeight! - personalInfo.targetWeight!).abs();
      
      if (weightDifference > 30) {
        score += 8.0;
        factors.add(RiskFactor(
          category: 'BMI',
          description: 'Aşırı hedef kilo değişimi (${weightDifference.toStringAsFixed(1)} kg)',
          score: 8.0,
          severity: RiskSeverity.medium,
        ));
      } else if (weightDifference > 20) {
        score += 4.0;
        factors.add(RiskFactor(
          category: 'BMI',
          description: 'Yüksek hedef kilo değişimi (${weightDifference.toStringAsFixed(1)} kg)',
          score: 4.0,
          severity: RiskSeverity.low,
        ));
      }
    }
    
    return score;
  }

  // Tıbbi geçmiş risk hesaplama
  static double _calculateMedicalHistoryRisk(MedicalHistory medicalHistory, List<RiskFactor> factors) {
    double score = 0.0;
    
    // Kronik hastalık varlığı
    if (medicalHistory.hasChronicConditions) {
      score += 15.0;
      factors.add(const RiskFactor(
        category: 'Tıbbi Geçmiş',
        description: 'Kronik hastalık varlığı',
        score: 15.0,
        severity: RiskSeverity.high,
      ));
      
      // Spesifik hastalık kontrolleri
      for (final condition in medicalHistory.conditions) {
        final conditionLower = condition.toLowerCase();
        
        if (conditionLower.contains('diyabet') || conditionLower.contains('diabetes')) {
          score += 8.0;
          factors.add(const RiskFactor(
            category: 'Tıbbi Geçmiş',
            description: 'Diabetes mellitus',
            score: 8.0,
            severity: RiskSeverity.high,
          ));
        }
        
        if (conditionLower.contains('hipertansiyon') || conditionLower.contains('tansiyon')) {
          score += 6.0;
          factors.add(const RiskFactor(
            category: 'Tıbbi Geçmiş',
            description: 'Hipertansiyon',
            score: 6.0,
            severity: RiskSeverity.medium,
          ));
        }
        
        if (conditionLower.contains('kalp') || conditionLower.contains('kardiyak')) {
          score += 10.0;
          factors.add(const RiskFactor(
            category: 'Tıbbi Geçmiş',
            description: 'Kardiyovasküler hastalık',
            score: 10.0,
            severity: RiskSeverity.critical,
          ));
        }
        
        if (conditionLower.contains('tiroid')) {
          score += 4.0;
          factors.add(const RiskFactor(
            category: 'Tıbbi Geçmiş',
            description: 'Tiroid bozukluğu',
            score: 4.0,
            severity: RiskSeverity.low,
          ));
        }
        
        if (conditionLower.contains('böbrek')) {
          score += 8.0;
          factors.add(const RiskFactor(
            category: 'Tıbbi Geçmiş',
            description: 'Böbrek hastalığı',
            score: 8.0,
            severity: RiskSeverity.high,
          ));
        }
        
        if (conditionLower.contains('karaciğer')) {
          score += 8.0;
          factors.add(const RiskFactor(
            category: 'Tıbbi Geçmiş',
            description: 'Karaciğer hastalığı',
            score: 8.0,
            severity: RiskSeverity.high,
          ));
        }
      }
    }
    
    // Düzenli ilaç kullanımı
    if (medicalHistory.isTakingMedications) {
      score += 5.0;
      factors.add(const RiskFactor(
        category: 'Tıbbi Geçmiş',
        description: 'Düzenli ilaç kullanımı',
        score: 5.0,
        severity: RiskSeverity.low,
      ));
      
      // İlaç sayısı kontrolü
      if (medicalHistory.medications.length >= 5) {
        score += 5.0;
        factors.add(RiskFactor(
          category: 'Tıbbi Geçmiş',
          description: 'Çoklu ilaç kullanımı (${medicalHistory.medications.length} ilaç)',
          score: 5.0,
          severity: RiskSeverity.medium,
        ));
      }
    }
    
    // Alerji varlığı
    if (medicalHistory.hasAllergies) {
      score += 3.0;
      factors.add(const RiskFactor(
        category: 'Tıbbi Geçmiş',
        description: 'Alerji varlığı',
        score: 3.0,
        severity: RiskSeverity.low,
      ));
      
      // Ciddi alerji kontrolleri
      for (final allergy in medicalHistory.allergies) {
        final allergyLower = allergy.toLowerCase();
        
        if (allergyLower.contains('ana') || allergyLower.contains('shock') || allergyLower.contains('anafilaksi')) {
          score += 8.0;
          factors.add(const RiskFactor(
            category: 'Tıbbi Geçmiş',
            description: 'Anafilaktik reaksiyon geçmişi',
            score: 8.0,
            severity: RiskSeverity.critical,
          ));
        }
      }
    }
    
    // Önceki diyet geçmişi
    if (medicalHistory.previousDietHistory?.toLowerCase().contains('başarısız') == true) {
      score += 3.0;
      factors.add(const RiskFactor(
        category: 'Tıbbi Geçmiş',
        description: 'Geçmişte başarısız diyet denemeleri',
        score: 3.0,
        severity: RiskSeverity.low,
      ));
    }
    
    return score;
  }

  // Beslenme alışkanlıkları risk hesaplama
  static double _calculateNutritionRisk(NutritionHabits nutritionHabits, List<RiskFactor> factors) {
    double score = 0.0;
    
    // Yetersiz su tüketimi
    if (nutritionHabits.waterIntakePerDay < 1.5) {
      score += 4.0;
      factors.add(RiskFactor(
        category: 'Beslenme',
        description: 'Yetersiz su tüketimi (${nutritionHabits.waterIntakePerDay.toStringAsFixed(1)} L/gün)',
        score: 4.0,
        severity: RiskSeverity.low,
      ));
    } else if (nutritionHabits.waterIntakePerDay < 2.0) {
      score += 2.0;
      factors.add(RiskFactor(
        category: 'Beslenme',
        description: 'Düşük su tüketimi (${nutritionHabits.waterIntakePerDay.toStringAsFixed(1)} L/gün)',
        score: 2.0,
        severity: RiskSeverity.low,
      ));
    }
    
    // Kahvaltı atlama
    if (nutritionHabits.skipBreakfast) {
      score += 3.0;
      factors.add(const RiskFactor(
        category: 'Beslenme',
        description: 'Kahvaltı atlama alışkanlığı',
        score: 3.0,
        severity: RiskSeverity.low,
      ));
    }
    
    // Geç gece yeme
    if (nutritionHabits.lateNightEating) {
      score += 4.0;
      factors.add(const RiskFactor(
        category: 'Beslenme',
        description: 'Gece geç saatlerde yeme alışkanlığı',
        score: 4.0,
        severity: RiskSeverity.low,
      ));
    }
    
    // Duygusal yeme
    if (nutritionHabits.emotionalEating) {
      score += 6.0;
      factors.add(const RiskFactor(
        category: 'Beslenme',
        description: 'Duygusal yeme bozukluğu',
        score: 6.0,
        severity: RiskSeverity.medium,
      ));
    }
    
    // Aşırı öğün sayısı
    if (nutritionHabits.mealsPerDay > 5) {
      score += 3.0;
      factors.add(RiskFactor(
        category: 'Beslenme',
        description: 'Aşırı öğün sayısı (${nutritionHabits.mealsPerDay} öğün/gün)',
        score: 3.0,
        severity: RiskSeverity.low,
      ));
    }
    
    // Aşırı ara öğün
    if (nutritionHabits.snacksPerDay > 3) {
      score += 2.0;
      factors.add(RiskFactor(
        category: 'Beslenme',
        description: 'Aşırı ara öğün (${nutritionHabits.snacksPerDay} ara öğün/gün)',
        score: 2.0,
        severity: RiskSeverity.low,
      ));
    }
    
    // Sık dışarıda yeme
    if (nutritionHabits.eatOutFrequencyPerWeek > 7) {
      score += 5.0;
      factors.add(RiskFactor(
        category: 'Beslenme',
        description: 'Çok sık dışarıda yeme (${nutritionHabits.eatOutFrequencyPerWeek} kez/hafta)',
        score: 5.0,
        severity: RiskSeverity.medium,
      ));
    } else if (nutritionHabits.eatOutFrequencyPerWeek > 4) {
      score += 2.0;
      factors.add(RiskFactor(
        category: 'Beslenme',
        description: 'Sık dışarıda yeme (${nutritionHabits.eatOutFrequencyPerWeek} kez/hafta)',
        score: 2.0,
        severity: RiskSeverity.low,
      ));
    }
    
    // Ev yemeği yapmama
    if (!nutritionHabits.cookAtHome) {
      score += 4.0;
      factors.add(const RiskFactor(
        category: 'Beslenme',
        description: 'Ev yemeği yapmama alışkanlığı',
        score: 4.0,
        severity: RiskSeverity.low,
      ));
    }
    
    return score;
  }

  // Fiziksel aktivite risk hesaplama
  static double _calculatePhysicalActivityRisk(PhysicalActivity physicalActivity, List<RiskFactor> factors) {
    double score = 0.0;
    
    // Aktivite seviyesi
    switch (physicalActivity.activityLevel) {
      case ActivityLevel.sedentary:
        score += 8.0;
        factors.add(const RiskFactor(
          category: 'Fiziksel Aktivite',
          description: 'Hareketsiz yaşam tarzı',
          score: 8.0,
          severity: RiskSeverity.medium,
        ));
        break;
      case ActivityLevel.lightly:
        score += 4.0;
        factors.add(const RiskFactor(
          category: 'Fiziksel Aktivite',
          description: 'Düşük aktivite seviyesi',
          score: 4.0,
          severity: RiskSeverity.low,
        ));
        break;
      case ActivityLevel.moderately:
        // Normal aktivite seviyesi, risk yok
        break;
      case ActivityLevel.very:
      case ActivityLevel.extremely:
        // Yüksek aktivite seviyesi olumlu
        break;
    }
    
    // Egzersiz sıklığı
    if (physicalActivity.exerciseFrequencyPerWeek == 0) {
      score += 6.0;
      factors.add(const RiskFactor(
        category: 'Fiziksel Aktivite',
        description: 'Düzenli egzersiz yapmıyor',
        score: 6.0,
        severity: RiskSeverity.medium,
      ));
    } else if (physicalActivity.exerciseFrequencyPerWeek < 2) {
      score += 3.0;
      factors.add(const RiskFactor(
        category: 'Fiziksel Aktivite',
        description: 'Yetersiz egzersiz sıklığı (haftada 1 kez)',
        score: 3.0,
        severity: RiskSeverity.low,
      ));
    }
    
    // Fiziksel sınırlılıklar
    if (physicalActivity.hasPhysicalLimitations) {
      score += 5.0;
      factors.add(const RiskFactor(
        category: 'Fiziksel Aktivite',
        description: 'Fiziksel sınırlılıklar mevcut',
        score: 5.0,
        severity: RiskSeverity.medium,
      ));
      
      // Sınırlılık sayısı
      if (physicalActivity.physicalLimitations.length >= 3) {
        score += 3.0;
        factors.add(RiskFactor(
          category: 'Fiziksel Aktivite',
          description: 'Çoklu fiziksel sınırlılık (${physicalActivity.physicalLimitations.length})',
          score: 3.0,
          severity: RiskSeverity.medium,
        ));
      }
    }
    
    // Günlük adım sayısı
    if (physicalActivity.dailySteps < 5000) {
      score += 4.0;
      factors.add(RiskFactor(
        category: 'Fiziksel Aktivite',
        description: 'Düşük günlük adım sayısı (${physicalActivity.dailySteps})',
        score: 4.0,
        severity: RiskSeverity.low,
      ));
    }
    
    // İş tipi (masa başı işler)
    if (physicalActivity.workType?.toLowerCase().contains('masa') == true || 
        physicalActivity.workType?.toLowerCase().contains('oturarak') == true) {
      score += 2.0;
      factors.add(const RiskFactor(
        category: 'Fiziksel Aktivite',
        description: 'Masa başı çalışma',
        score: 2.0,
        severity: RiskSeverity.low,
      ));
    }
    
    return score;
  }

  // Hedef ve motivasyon risk hesaplama
  static double _calculateGoalRisk(Goals goals, List<RiskFactor> factors) {
    double score = 0.0;
    
    // Düşük motivasyon
    if (goals.motivationLevel < 4) {
      score += 6.0;
      factors.add(RiskFactor(
        category: 'Hedefler',
        description: 'Düşük motivasyon seviyesi (${goals.motivationLevel}/10)',
        score: 6.0,
        severity: RiskSeverity.medium,
      ));
    } else if (goals.motivationLevel < 6) {
      score += 3.0;
      factors.add(RiskFactor(
        category: 'Hedefler',
        description: 'Orta motivasyon seviyesi (${goals.motivationLevel}/10)',
        score: 3.0,
        severity: RiskSeverity.low,
      ));
    }
    
    // Değişime isteksizlik
    if (!goals.willingToMakeChanges) {
      score += 8.0;
      factors.add(const RiskFactor(
        category: 'Hedefler',
        description: 'Değişim yapmaya isteksizlik',
        score: 8.0,
        severity: RiskSeverity.high,
      ));
    }
    
    // Gerçekçi olmayan zaman çerçevesi
    if (goals.timeframeWeeks < 4) {
      score += 4.0;
      factors.add(RiskFactor(
        category: 'Hedefler',
        description: 'Çok kısa zaman hedefi (${goals.timeframeWeeks} hafta)',
        score: 4.0,
        severity: RiskSeverity.low,
      ));
    } else if (goals.timeframeWeeks > 52) {
      score += 2.0;
      factors.add(RiskFactor(
        category: 'Hedefler',
        description: 'Çok uzun zaman hedefi (${goals.timeframeWeeks} hafta)',
        score: 2.0,
        severity: RiskSeverity.low,
      ));
    }
    
    // Aşırı kilo verme hedefi
    if (goals.targetWeightLoss != null && goals.targetWeightLoss! > 20) {
      score += 5.0;
      factors.add(RiskFactor(
        category: 'Hedefler',
        description: 'Aşırı kilo verme hedefi (${goals.targetWeightLoss!.toStringAsFixed(1)} kg)',
        score: 5.0,
        severity: RiskSeverity.medium,
      ));
    }
    
    // Çok sayıda başarısız deneme
    if (goals.previousAttempts.length >= 5) {
      score += 4.0;
      factors.add(RiskFactor(
        category: 'Hedefler',
        description: 'Çok sayıda başarısız deneme (${goals.previousAttempts.length})',
        score: 4.0,
        severity: RiskSeverity.low,
      ));
    } else if (goals.previousAttempts.length >= 3) {
      score += 2.0;
      factors.add(RiskFactor(
        category: 'Hedefler',
        description: 'Tekrarlayan başarısız denemeler (${goals.previousAttempts.length})',
        score: 2.0,
        severity: RiskSeverity.low,
      ));
    }
    
    return score;
  }

  // Risk seviyesi belirleme
  static String _determineRiskLevel(double totalScore) {
    if (totalScore <= 20.0) return 'low';
    if (totalScore <= 40.0) return 'medium';
    return 'high';
  }

  // Risk seviyesi açıklamaları
  static String getRiskLevelDescription(String riskLevel) {
    switch (riskLevel) {
      case 'low':
        return 'Düşük Risk - Genel olarak güvenli bir profil. Standart beslenme programı uygulanabilir.';
      case 'medium':
        return 'Orta Risk - Dikkat gereken faktörler mevcut. Daha yakın takip gerekebilir.';
      case 'high':
        return 'Yüksek Risk - Ciddi risk faktörleri tespit edildi. Medikal danışmanlık önerilir.';
      default:
        return 'Bilinmiyor';
    }
  }

  // Risk kategorisi renk kodları
  static String getRiskLevelColor(String riskLevel) {
    switch (riskLevel) {
      case 'low':
        return '#4CAF50'; // Yeşil
      case 'medium':
        return '#FF9800'; // Turuncu
      case 'high':
        return '#F44336'; // Kırmızı
      default:
        return '#9E9E9E'; // Gri
    }
  }

  // Öncelikli risk faktörlerini getir
  static List<RiskFactor> getPriorityRiskFactors(List<RiskFactor> factors) {
    // Critical ve high severity'li faktörleri öncelikle göster
    final priorityFactors = factors
        .where((factor) => factor.severity == RiskSeverity.critical || 
                          factor.severity == RiskSeverity.high)
        .toList();
    
    // Score'a göre sırala
    priorityFactors.sort((a, b) => b.score.compareTo(a.score));
    
    return priorityFactors.take(5).toList(); // En fazla 5 öncelikli faktör
  }

  // Öneriler oluştur
  static List<String> generateRecommendations(List<RiskFactor> factors) {
    final List<String> recommendations = [];
    
    for (final factor in factors) {
      if (factor.severity == RiskSeverity.critical || factor.severity == RiskSeverity.high) {
        switch (factor.category) {
          case 'BMI':
            if (factor.description.contains('obez')) {
              recommendations.add('Hekim kontrolünde kademeli kilo verme programı');
              recommendations.add('Kardiyovasküler risk değerlendirmesi');
            } else if (factor.description.contains('zayıf')) {
              recommendations.add('Beslenme uzmanı ile kilo alma programı');
              recommendations.add('Altta yatan sebeplerin araştırılması');
            }
            break;
          case 'Tıbbi Geçmiş':
            if (factor.description.contains('Diabetes')) {
              recommendations.add('Endokrinolog kontrolünde diyet planı');
              recommendations.add('Kan şekeri takibi ile beslenme düzenlemesi');
            } else if (factor.description.contains('Kardiyovasküler')) {
              recommendations.add('Kardiyolog onayı alınmalı');
              recommendations.add('Düşük sodyum diyeti önerilir');
            }
            break;
          case 'Beslenme':
            if (factor.description.contains('Duygusal yeme')) {
              recommendations.add('Psikolojik destek önerilir');
              recommendations.add('Davranışsal değişim tekniklerinin uygulanması');
            }
            break;
          case 'Fiziksel Aktivite':
            if (factor.description.contains('sınırlılık')) {
              recommendations.add('Fizik tedavi değerlendirmesi');
              recommendations.add('Uygun egzersiz programının belirlenmesi');
            }
            break;
        }
      }
    }
    
    // Genel öneriler
    if (recommendations.isEmpty) {
      recommendations.add('Dengeli beslenme programı uygulanabilir');
      recommendations.add('Düzenli kontroller önerilir');
    }
    
    return recommendations.take(5).toList(); // En fazla 5 öneri
  }
}