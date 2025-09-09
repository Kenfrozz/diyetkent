import 'package:flutter/foundation.dart';
import 'dart:async';
import '../database/drift_service.dart';
import '../models/user_model.dart';
import '../models/contact_index_model.dart';
import 'user_service.dart';
import 'contacts_sync_service.dart';
import 'progressive_contacts_loader.dart';

/// PeopleService: Kişi dizini yönetimi
/// - Kayıtlı kullanıcılar (Isar/Firebase)
/// - Rehber kişileri (ContactsService)
/// - Birleşik, UI-dostu veri modeli döndürür
class PeopleService {
  /// 🚀 YENİ: Progressive directory loading
  /// Büyük rehberlerde performans için aşamalı yükleme
  static Future<List<Map<String, dynamic>>> getDirectoryProgressive({
    bool includeUnregistered = false,
    int? maxContacts,
  }) async {
    return await ProgressiveContactsLoader.loadContactsProgressively(
      includeUnregistered: includeUnregistered,
      maxContacts: maxContacts,
    );
  }

  /// Progress stream'e erişim
  static Stream<ContactsLoadingProgress> get loadingProgressStream =>
      ProgressiveContactsLoader.progressStream;

  /// ESKI: Kişi dizinini döndürür (legacy, performans sorunlu)
  /// - includeUnregistered: Kayıtlı olmayan rehber kişileri de listeye ekle
  /// - userLimit: Firebase'den çekilecek kullanıcı sayısı limiti (gerekirse)
  /// - contactReadLimit: Rehber okuma limiti
  @Deprecated('Use ContactsManager.getRegisteredUsers instead')
  static Future<List<Map<String, dynamic>>> getDirectory({
    bool includeUnregistered = false,
    int userLimit = 200,
    int? contactReadLimit,
  }) async {
    try {
      // ⚠️ UYARI: Bu method büyük rehberlerde yavaş!
      // Bunun yerine getDirectoryProgressive() kullanın
      debugPrint(
          '⚠️ Legacy getDirectory() kullanılıyor - büyük rehberlerde yavaş olabilir!');

      // Kullanıcı cache'ini (Isar) tazele, UI'yi bloklamadan çalıştır
      unawaited(
        UserService.fetchUsersAndSaveToIsar(limit: userLimit)
            .timeout(const Duration(seconds: 10))
            .catchError((_) => <UserModel>[]),
      );

      // Rehber-Firebase eşlemesini arkaplanda başlat (Isar'a yazar)
      unawaited(
        ContactsSyncService.runFullSync(
          contactReadLimit: contactReadLimit ?? 1000, // Limit ekle
          showProgress: true,
        ),
      );

      // Yerelden oku: Users + ContactIndex (kayıtlılar)
      final List<UserModel> localUsers = await DriftService.getAllUsers();
      final Map<String, UserModel> uidToUser = {
        for (final u in localUsers) u.userId: u,
      };

      final List<ContactIndexModel> registeredIndexes =
          await DriftService.getRegisteredContactIndexes();

      final List<Map<String, dynamic>> result = [];
      for (final idx in registeredIndexes) {
        final uid = idx.registeredUid;
        final user = (uid != null) ? uidToUser[uid] : null;
        final displayName =
            (idx.contactName != null && idx.contactName!.isNotEmpty)
                ? idx.contactName!
                : (user?.name ?? 'İsimsiz Kullanıcı');
        result.add({
          'uid': uid,
          'displayName': displayName,
          'phoneNumber': user?.phoneNumber ?? idx.normalizedPhone,
          'profileImageUrl': user?.profileImageUrl,
          'isOnline': user?.isOnline ?? false,
          'lastSeen': user?.lastSeen,
          'isRegistered': true,
          'contactName': idx.contactName,
        });
      }

      if (includeUnregistered) {
        final all = await DriftService.getAllContactIndexes();
        for (final idx in all.where((e) => e.isRegistered == false)) {
          result.add({
            'uid': null,
            'displayName': idx.contactName ?? idx.normalizedPhone,
            'phoneNumber': idx.normalizedPhone,
            'profileImageUrl': null,
            'isOnline': false,
            'lastSeen': null,
            'isRegistered': false,
            'contactName': idx.contactName,
          });
        }
      }

      result.sort((a, b) => (a['displayName'] as String)
          .toLowerCase()
          .compareTo((b['displayName'] as String).toLowerCase()));
      return result;
    } catch (e) {
      debugPrint('❌ PeopleService.getDirectory hatası: $e');
      return [];
    }
  }

