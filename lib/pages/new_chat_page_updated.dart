import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/chat_model.dart';
import '../database/drift_service.dart';
import '../services/ui_contacts_service.dart';
import 'chat_page.dart';

/// 🚀 YENİ SOHBET SAYFASI - OPTIMIZE EDİLMİŞ VERSİYON
/// 
/// Bu sayfa ContactsManager sistemi kullanarak:
/// ✅ Hızlı yükleme (Isar cache)
/// ✅ Arkaplan senkronizasyon
/// ✅ Performanslı arama
/// ✅ UI responsiveness
class NewChatPageUpdated extends StatefulWidget {
  const NewChatPageUpdated({super.key});

  @override
  State<NewChatPageUpdated> createState() => _NewChatPageUpdatedState();
}

class _NewChatPageUpdatedState extends State<NewChatPageUpdated>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<ContactViewModel> _allUsers = [];
  List<ContactViewModel> _filteredUsers = [];
  bool _isLoading = true;
  late TabController _tabController;
  
  // Senkronizasyon durumu
  String? _syncStatus;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
    _tabController.addListener(_onTabChanged);
    _searchController.addListener(_onSearchChanged);
    
    // Senkronizasyon olaylarını dinle
    _listenToSyncEvents();
    
    // İlk yükleme
    _loadContacts();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _loadContacts();
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _filteredUsers = _allUsers;
      });
    } else {
      _performSearch(query);
    }
  }

  void _listenToSyncEvents() {
    UIContactsService.syncEventStream.listen((event) {
      if (!mounted) return;
      
      setState(() {
        _isSyncing = !event.isCompleted;
        if (event.hasError) {
          _syncStatus = 'Hata: ${event.error}';
        } else if (event.isCompleted) {
          _syncStatus = event.message;
          // Senkronizasyon tamamlandığında yeniden yükle
          _loadContacts();
        } else {
          _syncStatus = event.message;
        }
      });
    });
  }

  Future<void> _loadContacts() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);

    try {
      List<ContactViewModel> contacts;
      
      if (_tabController.index == 0) {
        // Kayıtlı kişiler (Rehber)
        contacts = await UIContactsService.getContactsForNewChat(
          limit: 500,
        );
      } else {
        // Tüm kişiler (arama yaparken dolacak)
        contacts = [];
      }

      if (mounted) {
        setState(() {
          _allUsers = contacts;
          _filteredUsers = contacts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _syncStatus = 'Yükleme hatası: $e';
        });
      }
    }
  }

  Future<void> _performSearch(String query) async {
    try {
      List<ContactViewModel> results;
      
      if (_tabController.index == 0) {
        // Kayıtlı kişilerde ara
        results = await UIContactsService.getContactsForNewChat(
          searchQuery: query,
          limit: 100,
        );
      } else {
        // Tüm kişilerde ara
        results = await UIContactsService.searchAllContacts(query);
      }

      if (mounted) {
        setState(() {
          _filteredUsers = results;
        });
      }
    } catch (e) {
      debugPrint('❌ Arama hatası: $e');
    }
  }

  Future<void> _refreshContacts() async {
    setState(() {
      _syncStatus = 'Yenileniyor...';
      _isSyncing = true;
    });
    
    await UIContactsService.refreshContacts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Sohbet'),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Rehber'),
            Tab(text: 'Tümü'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isSyncing ? Icons.sync : Icons.refresh),
            onPressed: _isSyncing ? null : _refreshContacts,
          ),
        ],
      ),
      body: Column(
        children: [
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
          
          // Senkronizasyon durumu
          if (_syncStatus != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: _isSyncing ? Colors.blue[50] : Colors.green[50],
              child: Row(
                children: [
                  if (_isSyncing)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _syncStatus!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
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

    if (_filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _tabController.index == 0 ? Icons.contacts : Icons.search,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _tabController.index == 0 
                  ? 'Henüz kayıtlı kişi bulunamadı' 
                  : 'Arama yapın',
            ),
            const SizedBox(height: 8),
            const Text(
              'Rehber senkronizasyonu arkaplanda devam ediyor',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        return _buildContactTile(_filteredUsers[index]);
      },
    );
  }

  Widget _buildContactTile(ContactViewModel contact) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: contact.isRegistered ? Colors.teal : Colors.grey,
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
            if (contact.isRegistered)
              Text(
                contact.onlineStatusText,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
          ],
        ),
        trailing: contact.isRegistered
            ? const Icon(Icons.message, color: Colors.teal)
            : const Icon(Icons.person_add, color: Colors.grey),
        onTap: () => _onContactTap(contact),
      ),
    );
  }

  Future<void> _onContactTap(ContactViewModel contact) async {
    if (!contact.canChat) {
      // Kayıtsız kullanıcı için davet gönder
      _showInviteDialog(contact);
      return;
    }

    // UID kontrolü
    if (contact.uid == null || contact.uid!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kullanıcı ID bulunamadı')),
        );
      }
      return;
    }

    try {
      // Yeni chat ID'yi oluştur (ChatModel ile aynı algoritma)
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;
      
      final ids = [currentUserId, contact.uid!];
      ids.sort();
      final expectedChatId = '${ids[0]}_${ids[1]}';
      
      // Bu chat ID'si ile mevcut chat'i kontrol et
      final existingChat = await DriftService.getChatById(expectedChatId);

      if (existingChat != null) {
        // Mevcut chat'i aç
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => ChatPage(chat: existingChat),
            ),
          );
        }
      } else {
        // Yeni chat oluştur
        final newChat = ChatModel.createPrivateChat(
          otherUserId: contact.uid!,
          otherUserName: contact.displayName,
          otherUserPhone: contact.phoneNumber,
          otherUserProfileImage: contact.profileImageUrl,
        );

        await DriftService.saveChat(newChat);

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => ChatPage(chat: newChat),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chat açılamadı: $e')),
        );
      }
    }
  }

  void _showInviteDialog(ContactViewModel contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Davet Gönder'),
        content: Text(
          '${contact.displayName} henüz uygulamayı kullanmıyor. '
          'Davet göndermek ister misiniz?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _sendInvite(contact);
            },
            child: const Text('Davet Gönder'),
          ),
        ],
      ),
    );
  }

  void _sendInvite(ContactViewModel contact) {
    // TODO: Davet gönderme işlemi
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${contact.displayName} kişisine davet gönderildi'),
      ),
    );
  }
}