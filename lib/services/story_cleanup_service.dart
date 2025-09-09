import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../database/drift_service.dart';

class StoryCleanupService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Tüm story'leri sil (sadece emergency durumlar için)
  static Future<void> deleteAllStories() async {
    if (!kDebugMode) {
      debugPrint('❌ Bu işlem sadece debug modda çalışır!');
      return;
    }

    try {
      debugPrint('🧹 Tüm storyler siliniyor...');

      // Firebase'den batch delete
      const batchSize = 500;
      var query = _firestore.collection('stories').limit(batchSize);
      
      while (true) {
        var snapshot = await query.get();
        if (snapshot.docs.isEmpty) break;

        var batch = _firestore.batch();
        for (var doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        
        await batch.commit();
        debugPrint('✅ ${snapshot.docs.length} story silindi');

        if (snapshot.docs.length < batchSize) break;
      }

      // Yerel veritabanından da temizle
      await DriftService.deleteAllStories();
      
      debugPrint('✅ Tüm storyler başarıyla silindi');
    } catch (e) {
      debugPrint('❌ Story silme hatası: $e');
      throw Exception('Storyler silinemedi: $e');
    }
  }

  /// Sadece duplicate/spam story'leri sil
  static Future<void> cleanupDuplicateStories() async {
    try {
      debugPrint('🧹 Duplicate storyler temizleniyor...');

      // Aynı kullanıcının aynı içerikli storylerini bul
      var snapshot = await _firestore
          .collection('stories')
          .orderBy('createdAt', descending: true)
          .get();

      Map<String, List<QueryDocumentSnapshot>> userStories = {};
      
      // Storyleri kullanıcıya göre grupla
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final userId = data['userId'] as String?;
        final content = data['content'] as String?;
        
        if (userId != null && content != null) {
          final key = '${userId}_$content';
          userStories.putIfAbsent(key, () => []).add(doc);
        }
      }

      var batch = _firestore.batch();
      int deleteCount = 0;

      // Her grup için en eskiler dışındakileri sil
      for (var group in userStories.values) {
        if (group.length > 1) {
          // İlk storyyi tut, diğerlerini sil
          for (int i = 1; i < group.length; i++) {
            batch.delete(group[i].reference);
            deleteCount++;
            
            // Batch limit (500) aşılırsa commit et ve yeni batch başlat
            if (deleteCount % 500 == 0) {
              await batch.commit();
              batch = _firestore.batch();
            }
          }
        }
      }

      if (deleteCount > 0) {
        await batch.commit();
        debugPrint('✅ $deleteCount duplicate story silindi');
      } else {
        debugPrint('ℹ️ Silinecek duplicate story bulunamadı');
      }

      // Yerel veritabanından da temizle
      await DriftService.deleteAllStories();
      
    } catch (e) {
      debugPrint('❌ Duplicate story temizleme hatası: $e');
      throw Exception('Duplicate storyler temizlenemedi: $e');
    }
  }

  /// Eski (süresi dolmuş) story'leri sil
  static Future<void> cleanupExpiredStories() async {
    try {
      debugPrint('🧹 Süresi dolmuş storyler temizleniyor...');

      final now = Timestamp.now();
      var query = _firestore
          .collection('stories')
          .where('expiresAt', isLessThan: now);

      const batchSize = 500;
      var snapshot = await query.limit(batchSize).get();
      
      while (snapshot.docs.isNotEmpty) {
        var batch = _firestore.batch();
        
        for (var doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        
        await batch.commit();
        debugPrint('✅ ${snapshot.docs.length} süresi dolmuş story silindi');

        if (snapshot.docs.length < batchSize) break;
        snapshot = await query.limit(batchSize).get();
      }

      // Yerel veritabanından da temizle
      await DriftService.deleteExpiredStories();

    } catch (e) {
      debugPrint('❌ Expired story temizleme hatası: $e');
      throw Exception('Süresi dolmuş storyler temizlenemedi: $e');
    }
  }

  /// Story sayısını kontrol et
  static Future<int> getStoryCount() async {
    try {
      var snapshot = await _firestore.collection('stories').count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('❌ Story sayısı alınamadı: $e');
      return -1;
    }
  }
}