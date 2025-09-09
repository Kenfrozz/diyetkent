class CallModel {
  final String name;
  final String phoneNumber;
  final DateTime time;
  final CallType type;
  final CallDirection direction;
  final String avatarUrl;

  CallModel({
    required this.name,
    required this.phoneNumber,
    required this.time,
    required this.type,
    required this.direction,
    required this.avatarUrl,
  });
}

enum CallType { voice, video }

enum CallDirection { incoming, outgoing, missed }
