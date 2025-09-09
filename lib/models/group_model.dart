import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  late String groupId;

  late String name;
  String? description;
  String? profileImageUrl;
  String? profileImageLocalPath;

  // Üye listeleri
  List<String> members = <String>[]; // Tüm üyeler (growable)
  List<String> admins = <String>[]; // Yöneticiler (growable)
  late String createdBy; // Grubu oluşturan kişi (süper admin)

  // Grup izinleri
  GroupMessagePermission messagePermission = GroupMessagePermission.everyone;

  GroupMediaPermission mediaPermission = GroupMediaPermission.downloadable;

  bool allowMembersToAddOthers =
      false; // Sadece adminler üye ekleyebilir varsayılan

  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();

  GroupModel();

  GroupModel.create({
    required this.groupId,
    required this.name,
    required this.createdBy,
    this.description,
    this.profileImageUrl,
    this.profileImageLocalPath,
    this.members = const [],
    this.admins = const [],
    this.messagePermission = GroupMessagePermission.everyone,
    this.mediaPermission = GroupMediaPermission.downloadable,
    this.allowMembersToAddOthers = false,
  }) {
    createdAt = DateTime.now();
    updatedAt = DateTime.now();

    // Listeleri growable yap
    members = List<String>.from(members);
    admins = List<String>.from(admins);

    // Oluşturan kişiyi üye ve admin listesine ekle
    if (!members.contains(createdBy)) {
      members.add(createdBy);
    }
    if (!admins.contains(createdBy)) {
      admins.add(createdBy);
    }
  }

  // Firebase'e çevirmek için Map
  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'name': name,
      'description': description,
      'profileImageUrl': profileImageUrl,
      'profileImageLocalPath': profileImageLocalPath,
      'members': members,
      'admins': admins,
      'createdBy': createdBy,
      'messagePermission': messagePermission.name,
      'mediaPermission': mediaPermission.name,
      'allowMembersToAddOthers': allowMembersToAddOthers,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  // Firebase'den çevirmek için factory
  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel.create(
      groupId: map['groupId'] ?? '',
      name: map['name'] ?? '',
      createdBy: map['createdBy'] ?? '',
      description: map['description'],
      profileImageUrl: map['profileImageUrl'],
      profileImageLocalPath: map['profileImageLocalPath'],
      members: List<String>.from(map['members'] ?? []),
      admins: List<String>.from(map['admins'] ?? []),
      messagePermission: GroupMessagePermission.values.byName(
        map['messagePermission'] ?? 'everyone',
      ),
      mediaPermission: GroupMediaPermission.values.byName(
        map['mediaPermission'] ?? 'downloadable',
      ),
      allowMembersToAddOthers: map['allowMembersToAddOthers'] ?? false,
    )
      ..createdAt = map['createdAt'] != null
          ? (map['createdAt'] is Timestamp 
              ? (map['createdAt'] as Timestamp).toDate()
              : DateTime.fromMillisecondsSinceEpoch(map['createdAt']))
          : DateTime.now()
      ..updatedAt = map['updatedAt'] != null
          ? (map['updatedAt'] is Timestamp 
              ? (map['updatedAt'] as Timestamp).toDate()
              : DateTime.fromMillisecondsSinceEpoch(map['updatedAt']))
          : DateTime.now();
  }

  // Yönetici mi kontrol et
  bool isAdmin(String userId) {
    return admins.contains(userId);
  }

  // Üye mi kontrol et
  bool isMember(String userId) {
    return members.contains(userId);
  }

  // Mesaj gönderebilir mi kontrol et
  bool canSendMessage(String userId) {
    if (!isMember(userId)) return false;

    switch (messagePermission) {
      case GroupMessagePermission.everyone:
        return true;
      case GroupMessagePermission.adminsOnly:
        return isAdmin(userId);
    }
  }

  // Üye ekleyebilir mi kontrol et
  bool canAddMembers(String userId) {
    return isAdmin(userId) || (allowMembersToAddOthers && isMember(userId));
  }

  // Grup bilgilerini düzenleyebilir mi
  bool canEditGroupInfo(String userId) {
    return isAdmin(userId);
  }
}

class GroupMemberModel {
  late String groupId;

  late String userId;

  String? displayName; // Gruptaki görünen ismi
  String? contactName; // Rehberdeki ismi
  String? firebaseName; // Firebase'deki ismi
  String? phoneNumber;
  String? profileImageUrl;

  GroupMemberRole role = GroupMemberRole.member;

  DateTime joinedAt = DateTime.now();
  DateTime? lastSeenAt;

  GroupMemberModel();

  GroupMemberModel.create({
    required this.groupId,
    required this.userId,
    this.displayName,
    this.contactName,
    this.firebaseName,
    this.phoneNumber,
    this.profileImageUrl,
    this.role = GroupMemberRole.member,
  }) {
    joinedAt = DateTime.now();
  }

  // Görüntülenecek ismi döndür (öncelik: rehber > firebase > telefon > userId)
  String get effectiveDisplayName {
    if (contactName != null && contactName!.isNotEmpty) {
      return contactName!;
    }
    if (firebaseName != null && firebaseName!.isNotEmpty) {
      return firebaseName!;
    }
    if (displayName != null && displayName!.isNotEmpty) {
      return displayName!;
    }
    if (phoneNumber != null && phoneNumber!.isNotEmpty) {
      return phoneNumber!;
    }
    return userId;
  }

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'userId': userId,
      'displayName': displayName,
      'contactName': contactName,
      'firebaseName': firebaseName,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'role': role.name,
      'joinedAt': joinedAt.millisecondsSinceEpoch,
      'lastSeenAt': lastSeenAt?.millisecondsSinceEpoch,
    };
  }

  factory GroupMemberModel.fromMap(Map<String, dynamic> map) {
    return GroupMemberModel.create(
      groupId: map['groupId'] ?? '',
      userId: map['userId'] ?? '',
      displayName: map['displayName'],
      contactName: map['contactName'],
      firebaseName: map['firebaseName'],
      phoneNumber: map['phoneNumber'],
      profileImageUrl: map['profileImageUrl'],
      role: GroupMemberRole.values.byName(map['role'] ?? 'member'),
    )
      ..joinedAt = map['joinedAt'] != null
          ? (map['joinedAt'] is Timestamp 
              ? (map['joinedAt'] as Timestamp).toDate()
              : DateTime.fromMillisecondsSinceEpoch(map['joinedAt']))
          : DateTime.now()
      ..lastSeenAt = map['lastSeenAt'] != null
          ? (map['lastSeenAt'] is Timestamp 
              ? (map['lastSeenAt'] as Timestamp).toDate()
              : DateTime.fromMillisecondsSinceEpoch(map['lastSeenAt']))
          : null;
  }
}

enum GroupMessagePermission {
  everyone, // Herkes mesaj gönderebilir
  adminsOnly, // Sadece yöneticiler mesaj gönderebilir
}

enum GroupMediaPermission {
  downloadable, // Medya dosyaları indirilebilir
  viewOnly, // Medya sadece grupta görüntülenebilir
}

enum GroupMemberRole {
  member, // Normal üye
  admin, // Yönetici
}
