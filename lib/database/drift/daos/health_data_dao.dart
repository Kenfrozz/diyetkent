import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/health_data_table.dart';

part 'health_data_dao.g.dart';

@DriftAccessor(tables: [HealthDataTable])
class HealthDataDao extends DatabaseAccessor<AppDatabase> with _$HealthDataDaoMixin {
  HealthDataDao(super.db);

  // Get all health data
  Future<List<HealthData>> getAllHealthData() {
    return (select(healthDataTable)
          ..orderBy([(t) => OrderingTerm(expression: t.recordDate, mode: OrderingMode.desc)]))
        .get();
  }

  // Watch all health data
  Stream<List<HealthData>> watchAllHealthData() {
    return (select(healthDataTable)
          ..orderBy([(t) => OrderingTerm(expression: t.recordDate, mode: OrderingMode.desc)]))
        .watch();
  }

  // Get health data by user ID
  Future<List<HealthData>> getHealthDataByUserId(String userId) {
    return (select(healthDataTable)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm(expression: t.recordDate, mode: OrderingMode.desc)]))
        .get();
  }

  // Watch health data by user ID
  Stream<List<HealthData>> watchHealthDataByUserId(String userId) {
    return (select(healthDataTable)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm(expression: t.recordDate, mode: OrderingMode.desc)]))
        .watch();
  }

  // Get health data by ID
  Future<HealthData?> getHealthDataById(int id) {
    return (select(healthDataTable)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  // Watch health data by ID
  Stream<HealthData?> watchHealthDataById(int id) {
    return (select(healthDataTable)..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  // Save or update health data (upsert by userId and recordDate)
  Future<int> saveHealthData(HealthDataTableCompanion healthData) {
    return into(healthDataTable).insertOnConflictUpdate(healthData);
  }

  // Batch save health data
  Future<void> saveHealthDataList(List<HealthDataTableCompanion> healthDataList) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(healthDataTable, healthDataList);
    });
  }

  // Update health data
  Future<bool> updateHealthData(HealthDataTableCompanion healthData) {
    return update(healthDataTable).replace(healthData);
  }

  // Delete health data
  Future<int> deleteHealthData(int id) {
    return (delete(healthDataTable)..where((t) => t.id.equals(id))).go();
  }

  // Get latest health data for user
  Future<HealthData?> getLatestHealthDataForUser(String userId) {
    return (select(healthDataTable)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm(expression: t.recordDate, mode: OrderingMode.desc)])
          ..limit(1))
        .getSingleOrNull();
  }

  // Watch latest health data for user
  Stream<HealthData?> watchLatestHealthDataForUser(String userId) {
    return (select(healthDataTable)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm(expression: t.recordDate, mode: OrderingMode.desc)])
          ..limit(1))
        .watchSingleOrNull();
  }

  // Get health data for specific date
  Future<HealthData?> getHealthDataForDate(String userId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return (select(healthDataTable)
          ..where((t) => t.userId.equals(userId) & 
                        t.recordDate.isBetweenValues(startOfDay, endOfDay))
          ..orderBy([(t) => OrderingTerm(expression: t.recordDate, mode: OrderingMode.desc)])
          ..limit(1))
        .getSingleOrNull();
  }

  // Get health data in date range
  Future<List<HealthData>> getHealthDataInDateRange(
    String userId, 
    DateTime from, 
    DateTime to,
  ) {
    return (select(healthDataTable)
          ..where((t) => t.userId.equals(userId) & 
                        t.recordDate.isBetweenValues(from, to))
          ..orderBy([(t) => OrderingTerm(expression: t.recordDate, mode: OrderingMode.desc)]))
        .get();
  }

  // Watch health data in date range
  Stream<List<HealthData>> watchHealthDataInDateRange(
    String userId, 
    DateTime from, 
    DateTime to,
  ) {
    return (select(healthDataTable)
          ..where((t) => t.userId.equals(userId) & 
                        t.recordDate.isBetweenValues(from, to))
          ..orderBy([(t) => OrderingTerm(expression: t.recordDate, mode: OrderingMode.desc)]))
        .watch();
  }

  // Update weight and BMI
  Future<int> updateWeightAndBMI(int id, double weight, double height) {
    final bmi = height > 0 ? weight / ((height / 100) * (height / 100)) : null;
    
    return (update(healthDataTable)..where((t) => t.id.equals(id)))
        .write(HealthDataTableCompanion(
      weight: Value(weight),
      height: Value(height),
      bmi: Value.absentIfNull(bmi),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update step count
  Future<int> updateStepCount(int id, int stepCount) {
    return (update(healthDataTable)..where((t) => t.id.equals(id)))
        .write(HealthDataTableCompanion(
      stepCount: Value(stepCount),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update body composition
  Future<int> updateBodyComposition({
    required int id,
    double? bodyFat,
    double? muscleMass,
    double? waterPercentage,
  }) {
    return (update(healthDataTable)..where((t) => t.id.equals(id)))
        .write(HealthDataTableCompanion(
      bodyFat: Value.absentIfNull(bodyFat),
      muscleMass: Value.absentIfNull(muscleMass),
      waterPercentage: Value.absentIfNull(waterPercentage),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update notes
  Future<int> updateNotes(int id, String notes) {
    return (update(healthDataTable)..where((t) => t.id.equals(id)))
        .write(HealthDataTableCompanion(
      notes: Value(notes),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Get weight history for user
  Future<List<HealthData>> getWeightHistory(String userId, {int? limit}) {
    var query = select(healthDataTable)
      ..where((t) => t.userId.equals(userId) & t.weight.isNotNull())
      ..orderBy([(t) => OrderingTerm(expression: t.recordDate, mode: OrderingMode.desc)]);
    
    if (limit != null) {
      query = query..limit(limit);
    }
    
    return query.get();
  }

  // Get BMI history for user
  Future<List<HealthData>> getBMIHistory(String userId, {int? limit}) {
    var query = select(healthDataTable)
      ..where((t) => t.userId.equals(userId) & t.bmi.isNotNull())
      ..orderBy([(t) => OrderingTerm(expression: t.recordDate, mode: OrderingMode.desc)]);
    
    if (limit != null) {
      query = query..limit(limit);
    }
    
    return query.get();
  }

  // Get step count history for user
  Future<List<HealthData>> getStepCountHistory(String userId, {int? limit}) {
    var query = select(healthDataTable)
      ..where((t) => t.userId.equals(userId) & t.stepCount.isNotNull())
      ..orderBy([(t) => OrderingTerm(expression: t.recordDate, mode: OrderingMode.desc)]);
    
    if (limit != null) {
      query = query..limit(limit);
    }
    
    return query.get();
  }

  // Get recent health data (last N days)
  Future<List<HealthData>> getRecentHealthData(String userId, {int days = 30}) {
    final since = DateTime.now().subtract(Duration(days: days));
    
    return (select(healthDataTable)
          ..where((t) => t.userId.equals(userId) & 
                        t.recordDate.isBiggerOrEqualValue(since))
          ..orderBy([(t) => OrderingTerm(expression: t.recordDate, mode: OrderingMode.desc)]))
        .get();
  }

  // Watch recent health data
  Stream<List<HealthData>> watchRecentHealthData(String userId, {int days = 30}) {
    final since = DateTime.now().subtract(Duration(days: days));
    
    return (select(healthDataTable)
          ..where((t) => t.userId.equals(userId) & 
                        t.recordDate.isBiggerOrEqualValue(since))
          ..orderBy([(t) => OrderingTerm(expression: t.recordDate, mode: OrderingMode.desc)]))
        .watch();
  }

  // Get health data with pagination
  Future<List<HealthData>> getHealthDataPaginated({
    String? userId,
    required int limit,
    int? offset,
    String? orderBy = 'recordDate',
    bool ascending = false,
  }) {
    var query = select(healthDataTable);
    
    // Add filter
    if (userId != null) {
      query = query..where((t) => t.userId.equals(userId));
    }
    
    // Add ordering
    switch (orderBy) {
      case 'recordDate':
        query = query..orderBy([(t) => OrderingTerm(
          expression: t.recordDate, 
          mode: ascending ? OrderingMode.asc : OrderingMode.desc
        )]);
        break;
      case 'weight':
        query = query..orderBy([(t) => OrderingTerm(
          expression: t.weight, 
          mode: ascending ? OrderingMode.asc : OrderingMode.desc
        )]);
        break;
      case 'bmi':
        query = query..orderBy([(t) => OrderingTerm(
          expression: t.bmi, 
          mode: ascending ? OrderingMode.asc : OrderingMode.desc
        )]);
        break;
      case 'stepCount':
        query = query..orderBy([(t) => OrderingTerm(
          expression: t.stepCount, 
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

  // Count health data entries
  Future<int> countHealthData({String? userId}) {
    var query = selectOnly(healthDataTable);
    
    if (userId != null) {
      query = query..where(healthDataTable.userId.equals(userId));
    }
    
    query = query..addColumns([healthDataTable.id.count()]);
    return query.map((row) => row.read(healthDataTable.id.count()) ?? 0).getSingle();
  }

  // Get health statistics for user
  Future<Map<String, dynamic>> getHealthStatistics(String userId) async {
    final healthData = await getHealthDataByUserId(userId);
    
    if (healthData.isEmpty) {
      return {};
    }
    
    // Weight statistics
    final weightsData = healthData.where((data) => data.weight != null);
    final weights = weightsData.map((data) => data.weight!).toList();
    
    // BMI statistics
    final bmisData = healthData.where((data) => data.bmi != null);
    final bmis = bmisData.map((data) => data.bmi!).toList();
    
    // Step count statistics
    final stepsData = healthData.where((data) => data.stepCount != null);
    final stepCounts = stepsData.map((data) => data.stepCount!).toList();
    
    return {
      'totalEntries': healthData.length,
      'weight': weights.isNotEmpty ? {
        'current': weights.first,
        'min': weights.reduce((a, b) => a < b ? a : b),
        'max': weights.reduce((a, b) => a > b ? a : b),
        'average': weights.reduce((a, b) => a + b) / weights.length,
        'trend': weights.length > 1 ? weights.first - weights.last : 0.0,
      } : null,
      'bmi': bmis.isNotEmpty ? {
        'current': bmis.first,
        'min': bmis.reduce((a, b) => a < b ? a : b),
        'max': bmis.reduce((a, b) => a > b ? a : b),
        'average': bmis.reduce((a, b) => a + b) / bmis.length,
      } : null,
      'stepCount': stepCounts.isNotEmpty ? {
        'total': stepCounts.reduce((a, b) => a + b),
        'average': stepCounts.reduce((a, b) => a + b) / stepCounts.length,
        'max': stepCounts.reduce((a, b) => a > b ? a : b),
      } : null,
    };
  }

  // Get average weight in date range
  Future<double?> getAverageWeight(String userId, DateTime from, DateTime to) async {
    final healthData = await getHealthDataInDateRange(userId, from, to);
    final weights = healthData.where((data) => data.weight != null).map((data) => data.weight!);
    
    if (weights.isEmpty) return null;
    
    return weights.reduce((a, b) => a + b) / weights.length;
  }

  // Get weight change between two dates
  Future<double?> getWeightChange(String userId, DateTime from, DateTime to) async {
    final startData = await getHealthDataForDate(userId, from);
    final endData = await getHealthDataForDate(userId, to);
    
    if (startData?.weight != null && endData?.weight != null) {
      return endData!.weight! - startData!.weight!;
    }
    
    return null;
  }

  // Delete old health data
  Future<int> deleteOldHealthData({String? userId, Duration? olderThan}) {
    final thresholdTime = olderThan != null 
        ? DateTime.now().subtract(olderThan)
        : DateTime.now().subtract(const Duration(days: 365));
    
    var query = delete(healthDataTable)
      ..where((t) => t.recordDate.isSmallerThanValue(thresholdTime));
    
    if (userId != null) {
      query = query..where((t) => t.userId.equals(userId));
    }
    
    return query.go();
  }

  // Delete health data for user
  Future<int> deleteHealthDataForUser(String userId) {
    return (delete(healthDataTable)..where((t) => t.userId.equals(userId))).go();
  }

  // Clear all health data
  Future<int> clearAll() {
    return delete(healthDataTable).go();
  }
}