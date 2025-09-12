import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../database/drift_service.dart';
import '../models/health_data_model.dart';

import 'package:flutter/foundation.dart';

class HealthService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sağlık verisi kaydet (hem Isar hem Firestore)
  static Future<bool> saveHealthData(HealthDataModel healthData) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('❌ Kullanıcı oturum açmamış');
        return false;
      }

      debugPrint('🔐 Kullanıcı ID: ${user.uid}');
      debugPrint('📱 Telefon: ${user.phoneNumber}');
      
      healthData.userId = user.uid;
      healthData.updatedAt = DateTime.now();

      // Önce Isar'a kaydet
      await DriftService.saveHealthData(user.uid, healthData.toMap());

      // Auth token'ı yenile
      await user.reload();
      final refreshedUser = _auth.currentUser;
      if (refreshedUser == null) {
        debugPrint('❌ Token yenileme sonrası kullanıcı bulunamadı');
        return false;
      }

      // Sonra Firestore'a kaydet
      final healthDataMap = healthData.toMap();
      debugPrint('💾 Firestore\'a kaydediliyor: users/${user.uid}/healthData/${healthData.recordDate.millisecondsSinceEpoch}');
      debugPrint('📊 Veri: $healthDataMap');
      
      // Güvenlik kuralı test - userId eşleşiyor mu?
      debugPrint('🔍 Auth UID: ${user.uid}');
      debugPrint('🔍 Data userId: ${healthDataMap['userId']}');
      debugPrint('🔍 Eşleşme: ${user.uid == healthDataMap['userId']}');
      
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('healthData')
          .doc(healthData.recordDate.millisecondsSinceEpoch.toString())
          .set(healthDataMap);

      // Kullanıcının mevcut sağlık bilgilerini güncelle
      if (healthData.height != null || healthData.weight != null) {
        await _updateUserCurrentHealth(
          height: healthData.height,
          weight: healthData.weight,
        );
      }

      // Adım sayısını güncelle
      if (healthData.stepCount != null && healthData.isLatestRecord) {
        await _updateUserStepCount(healthData.stepCount!);
      }

      debugPrint('✅ Sağlık verisi kaydedildi: ${healthData.recordDate}');
      return true;
    } catch (e) {
      debugPrint('❌ Sağlık verisi kaydetme hatası: $e');
      return false;
    }
  }

  // Kullanıcının tüm sağlık verilerini getir
  static Future<List<HealthDataModel>> getUserHealthData({
    int limit = 30,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      // Önce Drift'ten dene
      final localData = await DriftService.getUserHealthData();

      if (localData.isNotEmpty) {
        // Map'leri HealthDataModel'e dönüştür
        return localData.map((data) => HealthDataModel.fromMap(data)).toList();
      }

      // Isar'da veri yoksa Firestore'dan çek
      Query query = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('healthData')
          .orderBy('recordDate', descending: true)
          .limit(limit);

      if (startDate != null) {
        query = query.where('recordDate',
            isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch);
      }
      if (endDate != null) {
        query = query.where('recordDate',
            isLessThanOrEqualTo: endDate.millisecondsSinceEpoch);
      }

      final querySnapshot = await query.get();
      final healthDataList = querySnapshot.docs
          .map((doc) =>
              HealthDataModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Firestore'dan gelen verileri Isar'a kaydet
      for (final healthData in healthDataList) {
        await DriftService.saveHealthData(user.uid, healthData.toMap());
      }

      return healthDataList;
    } catch (e) {
      debugPrint('❌ Sağlık verisi getirme hatası: $e');
      return [];
    }
  }

  // Bugünkü sağlık verilerini getir
  static Future<HealthDataModel?> getTodayHealthData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Önce Drift'ten dene
      final localData = await DriftService.getUserHealthData();

      if (localData.isNotEmpty) {
        return HealthDataModel.fromMap(localData.first);
      }

      // Isar'da yoksa Firestore'dan çek
      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('healthData')
          .where('recordDate',
              isGreaterThanOrEqualTo: startOfDay.millisecondsSinceEpoch)
          .where('recordDate', isLessThan: endOfDay.millisecondsSinceEpoch)
          .orderBy('recordDate', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final healthData = HealthDataModel.fromMap(
          querySnapshot.docs.first.data(),
        );
        await DriftService.saveHealthData(user.uid, healthData.toMap());
        return healthData;
      }

      return null;
    } catch (e) {
      debugPrint('❌ Bugünkü sağlık verisi getirme hatası: $e');
      return null;
    }
  }

  // Adım sayısını güncelle
  static Future<bool> updateStepCount(int stepCount) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final today = DateTime.now();
      final todayData = await getTodayHealthData();

      if (todayData != null) {
        // Mevcut kayıt varsa güncelle
        todayData.stepCount = stepCount;
        todayData.updatedAt = DateTime.now();
        return await saveHealthData(todayData);
      } else {
        // Yeni kayıt oluştur
        final newHealthData = HealthDataModel.create(
          userId: user.uid,
          stepCount: stepCount,
          recordDate: today,
        );
        return await saveHealthData(newHealthData);
      }
    } catch (e) {
      debugPrint('❌ Adım sayısı güncelleme hatası: $e');
      return false;
    }
  }

  // Boy kilo güncelle
  static Future<bool> updateHeightWeight({
    double? height,
    double? weight,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final today = DateTime.now();
      final todayData = await getTodayHealthData();

      if (todayData != null) {
        // Mevcut kayıt varsa güncelle
        if (height != null) todayData.height = height;
        if (weight != null) todayData.weight = weight;

        // BMI'yi yeniden hesapla
        if (todayData.height != null && todayData.weight != null) {
          double heightInMeters = todayData.height! / 100;
          todayData.bmi = todayData.weight! / (heightInMeters * heightInMeters);
        }

        todayData.updatedAt = DateTime.now();
        return await saveHealthData(todayData);
      } else {
        // Yeni kayıt oluştur
        final newHealthData = HealthDataModel.create(
          userId: user.uid,
          height: height,
          weight: weight,
          recordDate: today,
        );
        return await saveHealthData(newHealthData);
      }
    } catch (e) {
      debugPrint('❌ Boy/kilo güncelleme hatası: $e');
      return false;
    }
  }

  // Kullanıcının mevcut sağlık bilgilerini güncelle (UserModel'de)
  static Future<void> _updateUserCurrentHealth({
    double? height,
    double? weight,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (height != null) {
        updateData['currentHeight'] = height;
      }
      if (weight != null) {
        updateData['currentWeight'] = weight;
      }

      await _firestore.collection('users').doc(user.uid).update(updateData);

      // Yerel Isar'daki user modelini de güncelle
      final localUser = await DriftService.getUser(user.uid);
      if (localUser != null) {
        if (height != null) localUser.currentHeight = height;
        if (weight != null) localUser.currentWeight = weight;
        localUser.updatedAt = DateTime.now();
        await DriftService.saveUser(localUser);
      }
    } catch (e) {
      debugPrint('❌ Kullanıcı sağlık bilgisi güncelleme hatası: $e');
    }
  }

  // Kullanıcının adım sayısını güncelle (UserModel'de)
  static Future<void> _updateUserStepCount(int stepCount) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'todayStepCount': stepCount,
        'lastStepUpdate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Yerel Isar'daki user modelini de güncelle
      final localUser = await DriftService.getUser(user.uid);
      if (localUser != null) {
        localUser.todayStepCount = stepCount;
        localUser.lastStepUpdate = DateTime.now();
        localUser.updatedAt = DateTime.now();
        await DriftService.saveUser(localUser);
      }
    } catch (e) {
      debugPrint('❌ Kullanıcı adım sayısı güncelleme hatası: $e');
    }
  }

  // Sağlık istatistikleri getir
  static Future<Map<String, dynamic>> getHealthStats({
    int days = 30,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));

      final healthDataList = await getUserHealthData(
        startDate: startDate,
        endDate: endDate,
        limit: days,
      );

      if (healthDataList.isEmpty) {
        return {
          'totalDays': 0,
          'averageSteps': 0,
          'totalSteps': 0,
          'maxSteps': 0,
          'weightChange': 0.0,
          'bmiChange': 0.0,
        };
      }

      // İstatistikleri hesapla
      int totalSteps = 0;
      int maxSteps = 0;
      double? firstWeight, lastWeight;
      double? firstBMI, lastBMI;

      for (final data in healthDataList.reversed) {
        if (data.stepCount != null) {
          totalSteps += data.stepCount!;
          if (data.stepCount! > maxSteps) maxSteps = data.stepCount!;
        }

        if (firstWeight == null && data.weight != null) {
          firstWeight = data.weight;
        }
        if (data.weight != null) {
          lastWeight = data.weight;
        }

        if (firstBMI == null && data.bmi != null) {
          firstBMI = data.bmi;
        }
        if (data.bmi != null) {
          lastBMI = data.bmi;
        }
      }

      final averageSteps = healthDataList.isNotEmpty
          ? (totalSteps / healthDataList.length).round()
          : 0;

      final weightChange = (lastWeight != null && firstWeight != null)
          ? lastWeight - firstWeight
          : 0.0;

      final bmiChange =
          (lastBMI != null && firstBMI != null) ? lastBMI - firstBMI : 0.0;

      return {
        'totalDays': healthDataList.length,
        'averageSteps': averageSteps,
        'totalSteps': totalSteps,
        'maxSteps': maxSteps,
        'weightChange': weightChange,
        'bmiChange': bmiChange,
        'firstWeight': firstWeight,
        'lastWeight': lastWeight,
        'firstBMI': firstBMI,
        'lastBMI': lastBMI,
      };
    } catch (e) {
      debugPrint('❌ Sağlık istatistikleri hesaplama hatası: $e');
      return {};
    }
  }
}
