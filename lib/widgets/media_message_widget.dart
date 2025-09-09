import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
import '../database/drift_service.dart';

class MediaMessageWidget extends StatefulWidget {
  final String? imageUrl;
  final String? videoUrl;
  final String? documentUrl;
  final String? documentName;
  final String? fileSize;
  final String? localPath;
  final String? messageId;
  final bool isFromMe;
  final String messageTime;
  final bool isRead;
  final VoidCallback? onTap;
  // Audio
  final String? audioUrl;
  final int? audioDurationSec;
  // Location
  final double? latitude;
  final double? longitude;
  final String? locationName;
  // Contact
  final String? contactName;
  final String? contactPhone;

  const MediaMessageWidget({
    super.key,
    this.imageUrl,
    this.videoUrl,
    this.documentUrl,
    this.documentName,
    this.fileSize,
    this.localPath,
    this.messageId,
    required this.isFromMe,
    required this.messageTime,
    required this.isRead,
    this.onTap,
    this.audioUrl,
    this.audioDurationSec,
    this.latitude,
    this.longitude,
    this.locationName,
    this.contactName,
    this.contactPhone,
  });

  @override
  State<MediaMessageWidget> createState() => _MediaMessageWidgetState();
}

class _MediaMessageWidgetState extends State<MediaMessageWidget> {
  String? _localPath;
  bool _downloading = false;
  double _progress = 0;
  // Audio
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _audioPos = Duration.zero;
  Duration _audioDur = Duration.zero;

  @override
  void initState() {
    super.initState();
    _localPath = widget.localPath;
    // Otomatik medya indirmeyi kapattık (maliyet/UX için)
    // Görseller CachedNetworkImage cache'i ile, videolar tıklandığında stream edilir.

    // Audio listeners
    _audioPlayer.onPositionChanged.listen((d) {
      if (mounted) setState(() => _audioPos = d);
    });
    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _audioDur = d);
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  // Not in use: automatic caching disabled

  @override
  Widget build(BuildContext context) {
    if (widget.audioUrl != null) {
      return _buildAudioMessage();
    } else if (widget.latitude != null && widget.longitude != null) {
      return _buildLocationMessage();
    } else if (widget.contactName != null && widget.contactPhone != null) {
      return _buildContactCard();
    } else if (widget.imageUrl != null ||
        (_localPath != null && _isImagePath(_localPath!))) {
      return _buildImageMessage();
    } else if (widget.videoUrl != null ||
        (_localPath != null && _isVideoPath(_localPath!))) {
      return _buildVideoMessage();
    } else if (widget.documentUrl != null || widget.documentName != null) {
      return _buildDocumentMessage();
    }
    return const SizedBox.shrink();
  }

