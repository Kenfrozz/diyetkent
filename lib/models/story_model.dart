class StoryModel {
  String storyId = '';
  String userId = '';

  String userPhone = '';
  String userName = '';
  String userProfileImage = '';

  StoryType type = StoryType.text;
  String content = '';
  String? mediaUrl;
  String? thumbnailUrl;
  String? mediaLocalPath;
  String backgroundColor = '#FF4CAF50'; // Default green

  DateTime createdAt = DateTime.now();
  DateTime expiresAt = DateTime.now().add(const Duration(hours: 24));

  bool isViewed = false;
  List<String> viewerIds = [];
  List<String> repliedUserIds = [];

  
  bool isActive = true;

  // Yerel veri
  bool isFromCurrentUser = false;
  int viewCount = 0;
  DateTime? lastViewedAt;

  StoryModel();

  StoryModel.fromMap(Map<String, dynamic> map) {
    storyId = map['storyId'] ?? '';
    userId = map['userId'] ?? '';
    userPhone = map['userPhone'] ?? '';
    userName = map['userName'] ?? '';
    userProfileImage = map['userProfileImage'] ?? '';
    type = StoryType.values.firstWhere(
      (e) => e.toString().split('.').last == map['type'],
      orElse: () => StoryType.text,
    );
    content = map['content'] ?? '';
    mediaUrl = map['mediaUrl'];
    thumbnailUrl = map['thumbnailUrl'];
    backgroundColor = map['backgroundColor'] ?? '#FF4CAF50';
    // Safe timestamp conversion
    final createdAtValue = map['createdAt'];
    createdAt = createdAtValue is DateTime 
        ? createdAtValue 
        : (createdAtValue?.toDate() ?? DateTime.now());
    
    final expiresAtValue = map['expiresAt'];
    expiresAt = expiresAtValue is DateTime 
        ? expiresAtValue 
        : (expiresAtValue?.toDate() ?? DateTime.now().add(const Duration(hours: 24)));
    isViewed = map['isViewed'] ?? false;
    viewerIds = List<String>.from(map['viewerIds'] ?? []);
    repliedUserIds = List<String>.from(map['repliedUserIds'] ?? []);
    isActive = map['isActive'] ?? true;
  }

  Map<String, dynamic> toMap() {
    return {
      'storyId': storyId,
      'userId': userId,
      'userPhone': userPhone,
      'userName': userName,
      'userProfileImage': userProfileImage,
      'type': type.toString().split('.').last,
      'content': content,
      'mediaUrl': mediaUrl,
      'thumbnailUrl': thumbnailUrl,
      'backgroundColor': backgroundColor,
      'createdAt': createdAt,
      'expiresAt': expiresAt,
      'isViewed': isViewed,
      'viewerIds': viewerIds,
      'repliedUserIds': repliedUserIds,
      'isActive': isActive,
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'şimdi';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}dk';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}sa';
    } else {
      return '1g';
    }
  }
}

enum StoryType { text, image, video }
