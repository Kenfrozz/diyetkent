import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../database/drift_service.dart';
import '../database/drift/database.dart';
import '../database/drift/tables/groups_table.dart';
import 'dart:async';
import 'dart:convert';

class GroupProvider extends ChangeNotifier {
  List<GroupData> _groups = [];
  List<GroupMemberData> _currentGroupMembers = [];
  GroupData? _currentGroup;
  bool _isLoading = false;
  String _searchQuery = '';

  // Getters
  List<GroupData> get groups => _groups;
  List<GroupMemberData> get currentGroupMembers => _currentGroupMembers;
  GroupData? get currentGroup => _currentGroup;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Kullanıcının gruplarını yükle
  Future<void> loadUserGroups() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      _groups = await DriftService.getUserGroups(user.uid);
      debugPrint('🏠 ${_groups.length} grup yüklendi');
    } catch (e) {
      debugPrint('❌ Grup yükleme hatası: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Grup oluştur
  Future<GroupData?> createGroup({
    required String name,
    required List<String> memberIds,
    String? description,
    String? profileImageUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      _isLoading = true;
      notifyListeners();

      final group = await DriftService.createGroup(
        name: name,
        memberIds: memberIds,
        description: description,
        profileImageUrl: profileImageUrl,
        createdBy: user.uid,
      );

      // Yerel listeye ekle
      _groups.add(group);
      notifyListeners();

      debugPrint('✅ Grup oluşturuldu: ${group.name}');
      return group;
    } catch (e) {
      debugPrint('❌ Grup oluşturma hatası: $e');
      throw Exception('Grup oluşturulamadı: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Belirli bir grubu yükle
  Future<void> loadGroup(String groupId) async {
    try {
      _isLoading = true;
      notifyListeners();

      _currentGroup = await DriftService.getGroupById(groupId);
      if (_currentGroup != null) {
        await loadGroupMembers(groupId);
      }
    } catch (e) {
      debugPrint('❌ Grup yükleme hatası: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Grup üyelerini yükle
  Future<void> loadGroupMembers(String groupId) async {
    try {
      _currentGroupMembers = await DriftService.getGroupMembers(groupId);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Grup üyeleri yükleme hatası: $e');
    }
  }

  // Gruba üye ekle
  Future<void> addMemberToGroup(String groupId, String newMemberId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await DriftService.addMemberToGroup(groupId, newMemberId);

      // Mevcut grup üyelerini yenile
      if (_currentGroup?.groupId == groupId) {
        await loadGroupMembers(groupId);
      }

      // Grup listesini de yenile
      await loadUserGroups();

      notifyListeners();
      debugPrint('✅ Üye eklendi: $newMemberId -> $groupId');
    } catch (e) {
      debugPrint('❌ Üye ekleme hatası: $e');
      throw Exception('Üye eklenemedi: $e');
    }
  }

  // Gruptan üye çıkar
  Future<void> removeMemberFromGroup(
      String groupId, String memberToRemove) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await DriftService.removeMemberFromGroup(groupId, memberToRemove);

      // Mevcut grup üyelerini yenile
      if (_currentGroup?.groupId == groupId) {
        await loadGroupMembers(groupId);
      }

      // Grup listesini de yenile
      await loadUserGroups();

      notifyListeners();
      debugPrint('✅ Üye çıkarıldı: $memberToRemove <- $groupId');
    } catch (e) {
      debugPrint('❌ Üye çıkarma hatası: $e');
      throw Exception('Üye çıkarılamadı: $e');
    }
  }

  // Üyeyi admin yap
  Future<void> makeUserAdmin(String groupId, String targetUserId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await DriftService.makeUserAdmin(groupId, targetUserId);

      // Mevcut grup bilgilerini güncelle
      if (_currentGroup?.groupId == groupId) {
        await loadGroup(groupId);
      }

      // Grup listesini de yenile
      await loadUserGroups();

      notifyListeners();
      debugPrint('✅ Admin yapıldı: $targetUserId @ $groupId');
    } catch (e) {
      debugPrint('❌ Admin yapma hatası: $e');
      throw Exception('Admin yapılamadı: $e');
    }
  }

  // Admin yetkisini kaldır
  Future<void> removeAdminRole(String groupId, String targetUserId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await DriftService.removeAdminRole(groupId, targetUserId);

      // Mevcut grup bilgilerini güncelle
      if (_currentGroup?.groupId == groupId) {
        await loadGroup(groupId);
      }

      // Grup listesini de yenile
      await loadUserGroups();

      notifyListeners();
      debugPrint('✅ Admin yetkisi kaldırıldı: $targetUserId @ $groupId');
    } catch (e) {
      debugPrint('❌ Admin yetkisi kaldırma hatası: $e');
      throw Exception('Admin yetkisi kaldırılamadı: $e');
    }
  }

  // Grup bilgilerini güncelle
  Future<void> updateGroupInfo({
    required String groupId,
    String? name,
    String? description,
    String? profileImageUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await DriftService.updateGroupInfo(
        groupId: groupId,
        name: name,
        description: description,
        profileImageUrl: profileImageUrl,
      );

      // Mevcut grup bilgilerini güncelle
      if (_currentGroup?.groupId == groupId) {
        await loadGroup(groupId);
      }

      // Grup listesini de yenile
      await loadUserGroups();

      notifyListeners();
      debugPrint('✅ Grup bilgileri güncellendi: $groupId');
    } catch (e) {
      debugPrint('❌ Grup güncelleme hatası: $e');
      throw Exception('Grup güncellenemedi: $e');
    }
  }

  // Grup izinlerini güncelle
  Future<void> updateGroupPermissions({
    required String groupId,
    String? messagePermission,
    String? mediaPermission,
    bool? allowMembersToAddOthers,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await DriftService.updateGroupPermissions(
        groupId: groupId,
        messagePermission: messagePermission,
        mediaPermission: mediaPermission,
        allowMembersToAddOthers: allowMembersToAddOthers,
      );

      // Mevcut grup bilgilerini güncelle
      if (_currentGroup?.groupId == groupId) {
        await loadGroup(groupId);
      }

      // Grup listesini de yenile
      await loadUserGroups();

      notifyListeners();
      debugPrint('✅ Grup izinleri güncellendi: $groupId');
    } catch (e) {
      debugPrint('❌ Grup izin güncelleme hatası: $e');
      throw Exception('Grup izinleri güncellenemedi: $e');
    }
  }

  // Gruptan ayrıl
  Future<void> leaveGroup(String groupId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await DriftService.removeMemberFromGroup(groupId, user.uid);

      // Yerel listeden çıkar
      _groups.removeWhere((g) => g.groupId == groupId);

      // Mevcut grup bu ise temizle
      if (_currentGroup?.groupId == groupId) {
        _currentGroup = null;
        _currentGroupMembers.clear();
      }

      notifyListeners();
      debugPrint('✅ Gruptan ayrıldı: $groupId');
    } catch (e) {
      debugPrint('❌ Gruptan ayrılma hatası: $e');
      throw Exception('Gruptan ayrılınamadı: $e');
    }
  }

  // Grubu sil (sadece grup oluşturucu)
  Future<void> deleteGroup(String groupId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await DriftService.deleteGroup(groupId);

      // Yerel listeden çıkar
      _groups.removeWhere((g) => g.groupId == groupId);

      // Mevcut grup bu ise temizle
      if (_currentGroup?.groupId == groupId) {
        _currentGroup = null;
        _currentGroupMembers.clear();
      }

      notifyListeners();
      debugPrint('✅ Grup silindi: $groupId');
    } catch (e) {
      debugPrint('❌ Grup silme hatası: $e');
      throw Exception('Grup silinemedi: $e');
    }
  }

  // Grup arama
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Filtrelenmiş grupları getir
  List<GroupData> get filteredGroups {
    if (_searchQuery.isEmpty) return _groups;

    final lowerQuery = _searchQuery.toLowerCase();
    return _groups.where((group) {
      return group.name.toLowerCase().contains(lowerQuery) ||
          (group.description?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  // Kullanıcının admin olduğu grupları getir
  List<GroupData> get adminGroups {
    final user = _auth.currentUser;
    if (user == null) return [];

    return _groups.where((group) {
      // Parse admins from JSON string
      try {
        final admins = (json.decode(group.admins) as List).cast<String>();
        return admins.contains(user.uid);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  // Yetki kontrol metodları
  bool canUserSendMessage(String groupId) {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final group = _groups.firstWhere((g) => g.groupId == groupId);
      // Simple permission check - admins can always send, others depend on messagePermission
      if (isUserAdmin(groupId)) return true;
      return group.messagePermission == MessagePermission.everyone;
    } catch (e) {
      return false;
    }
  }

  bool canUserAddMembers(String groupId) {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final group = _groups.firstWhere((g) => g.groupId == groupId);
      // Simple permission check
      if (isUserAdmin(groupId)) return true;
      return group.allowMembersToAddOthers;
    } catch (e) {
      return false;
    }
  }

  bool canUserEditGroupInfo(String groupId) {
    // Only admins can edit group info
    return isUserAdmin(groupId);
  }

  bool isUserAdmin(String groupId) {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final group = _groups.firstWhere((g) => g.groupId == groupId);
      final admins = (json.decode(group.admins) as List).cast<String>();
      return admins.contains(user.uid);
    } catch (e) {
      return false;
    }
  }

  bool isUserMember(String groupId) {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final group = _groups.firstWhere((g) => g.groupId == groupId);
      final members = (json.decode(group.members) as List).cast<String>();
      return members.contains(user.uid);
    } catch (e) {
      return false;
    }
  }

  // Mevcut grubu temizle
  void clearCurrentGroup() {
    _currentGroup = null;
    _currentGroupMembers.clear();
    notifyListeners();
  }

  // Tüm verileri temizle
  void clear() {
    _groups.clear();
    _currentGroup = null;
    _currentGroupMembers.clear();
    _searchQuery = '';
    _isLoading = false;
    notifyListeners();
  }
}
