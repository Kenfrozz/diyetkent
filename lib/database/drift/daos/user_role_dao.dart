import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/user_roles_table.dart';

part 'user_role_dao.g.dart';

@DriftAccessor(tables: [UserRolesTable])
class UserRoleDao extends DatabaseAccessor<AppDatabase> with _$UserRoleDaoMixin {
  UserRoleDao(super.db);

  // Get all user roles
  Future<List<UserRoleData>> getAllUserRoles() {
    return (select(userRolesTable)
          ..orderBy([(t) => OrderingTerm(expression: t.userId, mode: OrderingMode.asc)]))
        .get();
  }

  // Watch all user roles
  Stream<List<UserRoleData>> watchAllUserRoles() {
    return (select(userRolesTable)
          ..orderBy([(t) => OrderingTerm(expression: t.userId, mode: OrderingMode.asc)]))
        .watch();
  }

  // Get user role by user ID
  Future<UserRoleData?> getUserRoleByUserId(String userId) {
    return (select(userRolesTable)..where((t) => t.userId.equals(userId))).getSingleOrNull();
  }

  // Watch user role by user ID
  Stream<UserRoleData?> watchUserRoleByUserId(String userId) {
    return (select(userRolesTable)..where((t) => t.userId.equals(userId))).watchSingleOrNull();
  }

  // Save or update user role (upsert)
  Future<int> saveUserRole(UserRolesTableCompanion userRole) {
    return into(userRolesTable).insertOnConflictUpdate(userRole);
  }

