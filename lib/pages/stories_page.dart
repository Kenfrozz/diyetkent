import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../providers/story_provider.dart';
import '../widgets/story_creation_dialog.dart';
import '../services/story_service.dart';
import '../services/story_cleanup_service.dart';
import '../models/story_model.dart';

class StoriesPage extends StatefulWidget {
  const StoriesPage({super.key});

  @override
  State<StoriesPage> createState() => _StoriesPageState();
}

class _StoriesPageState extends State<StoriesPage> {
  static const String _prefsMutedKey = 'mutedStoryUserIds';
  final Set<String> _mutedUserIds = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StoryProvider>(context, listen: false).loadStories();
    });
    _loadMutedUsers();
  }

  Future<void> _loadMutedUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_prefsMutedKey) ?? <String>[];
      if (!mounted) return;
      setState(() {
        _mutedUserIds
          ..clear()
          ..addAll(list);
      });
    } catch (_) {}
  }

  Future<void> _toggleMute(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    if (_mutedUserIds.contains(userId)) {
      _mutedUserIds.remove(userId);
    } else {
      _mutedUserIds.add(userId);
    }
    await prefs.setStringList(_prefsMutedKey, _mutedUserIds.toList());
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Durumlar'),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
        actions: [
          // Debug modda temizleme butonu
          if (kDebugMode)
            PopupMenuButton<String>(
              icon: const Icon(Icons.cleaning_services),
              onSelected: (value) async {
                if (value == 'delete_all') {
                  await _deleteAllStories();
                } else if (value == 'cleanup_duplicates') {
                  await _cleanupDuplicateStories();
                } else if (value == 'cleanup_expired') {
                  await _cleanupExpiredStories();
                } else if (value == 'count') {
                  await _showStoryCount();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'count',
                  child: Text('Story Sayısı'),
                ),
                const PopupMenuItem(
                  value: 'cleanup_expired',
                  child: Text('Süresi Dolmuşları Sil'),
                ),
                const PopupMenuItem(
                  value: 'cleanup_duplicates',
                  child: Text('Duplicate Temizle'),
                ),
                const PopupMenuItem(
                  value: 'delete_all',
                  child: Text('HEPSİNİ SİL', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          IconButton(
            icon: const Icon(Icons.privacy_tip_outlined),
            onPressed: _showOptionsMenu,
            tooltip: 'Gizlilik',
          ),
        ],
      ),
      body: Consumer<StoryProvider>(
        builder: (context, storyProvider, child) {
          if (storyProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00796B)),
            );
          }

          final allStories = storyProvider.stories;
          if (allStories.isEmpty) {
            return _buildEmptyState();
          }

          final currentUid = FirebaseAuth.instance.currentUser?.uid;
          final grouped = _groupStoriesByUser(allStories);

          // Kendi dışındakileri üç gruba ayır: sessize alınmamış okunmamış, sessize alınmamış görüntülenen, sessize alınanlar
          final List<_UserStories> recent = [];
          final List<_UserStories> viewed = [];
          final List<_UserStories> muted = [];

          for (final entry in grouped.entries) {
            final userId = entry.key;
            if (userId == currentUid) continue;
            final stories = entry.value;
            final hasUnviewed = stories.any((s) => !s.isViewed);
            final container = _mutedUserIds.contains(userId)
                ? muted
                : (hasUnviewed ? recent : viewed);
            container.add(_UserStories(userId: userId, stories: stories));
          }

          // Sıralama: en yeniye göre
          int compareByLatest(_UserStories a, _UserStories b) =>
              b.stories.first.createdAt.compareTo(a.stories.first.createdAt);
          recent.sort(compareByLatest);
          viewed.sort(compareByLatest);
          muted.sort(compareByLatest);

          return RefreshIndicator(
            color: const Color(0xFF00796B),
            onRefresh: () async {
              await Provider.of<StoryProvider>(context, listen: false)
                  .loadStories();
            },
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 8),
                _buildMyStatusCard(storyProvider),
                const SizedBox(height: 8),
                if (recent.isNotEmpty) _buildSectionHeader('Son güncellemeler'),
                if (recent.isNotEmpty)
                  _buildHorizontalStrip(
                    recent,
                    onTap: (user) => _openStoryViewer(user.stories, 0),
                    onLongPress: (user) => _showUserOptions(user.userId),
                    showBadge: true,
                  ),
                if (viewed.isNotEmpty) _buildSectionHeader('Görüntülenenler'),
                if (viewed.isNotEmpty)
                  ...viewed.map(
                    (u) => _buildVerticalTile(
                      u,
                      onTap: () => _openStoryViewer(u.stories, 0),
                      onLongPress: () => _showUserOptions(u.userId),
                    ),
                  ),
                if (muted.isNotEmpty) _buildSectionHeader('Sessize alınanlar'),
                if (muted.isNotEmpty)
                  ...muted.map(
                    (u) => _buildVerticalTile(
                      u,
                      dimmed: true,
                      onTap: () => _openStoryViewer(u.stories, 0),
                      onLongPress: () => _showUserOptions(u.userId),
                    ),
                  ),
                const SizedBox(height: 96),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showStoryCreationDialog,
        backgroundColor: const Color(0xFF25D366),
        icon: const Icon(Icons.camera_alt, color: Colors.white),
        label: const Text('Yeni durum', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildMyStatusCard(StoryProvider storyProvider) {
    final myStories = storyProvider.getMyStories();
    final hasStories = myStories.isNotEmpty;
    final currentUser = FirebaseAuth.instance.currentUser;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Stack(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: hasStories
                  ? const LinearGradient(colors: [
                      Color(0xFF25D366),
                      Color(0xFF128C7E),
                    ])
                  : null,
            ),
            padding: const EdgeInsets.all(2),
            child: CircleAvatar(
              backgroundColor: Colors.grey[300],
              backgroundImage: currentUser?.photoURL != null
                  ? NetworkImage(currentUser!.photoURL!)
                  : null,
              child: currentUser?.photoURL == null
                  ? const Icon(Icons.person, color: Colors.grey)
                  : null,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Color(0xFF25D366),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, size: 14, color: Colors.white),
            ),
          ),
        ],
      ),
      title:
          const Text('Durumum', style: TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(hasStories ? 'Dokunarak görüntüle' : 'Durum ekle'),
      onTap: hasStories
          ? () => _openStoryViewer(myStories, 0)
          : _showStoryCreationDialog,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Henüz hiç durum yok',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'İlk durumunu oluşturmak için + butonuna dokun',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Map<String, List<StoryModel>> _groupStoriesByUser(
    List<StoryModel> stories,
  ) {
    final Map<String, List<StoryModel>> map = <String, List<StoryModel>>{};
    for (final s in stories.where((e) => e.isActive)) {
      map.putIfAbsent(s.userId, () => <StoryModel>[]).add(s);
    }
    for (final list in map.values) {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return map;
  }

  void _showStoryCreationDialog() {
    showDialog(
      context: context,
      builder: (context) => const StoryCreationDialog(),
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Durum Gizliliği'),
              onTap: () {
                Navigator.pop(context);
                _showPrivacySettings();
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Durum Hakkında'),
              onTap: () {
                Navigator.pop(context);
                _showStoryInfo();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacySettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        String mode = 'contacts';
        final Set<String> allowed = <String>{};
        final Set<String> excluded = <String>{};
        return StatefulBuilder(builder: (context, setState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Durum Gizliliği',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  RadioListTile<String>(
                    value: 'contacts',
                    groupValue: mode,
                    title: const Text('Rehberimdeki kişiler'),
                    onChanged: (v) => setState(() => mode = v!),
                  ),
                  RadioListTile<String>(
                    value: 'only',
                    groupValue: mode,
                    title: const Text('Sadece şu kişiler'),
                    subtitle:
                        const Text('Seçilen kişiler durumunuzu görebilir'),
                    onChanged: (v) => setState(() => mode = v!),
                  ),
                  RadioListTile<String>(
                    value: 'except',
                    groupValue: mode,
                    title: const Text('Şu kişiler hariç'),
                    subtitle: const Text('Seçilen kişiler durumunuzu göremez'),
                    onChanged: (v) => setState(() => mode = v!),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: mode == 'only'
                              ? () async {
                                  final ids = await _pickContacts();
                                  setState(() {
                                    allowed
                                      ..clear()
                                      ..addAll(ids);
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.person_add),
                          label: Text(allowed.isEmpty
                              ? 'Kişi seç'
                              : 'Seçili: ${allowed.length}'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: mode == 'except'
                              ? () async {
                                  final ids = await _pickContacts();
                                  setState(() {
                                    excluded
                                      ..clear()
                                      ..addAll(ids);
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.person_off),
                          label: Text(excluded.isEmpty
                              ? 'Hariç tut'
                              : 'Hariç: ${excluded.length}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('İptal'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await StoryService.savePrivacySettings(
                              mode: mode,
                              allowedIds: allowed.toList(),
                              excludedIds: excluded.toList(),
                            );
                            if (context.mounted) Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00796B),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Kaydet'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Future<List<String>> _pickContacts() async {
    // TODO: Rehber seçim ekranı eklenebilir. Şimdilik boş liste döndür.
    return <String>[];
  }

  void _showStoryInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Durum Hakkında'),
        content: const Text(
          'Durumlar 24 saat sonra otomatik olarak silinir. '
          'Sadece rehberinizde bulunan kişiler durumlarınızı görebilir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _openStoryViewer(List<StoryModel> stories, int initialIndex) {
    Navigator.pushNamed(
      context,
      '/story-viewer',
      arguments: {'stories': stories, 'initialIndex': initialIndex},
    );
  }

  // Bölüm başlığı
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          letterSpacing: .2,
          color: Colors.black54,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Yatay şerit
  Widget _buildHorizontalStrip(
    List<_UserStories> users, {
    required void Function(_UserStories) onTap,
    void Function(_UserStories)? onLongPress,
    bool showBadge = false,
  }) {
    return SizedBox(
      height: 98,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: users.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final u = users[index];
          final latest = u.stories.first;
          final hasUnviewed = u.stories.any((s) => !s.isViewed);
          return GestureDetector(
            onTap: () => onTap(u),
            onLongPress: onLongPress != null ? () => onLongPress(u) : null,
            child: Column(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: hasUnviewed
                        ? const SweepGradient(colors: [
                            Color(0xFF25D366),
                            Color(0xFF128C7E),
                            Color(0xFF25D366),
                          ])
                        : null,
                  ),
                  padding: const EdgeInsets.all(3),
                  child: CircleAvatar(
                    backgroundColor: Colors.grey[300],
                    backgroundImage: (latest.userProfileImage).isNotEmpty
                        ? NetworkImage(latest.userProfileImage)
                        : null,
                    child: (latest.userProfileImage).isEmpty
                        ? const Icon(Icons.person, color: Colors.grey)
                        : null,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 72,
                  child: Text(
                    latest.userName.isNotEmpty ? latest.userName : 'Kullanıcı',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Dikey liste öğesi
  Widget _buildVerticalTile(
    _UserStories user, {
    bool dimmed = false,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    final latest = user.stories.first;
    final hasUnviewed = user.stories.any((s) => !s.isViewed);
    return ListTile(
      onTap: onTap,
      onLongPress: onLongPress,
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: hasUnviewed
              ? const LinearGradient(colors: [
                  Color(0xFF25D366),
                  Color(0xFF128C7E),
                ])
              : null,
        ),
        padding: const EdgeInsets.all(2),
        child: CircleAvatar(
          backgroundColor: Colors.grey[300],
          backgroundImage: latest.userProfileImage.isNotEmpty
              ? NetworkImage(latest.userProfileImage)
              : null,
          child: latest.userProfileImage.isEmpty
              ? const Icon(Icons.person, color: Colors.grey)
              : null,
        ),
      ),
      title: Text(
        latest.userName.isNotEmpty ? latest.userName : 'Kullanıcı',
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: dimmed ? Colors.black54 : null,
        ),
      ),
      subtitle: Text(
        latest.timeAgo,
        style: TextStyle(color: dimmed ? Colors.black45 : Colors.black54),
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'mute_toggle') {
            _toggleMute(user.userId);
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem<String>(
            value: 'mute_toggle',
            child: Text(
              _mutedUserIds.contains(user.userId)
                  ? 'Sessizden çıkar'
                  : 'Sessize al',
            ),
          ),
        ],
      ),
    );
  }

  void _showUserOptions(String userId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                _mutedUserIds.contains(userId)
                    ? Icons.volume_up
                    : Icons.volume_off,
              ),
              title: Text(
                _mutedUserIds.contains(userId)
                    ? 'Sessizden çıkar'
                    : 'Sessize al',
              ),
              onTap: () {
                Navigator.pop(context);
                _toggleMute(userId);
              },
            ),
          ],
        ),
      ),
    );
  }

  // DEBUG: Story cleanup method'ları
  Future<void> _showStoryCount() async {
    try {
      final count = await StoryCleanupService.getStoryCount();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Toplam Story Sayısı: $count')),
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

  Future<void> _deleteAllStories() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('TÜM STORYLERİ SİL'),
        content: const Text('Bu işlem GERİ ALINMAZ! Tüm storyler silinecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('SİL'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await StoryCleanupService.deleteAllStories();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tüm storyler silindi'), backgroundColor: Colors.green),
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
  }

  Future<void> _cleanupDuplicateStories() async {
    try {
      await StoryCleanupService.cleanupDuplicateStories();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Duplicate storyler temizlendi'), backgroundColor: Colors.green),
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

  Future<void> _cleanupExpiredStories() async {
    try {
      await StoryCleanupService.cleanupExpiredStories();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Süresi dolmuş storyler temizlendi'), backgroundColor: Colors.green),
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
}

class _UserStories {
  final String userId;
  final List<StoryModel> stories;
  _UserStories({required this.userId, required this.stories});
}
