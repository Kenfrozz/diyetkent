import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_model.dart';
import '../providers/tag_provider.dart';
import '../widgets/chat_tile.dart';
import '../providers/optimized_chat_provider.dart';
import '../pages/create_group_page.dart';
// import '../database/drift_service.dart'; // Unused

class TagFilterDialogNew extends StatefulWidget {
  const TagFilterDialogNew({super.key});

  @override
  State<TagFilterDialogNew> createState() => _TagFilterDialogNewState();
}

class _TagFilterDialogNewState extends State<TagFilterDialogNew> {
  Set<String> selectedTagIds = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Etiketlere Göre Filtrele'),
      content: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxHeight: 400),
        child: Consumer<TagProvider>(
          builder: (context, tagProvider, child) {
            if (tagProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (tagProvider.allTags.isEmpty) {
              return const Center(
                child: Text('Henüz etiket yok'),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              itemCount: tagProvider.allTags.length,
              itemBuilder: (context, index) {
                final tag = tagProvider.allTags[index];
                final isSelected = selectedTagIds.contains(tag.tagId);
                final color = Color(
                  int.parse('0xFF${tag.color?.substring(1) ?? '2196F3'}'),
                );

                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        selectedTagIds.add(tag.tagId);
                      } else {
                        selectedTagIds.remove(tag.tagId);
                      }
                    });
                  },
                  title: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getIconData(tag.icon),
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tag.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      if (tag.usageCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${tag.usageCount}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  controlAffinity: ListTileControlAffinity.trailing,
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        if (selectedTagIds.isNotEmpty)
          TextButton(
            onPressed: () {
              setState(() {
                selectedTagIds.clear();
              });
            },
            child: const Text('Temizle'),
          ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(selectedTagIds.toList());
          },
          child: Text(selectedTagIds.isEmpty
              ? 'Tümünü Göster'
              : 'Filtrele (${selectedTagIds.length})'),
        ),
      ],
    );
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'work':
        return Icons.work;
      case 'family_restroom':
        return Icons.family_restroom;
      case 'people':
        return Icons.people;
      case 'star':
        return Icons.star;
      case 'school':
        return Icons.school;
      case 'sports_esports':
        return Icons.sports_esports;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'flight':
        return Icons.flight;
      case 'restaurant':
        return Icons.restaurant;
      case 'music_note':
        return Icons.music_note;
      case 'movie':
        return Icons.movie;
      case 'book':
        return Icons.book;
      case 'computer':
        return Icons.computer;
      case 'home':
        return Icons.home;
      case 'directions_car':
        return Icons.directions_car;
      case 'attach_money':
        return Icons.attach_money;
      case 'favorite':
        return Icons.favorite;
      default:
        return Icons.label;
    }
  }
}

class ChatListPageNew extends StatefulWidget {
  const ChatListPageNew({super.key});

  @override
  State<ChatListPageNew> createState() => _ChatListPageNewState();
}

