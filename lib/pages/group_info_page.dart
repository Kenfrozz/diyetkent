import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/group_model.dart';
import '../providers/group_provider.dart';
import '../services/contacts_manager.dart';
import '../database/drift_service.dart';
import '../database/drift/database.dart';

class GroupInfoPage extends StatefulWidget {
  final String groupId;

  const GroupInfoPage({
    super.key,
    required this.groupId,
  });

  @override
  State<GroupInfoPage> createState() => _GroupInfoPageState();
}

class _GroupInfoPageState extends State<GroupInfoPage> {
  bool _isLoading = true;
  bool _isEditingName = false;
  bool _isEditingDescription = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGroupInfo();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadGroupInfo() async {
    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      await groupProvider.loadGroup(widget.groupId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Grup bilgileri yüklenemedi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Grup Bilgileri'),
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<GroupProvider>(
              builder: (context, groupProvider, child) {
                final groupData = groupProvider.currentGroup;
                if (groupData == null) {
                  return const Center(
                    child: Text('Grup bulunamadı'),
                  );
                }

                // Convert GroupData to GroupModel - use FutureBuilder
                return FutureBuilder<GroupModel?>(
                  future: DriftService.convertGroupModel(groupData),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (!snapshot.hasData || snapshot.data == null) {
                      return const Center(child: Text('Grup verisi yüklenemedi'));
                    }
                    
                    final group = snapshot.data!;
                    final members = groupProvider.currentGroupMembers;
                    final canEdit = groupProvider.canUserEditGroupInfo(widget.groupId);
                    final isAdmin = groupProvider.isUserAdmin(widget.groupId);

                    return RefreshIndicator(
                      onRefresh: _loadGroupInfo,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        children: [
                          // Grup Header
                          _buildGroupHeader(group, canEdit),
                          const SizedBox(height: 16),

                          // Grup Açıklaması
                          _buildGroupDescription(group, canEdit),
                          const SizedBox(height: 16),

                          // Grup İzinleri (Sadece adminler görebilir)
                          if (isAdmin) ...[
                            _buildGroupPermissions(group),
                            const SizedBox(height: 16),
                          ],

                          // Üyeler Bölümü
                          _buildMembersSection(group, members, isAdmin),

                          // Tehlikeli İşlemler (Sadece adminler)
                          if (isAdmin) ...[
                            const SizedBox(height: 16),
                            _buildDangerZone(group),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildGroupHeader(GroupModel group, bool canEdit) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profil Resmi
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[300],
              image: group.profileImageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(group.profileImageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: group.profileImageUrl == null
                ? Icon(
                    Icons.group,
                    size: 50,
                    color: Colors.grey[600],
                  )
                : null,
          ),
          const SizedBox(height: 16),

          // Grup Adı
          _isEditingName
              ? Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        autofocus: true,
                      ),
                    ),
                    IconButton(
                      onPressed: _saveGroupName,
                      icon: const Icon(Icons.check, color: Colors.green),
                    ),
                    IconButton(
                      onPressed: _cancelEditName,
                      icon: const Icon(Icons.close, color: Colors.red),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        group.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (canEdit) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _startEditName,
                        icon: const Icon(Icons.edit, size: 20),
                      ),
                    ],
                  ],
                ),

          const SizedBox(height: 8),
          Text(
            '${group.members.length} üye',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupDescription(GroupModel group, bool canEdit) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline),
              const SizedBox(width: 8),
              const Text(
                'Açıklama',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (canEdit)
                IconButton(
                  onPressed: _isEditingDescription
                      ? _saveGroupDescription
                      : _startEditDescription,
                  icon: Icon(_isEditingDescription ? Icons.check : Icons.edit),
                ),
              if (_isEditingDescription)
                IconButton(
                  onPressed: _cancelEditDescription,
                  icon: const Icon(Icons.close, color: Colors.red),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _isEditingDescription
              ? TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Grup açıklaması...',
                  ),
                )
              : Text(
                  group.description?.isNotEmpty == true
                      ? group.description!
                      : 'Açıklama eklenmemiş',
                  style: TextStyle(
                    color: group.description?.isNotEmpty == true
                        ? Colors.black87
                        : Colors.grey,
                    fontSize: 14,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildGroupPermissions(GroupModel group) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.admin_panel_settings),
              SizedBox(width: 8),
              Text(
                'Grup İzinleri',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Mesaj Gönderme İzni
          ListTile(
            title: const Text('Mesaj Gönderme'),
            subtitle: Text(
              group.messagePermission == GroupMessagePermission.everyone
                  ? 'Herkes mesaj gönderebilir'
                  : 'Sadece yöneticiler mesaj gönderebilir',
            ),
            trailing: Switch(
              value: group.messagePermission == GroupMessagePermission.everyone,
              onChanged: (value) => _updateMessagePermission(
                value
                    ? GroupMessagePermission.everyone
                    : GroupMessagePermission.adminsOnly,
              ),
            ),
          ),

          // Medya İndirme İzni
          ListTile(
            title: const Text('Medya İndirme'),
            subtitle: Text(
              group.mediaPermission == GroupMediaPermission.downloadable
                  ? 'Medya dosyaları indirilebilir'
                  : 'Medya sadece grupta görüntülenebilir',
            ),
            trailing: Switch(
              value: group.mediaPermission == GroupMediaPermission.downloadable,
              onChanged: (value) => _updateMediaPermission(
                value
                    ? GroupMediaPermission.downloadable
                    : GroupMediaPermission.viewOnly,
              ),
            ),
          ),

          // Üye Ekleme İzni
          ListTile(
            title: const Text('Üye Ekleme'),
            subtitle: Text(
              group.allowMembersToAddOthers
                  ? 'Üyeler başkalarını ekleyebilir'
                  : 'Sadece yöneticiler üye ekleyebilir',
            ),
            trailing: Switch(
              value: group.allowMembersToAddOthers,
              onChanged: _updateMemberAddPermission,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersSection(
    GroupModel group,
    List<GroupMemberData> members,
    bool isAdmin,
  ) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.people),
                const SizedBox(width: 8),
                Text(
                  'Üyeler (${members.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (isAdmin)
                  IconButton(
                    onPressed: _addNewMembers,
                    icon: const Icon(Icons.person_add),
                  ),
              ],
            ),
          ),

          // Üye Listesi
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              final isOwner = member.userId == group.createdBy;
              final isMemberAdmin = group.isAdmin(member.userId);

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: member.profileImageUrl != null
                      ? NetworkImage(member.profileImageUrl!)
                      : null,
                  child: member.profileImageUrl == null
                      ? Text(_getEffectiveDisplayName(member)[0].toUpperCase())
                      : null,
                ),
                title: Text(_getEffectiveDisplayName(member)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (member.phoneNumber != null) Text(member.phoneNumber!),
                    Row(
                      children: [
                        if (isOwner) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Kurucu',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        if (isMemberAdmin && !isOwner)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Yönetici',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                trailing:
                    isAdmin && !isOwner && member.userId != group.createdBy
                        ? PopupMenuButton<String>(
                            onSelected: (value) =>
                                _handleMemberAction(value, member),
                            itemBuilder: (context) => [
                              if (!isMemberAdmin)
                                const PopupMenuItem(
                                  value: 'make_admin',
                                  child: Text('Yönetici Yap'),
                                ),
                              if (isMemberAdmin)
                                const PopupMenuItem(
                                  value: 'remove_admin',
                                  child: Text('Yönetici Yetkisini Kaldır'),
                                ),
                              const PopupMenuItem(
                                value: 'remove',
                                child: Text(
                                  'Gruptan Çıkar',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          )
                        : null,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone(GroupModel group) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text(
                'Tehlikeli İşlemler',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.orange),
            title: const Text('Gruptan Ayrıl'),
            subtitle: const Text('Bu gruptan ayrılırsınız'),
            onTap: _leaveGroup,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text(
              'Grubu Sil',
              style: TextStyle(color: Colors.red),
            ),
            subtitle: const Text('Bu grup kalıcı olarak silinir'),
            onTap: _deleteGroup,
          ),
        ],
      ),
    );
  }

  // Edit Metodları
  void _startEditName() {
    final group =
        Provider.of<GroupProvider>(context, listen: false).currentGroup;
    if (group != null) {
      _nameController.text = group.name;
      setState(() => _isEditingName = true);
    }
  }

  void _cancelEditName() {
    setState(() => _isEditingName = false);
    _nameController.clear();
  }

  Future<void> _saveGroupName() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grup adı boş olamaz')),
      );
      return;
    }

    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      await groupProvider.updateGroupInfo(
        groupId: widget.groupId,
        name: _nameController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isEditingName = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grup adı güncellendi')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  void _startEditDescription() {
    final group =
        Provider.of<GroupProvider>(context, listen: false).currentGroup;
    if (group != null) {
      _descriptionController.text = group.description ?? '';
      setState(() => _isEditingDescription = true);
    }
  }

  void _cancelEditDescription() {
    setState(() => _isEditingDescription = false);
    _descriptionController.clear();
  }

  Future<void> _saveGroupDescription() async {
    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      await groupProvider.updateGroupInfo(
        groupId: widget.groupId,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
      );

      if (!mounted) return;
      setState(() => _isEditingDescription = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grup açıklaması güncellendi')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  // İzin Güncellemeleri
  Future<void> _updateMessagePermission(
      GroupMessagePermission permission) async {
    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      await groupProvider.updateGroupPermissions(
        groupId: widget.groupId,
        messagePermission: permission.toString(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mesaj izinleri güncellendi')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  Future<void> _updateMediaPermission(GroupMediaPermission permission) async {
    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      await groupProvider.updateGroupPermissions(
        groupId: widget.groupId,
        mediaPermission: permission.toString(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medya izinleri güncellendi')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  Future<void> _updateMemberAddPermission(bool allow) async {
    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      await groupProvider.updateGroupPermissions(
        groupId: widget.groupId,
        allowMembersToAddOthers: allow,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Üye ekleme izinleri güncellendi')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  // Üye İşlemleri
  Future<void> _addNewMembers() async {
    try {
      final contacts = await ContactsManager.getRegisteredContacts();
      if (!mounted) return;
      final group =
          Provider.of<GroupProvider>(context, listen: false).currentGroup;

      if (group == null) return;

      // Zaten üye olmayanları filtrele
      final availableContacts = contacts
          .where((contact) => contact.isRegistered && contact.registeredUid != null && !group.members.contains(contact.registeredUid!))
          .toList();

      if (availableContacts.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Eklenebilecek yeni üye yok')),
        );
        return;
      }

      final selectedUsers = await showDialog<List<String>>(
        context: context,
        builder: (context) => _AddMembersDialog(
          contacts: availableContacts.map((contact) => {
            'uid': contact.registeredUid,
            'name': contact.displayName ?? contact.contactName,
            'phone': contact.originalPhone ?? contact.normalizedPhone,
            'profileImageUrl': contact.profileImageUrl,
          }).toList(),
        ),
      );

      if (selectedUsers != null && selectedUsers.isNotEmpty) {
        if (!mounted) return;
        final groupProvider =
            Provider.of<GroupProvider>(context, listen: false);

        for (final userId in selectedUsers) {
          await groupProvider.addMemberToGroup(widget.groupId, userId);
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${selectedUsers.length} üye eklendi')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Üye ekleme hatası: $e')),
      );
    }
  }

  Future<void> _handleMemberAction(
      String action, GroupMemberData member) async {
    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);

      switch (action) {
        case 'make_admin':
          await groupProvider.makeUserAdmin(widget.groupId, member.userId);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('${_getEffectiveDisplayName(member)} yönetici yapıldı')),
          );
          break;

        case 'remove_admin':
          await groupProvider.removeAdminRole(widget.groupId, member.userId);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    '${_getEffectiveDisplayName(member)} artık yönetici değil')),
          );
          break;

        case 'remove':
          final confirmed = await _showConfirmDialog(
            'Üyeyi Çıkar',
            '${_getEffectiveDisplayName(member)} adlı kişiyi gruptan çıkarmak istediğinizden emin misiniz?',
          );

          if (confirmed) {
            await groupProvider.removeMemberFromGroup(
                widget.groupId, member.userId);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text('${_getEffectiveDisplayName(member)} gruptan çıkarıldı')),
            );
          }
          break;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İşlem hatası: $e')),
      );
    }
  }

  // Tehlikeli İşlemler
  Future<void> _leaveGroup() async {
    final confirmed = await _showConfirmDialog(
      'Gruptan Ayrıl',
      'Bu gruptan ayrılmak istediğinizden emin misiniz?',
    );

    if (confirmed) {
      if (!mounted) return;
      try {
        final groupProvider =
            Provider.of<GroupProvider>(context, listen: false);
        await groupProvider.leaveGroup(widget.groupId);

        if (!mounted) return;
        Navigator.of(context).pop(); // Grup sayfasını kapat
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gruptan ayrıldınız')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gruptan ayrılma hatası: $e')),
        );
      }
    }
  }

  Future<void> _deleteGroup() async {
    final confirmed = await _showConfirmDialog(
      'Grubu Sil',
      'Bu grubu kalıcı olarak silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
    );

    if (confirmed) {
      if (!mounted) return;
      try {
        final groupProvider =
            Provider.of<GroupProvider>(context, listen: false);
        await groupProvider.deleteGroup(widget.groupId);

        if (!mounted) return;
        Navigator.of(context).pop(); // Grup sayfasını kapat
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grup silindi')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Grup silme hatası: $e')),
        );
      }
    }
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Onayla',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Get the effective display name for a group member
  String _getEffectiveDisplayName(GroupMemberData member) {
    if (member.contactName != null && member.contactName!.isNotEmpty) {
      return member.contactName!;
    } else if (member.displayName != null && member.displayName!.isNotEmpty) {
      return member.displayName!;
    } else if (member.firebaseName != null && member.firebaseName!.isNotEmpty) {
      return member.firebaseName!;
    } else if (member.phoneNumber != null && member.phoneNumber!.isNotEmpty) {
      return member.phoneNumber!;
    } else {
      return 'Bilinmeyen Kullanıcı';
    }
  }
}

