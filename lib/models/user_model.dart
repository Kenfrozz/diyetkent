enum PrivacyType { everyone, contacts, nobody }

class UserModel {
  late String userId;
  String? name;
  String? phoneNumber;
  String? profileImageUrl;
  String? profileImageLocalPath;
  String? about;

  // Sağlık bilgileri (temel)
  double? currentHeight; // cm
  double? currentWeight; // kg
  int? age;
  DateTime? birthDate;

  // Günlük aktivite
  int? todayStepCount = 0;
  DateTime? lastStepUpdate;

  bool isOnline = false;
  DateTime? lastSeen;

  // Privacy ayarları
  PrivacyType lastSeenPrivacy = PrivacyType.everyone;
  PrivacyType profilePhotoPrivacy = PrivacyType.everyone;
  PrivacyType aboutPrivacy = PrivacyType.everyone;

  late DateTime createdAt;
  late DateTime updatedAt;

  UserModel.create({
    required this.userId,
    this.name,
    this.phoneNumber,
    this.profileImageUrl,
    this.profileImageLocalPath,
    this.about,
    this.currentHeight,
    this.currentWeight,
    this.age,
    this.birthDate,
    this.todayStepCount = 0,
    this.lastStepUpdate,
    this.isOnline = false,
    this.lastSeen,
    this.lastSeenPrivacy = PrivacyType.everyone,
    this.profilePhotoPrivacy = PrivacyType.everyone,
    this.aboutPrivacy = PrivacyType.everyone,
  }) {
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'profileImageLocalPath': profileImageLocalPath,
      'about': about,
      'currentHeight': currentHeight,
      'currentWeight': currentWeight,
      'age': age,
      'birthDate': birthDate?.millisecondsSinceEpoch,
      'todayStepCount': todayStepCount,
      'lastStepUpdate': lastStepUpdate?.millisecondsSinceEpoch,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.millisecondsSinceEpoch,
      'lastSeenPrivacy': lastSeenPrivacy.name,
      'profilePhotoPrivacy': profilePhotoPrivacy.name,
      'aboutPrivacy': aboutPrivacy.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel.create(
      userId: map['userId'] ?? '',
      name: map['name'],
      phoneNumber: map['phoneNumber'],
      profileImageUrl: map['profileImageUrl'],
      profileImageLocalPath: map['profileImageLocalPath'],
      about: map['about'],
      currentHeight: map['currentHeight']?.toDouble(),
      currentWeight: map['currentWeight']?.toDouble(),
      age: map['age']?.toInt(),
      birthDate: map['birthDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['birthDate'])
          : null,
      todayStepCount: map['todayStepCount']?.toInt() ?? 0,
      lastStepUpdate: map['lastStepUpdate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastStepUpdate'])
          : null,
      isOnline: map['isOnline'] ?? false,
      lastSeen: map['lastSeen'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastSeen'])
          : null,
      lastSeenPrivacy: PrivacyType.values.firstWhere(
        (e) => e.name == map['lastSeenPrivacy'],
        orElse: () => PrivacyType.everyone,
      ),
      profilePhotoPrivacy: PrivacyType.values.firstWhere(
        (e) => e.name == map['profilePhotoPrivacy'],
        orElse: () => PrivacyType.everyone,
      ),
      aboutPrivacy: PrivacyType.values.firstWhere(
        (e) => e.name == map['aboutPrivacy'],
        orElse: () => PrivacyType.everyone,
      ),
    )
      ..createdAt = map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now()
      ..updatedAt = map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : DateTime.now();
  }

  // BMI hesaplama
  double? get bmi {
    if (currentHeight == null || currentWeight == null || currentHeight! <= 0) {
      return null;
    }
    final heightInMeters = currentHeight! / 100;
    return currentWeight! / (heightInMeters * heightInMeters);
  }

  // BMI kategorisi
  String get bmiCategory {
    final currentBmi = bmi;
    if (currentBmi == null) return 'Bilinmiyor';
    if (currentBmi < 18.5) return 'Zayıf';
    if (currentBmi < 25) return 'Normal';
    if (currentBmi < 30) return 'Fazla kilolu';
    return 'Obez';
  }

  // İdeal kilo hesaplama (BMI 22.5 baz alınarak)
  double? get idealWeight {
    if (currentHeight == null || currentHeight! <= 0) return null;
    final heightInMeters = currentHeight! / 100;
    return 22.5 * (heightInMeters * heightInMeters);
  }

  // Kilo farkı
  double? get weightDifference {
    if (currentWeight == null || idealWeight == null) return null;
    return currentWeight! - idealWeight!;
  }

  // Model kopyalama
  UserModel copyWith({
    String? userId,
    String? name,
    String? phoneNumber,
    String? profileImageUrl,
    String? profileImageLocalPath,
    String? about,
    double? currentHeight,
    double? currentWeight,
    int? age,
    DateTime? birthDate,
    int? todayStepCount,
    DateTime? lastStepUpdate,
    bool? isOnline,
    DateTime? lastSeen,
    PrivacyType? lastSeenPrivacy,
    PrivacyType? profilePhotoPrivacy,
    PrivacyType? aboutPrivacy,
  }) {
    return UserModel.create(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      profileImageLocalPath: profileImageLocalPath ?? this.profileImageLocalPath,
      about: about ?? this.about,
      currentHeight: currentHeight ?? this.currentHeight,
      currentWeight: currentWeight ?? this.currentWeight,
      age: age ?? this.age,
      birthDate: birthDate ?? this.birthDate,
      todayStepCount: todayStepCount ?? this.todayStepCount,
      lastStepUpdate: lastStepUpdate ?? this.lastStepUpdate,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      lastSeenPrivacy: lastSeenPrivacy ?? this.lastSeenPrivacy,
      profilePhotoPrivacy: profilePhotoPrivacy ?? this.profilePhotoPrivacy,
      aboutPrivacy: aboutPrivacy ?? this.aboutPrivacy,
    )
      ..createdAt = createdAt
      ..updatedAt = DateTime.now();
  }
}