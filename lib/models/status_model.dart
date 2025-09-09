class StatusModel {
  final String name;
  final String statusText;
  final DateTime time;
  final String avatarUrl;
  final bool isMyStatus;
  final bool isSeen;

  StatusModel({
    required this.name,
    required this.statusText,
    required this.time,
    required this.avatarUrl,
    this.isMyStatus = false,
    this.isSeen = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'statusText': statusText,
      'time': time.millisecondsSinceEpoch,
      'avatarUrl': avatarUrl,
      'isMyStatus': isMyStatus,
      'isSeen': isSeen,
    };
  }

  factory StatusModel.fromMap(Map<String, dynamic> map) {
    return StatusModel(
      name: map['name'] ?? '',
      statusText: map['statusText'] ?? '',
      time: DateTime.fromMillisecondsSinceEpoch(map['time'] ?? 0),
      avatarUrl: map['avatarUrl'] ?? '',
      isMyStatus: map['isMyStatus'] ?? false,
      isSeen: map['isSeen'] ?? false,
    );
  }

  StatusModel copyWith({
    String? name,
    String? statusText,
    DateTime? time,
    String? avatarUrl,
    bool? isMyStatus,
    bool? isSeen,
  }) {
    return StatusModel(
      name: name ?? this.name,
      statusText: statusText ?? this.statusText,
      time: time ?? this.time,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isMyStatus: isMyStatus ?? this.isMyStatus,
      isSeen: isSeen ?? this.isSeen,
    );
  }
}
