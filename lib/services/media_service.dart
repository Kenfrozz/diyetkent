import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';
import 'package:uuid/uuid.dart';
import 'firebase_usage_tracker.dart';

typedef UploadProgressCallback = void Function(double progress0to1);

class MediaService {
  static final MediaService _instance = MediaService._internal();
  factory MediaService() => _instance;
  MediaService._internal();

  // Varsayılan Firebase Storage instance'ı kullan (firebase_options içindeki bucket)
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();
  final Uuid _uuid = const Uuid();

  /// Firebase Storage bağlantısını test et (yalnızca debug)
  Future<bool> testStorageConnection() async {
    if (!kDebugMode) return true;
    debugPrint('🔗 Testing Storage connection to: ${_storage.bucket}');

    // Önce mevcut bucket'ı test et
    try {
      final testRef = _storage.ref().child('test/connection_test.txt');
      final testData = Uint8List.fromList(
        'Test connection - ${DateTime.now()}'.codeUnits,
      );

      debugPrint('📤 Uploading test file...');
      await testRef.putData(testData);

      debugPrint('📥 Downloading test file...');
      final downloadUrl = await testRef.getDownloadURL();

      debugPrint('🗑️ Cleaning up test file...');
      await testRef.delete(); // Test dosyasını temizle

      debugPrint('✅ Storage bağlantısı başarılı!');
      debugPrint('📍 Bucket: ${_storage.bucket}');
      debugPrint('🌐 Download URL format: $downloadUrl');
      return true;
    } catch (e) {
      debugPrint('❌ Storage bağlantı testi başarısız: $e');
      debugPrint('💡 Bucket: ${_storage.bucket}');

      // Hata tipine göre öneriler
      if (e.toString().contains('object-not-found') ||
          e.toString().contains('404')) {
        debugPrint(
          '💡 Çözüm: Firebase Console\'da Storage bucket\'ının aktif olduğunu kontrol edin',
        );
        debugPrint(
          '💡 URL: https://console.firebase.google.com/project/diyetkent-67a1a/storage',
        );
      } else if (e.toString().contains('permission-denied') ||
          e.toString().contains('403')) {
        debugPrint('💡 Çözüm: Storage Rules\'da test klasörü için izin verin');
      }

      return false;
    }
  }

