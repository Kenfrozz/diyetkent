import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../database/drift_service.dart';
import '../models/diet_file_model.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class DietFileService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // Kullanıcının diyet dosyalarını getir
  static Future<List<DietFileModel>> getUserDietFiles() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      // Önce Isar'dan dene
      final localFiles = await DriftService.getUserDietFiles(user.uid);
      if (localFiles.isNotEmpty) {
        return localFiles;
      }

      // Isar'da veri yoksa Firestore'dan çek
      final querySnapshot = await _firestore
          .collection('dietFiles')
          .where('userId', isEqualTo: user.uid)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      final dietFiles = querySnapshot.docs
          .map((doc) => DietFileModel.fromMap(doc.data()))
          .toList();

      // Firestore'dan gelen verileri Isar'a kaydet
      for (final dietFile in dietFiles) {
        await DriftService.saveDietFile(dietFile);
      }

      return dietFiles;
    } catch (e) {
      debugPrint('❌ Diyet dosyaları getirme hatası: $e');
      return [];
    }
  }

  // Diyet dosyası oluştur (sadece diyetisyenler için)
  static Future<bool> createDietFile({
    required String userId,
    required String title,
    String description = '',
    File? file,
    String? mealPlan,
    String? restrictions,
    String? recommendations,
    String? targetWeight,
    String? duration,
    String? dietitianNotes,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Diyetisyen yetkisi kontrolü (bu kontrol başka bir serviste olmalı)
      // Şimdilik basit kontrol yapıyoruz
      
      final fileId = '${DateTime.now().millisecondsSinceEpoch}_${userId}';
      String? fileUrl;
      String? fileName;
      String? fileType;
      int? fileSizeBytes;

      // Dosya varsa Storage'a yükle
      if (file != null) {
        final uploadResult = await _uploadDietFile(file, fileId);
        if (uploadResult != null) {
          fileUrl = uploadResult['url'];
          fileName = uploadResult['name'];
          fileType = uploadResult['type'];
          fileSizeBytes = uploadResult['size'];
        }
      }

      // Diyet dosyası modelini oluştur
      final dietFile = DietFileModel.create(
        fileId: fileId,
        userId: userId,
        dietitianId: currentUser.uid,
        title: title,
        description: description,
        fileUrl: fileUrl,
        fileName: fileName,
        fileType: fileType,
        fileSizeBytes: fileSizeBytes,
        mealPlan: mealPlan,
        restrictions: restrictions,
        recommendations: recommendations,
        targetWeight: targetWeight,
        duration: duration,
        dietitianNotes: dietitianNotes,
      );

      // Önce Isar'a kaydet
      await DriftService.saveDietFile(dietFile);

      // Sonra Firestore'a kaydet
      await _firestore
          .collection('dietFiles')
          .doc(fileId)
          .set(dietFile.toMap());

      debugPrint('✅ Diyet dosyası oluşturuldu: $title');
      return true;
    } catch (e) {
      debugPrint('❌ Diyet dosyası oluşturma hatası: $e');
      return false;
    }
  }

  // Diyet dosyasını okundu olarak işaretle
  static Future<bool> markAsRead(String fileId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Isar'da işaretle
      await DriftService.markDietFileAsRead(fileId);

      // Firestore'da işaretle
      await _firestore
          .collection('dietFiles')
          .doc(fileId)
          .update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Diyet dosyası okundu olarak işaretlendi: $fileId');
      return true;
    } catch (e) {
      debugPrint('❌ Diyet dosyası işaretleme hatası: $e');
      return false;
    }
  }

  // Diyet dosyasını sil
  static Future<bool> deleteDietFile(String fileId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Firestore'da pasif yap
      await _firestore
          .collection('dietFiles')
          .doc(fileId)
          .update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Isar'dan sil
      final dietFile = await DriftService.getDietFile(fileId);
      if (dietFile != null) {
        await DriftService.deleteDietFile(dietFile.fileId);
      }

      debugPrint('✅ Diyet dosyası silindi: $fileId');
      return true;
    } catch (e) {
      debugPrint('❌ Diyet dosyası silme hatası: $e');
      return false;
    }
  }

  // Diyetisyenin oluşturduğu dosyaları getir
  static Future<List<DietFileModel>> getDietitianFiles() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final querySnapshot = await _firestore
          .collection('dietFiles')
          .where('dietitianId', isEqualTo: user.uid)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => DietFileModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ Diyetisyen dosyaları getirme hatası: $e');
      return [];
    }
  }

  // Belirli bir kullanıcının diyet dosyalarını getir (diyetisyen için)
  static Future<List<DietFileModel>> getUserDietFilesForDietitian(String userId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      // Diyetisyen yetkisi kontrolü yapılmalı

      final querySnapshot = await _firestore
          .collection('dietFiles')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => DietFileModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ Kullanıcı diyet dosyaları getirme hatası: $e');
      return [];
    }
  }

  // Dosya yükleme yardımcı fonksiyonu
  static Future<Map<String, dynamic>?> _uploadDietFile(File file, String fileId) async {
    try {
      final fileName = file.path.split('/').last;
      final fileExtension = fileName.split('.').last.toLowerCase();
      final fileType = fileExtension;
      
      final storageRef = _storage
          .ref()
          .child('diet_files')
          .child('$fileId.$fileExtension');

      final uploadTask = storageRef.putFile(file);
      final snapshot = await uploadTask;
      
      if (snapshot.state == TaskState.success) {
        final downloadUrl = await snapshot.ref.getDownloadURL();
        final metadata = await snapshot.ref.getMetadata();
        
        return {
          'url': downloadUrl,
          'name': fileName,
          'type': fileType,
          'size': metadata.size,
        };
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ Dosya yükleme hatası: $e');
      return null;
    }
  }

  // Dosya türü kontrolü
  static bool isValidFileType(String fileName) {
    final allowedExtensions = ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'txt'];
    final extension = fileName.split('.').last.toLowerCase();
    return allowedExtensions.contains(extension);
  }

  // Dosya boyutu kontrolü (5MB limit)
  static bool isValidFileSize(File file) {
    const maxSizeBytes = 5 * 1024 * 1024; // 5MB
    return file.lengthSync() <= maxSizeBytes;
  }
}
