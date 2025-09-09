import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../database/drift_service.dart';
import '../models/diet_package_model.dart';
import '../models/user_diet_assignment_model.dart';
import '../services/firebase_usage_tracker.dart';

class DietPackageService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const _uuid = Uuid();

  // Diyet paketi oluştur (sadece diyetisyenler)
  static Future<bool> createDietPackage(DietPackageModel package) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('❌ Kullanıcı oturum açmamış');
        return false;
      }

      // Diyetisyen yetkisi kontrolü
      final userRole = await DriftService.getUserRole(user.uid);
      if (userRole == null || !userRole.isDietitian) {
        debugPrint('❌ Sadece diyetisyenler diyet paketi oluşturabilir');
        return false;
      }

      // Package ID oluştur
      package.packageId = _uuid.v4();
      package.dietitianId = user.uid;
      package.updatedAt = DateTime.now();

      // Firestore'a kaydet
      await _firestore
          .collection('dietPackages')
          .doc(package.packageId)
          .set(package.toMap());

      await FirebaseUsageTracker.incrementWrite(1);

      // Yerel Isar'a kaydet
      await DriftService.saveDietPackage(package);

      debugPrint('✅ Diyet paketi oluşturuldu: ${package.title}');
      return true;
    } catch (e) {
      debugPrint('❌ Diyet paketi oluşturma hatası: $e');
      return false;
    }
  }

  // Diyet paketini güncelle
  static Future<bool> updateDietPackage(DietPackageModel package) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Yetki kontrolü
      if (package.dietitianId != user.uid) {
        debugPrint('❌ Sadece paketi oluşturan diyetisyen güncelleyebilir');
        return false;
      }

      package.updatedAt = DateTime.now();

      // Firestore'da güncelle
      await _firestore
          .collection('dietPackages')
          .doc(package.packageId)
          .set(package.toMap(), SetOptions(merge: true));

      await FirebaseUsageTracker.incrementWrite(1);

      // Yerel Isar'da güncelle
      await DriftService.saveDietPackage(package);

      debugPrint('✅ Diyet paketi güncellendi: ${package.title}');
      return true;
    } catch (e) {
      debugPrint('❌ Diyet paketi güncelleme hatası: $e');
      return false;
    }
  }

  // Diyet paketini sil
  static Future<bool> deleteDietPackage(String packageId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Önce paketi kontrol et
      final package = await getDietPackage(packageId);
      if (package == null) return false;

      // Yetki kontrolü
      if (package.dietitianId != user.uid) {
        debugPrint('❌ Sadece paketi oluşturan diyetisyen silebilir');
        return false;
      }

      // Aktif ataması olan paketler silinemez
      final activeAssignments = await getActiveAssignmentsForPackage(packageId);
      if (activeAssignments.isNotEmpty) {
        debugPrint('❌ Aktif ataması olan paket silinemez');
        return false;
      }

      // Firestore'dan sil
      await _firestore.collection('dietPackages').doc(packageId).delete();
      await FirebaseUsageTracker.incrementWrite(1);

      // Yerel Isar'dan sil
      await DriftService.deleteDietPackage(packageId);

      debugPrint('✅ Diyet paketi silindi: ${package.title}');
      return true;
    } catch (e) {
      debugPrint('❌ Diyet paketi silme hatası: $e');
      return false;
    }
  }

  // Diyetisyenin paketlerini getir
  static Future<List<DietPackageModel>> getDietitianPackages(
    String? dietitianId,
  ) async {
    try {
      final currentUser = _auth.currentUser;
      final targetId = dietitianId ?? currentUser?.uid;

      if (targetId == null) return [];

      // Önce Isar'dan dene
      final localPackages = await DriftService.getDietitianPackages(targetId);
      if (localPackages.isNotEmpty) {
        return localPackages;
      }

      // Isar'da yoksa Firestore'dan çek
      final querySnapshot = await _firestore
          .collection('dietPackages')
          .where('dietitianId', isEqualTo: targetId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      await FirebaseUsageTracker.incrementRead(querySnapshot.docs.length);

      final packages = querySnapshot.docs
          .map((doc) => DietPackageModel.fromMap(doc.data()))
          .toList();

      // Isar'a kaydet
      for (final package in packages) {
        await DriftService.saveDietPackage(package);
      }

      return packages;
    } catch (e) {
      debugPrint('❌ Diyetisyen paketleri getirme hatası: $e');
      return [];
    }
  }

  // Tüm aktif paketleri getir (public olanlar)
  static Future<List<DietPackageModel>> getPublicPackages() async {
    try {
      final querySnapshot = await _firestore
          .collection('dietPackages')
          .where('isActive', isEqualTo: true)
          .where('isPublic', isEqualTo: true)
          .orderBy('averageRating', descending: true)
          .limit(50)
          .get();

      await FirebaseUsageTracker.incrementRead(querySnapshot.docs.length);

      return querySnapshot.docs
          .map((doc) => DietPackageModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ Public paketler getirme hatası: $e');
      return [];
    }
  }

  // Tek paket getir
  static Future<DietPackageModel?> getDietPackage(String packageId) async {
    try {
      // Önce Isar'dan dene
      final localPackage = await DriftService.getDietPackage(packageId);
      if (localPackage != null) {
        return localPackage;
      }

      // Isar'da yoksa Firestore'dan çek
      final doc =
          await _firestore.collection('dietPackages').doc(packageId).get();

      await FirebaseUsageTracker.incrementRead(1);

      if (!doc.exists) return null;

      final package = DietPackageModel.fromMap(doc.data()!);

      // Isar'a kaydet
      await DriftService.saveDietPackage(package);

      return package;
    } catch (e) {
      debugPrint('❌ Diyet paketi getirme hatası: $e');
      return null;
    }
  }

  // ========== DİYET ATAMA SİSTEMİ ==========

  // Kullanıcıya diyet paketi ata
  static Future<bool> assignDietPackageToUser({
    required String userId,
    required String packageId,
    required DateTime startDate,
    required DateTime endDate,
    String? dietitianNotes,
    Map<String, dynamic>? customSettings,
    double? targetWeight,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Diyetisyen yetkisi kontrolü
      final userRole = await DriftService.getUserRole(user.uid);
      if (userRole == null || !userRole.isDietitian) {
        debugPrint('❌ Sadece diyetisyenler diyet paketi atayabilir');
        return false;
      }

      // Paket kontrolü
      final package = await getDietPackage(packageId);
      if (package == null || !package.isActive) {
        debugPrint('❌ Geçersiz veya aktif olmayan paket');
        return false;
      }

      // Kullanıcının aktif ataması var mı kontrol et
      final existingActive = await getUserActiveAssignment(userId);
      if (existingActive != null) {
        // Mevcut atamanın durumunu güncelle
        existingActive.status = AssignmentStatus.cancelled;
        await updateAssignment(existingActive);
      }

      // Yeni atama oluştur
      final assignment = UserDietAssignmentModel.create(
        assignmentId: _uuid.v4(),
        userId: userId,
        packageId: packageId,
        dietitianId: user.uid,
        startDate: startDate,
        endDate: endDate,
        dietitianNotes: dietitianNotes,
        customSettings:
            customSettings != null ? customSettings.toString() : '{}',
        weightTarget: targetWeight ?? 0.0,
      );

      // Firestore'a kaydet
      await _firestore
          .collection('userDietAssignments')
          .doc(assignment.assignmentId)
          .set(assignment.toMap());

      await FirebaseUsageTracker.incrementWrite(1);

      // Yerel Isar'a kaydet
      await DriftService.saveUserDietAssignment(assignment);

      // Paket istatistiklerini güncelle
      package.assignedCount++;
      await updateDietPackage(package);

      debugPrint('✅ Diyet paketi atandı: ${package.title} → $userId');
      return true;
    } catch (e) {
      debugPrint('❌ Diyet paketi atama hatası: $e');
      return false;
    }
  }

  // Kullanıcının aktif atamasını getir
  static Future<UserDietAssignmentModel?> getUserActiveAssignment(
    String userId,
  ) async {
    try {
      // Önce Isar'dan dene
      final localAssignment =
          await DriftService.getUserActiveAssignment(userId);
      if (localAssignment != null) {
        return localAssignment;
      }

      // Isar'da yoksa Firestore'dan çek
      final querySnapshot = await _firestore
          .collection('userDietAssignments')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      await FirebaseUsageTracker.incrementRead(querySnapshot.docs.length);

      if (querySnapshot.docs.isEmpty) return null;

      final assignment = UserDietAssignmentModel.fromMap(
        querySnapshot.docs.first.data(),
      );

      // Isar'a kaydet
      await DriftService.saveUserDietAssignment(assignment);

      return assignment;
    } catch (e) {
      debugPrint('❌ Kullanıcı aktif ataması getirme hatası: $e');
      return null;
    }
  }

  // Paket için aktif atamaları getir
  static Future<List<UserDietAssignmentModel>> getActiveAssignmentsForPackage(
    String packageId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('userDietAssignments')
          .where('packageId', isEqualTo: packageId)
          .where('status', isEqualTo: 'active')
          .get();

      await FirebaseUsageTracker.incrementRead(querySnapshot.docs.length);

      return querySnapshot.docs
          .map((doc) => UserDietAssignmentModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ Paket aktif atamaları getirme hatası: $e');
      return [];
    }
  }

  // Atamayı güncelle
  static Future<bool> updateAssignment(
    UserDietAssignmentModel assignment,
  ) async {
    try {
      assignment.updatedAt = DateTime.now();

      await _firestore
          .collection('userDietAssignments')
          .doc(assignment.assignmentId)
          .set(assignment.toMap(), SetOptions(merge: true));

      await FirebaseUsageTracker.incrementWrite(1);

      await DriftService.saveUserDietAssignment(assignment);

      return true;
    } catch (e) {
      debugPrint('❌ Atama güncelleme hatası: $e');
      return false;
    }
  }

  // Diyetisyenin tüm atamalarını getir
  static Future<List<UserDietAssignmentModel>> getDietitianAssignments(
    String? dietitianId,
  ) async {
    try {
      final currentUser = _auth.currentUser;
      final targetId = dietitianId ?? currentUser?.uid;

      if (targetId == null) return [];

      final querySnapshot = await _firestore
          .collection('userDietAssignments')
          .where('dietitianId', isEqualTo: targetId)
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      await FirebaseUsageTracker.incrementRead(querySnapshot.docs.length);

      return querySnapshot.docs
          .map((doc) => UserDietAssignmentModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ Diyetisyen atamaları getirme hatası: $e');
      return [];
    }
  }

  // Paket arama
  static Future<List<DietPackageModel>> searchPackages(String query) async {
    try {
      final lowerQuery = query.toLowerCase();

      final querySnapshot = await _firestore
          .collection('dietPackages')
          .where('isActive', isEqualTo: true)
          .where('isPublic', isEqualTo: true)
          .get();

      await FirebaseUsageTracker.incrementRead(querySnapshot.docs.length);

      final packages = querySnapshot.docs
          .map((doc) => DietPackageModel.fromMap(doc.data()))
          .where((package) =>
              package.title.toLowerCase().contains(lowerQuery) ||
              package.description.toLowerCase().contains(lowerQuery) ||
              package.tags.any((tag) => tag.toLowerCase().contains(lowerQuery)))
          .toList();

      return packages;
    } catch (e) {
      debugPrint('❌ Paket arama hatası: $e');
      return [];
    }
  }
}