// Üye Ekleme Dialog'u
class _AddMembersDialog extends StatefulWidget {
  final List<Map<String, dynamic>> contacts;

  const _AddMembersDialog({required this.contacts});

  @override
  State<_AddMembersDialog> createState() => _AddMembersDialogState();
}

class _AddMembersDialogState extends State<_AddMembersDialog> {
  Set<String> selectedUserIds = {};
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredContacts = widget.contacts.where((contact) {
      final name = (contact['displayName'] ?? '').toLowerCase();
      final phone = (contact['phoneNumber'] ?? '').toLowerCase();
      return name.contains(searchQuery.toLowerCase()) ||
          phone.contains(searchQuery.toLowerCase());
    }).toList();

    return AlertDialog(
      title: const Text('Üye Ekle'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            // Arama kutusu
            TextField(
              decoration: const InputDecoration(
                labelText: 'Kişi ara...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() => searchQuery = value);
              },
            ),
            const SizedBox(height: 16),

            // Seçili üye sayısı
            if (selectedUserIds.isNotEmpty)
              Text(
                '${selectedUserIds.length} kişi seçildi',
                style: Theme.of(context).textTheme.bodySmall,
              ),

            // Kişi listesi
            Expanded(
              child: ListView.builder(
                itemCount: filteredContacts.length,
                itemBuilder: (context, index) {
                  final contact = filteredContacts[index];
                  final userId = contact['uid'] ?? '';
                  final isSelected = selectedUserIds.contains(userId);

                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          selectedUserIds.add(userId);
                        } else {
                          selectedUserIds.remove(userId);
                        }
                      });
                    },
                    title: Text(contact['displayName'] ?? 'Bilinmeyen'),
                    subtitle: Text(contact['phoneNumber'] ?? ''),
                    secondary: CircleAvatar(
                      backgroundImage: contact['profileImageUrl'] != null
                          ? NetworkImage(contact['profileImageUrl'])
                          : null,
                      child: contact['profileImageUrl'] == null
                          ? Text(
                              (contact['displayName'] ?? 'U')[0].toUpperCase())
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        TextButton(
          onPressed: selectedUserIds.isEmpty
              ? null
              : () => Navigator.of(context).pop(selectedUserIds.toList()),
          child: const Text('Ekle'),
        ),
      ],
    );
  }
}
