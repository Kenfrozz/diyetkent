import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  late String messageId;
  late String chatId;

  late String senderId;
  late String content;

  late MessageType type;
  late MessageStatus status;

  DateTime timestamp = DateTime.now();
  DateTime? readAt;
  DateTime? deliveredAt;

  // Medya mesajları için
  String? mediaUrl;
  String? mediaLocalPath;
  String? thumbnailUrl;
  double? mediaWidth;
  double? mediaHeight;
  int? mediaDuration; // Video/ses için saniye cinsinden

  // Yanıtlanan mesaj için
  String? replyToMessageId;
  String? replyToContent;
  String? replyToSenderId;

  // Konum mesajları için
  double? latitude;
  double? longitude;
  String? locationName;

  // Düzenleme bilgisi
  bool isEdited = false;
  DateTime? editedAt;

  MessageModel();

  MessageModel.create({
    required this.messageId,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.type,
    this.status = MessageStatus.sending,
    this.mediaUrl,
    this.mediaLocalPath,
    this.thumbnailUrl,
    this.mediaWidth,
    this.mediaHeight,
    this.mediaDuration,
    this.replyToMessageId,
    this.replyToContent,
    this.replyToSenderId,
    this.latitude,
    this.longitude,
    this.locationName,
    this.isEdited = false,
    this.editedAt,
  }) {
    timestamp = DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'chatId': chatId,
      'senderId': senderId,
      'content': content,
      'type': type.name,
      'status': status.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'readAt': readAt?.millisecondsSinceEpoch,
      'deliveredAt': deliveredAt?.millisecondsSinceEpoch,
      'mediaUrl': mediaUrl,
      'mediaLocalPath': mediaLocalPath,
      'thumbnailUrl': thumbnailUrl,
      'mediaWidth': mediaWidth,
      'mediaHeight': mediaHeight,
      'mediaDuration': mediaDuration,
      'replyToMessageId': replyToMessageId,
      'replyToContent': replyToContent,
      'replyToSenderId': replyToSenderId,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'isEdited': isEdited,
      'editedAt': editedAt?.millisecondsSinceEpoch,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel.create(
        messageId: map['messageId'] ?? '',
        chatId: map['chatId'] ?? '',
        senderId: map['senderId'] ?? '',
        content: map['content'] ?? '',
        type: MessageType.values.byName(map['type'] ?? 'text'),
        status: MessageStatus.values.byName(map['status'] ?? 'sending'),
        mediaUrl: map['mediaUrl'],
        mediaLocalPath: map['mediaLocalPath'],
        thumbnailUrl: map['thumbnailUrl'],
        mediaWidth: map['mediaWidth']?.toDouble(),
        mediaHeight: map['mediaHeight']?.toDouble(),
        mediaDuration: map['mediaDuration'],
        replyToMessageId: map['replyToMessageId'],
        replyToContent: map['replyToContent'],
        replyToSenderId: map['replyToSenderId'],
        latitude: map['latitude']?.toDouble(),
        longitude: map['longitude']?.toDouble(),
        locationName: map['locationName'],
      )
      ..timestamp = map['timestamp'] != null
          ? (map['timestamp'] is Timestamp 
              ? (map['timestamp'] as Timestamp).toDate()
              : DateTime.fromMillisecondsSinceEpoch(map['timestamp']))
          : DateTime.now()
      ..readAt = map['readAt'] != null
          ? (map['readAt'] is Timestamp 
              ? (map['readAt'] as Timestamp).toDate()
              : DateTime.fromMillisecondsSinceEpoch(map['readAt']))
          : null
      ..deliveredAt = map['deliveredAt'] != null
          ? (map['deliveredAt'] is Timestamp 
              ? (map['deliveredAt'] as Timestamp).toDate()
              : DateTime.fromMillisecondsSinceEpoch(map['deliveredAt']))
          : null;
  }
}

enum MessageType {
  text,
  image,
  video,
  audio,
  document,
  location,
  contact,
  sticker,
  gif,
}

enum MessageStatus { sending, sent, delivered, read, failed }
