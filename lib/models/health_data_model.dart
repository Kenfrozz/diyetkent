class HealthDataModel {
  late String userId;

  // Fiziksel ölçümler
  double? height; // cm
  double? weight; // kg
  double? bmi; // BMI hesaplanmış değer
  
  // Günlük aktivite verileri
  int? stepCount; // günlük adım sayısı
  DateTime recordDate = DateTime.now();
  
  // Ek sağlık bilgileri
  double? bodyFat; // vücut yağ oranı
  double? muscleMass; // kas kütlesi
  double? waterPercentage; // su oranı
  
  // Notlar
  String? notes;
  
  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();

  HealthDataModel();

  HealthDataModel.create({
    required this.userId,
    this.height,
    this.weight,
    this.bmi,
    this.stepCount,
    DateTime? recordDate,
    this.bodyFat,
    this.muscleMass,
    this.waterPercentage,
    this.notes,
  }) {
    this.recordDate = recordDate ?? DateTime.now();
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
    
    // BMI otomatik hesaplama
    if (height != null && weight != null && height! > 0) {
      double heightInMeters = height! / 100;
      bmi = weight! / (heightInMeters * heightInMeters);
    }
  }

  // Firebase'e çevirmek için Map
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'height': height,
      'weight': weight,
      'bmi': bmi,
      'stepCount': stepCount,
      'recordDate': recordDate.millisecondsSinceEpoch,
      'bodyFat': bodyFat,
      'muscleMass': muscleMass,
      'waterPercentage': waterPercentage,
      'notes': notes,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  // Firebase'den çevirmek için factory
  factory HealthDataModel.fromMap(Map<String, dynamic> map) {
    return HealthDataModel.create(
      userId: map['userId'] ?? '',
      height: map['height']?.toDouble(),
      weight: map['weight']?.toDouble(),
      bmi: map['bmi']?.toDouble(),
      stepCount: map['stepCount']?.toInt(),
      recordDate: map['recordDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['recordDate'])
          : DateTime.now(),
      bodyFat: map['bodyFat']?.toDouble(),
      muscleMass: map['muscleMass']?.toDouble(),
      waterPercentage: map['waterPercentage']?.toDouble(),
      notes: map['notes'],
    );
  }

  // BMI kategorisi
  String get bmiCategory {
    if (bmi == null) return 'Bilinmiyor';
    if (bmi! < 18.5) return 'Zayıf';
    if (bmi! < 25) return 'Normal';
    if (bmi! < 30) return 'Fazla Kilolu';
    return 'Obez';
  }

  // BMI renk kodu
  String get bmiColorHex {
    if (bmi == null) return '#9E9E9E';
    if (bmi! < 18.5) return '#2196F3'; // Mavi - Zayıf
    if (bmi! < 25) return '#4CAF50'; // Yeşil - Normal
    if (bmi! < 30) return '#FF9800'; // Turuncu - Fazla Kilolu
    return '#F44336'; // Kırmızı - Obez
  }

  // Günün en son kaydı mı kontrolü
  bool get isLatestRecord {
    final today = DateTime.now();
    return recordDate.year == today.year &&
           recordDate.month == today.month &&
           recordDate.day == today.day;
  }
}
