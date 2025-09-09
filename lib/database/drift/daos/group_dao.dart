import 'dart:convert';
import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/groups_table.dart';

part 'group_dao.g.dart';

@DriftAccessor(tables: [GroupsTable, GroupMembersTable])
class GroupDao extends DatabaseAccessor<AppDatabase> with _$GroupDaoMixin {
  GroupDao(super.db);

  // ============ GROUP OPERATIONS ============

  // Get all groups
  Future<List<GroupData>> getAllGroups() {
    return select(groupsTable).get();
  }

  // Watch all groups
  Stream<List<GroupData>> watchAllGroups() {
    return (select(groupsTable)
          ..orderBy([(t) => OrderingTerm(expression: t.name, mode: OrderingMode.asc)]))
        .watch();
  }

  // Get group by ID
  Future<GroupData?> getGroupById(String groupId) {
    return (select(groupsTable)..where((t) => t.groupId.equals(groupId))).getSingleOrNull();
  }

  // Watch group by ID
  Stream<GroupData?> watchGroupById(String groupId) {
    return (select(groupsTable)..where((t) => t.groupId.equals(groupId))).watchSingleOrNull();
  }

  // Save or update group (upsert)
  Future<int> saveGroup(GroupsTableCompanion group) {
    return into(groupsTable).insertOnConflictUpdate(group);
  }

