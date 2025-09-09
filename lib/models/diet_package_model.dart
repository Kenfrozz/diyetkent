enum DietPackageType {
  weightLoss,     // kilo verme
  weightGain,     // kilo alma
  maintenance,    // koruma
  diabetic,       // diyabet
  sports,         // spor
  custom,         // özel
}

enum MealType {
  breakfast,      // kahvaltı
  lunch,          // öğle yemeği
  dinner,         // akşam yemeği
  snack1,         // ara öğün 1
  snack2,         // ara öğün 2
  snack3,         // ara öğün 3
}

class DietPackageModel {
  late String packageId;
  late String dietitianId; // oluşturan diyetisyen

  // Temel bilgiler
  String title = '';
  String description = '';
  String? imageUrl;
  
  DietPackageType type = DietPackageType.custom;
  
  int durationDays = 30; // varsayılan 30 gün
  double price = 0.0;
  
  // Paket hesaplama parametreleri
  int numberOfFiles = 4;           // paket kaç diyet dosyasına sahip
  int daysPerFile = 7;             // her dosya kaç gün sürecek
  double targetWeightChangePerFile = -2.0; // her dosyada hedef kilo değişimi
  
  // Genel beslenme hedefleri (JSON string olarak saklanacak)
  String nutritionTargets = '{}'; // {"calories": 1500, "protein": 100, "carbs": 150, "fat": 50}
  
  // Genel öğün planları şablonu (JSON array string olarak)
  String mealPlans = '[]'; // [{"type": "breakfast", "foods": ["yumurta", "ekmek"], "calories": 300}]
  
  // İzin verilen/yasaklı yiyecekler
  List<String> allowedFoods = [];
  List<String> forbiddenFoods = [];
  
  // Ek bilgiler
  String? exercisePlan; // egzersiz önerileri
  String? specialNotes; // özel notlar
  List<String> tags = []; // etiketler
  
  // Durum bilgileri
  bool isActive = true;
  bool isPublic = false; // diğer diyetisyenlerin görebilmesi
  
  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
  
  // İstatistikler
  int assignedCount = 0; // kaç kullanıcıya atanmış
  double averageRating = 0.0; // ortalama puan
  int reviewCount = 0; // değerlendirme sayısı

  DietPackageModel();

  DietPackageModel.create({
    required this.packageId,
    required this.dietitianId,
    required this.title,
    required this.description,
    this.imageUrl,
    this.type = DietPackageType.custom,
    this.durationDays = 30,
    this.price = 0.0,
    this.numberOfFiles = 4,
    this.daysPerFile = 7,
    this.targetWeightChangePerFile = -2.0,
    this.nutritionTargets = '{}',
    this.mealPlans = '[]',
    this.allowedFoods = const [],
    this.forbiddenFoods = const [],
    this.exercisePlan,
    this.specialNotes,
    this.tags = const [],
    this.isActive = true,
    this.isPublic = false,
  }) {
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
  }

  // Firestore için Map dönüşümü
  Map<String, dynamic> toMap() {
    return {
      'packageId': packageId,
      'dietitianId': dietitianId,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'type': type.name,
      'durationDays': durationDays,
      'price': price,
      'numberOfFiles': numberOfFiles,
      'daysPerFile': daysPerFile,
      'targetWeightChangePerFile': targetWeightChangePerFile,
      'nutritionTargets': nutritionTargets,
      'mealPlans': mealPlans,
      'allowedFoods': allowedFoods,
      'forbiddenFoods': forbiddenFoods,
      'exercisePlan': exercisePlan,
      'specialNotes': specialNotes,
      'tags': tags,
      'isActive': isActive,
      'isPublic': isPublic,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'assignedCount': assignedCount,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
    };
  }

