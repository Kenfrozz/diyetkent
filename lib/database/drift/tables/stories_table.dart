import 'package:drift/drift.dart';

@DataClassName('StoryData')
class StoriesTable extends Table {
  @override
  String get tableName => 'stories';

  // Primary key
  IntColumn get id => integer().autoIncrement()();

  // Identifiers
  TextColumn get storyId => text()();
  TextColumn get userId => text()();

  // User information
  TextColumn get userPhone => text().withDefault(const Constant(''))();
  TextColumn get userName => text().withDefault(const Constant(''))();
  TextColumn get userProfileImage => text().withDefault(const Constant(''))();

  // Story content
  TextColumn get type => text().withDefault(const Constant('text'))(); // text, image, video
  TextColumn get content => text().withDefault(const Constant(''))();
  TextColumn get mediaUrl => text().nullable()();
  TextColumn get thumbnailUrl => text().nullable()();
  TextColumn get mediaLocalPath => text().nullable()();
  TextColumn get backgroundColor => text().withDefault(const Constant('#FF4CAF50'))();

  // Timestamps
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get expiresAt => dateTime()();

  // View tracking
  BoolColumn get isViewed => boolean().withDefault(const Constant(false))();
  TextColumn get viewerIds => text().withDefault(const Constant('[]'))(); // List<String> as JSON
  TextColumn get repliedUserIds => text().withDefault(const Constant('[]'))(); // List<String> as JSON

  // Status
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  // Local data
  BoolColumn get isFromCurrentUser => boolean().withDefault(const Constant(false))();
  IntColumn get viewCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastViewedAt => dateTime().nullable()();
}