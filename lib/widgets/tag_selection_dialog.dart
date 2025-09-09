import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tag_model.dart';
import '../providers/tag_provider.dart';
import 'tag_creation_dialog.dart';

class TagSelectionDialog extends StatefulWidget {
  final List<String> selectedTagIds;
  final Function(List<String>) onTagsSelected;
  final String? title;

  const TagSelectionDialog({
    super.key,
    required this.selectedTagIds,
    required this.onTagsSelected,
    this.title,
  });

  @override
  State<TagSelectionDialog> createState() => _TagSelectionDialogState();
}

class _TagSelectionDialogState extends State<TagSelectionDialog> {
  late List<String> _selectedTagIds;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedTagIds = List.from(widget.selectedTagIds);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          minHeight: 400,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title ?? 'Etiket Seç',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search bar
            TextField(
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
            const SizedBox(height: 16),

            // Create new tag button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showCreateTagDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Yeni Etiket Oluştur'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tags list
            Expanded(
              child: Consumer<TagProvider>(
                builder: (context, tagProvider, child) {
                  // Debug: TagSelectionDialog Consumer build

                  if (tagProvider.isLoading) {
                    // Debug: Loading state
                    return const Center(child: CircularProgressIndicator());
                  }

                  // TagProvider hata durumunu kontrol et
                  if (tagProvider.error != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Etiketler yüklenirken hata oluştu',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            tagProvider.error!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              tagProvider.clearError();
                              tagProvider.loadTags();
                            },
                            child: const Text('Tekrar Dene'),
                          ),
                        ],
                      ),
                    );
                  }

                  return FutureBuilder<List<TagModel>>(
                    future: _searchQuery.isEmpty
                        ? Future.value(tagProvider.allTags)
                        : tagProvider.searchTags(_searchQuery),
                    builder: (context, snapshot) {
                      // Debug: FutureBuilder state
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      // FutureBuilder hata durumunu kontrol et
                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Etiket arama hatası',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.error,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                snapshot.error.toString(),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.outline,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      final tags = snapshot.data ?? [];

                      if (tags.isEmpty) {
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
                                _searchQuery.isEmpty
                                    ? 'Henüz etiket yok'
                                    : 'Etiket bulunamadı',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outline,
                                    ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: tags.length,
                        itemBuilder: (context, index) {
                          final tag = tags[index];
                          final isSelected = _selectedTagIds.contains(
                            tag.tagId,
                          );

                          return _buildTagTile(tag, isSelected);
                        },
                      );
                    },
                  );
                },
              ),
            ),

            // Action buttons
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('İptal'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    widget.onTagsSelected(_selectedTagIds);
                    Navigator.of(context).pop(_selectedTagIds);
                  },
                  child: Text('Uygula (${_selectedTagIds.length})'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagTile(TagModel tag, bool isSelected) {
    final color = Color(
      int.parse('0xFF${tag.color?.substring(1) ?? '2196F3'}'),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (bool? value) {
          setState(() {
            if (value == true) {
              _selectedTagIds.add(tag.tagId);
            } else {
              _selectedTagIds.remove(tag.tagId);
            }
          });
        },
        title: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${tag.usageCount}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
        subtitle: null,
        controlAffinity: ListTileControlAffinity.trailing,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
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
      // Refresh the tags list
      if (mounted) {
        Provider.of<TagProvider>(context, listen: false).loadTags();
      }
    }
  }
}