  // --- Audio message ---
  Widget _buildAudioMessage() {
    final total = _audioDur.inMilliseconds == 0
        ? Duration(seconds: widget.audioDurationSec ?? 0)
        : _audioDur;
    final pos =
        _audioPos.inMilliseconds > total.inMilliseconds ? total : _audioPos;

    String fmt(Duration d) =>
        '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';

    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.isFromMe ? const Color(0xFF00796B) : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow,
                color: widget.isFromMe ? Colors.white : Colors.black87),
            onPressed: () async {
              if (widget.audioUrl == null) return;
              if (_isPlaying) {
                await _audioPlayer.pause();
                setState(() => _isPlaying = false);
              } else {
                await _audioPlayer.play(UrlSource(widget.audioUrl!));
                setState(() => _isPlaying = true);
              }
            },
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Slider(
                  value: pos.inMilliseconds.toDouble(),
                  max:
                      (total.inMilliseconds == 0 ? const Duration(seconds: 1) : total)
                          .inMilliseconds
                          .toDouble(),
                  onChanged: (v) async {
                    final target = Duration(milliseconds: v.toInt());
                    await _audioPlayer.seek(target);
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(fmt(pos),
                        style: TextStyle(
                            color: widget.isFromMe
                                ? Colors.white
                                : Colors.grey[700],
                            fontSize: 12)),
                    Text(fmt(total),
                        style: TextStyle(
                            color: widget.isFromMe
                                ? Colors.white
                                : Colors.grey[700],
                            fontSize: 12)),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            widget.messageTime,
            style: TextStyle(
                color: widget.isFromMe ? Colors.white : Colors.grey[600],
                fontSize: 12),
          ),
          if (widget.isFromMe) ...[
            const SizedBox(width: 4),
            Icon(widget.isRead ? Icons.done_all : Icons.done,
                color: widget.isRead ? Colors.blue : Colors.white, size: 16),
          ],
        ],
      ),
    );
  }

  // --- Location message ---
  Widget _buildLocationMessage() {
    final lat = widget.latitude!;
    final lng = widget.longitude!;
    final title = widget.locationName ?? 'Konum';
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.lightBlue[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_pin, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('$lat, $lng',
                      style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.map, color: Colors.green),
          ],
        ),
      ),
    );
  }

  // --- Contact card ---
  Widget _buildContactCard() {
    final name = widget.contactName!;
    final phone = widget.contactPhone!;
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const CircleAvatar(child: Icon(Icons.person)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(phone,
                    style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        // Mesaj gönder (varsayılan SMS/WhatsApp dışa yönlendirme)
                        final sms = Uri.parse('sms:$phone');
                        await launchUrl(sms,
                            mode: LaunchMode.externalApplication);
                      },
                      icon: const Icon(Icons.message, size: 18),
                      label: const Text('Mesaj gönder'),
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8)),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        // Rehbere ekleme: vCard oluşturup dışa aç
                        final vcf =
                            'BEGIN:VCARD\nVERSION:3.0\nFN:$name\nTEL:$phone\nEND:VCARD';
                        final dir = await getTemporaryDirectory();
                        final file = File('${dir.path}/$name.vcf');
                        await file.writeAsBytes(utf8.encode(vcf));
                        await OpenFilex.open(file.path);
                      },
                      icon: const Icon(Icons.person_add, size: 18),
                      label: const Text('Rehbere ekle'),
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8)),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildImageMessage() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 250, maxHeight: 350),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[300],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            if (_localPath != null)
              Image.file(
                File(_localPath!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildImageError(),
              )
            else if (widget.imageUrl != null)
              // Eğer local path yoksa, CachedNetworkImage gösterir (kendi disk cache'ini kullanır)
              CachedNetworkImage(
                imageUrl: widget.imageUrl!,
                fit: BoxFit.cover,
                memCacheWidth: 1024,
                memCacheHeight: 1024,
                placeholder: (context, url) => _buildImagePlaceholder(),
                errorWidget: (context, url, error) => _buildImageError(),
              )
            else
              _buildImageError(),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap ?? () => _openImageViewer(context),
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.messageTime,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    if (widget.isFromMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        widget.isRead ? Icons.done_all : Icons.done,
                        color: widget.isRead ? Colors.blue : Colors.white,
                        size: 16,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_downloading)
              Positioned.fill(
                child: Container(
                  color: Colors.black26,
                  child: Center(
                    child: CircularProgressIndicator(value: _progress),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoMessage() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 250, maxHeight: 350),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[300],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: 200,
              color: Colors.grey[400],
              child: const Icon(Icons.movie, size: 60, color: Colors.white),
            ),
            Positioned.fill(
              child: Center(
                child: GestureDetector(
                  onTap: widget.onTap ?? () => _openVideo(context),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
            // Otomatik indirme kaldırıldı: kullanıcı tıklayınca stream oynatılıyor
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.messageTime,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    if (widget.isFromMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        widget.isRead ? Icons.done_all : Icons.done,
                        color: widget.isRead ? Colors.blue : Colors.white,
                        size: 16,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_downloading)
              Positioned.fill(
                child: Container(
                  color: Colors.black26,
                  child: Center(
                    child: CircularProgressIndicator(value: _progress),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentMessage() {
    return InkWell(
      onTap: _openOrDownloadDocument,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 250),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.isFromMe ? Colors.green[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getDocumentColor(),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getDocumentIcon(),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.documentName ?? 'Belge',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.fileSize != null)
                        Text(
                          widget.fileSize!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                if (!(_localPath != null && File(_localPath!).existsSync()))
                  InkWell(
                    onTap: _downloadDocument,
                    child: Icon(
                      Icons.download,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  widget.messageTime,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                if (widget.isFromMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    widget.isRead ? Icons.done_all : Icons.done,
                    color: widget.isRead ? Colors.blue : Colors.grey[600],
                    size: 16,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 200,
      color: Colors.grey[300],
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildImageError() {
    return Container(
      width: double.infinity,
      height: 200,
      color: Colors.grey[300],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, size: 40, color: Colors.grey[600]),
          const SizedBox(height: 8),
          Text(
            'Fotoğraf yüklenemedi',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Color _getDocumentColor() {
    final name = widget.documentName;
    if (name == null) return Colors.grey;
    final String extension = name.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'txt':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getDocumentIcon() {
    final name = widget.documentName;
    if (name == null) return Icons.description;
    final String extension = name.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.description;
    }
  }

  void _openImageViewer(BuildContext context) {
    final path = _localPath;
    final url = widget.imageUrl;
    if (path == null && url == null) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: InteractiveViewer(
            child: path != null
                ? Image.file(File(path))
                : CachedNetworkImage(imageUrl: url!),
          ),
        ),
      ),
    );
  }

  void _openVideo(BuildContext context) {
    final path = _localPath;
    // Stream kaldırıldı: sadece yerel dosya varsa oynat
    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Video cihazda yok. İndirmek için mesaja dokunun.')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _InlineVideoPlayer(path: path, url: null),
      ),
    );
  }

  Future<void> _downloadDocument() async {
    final url = widget.documentUrl;
    if (url == null) return;
    try {
      setState(() {
        _downloading = true;
        _progress = 0;
      });
      final uri = Uri.parse(url);
      final httpClient = HttpClient();
      final req = await httpClient.getUrl(uri);
      final resp = await req.close();
      final bytes = <int>[];
      final total = resp.contentLength;
      await for (final data in resp) {
        bytes.addAll(data);
        if (total > 0) setState(() => _progress = bytes.length / total);
      }
      final dir = await getApplicationDocumentsDirectory();
      final fileName = widget.documentName ??
          'document_${DateTime.now().millisecondsSinceEpoch}';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(Uint8List.fromList(bytes));
      if (mounted) setState(() => _localPath = file.path);
      // Persist local path for future sessions
      if (widget.messageId != null) {
        // ignore: discarded_futures
        DriftService.updateMessageLocalMediaPath(widget.messageId!, file.path);
      }
      unawaited(OpenFilex.open(file.path));
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('İndirildi: ${file.path}')));
      }
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('İndirme hatası: $e')));
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _openOrDownloadDocument() async {
    if (_localPath != null && await File(_localPath!).exists()) {
      unawaited(OpenFilex.open(_localPath!));
      return;
    }
    await _downloadDocument();
  }

  bool _isImagePath(String p) {
    final s = p.toLowerCase();
    return s.endsWith('.jpg') ||
        s.endsWith('.jpeg') ||
        s.endsWith('.png') ||
        s.endsWith('.webp') ||
        s.endsWith('.gif');
  }

  bool _isVideoPath(String p) {
    final s = p.toLowerCase();
    // Bazı cihazlarda geçici video dosyası .temp uzantısıyla gelebilir
    return s.endsWith('.mp4') ||
        s.endsWith('.mov') ||
        s.endsWith('.m4v') ||
        s.endsWith('.avi') ||
        s.endsWith('.mkv') ||
        s.endsWith('.temp');
  }
}

class _InlineVideoPlayer extends StatefulWidget {
  final String? path;
  final String? url;
  const _InlineVideoPlayer({this.path, this.url});

  @override
  State<_InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<_InlineVideoPlayer> {
  VideoPlayerController? _controller;
  Future<void>? _initFuture;

  @override
  void initState() {
    super.initState();
    if (widget.path != null) {
      _controller = VideoPlayerController.file(File(widget.path!));
    }
    _initFuture = _controller?.initialize();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: _controller == null
            ? const Text(
                'Video bulunamadı',
                style: TextStyle(color: Colors.white),
              )
            : FutureBuilder(
                future: _initFuture,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const CircularProgressIndicator();
                  }
                  return AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        VideoPlayer(_controller!),
                        _ControlsOverlay(controller: _controller!),
                        VideoProgressIndicator(
                          _controller!,
                          allowScrubbing: true,
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _ControlsOverlay extends StatelessWidget {
  const _ControlsOverlay({required this.controller});
  final VideoPlayerController controller;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          controller.value.isPlaying ? controller.pause() : controller.play(),
      child: Stack(
        children: <Widget>[
          AnimatedOpacity(
            opacity: controller.value.isPlaying ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: Center(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(12),
                child: Icon(
                  controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 48.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
