import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Firestore doğrudan kullanılmıyor; listeleme Isar/Service üzerinden
import '../models/chat_model.dart';
import '../database/drift_service.dart';
import '../services/contacts_service.dart';
import '../services/people_service.dart';

import 'chat_page.dart';

class NewChatPage extends StatefulWidget {
  const NewChatPage({super.key});

  @override
  State<NewChatPage> createState() => _NewChatPageState();
}

class _NewChatPageState extends State<NewChatPage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = true;
  late TabController _tabController;
  bool _isFetching = false;
  int _lastLoadedIndex = -1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
    // Yalnızca gerçek indeks değişiminde 1 kez yükle
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      final idx = _tabController.index;
      if (!mounted || idx == _lastLoadedIndex) return;
      _lastLoadedIndex = idx;
      _loadUsers();
    });
    _lastLoadedIndex = _tabController.index;
    _loadUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterUsers);
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    if (_isFetching) return;
    _isFetching = true;
    try {
      if (!mounted) {
        _isFetching = false;
        return;
      }
      setState(() => _isLoading = true);

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        if (!mounted) {
          _isFetching = false;
          return;
        }
        setState(() {
          _isLoading = false;
          _allUsers = const [];
          _filteredUsers = const [];
        });
        _isFetching = false;
        return;
      }

      List<Map<String, dynamic>> users = [];

      // 🚀 Optimize edilmiş sekmeye göre yükleme
      if (_tabController.index == 0) {
        // Hızlı: kayıtlı kişileri getir (progressive loading)
        debugPrint('📱 Rehber kişileri yükleniyor (progressive)...');
        final directory = await PeopleService.getDirectoryProgressive(
          includeUnregistered: false,
          maxContacts: 1000, // Büyük rehberler için limit
        ).timeout(const Duration(seconds: 15),
            onTimeout: () => <Map<String, dynamic>>[]);
        users = directory
            .where((e) => e['uid'] != null && e['uid'] != currentUser.uid)
            .map((e) => {
                  'uid': e['uid'],
                  'displayName': e['displayName'],
                  'phoneNumber': e['phoneNumber'],
                  'photoURL': e['profileImageUrl'],
                  'lastSeen': e['lastSeen'],
                  'isOnline': e['isOnline'] ?? false,
                  'isRegistered': true,
                  'contactName': e['contactName'],
                })
            .take(500) // UI performansı için limit
            .toList();
      } else {
        // Tümü: 30k+ rehberlerde başlangıçta tümünü yüklemeyelim.
        // Kullanıcı aradıkça (>=2 karakter) hızlı arama ile doldurulacak.
        users = const [];
      }

      if (!mounted) {
        _isFetching = false;
        return;
      }
      setState(() {
        _allUsers = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Kullanıcılar yüklenemedi: $e')));
      }
    } finally {
      _isFetching = false;
      if (mounted && _isLoading) {
        // Her koşulda spinner takılmasın
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    // Büyük rehberlerde performans: eşik aşıldığında hızlı arama moduna geç
    if (query.length >= 2) {
      () async {
        final quick = await PeopleService.searchDirectoryQuick(
          query: query,
          includeUnregistered: true,
          limit: 500,
        );
        if (!mounted) return;
        setState(() {
          _filteredUsers = quick
              .map((e) => {
                    'uid': e['uid'],
                    'displayName': e['displayName'],
                    'phoneNumber': e['phoneNumber'],
                    'photoURL': e['profileImageUrl'],
                    'lastSeen': e['lastSeen'],
                    'isOnline': e['isOnline'] ?? false,
                    'isRegistered': e['isRegistered'] ?? false,
                    'contactName': e['contactName'],
                  })
              .toList();
        });
      }();
    } else {
      setState(() {
        _filteredUsers = _allUsers.where((user) {
          final name = (user['displayName'] as String? ?? '').toLowerCase();
          final contactName =
              (user['contactName'] as String? ?? '').toLowerCase();
          final phone = (user['phoneNumber'] as String? ?? '').toLowerCase();
          return name.contains(query) ||
              contactName.contains(query) ||
              phone.contains(query);
        }).toList();
      });
    }
  }

  String _getUserDisplayName(Map<String, dynamic> user) {
    // Eğer rehber ismi varsa onu göster
    if (user['contactName'] != null &&
        user['contactName'].toString().isNotEmpty) {
      return user['contactName'];
    }

    // Rehber ismi yoksa telefon numarasını göster
    if (user['phoneNumber'] != null &&
        user['phoneNumber'].toString().isNotEmpty) {
      return user['phoneNumber'];
    }

    // Son çare olarak Firebase ismini göster
    return user['displayName'] ?? 'Bilinmeyen Kullanıcı';
  }

  Future<void> _startChat(Map<String, dynamic> user) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Kayıtlı olmayan kullanıcı ise davet et
      if (user['isRegistered'] != true ||
          user['uid'] == null ||
          user['uid'].toString().isEmpty) {
        _showInviteDialog(
          user['phoneNumber'] ?? '',
          user['displayName'] ?? 'Bilinmeyen',
        );
        return;
      }

      // Chat ID oluştur (iki kullanıcı ID'sini sıralayarak)
      final userIds = [currentUser.uid, user['uid'] as String];
      userIds.sort();
      final chatId = userIds.join('_');

      // Mevcut chat'i kontrol et
      ChatModel? existingChat = await DriftService.getChatById(chatId);

      ChatModel chatForPage;
      if (existingChat != null) {
        // Mevcut chat varsa rehber ismini güncelle
        if (user['contactName'] != null &&
            existingChat.otherUserContactName != user['contactName']) {
          existingChat.otherUserContactName = user['contactName'] as String?;
          await DriftService.updateChatModel(existingChat);
        }
        chatForPage = existingChat;
      } else {
        // HENÜZ SOHBET OLUŞTURMA: Yalnızca sayfaya geçirmek için geçici model
        chatForPage = ChatModel.create(
          chatId: chatId,
          otherUserId: user['uid'] as String,
          otherUserName: user['displayName'] as String,
          otherUserContactName: user['contactName'] as String?,
          otherUserPhoneNumber: user['phoneNumber'] as String?,
          lastMessage: '',
          lastMessageTime: null,
          isLastMessageFromMe: false,
          isLastMessageRead: true,
          unreadCount: 0,
          tags: [],
        );
        // Mesaj gönderimi sırasında "Sohbet bulunamadı" hatasını önlemek için yerelde kaydet
        await DriftService.saveChat(chatForPage);
      }

      // Chat sayfasına git (mesaj gönderilirse Firestore/Isar kendini oluşturur)
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ChatPage(chat: chatForPage),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sohbet başlatılamadı: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
        title: const Text('Yeni Sohbet'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'İsim veya telefon numarası ara...',
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.white24,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                hintStyle: const TextStyle(color: Colors.white70),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00796B)),
            )
          : _filteredUsers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline,
                          size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _isLoading
                            ? 'Yükleniyor...'
                            : _searchController.text.isEmpty
                                ? (_tabController.index == 1
                                    ? 'Kişileri görmek için aramaya başlayın'
                                    : 'Henüz kayıtlı kullanıcı yok')
                                : 'Arama sonucu bulunamadı',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Arkadaşlarınızı DiyetKent\'e davet edin',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = _filteredUsers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF00796B),
                        backgroundImage: user['photoURL'] != null
                            ? NetworkImage(user['photoURL'])
                            : null,
                        child: user['photoURL'] == null
                            ? Text(
                                _getUserDisplayName(user).isNotEmpty
                                    ? _getUserDisplayName(user)[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      title: Text(
                        _getUserDisplayName(user),
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user['phoneNumber'] ?? '',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: user['isOnline'] == true
                                      ? Colors.green
                                      : Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                user['isOnline'] == true
                                    ? 'Çevrimiçi'
                                    : _formatLastSeen(user['lastSeen']),
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      onTap: () => _startChat(user),
                      trailing: const Icon(
                        Icons.chat_bubble_outline,
                        color: Color(0xFF00796B),
                      ),
                    );
                  },
                ),
      // Bu sayfada kendi FAB'ını göstermeyelim; ana sayfadaki FAB ile çakışmayı önle.
      floatingActionButton: null,
    );
  }

  String _formatLastSeen(dynamic lastSeen) {
    if (lastSeen == null) return 'Hiç görülmedi';

    DateTime lastSeenDate;
    if (lastSeen is Timestamp) {
      lastSeenDate = lastSeen.toDate();
    } else if (lastSeen is DateTime) {
      lastSeenDate = lastSeen;
    } else {
      return 'Bilinmeyor';
    }

    final now = DateTime.now();
    final difference = now.difference(lastSeenDate);

    if (difference.inMinutes < 1) {
      return 'Az önce';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dakika önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} saat önce';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return '${lastSeenDate.day}/${lastSeenDate.month}/${lastSeenDate.year}';
    }
  }

  void _showInviteDialog(String phoneNumber, String displayName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$displayName\'ı Davet Et'),
          content: Text(
            '$displayName henüz DiyetKent\'e kayıtlı değil. Onu uygulamaya davet etmek ister misiniz?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ContactsService.inviteContact(phoneNumber, displayName);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$displayName\'a davet gönderildi'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00796B),
                foregroundColor: Colors.white,
              ),
              child: const Text('Davet Et'),
            ),
          ],
        );
      },
    );
  }

  // Kaldırıldı: Davet FAB'ı bu sayfadan alındı; gereksiz dialog
}
