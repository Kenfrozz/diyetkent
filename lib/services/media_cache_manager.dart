import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';

class MediaCacheManager {
  static const String _lastCleanupKey = 'last_media_cleanup';
  static const int _maxCacheAgeDays = 30;
  static const int _maxCacheSizeMB = 500; // 500MB maksimum cache
  static const String _indexFile = 'media_index.json';

  // 🔥 MALIYET OPTIMIZASYONU: Otomatik medya temizleme
  static Future<void> performAutoCleanup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCleanup = prefs.getInt(_lastCleanupKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Son temizlemeden 24 saat geçtiyse temizle
      if (now - lastCleanup > 24 * 60 * 60 * 1000) {
        await cleanOldMediaFiles();
        await prefs.setInt(_lastCleanupKey, now);
        debugPrint('✅ Otomatik medya temizleme tamamlandı');
      }
    } catch (e) {
      debugPrint('❌ Otomatik temizleme hatası: $e');
    }
  }

  // URL -> local path sözlüğü tutan basit indeks
  static Future<File> _getIndexFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final mediaDir = Directory('${directory.path}/media_cache');
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }
    return File('${mediaDir.path}/$_indexFile');
  }

  static Future<Map<String, String>> _readIndex() async {
    try {
      final f = await _getIndexFile();
      if (!await f.exists()) return {};
      final txt = await f.readAsString();
      if (txt.isEmpty) return {};
      final Map<String, dynamic> jsonMap = Map<String, dynamic>.from(
        txt.isNotEmpty ? (jsonDecode(txt) as Map<String, dynamic>) : {},
      );
      return jsonMap.map((k, v) => MapEntry(k, v as String));
    } catch (_) {
      return {};
    }
  }

  static Future<void> _writeIndex(Map<String, String> map) async {
    try {
      final f = await _getIndexFile();
      await f.writeAsString(jsonEncode(map));
    } catch (_) {}
  }

  // Varsa cache patikasını döndür
  static Future<String?> getCachedPathIfExists(String url) async {
    final index = await _readIndex();
    final p = index[url];
    if (p == null) return null;
    final file = File(p);
    if (await file.exists()) return p;
    // Kullanıcı cihazdan silmişse indeks de temizlenir
    index.remove(url);
    await _writeIndex(index);
    return null;
  }

  // İndirip cache’e yerleştir ve indeksle
  static Future<String?> downloadToCache(String url) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final mediaDir = Directory('${directory.path}/media_cache');
      if (!await mediaDir.exists()) await mediaDir.create(recursive: true);

      // Dosya adı: URL'nin sabit uzunluklu güvenli hash'i (uzun dosya adı hatalarını önler)
      final safe = sha1.convert(utf8.encode(url)).toString(); // 40 hex karakter
      // Basit uzantı çıkarımı
      final ext = _guessExtFromUrl(url);
      final file = File('${mediaDir.path}/$safe$ext');

      if (await file.exists()) return file.path;

      final client = HttpClient();
      final req = await client.getUrl(Uri.parse(url));
      final resp = await req.close();
      final bytes = <int>[];
      await for (final chunk in resp) {
        bytes.addAll(chunk);
      }
      await file.writeAsBytes(bytes);

      // Indeks güncelle
      final index = await _readIndex();
      index[url] = file.path;
      await _writeIndex(index);

      return file.path;
    } catch (e) {
      debugPrint('❌ Cache indirme hatası: $e');
      return null;
    }
  }

  static String _guessExtFromUrl(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('.jpg') || lower.contains('.jpeg')) return '.jpg';
    if (lower.contains('.png')) return '.png';
    if (lower.contains('.webp')) return '.webp';
    if (lower.contains('.gif')) return '.gif';
    if (lower.contains('.mp4') || lower.contains('.m4v')) return '.mp4';
    if (lower.contains('.mov')) return '.mov';
    if (lower.contains('.mp3')) return '.mp3';
    if (lower.contains('.m4a') || lower.contains('.aac')) return '.m4a';
    if (lower.contains('.pdf')) return '.pdf';
    if (lower.contains('.docx')) return '.docx';
    if (lower.contains('.doc')) return '.doc';
    if (lower.contains('.xlsx')) return '.xlsx';
    if (lower.contains('.xls')) return '.xls';
    if (lower.contains('.txt')) return '.txt';
    return '';
  }

  // Eski medya dosyalarını temizle
  static Future<void> cleanOldMediaFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final mediaDir = Directory('${directory.path}/media_cache');

      if (!await mediaDir.exists()) return;

      final files = mediaDir.listSync(recursive: true);
      final now = DateTime.now();
      int deletedCount = 0;
      int freedSpaceMB = 0;

      for (final entity in files) {
        if (entity is File) {
          final stat = await entity.stat();
          final age = now.difference(stat.modified);

          if (age.inDays > _maxCacheAgeDays) {
            final sizeMB = stat.size / (1024 * 1024);
            await entity.delete();
            deletedCount++;
            freedSpaceMB += sizeMB.round();
          }
        }
      }

      debugPrint(
        '🗑️ $deletedCount dosya silindi, ${freedSpaceMB}MB alan boşaltıldı',
      );
    } catch (e) {
      debugPrint('❌ Medya temizleme hatası: $e');
    }
  }

  // Cache boyutunu kontrol et ve gerekirse temizle
  static Future<void> manageCacheSize() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final mediaDir = Directory('${directory.path}/media_cache');

      if (!await mediaDir.exists()) return;

      final files = mediaDir.listSync(recursive: true);
      int totalSizeMB = 0;
      final fileStats = <FileSystemEntity, FileStat>{};

      // Tüm dosyaların boyutunu hesapla
      for (final entity in files) {
        if (entity is File) {
          final stat = await entity.stat();
          fileStats[entity] = stat;
          totalSizeMB += (stat.size / (1024 * 1024)).round();
        }
      }

      // Cache boyutu limiti aştıysa eski dosyaları sil
      if (totalSizeMB > _maxCacheSizeMB) {
        final sortedFiles = fileStats.entries.toList();
        sortedFiles.sort(
          (a, b) => a.value.modified.compareTo(b.value.modified),
        );

        int deletedSizeMB = 0;
        for (final entry in sortedFiles) {
          if (totalSizeMB - deletedSizeMB <= _maxCacheSizeMB) break;

          final sizeMB = (entry.value.size / (1024 * 1024)).round();
          await entry.key.delete();
          deletedSizeMB += sizeMB;
        }

        debugPrint('📦 Cache boyutu ${deletedSizeMB}MB azaltıldı');
      }
    } catch (e) {
      debugPrint('❌ Cache boyut yönetimi hatası: $e');
    }
  }

  // Büyük dosyaları tespit et
  static Future<List<File>> findLargeFiles({int minSizeMB = 10}) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final mediaDir = Directory('${directory.path}/media_cache');

      if (!await mediaDir.exists()) return [];

      final files = mediaDir.listSync(recursive: true);
      final largeFiles = <File>[];

      for (final entity in files) {
        if (entity is File) {
          final stat = await entity.stat();
          final sizeMB = stat.size / (1024 * 1024);

          if (sizeMB >= minSizeMB) {
            largeFiles.add(entity);
          }
        }
      }

      return largeFiles;
    } catch (e) {
      debugPrint('❌ Büyük dosya tespiti hatası: $e');
      return [];
    }
  }

  // Kullanıcıya depolama uyarısı göster
  static Future<void> showStorageWarningIfNeeded(BuildContext context) async {
    try {
      final largeFiles = await findLargeFiles(minSizeMB: 20);

      if (largeFiles.length > 10) {
        // 10'dan fazla büyük dosya varsa
        if (context.mounted) {
          _showStorageDialog(context, largeFiles.length);
        }
      }
    } catch (e) {
      debugPrint('❌ Depolama uyarısı hatası: $e');
    }
  }

  static void _showStorageDialog(BuildContext context, int fileCount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Depolama Uyarısı'),
        content: Text(
          '$fileCount büyük medya dosyası bulundu. '
          'Uygulamanın performansını artırmak için bu dosyaları temizlemek ister misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Daha Sonra'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await cleanOldMediaFiles();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Medya dosyaları temizlendi'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
  }

  // Cache istatistiklerini al
  static Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final mediaDir = Directory('${directory.path}/media_cache');

      if (!await mediaDir.exists()) {
        return {
          'totalFiles': 0,
          'totalSizeMB': 0,
          'oldFiles': 0,
          'largeFiles': 0,
        };
      }

      final files = mediaDir.listSync(recursive: true);
      final now = DateTime.now();

      int totalFiles = 0;
      int totalSizeMB = 0;
      int oldFiles = 0;
      int largeFiles = 0;

      for (final entity in files) {
        if (entity is File) {
          final stat = await entity.stat();
          final sizeMB = stat.size / (1024 * 1024);
          final age = now.difference(stat.modified);

          totalFiles++;
          totalSizeMB += sizeMB.round();

          if (age.inDays > _maxCacheAgeDays) oldFiles++;
          if (sizeMB >= 10) largeFiles++;
        }
      }

      return {
        'totalFiles': totalFiles,
        'totalSizeMB': totalSizeMB,
        'oldFiles': oldFiles,
        'largeFiles': largeFiles,
      };
    } catch (e) {
      debugPrint('❌ Cache istatistik hatası: $e');
      return {
        'totalFiles': 0,
        'totalSizeMB': 0,
        'oldFiles': 0,
        'largeFiles': 0,
      };
    }
  }

  // Manuel temizleme
  static Future<bool> clearAllCache() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final mediaDir = Directory('${directory.path}/media_cache');

      if (await mediaDir.exists()) {
        await mediaDir.delete(recursive: true);
        debugPrint('🗑️ Tüm medya cache temizlendi');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Cache temizleme hatası: $e');
      return false;
    }
  }
}
