import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/call_logs_table.dart';

part 'call_log_dao.g.dart';

@DriftAccessor(tables: [CallLogsTable])
class CallLogDao extends DatabaseAccessor<AppDatabase> with _$CallLogDaoMixin {
  CallLogDao(super.db);

  // Get all call logs
  Future<List<CallLogData>> getAllCallLogs() {
    return (select(callLogsTable)
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Watch all call logs
  Stream<List<CallLogData>> watchAllCallLogs() {
    return (select(callLogsTable)
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .watch();
  }

  // Get call log by ID
  Future<CallLogData?> getCallLogById(String callId) {
    return (select(callLogsTable)..where((t) => t.callId.equals(callId))).getSingleOrNull();
  }

  // Watch call log by ID
  Stream<CallLogData?> watchCallLogById(String callId) {
    return (select(callLogsTable)..where((t) => t.callId.equals(callId))).watchSingleOrNull();
  }

  // Get call logs by other user ID
  Future<List<CallLogData>> getCallLogsByOtherUserId(String otherUserId) {
    return (select(callLogsTable)
          ..where((t) => t.otherUserId.equals(otherUserId))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Watch call logs by other user ID
  Stream<List<CallLogData>> watchCallLogsByOtherUserId(String otherUserId) {
    return (select(callLogsTable)
          ..where((t) => t.otherUserId.equals(otherUserId))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .watch();
  }

  // Get call logs by phone number
  Future<List<CallLogData>> getCallLogsByPhoneNumber(String phoneNumber) {
    return (select(callLogsTable)
          ..where((t) => t.otherUserPhone.equals(phoneNumber))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Save or update call log (upsert)
  Future<int> saveCallLog(CallLogsTableCompanion callLog) {
    return into(callLogsTable).insertOnConflictUpdate(callLog);
  }

  // Batch save call logs
  Future<void> saveCallLogs(List<CallLogsTableCompanion> callLogList) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(callLogsTable, callLogList);
    });
  }

  // Update call log
  Future<bool> updateCallLog(CallLogsTableCompanion callLog) {
    return update(callLogsTable).replace(callLog);
  }

  // Delete call log
  Future<int> deleteCallLog(String callId) {
    return (delete(callLogsTable)..where((t) => t.callId.equals(callId))).go();
  }

  // Update call status
  Future<int> updateCallStatus(String callId, CallLogStatus status, {DateTime? timestamp}) {
    return (update(callLogsTable)..where((t) => t.callId.equals(callId)))
        .write(CallLogsTableCompanion(
      status: Value(status),
      updatedAt: Value(DateTime.now()),
      // Set specific timestamp based on status
      connectedAt: status == CallLogStatus.connected ? Value(timestamp ?? DateTime.now()) : const Value.absent(),
      endedAt: status == CallLogStatus.ended || status == CallLogStatus.declined || status == CallLogStatus.missed 
          ? Value(timestamp ?? DateTime.now()) : const Value.absent(),
    ));
  }

  // Update call timestamps
  Future<int> updateCallTimestamps({
    required String callId,
    DateTime? startedAt,
    DateTime? connectedAt,
    DateTime? endedAt,
  }) {
    return (update(callLogsTable)..where((t) => t.callId.equals(callId)))
        .write(CallLogsTableCompanion(
      startedAt: Value.absentIfNull(startedAt),
      connectedAt: Value.absentIfNull(connectedAt),
      endedAt: Value.absentIfNull(endedAt),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update call display name
  Future<int> updateCallDisplayName(String callId, String displayName) {
    return (update(callLogsTable)..where((t) => t.callId.equals(callId)))
        .write(CallLogsTableCompanion(
      otherDisplayName: Value(displayName),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Get call logs by direction
  Future<List<CallLogData>> getCallLogsByDirection(CallLogDirection direction) {
    return (select(callLogsTable)
          ..where((t) => t.direction.equals(direction.index))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Watch call logs by direction
  Stream<List<CallLogData>> watchCallLogsByDirection(CallLogDirection direction) {
    return (select(callLogsTable)
          ..where((t) => t.direction.equals(direction.index))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .watch();
  }

  // Get call logs by status
  Future<List<CallLogData>> getCallLogsByStatus(CallLogStatus status) {
    return (select(callLogsTable)
          ..where((t) => t.status.equals(status.index))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Watch call logs by status
  Stream<List<CallLogData>> watchCallLogsByStatus(CallLogStatus status) {
    return (select(callLogsTable)
          ..where((t) => t.status.equals(status.index))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .watch();
  }

  // Get missed call logs
  Future<List<CallLogData>> getMissedCallLogs() {
    return (select(callLogsTable)
          ..where((t) => t.status.equals(CallLogStatus.missed.index))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Watch missed call logs
  Stream<List<CallLogData>> watchMissedCallLogs() {
    return (select(callLogsTable)
          ..where((t) => t.status.equals(CallLogStatus.missed.index))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .watch();
  }

  // Get incoming call logs
  Future<List<CallLogData>> getIncomingCallLogs() {
    return (select(callLogsTable)
          ..where((t) => t.direction.equals(CallLogDirection.incoming.index))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Get outgoing call logs
  Future<List<CallLogData>> getOutgoingCallLogs() {
    return (select(callLogsTable)
          ..where((t) => t.direction.equals(CallLogDirection.outgoing.index))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Get video call logs
  Future<List<CallLogData>> getVideoCallLogs() {
    return (select(callLogsTable)
          ..where((t) => t.isVideo.equals(true))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Get audio call logs
  Future<List<CallLogData>> getAudioCallLogs() {
    return (select(callLogsTable)
          ..where((t) => t.isVideo.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Get connected call logs (successful calls)
  Future<List<CallLogData>> getConnectedCallLogs() {
    return (select(callLogsTable)
          ..where((t) => t.status.equals(CallLogStatus.connected.index) | t.status.equals(CallLogStatus.ended.index))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Get active call logs (ongoing calls)
  Future<List<CallLogData>> getActiveCallLogs() {
    return (select(callLogsTable)
          ..where((t) => t.status.equals(CallLogStatus.ringing.index) | t.status.equals(CallLogStatus.connected.index))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Watch active call logs
  Stream<List<CallLogData>> watchActiveCallLogs() {
    return (select(callLogsTable)
          ..where((t) => t.status.equals(CallLogStatus.ringing.index) | t.status.equals(CallLogStatus.connected.index))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .watch();
  }

  // Get call logs in date range
  Future<List<CallLogData>> getCallLogsInDateRange(DateTime from, DateTime to) {
    return (select(callLogsTable)
          ..where((t) => t.createdAt.isBetweenValues(from, to))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Search call logs by display name or phone
  Future<List<CallLogData>> searchCallLogs(String query) {
    final lowerQuery = query.toLowerCase();
    return (select(callLogsTable)
          ..where((t) => t.otherDisplayName.lower().contains(lowerQuery) |
              t.otherUserPhone.lower().contains(lowerQuery))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Get call duration (for ended calls)
  Future<Duration?> getCallDuration(String callId) async {
    final call = await getCallLogById(callId);
    if (call != null && call.connectedAt != null && call.endedAt != null) {
      return call.endedAt!.difference(call.connectedAt!);
    }
    return null;
  }

  // Get call logs with pagination
  Future<List<CallLogData>> getCallLogsPaginated({
    required int limit,
    int? offset,
    CallLogDirection? direction,
    CallLogStatus? status,
    bool? isVideo,
    String? orderBy = 'createdAt',
    bool ascending = false,
  }) {
    var query = select(callLogsTable);
    
    // Add filters
    if (direction != null) {
      query = query..where((t) => t.direction.equals(direction.index));
    }
    
    if (status != null) {
      query = query..where((t) => t.status.equals(status.index));
    }
    
    if (isVideo != null) {
      query = query..where((t) => t.isVideo.equals(isVideo));
    }
    
    // Add ordering
    switch (orderBy) {
      case 'createdAt':
        query = query..orderBy([(t) => OrderingTerm(
          expression: t.createdAt, 
          mode: ascending ? OrderingMode.asc : OrderingMode.desc
        )]);
        break;
      case 'connectedAt':
        query = query..orderBy([(t) => OrderingTerm(
          expression: t.connectedAt, 
          mode: ascending ? OrderingMode.asc : OrderingMode.desc
        )]);
        break;
      case 'endedAt':
        query = query..orderBy([(t) => OrderingTerm(
          expression: t.endedAt, 
          mode: ascending ? OrderingMode.asc : OrderingMode.desc
        )]);
        break;
    }
    
    // Add pagination
    query = query..limit(limit);
    if (offset != null && offset > 0) {
      query = query..limit(limit, offset: offset);
    }
    
    return query.get();
  }

  // Count call logs
  Future<int> countCallLogs({
    CallLogDirection? direction,
    CallLogStatus? status,
    bool? isVideo,
  }) {
    var query = selectOnly(callLogsTable);
    
    if (direction != null) {
      query = query..where(callLogsTable.direction.equals(direction.index));
    }
    
    if (status != null) {
      query = query..where(callLogsTable.status.equals(status.index));
    }
    
    if (isVideo != null) {
      query = query..where(callLogsTable.isVideo.equals(isVideo));
    }
    
    query = query..addColumns([callLogsTable.id.count()]);
    return query.map((row) => row.read(callLogsTable.id.count()) ?? 0).getSingle();
  }

  // Count missed calls
  Future<int> countMissedCalls() {
    final query = selectOnly(callLogsTable)
      ..where(callLogsTable.status.equals(CallLogStatus.missed.index))
      ..addColumns([callLogsTable.id.count()]);
    return query.map((row) => row.read(callLogsTable.id.count()) ?? 0).getSingle();
  }

  // Get call statistics
  Future<Map<String, int>> getCallStatistics() async {
    final total = await countCallLogs();
    final incoming = await countCallLogs(direction: CallLogDirection.incoming);
    final outgoing = await countCallLogs(direction: CallLogDirection.outgoing);
    final missed = await countCallLogs(status: CallLogStatus.missed);
    final connected = await countCallLogs(status: CallLogStatus.connected);
    final video = await countCallLogs(isVideo: true);
    final audio = await countCallLogs(isVideo: false);
    
    return {
      'total': total,
      'incoming': incoming,
      'outgoing': outgoing,
      'missed': missed,
      'connected': connected,
      'video': video,
      'audio': audio,
    };
  }

  // Get recent calls (last 24 hours)
  Future<List<CallLogData>> getRecentCalls({Duration? within}) {
    final since = within != null 
        ? DateTime.now().subtract(within)
        : DateTime.now().subtract(const Duration(hours: 24));
        
    return (select(callLogsTable)
          ..where((t) => t.createdAt.isBiggerOrEqualValue(since))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Delete old call logs
  Future<int> deleteOldCallLogs({Duration? olderThan}) {
    final thresholdTime = olderThan != null 
        ? DateTime.now().subtract(olderThan)
        : DateTime.now().subtract(const Duration(days: 30));
        
    return (delete(callLogsTable)
          ..where((t) => t.createdAt.isSmallerThanValue(thresholdTime)))
        .go();
  }

  // Clear all call logs
  Future<int> clearAll() {
    return delete(callLogsTable).go();
  }
}