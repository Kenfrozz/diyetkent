import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class FirebaseUsageTracker {
  static const String _readCountKey = 'firebase_read_count';
  static const String _writeCountKey = 'firebase_write_count';
  static const String _storageDownloadKey = 'storage_download_mb';
  static const String _storageUploadKey = 'storage_upload_mb';
  static const String _lastResetKey = 'last_usage_reset';

  // Günlük sayaçlar
  static int _todayReads = 0;
  static int _todayWrites = 0;
  static double _todayDownloadMB = 0.0;
  static double _todayUploadMB = 0.0;

  // 🔥 MALIYET OPTIMIZASYONU: Firebase kullanım takibi
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final lastReset = prefs.getInt(_lastResetKey) ?? 0;
    final lastResetDate = DateTime.fromMillisecondsSinceEpoch(lastReset);

    // Yeni gün başladıysa sayaçları sıfırla
    if (now.day != lastResetDate.day || now.month != lastResetDate.month) {
      await _resetDailyCounters();
    } else {
      // Günün verilerini yükle
      _todayReads = prefs.getInt(_readCountKey) ?? 0;
      _todayWrites = prefs.getInt(_writeCountKey) ?? 0;
      _todayDownloadMB = prefs.getDouble(_storageDownloadKey) ?? 0.0;
      _todayUploadMB = prefs.getDouble(_storageUploadKey) ?? 0.0;
    }
  }

  // Okuma işlemi sayacı
  static Future<void> incrementRead([int count = 1]) async {
    _todayReads += count;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_readCountKey, _todayReads);

    // Yüksek kullanım uyarısı
    if (_todayReads > 10000) {
      // Günde 10K okuma
      debugPrint(
          '⚠️ UYARI: Günlük Firestore okuma limiti aşılıyor! ($_todayReads)');
    }
  }

  // Yazma işlemi sayacı
  static Future<void> incrementWrite([int count = 1]) async {
    _todayWrites += count;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_writeCountKey, _todayWrites);

    // Yüksek kullanım uyarısı
    if (_todayWrites > 1000) {
      // Günde 1K yazma
      debugPrint(
        '⚠️ UYARI: Günlük Firestore yazma limiti aşılıyor! ($_todayWrites)',
      );
    }
  }

  // Storage download takibi
  static Future<void> trackDownload(double sizeMB) async {
    _todayDownloadMB += sizeMB;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_storageDownloadKey, _todayDownloadMB);

    if (_todayDownloadMB > 100) {
      // Günde 100MB
      debugPrint(
        '⚠️ UYARI: Günlük storage download limiti aşılıyor! (${_todayDownloadMB.toStringAsFixed(1)}MB)',
      );
    }
  }

  // Storage upload takibi
  static Future<void> trackUpload(double sizeMB) async {
    _todayUploadMB += sizeMB;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_storageUploadKey, _todayUploadMB);

    if (_todayUploadMB > 50) {
      // Günde 50MB
      debugPrint(
        '⚠️ UYARI: Günlük storage upload limiti aşılıyor! (${_todayUploadMB.toStringAsFixed(1)}MB)',
      );
    }
  }

  // Günlük istatistikleri al
  static Map<String, dynamic> getDailyStats() {
    final firestoreCost = (_todayReads * 0.0006) + (_todayWrites * 0.0018);
    final storageCost = (_todayDownloadMB * 0.02) + (_todayUploadMB * 0.05);

    return {
      'reads': _todayReads,
      'writes': _todayWrites,
      'downloadMB': _todayDownloadMB,
      'uploadMB': _todayUploadMB,
      'estimatedCostUSD': firestoreCost + storageCost,
      'firestoreCost': firestoreCost,
      'storageCost': storageCost,
    };
  }

  // Günlük raporu yazdır
  static void logDailyUsage() {
    final stats = getDailyStats();
    debugPrint('📊 GÜNLÜK FIREBASE KULLANIMI:');
    debugPrint('   Firestore Okuma: ${stats['reads']}');
    debugPrint('   Firestore Yazma: ${stats['writes']}');
    debugPrint(
        '   Storage Download: ${stats['downloadMB'].toStringAsFixed(1)}MB');
    debugPrint('   Storage Upload: ${stats['uploadMB'].toStringAsFixed(1)}MB');
    debugPrint(
      '   Tahmini Maliyet: \$${stats['estimatedCostUSD'].toStringAsFixed(4)}',
    );
    debugPrint(
        '   ├─ Firestore: \$${stats['firestoreCost'].toStringAsFixed(4)}');
    debugPrint('   └─ Storage: \$${stats['storageCost'].toStringAsFixed(4)}');
  }

  // Aylık tahmini maliyet
  static double getMonthlyEstimate() {
    final daily = getDailyStats()['estimatedCostUSD'] as double;
    return daily * 30; // 30 günlük tahmin
  }

  // Sayaçları sıfırla
  static Future<void> _resetDailyCounters() async {
    final prefs = await SharedPreferences.getInstance();

    // Önce günlük raporu yazdır
    if (_todayReads > 0 || _todayWrites > 0) {
      logDailyUsage();
    }

    // Sayaçları sıfırla
    _todayReads = 0;
    _todayWrites = 0;
    _todayDownloadMB = 0.0;
    _todayUploadMB = 0.0;

    await prefs.setInt(_readCountKey, 0);
    await prefs.setInt(_writeCountKey, 0);
    await prefs.setDouble(_storageDownloadKey, 0.0);
    await prefs.setDouble(_storageUploadKey, 0.0);
    await prefs.setInt(_lastResetKey, DateTime.now().millisecondsSinceEpoch);

    debugPrint('🔄 Günlük Firebase usage sayaçları sıfırlandı');
  }

  // Manuel sayaç sıfırlama
  static Future<void> resetCounters() async {
    await _resetDailyCounters();
  }

  // Kullanım geçmişini JSON olarak al
  static Future<String> getUsageHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = {
      'currentDay': getDailyStats(),
      'lastReset': prefs.getInt(_lastResetKey),
      'monthlyEstimate': getMonthlyEstimate(),
    };

    return jsonEncode(history);
  }

  // Performans metriği - yavaş işlemleri tespit et
  static void trackSlowOperation(String operation, Duration duration) {
    if (duration.inMilliseconds > 2000) {
      // 2 saniyeden fazla
      debugPrint('🐌 YAVAŞ İŞLEM: $operation - ${duration.inMilliseconds}ms');
    }
  }

  // Network durumuna göre uyarı
  static void warnIfOfflineOperationAttempted(String operation) {
    debugPrint(
      '📴 OFFLINE İŞLEM DENENDİ: $operation - Bu işlem maliyet artırabilir',
    );
  }

  // Batch işlem önerisi
  static void suggestBatchOperation(int individualOperations) {
    if (individualOperations > 5) {
      debugPrint(
        '💡 ÖNERİ: $individualOperations tekil işlem yerine batch operation kullanın',
      );
    }
  }
}
