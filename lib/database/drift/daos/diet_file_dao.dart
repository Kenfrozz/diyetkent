import 'dart:convert';
import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/diet_files_table.dart';

part 'diet_file_dao.g.dart';

@DriftAccessor(tables: [DietFilesTable])
class DietFileDao extends DatabaseAccessor<AppDatabase> with _$DietFileDaoMixin {
  DietFileDao(super.db);

  // Get all diet files
  Future<List<DietFileData>> getAllDietFiles() {
    return (select(dietFilesTable)
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Watch all diet files
  Stream<List<DietFileData>> watchAllDietFiles() {
    return (select(dietFilesTable)
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .watch();
  }

  // Get diet file by ID
  Future<DietFileData?> getDietFileById(String fileId) {
    return (select(dietFilesTable)..where((t) => t.fileId.equals(fileId))).getSingleOrNull();
  }

  // Watch diet file by ID
  Stream<DietFileData?> watchDietFileById(String fileId) {
    return (select(dietFilesTable)..where((t) => t.fileId.equals(fileId))).watchSingleOrNull();
  }

  // Get diet files by user ID
  Future<List<DietFileData>> getDietFilesByUserId(String userId) {
    return (select(dietFilesTable)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Watch diet files by user ID
  Stream<List<DietFileData>> watchDietFilesByUserId(String userId) {
    return (select(dietFilesTable)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .watch();
  }

  // Get active diet files by user ID
  Future<List<DietFileData>> getActiveDietFilesByUserId(String userId) {
    return (select(dietFilesTable)
          ..where((t) => t.userId.equals(userId) & t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Watch active diet files by user ID
  Stream<List<DietFileData>> watchActiveDietFilesByUserId(String userId) {
    return (select(dietFilesTable)
          ..where((t) => t.userId.equals(userId) & t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .watch();
  }

  // Get diet files by dietitian ID
  Future<List<DietFileData>> getDietFilesByDietitianId(String dietitianId) {
    return (select(dietFilesTable)
          ..where((t) => t.dietitianId.equals(dietitianId))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Watch diet files by dietitian ID
  Stream<List<DietFileData>> watchDietFilesByDietitianId(String dietitianId) {
    return (select(dietFilesTable)
          ..where((t) => t.dietitianId.equals(dietitianId))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .watch();
  }

  // Save or update diet file (upsert)
  Future<int> saveDietFile(DietFilesTableCompanion dietFile) {
    return into(dietFilesTable).insertOnConflictUpdate(dietFile);
  }

  // Batch save diet files
  Future<void> saveDietFiles(List<DietFilesTableCompanion> dietFileList) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(dietFilesTable, dietFileList);
    });
  }

  // Update diet file
  Future<bool> updateDietFile(DietFilesTableCompanion dietFile) {
    return update(dietFilesTable).replace(dietFile);
  }

  // Delete diet file
  Future<int> deleteDietFile(String fileId) {
    return (delete(dietFilesTable)..where((t) => t.fileId.equals(fileId))).go();
  }

  // Update diet file basic info
  Future<int> updateDietFileInfo({
    required String fileId,
    String? title,
    String? description,
    String? dietitianNotes,
  }) {
    return (update(dietFilesTable)..where((t) => t.fileId.equals(fileId)))
        .write(DietFilesTableCompanion(
      title: Value.absentIfNull(title),
      description: Value.absentIfNull(description),
      dietitianNotes: Value.absentIfNull(dietitianNotes),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update diet file URL and metadata
  Future<int> updateDietFileUrl({
    required String fileId,
    String? fileUrl,
    String? fileName,
    String? fileType,
    int? fileSizeBytes,
  }) {
    return (update(dietFilesTable)..where((t) => t.fileId.equals(fileId)))
        .write(DietFilesTableCompanion(
      fileUrl: Value.absentIfNull(fileUrl),
      fileName: Value.absentIfNull(fileName),
      fileType: Value.absentIfNull(fileType),
      fileSizeBytes: Value.absentIfNull(fileSizeBytes),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update diet plan details
  Future<int> updateDietPlanDetails({
    required String fileId,
    String? mealPlan,
    String? restrictions,
    String? recommendations,
    String? targetWeight,
    String? duration,
  }) {
    return (update(dietFilesTable)..where((t) => t.fileId.equals(fileId)))
        .write(DietFilesTableCompanion(
      mealPlan: Value.absentIfNull(mealPlan),
      restrictions: Value.absentIfNull(restrictions),
      recommendations: Value.absentIfNull(recommendations),
      targetWeight: Value.absentIfNull(targetWeight),
      duration: Value.absentIfNull(duration),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Mark diet file as read
  Future<int> markDietFileAsRead(String fileId) {
    return (update(dietFilesTable)..where((t) => t.fileId.equals(fileId)))
        .write(DietFilesTableCompanion(
      isRead: const Value(true),
      readAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Mark diet file as unread
  Future<int> markDietFileAsUnread(String fileId) {
    return (update(dietFilesTable)..where((t) => t.fileId.equals(fileId)))
        .write(DietFilesTableCompanion(
      isRead: const Value(false),
      readAt: const Value(null),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Activate/deactivate diet file
  Future<int> updateDietFileActiveStatus(String fileId, bool isActive) {
    return (update(dietFilesTable)..where((t) => t.fileId.equals(fileId)))
        .write(DietFilesTableCompanion(
      isActive: Value(isActive),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Add tags to diet file
  Future<int> addTagsToDietFile(String fileId, List<String> newTags) async {
    final dietFile = await getDietFileById(fileId);
    if (dietFile != null) {
      final existingTags = (jsonDecode(dietFile.tags) as List).cast<String>();
      final updatedTags = {...existingTags, ...newTags}.toList();
      
      return (update(dietFilesTable)..where((t) => t.fileId.equals(fileId)))
          .write(DietFilesTableCompanion(
        tags: Value(jsonEncode(updatedTags)),
        updatedAt: Value(DateTime.now()),
      ));
    }
    return 0;
  }

  // Remove tags from diet file
  Future<int> removeTagsFromDietFile(String fileId, List<String> tagsToRemove) async {
    final dietFile = await getDietFileById(fileId);
    if (dietFile != null) {
      final existingTags = (jsonDecode(dietFile.tags) as List).cast<String>();
      final updatedTags = existingTags.where((tag) => !tagsToRemove.contains(tag)).toList();
      
      return (update(dietFilesTable)..where((t) => t.fileId.equals(fileId)))
          .write(DietFilesTableCompanion(
        tags: Value(jsonEncode(updatedTags)),
        updatedAt: Value(DateTime.now()),
      ));
    }
    return 0;
  }

  // Get unread diet files by user ID
  Future<List<DietFileData>> getUnreadDietFilesByUserId(String userId) {
    return (select(dietFilesTable)
          ..where((t) => t.userId.equals(userId) & 
                        t.isRead.equals(false) & 
                        t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Watch unread diet files by user ID
  Stream<List<DietFileData>> watchUnreadDietFilesByUserId(String userId) {
    return (select(dietFilesTable)
          ..where((t) => t.userId.equals(userId) & 
                        t.isRead.equals(false) & 
                        t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .watch();
  }

  // Get diet files by file type
  Future<List<DietFileData>> getDietFilesByFileType(String fileType) {
    return (select(dietFilesTable)
          ..where((t) => t.fileType.equals(fileType))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Get diet files by tags
  Future<List<DietFileData>> getDietFilesByTags(List<String> tags) async {
    final allFiles = await getAllDietFiles();
    return allFiles.where((file) {
      final fileTags = (jsonDecode(file.tags) as List).cast<String>();
      return tags.any((tag) => fileTags.contains(tag));
    }).toList();
  }

  // Search diet files
  Future<List<DietFileData>> searchDietFiles(String query) {
    final lowerQuery = query.toLowerCase();
    return (select(dietFilesTable)
          ..where((t) => t.title.lower().contains(lowerQuery) |
              t.description.lower().contains(lowerQuery) |
              t.dietitianNotes.lower().contains(lowerQuery) |
              t.fileName.lower().contains(lowerQuery)))
        .get();
  }

  // Search diet files for user
  Future<List<DietFileData>> searchDietFilesForUser(String userId, String query) {
    final lowerQuery = query.toLowerCase();
    return (select(dietFilesTable)
          ..where((t) => t.userId.equals(userId) & 
                        (t.title.lower().contains(lowerQuery) |
                         t.description.lower().contains(lowerQuery) |
                         t.dietitianNotes.lower().contains(lowerQuery))))
        .get();
  }

  // Get diet files in date range
  Future<List<DietFileData>> getDietFilesInDateRange(DateTime from, DateTime to) {
    return (select(dietFilesTable)
          ..where((t) => t.createdAt.isBetweenValues(from, to))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Get recent diet files (last N days)
  Future<List<DietFileData>> getRecentDietFiles({int days = 7}) {
    final since = DateTime.now().subtract(Duration(days: days));
    
    return (select(dietFilesTable)
          ..where((t) => t.createdAt.isBiggerOrEqualValue(since))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Get recent diet files for user
  Future<List<DietFileData>> getRecentDietFilesForUser(String userId, {int days = 7}) {
    final since = DateTime.now().subtract(Duration(days: days));
    
    return (select(dietFilesTable)
          ..where((t) => t.userId.equals(userId) & 
                        t.createdAt.isBiggerOrEqualValue(since))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Get diet files with pagination
  Future<List<DietFileData>> getDietFilesPaginated({
    String? userId,
    String? dietitianId,
    bool? isActive,
    bool? isRead,
    required int limit,
    int? offset,
    String? orderBy = 'createdAt',
    bool ascending = false,
  }) {
    var query = select(dietFilesTable);
    
    // Add filters
    if (userId != null) {
      query = query..where((t) => t.userId.equals(userId));
    }
    
    if (dietitianId != null) {
      query = query..where((t) => t.dietitianId.equals(dietitianId));
    }
    
    if (isActive != null) {
      query = query..where((t) => t.isActive.equals(isActive));
    }
    
    if (isRead != null) {
      query = query..where((t) => t.isRead.equals(isRead));
    }
    
    // Add ordering
    switch (orderBy) {
      case 'createdAt':
        query = query..orderBy([(t) => OrderingTerm(
          expression: t.createdAt, 
          mode: ascending ? OrderingMode.asc : OrderingMode.desc
        )]);
        break;
      case 'title':
        query = query..orderBy([(t) => OrderingTerm(
          expression: t.title, 
          mode: ascending ? OrderingMode.asc : OrderingMode.desc
        )]);
        break;
      case 'readAt':
        query = query..orderBy([(t) => OrderingTerm(
          expression: t.readAt, 
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

  // Count diet files
  Future<int> countDietFiles({
    String? userId,
    String? dietitianId,
    bool? isActive,
    bool? isRead,
  }) {
    var query = selectOnly(dietFilesTable);
    
    if (userId != null) {
      query = query..where(dietFilesTable.userId.equals(userId));
    }
    
    if (dietitianId != null) {
      query = query..where(dietFilesTable.dietitianId.equals(dietitianId));
    }
    
    if (isActive != null) {
      query = query..where(dietFilesTable.isActive.equals(isActive));
    }
    
    if (isRead != null) {
      query = query..where(dietFilesTable.isRead.equals(isRead));
    }
    
    query = query..addColumns([dietFilesTable.id.count()]);
    return query.map((row) => row.read(dietFilesTable.id.count()) ?? 0).getSingle();
  }

  // Count unread diet files for user
  Future<int> countUnreadDietFilesForUser(String userId) {
    final query = selectOnly(dietFilesTable)
      ..where(dietFilesTable.userId.equals(userId) & 
              dietFilesTable.isRead.equals(false) &
              dietFilesTable.isActive.equals(true))
      ..addColumns([dietFilesTable.id.count()]);
    return query.map((row) => row.read(dietFilesTable.id.count()) ?? 0).getSingle();
  }

  // Get diet file statistics for dietitian
  Future<Map<String, int>> getDietitianStatistics(String dietitianId) async {
    final totalFiles = await countDietFiles(dietitianId: dietitianId);
    final activeFiles = await countDietFiles(dietitianId: dietitianId, isActive: true);
    final readFiles = await countDietFiles(dietitianId: dietitianId, isRead: true);
    final unreadFiles = await countDietFiles(dietitianId: dietitianId, isRead: false);
    
    return {
      'total': totalFiles,
      'active': activeFiles,
      'read': readFiles,
      'unread': unreadFiles,
    };
  }

  // Get diet file statistics for user
  Future<Map<String, int>> getUserStatistics(String userId) async {
    final totalFiles = await countDietFiles(userId: userId);
    final activeFiles = await countDietFiles(userId: userId, isActive: true);
    final readFiles = await countDietFiles(userId: userId, isRead: true);
    final unreadFiles = await countDietFiles(userId: userId, isRead: false);
    
    return {
      'total': totalFiles,
      'active': activeFiles,
      'read': readFiles,
      'unread': unreadFiles,
    };
  }

  // Bulk mark as read
  Future<void> bulkMarkAsRead(List<String> fileIds) async {
    final now = DateTime.now();
    await batch((batch) {
      for (final fileId in fileIds) {
        batch.update(
          dietFilesTable,
          DietFilesTableCompanion(
            isRead: const Value(true),
            readAt: Value(now),
            updatedAt: Value(now),
          ),
          where: (t) => t.fileId.equals(fileId),
        );
      }
    });
  }

  // Delete diet files for user
  Future<int> deleteDietFilesForUser(String userId) {
    return (delete(dietFilesTable)..where((t) => t.userId.equals(userId))).go();
  }

  // Delete diet files by dietitian
  Future<int> deleteDietFilesByDietitian(String dietitianId) {
    return (delete(dietFilesTable)..where((t) => t.dietitianId.equals(dietitianId))).go();
  }

  // Clear old diet files
  Future<int> clearOldDietFiles({Duration? olderThan}) {
    final thresholdTime = olderThan != null 
        ? DateTime.now().subtract(olderThan)
        : DateTime.now().subtract(const Duration(days: 365));
        
    return (delete(dietFilesTable)
          ..where((t) => t.createdAt.isSmallerThanValue(thresholdTime) & 
                        t.isActive.equals(false)))
        .go();
  }

  // Clear all diet files
  Future<int> clearAll() {
    return delete(dietFilesTable).go();
  }
}