  // Batch save user roles
  Future<void> saveUserRoles(List<UserRolesTableCompanion> userRoleList) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(userRolesTable, userRoleList);
    });
  }

  // Update user role
  Future<bool> updateUserRole(UserRolesTableCompanion userRole) {
    return update(userRolesTable).replace(userRole);
  }

  // Delete user role
  Future<int> deleteUserRole(String userId) {
    return (delete(userRolesTable)..where((t) => t.userId.equals(userId))).go();
  }

  // Update user role type
  Future<int> updateUserRoleType(String userId, String role) {
    return (update(userRolesTable)..where((t) => t.userId.equals(userId)))
        .write(UserRolesTableCompanion(
      role: Value(role),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update dietitian information
  Future<int> updateDietitianInfo({
    required String userId,
    String? licenseNumber,
    String? specialization,
    String? clinicName,
    String? clinicAddress,
    int? experienceYears,
  }) {
    return (update(userRolesTable)..where((t) => t.userId.equals(userId)))
        .write(UserRolesTableCompanion(
      licenseNumber: Value.absentIfNull(licenseNumber),
      specialization: Value.absentIfNull(specialization),
      clinicName: Value.absentIfNull(clinicName),
      clinicAddress: Value.absentIfNull(clinicAddress),
      experienceYears: Value.absentIfNull(experienceYears),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update user permissions
  Future<int> updateUserPermissions({
    required String userId,
    bool? canSendBulkMessages,
    bool? canViewAllUsers,
    bool? canCreateDietFiles,
    bool? canViewUserHealth,
  }) {
    return (update(userRolesTable)..where((t) => t.userId.equals(userId)))
        .write(UserRolesTableCompanion(
      canSendBulkMessages: Value.absentIfNull(canSendBulkMessages),
      canViewAllUsers: Value.absentIfNull(canViewAllUsers),
      canCreateDietFiles: Value.absentIfNull(canCreateDietFiles),
      canViewUserHealth: Value.absentIfNull(canViewUserHealth),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update statistics
  Future<int> updateUserStatistics({
    required String userId,
    int? totalPatientsCount,
    int? activePatientsCount,
    int? dietFilesCreatedCount,
  }) {
    return (update(userRolesTable)..where((t) => t.userId.equals(userId)))
        .write(UserRolesTableCompanion(
      totalPatientsCount: Value.absentIfNull(totalPatientsCount),
      activePatientsCount: Value.absentIfNull(activePatientsCount),
      dietFilesCreatedCount: Value.absentIfNull(dietFilesCreatedCount),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Increment patient count
  Future<int> incrementPatientCount(String userId) async {
    final userRole = await getUserRoleByUserId(userId);
    if (userRole != null) {
      return (update(userRolesTable)..where((t) => t.userId.equals(userId)))
          .write(UserRolesTableCompanion(
        totalPatientsCount: Value(userRole.totalPatientsCount + 1),
        activePatientsCount: Value(userRole.activePatientsCount + 1),
        updatedAt: Value(DateTime.now()),
      ));
    }
    return 0;
  }

  // Decrement patient count
  Future<int> decrementPatientCount(String userId, {bool onlyActive = false}) async {
    final userRole = await getUserRoleByUserId(userId);
    if (userRole != null) {
      return (update(userRolesTable)..where((t) => t.userId.equals(userId)))
          .write(UserRolesTableCompanion(
        totalPatientsCount: onlyActive 
            ? const Value.absent() 
            : Value((userRole.totalPatientsCount - 1).clamp(0, double.infinity).toInt()),
        activePatientsCount: Value((userRole.activePatientsCount - 1).clamp(0, double.infinity).toInt()),
        updatedAt: Value(DateTime.now()),
      ));
    }
    return 0;
  }

  // Increment diet files created count
  Future<int> incrementDietFilesCreatedCount(String userId) async {
    final userRole = await getUserRoleByUserId(userId);
    if (userRole != null) {
      return (update(userRolesTable)..where((t) => t.userId.equals(userId)))
          .write(UserRolesTableCompanion(
        dietFilesCreatedCount: Value(userRole.dietFilesCreatedCount + 1),
        updatedAt: Value(DateTime.now()),
      ));
    }
    return 0;
  }

  // Get users by role
  Future<List<UserRoleData>> getUsersByRole(String role) {
    return (select(userRolesTable)
          ..where((t) => t.role.equals(role))
          ..orderBy([(t) => OrderingTerm(expression: t.userId, mode: OrderingMode.asc)]))
        .get();
  }

  // Watch users by role
  Stream<List<UserRoleData>> watchUsersByRole(String role) {
    return (select(userRolesTable)
          ..where((t) => t.role.equals(role))
          ..orderBy([(t) => OrderingTerm(expression: t.userId, mode: OrderingMode.asc)]))
        .watch();
  }

  // Get dietitians
  Future<List<UserRoleData>> getDietitians() {
    return getUsersByRole('dietitian');
  }

  // Watch dietitians
  Stream<List<UserRoleData>> watchDietitians() {
    return watchUsersByRole('dietitian');
  }

  // Get admins
  Future<List<UserRoleData>> getAdmins() {
    return getUsersByRole('admin');
  }

  // Watch admins
  Stream<List<UserRoleData>> watchAdmins() {
    return watchUsersByRole('admin');
  }

  // Get regular users
  Future<List<UserRoleData>> getRegularUsers() {
    return getUsersByRole('user');
  }

  // Watch regular users
  Stream<List<UserRoleData>> watchRegularUsers() {
    return watchUsersByRole('user');
  }

  // Get users with specific permission
  Future<List<UserRoleData>> getUsersWithPermission(String permissionType) {
    switch (permissionType) {
      case 'canSendBulkMessages':
        return (select(userRolesTable)
              ..where((t) => t.canSendBulkMessages.equals(true)))
            .get();
      case 'canViewAllUsers':
        return (select(userRolesTable)
              ..where((t) => t.canViewAllUsers.equals(true)))
            .get();
      case 'canCreateDietFiles':
        return (select(userRolesTable)
              ..where((t) => t.canCreateDietFiles.equals(true)))
            .get();
      case 'canViewUserHealth':
        return (select(userRolesTable)
              ..where((t) => t.canViewUserHealth.equals(true)))
            .get();
      default:
        return Future.value([]);
    }
  }

  // Get dietitians by specialization
  Future<List<UserRoleData>> getDietitiansBySpecialization(String specialization) {
    return (select(userRolesTable)
          ..where((t) => t.role.equals('dietitian') & 
                        t.specialization.equals(specialization))
          ..orderBy([(t) => OrderingTerm(expression: t.userId, mode: OrderingMode.asc)]))
        .get();
  }

  // Get dietitians by experience years
  Future<List<UserRoleData>> getDietitiansByExperience({int? minYears, int? maxYears}) {
    var query = select(userRolesTable)
      ..where((t) => t.role.equals('dietitian'));
    
    if (minYears != null) {
      query = query..where((t) => t.experienceYears.isBiggerOrEqualValue(minYears));
    }
    
    if (maxYears != null) {
      query = query..where((t) => t.experienceYears.isSmallerOrEqualValue(maxYears));
    }
    
    return (query
          ..orderBy([(t) => OrderingTerm(expression: t.experienceYears, mode: OrderingMode.desc)]))
        .get();
  }

  // Get most active dietitians (by patient count)
  Future<List<UserRoleData>> getMostActiveDietitians({int limit = 10}) {
    return (select(userRolesTable)
          ..where((t) => t.role.equals('dietitian'))
          ..orderBy([(t) => OrderingTerm(expression: t.activePatientsCount, mode: OrderingMode.desc)])
          ..limit(limit))
        .get();
  }

  // Get most productive dietitians (by diet files created)
  Future<List<UserRoleData>> getMostProductiveDietitians({int limit = 10}) {
    return (select(userRolesTable)
          ..where((t) => t.role.equals('dietitian'))
          ..orderBy([(t) => OrderingTerm(expression: t.dietFilesCreatedCount, mode: OrderingMode.desc)])
          ..limit(limit))
        .get();
  }

  // Search dietitians
  Future<List<UserRoleData>> searchDietitians(String query) {
    final lowerQuery = query.toLowerCase();
    return (select(userRolesTable)
          ..where((t) => t.role.equals('dietitian') & 
                        (t.specialization.lower().contains(lowerQuery) |
                         t.clinicName.lower().contains(lowerQuery) |
                         t.licenseNumber.lower().contains(lowerQuery)))
          ..orderBy([(t) => OrderingTerm(expression: t.userId, mode: OrderingMode.asc)]))
        .get();
  }

  // Get users with pagination
  Future<List<UserRoleData>> getUserRolesPaginated({
    String? role,
    String? specialization,
    bool? hasPermissions,
    required int limit,
    int? offset,
    String? orderBy = 'userId',
    bool ascending = true,
  }) {
    var query = select(userRolesTable);
    
    // Add filters
    if (role != null) {
      query = query..where((t) => t.role.equals(role));
    }
    
    if (specialization != null) {
      query = query..where((t) => t.specialization.equals(specialization));
    }
    
    if (hasPermissions == true) {
      query = query..where((t) => t.canSendBulkMessages.equals(true) |
                                  t.canViewAllUsers.equals(true) |
                                  t.canCreateDietFiles.equals(true) |
                                  t.canViewUserHealth.equals(true));
    }
    
    // Add ordering
    switch (orderBy) {
      case 'userId':
        query = query..orderBy([(t) => OrderingTerm(
          expression: t.userId, 
          mode: ascending ? OrderingMode.asc : OrderingMode.desc
        )]);
        break;
      case 'role':
        query = query..orderBy([(t) => OrderingTerm(
          expression: t.role, 
          mode: ascending ? OrderingMode.asc : OrderingMode.desc
        )]);
        break;
      case 'experienceYears':
        query = query..orderBy([(t) => OrderingTerm(
          expression: t.experienceYears, 
          mode: ascending ? OrderingMode.asc : OrderingMode.desc
        )]);
        break;
      case 'totalPatientsCount':
        query = query..orderBy([(t) => OrderingTerm(
          expression: t.totalPatientsCount, 
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

  // Count users by role
  Future<int> countUsersByRole(String role) {
    final query = selectOnly(userRolesTable)
      ..where(userRolesTable.role.equals(role))
      ..addColumns([userRolesTable.id.count()]);
    return query.map((row) => row.read(userRolesTable.id.count()) ?? 0).getSingle();
  }

  // Count dietitians
  Future<int> countDietitians() {
    return countUsersByRole('dietitian');
  }

  // Count admins
  Future<int> countAdmins() {
    return countUsersByRole('admin');
  }

  // Count regular users
  Future<int> countRegularUsers() {
    return countUsersByRole('user');
  }

  // Get role statistics
  Future<Map<String, int>> getRoleStatistics() async {
    final totalUsers = await countUsersByRole('user');
    final totalDietitians = await countUsersByRole('dietitian');
    final totalAdmins = await countUsersByRole('admin');
    
    final totalPatients = await _getTotalPatientCount();
    final totalDietFiles = await _getTotalDietFilesCount();
    
    return {
      'users': totalUsers,
      'dietitians': totalDietitians,
      'admins': totalAdmins,
      'totalPatients': totalPatients,
      'totalDietFiles': totalDietFiles,
    };
  }

  // Helper method to get total patient count
  Future<int> _getTotalPatientCount() async {
    final query = selectOnly(userRolesTable)
      ..addColumns([userRolesTable.totalPatientsCount.sum()]);
    return query.map((row) => row.read(userRolesTable.totalPatientsCount.sum()) ?? 0).getSingle();
  }

  // Helper method to get total diet files count
  Future<int> _getTotalDietFilesCount() async {
    final query = selectOnly(userRolesTable)
      ..addColumns([userRolesTable.dietFilesCreatedCount.sum()]);
    return query.map((row) => row.read(userRolesTable.dietFilesCreatedCount.sum()) ?? 0).getSingle();
  }

  // Check if user has permission
  Future<bool> userHasPermission(String userId, String permissionType) async {
    final userRole = await getUserRoleByUserId(userId);
    if (userRole == null) return false;
    
    switch (permissionType) {
      case 'canSendBulkMessages':
        return userRole.canSendBulkMessages;
      case 'canViewAllUsers':
        return userRole.canViewAllUsers;
      case 'canCreateDietFiles':
        return userRole.canCreateDietFiles;
      case 'canViewUserHealth':
        return userRole.canViewUserHealth;
      default:
        return false;
    }
  }

  // Check if user is dietitian
  Future<bool> userIsDietitian(String userId) async {
    final userRole = await getUserRoleByUserId(userId);
    return userRole?.role == 'dietitian';
  }

  // Check if user is admin
  Future<bool> userIsAdmin(String userId) async {
    final userRole = await getUserRoleByUserId(userId);
    return userRole?.role == 'admin';
  }

  // Create default user role
  Future<int> createDefaultUserRole(String userId) {
    final companion = UserRolesTableCompanion(
      userId: Value(userId),
      role: const Value('user'),
      canSendBulkMessages: const Value(false),
      canViewAllUsers: const Value(false),
      canCreateDietFiles: const Value(false),
      canViewUserHealth: const Value(false),
      totalPatientsCount: const Value(0),
      activePatientsCount: const Value(0),
      dietFilesCreatedCount: const Value(0),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    );
    
    return saveUserRole(companion);
  }

  // Create dietitian role
  Future<int> createDietitianRole({
    required String userId,
    String? licenseNumber,
    String? specialization,
    String? clinicName,
    String? clinicAddress,
    int? experienceYears,
  }) {
    final companion = UserRolesTableCompanion(
      userId: Value(userId),
      role: const Value('dietitian'),
      licenseNumber: Value.absentIfNull(licenseNumber),
      specialization: Value.absentIfNull(specialization),
      clinicName: Value.absentIfNull(clinicName),
      clinicAddress: Value.absentIfNull(clinicAddress),
      experienceYears: Value.absentIfNull(experienceYears),
      canSendBulkMessages: const Value(true),
      canViewAllUsers: const Value(true),
      canCreateDietFiles: const Value(true),
      canViewUserHealth: const Value(true),
      totalPatientsCount: const Value(0),
      activePatientsCount: const Value(0),
      dietFilesCreatedCount: const Value(0),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    );
    
    return saveUserRole(companion);
  }

  // Clear all user roles
  Future<int> clearAll() {
    return delete(userRolesTable).go();
  }
}