import 'dart:convert';
import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/stories_table.dart';

part 'story_dao.g.dart';

@DriftAccessor(tables: [StoriesTable])
class StoryDao extends DatabaseAccessor<AppDatabase> with _$StoryDaoMixin {
  StoryDao(super.db);

  // Get all stories
  Future<List<StoryData>> getAllStories() {
    return (select(storiesTable)
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Get all active stories
  Future<List<StoryData>> getAllActiveStories() {
    return (select(storiesTable)
          ..where((t) => t.isActive.equals(true) & t.expiresAt.isBiggerThanValue(DateTime.now()))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Watch all active stories
  Stream<List<StoryData>> watchActiveStories() {
    return (select(storiesTable)
          ..where((t) => t.isActive.equals(true) & t.expiresAt.isBiggerThanValue(DateTime.now()))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .watch();
  }

  // Get story by ID
  Future<StoryData?> getStoryById(String storyId) {
    return (select(storiesTable)..where((t) => t.storyId.equals(storyId))).getSingleOrNull();
  }

  // Watch story by ID
  Stream<StoryData?> watchStoryById(String storyId) {
    return (select(storiesTable)..where((t) => t.storyId.equals(storyId))).watchSingleOrNull();
  }

  // Get stories by user ID
  Future<List<StoryData>> getStoriesByUserId(String userId) {
    return (select(storiesTable)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Watch stories by user ID
  Stream<List<StoryData>> watchStoriesByUserId(String userId) {
    return (select(storiesTable)
          ..where((t) => t.userId.equals(userId) & t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .watch();
  }

  // Get active stories by user ID
  Future<List<StoryData>> getActiveStoriesByUserId(String userId) {
    return (select(storiesTable)
          ..where((t) => t.userId.equals(userId) & 
                        t.isActive.equals(true) & 
                        t.expiresAt.isBiggerThanValue(DateTime.now()))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Get current user stories
  Stream<List<StoryData>> watchCurrentUserStories() {
    return (select(storiesTable)
          ..where((t) => t.isFromCurrentUser.equals(true) & t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .watch();
  }

  // Save or update story (upsert)
  Future<int> saveStory(StoriesTableCompanion story) {
    return into(storiesTable).insertOnConflictUpdate(story);
  }

  // Batch save stories
  Future<void> saveStories(List<StoriesTableCompanion> storyList) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(storiesTable, storyList);
    });
  }

  // Update story
  Future<bool> updateStory(StoriesTableCompanion story) {
    return update(storiesTable).replace(story);
  }

  // Delete story
  Future<int> deleteStory(String storyId) {
    return (delete(storiesTable)..where((t) => t.storyId.equals(storyId))).go();
  }

  // Mark story as viewed
  Future<int> markStoryAsViewed(String storyId, String viewerId) async {
    final story = await getStoryById(storyId);
    if (story != null) {
      final viewerIds = (jsonDecode(story.viewerIds) as List).cast<String>();
      if (!viewerIds.contains(viewerId)) {
        viewerIds.add(viewerId);
        return (update(storiesTable)..where((t) => t.storyId.equals(storyId)))
            .write(StoriesTableCompanion(
          isViewed: const Value(true),
          viewerIds: Value(jsonEncode(viewerIds)),
          viewCount: Value(story.viewCount + 1),
          lastViewedAt: Value(DateTime.now()),
        ));
      }
    }
    return 0;
  }

  // Add story reply
  Future<int> addStoryReply(String storyId, String replierId) async {
    final story = await getStoryById(storyId);
    if (story != null) {
      final repliedUserIds = (jsonDecode(story.repliedUserIds) as List).cast<String>();
      if (!repliedUserIds.contains(replierId)) {
        repliedUserIds.add(replierId);
        return (update(storiesTable)..where((t) => t.storyId.equals(storyId)))
            .write(StoriesTableCompanion(
          repliedUserIds: Value(jsonEncode(repliedUserIds)),
        ));
      }
    }
    return 0;
  }

  // Update story media local path
  Future<int> updateStoryMediaLocalPath(String storyId, String localPath) {
    return (update(storiesTable)..where((t) => t.storyId.equals(storyId)))
        .write(StoriesTableCompanion(
      mediaLocalPath: Value(localPath),
    ));
  }

  // Deactivate story
  Future<int> deactivateStory(String storyId) {
    return (update(storiesTable)..where((t) => t.storyId.equals(storyId)))
        .write(const StoriesTableCompanion(
      isActive: Value(false),
    ));
  }

  // Get stories by type
  Future<List<StoryData>> getStoriesByType(String type) {
    return (select(storiesTable)
          ..where((t) => t.type.equals(type) & t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Get viewed stories
  Future<List<StoryData>> getViewedStories() {
    return (select(storiesTable)
          ..where((t) => t.isViewed.equals(true))
          ..orderBy([(t) => OrderingTerm(expression: t.lastViewedAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Get unviewed stories
  Future<List<StoryData>> getUnviewedStories() {
    return (select(storiesTable)
          ..where((t) => t.isViewed.equals(false) & 
                        t.isActive.equals(true) & 
                        t.expiresAt.isBiggerThanValue(DateTime.now()))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Get expired stories
  Future<List<StoryData>> getExpiredStories() {
    return (select(storiesTable)
          ..where((t) => t.expiresAt.isSmallerThanValue(DateTime.now()))
          ..orderBy([(t) => OrderingTerm(expression: t.expiresAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Clean up expired stories
  Future<int> cleanupExpiredStories() {
    return (update(storiesTable)
          ..where((t) => t.expiresAt.isSmallerThanValue(DateTime.now())))
        .write(const StoriesTableCompanion(
      isActive: Value(false),
    ));
  }

  // Delete expired stories
  Future<int> deleteExpiredStories() {
    return (delete(storiesTable)
          ..where((t) => t.expiresAt.isSmallerThanValue(DateTime.now())))
        .go();
  }

  // Get stories with high view count
  Future<List<StoryData>> getPopularStories({int minViews = 10}) {
    return (select(storiesTable)
          ..where((t) => t.viewCount.isBiggerOrEqualValue(minViews) & t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm(expression: t.viewCount, mode: OrderingMode.desc)]))
        .get();
  }

  // Get stories in date range
  Future<List<StoryData>> getStoriesInDateRange(DateTime from, DateTime to) {
    return (select(storiesTable)
          ..where((t) => t.createdAt.isBetweenValues(from, to))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Search stories by content
  Future<List<StoryData>> searchStories(String query) {
    final lowerQuery = query.toLowerCase();
    return (select(storiesTable)
          ..where((t) => t.content.lower().contains(lowerQuery) |
              t.userName.lower().contains(lowerQuery)))
        .get();
  }

  // Get stories with pagination
  Future<List<StoryData>> getStoriesPaginated({
    required int limit,
    int? offset,
    String? userId,
    String? type,
    bool activeOnly = true,
    String? orderBy = 'createdAt',
    bool ascending = false,
  }) {
    var query = select(storiesTable);
    
    // Add filters
    if (userId != null) {
      query = query..where((t) => t.userId.equals(userId));
    }
    
    if (type != null) {
      query = query..where((t) => t.type.equals(type));
    }
    
    if (activeOnly) {
      query = query..where((t) => t.isActive.equals(true) & 
                                  t.expiresAt.isBiggerThanValue(DateTime.now()));
    }
    
    // Add ordering
    switch (orderBy) {
      case 'createdAt':
        query = query..orderBy([(t) => OrderingTerm(
          expression: t.createdAt, 
          mode: ascending ? OrderingMode.asc : OrderingMode.desc
        )]);
        break;
      case 'viewCount':
        query = query..orderBy([(t) => OrderingTerm(
          expression: t.viewCount, 
          mode: ascending ? OrderingMode.asc : OrderingMode.desc
        )]);
        break;
      case 'expiresAt':
        query = query..orderBy([(t) => OrderingTerm(
          expression: t.expiresAt, 
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

  // Count stories
  Future<int> countStories({String? userId, bool activeOnly = false}) {
    var query = selectOnly(storiesTable);
    
    if (userId != null) {
      query = query..where(storiesTable.userId.equals(userId));
    }
    
    if (activeOnly) {
      query = query..where(storiesTable.isActive.equals(true) & 
                          storiesTable.expiresAt.isBiggerThanValue(DateTime.now()));
    }
    
    query = query..addColumns([storiesTable.id.count()]);
    return query.map((row) => row.read(storiesTable.id.count()) ?? 0).getSingle();
  }

  // Count story views
  Future<int> getTotalStoryViews({String? userId}) {
    var query = selectOnly(storiesTable);
    
    if (userId != null) {
      query = query..where(storiesTable.userId.equals(userId));
    }
    
    query = query..addColumns([storiesTable.viewCount.sum()]);
    return query.map((row) => row.read(storiesTable.viewCount.sum()) ?? 0).getSingle();
  }

  // Get users who viewed story
  Future<List<String>> getStoryViewers(String storyId) async {
    final story = await getStoryById(storyId);
    if (story != null) {
      return (jsonDecode(story.viewerIds) as List).cast<String>();
    }
    return [];
  }

  // Get users who replied to story
  Future<List<String>> getStoryRepliers(String storyId) async {
    final story = await getStoryById(storyId);
    if (story != null) {
      return (jsonDecode(story.repliedUserIds) as List).cast<String>();
    }
    return [];
  }

  // Clear all stories
  Future<int> clearAll() {
    return delete(storiesTable).go();
  }
}