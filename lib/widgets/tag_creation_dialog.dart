import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tag_model.dart';
import '../providers/tag_provider.dart';

class TagCreationDialog extends StatefulWidget {
  final TagModel? tagToEdit;

  const TagCreationDialog({super.key, this.tagToEdit});

  @override
  State<TagCreationDialog> createState() => _TagCreationDialogState();
}

class _TagCreationDialogState extends State<TagCreationDialog> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedColor = '#2196F3';
  String _selectedIcon = 'label';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.tagToEdit != null) {
      final tag = widget.tagToEdit!;
      _nameController.text = tag.name;
      _selectedColor = tag.color ?? '#2196F3';
      _selectedIcon = tag.icon ?? 'label';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
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
                  widget.tagToEdit != null ? 'Etiket Düzenle' : 'Yeni Etiket',
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

            // Tag preview
            _buildTagPreview(),
            const SizedBox(height: 24),

            // Name field
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Etiket Adı',
                hintText: 'Örn: İş, Aile, Arkadaşlar',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 24),

            // Color selection
            Text(
              'Renk Seçin',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            _buildColorSelection(),
            const SizedBox(height: 16),

            // Icon selection
            Text(
              'İkon Seçin',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            _buildIconSelection(),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                      _isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('İptal'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveTag,
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.tagToEdit != null ? 'Güncelle' : 'Oluştur'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagPreview() {
    final color = Color(int.parse('0xFF${_selectedColor.substring(1)}'));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(
              _getIconData(_selectedIcon),
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nameController.text.isEmpty
                      ? 'Etiket Adı'
                      : _nameController.text,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSelection() {
    final colors = TagProvider.getPredefinedColors();

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: colors.length,
        itemBuilder: (context, index) {
          final colorHex = colors[index];
          final color = Color(int.parse('0xFF${colorHex.substring(1)}'));
          final isSelected = _selectedColor == colorHex;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedColor = colorHex;
              });
            },
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 3,
                      )
                    : null,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildIconSelection() {
    final icons = TagProvider.getPredefinedIcons();

    return SizedBox(
      height: 120,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: icons.length,
        itemBuilder: (context, index) {
          final iconData = icons[index];
          final iconName = iconData['icon']!;
          final isSelected = _selectedIcon == iconName;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedIcon = iconName;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getIconData(iconName),
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getIconData(String iconName) {
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

  void _saveTag() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen etiket adını girin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final tagProvider = Provider.of<TagProvider>(context, listen: false);

      if (widget.tagToEdit != null) {
        // Update existing tag
        final tag = widget.tagToEdit!;
        tag.name = _nameController.text.trim();
        tag.color = _selectedColor;
        tag.icon = _selectedIcon;

        final success = await tagProvider.updateTag(tag);
        if (success && mounted) {
          Navigator.of(context).pop(tag);
        }
      } else {
        // Create new tag
        final tag = await tagProvider.createTag(
          name: _nameController.text.trim(),
          color: _selectedColor,
          icon: _selectedIcon,
        );

        if (tag != null && mounted) {
          Navigator.of(context).pop(tag);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
