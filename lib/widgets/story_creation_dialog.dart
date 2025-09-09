import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/story_provider.dart';
import '../models/story_model.dart';
import '../services/media_service.dart';
import 'package:image_picker/image_picker.dart';

class StoryCreationDialog extends StatefulWidget {
  const StoryCreationDialog({super.key});

  @override
  State<StoryCreationDialog> createState() => _StoryCreationDialogState();
}

class _StoryCreationDialogState extends State<StoryCreationDialog> {
  final _textController = TextEditingController();
  Color _selectedColor = const Color(0xFF4CAF50);
  bool _isLoading = false;

  final List<Color> _backgroundColors = [
    const Color(0xFF4CAF50), // Green
    const Color(0xFF2196F3), // Blue
    const Color(0xFF9C27B0), // Purple
    const Color(0xFFFF9800), // Orange
    const Color(0xFFE91E63), // Pink
    const Color(0xFF607D8B), // Blue Grey
    const Color(0xFF795548), // Brown
    const Color(0xFF424242), // Grey
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Durum Oluştur',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Seçenekler
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildOptionCard(
                  icon: Icons.text_fields,
                  label: 'Metin',
                  onTap: _showTextStoryDialog,
                ),
                _buildOptionCard(
                  icon: Icons.camera_alt,
                  label: 'Kamera',
                  onTap: _takePhoto,
                ),
                _buildOptionCard(
                  icon: Icons.photo_library,
                  label: 'Galeri',
                  onTap: _pickFromGallery,
                ),
              ],
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildOptionCard(
                  icon: Icons.videocam,
                  label: 'Video',
                  onTap: _recordVideo,
                ),
                _buildOptionCard(
                  icon: Icons.video_library,
                  label: 'Video Seç',
                  onTap: _pickVideo,
                ),
              ],
            ),

            const SizedBox(height: 24),

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFF00796B).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: const Color(0xFF00796B).withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF00796B), size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF00796B),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTextStoryDialog() {
    Navigator.pop(context);
    showDialog(context: context, builder: (context) => _buildTextStoryDialog());
  }

  Widget _buildTextStoryDialog() {
    return StatefulBuilder(
      builder: (context, setState) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Metin Durumu',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),

                // Metin alanı
                Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    color: _selectedColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _textController,
                    maxLines: null,
                    maxLength: 150,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                      hintText: 'Ne düşünüyorsun?',
                      hintStyle: TextStyle(color: Colors.white70, fontSize: 18),
                      counterStyle: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Renk seçici
                const Text(
                  'Arka Plan Rengi',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),

                Wrap(
                  spacing: 8,
                  children: _backgroundColors.map((color) {
                    final isSelected = color == _selectedColor;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = color),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.black, width: 3)
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('İptal'),
                    ),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _createTextStory,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00796B),
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Paylaş'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _createTextStory() async {
    if (_textController.text.trim().isEmpty) {
      if (mounted) {
        _showError('Lütfen bir metin girin');
      }
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final storyProvider = Provider.of<StoryProvider>(context, listen: false);
      final rgbHex = (_selectedColor.toARGB32() & 0xFFFFFF)
          .toRadixString(16)
          .padLeft(6, '0')
          .toUpperCase();
      await storyProvider.createStory(
        type: StoryType.text.name,
        content: _textController.text.trim(),
        backgroundColor: '#$rgbHex',
      );

      if (mounted) {
        FocusScope.of(context).unfocus();
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        messenger.showSnackBar(
          const SnackBar(
              content: Text('Durum paylaşıldı'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Durum paylaşılamadı: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _takePhoto() async {
    try {
      final mediaService = MediaService();
      final file = await mediaService.takePhoto();
      if (file != null) {
        await _createMediaStory(file.path, StoryType.image.name);
      }
    } catch (e) {
      if (mounted) {
        _showError('Fotoğraf çekilemedi: $e');
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final mediaService = MediaService();
      final file = await mediaService.pickImageFromGallery();
      if (file != null) {
        await _createMediaStory(file.path, StoryType.image.name);
      }
    } catch (e) {
      if (mounted) {
        _showError('Fotoğraf seçilemedi: $e');
      }
    }
  }

  Future<void> _recordVideo() async {
    try {
      final mediaService = MediaService();
      final file = await mediaService.recordVideo();
      if (file != null) {
        await _createMediaStory(file.path, StoryType.video.name);
      }
    } catch (e) {
      if (mounted) {
        _showError('Video çekilemedi: $e');
      }
    }
  }

  Future<void> _pickVideo() async {
    try {
      final mediaService = MediaService();
      final file = await mediaService.pickVideoFromGallery();
      if (file != null) {
        await _createMediaStory(file.path, StoryType.video.name);
      }
    } catch (e) {
      if (mounted) {
        _showError('Video seçilemedi: $e');
      }
    }
  }

  Future<void> _createMediaStory(String filePath, String type) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final storyProvider = Provider.of<StoryProvider>(context, listen: false);

      // Medyayı Firebase Storage'a yükle
      String? downloadUrl;
      if (type == StoryType.image.name) {
        downloadUrl = await MediaService()
            .uploadStoryImage(XFile(filePath), onProgress: (p) {});
      } else {
        downloadUrl = await MediaService()
            .uploadStoryVideo(XFile(filePath), onProgress: (p) {});
      }

      if (downloadUrl == null) {
        throw Exception('Medya yüklenemedi');
      }

      await storyProvider.createStory(
        type: type,
        content: type == StoryType.image.name ? 'Fotoğraf' : 'Video',
        mediaUrl: downloadUrl,
      );

      if (mounted) {
        FocusScope.of(context).unfocus();
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        messenger.showSnackBar(
          const SnackBar(
              content: Text('Durum paylaşıldı'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Durum paylaşılamadı: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // removed: success handled inline via messenger before pop
}
