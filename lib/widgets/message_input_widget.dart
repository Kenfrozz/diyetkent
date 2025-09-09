import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:async';
import 'attachment_bottom_sheet.dart';
import 'app_notifier.dart';
import 'package:record/record.dart' as rec;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class MessageInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final Future<void> Function() onSendMessage;
  final Function(File) onImageSelected;
  final Function(XFile) onVideoSelected;
  final Function(PlatformFile) onDocumentSelected;
  final VoidCallback onShareLocation;
  final VoidCallback onShareContact;
  final VoidCallback onOpenCamera;
  final Future<void> Function(File) onAudioRecorded;
  final Function(bool) onTypingChanged;

  const MessageInputWidget({
    super.key,
    required this.controller,
    required this.onSendMessage,
    required this.onImageSelected,
    required this.onVideoSelected,
    required this.onDocumentSelected,
    required this.onShareLocation,
    required this.onShareContact,
    required this.onOpenCamera,
    required this.onAudioRecorded,
    required this.onTypingChanged,
  });

  @override
  State<MessageInputWidget> createState() => _MessageInputWidgetState();
}

class _MessageInputWidgetState extends State<MessageInputWidget> {
  bool _isTyping = false;
  bool _isSending = false; // Mesaj gönderiliyor mu?
  bool _hasText = false; // Text var mı?
  Timer? _typingTimer; // Typing durumunu kontrol etmek için
  // Ses kaydı
  final rec.AudioRecorder _recorder = rec.AudioRecorder();
  bool _isRecording = false;
  bool _isPaused = false;
  Duration _recordDuration = Duration.zero;
  Timer? _recordTimer;
  String? _currentRecordPath;