  /// Galeri'den fotoğraf seç
  Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280, // 1920'den 1280'e düşürüldü
        maxHeight: 720, // 1080'den 720'ye düşürüldü
        imageQuality: 60, // 80'den 60'a düşürüldü
      );
      return image;
    } catch (e) {
      debugPrint('❌ Galeri fotoğraf seçme hatası: $e');
      return null;
    }
  }

  /// Kamera ile fotoğraf çek
  Future<XFile?> takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1280, // 1920'den 1280'e düşürüldü
        maxHeight: 720, // 1080'den 720'ye düşürüldü
        imageQuality: 60, // 80'den 60'a düşürüldü
      );
      return image;
    } catch (e) {
      debugPrint('❌ Kamera fotoğraf çekme hatası: $e');
      return null;
    }
  }

  /// Galeri'den video seç
  Future<XFile?> pickVideoFromGallery() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5), // 5 dakika max
      );
      return video;
    } catch (e) {
      debugPrint('❌ Galeri video seçme hatası: $e');
      return null;
    }
  }

  /// Kamera ile video çek
  Future<XFile?> recordVideo() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 2), // 2 dakika max
      );
      return video;
    } catch (e) {
      debugPrint('❌ Kamera video çekme hatası: $e');
      return null;
    }
  }

  /// Dosya seç (belgeler)
  Future<PlatformFile?> pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Dosya boyut kontrolü (10MB limit)
        if (file.size > 10 * 1024 * 1024) {
          throw Exception('Dosya boyutu 10MB\'dan büyük olamaz');
        }

        return file;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Dosya seçme hatası: $e');
      rethrow;
    }
  }

  /// Firebase Storage'a fotoğraf yükle
  Future<String?> uploadImage(
    XFile imageFile,
    String chatId, {
    UploadProgressCallback? onProgress,
  }) async {
    try {
      // Debug'ta bağlantıyı sadece bir kez test et (hata olsa bile devam et)
      if (kDebugMode) {
        // Arka planda beklemeden çalıştır
        // Ağ ve App Check sebepli sık tetiklemeleri engellemek için tek seferlik
        // basit bir guard kullanıyoruz.
        // ignore: invalid_use_of_visible_for_testing_member
        _OneTimeGuards.runOnce('storage_test', () => testStorageConnection());
      }

      final String fileName = '${_uuid.v4()}_${path.basename(imageFile.path)}';
      final String filePath = 'chats/$chatId/images/$fileName';
      debugPrint('⬆️ uploadImage -> $filePath');

      // Dosya varlığını kontrol et
      final fileOnDisk = File(imageFile.path);
      if (!await fileOnDisk.exists()) {
        throw Exception('Dosya bulunamadı: ${imageFile.path}');
      }

      // Gerekirse resmi sıkıştır
      final File fileToUpload = await _compressImageIfNeeded(fileOnDisk);

      // Dosyayı Firebase Storage'a yükle - putFile (bellek dostu)
      final Reference storageRef = _storage.ref().child(filePath);
      final contentType = _guessImageContentType(imageFile.path);

      final int uploadBytes = await fileToUpload.length();
      await FirebaseUsageTracker.trackUpload(uploadBytes / (1024 * 1024));

      // putFile kullanımı diskten stream ederek bellek kullanımını azaltır.
      final uploadTask = storageRef.putFile(
        fileToUpload,
        SettableMetadata(
          contentType: contentType,
          customMetadata: {
            'uploadTime': DateTime.now().toIso8601String(),
            'chatId': chatId,
            'originalName': path.basename(imageFile.path),
          },
        ),
      );

      final sub = uploadTask.snapshotEvents.listen((snapshot) {
        final total = snapshot.totalBytes;
        final transferred = snapshot.bytesTransferred;
        if (total > 0 && onProgress != null) {
          onProgress((transferred / total).clamp(0, 1));
        }
      });

      final TaskSnapshot snapshot = await uploadTask;
      await sub.cancel();

      // Download URL'i al
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('✅ Fotoğraf yüklendi: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Fotoğraf yükleme hatası: $e');

      // Hata tipine göre özel mesajlar
      if (e.toString().contains('object-not-found')) {
        debugPrint(
          '💡 İpucu: Firebase Storage rules veya bucket konfigürasyonu kontrol edin',
        );
      } else if (e.toString().contains('permission-denied')) {
        debugPrint('💡 İpucu: Storage security rules izinleri kontrol edin');
      } else if (e.toString().contains('Too many attempts')) {
        debugPrint('💡 İpucu: App Check token limiti aşıldı, biraz bekleyin');
      }

      return null;
    }
  }

  /// Story için fotoğraf yükle
  Future<String?> uploadStoryImage(
    XFile imageFile, {
    UploadProgressCallback? onProgress,
  }) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Kullanıcı giriş yapmamış');
      final String fileName = '${_uuid.v4()}_${path.basename(imageFile.path)}';
      final String filePath = 'stories/$uid/$fileName';

      final fileOnDisk = File(imageFile.path);
      if (!await fileOnDisk.exists()) {
        throw Exception('Dosya bulunamadı: ${imageFile.path}');
      }

      final File fileToUpload = await _compressImageIfNeeded(fileOnDisk);
      final Reference storageRef = _storage.ref().child(filePath);
      final contentType = _guessImageContentType(imageFile.path);

      final int uploadBytes = await fileToUpload.length();
      await FirebaseUsageTracker.trackUpload(uploadBytes / (1024 * 1024));

      final uploadTask = storageRef.putFile(
        fileToUpload,
        SettableMetadata(contentType: contentType),
      );

      final sub = uploadTask.snapshotEvents.listen((snapshot) {
        final total = snapshot.totalBytes;
        final transferred = snapshot.bytesTransferred;
        if (total > 0 && onProgress != null) {
          onProgress((transferred / total).clamp(0, 1));
        }
      });

      final TaskSnapshot snapshot = await uploadTask;
      await sub.cancel();
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('❌ Story fotoğraf yükleme hatası: $e');
      return null;
    }
  }

  /// Story için video yükle
  Future<String?> uploadStoryVideo(
    XFile videoFile, {
    UploadProgressCallback? onProgress,
  }) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Kullanıcı giriş yapmamış');
      final originalBase = path.basename(videoFile.path);
      final normalizedBase = originalBase.toLowerCase().endsWith('.temp')
          ? originalBase.replaceAll(
              RegExp(r'\.temp$', caseSensitive: false), '.mp4')
          : originalBase;
      final String fileName = '${_uuid.v4()}_$normalizedBase';
      final String filePath = 'stories/$uid/$fileName';

      final fileOnDisk = File(videoFile.path);
      if (!await fileOnDisk.exists()) {
        throw Exception('Video dosyası bulunamadı: ${videoFile.path}');
      }

      final File fileToUpload = await _compressVideoIfNeeded(fileOnDisk);
      final fileSize = await fileToUpload.length();
      if (fileSize > 25 * 1024 * 1024) {
        throw Exception('Video boyutu 25MB\'dan büyük olamaz');
      }

      final Reference storageRef = _storage.ref().child(filePath);
      final contentType = _guessVideoContentType(videoFile.path);
      await FirebaseUsageTracker.trackUpload(fileSize / (1024 * 1024));

      final uploadTask = storageRef.putFile(
        fileToUpload,
        SettableMetadata(contentType: contentType),
      );

      final sub = uploadTask.snapshotEvents.listen((snapshot) {
        final total = snapshot.totalBytes;
        final transferred = snapshot.bytesTransferred;
        if (total > 0 && onProgress != null) {
          onProgress((transferred / total).clamp(0, 1));
        }
      });

      final TaskSnapshot snapshot = await uploadTask;
      await sub.cancel();
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('❌ Story video yükleme hatası: $e');
      return null;
    }
  }

  /// Firebase Storage'a video yükle
  Future<String?> uploadVideo(
    XFile videoFile,
    String chatId, {
    UploadProgressCallback? onProgress,
  }) async {
    try {
      // Bazı cihazlarda kayıt geçici .temp uzantısıyla gelir; .mp4'e normalize edelim
      final originalBase = path.basename(videoFile.path);
      final normalizedBase = originalBase.toLowerCase().endsWith('.temp')
          ? originalBase.replaceAll(
              RegExp(r'\.temp$', caseSensitive: false),
              '.mp4',
            )
          : originalBase;
      final String fileName = '${_uuid.v4()}_$normalizedBase';
      final String filePath = 'chats/$chatId/videos/$fileName';
      debugPrint('⬆️ uploadVideo -> $filePath');

      // Dosya varlığını kontrol et
      final fileOnDisk = File(videoFile.path);
      if (!await fileOnDisk.exists()) {
        throw Exception('Video dosyası bulunamadı: ${videoFile.path}');
      }

      // Gerekirse videoyu sıkıştır
      final File fileToUpload = await _compressVideoIfNeeded(fileOnDisk);

      // Boyutu kontrol et (maks. 25MB)
      final fileSize = await fileToUpload.length();
      debugPrint('📁 Video boyutu (yükleme öncesi): $fileSize bytes');
      if (fileSize > 25 * 1024 * 1024) {
        throw Exception('Video boyutu 25MB\'dan büyük olamaz');
      }

      // Dosyayı Firebase Storage'a yükle (putFile)
      final Reference storageRef = _storage.ref().child(filePath);
      final contentType = _guessVideoContentType(videoFile.path);

      await FirebaseUsageTracker.trackUpload(fileSize / (1024 * 1024));

      final uploadTask = storageRef.putFile(
        fileToUpload,
        SettableMetadata(
          contentType: contentType,
          customMetadata: {
            'uploadTime': DateTime.now().toIso8601String(),
            'chatId': chatId,
          },
        ),
      );

      final sub = uploadTask.snapshotEvents.listen((snapshot) {
        final total = snapshot.totalBytes;
        final transferred = snapshot.bytesTransferred;
        if (total > 0 && onProgress != null) {
          onProgress((transferred / total).clamp(0, 1));
        }
      });

      final TaskSnapshot snapshot = await uploadTask;
      await sub.cancel();

      // Download URL'i al
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('✅ Video yüklendi: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Video yükleme hatası: $e');
      return null;
    }
  }

  String _guessImageContentType(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    switch (ext) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.gif':
        return 'image/gif';
      case '.jpg':
      case '.jpeg':
      default:
        return 'image/jpeg';
    }
  }

  String _guessVideoContentType(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    switch (ext) {
      case '.3gp':
        return 'video/3gpp';
      case '.mov':
        return 'video/quicktime';
      case '.mkv':
        return 'video/x-matroska';
      case '.avi':
        return 'video/x-msvideo';
      case '.m4v':
      case '.mp4':
      default:
        return 'video/mp4';
    }
  }

  String _guessDocumentContentType(String fileName) {
    final ext = path.extension(fileName).toLowerCase();
    switch (ext) {
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.xls':
        return 'application/vnd.ms-excel';
      case '.xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case '.txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  /// Firebase Storage'a ses kaydı yükle
  Future<String?> uploadAudio(
    File audioFile,
    String chatId, {
    UploadProgressCallback? onProgress,
  }) async {
    try {
      if (!await audioFile.exists()) {
        throw Exception('Ses dosyası bulunamadı: ${audioFile.path}');
      }

      final String fileName = '${_uuid.v4()}_${path.basename(audioFile.path)}';
      final String filePath = 'chats/$chatId/audios/$fileName';

      final Reference storageRef = _storage.ref().child(filePath);
      final String ext = path.extension(audioFile.path).toLowerCase();
      final String contentType = ext == '.m4a'
          ? 'audio/mp4'
          : ext == '.aac'
              ? 'audio/aac'
              : 'audio/mpeg';

      final int uploadBytes = await audioFile.length();
      await FirebaseUsageTracker.trackUpload(uploadBytes / (1024 * 1024));

      final uploadTask = storageRef.putFile(
        audioFile,
        SettableMetadata(
          contentType: contentType,
          customMetadata: {
            'uploadTime': DateTime.now().toIso8601String(),
            'chatId': chatId,
          },
        ),
      );

      final sub = uploadTask.snapshotEvents.listen((snapshot) {
        final total = snapshot.totalBytes;
        final transferred = snapshot.bytesTransferred;
        if (total > 0 && onProgress != null) {
          onProgress((transferred / total).clamp(0, 1));
        }
      });

      final TaskSnapshot snapshot = await uploadTask;
      await sub.cancel();

      final String downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('✅ Ses kaydı yüklendi: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Ses kaydı yükleme hatası: $e');
      return null;
    }
  }

  /// Firebase Storage'a belge yükle
  Future<String?> uploadDocument(
    PlatformFile documentFile,
    String chatId, {
    UploadProgressCallback? onProgress,
  }) async {
    try {
      final String fileName = '${_uuid.v4()}_${documentFile.name}';
      final String filePath = 'chats/$chatId/documents/$fileName';

      // Dosyayı Firebase Storage'a yükle
      final Reference storageRef = _storage.ref().child(filePath);

      UploadTask uploadTask;
      if (documentFile.bytes != null) {
        uploadTask = storageRef.putData(
          documentFile.bytes!,
          SettableMetadata(
              contentType: _guessDocumentContentType(documentFile.name)),
        );
      } else if (documentFile.path != null) {
        uploadTask = storageRef.putFile(
          File(documentFile.path!),
          SettableMetadata(
              contentType: _guessDocumentContentType(documentFile.name)),
        );
      } else {
        throw Exception('Dosya verisi bulunamadı');
      }

      final sub = uploadTask.snapshotEvents.listen((snapshot) {
        final total = snapshot.totalBytes;
        final transferred = snapshot.bytesTransferred;
        if (total > 0 && onProgress != null) {
          onProgress((transferred / total).clamp(0, 1));
        }
      });

      final TaskSnapshot snapshot = await uploadTask;
      await sub.cancel();
      String downloadUrl;
      int attempts = 0;
      while (true) {
        try {
          downloadUrl = await snapshot.ref.getDownloadURL();
          break;
        } catch (e) {
          attempts++;
          if (attempts >= 3) rethrow;
          await Future.delayed(const Duration(milliseconds: 600));
        }
      }

      debugPrint('✅ Belge yüklendi: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Belge yükleme hatası: $e');
      return null;
    }
  }

  /// Dosya boyutunu kontrol et (10MB limit)
  bool isFileSizeValid(File file) {
    final int fileSizeInBytes = file.lengthSync();
    final double fileSizeInMB = fileSizeInBytes / (1024 * 1024);
    return fileSizeInMB <= 10; // 10MB limit
  }

  /// Dosya türünü kontrol et
  String getFileType(String filePath) {
    final String extension = path.extension(filePath).toLowerCase();

    switch (extension) {
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
        return 'image';
      case '.mp4':
      case '.mov':
      case '.avi':
      case '.mkv':
        return 'video';
      case '.pdf':
      case '.doc':
      case '.docx':
      case '.txt':
      case '.xls':
      case '.xlsx':
        return 'document';
      default:
        return 'unknown';
    }
  }

  /// Dosya boyutunu okunabilir formata çevir
  String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Thumbnail oluştur (video için)
  Future<Uint8List?> generateVideoThumbnail(String videoPath) async {
    try {
      // Video thumbnail oluşturma işlemi
      // Bu özellik için video_thumbnail paketi gerekebilir
      return null;
    } catch (e) {
      debugPrint('❌ Video thumbnail oluşturma hatası: $e');
      return null;
    }
  }

  // --- Helpers: Compression ---
  Future<File> _compressImageIfNeeded(File input) async {
    try {
      final int originalSize = await input.length();
      // 2MB üstü ise sıkıştır
      if (originalSize <= 2 * 1024 * 1024) return input;

      final tempDir = await getTemporaryDirectory();
      final targetPath = path.join(
        tempDir.path,
        'img_${_uuid.v4()}.jpg',
      );
      final result = await FlutterImageCompress.compressAndGetFile(
        input.path,
        targetPath,
        quality: 70,
        minWidth: 1280,
        minHeight: 720,
      );
      if (result == null) return input;
      return File(result.path);
    } catch (_) {
      return input;
    }
  }

  Future<File> _compressVideoIfNeeded(File input) async {
    try {
      // Hafif bir limit: 12MB üstü ise sıkıştırmayı dene
      final int originalSize = await input.length();
      if (originalSize <= 12 * 1024 * 1024) return input;

      final info = await VideoCompress.compressVideo(
        input.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
      );
      if (info == null || info.path == null) return input;
      final out = File(info.path as String);
      return await out.exists() ? out : input;
    } catch (_) {
      return input;
    }
  }
}

/// Basit tek seferlik çalıştırma koruması (in-memory)
class _OneTimeGuards {
  static final Set<String> _executed = <String>{};

  static void runOnce(String key, FutureOr<void> Function() action) {
    if (_executed.contains(key)) return;
    _executed.add(key);
    // intentionally not awaited
    // ignore: discarded_futures
    action();
  }
}
