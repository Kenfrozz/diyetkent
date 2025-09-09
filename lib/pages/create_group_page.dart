import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/group_provider.dart';
// ContactsService doğrudan kullanılmıyor, PeopleService üzerinden birleşik okuma yapılır
import '../services/people_service.dart';
import 'package:image_picker/image_picker.dart';
import '../services/media_service.dart';

class CreateGroupPage extends StatefulWidget {
  final List<String>? initialMemberIds;
  const CreateGroupPage({super.key, this.initialMemberIds});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allContacts = [];
  List<Map<String, dynamic>> _filteredContacts = [];
  final Set<String> _selectedUserIds = {};
  bool _isLoading = false;
  String? _groupImageUrl;

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _searchController.addListener(_filterContacts);
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);

    try {
      final directory = await PeopleService.getDirectory(
        includeUnregistered: false,
        contactReadLimit: 150,
        userLimit: 200,
      );
      _allContacts = directory
          .where((e) => e['uid'] != null)
          .map((e) => {
                'uid': e['uid'],
                'displayName': e['displayName'],
                'phoneNumber': e['phoneNumber'],
                'profileImageUrl': e['profileImageUrl'],
                'isRegistered': true,
              })
          .toList();
      _filteredContacts = List.from(_allContacts);

      // Ön seçim: dışarıdan verilen kullanıcıları işaretle
      final preset = widget.initialMemberIds ?? const <String>[];
      if (preset.isNotEmpty) {
        final presetSet = Set<String>.from(preset);
        for (final c in _allContacts) {
          final uid = (c['uid'] ?? '') as String;
          if (presetSet.contains(uid)) {
            _selectedUserIds.add(uid);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kişiler yüklenemedi: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredContacts = _allContacts.where((contact) {
        final name = (contact['displayName'] ?? '').toLowerCase();
        final phone = (contact['phoneNumber'] ?? '').toLowerCase();
        return name.contains(query) || phone.contains(query);
      }).toList();
    });
  }

  void _toggleContactSelection(String userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
      } else {
        _selectedUserIds.add(userId);
      }
    });
  }

  Future<void> _createGroup() async {
    if (_groupNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grup adı gerekli')),
      );
      return;
    }

    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az bir üye seçin')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);

      final group = await groupProvider.createGroup(
        name: _groupNameController.text.trim(),
        memberIds: _selectedUserIds.toList(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        profileImageUrl: _groupImageUrl,
      );

      if (group != null) {
        if (mounted) {
          Navigator.of(context).pop(group);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Grup "${group.name}" oluşturuldu')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Grup oluşturulamadı: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Grup'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createGroup,
            child: const Text(
              'OLUŞTUR',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Grup bilgileri
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Grup profil resmi seçimi
                      _GroupImagePicker(
                        imageUrl: _groupImageUrl,
                        onPick: (url) => setState(() => _groupImageUrl = url),
                        setLoading: (v) => setState(() => _isLoading = v),
                      ),
                      const SizedBox(height: 16),

                      // Grup adı
                      TextField(
                        controller: _groupNameController,
                        decoration: const InputDecoration(
                          labelText: 'Grup Adı',
                          border: OutlineInputBorder(),
                        ),
                        maxLength: 50,
                      ),
                      const SizedBox(height: 16),

                      // Grup açıklaması
                      TextField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Grup Açıklaması (İsteğe bağlı)',
                          border: OutlineInputBorder(),
                        ),
                        maxLength: 100,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),

                const Divider(),

                // Üye seçimi
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Üyeleri Seç (${_selectedUserIds.length} seçildi)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),

                      // Arama kutusu
                      TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          labelText: 'Kişi ara...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),

                // Kişi listesi
                Expanded(
                  child: ListView.builder(
                    itemCount: _filteredContacts.length,
                    itemBuilder: (context, index) {
                      final contact = _filteredContacts[index];
                      final userId = contact['uid'] ?? '';
                      final isSelected = _selectedUserIds.contains(userId);

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: contact['profileImageUrl'] != null
                              ? NetworkImage(contact['profileImageUrl'])
                              : null,
                          child: contact['profileImageUrl'] == null
                              ? Text(
                                  (contact['displayName'] ?? 'U')[0]
                                      .toUpperCase(),
                                )
                              : null,
                        ),
                        title: Text(contact['displayName'] ?? 'Bilinmeyen'),
                        subtitle: Text(contact['phoneNumber'] ?? ''),
                        trailing: Checkbox(
                          value: isSelected,
                          onChanged: (value) => _toggleContactSelection(userId),
                        ),
                        onTap: () => _toggleContactSelection(userId),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _GroupImagePicker extends StatelessWidget {
  final String? imageUrl;
  final ValueChanged<String?> onPick;
  final ValueChanged<bool> setLoading;
  const _GroupImagePicker({
    required this.imageUrl,
    required this.onPick,
    required this.setLoading,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        try {
          final picker = ImagePicker();
          final xfile = await picker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 70,
            maxWidth: 1024,
            maxHeight: 1024,
          );
          if (xfile == null) return;
          setLoading(true);
          final url = await MediaService().uploadImage(xfile, 'group_assets');
          onPick(url);
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Resim yüklenemedi: $e')),
          );
        } finally {
          setLoading(false);
        }
      },
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.grey[300],
            backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
                ? NetworkImage(imageUrl!)
                : null,
            child: (imageUrl == null || imageUrl!.isEmpty)
                ? Icon(Icons.group, size: 40, color: Colors.grey[600])
                : null,
          ),
          const CircleAvatar(
            radius: 14,
            backgroundColor: Colors.white,
            child:
                Icon(Icons.camera_alt, size: 16, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
