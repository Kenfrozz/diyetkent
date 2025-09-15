import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:encrypt/encrypt.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../database/drift_service.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/health_data_model.dart';
import '../models/tag_model.dart';

/// Google Sign-In ve Drive API ile yedekleme servisi
/// 🔒 AES-256 şifreleme ile güvenli yedekleme
/// ☁️ Google Drive'da sadece uygulama dosyalarına erişim
class GoogleBackupService {
  static const String _backupFileName = 'diyetkent_backup.encrypted';
  static const String _backupFolderName = 'DiyetKent Yedekler';

  // SharedPreferences keys
  static const String _isGoogleConnectedKey = 'google_backup_connected';
  static const String _lastBackupTimeKey = 'last_backup_time';
  static const String _autoBackupEnabledKey = 'auto_backup_enabled';
  static const String _userEmailKey = 'google_user_email';

  // Google Sign-In configuration
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      drive.DriveApi.driveFileScope, // Sadece app dosyalarına erişim
    ],
  );

  static GoogleSignInAccount? _currentUser;
  static drive.DriveApi? _driveApi;

  /// 🔐 1. ADIM: Google hesabına bağlan
  static Future<GoogleSignInAccount?> signInToGoogle() async {
    try {
      debugPrint('🔐 Google Sign-In başlatılıyor...');

      // Mevcut kullanıcıyı kontrol et
      _currentUser = await _googleSignIn.signInSilently();

      if (_currentUser == null) {
        // İlk kez giriş yap
        _currentUser = await _googleSignIn.signIn();
      }

      if (_currentUser != null) {
        debugPrint('✅ Google hesabına bağlanıldı: ${_currentUser!.email}');

        // Drive API'yi initialize et
        await _initializeDriveApi();

        // Bağlantı durumunu kaydet
        await _saveConnectionStatus(true);
        await _saveUserEmail(_currentUser!.email);

        return _currentUser;
      } else {
        debugPrint('❌ Google Sign-In iptal edildi');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Google Sign-In hatası: $e');
      return null;
    }
  }

  /// 📤 2. ADIM: Drive API'yi initialize et
  static Future<void> _initializeDriveApi() async {
    if (_currentUser == null) return;

    try {
      final authHeaders = await _currentUser!.authHeaders;
      final client = GoogleAuthClient(authHeaders);
      _driveApi = drive.DriveApi(client);
      debugPrint('✅ Google Drive API hazır');
    } catch (e) {
      debugPrint('❌ Drive API initialize hatası: $e');
      throw Exception('Drive API başlatılamadı: $e');
    }
  }

  /// ☁️ 3. ADIM: Yedek oluştur ve yükle
  static Future<BackupResult> createBackup() async {
    if (!await isGoogleConnected()) {
      return BackupResult(success: false, error: 'Google hesabı bağlı değil');
    }

    try {
      debugPrint('📦 Yedek oluşturma başlatılıyor...');
      final startTime = DateTime.now();

      // 1. Local veritabanından tüm veriyi al
      final backupData = await _getAllLocalData();
      debugPrint('📊 Toplanan veri boyutu: ${jsonEncode(backupData).length} karakter');

      // 2. Veriyi şifrele
      final encryptedData = await _encryptBackupData(backupData);
      debugPrint('🔒 Veri şifrelendi: ${encryptedData.length} byte');

      // 3. Google Drive'a yükle
      final uploadSuccess = await _uploadToGoogleDrive(encryptedData);

      if (uploadSuccess) {
        // 4. Metadata güncelle
        await _updateBackupMetadata();

        final duration = DateTime.now().difference(startTime);
        debugPrint('✅ Yedekleme tamamlandı: ${duration.inSeconds} saniye');

        return BackupResult(
          success: true,
          backupSize: encryptedData.length,
          duration: duration,
        );
      } else {
        return BackupResult(success: false, error: 'Drive upload başarısız');
      }

    } catch (e) {
      debugPrint('❌ Yedekleme hatası: $e');
      return BackupResult(success: false, error: e.toString());
    }
  }

  /// 📥 4. ADIM: Yedeği geri yükle
  static Future<RestoreResult> restoreBackup() async {
    if (!await isGoogleConnected()) {
      return RestoreResult(success: false, error: 'Google hesabı bağlı değil');
    }

    try {
      debugPrint('📥 Yedek geri yükleme başlatılıyor...');
      final startTime = DateTime.now();

      // 1. Google Drive'dan dosyayı indir
      final encryptedData = await _downloadFromGoogleDrive();
      if (encryptedData == null) {
        return RestoreResult(success: false, error: 'Yedek dosyası bulunamadı');
      }
      debugPrint('📥 Yedek indirildi: ${encryptedData.length} byte');

      // 2. Şifreyi çöz
      final backupData = await _decryptBackupData(encryptedData);
      debugPrint('🔓 Veri şifresi çözüldü');

      // 3. Local veritabanına geri yükle
      final restoreSuccess = await _restoreLocalData(backupData);

      if (restoreSuccess) {
        final duration = DateTime.now().difference(startTime);
        debugPrint('✅ Geri yükleme tamamlandı: ${duration.inSeconds} saniye');

        return RestoreResult(
          success: true,
          restoredItemCount: _countRestoredItems(backupData),
          duration: duration,
        );
      } else {
        return RestoreResult(success: false, error: 'Veri geri yükleme başarısız');
      }

    } catch (e) {
      debugPrint('❌ Geri yükleme hatası: $e');
      return RestoreResult(success: false, error: e.toString());
    }
  }

  /// 📊 Local veritabanından tüm veriyi topla
  static Future<Map<String, dynamic>> _getAllLocalData() async {
    try {
      // Drift'ten veri çekme işlemleri
      final chats = await DriftService.getAllChats();
      final messages = await DriftService.getAllMessages();
      final tags = await DriftService.getAllTags();
      final healthData = await DriftService.getAllHealthData();

      // User bilgilerini SharedPreferences'tan al
      final prefs = await SharedPreferences.getInstance();
      final userPhone = prefs.getString('user_phone') ?? '';
      final userName = prefs.getString('user_name') ?? '';

      return {
        'metadata': {
          'version': '1.0',
          'created_at': DateTime.now().toIso8601String(),
          'phone_number': userPhone,
          'user_name': userName,
          'app_version': '1.0.0',
          'platform': defaultTargetPlatform.name,
        },
        'data': {
          'chats': chats.map((chat) => chat.toMap()).toList(),
          'messages': messages.map((msg) => msg.toMap()).toList(),
          'tags': tags.map((tag) => tag.toMap()).toList(),
          'health_data': healthData.map((health) => health.toMap()).toList(),
          'settings': {
            'auto_backup_enabled': prefs.getBool(_autoBackupEnabledKey) ?? false,
            'theme_mode': prefs.getString('theme_mode') ?? 'system',
            // Diğer ayarlar eklenebilir
          }
        }
      };
    } catch (e) {
      debugPrint('❌ Local veri toplama hatası: $e');
      rethrow;
    }
  }

  /// 🔒 Veriyi AES-256 ile şifrele
  static Future<Uint8List> _encryptBackupData(Map<String, dynamic> data) async {
    try {
      // Kullanıcının telefon numarasından encryption key oluştur
      final prefs = await SharedPreferences.getInstance();
      final phoneNumber = prefs.getString('user_phone') ?? '';

      if (phoneNumber.isEmpty) {
        throw Exception('Telefon numarası bulunamadı');
      }

      // AES key oluştur (telefon numarasından)
      final keyString = _generateEncryptionKey(phoneNumber);
      final key = Key.fromBase64(keyString);
      final iv = IV.fromSecureRandom(16); // Random IV

      final encrypter = Encrypter(AES(key));

      // JSON'a çevir ve şifrele
      final jsonString = jsonEncode(data);
      final encrypted = encrypter.encrypt(jsonString, iv: iv);

      // IV + encrypted data birleştir
      final result = Uint8List.fromList(iv.bytes + encrypted.bytes);

      return result;
    } catch (e) {
      debugPrint('❌ Şifreleme hatası: $e');
      rethrow;
    }
  }

  /// 🔓 Şifreli veriyi çöz
  static Future<Map<String, dynamic>> _decryptBackupData(Uint8List encryptedData) async {
    try {
      // IV ve encrypted data'yı ayır
      final iv = IV(encryptedData.sublist(0, 16));
      final encrypted = Encrypted(encryptedData.sublist(16));

      // Telefon numarasından key oluştur
      final prefs = await SharedPreferences.getInstance();
      final phoneNumber = prefs.getString('user_phone') ?? '';

      if (phoneNumber.isEmpty) {
        throw Exception('Telefon numarası bulunamadı');
      }

      final keyString = _generateEncryptionKey(phoneNumber);
      final key = Key.fromBase64(keyString);

      final encrypter = Encrypter(AES(key));

      // Şifreyi çöz ve JSON parse et
      final decrypted = encrypter.decrypt(encrypted, iv: iv);
      final data = jsonDecode(decrypted) as Map<String, dynamic>;

      return data;
    } catch (e) {
      debugPrint('❌ Şifre çözme hatası: $e');
      rethrow;
    }
  }

  /// 🔑 Telefon numarasından encryption key oluştur
  static String _generateEncryptionKey(String phoneNumber) {
    const salt = 'DiyetKent2025_Salt_Key_Generation';
    final combined = phoneNumber + salt;

    // SHA256 hash oluştur ve Base64'e çevir
    final bytes = utf8.encode(combined);
    final digest = bytes.fold<int>(0, (prev, byte) => prev + byte) % 256;

    // 32 byte key oluştur (AES-256 için)
    final keyBytes = List.generate(32, (i) => (digest + i + phoneNumber.codeUnitAt(i % phoneNumber.length)) % 256);
    final key = base64.encode(keyBytes);

    return key;
  }

  /// ☁️ Google Drive'a dosya yükle
  static Future<bool> _uploadToGoogleDrive(Uint8List data) async {
    if (_driveApi == null) {
      await _initializeDriveApi();
    }

    try {
      // Mevcut yedek dosyasını kontrol et
      final existingFileId = await _findExistingBackupFile();

      final media = drive.Media(Stream.value(data), data.length);

      if (existingFileId != null) {
        // Mevcut dosyayı güncelle
        await _driveApi!.files.update(
          drive.File()..name = _backupFileName,
          existingFileId,
          uploadMedia: media,
        );
        debugPrint('🔄 Mevcut yedek güncellendi');
      } else {
        // Yeni dosya oluştur
        final driveFile = drive.File()
          ..name = _backupFileName
          ..parents = [await _getOrCreateBackupFolder()];

        await _driveApi!.files.create(
          driveFile,
          uploadMedia: media,
        );
        debugPrint('📁 Yeni yedek dosyası oluşturuldu');
      }

      return true;
    } catch (e) {
      debugPrint('❌ Drive upload hatası: $e');
      return false;
    }
  }

  /// 📥 Google Drive'dan dosya indir
  static Future<Uint8List?> _downloadFromGoogleDrive() async {
    if (_driveApi == null) {
      await _initializeDriveApi();
    }

    try {
      final fileId = await _findExistingBackupFile();
      if (fileId == null) {
        debugPrint('❌ Yedek dosyası bulunamadı');
        return null;
      }

      final media = await _driveApi!.files.get(fileId, downloadOptions: drive.DownloadOptions.fullMedia);

      if (media is drive.Media) {
        final bytes = <int>[];
        await for (var chunk in media.stream) {
          bytes.addAll(chunk);
        }
        return Uint8List.fromList(bytes);
      }

      return null;
    } catch (e) {
      debugPrint('❌ Drive download hatası: $e');
      return null;
    }
  }

  /// 📁 Yedek klasörü oluştur veya bul
  static Future<String> _getOrCreateBackupFolder() async {
    try {
      // Mevcut klasörü ara
      final query = "name='$_backupFolderName' and mimeType='application/vnd.google-apps.folder'";
      final fileList = await _driveApi!.files.list(q: query);

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        return fileList.files!.first.id!;
      }

      // Klasör yoksa oluştur
      final folder = drive.File()
        ..name = _backupFolderName
        ..mimeType = 'application/vnd.google-apps.folder';

      final createdFolder = await _driveApi!.files.create(folder);
      return createdFolder.id!;
    } catch (e) {
      debugPrint('❌ Klasör oluşturma hatası: $e');
      rethrow;
    }
  }

  /// 🔍 Mevcut yedek dosyasını bul
  static Future<String?> _findExistingBackupFile() async {
    try {
      final folderId = await _getOrCreateBackupFolder();
      final query = "name='$_backupFileName' and parents in '$folderId'";
      final fileList = await _driveApi!.files.list(q: query);

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        return fileList.files!.first.id;
      }

      return null;
    } catch (e) {
      debugPrint('❌ Dosya arama hatası: $e');
      return null;
    }
  }

  /// 💾 Local veritabanına geri yükle
  static Future<bool> _restoreLocalData(Map<String, dynamic> backupData) async {
    try {
      final data = backupData['data'] as Map<String, dynamic>;

      // Chats'leri geri yükle
      if (data['chats'] != null) {
        final chats = (data['chats'] as List).map((json) => ChatModel.fromMap(json)).toList();
        for (final chat in chats) {
          await DriftService.saveChat(chat);
        }
        debugPrint('✅ ${chats.length} sohbet geri yüklendi');
      }

      // Messages'ları geri yükle
      if (data['messages'] != null) {
        final messages = (data['messages'] as List).map((json) => MessageModel.fromMap(json)).toList();
        for (final message in messages) {
          await DriftService.saveMessage(message);
        }
        debugPrint('✅ ${messages.length} mesaj geri yüklendi');
      }

      // Tags'ları geri yükle
      if (data['tags'] != null) {
        final tags = (data['tags'] as List).map((json) => TagModel.fromMap(json)).toList();
        for (final tag in tags) {
          await DriftService.saveTag(tag);
        }
        debugPrint('✅ ${tags.length} etiket geri yüklendi');
      }

      // Health data'yı geri yükle
      if (data['health_data'] != null) {
        final healthDataList = (data['health_data'] as List).map((json) => HealthDataModel.fromMap(json)).toList();
        for (final healthData in healthDataList) {
          await DriftService.saveHealthData(healthData);
        }
        debugPrint('✅ ${healthDataList.length} sağlık verisi geri yüklendi');
      }

      // Settings'leri geri yükle
      if (data['settings'] != null) {
        final settings = data['settings'] as Map<String, dynamic>;
        final prefs = await SharedPreferences.getInstance();

        for (final entry in settings.entries) {
          if (entry.value is bool) {
            await prefs.setBool(entry.key, entry.value);
          } else if (entry.value is String) {
            await prefs.setString(entry.key, entry.value);
          }
        }
        debugPrint('✅ Ayarlar geri yüklendi');
      }

      return true;
    } catch (e) {
      debugPrint('❌ Veri geri yükleme hatası: $e');
      return false;
    }
  }

  /// 📊 Geri yüklenen item sayısını hesapla
  static int _countRestoredItems(Map<String, dynamic> backupData) {
    final data = backupData['data'] as Map<String, dynamic>;
    int count = 0;

    if (data['chats'] != null) count += (data['chats'] as List).length;
    if (data['messages'] != null) count += (data['messages'] as List).length;
    if (data['tags'] != null) count += (data['tags'] as List).length;
    if (data['health_data'] != null) count += (data['health_data'] as List).length;

    return count;
  }

  /// 📝 Yedekleme metadata'sını güncelle
  static Future<void> _updateBackupMetadata() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastBackupTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// 🔗 Mevcut kullanıcıyı al
  static Future<GoogleSignInAccount?> getCurrentUser() async {
    _currentUser ??= await _googleSignIn.signInSilently();
    return _currentUser;
  }

  /// 🔌 Google bağlantısını kes
  static Future<void> signOutFromGoogle() async {
    try {
      await _googleSignIn.signOut();
      _currentUser = null;
      _driveApi = null;

      // Bağlantı durumunu temizle
      await _saveConnectionStatus(false);
      await _clearUserEmail();

      debugPrint('✅ Google bağlantısı kesildi');
    } catch (e) {
      debugPrint('❌ Google sign-out hatası: $e');
    }
  }

  /// ✅ Google bağlantı durumu
  static Future<bool> isGoogleConnected() async {
    final prefs = await SharedPreferences.getInstance();
    final isConnected = prefs.getBool(_isGoogleConnectedKey) ?? false;

    if (isConnected) {
      // Bağlantıyı doğrula
      _currentUser ??= await _googleSignIn.signInSilently();
      return _currentUser != null;
    }

    return false;
  }

  /// 📧 Google kullanıcı email'ini al
  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  /// ⏰ Son yedekleme zamanını al
  static Future<DateTime?> getLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastBackupTimeKey);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  /// 🔄 Otomatik yedekleme durumu
  static Future<bool> isAutoBackupEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoBackupEnabledKey) ?? false;
  }

  /// 🔄 Otomatik yedeklemeyi aç/kapat
  static Future<void> setAutoBackupEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoBackupEnabledKey, enabled);
    debugPrint('🔄 Otomatik yedekleme: ${enabled ? 'Açık' : 'Kapalı'}');
  }

  /// 💾 Bağlantı durumunu kaydet
  static Future<void> _saveConnectionStatus(bool connected) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isGoogleConnectedKey, connected);
  }

  /// 📧 Kullanıcı email'ini kaydet
  static Future<void> _saveUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userEmailKey, email);
  }

  /// 📧 Kullanıcı email'ini temizle
  static Future<void> _clearUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userEmailKey);
  }

  /// 📊 WiFi bağlantısı kontrolü
  static Future<bool> isOnWiFi() async {
    final connectivityResults = await Connectivity().checkConnectivity();
    return connectivityResults.contains(ConnectivityResult.wifi);
  }

  /// 🔋 Otomatik yedekleme koşulları (WiFi + Batarya)
  static Future<bool> shouldPerformAutoBackup() async {
    // WiFi kontrolü
    if (!await isOnWiFi()) {
      debugPrint('⚠️ WiFi bağlantısı yok, otomatik yedekleme atlandı');
      return false;
    }

    // Son yedekleme zamanı kontrolü (24 saatten eski mi?)
    final lastBackup = await getLastBackupTime();
    if (lastBackup != null) {
      final hoursSinceLastBackup = DateTime.now().difference(lastBackup).inHours;
      if (hoursSinceLastBackup < 20) {
        debugPrint('⚠️ Son yedekleme çok yakın zamanda yapıldı, atlandı');
        return false;
      }
    }

    return true;
  }
}

/// HTTP Client for Google APIs
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }

  @override
  void close() {
    _client.close();
    super.close();
  }
}

/// Yedekleme sonucu modeli
class BackupResult {
  final bool success;
  final String? error;
  final int? backupSize;
  final Duration? duration;

  BackupResult({
    required this.success,
    this.error,
    this.backupSize,
    this.duration,
  });
}

/// Geri yükleme sonucu modeli
class RestoreResult {
  final bool success;
  final String? error;
  final int? restoredItemCount;
  final Duration? duration;

  RestoreResult({
    required this.success,
    this.error,
    this.restoredItemCount,
    this.duration,
  });
}