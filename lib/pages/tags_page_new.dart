import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tag_provider.dart';
import '../models/tag_model.dart';
import '../widgets/tag_creation_dialog.dart';

class TagsPageNew extends StatefulWidget {
  const TagsPageNew({super.key});

  @override
  State<TagsPageNew> createState() => _TagsPageNewState();
}

class _TagsPageNewState extends State<TagsPageNew> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Selection mode variables
  bool _isSelectionMode = false;
  Set<String> _selectedTagIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _enterSelectionMode(String tagId) {
    setState(() {
      _isSelectionMode = true;
      _selectedTagIds = {tagId};
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedTagIds.clear();
    });
  }

  void _toggleTagSelection(String tagId) {
    setState(() {
      if (_selectedTagIds.contains(tagId)) {
        _selectedTagIds.remove(tagId);
        if (_selectedTagIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedTagIds.add(tagId);
      }
    });
  }

  void _selectAllTags(List<TagModel> tags) {
    setState(() {
      _selectedTagIds = tags.map((tag) => tag.tagId).toSet();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Search bar (only show in normal mode)
          if (!_isSelectionMode) _buildSearchBar(),

          // Tags list
          Expanded(
            child: Consumer<TagProvider>(
              builder: (context, tagProvider, child) {
                if (tagProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                return FutureBuilder<List<TagModel>>(
                  future: _searchQuery.isEmpty
                      ? Future.value(tagProvider.allTags)
                      : tagProvider.searchTags(_searchQuery),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final tags = snapshot.data ?? [];

                    if (tags.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: tags.length,
                      itemBuilder: (context, index) {
                        final tag = tags[index];
                        final isSelected = _selectedTagIds.contains(tag.tagId);
                        return _buildTagCard(
                            tag, isSelected, tagProvider, tags);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton:
          !_isSelectionMode ? _buildFloatingActionButton() : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    if (_isSelectionMode) {
      return AppBar(
        title: Text('${_selectedTagIds.length} seçili'),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
        leading: IconButton(
          onPressed: _exitSelectionMode,
          icon: const Icon(Icons.close),
        ),
        actions: [
          IconButton(
            onPressed: _selectedTagIds.length == 1 ? _editSelectedTag : null,
            icon: const Icon(Icons.edit),
            tooltip: 'Düzenle',
          ),
          IconButton(
            onPressed: _deleteSelectedTags,
            icon: const Icon(Icons.delete),
            tooltip: 'Sil',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'select_all':
                  Consumer<TagProvider>(
                    builder: (context, tagProvider, child) {
                      _selectAllTags(tagProvider.allTags);
                      return const SizedBox.shrink();
                    },
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'select_all',
                child: ListTile(
                  leading: Icon(Icons.select_all),
                  title: Text('Tümünü Seç'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return AppBar(
      title: const Text('Etiketler'),
      backgroundColor: const Color(0xFF00796B),
      foregroundColor: Colors.white,
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Etiket ara...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.label_off,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'Henüz etiket yok' : 'Etiket bulunamadı',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showCreateTagDialog,
              icon: const Icon(Icons.add),
              label: const Text('İlk Etiketini Oluştur'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTagCard(TagModel tag, bool isSelected, TagProvider tagProvider,
      List<TagModel> allTags) {
    final color = Color(
      int.parse('0xFF${tag.color?.substring(1) ?? '2196F3'}'),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      color: isSelected ? Colors.blue[50] : null,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(_getIconData(tag.icon), color: Colors.white, size: 20),
        ),
        title: Text(
          tag.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 14,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: 4),
                Text(
                  '${tag.usageCount} sohbet',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          ],
        ),
        trailing: _isSelectionMode
            ? Checkbox(
                value: isSelected,
                onChanged: (value) => _toggleTagSelection(tag.tagId),
              )
            : null,
        onTap: () {
          if (_isSelectionMode) {
            _toggleTagSelection(tag.tagId);
          }
        },
        onLongPress: () {
          if (!_isSelectionMode) {
            _enterSelectionMode(tag.tagId);
          }
        },
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _showCreateTagDialog,
      backgroundColor: const Color(0xFF00796B),
      child: const Icon(Icons.add, color: Colors.white),
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

  void _showCreateTagDialog() async {
    final result = await showDialog<TagModel>(
      context: context,
      builder: (context) => const TagCreationDialog(),
    );

    if (result != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Etiket oluşturuldu: ${result.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _editSelectedTag() async {
    if (_selectedTagIds.length != 1) return;

    final tagProvider = Provider.of<TagProvider>(context, listen: false);
    final tagId = _selectedTagIds.first;
    final tag = await tagProvider.getTagById(tagId);

    if (tag == null) return;

    if (!mounted) return;
    final result = await showDialog<TagModel>(
      context: context,
      builder: (context) => TagCreationDialog(tagToEdit: tag),
    );

    if (result != null) {
      _exitSelectionMode();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Etiket güncellendi: ${result.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _deleteSelectedTags() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Etiket Sil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_selectedTagIds.length == 1
                ? 'Seçili etiketi silmek istediğinizden emin misiniz?'
                : '${_selectedTagIds.length} etiketi silmek istediğinizden emin misiniz?'),
            const SizedBox(height: 8),
            Text(
              'Bu işlem geri alınamaz ve etiketler tüm sohbetlerden kaldırılacak.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _performDeleteSelectedTags();
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  Future<void> _performDeleteSelectedTags() async {
    final tagProvider = Provider.of<TagProvider>(context, listen: false);
    int deletedCount = 0;

    for (final tagId in _selectedTagIds) {
      final success = await tagProvider.deleteTag(tagId);
      if (success) deletedCount++;
    }

    _exitSelectionMode();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$deletedCount etiket silindi'),
          backgroundColor: deletedCount > 0 ? Colors.green : Colors.red,
        ),
      );
    }
  }
}