  // Batch save groups
  Future<void> saveGroups(List<GroupsTableCompanion> groupList) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(groupsTable, groupList);
    });
  }

  // Update group
  Future<bool> updateGroup(GroupsTableCompanion group) {
    return update(groupsTable).replace(group);
  }

  // Delete group
  Future<int> deleteGroup(String groupId) {
    return (delete(groupsTable)..where((t) => t.groupId.equals(groupId))).go();
  }

  // Update group profile image
  Future<int> updateGroupProfileImage(String groupId, {String? imageUrl, String? localPath}) {
    return (update(groupsTable)..where((t) => t.groupId.equals(groupId)))
        .write(GroupsTableCompanion(
      profileImageUrl: Value.absentIfNull(imageUrl),
      profileImageLocalPath: Value.absentIfNull(localPath),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update group basic info
  Future<int> updateGroupInfo({
    required String groupId,
    String? name,
    String? description,
  }) {
    return (update(groupsTable)..where((t) => t.groupId.equals(groupId)))
        .write(GroupsTableCompanion(
      name: Value.absentIfNull(name),
      description: Value.absentIfNull(description),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update group permissions
  Future<int> updateGroupPermissions({
    required String groupId,
    MessagePermission? messagePermission,
    MediaPermission? mediaPermission,
    bool? allowMembersToAddOthers,
  }) {
    return (update(groupsTable)..where((t) => t.groupId.equals(groupId)))
        .write(GroupsTableCompanion(
      messagePermission: Value.absentIfNull(messagePermission),
      mediaPermission: Value.absentIfNull(mediaPermission),
      allowMembersToAddOthers: Value.absentIfNull(allowMembersToAddOthers),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Add member to group
  Future<int> addGroupMember(String groupId, String userId) async {
    final group = await getGroupById(groupId);
    if (group != null) {
      final members = (jsonDecode(group.members) as List).cast<String>();
      if (!members.contains(userId)) {
        members.add(userId);
        return (update(groupsTable)..where((t) => t.groupId.equals(groupId)))
            .write(GroupsTableCompanion(
          members: Value(jsonEncode(members)),
          updatedAt: Value(DateTime.now()),
        ));
      }
    }
    return 0;
  }

  // Remove member from group
  Future<int> removeGroupMember(String groupId, String userId) async {
    final group = await getGroupById(groupId);
    if (group != null) {
      final members = (jsonDecode(group.members) as List).cast<String>();
      final admins = (jsonDecode(group.admins) as List).cast<String>();
      
      members.remove(userId);
      admins.remove(userId);
      
      return (update(groupsTable)..where((t) => t.groupId.equals(groupId)))
          .write(GroupsTableCompanion(
        members: Value(jsonEncode(members)),
        admins: Value(jsonEncode(admins)),
        updatedAt: Value(DateTime.now()),
      ));
    }
    return 0;
  }

  // Add admin to group
  Future<int> addGroupAdmin(String groupId, String userId) async {
    final group = await getGroupById(groupId);
    if (group != null) {
      final admins = (jsonDecode(group.admins) as List).cast<String>();
      if (!admins.contains(userId)) {
        admins.add(userId);
        // Also ensure user is a member
        await addGroupMember(groupId, userId);
        return (update(groupsTable)..where((t) => t.groupId.equals(groupId)))
            .write(GroupsTableCompanion(
          admins: Value(jsonEncode(admins)),
          updatedAt: Value(DateTime.now()),
        ));
      }
    }
    return 0;
  }

  // Remove admin from group
  Future<int> removeGroupAdmin(String groupId, String userId) async {
    final group = await getGroupById(groupId);
    if (group != null) {
      final admins = (jsonDecode(group.admins) as List).cast<String>();
      admins.remove(userId);
      return (update(groupsTable)..where((t) => t.groupId.equals(groupId)))
          .write(GroupsTableCompanion(
        admins: Value(jsonEncode(admins)),
        updatedAt: Value(DateTime.now()),
      ));
    }
    return 0;
  }

  // Get groups by creator
  Future<List<GroupData>> getGroupsByCreator(String creatorId) {
    return (select(groupsTable)..where((t) => t.createdBy.equals(creatorId))).get();
  }

  // Get groups where user is member
  Future<List<GroupData>> getGroupsForUser(String userId) async {
    final allGroups = await getAllGroups();
    return allGroups.where((group) {
      final members = (jsonDecode(group.members) as List).cast<String>();
      return members.contains(userId);
    }).toList();
  }

  // Get groups where user is admin
  Future<List<GroupData>> getGroupsWhereUserIsAdmin(String userId) async {
    final allGroups = await getAllGroups();
    return allGroups.where((group) {
      final admins = (jsonDecode(group.admins) as List).cast<String>();
      return admins.contains(userId);
    }).toList();
  }

  // Search groups by name
  Future<List<GroupData>> searchGroups(String query) {
    final lowerQuery = query.toLowerCase();
    return (select(groupsTable)
          ..where((t) => t.name.lower().contains(lowerQuery) |
              t.description.lower().contains(lowerQuery)))
        .get();
  }

  // ============ GROUP MEMBER OPERATIONS ============

  // Get all group members
  Future<List<GroupMemberData>> getAllGroupMembers() {
    return select(groupMembersTable).get();
  }

  // Get group members by group ID
  Future<List<GroupMemberData>> getGroupMembers(String groupId) {
    return (select(groupMembersTable)..where((t) => t.groupId.equals(groupId))).get();
  }

  // Watch group members by group ID
  Stream<List<GroupMemberData>> watchGroupMembers(String groupId) {
    return (select(groupMembersTable)..where((t) => t.groupId.equals(groupId))).watch();
  }

  // Get group member by IDs
  Future<GroupMemberData?> getGroupMember(String groupId, String userId) {
    return (select(groupMembersTable)
          ..where((t) => t.groupId.equals(groupId) & t.userId.equals(userId)))
        .getSingleOrNull();
  }

  // Save or update group member (upsert)
  Future<int> saveGroupMember(GroupMembersTableCompanion member) {
    return into(groupMembersTable).insertOnConflictUpdate(member);
  }

  // Batch save group members
  Future<void> saveGroupMembers(List<GroupMembersTableCompanion> memberList) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(groupMembersTable, memberList);
    });
  }

  // Update group member info
  Future<int> updateGroupMemberInfo({
    required String groupId,
    required String userId,
    String? displayName,
    String? contactName,
    String? firebaseName,
    String? phoneNumber,
    String? profileImageUrl,
    GroupMemberRole? role,
  }) {
    return (update(groupMembersTable)
          ..where((t) => t.groupId.equals(groupId) & t.userId.equals(userId)))
        .write(GroupMembersTableCompanion(
      displayName: Value.absentIfNull(displayName),
      contactName: Value.absentIfNull(contactName),
      firebaseName: Value.absentIfNull(firebaseName),
      phoneNumber: Value.absentIfNull(phoneNumber),
      profileImageUrl: Value.absentIfNull(profileImageUrl),
      role: Value.absentIfNull(role),
    ));
  }

  // Update group member last seen
  Future<int> updateGroupMemberLastSeen(String groupId, String userId) {
    return (update(groupMembersTable)
          ..where((t) => t.groupId.equals(groupId) & t.userId.equals(userId)))
        .write(GroupMembersTableCompanion(
      lastSeenAt: Value(DateTime.now()),
    ));
  }

  // Delete group member
  Future<int> deleteGroupMember(String groupId, String userId) {
    return (delete(groupMembersTable)
          ..where((t) => t.groupId.equals(groupId) & t.userId.equals(userId)))
        .go();
  }

  // Delete all group members for a group
  Future<int> deleteAllGroupMembers(String groupId) {
    return (delete(groupMembersTable)..where((t) => t.groupId.equals(groupId))).go();
  }

  // Get group admins
  Future<List<GroupMemberData>> getGroupAdmins(String groupId) {
    return (select(groupMembersTable)
          ..where((t) => t.groupId.equals(groupId) & t.role.equals(GroupMemberRole.admin.index)))
        .get();
  }

  // Get groups where user is member (from members table)
  Future<List<GroupMemberData>> getUserGroupMemberships(String userId) {
    return (select(groupMembersTable)..where((t) => t.userId.equals(userId))).get();
  }

  // Count group members
  Future<int> countGroupMembers(String groupId) {
    final query = selectOnly(groupMembersTable)
      ..where(groupMembersTable.groupId.equals(groupId))
      ..addColumns([groupMembersTable.userId.count()]);
    return query.map((row) => row.read(groupMembersTable.userId.count()) ?? 0).getSingle();
  }

  // Get groups with pagination
  Future<List<GroupData>> getGroupsPaginated({
    required int limit,
    int? offset,
    String? orderBy = 'name',
    bool ascending = true,
  }) {
    var query = select(groupsTable);
    
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
    }
    
    // Add pagination
    query = query..limit(limit);
    if (offset != null && offset > 0) {
      query = query..limit(limit, offset: offset);
    }
    
    return query.get();
  }

  // Count total groups
  Future<int> countGroups() {
    final query = selectOnly(groupsTable)..addColumns([groupsTable.id.count()]);
    return query.map((row) => row.read(groupsTable.id.count()) ?? 0).getSingle();
  }

  // Clear all groups
  Future<int> clearAllGroups() {
    return delete(groupsTable).go();
  }

  // Clear all group members
  Future<int> clearAllGroupMembers() {
    return delete(groupMembersTable).go();
  }

  // Clear all data
  Future<void> clearAll() async {
    await clearAllGroupMembers();
    await clearAllGroups();
  }
}