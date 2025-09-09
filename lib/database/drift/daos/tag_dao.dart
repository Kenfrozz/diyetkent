import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/tags_table.dart';

part 'tag_dao.g.dart';

@DriftAccessor(tables: [TagsTable])
class TagDao extends DatabaseAccessor<AppDatabase> with _$TagDaoMixin {
  TagDao(super.db);

  // Get all tags
  Future<List<TagData>> getAllTags() {
    return (select(tagsTable)
          ..orderBy([(t) => OrderingTerm(expression: t.name, mode: OrderingMode.asc)]))
        .get();
  }

  // Watch all tags
  Stream<List<TagData>> watchAllTags() {
    return (select(tagsTable)
          ..orderBy([(t) => OrderingTerm(expression: t.name, mode: OrderingMode.asc)]))
        .watch();
  }

  // Watch tags ordered by usage count
  Stream<List<TagData>> watchTagsByUsage() {
    return (select(tagsTable)
          ..orderBy([(t) => OrderingTerm(expression: t.usageCount, mode: OrderingMode.desc)]))
        .watch();
  }

  // Get tag by ID
  Future<TagData?> getTagById(String tagId) {
    return (select(tagsTable)..where((t) => t.tagId.equals(tagId))).getSingleOrNull();
  }

  // Watch tag by ID
  Stream<TagData?> watchTagById(String tagId) {
    return (select(tagsTable)..where((t) => t.tagId.equals(tagId))).watchSingleOrNull();
  }

  // Get tag by name
  Future<TagData?> getTagByName(String name) {
    return (select(tagsTable)..where((t) => t.name.equals(name))).getSingleOrNull();
  }

  // Save or update tag (upsert)
  Future<int> saveTag(TagsTableCompanion tag) {
    return into(tagsTable).insertOnConflictUpdate(tag);
  }

