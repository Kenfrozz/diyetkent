import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  late String chatId;

  // Grup sohbeti desteği
  bool isGroup = false;
  String? groupId;
  String? groupName;
  String? groupImage;
  String? groupDescription;

  // Bireysel sohbet için (grup değilse kullanılır)
  String? otherUserId;
  String? otherUserName;
  String? otherUserContactName; // Rehberdeki isim
  String? otherUserPhoneNumber;
  String? otherUserProfileImage;

  String? lastMessage;
  DateTime? lastMessageTime;
  bool isLastMessageFromMe = false;
  bool isLastMessageRead = false;

  int unreadCount = 0;
  bool isPinned = false;
  bool isMuted = false;
  bool isArchived = false;

  List<String> tags = <String>[]; // growable list

  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();

  ChatModel();

  ChatModel.create({
    required this.chatId,
    this.isGroup = false,
    this.groupId,
    this.groupName,
    this.groupImage,
    this.groupDescription,
    this.otherUserId,
    this.otherUserName,
    this.otherUserContactName,
    this.otherUserPhoneNumber,
    this.otherUserProfileImage,
    this.lastMessage,
    this.lastMessageTime,
    this.isLastMessageFromMe = false,
    this.isLastMessageRead = false,
    this.unreadCount = 0,
    this.isPinned = false,
    this.isMuted = false,
    this.isArchived = false,
    // Growable kopya oluştur
    this.tags = const [],
  }) {
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
    tags = List<String>.from(tags); // sabit liste geldiyse growable yap
  }

  // Bireysel sohbet oluşturmak için yardımcı constructor
  ChatModel.createPrivateChat({
    required this.otherUserId,
    required this.otherUserName,
    required String otherUserPhone,
    this.otherUserProfileImage,
  }) {
    // Tutarlı chat ID oluştur: iki kullanıcı ID'sini sırala ve birleştir
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    final ids = [currentUserId, otherUserId];
    ids.sort();
    chatId = '${ids[0]}_${ids[1]}';
    
    isGroup = false;
    otherUserPhoneNumber = otherUserPhone;
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
    tags = <String>[];
  }

  // Grup sohbeti oluşturmak için yardımcı constructor
  ChatModel.createGroup({
    required this.chatId,
    required this.groupId,
    required this.groupName,
    this.groupImage,
    this.groupDescription,
    this.lastMessage,
    this.lastMessageTime,
    this.isLastMessageFromMe = false,
    this.isLastMessageRead = false,
    this.unreadCount = 0,
    this.isPinned = false,
    this.isMuted = false,
    this.isArchived = false,
    this.tags = const [],
  }) {
    isGroup = true;
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
    tags = List<String>.from(tags);
  }
  
  // UI için yardımcı getter - participants listesi
  List<String> get participants {
    if (isGroup) {
      // Grup için gerçek participants listesi gerekir
      // Şimdilik boş liste döndürüyor
      return [];
    } else {
      // Bireysel sohbet için otherUserId
      return otherUserId != null ? [otherUserId!] : [];
    }
  }

  // Firebase'e çevirmek için Map
  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'isGroup': isGroup,
      'groupId': groupId,
      'groupName': groupName,
      'groupImage': groupImage,
      'groupDescription': groupDescription,
      'otherUserId': otherUserId,
      'otherUserName': otherUserName,
      'otherUserPhoneNumber': otherUserPhoneNumber,
      'otherUserProfileImage': otherUserProfileImage,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.millisecondsSinceEpoch,
      'isLastMessageFromMe': isLastMessageFromMe,
      'isLastMessageRead': isLastMessageRead,
      'unreadCount': unreadCount,
      'isPinned': isPinned,
      'isMuted': isMuted,
      'isArchived': isArchived,
      'tags': tags,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  // Firebase'den çevirmek için factory
  factory ChatModel.fromMap(Map<String, dynamic> map) {
    return ChatModel.create(
      chatId: map['chatId'] ?? '',
      isGroup: map['isGroup'] ?? false,
      groupId: map['groupId'],
      groupName: map['groupName'],
      groupImage: map['groupImage'],
      groupDescription: map['groupDescription'],
      otherUserId: map['otherUserId'],
      otherUserName: map['otherUserName'],
      otherUserPhoneNumber: map['otherUserPhoneNumber'],
      otherUserProfileImage: map['otherUserProfileImage'],
      lastMessage: map['lastMessage'],
      lastMessageTime: map['lastMessageTime'] != null
          ? (map['lastMessageTime'] is Timestamp 
              ? (map['lastMessageTime'] as Timestamp).toDate()
              : DateTime.fromMillisecondsSinceEpoch(map['lastMessageTime']))
          : null,
      isLastMessageFromMe: map['isLastMessageFromMe'] ?? false,
      isLastMessageRead: map['isLastMessageRead'] ?? false,
      unreadCount: map['unreadCount'] ?? 0,
      isPinned: map['isPinned'] ?? false,
      isMuted: map['isMuted'] ?? false,
      isArchived: map['isArchived'] ?? false,
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  // Görüntülenecek ismi döndür (grup ise grup adı, bireysel ise kullanıcı adı)
  String get displayName {
    if (isGroup) {
      return groupName ?? 'Adsız Grup';
    } else {
      return otherUserContactName ?? otherUserName ?? 'Bilinmeyen Kullanıcı';
    }
  }

  // Görüntülenecek profil resmini döndür
  String? get displayImage {
    if (isGroup) {
      return groupImage;
    } else {
      return otherUserProfileImage;
    }
  }

  // CopyWith method for immutable updates
  ChatModel copyWith({
    String? chatId,
    bool? isGroup,
    String? groupId,
    String? groupName,
    String? groupImage,
    String? groupDescription,
    String? otherUserId,
    String? otherUserName,
    String? otherUserContactName,
    String? otherUserPhoneNumber,
    String? otherUserProfileImage,
    String? lastMessage,
    DateTime? lastMessageTime,
    bool? isLastMessageFromMe,
    bool? isLastMessageRead,
    int? unreadCount,
    bool? isPinned,
    bool? isMuted,
    bool? isArchived,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final updated = ChatModel.create(
      chatId: chatId ?? this.chatId,
      isGroup: isGroup ?? this.isGroup,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      groupImage: groupImage ?? this.groupImage,
      groupDescription: groupDescription ?? this.groupDescription,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserContactName: otherUserContactName ?? this.otherUserContactName,
      otherUserPhoneNumber: otherUserPhoneNumber ?? this.otherUserPhoneNumber,
      otherUserProfileImage: otherUserProfileImage ?? this.otherUserProfileImage,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      isLastMessageFromMe: isLastMessageFromMe ?? this.isLastMessageFromMe,
      isLastMessageRead: isLastMessageRead ?? this.isLastMessageRead,
      unreadCount: unreadCount ?? this.unreadCount,
      isPinned: isPinned ?? this.isPinned,
      isMuted: isMuted ?? this.isMuted,
      isArchived: isArchived ?? this.isArchived,
      tags: tags ?? this.tags,
    );
    
    if (createdAt != null) updated.createdAt = createdAt;
    if (updatedAt != null) updated.updatedAt = updatedAt;
    
    return updated;
  }
}
