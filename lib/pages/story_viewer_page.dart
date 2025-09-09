import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../models/story_model.dart';
import '../providers/story_provider.dart';
import '../widgets/story_reply_bottom_sheet.dart';
import 'dart:async';

class StoryViewerPage extends StatefulWidget {
  final List<StoryModel> stories;
  final int initialIndex;

  const StoryViewerPage({
    super.key,
    required this.stories,
    required this.initialIndex,
  });

  @override
  State<StoryViewerPage> createState() => _StoryViewerPageState();
}

class _StoryViewerPageState extends State<StoryViewerPage>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  int _currentIndex = 0;
  Timer? _storyTimer;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _progressController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );

    _startStoryTimer();
    _markCurrentStoryAsViewed();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    _storyTimer?.cancel();
    _videoController?.dispose();
    super.dispose();
  }

  void _startStoryTimer() {
    _storyTimer?.cancel();
    _progressController.reset();

    final currentStory = widget.stories[_currentIndex];

    if (currentStory.type == StoryType.video) {
      _initializeVideo(currentStory);
    } else {
      _progressController.forward();
      _storyTimer = Timer(const Duration(seconds: 5), _nextStory);
    }
  }

  void _initializeVideo(StoryModel story) async {
    if (story.mediaUrl == null) return;

    _videoController?.dispose();
    _videoController =
        VideoPlayerController.networkUrl(Uri.parse(story.mediaUrl!));

    try {
      await _videoController!.initialize();
      setState(() {
        _isVideoInitialized = true;
      });

      _videoController!.play();
      _progressController.duration = _videoController!.value.duration;
      _progressController.forward();

      _storyTimer = Timer(_videoController!.value.duration, _nextStory);
    } catch (e) {
      debugPrint('Video yüklenirken hata: $e');
      _nextStory();
    }
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startStoryTimer();
      _markCurrentStoryAsViewed();
    } else {
      Navigator.pop(context);
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startStoryTimer();
      _markCurrentStoryAsViewed();
    }
  }

  void _markCurrentStoryAsViewed() {
    final storyProvider = Provider.of<StoryProvider>(context, listen: false);
    storyProvider.viewStory(widget.stories[_currentIndex].storyId);
  }

  void _pauseStory() {
    _storyTimer?.cancel();
    _progressController.stop();
    _videoController?.pause();
  }

  void _resumeStory() {
    if (widget.stories[_currentIndex].type == StoryType.video) {
      _videoController?.play();
      final remaining =
          _progressController.duration! * (1 - _progressController.value);
      _storyTimer = Timer(remaining, _nextStory);
    } else {
      final remaining = Duration(
        milliseconds: (5000 * (1 - _progressController.value)).round(),
      );
      _storyTimer = Timer(remaining, _nextStory);
    }
    _progressController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.localPosition.dx < screenWidth / 2) {
            _previousStory();
          } else {
            _nextStory();
          }
        },
        onLongPressStart: (_) => _pauseStory(),
        onLongPressEnd: (_) => _resumeStory(),
        child: Stack(
          children: [
            // Story content
            PageView.builder(
              controller: _pageController,
              itemCount: widget.stories.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
                _startStoryTimer();
                _markCurrentStoryAsViewed();
              },
              itemBuilder: (context, index) {
                return _buildStoryContent(widget.stories[index]);
              },
            ),

            // Progress bars
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              right: 8,
              child: Row(
                children: List.generate(
                  widget.stories.length,
                  (index) => Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      child: LinearProgressIndicator(
                        value: index < _currentIndex
                            ? 1.0
                            : index == _currentIndex
                                ? _progressController.value
                                : 0.0,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Header
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 8,
              right: 8,
              child: _buildHeader(widget.stories[_currentIndex]),
            ),

            // Close button
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // Reply button (only for other users' stories)
            if (!widget.stories[_currentIndex].isFromCurrentUser)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 20,
                left: 16,
                right: 16,
                child: _buildReplyButton(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryContent(StoryModel story) {
    switch (story.type) {
      case StoryType.text:
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Color(
            int.parse(story.backgroundColor.replaceFirst('#', '0xFF')),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                story.content,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );

      case StoryType.image:
        if (story.mediaUrl != null && story.mediaUrl!.isNotEmpty) {
          return Center(
            child: CachedNetworkImage(
              imageUrl: story.mediaUrl!,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              errorWidget: (context, url, error) => const Center(
                child: Icon(Icons.error, color: Colors.white, size: 50),
              ),
            ),
          );
        }
        return const Center(
          child: Icon(Icons.image, color: Colors.white, size: 100),
        );

      case StoryType.video:
        if (_videoController != null && _isVideoInitialized) {
          return Center(
            child: AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
          );
        }
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
    }
  }

  Widget _buildHeader(StoryModel story) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey[400],
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
                    color: Colors.white,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                story.userName.isNotEmpty ? story.userName : 'Bilinmeyen',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                story.timeAgo,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (story.isFromCurrentUser)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'delete') {
                _deleteStory(story);
              } else if (value == 'viewers') {
                _showViewers(story);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'viewers',
                child: Row(
                  children: [
                    Icon(Icons.visibility),
                    SizedBox(width: 8),
                    Text('Görüntüleyenler'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Sil', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildReplyButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: GestureDetector(
        onTap: () => _showReplyBottomSheet(),
        child: Row(
          children: [
            Icon(Icons.reply,
                color: Colors.white.withValues(alpha: 0.8), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Yanıtla...',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 16,
                ),
              ),
            ),
            Icon(Icons.send,
                color: Colors.white.withValues(alpha: 0.8), size: 20),
          ],
        ),
      ),
    );
  }

  void _showReplyBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StoryReplyBottomSheet(
        story: widget.stories[_currentIndex],
        onSend: (message) {
          _sendReply(message);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _sendReply(String message) async {
    try {
      final storyProvider = Provider.of<StoryProvider>(context, listen: false);
      await storyProvider.replyToStory(
        widget.stories[_currentIndex].storyId,
        message,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yanıt gönderildi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yanıt gönderilemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteStory(StoryModel story) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Durum Sil'),
        content: const Text('Bu durumu silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final storyProvider = Provider.of<StoryProvider>(
                  context,
                  listen: false,
                );
                await storyProvider.deleteStory(story.storyId);
                if (!context.mounted) return;
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Durum silindi'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                final messenger = ScaffoldMessenger.of(context);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Durum silinemedi: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showViewers(StoryModel story) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Görüntüleyenler'),
        content: SizedBox(
          width: double.maxFinite,
          height: 200,
          child: story.viewerIds.isEmpty
              ? const Center(child: Text('Henüz kimse görüntülemedi'))
              : ListView.builder(
                  itemCount: story.viewerIds.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(story.viewerIds[index][0].toUpperCase()),
                      ),
                      title: Text('Kullanıcı ${index + 1}'),
                      subtitle: const Text('Görüntülendi'),
                    );
                  },
                ),
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
}
