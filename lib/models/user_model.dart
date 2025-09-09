import 'user_role_model.dart';

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

  // Kullanıcı rolü
  UserRoleType userRole = UserRoleType.user;

  bool isOnline = false;
  DateTime? lastSeen;

  // Privacy ayarları
  PrivacyType lastSeenPrivacy = PrivacyType.everyone;

  PrivacyType profilePhotoPrivacy = PrivacyType.everyone;

  PrivacyType aboutPrivacy = PrivacyType.everyone;

  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();

  UserModel();

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
    this.userRole = UserRoleType.user,
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
      'userRole': userRole.name,
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
      userRole: UserRoleType.values.firstWhere(
        (e) => e.name == map['userRole'],
        orElse: () => UserRoleType.user,
      ),
      isOnline: map['isOnline'] ?? false,
      lastSeen: map['lastSeen'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastSeen'])
          : null,
      lastSeenPrivacy: PrivacyType.values.byName(
        map['lastSeenPrivacy'] ?? 'everyone',
      ),
      profilePhotoPrivacy: PrivacyType.values.byName(
        map['profilePhotoPrivacy'] ?? 'everyone',
      ),
      aboutPrivacy: PrivacyType.values.byName(
        map['aboutPrivacy'] ?? 'everyone',
      ),
    );
  }

  // BMI hesaplama
  double? get currentBMI {
    if (currentHeight == null || currentWeight == null || currentHeight! <= 0) {
      return null;
    }
    double heightInMeters = currentHeight! / 100;
    return currentWeight! / (heightInMeters * heightInMeters);
  }

  // Diyetisyen mi kontrolü
  bool get isDietitian => userRole == UserRoleType.dietitian || userRole == UserRoleType.admin;

  // Admin mi kontrolü
  bool get isAdmin => userRole == UserRoleType.admin;
}

enum PrivacyType { everyone, contacts, nobody }
