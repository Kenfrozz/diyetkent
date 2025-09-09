enum UserRoleType {
  user,      // Normal kullanıcı
  dietitian, // Diyetisyen
  admin,     // Sistem yöneticisi
}

class UserRoleModel {
  late String userId;

  UserRoleType role = UserRoleType.user;

  // Diyetisyen özel bilgileri
  String? licenseNumber; // diploma/lisans numarası
  String? specialization; // uzmanlık alanı
  String? clinicName; // klinik/hastane adı
  String? clinicAddress; // klinik adresi
  int? experienceYears; // deneyim yılı
  
  // Yetkiler
  bool canSendBulkMessages = false;
  bool canViewAllUsers = false;
  bool canCreateDietFiles = false;
  bool canViewUserHealth = false;
  
  // İstatistikler
  int totalPatientsCount = 0;
  int activePatientsCount = 0;
  int dietFilesCreatedCount = 0;
  
  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();

  UserRoleModel();

  UserRoleModel.create({
    required this.userId,
    this.role = UserRoleType.user,
    this.licenseNumber,
    this.specialization,
    this.clinicName,
    this.clinicAddress,
    this.experienceYears,
    this.canSendBulkMessages = false,
    this.canViewAllUsers = false,
    this.canCreateDietFiles = false,
    this.canViewUserHealth = false,
    this.totalPatientsCount = 0,
    this.activePatientsCount = 0,
    this.dietFilesCreatedCount = 0,
  }) {
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
    
    // Diyetisyen rolü için otomatik yetki ataması
    if (role == UserRoleType.dietitian) {
      canSendBulkMessages = true;
      canViewAllUsers = true;
      canCreateDietFiles = true;
      canViewUserHealth = true;
    }
    
    // Admin rolü için tüm yetkiler
    if (role == UserRoleType.admin) {
      canSendBulkMessages = true;
      canViewAllUsers = true;
      canCreateDietFiles = true;
      canViewUserHealth = true;
    }
  }

  // Firebase'e çevirmek için Map
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'role': role.name,
      'licenseNumber': licenseNumber,
      'specialization': specialization,
      'clinicName': clinicName,
      'clinicAddress': clinicAddress,
      'experienceYears': experienceYears,
      'canSendBulkMessages': canSendBulkMessages,
      'canViewAllUsers': canViewAllUsers,
      'canCreateDietFiles': canCreateDietFiles,
      'canViewUserHealth': canViewUserHealth,
      'totalPatientsCount': totalPatientsCount,
      'activePatientsCount': activePatientsCount,
      'dietFilesCreatedCount': dietFilesCreatedCount,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  // Firebase'den çevirmek için factory
  factory UserRoleModel.fromMap(Map<String, dynamic> map) {
    return UserRoleModel.create(
      userId: map['userId'] ?? '',
      role: UserRoleType.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRoleType.user,
      ),
      licenseNumber: map['licenseNumber'],
      specialization: map['specialization'],
      clinicName: map['clinicName'],
      clinicAddress: map['clinicAddress'],
      experienceYears: map['experienceYears']?.toInt(),
      canSendBulkMessages: map['canSendBulkMessages'] ?? false,
      canViewAllUsers: map['canViewAllUsers'] ?? false,
      canCreateDietFiles: map['canCreateDietFiles'] ?? false,
      canViewUserHealth: map['canViewUserHealth'] ?? false,
      totalPatientsCount: map['totalPatientsCount'] ?? 0,
      activePatientsCount: map['activePatientsCount'] ?? 0,
      dietFilesCreatedCount: map['dietFilesCreatedCount'] ?? 0,
    );
  }

  // Rol görüntü adı
  String get roleDisplayName {
    switch (role) {
      case UserRoleType.user:
        return 'Kullanıcı';
      case UserRoleType.dietitian:
        return 'Diyetisyen';
      case UserRoleType.admin:
        return 'Yönetici';
    }
  }

  // Rol ikonu
  String get roleIcon {
    switch (role) {
      case UserRoleType.user:
        return '👤';
      case UserRoleType.dietitian:
        return '👩‍⚕️';
      case UserRoleType.admin:
        return '👑';
    }
  }

  // Diyetisyen mi kontrolü
  bool get isDietitian => role == UserRoleType.dietitian || role == UserRoleType.admin;

  // Admin mi kontrolü
  bool get isAdmin => role == UserRoleType.admin;

  // Normal kullanıcı mı kontrolü
  bool get isRegularUser => role == UserRoleType.user;
}
