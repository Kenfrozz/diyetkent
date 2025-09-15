import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'calls_page.dart';
import 'chat_list_page_new.dart';
import 'stories_page.dart';
import 'new_chat_page_updated.dart';
import 'voice_call_page.dart';
import '../services/contacts_service.dart';
import 'dart:async';
import '../services/test_data_service.dart';
import '../services/notification_service.dart';
import '../providers/optimized_chat_provider.dart';
import '../widgets/tag_selection_dialog.dart';
import '../widgets/appbar_health_indicators.dart';
import '../widgets/google_backup_widget.dart';
import 'profile_settings_page.dart';
import 'create_group_page_updated.dart';
// Removed dietitian_dashboard_page (dietitian panel removed)
import '../database/drift_service.dart';
import '../services/user_service.dart';
import '../models/message_model.dart';
import '../models/chat_model.dart';
// Removed user_role_model (dietitian panel removed)

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late TabController _tabController;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _incomingCallSub;
  final Set<String> _handledCallIds = <String>{};
  String? _currentUserRole; // User role system simplified (dietitian panel removed)

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);

    // NotificationService'i initialize et
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().initialize();
      _startIncomingCallListener();
    });

    _loadCurrentUserRole();
  }

  Future<void> _loadCurrentUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // User role system simplified (dietitian panel removed)
      final roleType = await UserService.getUserRole(user.uid);
      
      debugPrint('🔍 User role (simplified): $roleType');
      
      setState(() {
        _currentUserRole = roleType ?? 'user'; // Default to user role
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _incomingCallSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OptimizedChatProvider>(
      builder: (context, chatProvider, child) {
        return Scaffold(
          appBar: chatProvider.isSelectionMode && _tabController.index == 0
              ? _buildSelectionAppBar(chatProvider)
              : _buildNormalAppBar(),
          body: TabBarView(
            controller: _tabController,
            children: const [ChatListPageNew(), StoriesPage(), CallsPage()],
          ),
          floatingActionButton:
              chatProvider.isSelectionMode && _tabController.index == 0
                  ? null
                  : _buildFloatingActionButton(),
        );
      },
    );
  }

  void _startIncomingCallListener() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _incomingCallSub?.cancel();
    _incomingCallSub = FirebaseFirestore.instance
        .collection('calls')
        .where('calleeId', isEqualTo: uid)
        .where('status', isEqualTo: 'ringing')
        .snapshots()
        .listen((snapshot) async {
      if (!mounted) return;
      for (final doc in snapshot.docs) {
        final callId = doc.id;
        if (_handledCallIds.contains(callId)) continue;
        _handledCallIds.add(callId);
        String displayName = 'Gelen arama';
        final data = doc.data();
        final String? callerId = data['callerId'] as String?;
        if (callerId != null) {
          try {
            final name = await ContactsService.getContactNameByUid(callerId);
            if (name != null && name.isNotEmpty) displayName = name;
          } catch (_) {}
        }
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VoiceCallPage(
              otherUserName: displayName,
              callId: callId,
              isIncoming: true,
            ),
          ),
        );
      }
    });
  }

  // Normal AppBar
  PreferredSizeWidget _buildNormalAppBar() {
    return AppBar(
      title: const Text(
        'DiyetKent',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const _LocalSearchPage()),
            );
          },
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'new_group':
                _createGroupFromMenu();
                break;
              case 'test_data':
                _addTestData();
                break;
              case 'tags':
                _navigateToTags();
                break;
              case 'archived':
                _navigateToArchived();
                break;
              case 'profile':
                _navigateToProfile();
                break;
              case 'settings':
                _navigateToSettings();
                break;
              case 'logout':
                _showLogoutDialog();
                break;
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: 'new_group',
              child: Row(
                children: [
                  Icon(Icons.group_add, color: Colors.black54),
                  SizedBox(width: 12),
                  Text('Yeni grup'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'tags',
              child: Row(
                children: [
                  Icon(Icons.label_outline, color: Colors.black54),
                  SizedBox(width: 12),
                  Text('Etiketler'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'archived',
              child: Row(
                children: [
                  Icon(Icons.archive_outlined, color: Colors.black54),
                  SizedBox(width: 12),
                  Text('Arşivlenmiş Sohbetler'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.account_circle_outlined, color: Colors.black54),
                  SizedBox(width: 12),
                  Text('Profilim'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings_outlined, color: Colors.black54),
                  SizedBox(width: 12),
                  Text('Ayarlar'),
                ],
              ),
            ),
            // Diyetisyen paneli kaldırıldı (dietitian panel removed)
            const PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 120),
        child: Column(
          children: [
            // Sağlık göstergeleri
            const AppBarHealthIndicators(),
            // Backup durumu göstergesi
            const BackupStatusWidget(),
            // Tab bar
            TabBar(
              controller: _tabController,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              tabs: const [
                Tab(text: 'SOHBETLER'),
                Tab(text: 'DURUM'),
                Tab(text: 'ARAMALAR'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Seçim modu AppBar
  PreferredSizeWidget _buildSelectionAppBar(OptimizedChatProvider chatProvider) {
    // Durumları dinamik belirle
    final selectedIds = chatProvider.selectedChatIds.toSet();
    final selectedChats = chatProvider.chats
        .where((c) => selectedIds.contains(c.chatId))
        .toList();
    final allPinned =
        selectedChats.isNotEmpty && selectedChats.every((c) => c.isPinned);
    final allMuted =
        selectedChats.isNotEmpty && selectedChats.every((c) => c.isMuted);
    final anyUnread = selectedChats.any((c) => c.unreadCount > 0);

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => chatProvider.exitSelectionMode(),
      ),
      title: Text('${chatProvider.selectedCount} seçildi'),
      actions: [
        // Sabitleme
        IconButton(
          icon: Icon(allPinned ? Icons.push_pin_outlined : Icons.push_pin),
          onPressed: () => chatProvider.togglePinForSelected(),
          tooltip: allPinned ? 'Sabitlemeyi kaldır' : 'Sabitle',
        ),
        // Silme
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => _showDeleteConfirmation(chatProvider),
          tooltip: 'Sil',
        ),
        // Etiketleme
        IconButton(
          icon: const Icon(Icons.label),
          onPressed: () => _showTagDialog(chatProvider),
          tooltip: 'Etiketle',
        ),
        // Sessizle
        IconButton(
          icon: Icon(allMuted ? Icons.volume_up : Icons.volume_off),
          onPressed: () => chatProvider.toggleMuteForSelected(),
          tooltip: allMuted ? 'Sesi aç' : 'Sessize al',
        ),
        // Arşivle
        IconButton(
          icon: const Icon(Icons.archive),
          onPressed: () => chatProvider.toggleArchiveForSelected(),
          tooltip: 'Arşivle',
        ),
        // Daha fazla seçenek
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) =>
              _handleSelectionMenuAction(value, chatProvider),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'read_toggle',
              child: Row(
                children: [
                  Icon(
                    anyUnread ? Icons.mark_email_read : Icons.mark_email_unread,
                    color: Colors.black54,
                  ),
                  const SizedBox(width: 12),
                  Text(anyUnread ? 'Okundu işaretle' : 'Okunmadı işaretle'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'block',
              child: Row(
                children: [
                  Icon(Icons.block, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Engelle'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'create_group',
              child: Row(
                children: [
                  Icon(Icons.group_add, color: Colors.black54),
                  SizedBox(width: 12),
                  Text('Grup oluştur'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, child) {
        // Sadece Sohbetler sekmesinde genel FAB göster, diğer sekmeler kendi FAB'ını yönetir
        if (_tabController.index == 0) {
          return FloatingActionButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => const NewChatPageUpdated()),
              );
            },
            backgroundColor: const Color(0xFF25D366),
            heroTag: 'new_chat',
            child: const Icon(Icons.chat, color: Colors.white),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  // Eski diyalog kaldırıldı; menüden doğrudan grup oluştur ekranı açılıyor

  Future<void> _createGroupFromMenu() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateGroupPageUpdated()),
    );
  }

  Future<void> _addTestData() async {
    try {
      await TestDataService.seedTestData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test kullanıcıları ve örnek sohbetler eklendi!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _navigateToTags() {
    Navigator.pushNamed(context, '/tags');
  }

  void _navigateToArchived() {
    Navigator.pushNamed(context, '/archived');
  }

  void _navigateToProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileSettingsPage()),
    );
  }

  void _navigateToSettings() {
    Navigator.pushNamed(context, '/settings');
  }


  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Çıkış yapmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _logout();
            },
            child: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    try {
      // Firebase Auth'dan çıkış yap
      await FirebaseAuth.instance.signOut();
      // AuthWrapper otomatik olarak LoginPage'e yönlendirecek
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Çıkış yapılırken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
      }
    }
  }

  // Seçim modu menü eylemlerini işle
  void _handleSelectionMenuAction(String action, OptimizedChatProvider chatProvider) {
    switch (action) {
      case 'read_toggle':
        {
          chatProvider.markSelectedAsRead();
        }
        break;
      case 'block':
        _showBlockConfirmation(chatProvider);
        break;
      case 'create_group':
        _createGroupFromSelected(chatProvider);
        break;
    }
  }

  // Silme onayı dialog'u
  void _showDeleteConfirmation(OptimizedChatProvider chatProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sohbetleri Sil'),
        content: Text(
          '${chatProvider.selectedCount} sohbeti silmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              chatProvider.deleteSelectedChats();
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Etiket dialog'u
  void _showTagDialog(OptimizedChatProvider chatProvider) async {
    // Seçili sohbetlerin mevcut etiketlerini al (kesişim)
    final selectedChats = <ChatModel>[];
    for (final id in chatProvider.selectedChatIds) {
      final chat = await DriftService.getChatById(id);
      if (chat != null) selectedChats.add(chat);
    }
    // Ortak etiketler ön-seçili gelsin
    final Set<String> common = selectedChats.isEmpty
        ? <String>{}
        : selectedChats
            .map((c) => c.tags.toSet())
            .reduce((a, b) => a.intersection(b));
    final List<String> currentTags = common.toList();

    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => TagSelectionDialog(
        selectedTagIds: currentTags,
        title: 'Etiket Ekle (${chatProvider.selectedCount} sohbet)',
        onTagsSelected: (selectedTagIds) {
          // Seçilenler set'iyle mevcutları kıyaslayıp ekleme/kaldırma yapalım
          final Set<String> selected = selectedTagIds.toSet();
          final Set<String> existingUnion =
              selectedChats.expand((c) => c.tags).toSet();
          // Ekle
          final toAdd = selected.difference(existingUnion).toList();
          for (final tagId in toAdd) {
            chatProvider.addTagToSelected(tagId);
          }
          // Kaldır: Ortak olanlardan ama seçilmeyenler
          final toRemove = common.difference(selected).toList();
          for (final tagId in toRemove) {
            chatProvider.removeTagFromSelected(tagId);
          }
        },
      ),
    );
  }

  // Engelleme onayı
  void _showBlockConfirmation(OptimizedChatProvider chatProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kişileri Engelle'),
        content: Text(
          '${chatProvider.selectedCount} kişiyi engellemek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Engelleme işlemi implement edilecek
              chatProvider.exitSelectionMode();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Engelleme özelliği yakında eklenecek'),
                ),
              );
            },
            child: const Text('Engelle', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Seçili sohbetlerden grup oluştur
  void _createGroupFromSelected(OptimizedChatProvider chatProvider) {
    final selectedIds = List<String>.from(chatProvider.selectedChatIds);
    chatProvider.exitSelectionMode();

    // Seçili sohbetlerdeki karşı kullanıcıların uid'lerini topla
    () async {
      final memberIds = <String>{};
      for (final chatId in selectedIds) {
        final chat = await DriftService.getChatById(chatId);
        if (chat == null) continue;
        if (chat.isGroup) continue; // yalnız bireysel sohbetlerden ekle
        final other = chat.otherUserId;
        if (other != null && other.isNotEmpty) memberIds.add(other);
      }
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const CreateGroupPageUpdated(
              // initialMemberIds özelliği kaldırıldı
              ),
        ),
      );
    }();
  }
}

class _LocalSearchPage extends StatefulWidget {
  const _LocalSearchPage();
  @override
  State<_LocalSearchPage> createState() => _LocalSearchPageState();
}

class _LocalSearchPageState extends State<_LocalSearchPage> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  bool _isSearching = false;
  List<ChatModel> _chatResults = [];
  List<MessageModel> _messageResults = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() {
        _chatResults = [];
        _messageResults = [];
      });
      return;
    }
    setState(() => _isSearching = true);
    try {
      // Basit local arama: isim, telefon, son mesaj, mesaj içerikleri
      final allChats = await DriftService.getAllChats();
      final chats = allChats.where((c) {
        bool hit = false;
        if ((c.otherUserContactName ?? '').toLowerCase().contains(q)) {
          hit = true;
        }
        if ((c.otherUserName ?? '').toLowerCase().contains(q)) {
          hit = true;
        }
        if ((c.otherUserPhoneNumber ?? '').toLowerCase().contains(q)) {
          hit = true;
        }
        if ((c.lastMessage ?? '').toLowerCase().contains(q)) {
          hit = true;
        }
        // Etiketlerde arama
        if (c.tags.any((t) => t.toLowerCase().contains(q))) {
          hit = true;
        }
        return hit;
      }).toList();

      // Mesaj içeriği araması: tüm mesajlardan filtrele (gerekirse optimize edilir)
      // Not: Büyük veri için indeks ve sayfalama eklenebilir
      final List<MessageModel> messages =
          await DriftService.searchMessagesByText(q);

      setState(() {
        _chatResults = chats;
        _messageResults = messages;
      });
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Sohbet, kişi, telefon veya içerik ara',
            border: InputBorder.none,
          ),
          onChanged: (v) {
            setState(() => _query = v);
          },
          onSubmitted: (_) => _search(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _search,
          ),
        ],
      ),
      body: _isSearching
          ? const Center(child: CircularProgressIndicator())
          : (_chatResults.isEmpty && _messageResults.isEmpty)
              ? const Center(child: Text('Sonuç bulunamadı'))
              : ListView(
                  children: [
                    if (_chatResults.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text('Sohbetler',
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                    ..._chatResults.map((c) => ListTile(
                          leading: const Icon(Icons.chat_bubble_outline),
                          title: Text(c.otherUserContactName?.isNotEmpty == true
                              ? c.otherUserContactName!
                              : (c.otherUserName ??
                                  c.otherUserPhoneNumber ??
                                  'Sohbet')),
                          subtitle: Text(c.lastMessage ?? ''),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/chat', arguments: c);
                          },
                        )),
                    if (_messageResults.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text('Mesajlar',
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                    ..._messageResults.map((m) => ListTile(
                          leading: const Icon(Icons.messenger_outline),
                          title: Text(m.content),
                          subtitle: Text('${m.type.name} • ${m.timestamp}'),
                          onTap: () async {
                            // İlgili sohbeti aç
                            final chat =
                                await DriftService.getChatById(m.chatId);
                            if (!context.mounted) return;
                            if (chat != null) {
                              Navigator.pop(context);
                              Navigator.pushNamed(context, '/chat',
                                  arguments: chat);
                            }
                          },
                        )),
                  ],
                ),
    );
  }
}
