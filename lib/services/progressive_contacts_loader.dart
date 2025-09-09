import 'dart:async';
import 'package:flutter/foundation.dart';

import '../database/drift_service.dart';

import 'contacts_service.dart';
import 'contacts_sync_service.dart';

/// 🚀 Progressive Contacts Loader
/// Büyük rehberlerde kullanıcı deneyimini iyileştirmek için
/// aşamalı yükleme sağlar
class ProgressiveContactsLoader {
  static bool _isLoading = false;
  static final StreamController<ContactsLoadingProgress> _progressController =
      StreamController<ContactsLoadingProgress>.broadcast();
  
  /// Loading progress stream
  static Stream<ContactsLoadingProgress> get progressStream => 
      _progressController.stream;

  /// 🔄 Aşamalı rehber yükleme
  /// 1. Önce yerelden hızlıca yükle
  /// 2. Arkaplanda tam senkronizasyon yap
  /// 3. Progress updates gönder
  static Future<List<Map<String, dynamic>>> loadContactsProgressively({
    bool includeUnregistered = false,
    int? maxContacts,
  }) async {
    if (_isLoading) {
      debugPrint('⚠️ Progressive loading zaten çalışıyor');
      return [];
    }

    _isLoading = true;


    try {
      // 1️⃣ HIZLI START: Yerelden kayıtlı kişileri getir
      _emitProgress(ContactsLoadingProgress.loading(
        phase: LoadingPhase.localData,
        message: 'Kayıtlı kişiler yükleniyor...',
        currentCount: 0,
      ));

      final localRegistered = await _getLocalRegisteredContacts();
      
      _emitProgress(ContactsLoadingProgress.loading(
        phase: LoadingPhase.localData,
        message: '${localRegistered.length} kayıtlı kişi bulundu',
        currentCount: localRegistered.length,
      ));

      // Kullanıcıya hızlıca bir şeyler göster
      if (localRegistered.isNotEmpty) {
        _emitProgress(ContactsLoadingProgress.partialData(
          data: localRegistered,
          phase: LoadingPhase.localData,
        ));
      }

      // 2️⃣ ARKAPLAN: Tam rehber senkronizasyonu
      _emitProgress(ContactsLoadingProgress.loading(
        phase: LoadingPhase.contactsReading,
        message: 'Rehber okunuyor...',
        currentCount: localRegistered.length,
      ));

      // Arkaplanda tam senkronizasyon başlat
      unawaited(_performBackgroundSync(
        maxContacts: maxContacts,
        includeUnregistered: includeUnregistered,
        initialCount: localRegistered.length,
      ));

      return localRegistered;
    } catch (e) {
      debugPrint('❌ Progressive loading error: $e');
      _emitProgress(ContactsLoadingProgress.error(
        error: e.toString(),
      ));
      return [];
    } finally {
      _isLoading = false;
    }
  }