  @override
  void dispose() {
    _typingTimer?.cancel(); // Timer'ı temizle
    // Eğer hala typing durumundaysa temizle
    if (_isTyping) {
      widget.onTypingChanged(false);
    }
    _recordTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged(String text) {
    final hasText = text.trim().isNotEmpty;
    final isCurrentlyTyping = text.isNotEmpty;

    // Eğer kullanıcı yazıyorsa ve daha önce typing değilse
    if (isCurrentlyTyping && !_isTyping) {
      setState(() {
        _isTyping = true;
        _hasText = hasText;
      });
      widget.onTypingChanged(true);
    }

    // Eğer kullanıcı yazmayı bıraktıysa
    if (!isCurrentlyTyping && _isTyping) {
      setState(() {
        _isTyping = false;
        _hasText = hasText;
      });
      widget.onTypingChanged(false);
    }

    // Text durumunu güncelle
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }

    // Typing timer'ını sıfırla
    _typingTimer?.cancel();
    if (isCurrentlyTyping) {
      _typingTimer = Timer(const Duration(milliseconds: 1500), () {
        // 1.5 saniye yazmayı durursa typing'i durdur
        if (_isTyping) {
          setState(() {
            _isTyping = false;
          });
          widget.onTypingChanged(false);
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_isSending || !_hasText) return;

    setState(() {
      _isSending = true;
    });

    try {
      // Mesaj gönderilirken typing durumunu temizle
      if (_isTyping) {
        setState(() {
          _isTyping = false;
        });
        widget.onTypingChanged(false);
      }

      await widget.onSendMessage();
    } catch (e) {
      if (mounted) {
        AppNotifier.showError(context, 'Mesaj gönderme hatası: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return AttachmentBottomSheet(
          onDocumentSelected: widget.onDocumentSelected,
          onShareLocation: widget.onShareLocation,
          onShareContact: widget.onShareContact,
        );
      },
    );
  }

  Future<void> _startRecording() async {
    if (_isRecording) return;
    try {
      final hasPerm = await _recorder.hasPermission();
      if (!hasPerm) {
        if (mounted) {
          AppNotifier.showError(context, 'Mikrofon izni gerekli');
        }
        return;
      }
      final tmpDir = await getTemporaryDirectory();
      final filePath = p.join(
        tmpDir.path,
        'rec_${DateTime.now().millisecondsSinceEpoch}.m4a',
      );

      await _recorder.start(
        const rec.RecordConfig(
          encoder: rec.AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: filePath,
      );
      setState(() {
        _isRecording = true;
        _isPaused = false;
        _recordDuration = Duration.zero;
        _currentRecordPath = filePath;
      });
      _recordTimer?.cancel();
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted && _isRecording && !_isPaused) {
          setState(() {
            _recordDuration += const Duration(seconds: 1);
          });
        }
      });
    } catch (e) {
      if (mounted) {
        AppNotifier.showError(context, 'Ses kaydı başlatılamadı: $e');
      }
    }
  }

  Future<void> _stopRecordingAndSend() async {
    if (!_isRecording) return;
    try {
      final path = await _recorder.stop();
      _recordTimer?.cancel();
      setState(() => _isRecording = false);
      if (path == null) return;
      final file = File(path);
      await widget.onAudioRecorded(file);
      _currentRecordPath = null;
      _isPaused = false;
    } catch (e) {
      if (mounted) {
        AppNotifier.showError(context, 'Ses kaydı gönderilemedi: $e');
      }
    }
  }

  Future<void> _cancelRecording() async {
    if (!_isRecording) return;
    try {
      final path = await _recorder.stop();
      _recordTimer?.cancel();
      setState(() {
        _isRecording = false;
        _isPaused = false;
      });
      if (path != null) {
        final f = File(path);
        if (await f.exists()) {
          await f.delete();
        }
      } else if (_currentRecordPath != null) {
        final f = File(_currentRecordPath!);
        if (await f.exists()) {
          await f.delete();
        }
      }
      _currentRecordPath = null;
    } catch (_) {}
  }

  Future<void> _togglePauseResume() async {
    if (!_isRecording) return;
    try {
      if (_isPaused) {
        await _recorder.resume();
        setState(() => _isPaused = false);
      } else {
        await _recorder.pause();
        setState(() => _isPaused = true);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // Alt sistem çubuğu (gesture/home indicator) ile çakışmayı önlemek için
    // klavye durumu ve güvenli alanı dikkate alarak dinamik alt padding uygula.
    final mediaQuery = MediaQuery.of(context);
    final keyboardInset = mediaQuery.viewInsets.bottom; // Klavye yüksekliği
    final systemBottomPadding =
        mediaQuery.padding.bottom; // Sistem alt güvenli alanı
    final extraBottomSpace = keyboardInset > 0 ? 0.0 : systemBottomPadding;

    return Padding(
      // Klavye kapalıyken cihazın alt güvenli alanı kadar boşluk bırak
      padding: EdgeInsets.only(bottom: extraBottomSpace),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, -2),
              blurRadius: 6,
              color: Colors.black.withValues(alpha: 0.1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Ek dosya butonu
                IconButton(
                  icon: const Icon(Icons.attach_file, color: Color(0xFF5F6368)),
                  onPressed: _showAttachmentOptions,
                ),
                // Kamera butonu (birleşik ekran)
                IconButton(
                  icon: const Icon(Icons.camera_alt, color: Color(0xFF5F6368)),
                  onPressed: widget.onOpenCamera,
                ),
                // Mesaj input alanı
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: Colors.grey[100],
                    ),
                    child: TextField(
                      controller: widget.controller,
                      onChanged: _onTextChanged,
                      maxLength: 1000, // Mesaj karakter sınırı
                      decoration: const InputDecoration(
                        hintText: 'Mesaj',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        counterText: '', // Karakter sayacını gizle
                      ),
                      maxLines: 5,
                      minLines: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Sağda dinamik buton: metin varsa Gönder, yoksa Mikrofon (tek tıkla başlat/bitir)
                Container(
                  decoration: BoxDecoration(
                    color: (_hasText && !_isSending)
                        ? const Color(0xFF25D366)
                        : (_isRecording ? Colors.red : const Color(0xFF25D366)),
                    shape: BoxShape.circle,
                  ),
                  width: 48,
                  height: 48,
                  child: IconButton(
                    icon: Icon(
                      (_hasText && !_isSending)
                          ? Icons.send
                          : (_isRecording
                              ? (_isPaused ? Icons.mic : Icons.stop)
                              : Icons.mic),
                      color: Colors.white,
                    ),
                    onPressed: () async {
                      if (_hasText && !_isSending) {
                        await _sendMessage();
                      } else {
                        if (_isRecording) {
                          await _stopRecordingAndSend();
                        } else {
                          await _startRecording();
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
            if (_isRecording) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text(
                          _formatDuration(_recordDuration),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _FakeWaveform(isPaused: _isPaused),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: _cancelRecording,
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                        ),
                        IconButton(
                          onPressed: _togglePauseResume,
                          icon: Icon(
                            _isPaused ? Icons.mic : Icons.pause,
                            color: Colors.black87,
                          ),
                        ),
                        Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF25D366),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: _stopRecordingAndSend,
                            icon: const Icon(Icons.send, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
  }
}

class _FakeWaveform extends StatefulWidget {
  final bool isPaused;
  const _FakeWaveform({required this.isPaused});

  @override
  State<_FakeWaveform> createState() => _FakeWaveformState();
}

class _FakeWaveformState extends State<_FakeWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _ac;
  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isPaused) {
      return Container(
        height: 24,
        alignment: Alignment.centerLeft,
        child: Container(
          height: 2,
          width: double.infinity,
          color: Colors.grey[400],
        ),
      );
    }
    return SizedBox(
      height: 24,
      child: AnimatedBuilder(
        animation: _ac,
        builder: (_, __) {
          final v = (0.3 + 0.7 * _ac.value);
          return CustomPaint(
            painter: _WavePainter(scale: v),
          );
        },
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double scale;
  _WavePainter({required this.scale});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final midY = size.height / 2;
    final path = Path();
    const segments = 40;
    for (int i = 0; i <= segments; i++) {
      final x = i * size.width / segments;
      final amp = (i % 4 == 0 ? 8.0 : 4.0) * scale;
      final y = midY + (i % 2 == 0 ? -amp : amp) * 0.5;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.scale != scale;
  }
}
