import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/story_model.dart';
import '../pages/story_viewer_page.dart';

class StoryCardWidget extends StatelessWidget {
  final StoryModel story;
  final List<StoryModel> userStories;
  final VoidCallback onTap;

  const StoryCardWidget({
    super.key,
    required this.story,
    required this.userStories,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnviewed = userStories.any((s) => !s.isViewed);
    final unviewedCount = userStories.where((s) => !s.isViewed).length;

    return ListTile(
      onTap: () {
        // Story viewer'ı aç
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoryViewerPage(
              stories: userStories,
              initialIndex: userStories.indexOf(story),
            ),
          ),
        );
        onTap();
      },
      leading: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: hasUnviewed
                    ? const Color(0xFF00796B)
                    : Colors.grey[300]!,
                width: hasUnviewed ? 3 : 2,
              ),
            ),
            child: CircleAvatar(
              radius: 25,
              backgroundColor: Colors.grey[300],
              backgroundImage: story.userProfileImage.isNotEmpty
                  ? CachedNetworkImageProvider(story.userProfileImage)
                  : null,
              child: story.userProfileImage.isEmpty
                  ? Text(
                      story.userName.isNotEmpty
                          ? story.userName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    )
                  : null,
            ),
          ),
          if (hasUnviewed)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFF00796B),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  unviewedCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        story.userName.isNotEmpty ? story.userName : 'Bilinmeyen',
        style: TextStyle(
          fontWeight: hasUnviewed ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (story.type == StoryType.image)
                const Icon(Icons.image, size: 16, color: Colors.grey)
              else if (story.type == StoryType.video)
                const Icon(Icons.videocam, size: 16, color: Colors.grey)
              else
                const Icon(Icons.text_fields, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _getStoryPreview(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            story.timeAgo,
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
      trailing: _buildStoryPreview(),
    );
  }

  String _getStoryPreview() {
    switch (story.type) {
      case StoryType.text:
        return story.content.isNotEmpty ? story.content : 'Metin durumu';
      case StoryType.image:
        return 'Fotoğraf';
      case StoryType.video:
        return 'Video';
    }
  }

  Widget _buildStoryPreview() {
    switch (story.type) {
      case StoryType.text:
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Color(
              int.parse(story.backgroundColor.replaceFirst('#', '0xFF')),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.text_fields, color: Colors.white, size: 20),
        );

      case StoryType.image:
        if (story.mediaUrl != null && story.mediaUrl!.isNotEmpty) {
          return Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: CachedNetworkImage(
                imageUrl: story.mediaUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) =>
                    Icon(Icons.image, color: Colors.grey[400], size: 20),
              ),
            ),
          );
        }
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.image, color: Colors.grey[400], size: 20),
        );

      case StoryType.video:
        if (story.thumbnailUrl != null && story.thumbnailUrl!.isNotEmpty) {
          return Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: CachedNetworkImage(
                    imageUrl: story.thumbnailUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) =>
                        Icon(Icons.videocam, color: Colors.grey[400], size: 20),
                  ),
                ),
                const Center(
                  child: Icon(
                    Icons.play_circle_fill,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
          );
        }
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(Icons.videocam, color: Colors.grey[400], size: 20),
              ),
              const Center(
                child: Icon(
                  Icons.play_circle_fill,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ),
        );
    }
  }
}