  /// Yerelden kayıtlı kişileri hızlıca getir
  static Future<List<Map<String, dynamic>>> _getLocalRegisteredContacts() async {
    try {
      final registeredIndexes = await DriftService.getRegisteredContactIndexes();
      final localUsers = await DriftService.getAllUsers();
      
      final Map<String, dynamic> uidToUser = {
        for (final u in localUsers) u.userId: u,
      };

      final List<Map<String, dynamic>> result = [];
      for (final idx in registeredIndexes) {
        final uid = idx.registeredUid;
        final user = (uid != null) ? uidToUser[uid] : null;
        final displayName = (idx.contactName?.isNotEmpty == true)
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

      return result;
    } catch (e) {
      debugPrint('❌ Local contacts loading error: $e');
      return [];
    }
  }

  /// Arkaplanda tam senkronizasyon
  static Future<void> _performBackgroundSync({
    int? maxContacts,
    bool includeUnregistered = false,
    int initialCount = 0,
  }) async {
    try {
      // Rehber iznini kontrol et
      final hasPermission = await ContactsService.requestContactsPermission();
      if (!hasPermission) {
        _emitProgress(ContactsLoadingProgress.error(
          error: 'Rehber izni gerekli',
        ));
        return;
      }

      // Arkaplanda optimize edilmiş senkronizasyon
      await ContactsSyncService.runFullSync(
        contactReadLimit: maxContacts ?? 2000,
        showProgress: true,
      );

      _emitProgress(ContactsLoadingProgress.loading(
        phase: LoadingPhase.finalizing,
        message: 'Sonuçlar hazırlanıyor...',
        currentCount: initialCount,
      ));

      // Final sonuçları getir
      final finalData = await _getFinalResults(includeUnregistered);
      
      _emitProgress(ContactsLoadingProgress.completed(
        data: finalData,
        totalCount: finalData.length,
      ));

    } catch (e) {
      debugPrint('❌ Background sync error: $e');
      _emitProgress(ContactsLoadingProgress.error(
        error: 'Senkronizasyon hatası: ${e.toString()}',
      ));
    }
  }

  /// Final sonuçları getir
  static Future<List<Map<String, dynamic>>> _getFinalResults(
    bool includeUnregistered,
  ) async {
    try {
      final registeredIndexes = await DriftService.getRegisteredContactIndexes();
      final localUsers = await DriftService.getAllUsers();
      
      final Map<String, dynamic> uidToUser = {
        for (final u in localUsers) u.userId: u,
      };

      final List<Map<String, dynamic>> result = [];
      
      // Kayıtlı kişiler
      for (final idx in registeredIndexes) {
        final uid = idx.registeredUid;
        final user = (uid != null) ? uidToUser[uid] : null;
        final displayName = (idx.contactName?.isNotEmpty == true)
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

      // Kayıtlı olmayan kişiler (isteğe bağlı)
      if (includeUnregistered) {
        final allIndexes = await DriftService.getAllContactIndexes();
        for (final idx in allIndexes.where((e) => !e.isRegistered)) {
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

      // Alfabetik sıralama
      result.sort((a, b) => (a['displayName'] as String)
          .toLowerCase()
          .compareTo((b['displayName'] as String).toLowerCase()));

      return result;
    } catch (e) {
      debugPrint('❌ Final results error: $e');
      return [];
    }
  }

  /// Progress event gönder
  static void _emitProgress(ContactsLoadingProgress progress) {
    if (!_progressController.isClosed) {
      _progressController.add(progress);
    }
  }

  /// Stream'i temizle
  static void dispose() {
    _progressController.close();
  }
}

/// Loading phase'leri
enum LoadingPhase {
  localData,        // Yerelden hızlı yükleme
  contactsReading,  // Rehber okunuyor
  firebaseSync,     // Firebase ile senkronizasyon
  finalizing,       // Son işlemler
}

/// Loading progress model
class ContactsLoadingProgress {
  final LoadingPhase? phase;
  final String? message;
  final int? currentCount;
  final int? totalCount;
  final List<Map<String, dynamic>>? data;
  final String? error;
  final bool isCompleted;
  final bool hasError;

  const ContactsLoadingProgress._({
    this.phase,
    this.message,
    this.currentCount,
    this.totalCount,
    this.data,
    this.error,
    required this.isCompleted,
    required this.hasError,
  });

  // Loading state
  factory ContactsLoadingProgress.loading({
    required LoadingPhase phase,
    required String message,
    int? currentCount,
    int? totalCount,
  }) {
    return ContactsLoadingProgress._(
      phase: phase,
      message: message,
      currentCount: currentCount,
      totalCount: totalCount,
      isCompleted: false,
      hasError: false,
    );
  }

  // Partial data available
  factory ContactsLoadingProgress.partialData({
    required List<Map<String, dynamic>> data,
    required LoadingPhase phase,
  }) {
    return ContactsLoadingProgress._(
      phase: phase,
      data: data,
      currentCount: data.length,
      isCompleted: false,
      hasError: false,
    );
  }

  // Completed
  factory ContactsLoadingProgress.completed({
    required List<Map<String, dynamic>> data,
    required int totalCount,
  }) {
    return ContactsLoadingProgress._(
      data: data,
      totalCount: totalCount,
      currentCount: totalCount,
      isCompleted: true,
      hasError: false,
      message: 'Tamamlandı: $totalCount kişi',
    );
  }

  // Error
  factory ContactsLoadingProgress.error({
    required String error,
  }) {
    return ContactsLoadingProgress._(
      error: error,
      isCompleted: true,
      hasError: true,
    );
  }
}