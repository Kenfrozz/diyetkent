import 'package:flutter/material.dart';
import '../models/story_model.dart';

class StoryReplyBottomSheet extends StatefulWidget {
  final StoryModel story;
  final Function(String) onSend;

  const StoryReplyBottomSheet({
    super.key,
    required this.story,
    required this.onSend,
  });

  @override
  State<StoryReplyBottomSheet> createState() => _StoryReplyBottomSheetState();
}

class _StoryReplyBottomSheetState extends State<StoryReplyBottomSheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Keyboard açıldığında focus ver
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendReply() {
    final message = _controller.text.trim();
    if (message.isNotEmpty && !_isLoading) {
      setState(() {
        _isLoading = true;
      });
      widget.onSend(message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey[400],
                    child: widget.story.userProfileImage.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              widget.story.userProfileImage,
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Text(
                                  widget.story.userName.isNotEmpty
                                      ? widget.story.userName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                );
                              },
                            ),
                          )
                        : Text(
                            widget.story.userName.isNotEmpty
                                ? widget.story.userName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.story.userName.isNotEmpty
                              ? widget.story.userName
                              : 'Bilinmeyen',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Text(
                          'Duruma yanıtla',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Story preview
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  // Story thumbnail
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: widget.story.type == StoryType.text
                          ? Color(
                              int.parse(
                                widget.story.backgroundColor.replaceFirst(
                                  '#',
                                  '0xFF',
                                ),
                              ),
                            )
                          : Colors.grey[300],
                    ),
                    child: widget.story.type == StoryType.text
                        ? const Center(
                            child: Text(
                              'Aa',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : widget.story.type == StoryType.image
                        ? const Icon(Icons.image, color: Colors.white, size: 20)
                        : const Icon(
                            Icons.videocam,
                            color: Colors.white,
                            size: 20,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.story.type == StoryType.text
                          ? widget.story.content.length > 30
                                ? '${widget.story.content.substring(0, 30)}...'
                                : widget.story.content
                          : widget.story.type == StoryType.image
                          ? 'Fotoğraf'
                          : 'Video',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Message input
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        enabled: !_isLoading,
                        maxLines: null,
                        maxLength: 500,
                        decoration: const InputDecoration(
                          hintText: 'Mesaj yazın...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          counterText: '',
                        ),
                        onSubmitted: (_) => _sendReply(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _isLoading ? null : _sendReply,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                  ),
                ],
              ),
            ),

            // Quick replies
            Container(
              height: 50,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildQuickReply('👍'),
                  _buildQuickReply('❤️'),
                  _buildQuickReply('😂'),
                  _buildQuickReply('😮'),
                  _buildQuickReply('😢'),
                  _buildQuickReply('😡'),
                  _buildQuickReply('👏'),
                  _buildQuickReply('🔥'),
                ],
              ),
            ),

            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickReply(String emoji) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => widget.onSend(emoji),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
        ),
      ),
    );
  }
}
