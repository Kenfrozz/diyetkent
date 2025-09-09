import 'dart:convert';
import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/diet_packages_table.dart';

part 'diet_package_dao.g.dart';

@DriftAccessor(tables: [DietPackagesTable])
class DietPackageDao extends DatabaseAccessor<AppDatabase> with _$DietPackageDaoMixin {
  DietPackageDao(super.db);

  // Get all diet packages
  Future<List<DietPackageData>> getAllDietPackages() {
    return (select(dietPackagesTable)
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Watch all diet packages
  Stream<List<DietPackageData>> watchAllDietPackages() {
    return (select(dietPackagesTable)
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .watch();
  }

  // Get diet package by ID
  Future<DietPackageData?> getDietPackageById(String packageId) {
    return (select(dietPackagesTable)..where((t) => t.packageId.equals(packageId))).getSingleOrNull();
  }

  // Watch diet package by ID
  Stream<DietPackageData?> watchDietPackageById(String packageId) {
    return (select(dietPackagesTable)..where((t) => t.packageId.equals(packageId))).watchSingleOrNull();
  }

  // Get diet packages by dietitian ID
  Future<List<DietPackageData>> getDietPackagesByDietitianId(String dietitianId) {
    return (select(dietPackagesTable)
          ..where((t) => t.dietitianId.equals(dietitianId))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Watch diet packages by dietitian ID
  Stream<List<DietPackageData>> watchDietPackagesByDietitianId(String dietitianId) {
    return (select(dietPackagesTable)
          ..where((t) => t.dietitianId.equals(dietitianId))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .watch();
  }

  // Get active diet packages
  Future<List<DietPackageData>> getActiveDietPackages() {
    return (select(dietPackagesTable)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Watch active diet packages
  Stream<List<DietPackageData>> watchActiveDietPackages() {
    return (select(dietPackagesTable)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .watch();
  }

  // Get public diet packages
  Future<List<DietPackageData>> getPublicDietPackages() {
    return (select(dietPackagesTable)
          ..where((t) => t.isPublic.equals(true) & t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm(expression: t.averageRating, mode: OrderingMode.desc)]))
        .get();
  }

  // Watch public diet packages
  Stream<List<DietPackageData>> watchPublicDietPackages() {
    return (select(dietPackagesTable)
          ..where((t) => t.isPublic.equals(true) & t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm(expression: t.averageRating, mode: OrderingMode.desc)]))
        .watch();
  }

  // Save or update diet package (upsert)
  Future<int> saveDietPackage(DietPackagesTableCompanion dietPackage) {
    return into(dietPackagesTable).insertOnConflictUpdate(dietPackage);
  }

  // Batch save diet packages
  Future<void> saveDietPackages(List<DietPackagesTableCompanion> dietPackageList) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(dietPackagesTable, dietPackageList);
    });
  }

  // Update diet package
  Future<bool> updateDietPackage(DietPackagesTableCompanion dietPackage) {
    return update(dietPackagesTable).replace(dietPackage);
  }

  // Delete diet package
  Future<int> deleteDietPackage(String packageId) {
    return (delete(dietPackagesTable)..where((t) => t.packageId.equals(packageId))).go();
  }

  // Update diet package basic info
  Future<int> updateDietPackageBasicInfo({
    required String packageId,
    String? title,
    String? description,
    String? imageUrl,
  }) {
    return (update(dietPackagesTable)..where((t) => t.packageId.equals(packageId)))
        .write(DietPackagesTableCompanion(
      title: Value.absentIfNull(title),
      description: Value.absentIfNull(description),
      imageUrl: Value.absentIfNull(imageUrl),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update diet package parameters
  Future<int> updateDietPackageParameters({
    required String packageId,
    String? type,
    int? durationDays,
    double? price,
    int? numberOfFiles,
    int? daysPerFile,
    double? targetWeightChangePerFile,
  }) {
    return (update(dietPackagesTable)..where((t) => t.packageId.equals(packageId)))
        .write(DietPackagesTableCompanion(
      type: Value.absentIfNull(type),
      durationDays: Value.absentIfNull(durationDays),
      price: Value.absentIfNull(price),
      numberOfFiles: Value.absentIfNull(numberOfFiles),
      daysPerFile: Value.absentIfNull(daysPerFile),
      targetWeightChangePerFile: Value.absentIfNull(targetWeightChangePerFile),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update nutrition targets (JSON)
  Future<int> updateNutritionTargets(String packageId, Map<String, dynamic> nutritionTargets) {
    return (update(dietPackagesTable)..where((t) => t.packageId.equals(packageId)))
        .write(DietPackagesTableCompanion(
      nutritionTargets: Value(jsonEncode(nutritionTargets)),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update meal plans (JSON)
  Future<int> updateMealPlans(String packageId, List<Map<String, dynamic>> mealPlans) {
    return (update(dietPackagesTable)..where((t) => t.packageId.equals(packageId)))
        .write(DietPackagesTableCompanion(
      mealPlans: Value(jsonEncode(mealPlans)),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update allowed/forbidden foods
  Future<int> updateFoodLists({
    required String packageId,
    List<String>? allowedFoods,
    List<String>? forbiddenFoods,
  }) {
    return (update(dietPackagesTable)..where((t) => t.packageId.equals(packageId)))
        .write(DietPackagesTableCompanion(
      allowedFoods: allowedFoods != null ? Value(jsonEncode(allowedFoods)) : const Value.absent(),
      forbiddenFoods: forbiddenFoods != null ? Value(jsonEncode(forbiddenFoods)) : const Value.absent(),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Add food to allowed list
  Future<int> addAllowedFood(String packageId, String food) async {
    final package = await getDietPackageById(packageId);
    if (package != null) {
      final allowedFoods = (jsonDecode(package.allowedFoods) as List).cast<String>();
      if (!allowedFoods.contains(food)) {
        allowedFoods.add(food);
        return updateFoodLists(packageId: packageId, allowedFoods: allowedFoods);
      }
    }
    return 0;
  }

  // Remove food from allowed list
  Future<int> removeAllowedFood(String packageId, String food) async {
    final package = await getDietPackageById(packageId);
    if (package != null) {
      final allowedFoods = (jsonDecode(package.allowedFoods) as List).cast<String>();
      allowedFoods.remove(food);
      return updateFoodLists(packageId: packageId, allowedFoods: allowedFoods);
    }
    return 0;
  }

  // Add food to forbidden list
  Future<int> addForbiddenFood(String packageId, String food) async {
    final package = await getDietPackageById(packageId);
    if (package != null) {
      final forbiddenFoods = (jsonDecode(package.forbiddenFoods) as List).cast<String>();
      if (!forbiddenFoods.contains(food)) {
        forbiddenFoods.add(food);
        return updateFoodLists(packageId: packageId, forbiddenFoods: forbiddenFoods);
      }
    }
    return 0;
  }

  // Remove food from forbidden list
  Future<int> removeForbiddenFood(String packageId, String food) async {
    final package = await getDietPackageById(packageId);
    if (package != null) {
      final forbiddenFoods = (jsonDecode(package.forbiddenFoods) as List).cast<String>();
      forbiddenFoods.remove(food);
      return updateFoodLists(packageId: packageId, forbiddenFoods: forbiddenFoods);
    }
    return 0;
  }

  // Update additional information
  Future<int> updateAdditionalInfo({
    required String packageId,
    String? exercisePlan,
    String? specialNotes,
  }) {
    return (update(dietPackagesTable)..where((t) => t.packageId.equals(packageId)))
        .write(DietPackagesTableCompanion(
      exercisePlan: Value.absentIfNull(exercisePlan),
      specialNotes: Value.absentIfNull(specialNotes),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update package status
  Future<int> updatePackageStatus({
    required String packageId,
    bool? isActive,
    bool? isPublic,
  }) {
    return (update(dietPackagesTable)..where((t) => t.packageId.equals(packageId)))
        .write(DietPackagesTableCompanion(
      isActive: Value.absentIfNull(isActive),
      isPublic: Value.absentIfNull(isPublic),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Increment assigned count
  Future<int> incrementAssignedCount(String packageId) async {
    final package = await getDietPackageById(packageId);
    if (package != null) {
      return (update(dietPackagesTable)..where((t) => t.packageId.equals(packageId)))
          .write(DietPackagesTableCompanion(
        assignedCount: Value(package.assignedCount + 1),
        updatedAt: Value(DateTime.now()),
      ));
    }
    return 0;
  }

  // Decrement assigned count
  Future<int> decrementAssignedCount(String packageId) async {
    final package = await getDietPackageById(packageId);
    if (package != null && package.assignedCount > 0) {
      return (update(dietPackagesTable)..where((t) => t.packageId.equals(packageId)))
          .write(DietPackagesTableCompanion(
        assignedCount: Value(package.assignedCount - 1),
        updatedAt: Value(DateTime.now()),
      ));
    }
    return 0;
  }

  // Update rating and review count
  Future<int> updateRatingAndReviews(String packageId, double newRating) async {
    final package = await getDietPackageById(packageId);
    if (package != null) {
      final currentAvg = package.averageRating;
      final currentCount = package.reviewCount;
      final newCount = currentCount + 1;
      final newAvg = ((currentAvg * currentCount) + newRating) / newCount;
      
      return (update(dietPackagesTable)..where((t) => t.packageId.equals(packageId)))
          .write(DietPackagesTableCompanion(
        averageRating: Value(newAvg),
        reviewCount: Value(newCount),
        updatedAt: Value(DateTime.now()),
      ));
    }
    return 0;
  }

  // Add tags to diet package
  Future<int> addTagsToPackage(String packageId, List<String> newTags) async {
    final package = await getDietPackageById(packageId);
    if (package != null) {
      final existingTags = (jsonDecode(package.tags) as List).cast<String>();
      final updatedTags = {...existingTags, ...newTags}.toList();
      
      return (update(dietPackagesTable)..where((t) => t.packageId.equals(packageId)))
          .write(DietPackagesTableCompanion(
        tags: Value(jsonEncode(updatedTags)),
        updatedAt: Value(DateTime.now()),
      ));
    }
    return 0;
  }

  // Remove tags from diet package
  Future<int> removeTagsFromPackage(String packageId, List<String> tagsToRemove) async {
    final package = await getDietPackageById(packageId);
    if (package != null) {
      final existingTags = (jsonDecode(package.tags) as List).cast<String>();
      final updatedTags = existingTags.where((tag) => !tagsToRemove.contains(tag)).toList();
      
      return (update(dietPackagesTable)..where((t) => t.packageId.equals(packageId)))
          .write(DietPackagesTableCompanion(
        tags: Value(jsonEncode(updatedTags)),
        updatedAt: Value(DateTime.now()),
      ));
    }
    return 0;
  }

  // Get diet packages by type
  Future<List<DietPackageData>> getDietPackagesByType(String type) {
    return (select(dietPackagesTable)
          ..where((t) => t.type.equals(type) & t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm(expression: t.averageRating, mode: OrderingMode.desc)]))
        .get();
  }

  // Get diet packages by price range
  Future<List<DietPackageData>> getDietPackagesByPriceRange(double minPrice, double maxPrice) {
    return (select(dietPackagesTable)
          ..where((t) => t.price.isBetweenValues(minPrice, maxPrice) & t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm(expression: t.price, mode: OrderingMode.asc)]))
        .get();
  }

  // Get popular diet packages (high rating and assignment count)
  Future<List<DietPackageData>> getPopularDietPackages({int limit = 10}) {
    return (select(dietPackagesTable)
          ..where((t) => t.isActive.equals(true) & t.reviewCount.isBiggerThanValue(0))
          ..orderBy([(t) => OrderingTerm(expression: t.averageRating, mode: OrderingMode.desc),
                    (t) => OrderingTerm(expression: t.assignedCount, mode: OrderingMode.desc)])
          ..limit(limit))
        .get();
  }

  // Get diet packages by tags
  Future<List<DietPackageData>> getDietPackagesByTags(List<String> tags) async {
    final allPackages = await getActiveDietPackages();
    return allPackages.where((package) {
      final packageTags = (jsonDecode(package.tags) as List).cast<String>();
      return tags.any((tag) => packageTags.contains(tag));
    }).toList();
  }

  // Search diet packages
  Future<List<DietPackageData>> searchDietPackages(String query) {
    final lowerQuery = query.toLowerCase();
    return (select(dietPackagesTable)
          ..where((t) => t.isActive.equals(true) & 
                        (t.title.lower().contains(lowerQuery) |
                         t.description.lower().contains(lowerQuery) |
                         t.type.lower().contains(lowerQuery)))
          ..orderBy([(t) => OrderingTerm(expression: t.averageRating, mode: OrderingMode.desc)]))
        .get();
  }

  // Get diet packages in date range
  Future<List<DietPackageData>> getDietPackagesInDateRange(DateTime from, DateTime to) {
    return (select(dietPackagesTable)
          ..where((t) => t.createdAt.isBetweenValues(from, to))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Get diet packages with pagination
  Future<List<DietPackageData>> getDietPackagesPaginated({
    String? dietitianId,
    String? type,
    bool? isActive,
    bool? isPublic,
    double? minPrice,
    double? maxPrice,
    required int limit,
    int? offset,
    String? orderBy = 'createdAt',
    bool ascending = false,
  }) {
    var query = select(dietPackagesTable);
    
    // Add filters
    if (dietitianId != null) {
      query = query..where((t) => t.dietitianId.equals(dietitianId));
    }
    
    if (type != null) {
      query = query..where((t) => t.type.equals(type));
    }
    
    if (isActive != null) {
      query = query..where((t) => t.isActive.equals(isActive));
    }
    
    if (isPublic != null) {
      query = query..where((t) => t.isPublic.equals(isPublic));
    }
    
    if (minPrice != null && maxPrice != null) {
      query = query..where((t) => t.price.isBetweenValues(minPrice, maxPrice));
    } else if (minPrice != null) {
      query = query..where((t) => t.price.isBiggerOrEqualValue(minPrice));
    } else if (maxPrice != null) {
      query = query..where((t) => t.price.isSmallerOrEqualValue(maxPrice));
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
      case 'price':
        query = query..orderBy([(t) => OrderingTerm(
          expression: t.price, 
          mode: ascending ? OrderingMode.asc : OrderingMode.desc
        )]);
        break;
      case 'averageRating':
        query = query..orderBy([(t) => OrderingTerm(
          expression: t.averageRating, 
          mode: ascending ? OrderingMode.asc : OrderingMode.desc
        )]);
        break;
      case 'assignedCount':
        query = query..orderBy([(t) => OrderingTerm(
          expression: t.assignedCount, 
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

  // Count diet packages
  Future<int> countDietPackages({
    String? dietitianId,
    String? type,
    bool? isActive,
    bool? isPublic,
  }) {
    var query = selectOnly(dietPackagesTable);
    
    if (dietitianId != null) {
      query = query..where(dietPackagesTable.dietitianId.equals(dietitianId));
    }
    
    if (type != null) {
      query = query..where(dietPackagesTable.type.equals(type));
    }
    
    if (isActive != null) {
      query = query..where(dietPackagesTable.isActive.equals(isActive));
    }
    
    if (isPublic != null) {
      query = query..where(dietPackagesTable.isPublic.equals(isPublic));
    }
    
    query = query..addColumns([dietPackagesTable.id.count()]);
    return query.map((row) => row.read(dietPackagesTable.id.count()) ?? 0).getSingle();
  }

  // Get package statistics for dietitian
  Future<Map<String, int>> getDietitianPackageStatistics(String dietitianId) async {
    final totalPackages = await countDietPackages(dietitianId: dietitianId);
    final activePackages = await countDietPackages(dietitianId: dietitianId, isActive: true);
    final publicPackages = await countDietPackages(dietitianId: dietitianId, isPublic: true);
    
    return {
      'total': totalPackages,
      'active': activePackages,
      'public': publicPackages,
    };
  }

  // Get nutrition targets from JSON
  Future<Map<String, dynamic>> getNutritionTargets(String packageId) async {
    final package = await getDietPackageById(packageId);
    if (package != null) {
      return jsonDecode(package.nutritionTargets) as Map<String, dynamic>;
    }
    return {};
  }

  // Get meal plans from JSON
  Future<List<Map<String, dynamic>>> getMealPlans(String packageId) async {
    final package = await getDietPackageById(packageId);
    if (package != null) {
      return (jsonDecode(package.mealPlans) as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  // Get allowed foods from JSON
  Future<List<String>> getAllowedFoods(String packageId) async {
    final package = await getDietPackageById(packageId);
    if (package != null) {
      return (jsonDecode(package.allowedFoods) as List).cast<String>();
    }
    return [];
  }

  // Get forbidden foods from JSON
  Future<List<String>> getForbiddenFoods(String packageId) async {
    final package = await getDietPackageById(packageId);
    if (package != null) {
      return (jsonDecode(package.forbiddenFoods) as List).cast<String>();
    }
    return [];
  }

  // Delete diet packages by dietitian
  Future<int> deleteDietPackagesByDietitian(String dietitianId) {
    return (delete(dietPackagesTable)..where((t) => t.dietitianId.equals(dietitianId))).go();
  }

  // Clear all diet packages
  Future<int> clearAll() {
    return delete(dietPackagesTable).go();
  }
}