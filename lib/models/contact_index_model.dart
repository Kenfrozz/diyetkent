class ContactIndexModel {
  late String normalizedPhone; // E.164 benzeri normalize edilmiş telefon

  String? contactName; // Rehberde görünen isim
  String? originalPhone; // Orijinal telefon formatı
  
  // Kullanıcı bilgileri
  bool isRegistered = false; // Uygulamayı kullanıyor mu
  String? registeredUid; // Kayıtlıysa eşleşen kullanıcı UID'si
  String? displayName; // Kayıtlı kullanıcının adı
  String? profileImageUrl; // Profil fotoğrafı
  bool isOnline = false; // Online durumu
  DateTime? lastSeen; // Son görülme
  
  // Meta bilgiler
  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
  DateTime? lastSyncAt; // Son Firebase senkronizasyonu

  ContactIndexModel();

  ContactIndexModel.create({
    required this.normalizedPhone,
    this.contactName,
    this.originalPhone,
    required this.isRegistered,
    this.registeredUid,
    this.displayName,
    this.profileImageUrl,
    this.isOnline = false,
    this.lastSeen,
  }) {
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
    lastSyncAt = DateTime.now();
  }
  
  // 🚀 Factory method - Firebase'den gelen veri için
  factory ContactIndexModel.fromFirebaseUser({
    required String normalizedPhone,
    required Map<String, dynamic> userData,
    String? contactName,
    String? originalPhone,
  }) {
    return ContactIndexModel.create(
      normalizedPhone: normalizedPhone,
      contactName: contactName,
      originalPhone: originalPhone,
      isRegistered: true,
      registeredUid: userData['uid'] ?? userData['id'],
      displayName: userData['name'] ?? userData['displayName'] ?? userData['username'],
      profileImageUrl: userData['profileImageUrl'] ?? userData['photoURL'],
      isOnline: userData['isOnline'] ?? false,
      lastSeen: userData['lastSeen'] != null ? DateTime.tryParse(userData['lastSeen'].toString()) : null,
    );
  }
  
  // 🚀 Factory method - Rehber kişisi için
  factory ContactIndexModel.fromContact({
    required String normalizedPhone,
    required String contactName,
    String? originalPhone,
  }) {
    return ContactIndexModel.create(
      normalizedPhone: normalizedPhone,
      contactName: contactName,
      originalPhone: originalPhone,
      isRegistered: false,
    );
  }
  
  // Güncelleme metodu
  void updateFromFirebase(Map<String, dynamic> userData) {
    isRegistered = true;
    registeredUid = userData['uid'] ?? userData['id'];
    displayName = userData['name'] ?? userData['displayName'] ?? userData['username'];
    profileImageUrl = userData['profileImageUrl'] ?? userData['photoURL'];
    isOnline = userData['isOnline'] ?? false;
    lastSeen = userData['lastSeen'] != null ? DateTime.tryParse(userData['lastSeen'].toString()) : null;
    updatedAt = DateTime.now();
    lastSyncAt = DateTime.now();
  }
  
  // UI için görünüm adı
  String get effectiveDisplayName {
    if (contactName?.isNotEmpty == true) return contactName!;
    if (displayName?.isNotEmpty == true) return displayName!;
    return originalPhone ?? normalizedPhone;
  }
  
  // JSON serialize/deserialize
  Map<String, dynamic> toJson() {
    return {
      'normalizedPhone': normalizedPhone,
      'contactName': contactName,
      'originalPhone': originalPhone,
      'isRegistered': isRegistered,
      'registeredUid': registeredUid,
      'displayName': displayName,
      'profileImageUrl': profileImageUrl,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastSyncAt': lastSyncAt?.toIso8601String(),
    };
  }
  
  @override
  String toString() {
    return 'ContactIndexModel(phone: $normalizedPhone, name: $effectiveDisplayName, registered: $isRegistered)';
  }
}