  // Batch save tags
  Future<void> saveTags(List<TagsTableCompanion> tagList) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(tagsTable, tagList);
    });
  }

  // Update tag
  Future<bool> updateTag(TagsTableCompanion tag) {
    return update(tagsTable).replace(tag);
  }

  // Delete tag
  Future<int> deleteTag(String tagId) {
    return (delete(tagsTable)..where((t) => t.tagId.equals(tagId))).go();
  }

  // Update tag info
  Future<int> updateTagInfo({
    required String tagId,
    String? name,
    String? color,
    String? icon,
    String? description,
  }) {
    return (update(tagsTable)..where((t) => t.tagId.equals(tagId)))
        .write(TagsTableCompanion(
      name: Value.absentIfNull(name),
      color: Value.absentIfNull(color),
      icon: Value.absentIfNull(icon),
      description: Value.absentIfNull(description),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Increment tag usage count
  Future<int> incrementTagUsage(String tagId) async {
    final tag = await getTagById(tagId);
    if (tag != null) {
      return (update(tagsTable)..where((t) => t.tagId.equals(tagId)))
          .write(TagsTableCompanion(
        usageCount: Value(tag.usageCount + 1),
        updatedAt: Value(DateTime.now()),
      ));
    }
    return 0;
  }

  // Decrement tag usage count
  Future<int> decrementTagUsage(String tagId) async {
    final tag = await getTagById(tagId);
    if (tag != null && tag.usageCount > 0) {
      return (update(tagsTable)..where((t) => t.tagId.equals(tagId)))
          .write(TagsTableCompanion(
        usageCount: Value(tag.usageCount - 1),
        updatedAt: Value(DateTime.now()),
      ));
    }
    return 0;
  }

  // Reset tag usage count
  Future<int> resetTagUsage(String tagId) {
    return (update(tagsTable)..where((t) => t.tagId.equals(tagId)))
        .write(TagsTableCompanion(
      usageCount: const Value(0),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Search tags by name
  Future<List<TagData>> searchTags(String query) {
    final lowerQuery = query.toLowerCase();
    return (select(tagsTable)
          ..where((t) => t.name.lower().contains(lowerQuery) |
              t.description.lower().contains(lowerQuery))
          ..orderBy([(t) => OrderingTerm(expression: t.name, mode: OrderingMode.asc)]))
        .get();
  }

  // Get tags by color
  Future<List<TagData>> getTagsByColor(String color) {
    return (select(tagsTable)
          ..where((t) => t.color.equals(color))
          ..orderBy([(t) => OrderingTerm(expression: t.name, mode: OrderingMode.asc)]))
        .get();
  }

  // Get tags by icon
  Future<List<TagData>> getTagsByIcon(String icon) {
    return (select(tagsTable)
          ..where((t) => t.icon.equals(icon))
          ..orderBy([(t) => OrderingTerm(expression: t.name, mode: OrderingMode.asc)]))
        .get();
  }

  // Get most used tags
  Future<List<TagData>> getMostUsedTags({int limit = 10}) {
    return (select(tagsTable)
          ..where((t) => t.usageCount.isBiggerThanValue(0))
          ..orderBy([(t) => OrderingTerm(expression: t.usageCount, mode: OrderingMode.desc)])
          ..limit(limit))
        .get();
  }

  // Get least used tags
  Future<List<TagData>> getLeastUsedTags({int limit = 10}) {
    return (select(tagsTable)
          ..orderBy([(t) => OrderingTerm(expression: t.usageCount, mode: OrderingMode.asc)])
          ..limit(limit))
        .get();
  }

  // Get unused tags
  Future<List<TagData>> getUnusedTags() {
    return (select(tagsTable)
          ..where((t) => t.usageCount.equals(0))
          ..orderBy([(t) => OrderingTerm(expression: t.name, mode: OrderingMode.asc)]))
        .get();
  }

  // Get recently created tags
  Future<List<TagData>> getRecentTags({int limit = 10}) {
    return (select(tagsTable)
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])
          ..limit(limit))
        .get();
  }

  // Get tags created in date range
  Future<List<TagData>> getTagsInDateRange(DateTime from, DateTime to) {
    return (select(tagsTable)
          ..where((t) => t.createdAt.isBetweenValues(from, to))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Get tags with pagination
  Future<List<TagData>> getTagsPaginated({
    required int limit,
    int? offset,
    String? orderBy = 'name',
    bool ascending = true,
  }) {
    var query = select(tagsTable);
    
    // Add ordering
    switch (orderBy) {
      case 'name':
        query = query..orderBy([(t) => OrderingTerm(
          expression: t.name, 
          mode: ascending ? OrderingMode.asc : OrderingMode.desc
        )]);
        break;
      case 'usageCount':
        query = query..orderBy([(t) => OrderingTerm(
          expression: t.usageCount, 
          mode: ascending ? OrderingMode.asc : OrderingMode.desc
        )]);
        break;
      case 'createdAt':
        query = query..orderBy([(t) => OrderingTerm(
          expression: t.createdAt, 
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

  // Count total tags
  Future<int> countTags() {
    final query = selectOnly(tagsTable)..addColumns([tagsTable.id.count()]);
    return query.map((row) => row.read(tagsTable.id.count()) ?? 0).getSingle();
  }

  // Count tags with usage
  Future<int> countUsedTags() {
    final query = selectOnly(tagsTable)
      ..where(tagsTable.usageCount.isBiggerThanValue(0))
      ..addColumns([tagsTable.id.count()]);
    return query.map((row) => row.read(tagsTable.id.count()) ?? 0).getSingle();
  }

  // Get total usage count across all tags
  Future<int> getTotalUsageCount() {
    final query = selectOnly(tagsTable)..addColumns([tagsTable.usageCount.sum()]);
    return query.map((row) => row.read(tagsTable.usageCount.sum()) ?? 0).getSingle();
  }

  // Get tags by name list
  Future<List<TagData>> getTagsByNames(List<String> names) {
    return (select(tagsTable)
          ..where((t) => t.name.isIn(names))
          ..orderBy([(t) => OrderingTerm(expression: t.name, mode: OrderingMode.asc)]))
        .get();
  }

  // Create tag if not exists
  Future<TagData> createTagIfNotExists(String name, {
    String? color,
    String? icon,
    String? description,
  }) async {
    // Check if tag exists
    TagData? existingTag = await getTagByName(name);
    if (existingTag != null) {
      return existingTag;
    }
    
    // Create new tag
    final tagId = 'tag_${DateTime.now().millisecondsSinceEpoch}';
    final companion = TagsTableCompanion(
      tagId: Value(tagId),
      name: Value(name),
      color: Value.absentIfNull(color),
      icon: Value.absentIfNull(icon),
      description: Value.absentIfNull(description),
      usageCount: const Value(0),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    );
    
    await saveTag(companion);
    return (await getTagById(tagId))!;
  }

  // Bulk increment usage for multiple tags
  Future<void> bulkIncrementUsage(List<String> tagIds) async {
    await batch((batch) {
      for (final tagId in tagIds) {
        batch.customStatement(
          'UPDATE tags SET usage_count = usage_count + 1, updated_at = ? WHERE tag_id = ?',
          [DateTime.now().millisecondsSinceEpoch, tagId]
        );
      }
    });
  }

  // Bulk decrement usage for multiple tags
  Future<void> bulkDecrementUsage(List<String> tagIds) async {
    await batch((batch) {
      for (final tagId in tagIds) {
        batch.customStatement(
          'UPDATE tags SET usage_count = MAX(0, usage_count - 1), updated_at = ? WHERE tag_id = ?',
          [DateTime.now().millisecondsSinceEpoch, tagId]
        );
      }
    });
  }

  // Clean up unused tags
  Future<int> deleteUnusedTags() {
    return (delete(tagsTable)..where((t) => t.usageCount.equals(0))).go();
  }

  // Clear all tags
  Future<int> clearAll() {
    return delete(tagsTable).go();
  }
}