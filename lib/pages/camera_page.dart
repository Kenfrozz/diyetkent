import 'dart:async';
import 'dart:typed_data';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';

// Seçim sonrası üst bileşene XFile döndürür.
typedef OnMediaCaptured = void Function(XFile file, {required bool isVideo});

class CameraPage extends StatefulWidget {
  const CameraPage({super.key, this.onCaptured, this.startInVideoMode = false});

  final OnMediaCaptured? onCaptured;
  final bool startInVideoMode;

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  int _cameraIndex = 0;
  bool _isInitialized = false;
  bool _isRecording = false;
  bool _isVideoMode = false; // Alt mod anahtarı (Video / Fotoğraf)
  FlashMode _flashMode = FlashMode.off;

  // Alt şerit için son medya öğeleri
  List<AssetEntity> _recentAssets = [];
  bool _galleryLoading = false;

  // Navigasyon sonucu sadece bir kez dönsün
  bool _hasPopped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _isVideoMode = widget.startInVideoMode;
    _setup();
  }

  Future<void> _setup() async {
    try {
      // Kamera ve mikrofon izinleri
      final statuses =
          await [Permission.camera, Permission.microphone].request();
      if (statuses[Permission.camera]?.isGranted != true ||
          statuses[Permission.microphone]?.isGranted != true) {
        debugPrint('Camera/Microphone permission denied');
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        return;
      }

      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;
      await _initController(_cameras[_cameraIndex]);
      await _loadRecentGallery();
    } catch (e) {
      debugPrint('Camera setup error: $e');
    }
  }

  Future<void> _initController(CameraDescription description) async {
    // Önce eski controller'ı dispose et
    await _controller?.dispose();

    final controller = CameraController(
      description,
      ResolutionPreset.medium, // Daha iyi kalite, yine de stabil
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
      // Buffer yönetimi için ek ayarlar
    );
    _controller = controller;
    try {
      await controller.initialize();

      // Preview streaming'i optimize et
      await controller.setFlashMode(_flashMode);
      // Android cihazlarda 30fps tipik olarak stabil
      if (controller.value.isInitialized) {
        try {
          await controller.setExposureMode(ExposureMode.auto);
          await controller.setFocusMode(FocusMode.auto);
        } catch (_) {}
      }

      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Camera initialize error: $e');
    }
  }

  Future<void> _loadRecentGallery() async {
    setState(() => _galleryLoading = true);
    final perm = await PhotoManager.requestPermissionExtend();
    if (perm.isAuth) {
      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        type: RequestType.common,
        onlyAll: true,
      );
      if (paths.isNotEmpty) {
        // Buffer yükünü azaltmak için daha az asset yükle
        final recent = await paths.first.getAssetListPaged(page: 0, size: 20);
        if (mounted) setState(() => _recentAssets = recent);
      }
    }
    if (mounted) setState(() => _galleryLoading = false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        // Uygulamadan çıkılırken kaynakları serbest bırak
        controller.dispose();
        setState(() => _isInitialized = false);
        break;
      case AppLifecycleState.resumed:
        // Uygulamaya geri dönüldüğünde kamerayı yeniden başlat
        if (_cameras.isNotEmpty) {
          _initController(_cameras[_cameraIndex]);
        }
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _onShutter() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    try {
      if (_isVideoMode) {
        if (_isRecording) {
          final file = await controller.stopVideoRecording();
          setState(() => _isRecording = false);
          // Bazı cihazlarda video yolu .temp ile bitebilir; bunu .mp4'e taşırız
          XFile outFile = file;
          final lower = file.path.toLowerCase();
          if (lower.endsWith('.temp')) {
            try {
              final newPath = file.path.replaceAll(
                RegExp(r'\.temp$', caseSensitive: false),
                '.mp4',
              );
              final f = File(file.path);
              if (await f.exists()) {
                await f.rename(newPath);
                outFile = XFile(newPath);
              }
            } catch (_) {}
          }

          // Callback'i çağır ama navigation'ı geciktir
          widget.onCaptured?.call(outFile, isVideo: true);

          // Navigation'ı bir sonraki frame'e ertele
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_hasPopped && Navigator.of(context).canPop()) {
              _hasPopped = true;
              Navigator.of(context).pop();
            }
          });
        } else {
          await controller.startVideoRecording();
          setState(() {
            _isRecording = true;
          });
        }
      } else {
        final file = await controller.takePicture();

        // Callback'i çağır ama navigation'ı geciktir
        widget.onCaptured?.call(file, isVideo: false);

        // Navigation'ı bir sonraki frame'e ertele
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_hasPopped && Navigator.of(context).canPop()) {
            _hasPopped = true;
            Navigator.of(context).pop();
          }
        });
      }
    } catch (e) {
      debugPrint('Capture error: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;

    // Önce mevcut state'i temizle
    setState(() => _isInitialized = false);

    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _initController(_cameras[_cameraIndex]);
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null) return;
    final modes = [
      FlashMode.off,
      FlashMode.auto,
      FlashMode.always,
      FlashMode.torch,
    ];
    final next = modes[(modes.indexOf(_flashMode) + 1) % modes.length];
    try {
      await controller.setFlashMode(next);
      setState(() => _flashMode = next);
    } catch (e) {
      debugPrint('Flash change error: $e');
    }
  }

  IconData _flashIcon(FlashMode mode) {
    switch (mode) {
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.torch:
        return Icons.flashlight_on;
      case FlashMode.off:
        return Icons.flash_off;
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.of(context).padding.top;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Kamera önizleme: 3:4 oranında göster
          if (_isInitialized && _controller != null)
            Center(
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: CameraPreview(_controller!),
              ),
            )
          else
            const Center(child: CircularProgressIndicator()),

          // Üst bar (sol X, sağda kamera çevir ve flash)
          Positioned(
            top: safeTop + 8,
            left: 8,
            right: 8,
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _toggleFlash,
                  icon: Icon(_flashIcon(_flashMode), color: Colors.white),
                ),
                IconButton(
                  onPressed: _switchCamera,
                  icon: const Icon(Icons.cameraswitch, color: Colors.white),
                ),
              ],
            ),
          ),

          // Alt kontrol alanı
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                padding: EdgeInsets.only(bottom: safeBottom > 0 ? 0 : 8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildGalleryStrip(),
                    const SizedBox(height: 8),
                    if (_isRecording)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.fiber_manual_record,
                                color: Colors.red, size: 16),
                            const SizedBox(width: 6),
                            _RecordingTimer(),
                          ],
                        ),
                      ),
                    _buildControls(),
                    const SizedBox(height: 8),
                    _buildModeSwitcher(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        const SizedBox(width: 64),
        GestureDetector(
          onTap: _onShutter,
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 6),
            ),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _isVideoMode && _isRecording ? 28 : 64,
                height: _isVideoMode && _isRecording ? 28 : 64,
                decoration: BoxDecoration(
                  color: _isVideoMode ? Colors.red : Colors.white,
                  borderRadius: BorderRadius.circular(
                    _isVideoMode && _isRecording ? 6 : 999,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 64),
      ],
    );
  }

  Widget _buildModeSwitcher() {
    final selectedStyle = const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w600,
    );
    final unselectedStyle =
        TextStyle(color: Colors.white.withValues(alpha: 0.6));
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: () => setState(() => _isVideoMode = false),
          child: Text(
            'Fotoğraf',
            style: _isVideoMode ? unselectedStyle : selectedStyle,
          ),
        ),
        const SizedBox(width: 12),
        TextButton(
          onPressed: () => setState(() => _isVideoMode = true),
          child: Text(
            'Video',
            style: _isVideoMode ? selectedStyle : unselectedStyle,
          ),
        ),
      ],
    );
  }

  Widget _buildGalleryStrip() {
    if (_galleryLoading) {
      return const SizedBox(
        height: 90,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_recentAssets.isEmpty) return const SizedBox(height: 90);

    return SizedBox(
      height: 90,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        scrollDirection: Axis.horizontal,
        itemCount: _recentAssets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final asset = _recentAssets[index];
          return FutureBuilder<Uint8List?>(
            future: asset.thumbnailDataWithSize(const ThumbnailSize(200, 200)),
            builder: (context, snapshot) {
              final bytes = snapshot.data;
              return GestureDetector(
                onTap: () async {
                  final file = await asset.file;
                  if (file == null) return;
                  final isVideo = asset.type == AssetType.video;

                  // Callback'i çağır ama navigation'ı geciktir
                  widget.onCaptured?.call(XFile(file.path), isVideo: isVideo);

                  // Navigation'ı bir sonraki frame'e ertele
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted &&
                        !_hasPopped &&
                        Navigator.of(context).canPop()) {
                      _hasPopped = true;
                      Navigator.of(context).pop();
                    }
                  });
                },
                child: Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: bytes == null
                          ? const SizedBox.shrink()
                          : Image.memory(bytes, fit: BoxFit.cover),
                    ),
                    if (asset.type == AssetType.video)
                      const Positioned(
                        right: 6,
                        bottom: 6,
                        child: Icon(
                          Icons.videocam,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _RecordingTimer extends StatefulWidget {
  @override
  State<_RecordingTimer> createState() => _RecordingTimerState();
}

class _RecordingTimerState extends State<_RecordingTimer> {
  late Timer _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _elapsed += const Duration(seconds: 1);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final m = twoDigits(_elapsed.inMinutes.remainder(60));
    final s = twoDigits(_elapsed.inSeconds.remainder(60));
    return Text(
      '$m:$s',
      style: const TextStyle(color: Colors.white),
    );
  }
}
