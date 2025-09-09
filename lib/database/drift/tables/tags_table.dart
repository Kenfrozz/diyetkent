import 'package:drift/drift.dart';

@DataClassName('TagData')
class TagsTable extends Table {
  @override
  String get tableName => 'tags';

  // Primary key
  IntColumn get id => integer().autoIncrement()();

  // Unique identifier
  TextColumn get tagId => text().unique()();

  // Tag information
  TextColumn get name => text()();
  TextColumn get color => text().nullable()(); // Hex color code (e.g: "#FF5722")
  TextColumn get icon => text().nullable()(); // Icon name (e.g: "work", "family", "friends")
  TextColumn get description => text().nullable()();

  // Usage tracking
  IntColumn get usageCount => integer().withDefault(const Constant(0))();

  // Timestamps
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}