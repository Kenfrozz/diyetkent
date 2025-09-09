class CallLogModel {
  late String callId; // Firestore call doc id

  // Karşı taraf
  String? otherUserId;
  String? otherUserPhone; // fallback

  // Görünüm/özet için (isteğe bağlı)
  String? otherDisplayName; // rehber üzerinden zamanla doldurulabilir

  bool isVideo = false; // şu an sadece sesli

  CallLogDirection direction = CallLogDirection.outgoing;

  CallLogStatus status = CallLogStatus.ringing;

  DateTime createdAt = DateTime.now();
  DateTime? startedAt; // oluşturulma zamanı
  DateTime? connectedAt;
  DateTime? endedAt;

  int get durationSeconds {
    if (connectedAt == null || endedAt == null) return 0;
    return endedAt!.difference(connectedAt!).inSeconds;
  }

  DateTime updatedAt = DateTime.now();
}

enum CallLogDirection { incoming, outgoing }

enum CallLogStatus { ringing, connected, ended, declined, missed }