  /// Hızlı arama: Büyük rehberlerde performans için yalnızca sorguyla eşleşen
  /// kişileri getirir. Rehber tarafını ContactsService.query ile daraltır,
  /// kayıtlı kullanıcıları Firestore yerine yerel Isar + minimal Firestore ile
  /// birleştirir. includeUnregistered true ise kayıtlı olmayan rehber kişiler de listelenir.
  static Future<List<Map<String, dynamic>>> searchDirectoryQuick({
    required String query,
    bool includeUnregistered = true,
    int limit = 500,
    int userLimit = 2000,
  }) async {
    try {
      // Kullanıcıları arka planda tazele
      unawaited(
        UserService.fetchUsersAndSaveToIsar(limit: userLimit)
            .timeout(const Duration(seconds: 10))
            .catchError((_) => <UserModel>[]),
      );

      final List<UserModel> localUsers = await DriftService.getAllUsers();
      final Map<String, UserModel> uidToUser = {
        for (final u in localUsers) u.userId: u,
      };

      final String q = query.trim().toLowerCase();

      // Kayıtlı rehber indekslerini getir ve isim/telefon eşleşmesine göre filtrele
      final List<ContactIndexModel> registeredIndexes =
          await DriftService.getRegisteredContactIndexes();

      final List<Map<String, dynamic>> results = [];
      for (final idx in registeredIndexes) {
        final uid = idx.registeredUid;
        final user = (uid != null) ? uidToUser[uid] : null;
        final displayName =
            (idx.contactName != null && idx.contactName!.isNotEmpty)
                ? idx.contactName!
                : (user?.name ?? 'İsimsiz Kullanıcı');
        final phone = user?.phoneNumber ?? idx.normalizedPhone;
        if (displayName.toLowerCase().contains(q) ||
            (phone.toLowerCase().contains(q))) {
          results.add({
            'uid': uid,
            'displayName': displayName,
            'phoneNumber': phone,
            'profileImageUrl': user?.profileImageUrl,
            'isOnline': user?.isOnline ?? false,
            'lastSeen': user?.lastSeen,
            'isRegistered': true,
            'contactName': idx.contactName,
          });
        }
      }

      if (includeUnregistered && results.length < limit) {
        final all = await DriftService.getAllContactIndexes();
        for (final idx in all.where((e) => e.isRegistered == false)) {
          final displayName = idx.contactName ?? idx.normalizedPhone;
          if (displayName.toLowerCase().contains(q) ||
              idx.normalizedPhone.toLowerCase().contains(q)) {
            results.add({
              'uid': null,
              'displayName': displayName,
              'phoneNumber': idx.normalizedPhone,
              'profileImageUrl': null,
              'isOnline': false,
              'lastSeen': null,
              'isRegistered': false,
              'contactName': idx.contactName,
            });
          }
          if (results.length >= limit) break;
        }
      }

      results.sort((a, b) => (a['displayName'] as String)
          .toLowerCase()
          .compareTo((b['displayName'] as String).toLowerCase()));
      return results.take(limit).toList();
    } catch (e) {
      debugPrint('❌ PeopleService.searchDirectoryQuick hatası: $e');
      return [];
    }
  }

  /// Basit arama yardımcı
  static List<Map<String, dynamic>> searchDirectory(
    List<Map<String, dynamic>> directory,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return directory;
    return directory.where((entry) {
      final name = (entry['displayName'] as String? ?? '').toLowerCase();
      final phone = (entry['phoneNumber'] as String? ?? '').toLowerCase();
      final contactName = (entry['contactName'] as String? ?? '').toLowerCase();
      return name.contains(q) || phone.contains(q) || contactName.contains(q);
    }).toList();
  }
}
