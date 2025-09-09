import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/users_table.dart';

part 'user_dao.g.dart';

@DriftAccessor(tables: [UsersTable])
class UserDao extends DatabaseAccessor<AppDatabase> with _$UserDaoMixin {
  UserDao(super.db);

  // Get all users
  Future<List<UserData>> getAllUsers() {
    return select(usersTable).get();
  }

  // Watch all users
  Stream<List<UserData>> watchAllUsers() {
    return (select(usersTable)
          ..orderBy([(t) => OrderingTerm(expression: t.name, mode: OrderingMode.asc)]))
        .watch();
  }

  // Get user by ID
  Future<UserData?> getUserById(String userId) {
    return (select(usersTable)..where((t) => t.userId.equals(userId))).getSingleOrNull();
  }

  // Watch user by ID
  Stream<UserData?> watchUserById(String userId) {
    return (select(usersTable)..where((t) => t.userId.equals(userId))).watchSingleOrNull();
  }

  // Get user by phone number
  Future<UserData?> getUserByPhoneNumber(String phoneNumber) {
    return (select(usersTable)..where((t) => t.phoneNumber.equals(phoneNumber))).getSingleOrNull();
  }

  // Watch user by phone number
  Stream<UserData?> watchUserByPhoneNumber(String phoneNumber) {
    return (select(usersTable)..where((t) => t.phoneNumber.equals(phoneNumber))).watchSingleOrNull();
  }

  // Save or update user (upsert)
  Future<int> saveUser(UsersTableCompanion user) {
    return into(usersTable).insertOnConflictUpdate(user);
  }

  // Batch save users
  Future<void> saveUsers(List<UsersTableCompanion> userList) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(usersTable, userList);
    });
  }

  // Alias for compatibility
  Future<void> batchSaveUsers(List<UsersTableCompanion> userList) async {
    return saveUsers(userList);
  }

  // Update user
  Future<bool> updateUser(UsersTableCompanion user) {
    return update(usersTable).replace(user);
  }

  // Delete user
  Future<int> deleteUser(String userId) {
    return (delete(usersTable)..where((t) => t.userId.equals(userId))).go();
  }

  // Update user profile image
  Future<int> updateUserProfileImage(String userId, {String? imageUrl, String? localPath}) {
    return (update(usersTable)..where((t) => t.userId.equals(userId)))
        .write(UsersTableCompanion(
      profileImageUrl: Value.absentIfNull(imageUrl),
      profileImageLocalPath: Value.absentIfNull(localPath),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update user online status
  Future<int> updateUserOnlineStatus(String userId, bool isOnline, {DateTime? lastSeen}) {
    return (update(usersTable)..where((t) => t.userId.equals(userId)))
        .write(UsersTableCompanion(
      isOnline: Value(isOnline),
      lastSeen: Value.absentIfNull(lastSeen ?? (isOnline ? null : DateTime.now())),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update user health information
  Future<int> updateUserHealthInfo(
    String userId, {
    double? height,
    double? weight,
    int? age,
    DateTime? birthDate,
  }) {
    return (update(usersTable)..where((t) => t.userId.equals(userId)))
        .write(UsersTableCompanion(
      currentHeight: Value.absentIfNull(height),
      currentWeight: Value.absentIfNull(weight),
      age: Value.absentIfNull(age),
      birthDate: Value.absentIfNull(birthDate),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update user step count
  Future<int> updateUserStepCount(String userId, int stepCount) {
    return (update(usersTable)..where((t) => t.userId.equals(userId)))
        .write(UsersTableCompanion(
      todayStepCount: Value(stepCount),
      lastStepUpdate: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update user privacy settings
  Future<int> updateUserPrivacySettings(
    String userId, {
    PrivacySetting? lastSeenPrivacy,
    PrivacySetting? profilePhotoPrivacy,
    PrivacySetting? aboutPrivacy,
  }) {
    return (update(usersTable)..where((t) => t.userId.equals(userId)))
        .write(UsersTableCompanion(
      lastSeenPrivacy: Value.absentIfNull(lastSeenPrivacy),
      profilePhotoPrivacy: Value.absentIfNull(profilePhotoPrivacy),
      aboutPrivacy: Value.absentIfNull(aboutPrivacy),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Search users by name or phone
  Future<List<UserData>> searchUsers(String query) {
    final lowerQuery = query.toLowerCase();
    return (select(usersTable)
          ..where((t) => t.name.lower().contains(lowerQuery) |
              t.phoneNumber.lower().contains(lowerQuery)))
        .get();
  }

  // Get users by role
  Future<List<UserData>> getUsersByRole(UserRole role) {
    return (select(usersTable)..where((t) => t.userRole.equals(role.index))).get();
  }

  // Watch users by role
  Stream<List<UserData>> watchUsersByRole(UserRole role) {
    return (select(usersTable)..where((t) => t.userRole.equals(role.index))).watch();
  }

  // Get online users
  Stream<List<UserData>> watchOnlineUsers() {
    return (select(usersTable)
          ..where((t) => t.isOnline.equals(true))
          ..orderBy([(t) => OrderingTerm(expression: t.name, mode: OrderingMode.asc)]))
        .watch();
  }

  // Get users with health data
  Future<List<UserData>> getUsersWithHealthData() {
    return (select(usersTable)
          ..where((t) => t.currentHeight.isNotNull() & t.currentWeight.isNotNull()))
        .get();
  }

  // Get users created within date range
  Future<List<UserData>> getUsersInDateRange(DateTime from, DateTime to) {
    return (select(usersTable)
          ..where((t) => t.createdAt.isBetweenValues(from, to))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Get users with pagination
  Future<List<UserData>> getUsersPaginated({
    required int limit,
    int? offset,
    String? orderBy = 'name',
    bool ascending = true,
  }) {
    var query = select(usersTable);
    
    // Add ordering
    switch (orderBy) {
      case 'name':
        query = query..orderBy([(t) => OrderingTerm(
          expression: t.name, 
          mode: ascending ? OrderingMode.asc : OrderingMode.desc
        )]);
        break;
      case 'createdAt':
        query = query..orderBy([(t) => OrderingTerm(
          expression: t.createdAt, 
          mode: ascending ? OrderingMode.asc : OrderingMode.desc
        )]);
        break;
      case 'lastSeen':
        query = query..orderBy([(t) => OrderingTerm(
          expression: t.lastSeen, 
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

  // Count total users
  Future<int> countUsers() {
    final query = selectOnly(usersTable)..addColumns([usersTable.id.count()]);
    return query.map((row) => row.read(usersTable.id.count()) ?? 0).getSingle();
  }

  // Count users by role
  Future<int> countUsersByRole(UserRole role) {
    final query = selectOnly(usersTable)
      ..where(usersTable.userRole.equals(role.index))
      ..addColumns([usersTable.id.count()]);
    return query.map((row) => row.read(usersTable.id.count()) ?? 0).getSingle();
  }

  // Update user role
  Future<int> updateUserRole(String userId, UserRole role) {
    return (update(usersTable)..where((t) => t.userId.equals(userId)))
        .write(UsersTableCompanion(
      userRole: Value(role),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update user about
  Future<int> updateUserAbout(String userId, String about) {
    return (update(usersTable)..where((t) => t.userId.equals(userId)))
        .write(UsersTableCompanion(
      about: Value(about),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Clear all users
  Future<int> clearAll() {
    return delete(usersTable).go();
  }
}