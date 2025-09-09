import 'package:drift/drift.dart';

// Call direction enum
enum CallLogDirection { incoming, outgoing }

// Call status enum
enum CallLogStatus { ringing, connected, ended, declined, missed }

@DataClassName('CallLogData')
class CallLogsTable extends Table {
  @override
  String get tableName => 'call_logs';

  // Primary key
  IntColumn get id => integer().autoIncrement()();

  // Unique identifier
  TextColumn get callId => text().unique()(); // Firestore call doc id

  // Other party information
  TextColumn get otherUserId => text().nullable()();
  TextColumn get otherUserPhone => text().nullable()(); // fallback

  // Display/summary information (optional)
  TextColumn get otherDisplayName => text().nullable()(); // from contacts/Isar over time

  // Call details
  BoolColumn get isVideo => boolean().withDefault(const Constant(false))(); // currently only audio

  // Call direction - stored as enum
  IntColumn get direction => intEnum<CallLogDirection>().withDefault(Constant(CallLogDirection.outgoing.index))();

  // Call status - stored as enum
  IntColumn get status => intEnum<CallLogStatus>().withDefault(Constant(CallLogStatus.ringing.index))();

  // Timestamps
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get startedAt => dateTime().nullable()(); // creation time
  DateTimeColumn get connectedAt => dateTime().nullable()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}