class _ChatListPageNewState extends State<ChatListPageNew> {
  Set<String> _activeTagIds = <String>{};
  @override
  Widget build(BuildContext context) {
    return Consumer<OptimizedChatProvider>(
      builder: (context, chatProvider, child) {
        return Column(
          children: [
            // Filtreler (sadece normal modda göster)
            if (!chatProvider.isSelectionMode)
              _buildFilterSection(chatProvider),

            // Arşivlenmiş bölümü (sadece normal modda göster)
            if (!chatProvider.isSelectionMode)
              _buildArchivedSection(chatProvider),

            // Chat listesi
            Expanded(
              child: chatProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _getDisplayedChats(chatProvider).isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          itemCount: _getDisplayedChats(chatProvider).length,
                          itemBuilder: (context, index) {
                            final chat =
                                _getDisplayedChats(chatProvider)[index];
                            return ChatTile(
                              chat: chat,
                              onTap: () => _handleChatTap(chat, chatProvider),
                              onLongPress: () =>
                                  _handleChatLongPress(chat, chatProvider),
                              isSelected: chatProvider.isChatSelected(
                                chat.chatId,
                              ),
                              isSelectionMode: chatProvider.isSelectionMode,
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterSection(OptimizedChatProvider chatProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              'Tümü',
              ChatFilter.all,
              chatProvider.currentFilter == ChatFilter.all,
              chatProvider,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Okunmamış',
              ChatFilter.unread,
              chatProvider.currentFilter == ChatFilter.unread,
              chatProvider,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Gruplar',
              ChatFilter.groups,
              chatProvider.currentFilter == ChatFilter.groups,
              chatProvider,
            ),
            const SizedBox(width: 8),
            _buildTagFilterButton(chatProvider),
            // Grup filtresi aktifken yeni grup oluşturma butonu
            // Grup filtresine bağlı inline butonu kaldırıldı; app bar menüden kullanılacak
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    ChatFilter filter,
    bool isSelected,
    OptimizedChatProvider chatProvider,
  ) {
    return GestureDetector(
      onTap: () => chatProvider.setFilter(filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00796B) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildTagFilterButton(OptimizedChatProvider chatProvider) {
    return GestureDetector(
      onTap: () async {
        // Toggle davranışı: aktif etiket varsa kapat, yoksa seçim diyalogunu aç
        if (_activeTagIds.isNotEmpty) {
          setState(() => _activeTagIds.clear());
          return;
        }
        try {
          final tagProvider = Provider.of<TagProvider>(context, listen: false);
          if (tagProvider.allTags.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Filtrelemek için önce etiket oluşturun'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }
          final selected = await showDialog<List<String>>(
            context: context,
            builder: (context) => const TagFilterDialogNew(),
          );
          if (selected == null) return;
          setState(() => _activeTagIds = selected.toSet());
        } catch (e) {
          debugPrint('Tag filtering error: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Etiket filtreleme hatası: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _activeTagIds.isNotEmpty
              ? const Color(0xFF00796B)
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_alt,
              size: 16,
              color: _activeTagIds.isNotEmpty ? Colors.white : Colors.black87,
            ),
            const SizedBox(width: 6),
            Text(
              _activeTagIds.isNotEmpty
                  ? 'Etiketler (${_activeTagIds.length})'
                  : 'Etiketler',
              style: TextStyle(
                color: _activeTagIds.isNotEmpty ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // removed legacy clear button

  // removed inline create group button (moved to app bar menu)

  Widget _buildArchivedSection(OptimizedChatProvider chatProvider) {
    final archivedCount = chatProvider.archivedChats.length;
    if (archivedCount == 0) return const SizedBox.shrink();

    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/archived'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.archive_outlined, color: Colors.black54, size: 20),
            const SizedBox(width: 16),
            const Text(
              'Arşivlenmiş',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w400,
              ),
            ),
            const Spacer(),
            Text(
              archivedCount.toString(),
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_right,
              color: Colors.black54,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Consumer<OptimizedChatProvider>(
      builder: (context, chatProvider, child) {
        final isGroupFilter = chatProvider.currentFilter == ChatFilter.groups;

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isGroupFilter ? Icons.group : Icons.chat_bubble_outline,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                isGroupFilter
                    ? 'Henüz hiç grup sohbetiniz yok'
                    : 'Henüz hiç sohbetiniz yok',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                isGroupFilter
                    ? 'Yeni bir grup oluşturmak için aşağıdaki butona dokunun'
                    : 'Yeni bir sohbet başlatmak için + butonuna dokunun',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              if (isGroupFilter) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _createNewGroup,
                  icon: const Icon(Icons.group_add),
                  label: const Text('Yeni Grup Oluştur'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // Chat tap handler
  void _handleChatTap(ChatModel chat, OptimizedChatProvider chatProvider) {
    if (chatProvider.isSelectionMode) {
      // Seçim modundaysa chat'i seçime ekle/çıkar
      chatProvider.toggleChatSelection(chat.chatId);
    } else {
      // Normal modda sohbet sayfasına git
      _openChat(chat);
    }
  }

  // Chat long press handler
  void _handleChatLongPress(ChatModel chat, OptimizedChatProvider chatProvider) {
    if (chatProvider.isSelectionMode) {
      // Zaten seçim modundaysa normal seçim yap
      chatProvider.toggleChatSelection(chat.chatId);
    } else {
      // Seçim modunu başlat
      chatProvider.enterSelectionMode();
      chatProvider.toggleChatSelection(chat.chatId);
    }
  }

  void _openChat(ChatModel chat) {
    // Sohbet sayfasına git
    Navigator.pushNamed(context, '/chat', arguments: chat);
  }

  // Yeni grup oluştur
  Future<void> _createNewGroup() async {
    try {
      final result = await Navigator.push<dynamic>(
        context,
        MaterialPageRoute(
          builder: (context) => const CreateGroupPage(),
        ),
      );

      if (result != null && mounted) {
        // Grup oluşturulduysa Isar stream zaten güncelleyecek
        // Grup filtresine geç
        final cp = Provider.of<OptimizedChatProvider>(context, listen: false);
        cp.setFilter(ChatFilter.groups);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Grup başarıyla oluşturuldu'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Grup oluşturulurken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Etkin filtrelere göre gösterilecek sohbetler
  List<ChatModel> _getDisplayedChats(OptimizedChatProvider chatProvider) {
    final base = chatProvider.chats;
    if (_activeTagIds.isEmpty) return base;
    
    // Mevcut chat listesine ek olarak etiket filtresi uygula - tags string'den List'e çevirmek gerekebilir
    return base
        .where((c) {
          try {
            // tags direkt kullan (null olamaz)
            final tagsList = c.tags;
            
            return tagsList.any((t) => _activeTagIds.contains(t));
          } catch (e) {
            debugPrint('❌ Tag filtresi hatası: $e');
            return false;
          }
        })
        .toList();
  }
}
