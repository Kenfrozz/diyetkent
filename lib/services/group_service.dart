import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/group_model.dart';
import '../models/chat_model.dart';
import '../database/drift_service.dart';
import '../services/contacts_service.dart';
import 'dart:async';

class GroupService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Grup oluştur
  static Future<GroupModel> createGroup({
    required String name,
    required List<String> memberIds,
    String? description,
    String? profileImageUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Kullanıcı giriş yapmamış');

    try {
      // Grup ID oluştur
      final groupId = _firestore.collection('groups').doc().id;

      // Oluşturanı üye listesine ekle (eğer yoksa)
      final allMembers = List<String>.from(memberIds);
      if (!allMembers.contains(user.uid)) {
        allMembers.add(user.uid);
      }

      // Grup model oluştur
      final group = GroupModel.create(
        groupId: groupId,
        name: name,
        createdBy: user.uid,
        description: description,
        profileImageUrl: profileImageUrl,
        members: allMembers,
        admins: [user.uid], // Oluşturan kişi otomatik admin
      );

      // Firestore'a kaydet
      await _firestore.collection('groups').doc(groupId).set(group.toMap());

      // Yerel veritabanına kaydet
      await DriftService.saveGroupModel(group);

      // Her üye için grup üye bilgisini oluştur ve kaydet
      await _createGroupMembersInfo(groupId, allMembers);

      // Grup için chat oluştur
      await _createGroupChat(group);

      debugPrint('✅ Grup oluşturuldu: $groupId - $name');
      return group;
    } catch (e) {
      debugPrint('❌ Grup oluşturma hatası: $e');
      throw Exception('Grup oluşturulamadı: $e');
    }
  }

  // Grup üyeleri bilgisini oluştur
  static Future<void> _createGroupMembersInfo(
    String groupId,
    List<String> memberIds,
  ) async {
    try {
      final batch = _firestore.batch();

      for (final memberId in memberIds) {
        // Üye bilgilerini Firebase'den al
        final userDoc =
            await _firestore.collection('users').doc(memberId).get();
        String? firebaseName;
        String? phoneNumber;
        String? profileImageUrl;

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          firebaseName = userData['name'] ?? userData['displayName'];
          phoneNumber = userData['phoneNumber'];
          profileImageUrl = userData['profileImageUrl'] ?? userData['photoURL'];
        }

        // Rehber ismini kontrol et
        String? contactName;
        if (phoneNumber != null) {
          contactName =
              await ContactsService.getContactNameByPhone(phoneNumber);
        }

        // Grup üye modeli oluştur
        final groupMember = GroupMemberModel.create(
          groupId: groupId,
          userId: memberId,
          firebaseName: firebaseName,
          contactName: contactName,
          phoneNumber: phoneNumber,
          profileImageUrl: profileImageUrl,
          role: GroupMemberRole.member,
        );

        // Firestore'a üye bilgisini kaydet
        final memberRef = _firestore
            .collection('groups')
            .doc(groupId)
            .collection('members')
            .doc(memberId);

        batch.set(memberRef, groupMember.toMap());

        // Yerel veritabanına kaydet - group members are stored in groups table
        // await DriftService.saveGroupMember(groupMember); // TODO: Implement group member saving
      }

      await batch.commit();
      debugPrint('✅ Grup üye bilgileri oluşturuldu');
    } catch (e) {
      debugPrint('❌ Grup üye bilgileri oluşturma hatası: $e');
    }
  }

  // Grup için chat oluştur
  static Future<void> _createGroupChat(GroupModel group) async {
    try {
      // Chat ID'yi grup ID ile aynı yap
      final chatId = group.groupId;

      // Grup chat modeli oluştur
      final groupChat = ChatModel.createGroup(
        chatId: chatId,
        groupId: group.groupId,
        groupName: group.name,
        groupImage: group.profileImageUrl,
        groupDescription: group.description,
        lastMessage: 'Grup oluşturuldu',
        lastMessageTime: DateTime.now(),
        isLastMessageFromMe: true,
      );

      // Firestore'a chat kaydet (timestamp alanlarını serverTimestamp ile yaz)
      final chatRef = _firestore.collection('chats').doc(chatId);
      await chatRef.set({
        'chatId': chatId,
        'isGroup': true,
        'groupId': group.groupId,
        'groupName': group.name,
        'groupImage': group.profileImageUrl,
        'groupDescription': group.description,
        'lastMessage': groupChat.lastMessage,
        'isLastMessageFromMe': true,
        'isLastMessageRead': true,
        'unreadCount': 0,
        'participants': group.members,
        'type': 'group',
        // Katılımcı adları: listeyi basitçe userId->ad olarak doldurmaya çalış
        'participantNames': {
          for (final uid in group.members)
            uid: await ContactsService.getContactNameByUid(uid) ?? uid,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessageTime': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Yerel veritabanına kaydet
      await DriftService.saveChat(groupChat);

      // Tüm üyeler için kişisel sohbet kaydı oluştur (chat listede görünsün)
      try {
        final batch = _firestore.batch();
        for (final uid in group.members) {
          final userChatRef = _firestore
              .collection('users')
              .doc(uid)
              .collection('userChats')
              .doc(chatId);
          batch.set(userChatRef, {
            'chatId': chatId,
            'type': 'group',
            'lastMessage': groupChat.lastMessage,
            'lastMessageTime': FieldValue.serverTimestamp(),
            'isArchived': false,
            'isMuted': false,
            'pinned': false,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
      } catch (e) {
        debugPrint('⚠️ Üyelere kullanıcı sohbet kaydı oluşturulamadı: $e');
      }

      // Grup oluşturuldu sistem mesajı ekle (üyelerin chat listesine düşmesi ve bildirim için)
      try {
        final user = _auth.currentUser;
        final messagesRef = _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .doc();
        await messagesRef.set({
          'messageId': messagesRef.id,
          'chatId': chatId,
          'senderId': user?.uid ?? group.createdBy,
          'text': 'Grup oluşturuldu',
          'type': 'text',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'isDelivered': false,
          'isEdited': false,
          'createdAt': FieldValue.serverTimestamp(),
          // group specific
          'isGroupMessage': true,
          'groupId': group.groupId,
          'groupMembers': group.members,
        });
      } catch (e) {
        debugPrint('⚠️ Grup başlangıç mesajı oluşturulamadı: $e');
      }

      debugPrint('✅ Grup chat\'i oluşturuldu: $chatId');
    } catch (e) {
      debugPrint('❌ Grup chat oluşturma hatası: $e');
    }
  }

  // Gruba üye ekle
  static Future<void> addMemberToGroup(
    String groupId,
    String userId,
    String newMemberId,
  ) async {
    try {
      // Yetki kontrol et
      final group = await getGroup(groupId);
      if (group == null) throw Exception('Grup bulunamadı');

      if (!group.canAddMembers(userId)) {
        throw Exception('Bu işlem için yetkiniz yok');
      }

      // Zaten üye mi kontrol et
      if (group.isMember(newMemberId)) {
        throw Exception('Kullanıcı zaten grup üyesi');
      }

      // Firebase'de grup üye listesini güncelle
      await _firestore.collection('groups').doc(groupId).update({
        'members': FieldValue.arrayUnion([newMemberId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Chat'teki participants listesini güncelle
      await _firestore.collection('chats').doc(groupId).update({
        'participants': FieldValue.arrayUnion([newMemberId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Yeni üye bilgisini oluştur
      await _createGroupMembersInfo(groupId, [newMemberId]);

      // Yerel grubu güncelle
      group.members.add(newMemberId);
      group.updatedAt = DateTime.now();
      await DriftService.updateGroupModel(group);

      debugPrint('✅ Üye gruba eklendi: $newMemberId -> $groupId');
    } catch (e) {
      debugPrint('❌ Üye ekleme hatası: $e');
      throw Exception('Üye eklenemedi: $e');
    }
  }

  // Gruptan üye çıkar
  static Future<void> removeMemberFromGroup(
    String groupId,
    String userId,
    String memberToRemove,
  ) async {
    try {
      // Yetki kontrol et
      final group = await getGroup(groupId);
      if (group == null) throw Exception('Grup bulunamadı');

      if (!group.isAdmin(userId) && userId != memberToRemove) {
        throw Exception('Bu işlem için yetkiniz yok');
      }

      // Grup oluşturucusunu çıkaramaz
      if (memberToRemove == group.createdBy) {
        throw Exception('Grup oluşturucusu çıkarılamaz');
      }

      // Firebase'de grup üye listesini güncelle
      await _firestore.collection('groups').doc(groupId).update({
        'members': FieldValue.arrayRemove([memberToRemove]),
        'admins': FieldValue.arrayRemove(
            [memberToRemove]), // Admin listesinden de çıkar
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Chat'teki participants listesini güncelle
      await _firestore.collection('chats').doc(groupId).update({
        'participants': FieldValue.arrayRemove([memberToRemove]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Üye bilgisini sil
      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('members')
          .doc(memberToRemove)
          .delete();

      // Yerel grubu güncelle
      group.members.remove(memberToRemove);
      group.admins.remove(memberToRemove);
      group.updatedAt = DateTime.now();
      await DriftService.updateGroupModel(group);

      // Yerel üye bilgisini sil
      // await DriftService.deleteGroupMember(groupId, memberToRemove); // TODO: Implement group member deletion

      debugPrint('✅ Üye gruptan çıkarıldı: $memberToRemove <- $groupId');
    } catch (e) {
      debugPrint('❌ Üye çıkarma hatası: $e');
      throw Exception('Üye çıkarılamadı: $e');
    }
  }

  // Üyeyi admin yap
  static Future<void> makeUserAdmin(
    String groupId,
    String userId,
    String targetUserId,
  ) async {
    try {
      // Yetki kontrol et
      final group = await getGroup(groupId);
      if (group == null) throw Exception('Grup bulunamadı');

      if (!group.isAdmin(userId)) {
        throw Exception('Bu işlem için yetkiniz yok');
      }

      if (!group.isMember(targetUserId)) {
        throw Exception('Kullanıcı grup üyesi değil');
      }

      if (group.isAdmin(targetUserId)) {
        throw Exception('Kullanıcı zaten admin');
      }

      // Firebase'de admin listesini güncelle
      await _firestore.collection('groups').doc(groupId).update({
        'admins': FieldValue.arrayUnion([targetUserId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Üye bilgisini güncelle
      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('members')
          .doc(targetUserId)
          .update({
        'role': GroupMemberRole.admin.name,
      });

      // Yerel grubu güncelle
      group.admins.add(targetUserId);
      group.updatedAt = DateTime.now();
      await DriftService.updateGroupModel(group);

      // Yerel üye bilgisini güncelle
      // final member = await DriftService.getGroupMember(groupId, targetUserId);
      // if (member != null) {
      //   member.role = GroupMemberRole.admin;
      //   await DriftService.updateGroupMember(member); // TODO: Implement group member updating
      // }

      debugPrint('✅ Kullanıcı admin yapıldı: $targetUserId @ $groupId');
    } catch (e) {
      debugPrint('❌ Admin yapma hatası: $e');
      throw Exception('Admin yapılamadı: $e');
    }
  }

  // Admin yetkisini kaldır
  static Future<void> removeAdminRole(
    String groupId,
    String userId,
    String targetUserId,
  ) async {
    try {
      // Yetki kontrol et
      final group = await getGroup(groupId);
      if (group == null) throw Exception('Grup bulunamadı');

      if (!group.isAdmin(userId)) {
        throw Exception('Bu işlem için yetkiniz yok');
      }

      // Grup oluşturucusunun admin yetkisi kaldırılamaz
      if (targetUserId == group.createdBy) {
        throw Exception('Grup oluşturucusunun admin yetkisi kaldırılamaz');
      }

      if (!group.isAdmin(targetUserId)) {
        throw Exception('Kullanıcı zaten admin değil');
      }

      // Firebase'de admin listesinden çıkar
      await _firestore.collection('groups').doc(groupId).update({
        'admins': FieldValue.arrayRemove([targetUserId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Üye bilgisini güncelle
      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('members')
          .doc(targetUserId)
          .update({
        'role': GroupMemberRole.member.name,
      });

      // Yerel grubu güncelle
      group.admins.remove(targetUserId);
      group.updatedAt = DateTime.now();
      await DriftService.updateGroupModel(group);

      // Yerel üye bilgisini güncelle
      // final member = await DriftService.getGroupMember(groupId, targetUserId);
      // if (member != null) {
      //   member.role = GroupMemberRole.member;
      //   await DriftService.updateGroupMember(member); // TODO: Implement group member updating
      // }

      debugPrint('✅ Admin yetkisi kaldırıldı: $targetUserId @ $groupId');
    } catch (e) {
      debugPrint('❌ Admin yetkisi kaldırma hatası: $e');
      throw Exception('Admin yetkisi kaldırılamadı: $e');
    }
  }

  // Grup bilgilerini güncelle
  static Future<void> updateGroupInfo({
    required String groupId,
    required String userId,
    String? name,
    String? description,
    String? profileImageUrl,
  }) async {
    try {
      // Yetki kontrol et
      final group = await getGroup(groupId);
      if (group == null) throw Exception('Grup bulunamadı');

      if (!group.canEditGroupInfo(userId)) {
        throw Exception('Bu işlem için yetkiniz yok');
      }

      // Güncelleme verisini hazırla
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (profileImageUrl != null) {
        updateData['profileImageUrl'] = profileImageUrl;
      }

      // Firebase'de güncelle
      await _firestore.collection('groups').doc(groupId).update(updateData);

      // Chat'i de güncelle
      final chatUpdateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (name != null) chatUpdateData['groupName'] = name;
      if (profileImageUrl != null) {
        chatUpdateData['groupImage'] = profileImageUrl;
      }
      if (description != null) chatUpdateData['groupDescription'] = description;

      if (chatUpdateData.length > 1) {
        // sadece updatedAt varsa güncelleme
        await _firestore
            .collection('chats')
            .doc(groupId)
            .update(chatUpdateData);
      }

      // Yerel grubu güncelle
      if (name != null) group.name = name;
      if (description != null) group.description = description;
      if (profileImageUrl != null) group.profileImageUrl = profileImageUrl;
      group.updatedAt = DateTime.now();
      await DriftService.updateGroupModel(group);

      // Yerel chat'i güncelle
      final chat = await DriftService.getChatById(groupId);
      if (chat != null) {
        if (name != null) chat.groupName = name;
        if (profileImageUrl != null) chat.groupImage = profileImageUrl;
        if (description != null) chat.groupDescription = description;
        chat.updatedAt = DateTime.now();
        await DriftService.updateChatModel(chat);
      }

      debugPrint('✅ Grup bilgileri güncellendi: $groupId');
    } catch (e) {
      debugPrint('❌ Grup güncelleme hatası: $e');
      throw Exception('Grup güncellenemedi: $e');
    }
  }

  // Grup izinlerini güncelle
  static Future<void> updateGroupPermissions({
    required String groupId,
    required String userId,
    GroupMessagePermission? messagePermission,
    GroupMediaPermission? mediaPermission,
    bool? allowMembersToAddOthers,
  }) async {
    try {
      // Yetki kontrol et
      final group = await getGroup(groupId);
      if (group == null) throw Exception('Grup bulunamadı');

      if (!group.isAdmin(userId)) {
        throw Exception('Bu işlem için yetkiniz yok');
      }

      // Güncelleme verisini hazırla
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (messagePermission != null) {
        updateData['messagePermission'] = messagePermission.name;
      }
      if (mediaPermission != null) {
        updateData['mediaPermission'] = mediaPermission.name;
      }
      if (allowMembersToAddOthers != null) {
        updateData['allowMembersToAddOthers'] = allowMembersToAddOthers;
      }

      // Firebase'de güncelle
      await _firestore.collection('groups').doc(groupId).update(updateData);

      // Yerel grubu güncelle
      if (messagePermission != null) {
        group.messagePermission = messagePermission;
      }
      if (mediaPermission != null) {
        group.mediaPermission = mediaPermission;
      }
      if (allowMembersToAddOthers != null) {
        group.allowMembersToAddOthers = allowMembersToAddOthers;
      }
      group.updatedAt = DateTime.now();
      await DriftService.updateGroupModel(group);

      debugPrint('✅ Grup izinleri güncellendi: $groupId');
    } catch (e) {
      debugPrint('❌ Grup izin güncelleme hatası: $e');
      throw Exception('Grup izinleri güncellenemedi: $e');
    }
  }

  // Grup bilgisini getir
  static Future<GroupModel?> getGroup(String groupId) async {
    try {
      // Önce yerel veritabanından dene
      final localGroup = await DriftService.getGroupModel(groupId);
      if (localGroup != null) return localGroup;

      // Yoksa Firebase'den al
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      if (!groupDoc.exists) return null;

      final group = GroupModel.fromMap(groupDoc.data()!);

      // Yerel veritabanına kaydet
      await DriftService.saveGroupModel(group);

      return group;
    } catch (e) {
      debugPrint('❌ Grup getirme hatası: $e');
      return null;
    }
  }

  // Grup üyelerini getir
  static Future<List<GroupMemberModel>> getGroupMembers(String groupId) async {
    try {
      // Önce yerel veritabanından dene
      final localMembers = await DriftService.getGroupMembers(groupId);
      // Convert GroupMemberData to GroupMemberModel if needed
      if (localMembers.isNotEmpty) {
        // TODO: Convert GroupMemberData to GroupMemberModel
        return <GroupMemberModel>[];
      }

      // Yoksa Firebase'den al
      final membersSnapshot = await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('members')
          .get();

      final members = <GroupMemberModel>[];
      for (final doc in membersSnapshot.docs) {
        final member = GroupMemberModel.fromMap(doc.data());
        members.add(member);

        // Yerel veritabanına kaydet
        // await DriftService.saveGroupMember(member); // TODO: Implement group member saving
      }

      return members;
    } catch (e) {
      debugPrint('❌ Grup üyeleri getirme hatası: $e');
      return [];
    }
  }

  // Kullanıcının üyesi olduğu grupları getir
  static Future<List<GroupModel>> getUserGroups(String userId) async {
    try {
      // Firebase'den kullanıcının üyesi olduğu grupları al
      final groupsSnapshot = await _firestore
          .collection('groups')
          .where('members', arrayContains: userId)
          .get();

      final groups = <GroupModel>[];
      for (final doc in groupsSnapshot.docs) {
        final group = GroupModel.fromMap(doc.data());
        groups.add(group);

        // Yerel veritabanına kaydet
        await DriftService.saveGroupModel(group);
      }

      return groups;
    } catch (e) {
      debugPrint('❌ Kullanıcı grupları getirme hatası: $e');
      return [];
    }
  }

  // Gruptan ayrıl
  static Future<void> leaveGroup(String groupId, String userId) async {
    try {
      final group = await getGroup(groupId);
      if (group == null) throw Exception('Grup bulunamadı');

      // Grup oluşturucusu gruptan ayrılamaz
      if (userId == group.createdBy) {
        throw Exception('Grup oluşturucusu gruptan ayrılamaz');
      }

      await removeMemberFromGroup(groupId, userId, userId);
      debugPrint('✅ Gruptan ayrıldı: $userId <- $groupId');
    } catch (e) {
      debugPrint('❌ Gruptan ayrılma hatası: $e');
      throw Exception('Gruptan ayrılınamadı: $e');
    }
  }

  // Grubu sil (sadece grup oluşturucu yapabilir)
  static Future<void> deleteGroup(String groupId, String userId) async {
    try {
      final group = await getGroup(groupId);
      if (group == null) throw Exception('Grup bulunamadı');

      // Sadece grup oluşturucu silebilir
      if (userId != group.createdBy) {
        throw Exception('Sadece grup oluşturucu grubu silebilir');
      }

      // Firebase'den sil
      await _firestore.collection('groups').doc(groupId).delete();
      await _firestore.collection('chats').doc(groupId).delete();

      // Yerel veritabanından sil
      await DriftService.deleteGroup(groupId);
      await DriftService.deleteChat(groupId);

      debugPrint('✅ Grup silindi: $groupId');
    } catch (e) {
      debugPrint('❌ Grup silme hatası: $e');
      throw Exception('Grup silinemedi: $e');
    }
  }
}
