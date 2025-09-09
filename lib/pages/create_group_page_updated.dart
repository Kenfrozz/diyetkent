import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/group_model.dart';
import '../database/drift_service.dart';
import '../services/ui_contacts_service.dart';

/// 🚀 GRUP OLUŞTURMA SAYFASI - OPTIMIZE EDİLMİŞ VERSİYON
/// 
/// Bu sayfa ContactsManager sistemi kullanarak:
/// ✅ Hızlı kişi seçimi
/// ✅ Multi-select özelliği
/// ✅ Arama desteği
/// ✅ Performanslı UI
class CreateGroupPageUpdated extends StatefulWidget {
  const CreateGroupPageUpdated({super.key});

  @override
  State<CreateGroupPageUpdated> createState() => _CreateGroupPageUpdatedState();
}

class _CreateGroupPageUpdatedState extends State<CreateGroupPageUpdated> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  
  List<ContactViewModel> _allContacts = [];
  List<ContactViewModel> _filteredContacts = [];
  final Set<String> _selectedUids = <String>{};
  bool _isLoading = true;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadContacts();
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _filteredContacts = _allContacts;
      });
    } else {
      _performSearch(query);
    }
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);

    try {
      final contacts = await UIContactsService.getContactsForGroup();
      
      if (mounted) {
        setState(() {
          _allContacts = contacts;
          _filteredContacts = contacts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kişiler yüklenirken hata: $e')),
        );
      }
    }
  }

  Future<void> _performSearch(String query) async {
    try {
      final results = await UIContactsService.getContactsForGroup(
        searchQuery: query,
        excludeUids: _selectedUids.toList(),
      );

      if (mounted) {
        setState(() {
          _filteredContacts = results;
        });
      }
    } catch (e) {
      debugPrint('❌ Grup arama hatası: $e');
    }
  }

  void _toggleContactSelection(ContactViewModel contact) {
    if (contact.uid == null) return;

    setState(() {
      if (_selectedUids.contains(contact.uid)) {
        _selectedUids.remove(contact.uid);
      } else {
        _selectedUids.add(contact.uid!);
      }
    });
  }

  Future<void> _createGroup() async {
    final groupName = _groupNameController.text.trim();
    
    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grup adı gerekli')),
      );
      return;
    }

    if (_selectedUids.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az 2 kişi seçmelisiniz')),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('Kullanıcı oturumu bulunamadı');

      // Seçilen kişilerin bilgilerini topla
      final selectedContacts = _allContacts
          .where((c) => _selectedUids.contains(c.uid))
          .toList();

      // GroupModel için basit üye listesi hazırla
      final memberUids = <String>[
        currentUser.uid, // Kendini ekle
        ...selectedContacts.map((c) => c.uid!), // Seçilen kişileri ekle
      ];
      
      final adminUids = <String>[
        currentUser.uid, // Sadece oluşturan admin
      ];

      // Grup oluştur
      final groupId = 'group_${DateTime.now().millisecondsSinceEpoch}_${currentUser.uid}';
      final group = GroupModel.create(
        groupId: groupId,
        name: groupName,
        description: '',
        members: memberUids,
        admins: adminUids,
        createdBy: currentUser.uid,
      );

      // Veritabanına kaydet
      await DriftService.saveGroupModel(group);

      // Başarı mesajı ve geri dön
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$groupName grubu oluşturuldu')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Grup oluşturulamadı: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Grup'),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isCreating || _selectedUids.isEmpty 
                ? null 
                : _createGroup,
            child: _isCreating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'OLUŞTUR',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Grup adı
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _groupNameController,
              decoration: const InputDecoration(
                labelText: 'Grup adı',
                hintText: 'Grup adını girin',
                border: OutlineInputBorder(),
              ),
              maxLength: 50,
            ),
          ),

          // Seçilen kişiler
          if (_selectedUids.isNotEmpty)
            Container(
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seçilen: ${_selectedUids.length} kişi',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedUids.length,
                      itemBuilder: (context, index) {
                        final uid = _selectedUids.elementAt(index);
                        final contact = _allContacts
                            .where((c) => c.uid == uid)
                            .isNotEmpty ? _allContacts.where((c) => c.uid == uid).first : null;
                        
                        if (contact == null) return const SizedBox();
                        
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: Chip(
                            avatar: CircleAvatar(
                              backgroundColor: Colors.teal,
                              child: Text(
                                contact.avatarText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            label: Text(
                              contact.displayName,
                              style: const TextStyle(fontSize: 12),
                            ),
                            onDeleted: () => _toggleContactSelection(contact),
                            deleteIconColor: Colors.red,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          // Arama çubuğu
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Kişi ara...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),

          // Kişi listesi
          Expanded(
            child: _buildContactsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsList() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Kişiler yükleniyor...'),
          ],
        ),
      );
    }

    if (_filteredContacts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.contacts, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Kişi bulunamadı'),
            SizedBox(height: 8),
            Text(
              'Sadece kayıtlı kullanıcılar gösterilir',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredContacts.length,
      itemBuilder: (context, index) {
        return _buildContactTile(_filteredContacts[index]);
      },
    );
  }

  Widget _buildContactTile(ContactViewModel contact) {
    final isSelected = _selectedUids.contains(contact.uid);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isSelected ? Colors.teal : Colors.grey,
          backgroundImage: contact.profileImageUrl != null
              ? NetworkImage(contact.profileImageUrl!)
              : null,
          child: contact.profileImageUrl == null
              ? Text(
                  contact.avatarText,
                  style: const TextStyle(color: Colors.white),
                )
              : null,
        ),
        title: Row(
          children: [
            Expanded(child: Text(contact.displayName)),
            if (contact.isOnline)
              const Icon(
                Icons.circle,
                size: 8,
                color: Colors.green,
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(contact.phoneNumber),
            Text(
              contact.onlineStatusText,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Colors.teal)
            : const Icon(Icons.add_circle_outline, color: Colors.grey),
        onTap: () => _toggleContactSelection(contact),
        selected: isSelected,
        selectedTileColor: Colors.teal.withValues(alpha: 0.1),
      ),
    );
  }
}