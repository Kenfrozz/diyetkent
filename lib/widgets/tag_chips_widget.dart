import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tag_model.dart';
import '../providers/tag_provider.dart';

class TagChipsWidget extends StatelessWidget {
  final List<String> tagIds;
  final int maxVisible;
  final double fontSize;
  final EdgeInsets padding;

  const TagChipsWidget({
    super.key,
    required this.tagIds,
    this.maxVisible = 3,
    this.fontSize = 10,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  });

  @override
  Widget build(BuildContext context) {
    if (tagIds.isEmpty) return const SizedBox.shrink();

    return Consumer<TagProvider>(
      builder: (context, tagProvider, child) {
        return FutureBuilder<List<TagModel>>(
          future: _getTagsFromIds(tagProvider, tagIds),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox.shrink();
            }

            final tags = snapshot.data!;
            final visibleTags = tags.take(maxVisible).toList();
            final hasMore = tags.length > maxVisible;

            return Wrap(
              spacing: 4,
              runSpacing: 2,
              children: [
                ...visibleTags.map((tag) => _buildTagChip(tag)),
                if (hasMore)
                  Container(
                    padding: padding,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+${tags.length - maxVisible}',
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTagChip(TagModel tag) {
    final color =
        Color(int.parse('0xFF${tag.color?.substring(1) ?? '2196F3'}'));

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (tag.icon != null) ...[
            Icon(
              _getIconData(tag.icon!),
              size: fontSize + 2,
              color: Colors.white,
            ),
            const SizedBox(width: 2),
          ],
          Text(
            tag.name,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<List<TagModel>> _getTagsFromIds(
      TagProvider tagProvider, List<String> tagIds) async {
    final List<TagModel> tags = [];

    for (String tagId in tagIds) {
      final tag = await tagProvider.getTagById(tagId);
      if (tag != null) {
        tags.add(tag);
      }
    }

    return tags;
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
}