  // Firestore'dan Map dönüşümü
  factory DietPackageModel.fromMap(Map<String, dynamic> map) {
    return DietPackageModel.create(
      packageId: map['packageId'] ?? '',
      dietitianId: map['dietitianId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'],
      type: DietPackageType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => DietPackageType.custom,
      ),
      durationDays: map['durationDays'] ?? 30,
      price: (map['price'] ?? 0.0).toDouble(),
      numberOfFiles: map['numberOfFiles'] ?? 4,
      daysPerFile: map['daysPerFile'] ?? 7,
      targetWeightChangePerFile: (map['targetWeightChangePerFile'] ?? -2.0).toDouble(),
      nutritionTargets: map['nutritionTargets'] ?? '{}',
      mealPlans: map['mealPlans'] ?? '[]',
      allowedFoods: List<String>.from(map['allowedFoods'] ?? []),
      forbiddenFoods: List<String>.from(map['forbiddenFoods'] ?? []),
      exercisePlan: map['exercisePlan'],
      specialNotes: map['specialNotes'],
      tags: List<String>.from(map['tags'] ?? []),
      isActive: map['isActive'] ?? true,
      isPublic: map['isPublic'] ?? false,
    )
      ..assignedCount = map['assignedCount'] ?? 0
      ..averageRating = (map['averageRating'] ?? 0.0).toDouble()
      ..reviewCount = map['reviewCount'] ?? 0
      ..createdAt = DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      )
      ..updatedAt = DateTime.fromMillisecondsSinceEpoch(
        map['updatedAt'] ?? DateTime.now().millisecondsSinceEpoch,
      );
  }

  // Görüntüleme için tür adı
  String get typeDisplayName {
    switch (type) {
      case DietPackageType.weightLoss:
        return 'Kilo Verme';
      case DietPackageType.weightGain:
        return 'Kilo Alma';
      case DietPackageType.maintenance:
        return 'Koruma';
      case DietPackageType.diabetic:
        return 'Diyabet';
      case DietPackageType.sports:
        return 'Spor';
      case DietPackageType.custom:
        return 'Özel';
    }
  }

  // Paketin aktif olup olmadığını kontrol et
  bool get isAvailable => isActive;

  // Backwards compatibility için name getter (title ile aynı)
  String get name => title;

  // Fiyat formatı
  String get formattedPrice {
    if (price == 0) return 'Ücretsiz';
    return '${price.toStringAsFixed(0)} ₺';
  }

  // Süre formatı  
  String get formattedDuration {
    if (durationDays < 7) {
      return '$durationDays gün';
    } else if (durationDays < 30) {
      final weeks = (durationDays / 7).round();
      return '$weeks hafta';
    } else {
      final months = (durationDays / 30).round();
      return '$months ay';
    }
  }

  // Toplam hedef kilo değişimi hesaplama
  double get totalTargetWeightChange {
    return numberOfFiles * targetWeightChangePerFile;
  }

  // Toplam süre hesaplama (otomatik)
  int get calculatedTotalDuration {
    return numberOfFiles * daysPerFile;
  }

  // Paket özet bilgisi
  String get packageSummary {
    String summary = '$numberOfFiles dosya • $calculatedTotalDuration gün';
    
    if (totalTargetWeightChange != 0.0) {
      final changeText = totalTargetWeightChange > 0 
        ? '+${totalTargetWeightChange.toStringAsFixed(1)} kg' 
        : '${totalTargetWeightChange.toStringAsFixed(1)} kg';
      summary += ' • $changeText hedef';
    }
    
    return summary;
  }

  // Her dosyada hedef kilo değişimi metni
  String get weightChangePerFileText {
    if (targetWeightChangePerFile == 0.0) return 'Koruma';
    if (targetWeightChangePerFile > 0) return '+${targetWeightChangePerFile.toStringAsFixed(1)} kg/dosya';
    return '${targetWeightChangePerFile.toStringAsFixed(1)} kg/dosya';
  }

  // Dosya başına süre metni
  String get daysPerFileText {
    if (daysPerFile == 7) return '1 hafta/dosya';
    return '$daysPerFile gün/dosya';
  }

  // Paket parametreleri özeti
  String get parametersDetails {
    final parts = <String>[];
    parts.add('$numberOfFiles dosya');
    parts.add(daysPerFileText);
    parts.add(weightChangePerFileText);
    return parts.join(' • ');
  }
}