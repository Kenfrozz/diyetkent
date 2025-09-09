import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import '../database/drift_service.dart';
import '../models/contact_index_model.dart';
import 'firebase_usage_tracker.dart';

/// 🎯 MERKEZI REHBER YÖNETİCİSİ
///
/// Bu servis tüm rehber işlemlerini tek noktadan yönetir:
/// ✅ Rehber okuma
/// ✅ Firebase kayıt kontrolü
/// ✅ Drift veritabanında tutma
/// ✅ Arkaplan senkronizasyonu
/// ✅ UI için hızlı veri sağlama
///
/// DİĞER SERVİSLER BU SERVİSİ KULLANMALI!
class ContactsManager {
  static bool _isInitialized = false;
  static bool _isSyncing = false;
  static DateTime? _lastFullSync;

  // Event streamler
  static final StreamController<ContactsSyncEvent> _syncEventController =
      StreamController<ContactsSyncEvent>.broadcast();
  static final StreamController<List<ContactIndexModel>> _contactsController =
      StreamController<List<ContactIndexModel>>.broadcast();

  // Cache
  static List<ContactIndexModel>? _cachedContacts;
  static DateTime? _cacheTime;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  /// Event stream'leri
  static Stream<ContactsSyncEvent> get syncEventStream =>
      _syncEventController.stream;
  static Stream<List<ContactIndexModel>> get contactsStream =>
      _contactsController.stream;

  /// 🚀 Başlatma - Uygulama açılışında çağrılmalı
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _isInitialized = true;
      debugPrint('🎯 ContactsManager başlatılıyor...');

      // İzin kontrolü ve ilk yükleme
      final hasPermission = await _requestContactsPermission();
      debugPrint('🔐 Rehber izni durumu: $hasPermission');
      
      if (hasPermission) {
        // Arkaplanda otomatik senkronizasyon başlat
        debugPrint('🔄 Otomatik senkronizasyon başlatılıyor...');
        unawaited(_performAutoSync());
      } else {
        debugPrint(
            '⚠️ Rehber izni yok - sadece kayıtlı kullanıcılar gösterilecek');
      }

      debugPrint('✅ ContactsManager hazır');
    } catch (e) {
      debugPrint('❌ ContactsManager başlatma hatası: $e');
    }
  }

  /// 📱 UI için ana veri kaynağı - SADECE BU METODU KULLANIN!
  static Future<List<ContactIndexModel>> getContacts({
    bool onlyRegistered = false,
    String? searchQuery,
    int? limit,
  }) async {
    try {
      // Önbellekten kontrol et
      if (_cachedContacts != null && _isCacheValid()) {
        return _applyFilters(_cachedContacts!,
            onlyRegistered: onlyRegistered,
            searchQuery: searchQuery,
            limit: limit);
      }

      // Yerelden yükle
      List<ContactIndexModel> contacts;
      if (onlyRegistered) {
        contacts = await DriftService.getRegisteredContactIndexes();
      } else {
        contacts = await DriftService.getAllContactIndexes();
      }

      // Cache'e al
      _cachedContacts = contacts;
      _cacheTime = DateTime.now();

      // Filtreleri uygula ve döndür
      final filtered = _applyFilters(contacts,
          onlyRegistered: onlyRegistered,
          searchQuery: searchQuery,
          limit: limit);

      // Stream'e gönder
      _contactsController.add(contacts);

      // Arkaplanda senkronizasyon varsa bekleme
      if (!_isSyncing && _shouldPerformSync()) {
        unawaited(_performAutoSync());
      }

      return filtered;
    } catch (e) {
      debugPrint('❌ ContactsManager.getContacts hatası: $e');
      return [];
    }
  }

  /// 🔍 Hızlı arama - UI'den çağrılabilir
  static Future<List<ContactIndexModel>> searchContacts(String query) async {
    if (query.trim().isEmpty) {
      return getContacts();
    }

    return getContacts(searchQuery: query.trim());
  }

  /// 👥 Sadece kayıtlı kullanıcıları getir
  static Future<List<ContactIndexModel>> getRegisteredContacts() async {
    return getContacts(onlyRegistered: true);
  }

  /// 📞 Telefon numarasına göre kişi bul
  static Future<ContactIndexModel?> findContactByPhone(
      String phoneNumber) async {
    final normalized = _normalizePhoneNumber(phoneNumber);
    if (normalized == null) return null;

    try {
      return await DriftService.getContactIndexByPhone(normalized);
    } catch (e) {
      debugPrint('❌ findContactByPhone hatası: $e');
      return null;
    }
  }

  /// 🔄 Manuel senkronizasyon tetikleme
  static Future<void> forceSync() async {
    if (_isSyncing) {
      debugPrint('⚠️ Senkronizasyon zaten çalışıyor');
      return;
    }

    await _performFullSync(showProgress: true);
  }

  /// 🔄 Arkaplan otomatik senkronizasyonu
  static Future<void> _performAutoSync() async {
    if (_isSyncing) {
      debugPrint('⏳ Senkronizasyon zaten devam ediyor');
      return;
    }

    try {
      _isSyncing = true;
      debugPrint('🔄 Otomatik senkronizasyon başladı');
      _emitSyncEvent(ContactsSyncEvent.started());

      // İzin kontrolü
      final hasPermission = await _requestContactsPermission();
      if (!hasPermission) {
        debugPrint('❌ Rehber izni yoktu, senkronizasyon iptal edildi');
        _emitSyncEvent(ContactsSyncEvent.error('Rehber izni gerekli'));
        return;
      }

      debugPrint('✅ İzin onaylandı, tam senkronizasyon başlıyor');
      await _performFullSync(showProgress: false);
    } finally {
      _isSyncing = false;
      debugPrint('🏁 Otomatik senkronizasyon tamamlandı');
    }
  }

  /// 🔄 Tam senkronizasyon işlemi
  static Future<void> _performFullSync({bool showProgress = false}) async {
    try {
      if (showProgress) {
        _emitSyncEvent(ContactsSyncEvent.progress(
          phase: SyncPhase.readingContacts,
          message: 'Rehber okunuyor...',
        ));
      }

      // 1️⃣ Rehberi oku
      debugPrint('📱 Cihaz rehberi okunuyor...');
      final contacts = await _readContactsFromDevice();
      if (contacts.isEmpty) {
        debugPrint('⚠️ Rehber boş veya okunamadı');
        _emitSyncEvent(ContactsSyncEvent.completed(0, 0));
        return;
      }
      debugPrint('✅ ${contacts.length} kişi rehberden okundu');

      if (showProgress) {
        _emitSyncEvent(ContactsSyncEvent.progress(
          phase: SyncPhase.processing,
          message: '${contacts.length} kişi işleniyor...',
        ));
      }

      // 2️⃣ Telefonları normalize et
      final phoneToContact = <String, Contact>{};
      for (final contact in contacts) {
        for (final phone in contact.phones) {
          final normalized = _normalizePhoneNumber(phone.number);
          if (normalized != null) {
            phoneToContact[normalized] = contact;
          }
        }
      }

      final allPhones = phoneToContact.keys.toList();
      debugPrint('📞 ${allPhones.length} benzersiz telefon numarası işlenecek');

      if (showProgress) {
        _emitSyncEvent(ContactsSyncEvent.progress(
          phase: SyncPhase.checkingFirebase,
          message: 'Firebase kontrol ediliyor...',
        ));
      }

      // 3️⃣ Firebase'de kayıtlı olanları kontrol et
      final registeredUsers = await _checkPhoneNumbersInFirebase(allPhones);

      if (showProgress) {
        _emitSyncEvent(ContactsSyncEvent.progress(
          phase: SyncPhase.savingToDatabase,
          message: 'Veritabanına kaydediliyor...',
        ));
      }

      // 4️⃣ Drift'e kaydet
      final contactModels = <ContactIndexModel>[];
      int registeredCount = 0;

      for (final phone in allPhones) {
        final contact = phoneToContact[phone]!;
        final userData = registeredUsers[phone];

        ContactIndexModel model;
        if (userData != null) {
          // Kayıtlı kullanıcı
          model = _createContactIndexModelFromFirebaseUser(
            normalizedPhone: phone,
            userData: userData,
            contactName: contact.displayName,
            originalPhone: contact.phones.first.number,
          );
          registeredCount++;
        } else {
          // Sadece rehber kişisi
          model = _createContactIndexModelFromContact(
            normalizedPhone: phone,
            contactName: contact.displayName,
            originalPhone: contact.phones.first.number,
          );
        }

        contactModels.add(model);
      }

      // Toplu kaydetme
      await DriftService.saveContactIndexes(contactModels);

      // Cache'i güncelle
      _cachedContacts = contactModels;
      _cacheTime = DateTime.now();
      _lastFullSync = DateTime.now();

      // Event gönder
      _contactsController.add(contactModels);
      _emitSyncEvent(ContactsSyncEvent.completed(
        contactModels.length,
        registeredCount,
      ));

      debugPrint('✅ Senkronizasyon tamamlandı:');
      debugPrint('   📊 Toplam: ${contactModels.length}');
      debugPrint('   🟢 Kayıtlı: $registeredCount');
      debugPrint('   🔴 Kayıtsız: ${contactModels.length - registeredCount}');
    } catch (e) {
      debugPrint('❌ Senkronizasyon hatası: $e');
      _emitSyncEvent(ContactsSyncEvent.error(e.toString()));
    }
  }

  /// 📱 Cihazdan rehberi oku
  static Future<List<Contact>> _readContactsFromDevice() async {
    try {
      // Platform kontrolü
      if (kIsWeb) {
        debugPrint('⚠️ Web platformunda rehber desteği yok');
        return [];
      }

      debugPrint('📋 FlutterContacts ile rehber okunuyor...');
      
      // Rehberi oku
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      ).timeout(const Duration(seconds: 60));

      debugPrint('📋 FlutterContacts ${contacts.length} kişi döndürdü');
      return contacts;
    } on TimeoutException {
      debugPrint('⏰ Rehber okuma zaman aşımı');
      return [];
    } catch (e) {
      debugPrint('❌ Rehber okuma hatası: $e');
      return [];
    }
  }

  /// 🔥 Firebase'de telefon numaralarını kontrol et
  static Future<Map<String, Map<String, dynamic>>> _checkPhoneNumbersInFirebase(
    List<String> phoneNumbers,
  ) async {
    final result = <String, Map<String, dynamic>>{};
    const chunkSize = 10; // Firebase whereIn limiti

    try {
      final col = FirebaseFirestore.instance.collection('users');

      for (int i = 0; i < phoneNumbers.length; i += chunkSize) {
        final chunk = phoneNumbers.sublist(
          i,
          (i + chunkSize > phoneNumbers.length)
              ? phoneNumbers.length
              : i + chunkSize,
        );

        // normalizedPhone alanında ara
        try {
          final snapshot = await col
              .where('normalizedPhone', whereIn: chunk)
              .get()
              .timeout(const Duration(seconds: 10));

          await FirebaseUsageTracker.incrementRead(snapshot.docs.length);

          for (final doc in snapshot.docs) {
            final data = doc.data();
            final normalizedPhone = data['normalizedPhone'] as String?;
            if (normalizedPhone != null) {
              data['id'] = doc.id; // Belge ID'sini ekle
              result[normalizedPhone] = data;
            }
          }
        } catch (e) {
          debugPrint('⚠️ Firebase normalizedPhone sorgu hatası: $e');
        }

        // phoneNumber alanında da ara (bulunamayanlar için)
        final remaining =
            chunk.where((phone) => !result.containsKey(phone)).toList();
        if (remaining.isNotEmpty) {
          try {
            final snapshot = await col
                .where('phoneNumber', whereIn: remaining)
                .get()
                .timeout(const Duration(seconds: 10));

            await FirebaseUsageTracker.incrementRead(snapshot.docs.length);

            for (final doc in snapshot.docs) {
              final data = doc.data();
              final phoneNumber = data['phoneNumber'] as String?;
              final normalizedPhone =
                  data['normalizedPhone'] as String? ?? phoneNumber;

              if (normalizedPhone != null &&
                  !result.containsKey(normalizedPhone)) {
                data['id'] = doc.id;
                result[normalizedPhone] = data;
              }
            }
          } catch (e) {
            debugPrint('⚠️ Firebase phoneNumber sorgu hatası: $e');
          }
        }

        // Rate limiting
        if (i + chunkSize < phoneNumbers.length) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
    } catch (e) {
      debugPrint('❌ Firebase kontrol hatası: $e');
    }

    return result;
  }

  /// 📞 Telefon numarası normalizasyonu
  static String? _normalizePhoneNumber(String phoneNumber) {
    try {
      // Temizle: sadece rakam ve +
      String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      if (cleaned.isEmpty) return null;

      // 00 ile başlayan uluslararası formatı + ile değiştir
      if (cleaned.startsWith('00')) {
        cleaned = '+${cleaned.substring(2)}';
      }

      // Türkiye özel: 0 başlıyorsa +90'a çevir
      if (cleaned.startsWith('0') && !cleaned.startsWith('00')) {
        cleaned = '+90${cleaned.substring(1)}';
      }

      // 90 ile başlıyorsa + ekle
      if (cleaned.startsWith('90') && !cleaned.startsWith('+')) {
        cleaned = '+$cleaned';
      }

      // + ile başlıyorsa olduğu gibi bırak, aksi halde TR ekle
      if (!cleaned.startsWith('+')) {
        cleaned = '+90$cleaned';
      }

      // Çoklu + temizle
      cleaned = cleaned.replaceAll(RegExp(r'^\++'), '+');

      return cleaned;
    } catch (e) {
      debugPrint('❌ Telefon normalizasyon hatası: $e');
      return null;
    }
  }

  /// ✅ Rehber izni kontrolü
  static Future<bool> _requestContactsPermission() async {
    if (kIsWeb) return false;

    try {
      final permission = Permission.contacts;
      final status = await permission.status;

      if (status.isGranted) {
        return true;
      } else if (status.isDenied) {
        final result = await permission.request();
        return result.isGranted;
      } else if (status.isPermanentlyDenied) {
        debugPrint('⚠️ Rehber izni kalıcı olarak reddedildi');
        return false;
      }

      return false;
    } catch (e) {
      debugPrint('❌ İzin kontrolü hatası: $e');
      return false;
    }
  }

  /// 🔍 Filtreleri uygula
  static List<ContactIndexModel> _applyFilters(
    List<ContactIndexModel> contacts, {
    bool onlyRegistered = false,
    String? searchQuery,
    int? limit,
  }) {
    var filtered = contacts;

    // Kayıtlı filtresi
    if (onlyRegistered) {
      filtered = filtered.where((c) => c.isRegistered).toList();
    }

    // Arama filtresi
    if (searchQuery?.isNotEmpty == true) {
      final query = searchQuery!.toLowerCase();
      filtered = filtered.where((contact) {
        final name = _getEffectiveDisplayName(contact).toLowerCase();
        final phone = contact.normalizedPhone.toLowerCase();
        return name.contains(query) || phone.contains(query);
      }).toList();
    }

    // Limit
    if (limit != null && limit > 0) {
      filtered = filtered.take(limit).toList();
    }

    // Alfabetik sıralama
    filtered.sort((a, b) => _getEffectiveDisplayName(a)
        .toLowerCase()
        .compareTo(_getEffectiveDisplayName(b).toLowerCase()));

    return filtered;
  }

  /// ⏰ Cache geçerlilik kontrolü
  static bool _isCacheValid() {
    if (_cacheTime == null) return false;
    return DateTime.now().difference(_cacheTime!) < _cacheValidDuration;
  }

  /// 🕐 Senkronizasyon gerekli mi?
  static bool _shouldPerformSync() {
    if (_lastFullSync == null) return true;
    return DateTime.now().difference(_lastFullSync!) > const Duration(hours: 1);
  }

  /// 📡 Event gönder
  static void _emitSyncEvent(ContactsSyncEvent event) {
    if (!_syncEventController.isClosed) {
      _syncEventController.add(event);
    }
  }

  /// 🔄 Temizlik
  static void dispose() {
    _syncEventController.close();
    _contactsController.close();
    _cachedContacts = null;
    _cacheTime = null;
    _isInitialized = false;
  }

  /// 🔧 Firebase kullanıcısından ContactIndexModel oluştur
  static ContactIndexModel _createContactIndexModelFromFirebaseUser({
    required String normalizedPhone,
    required Map<String, dynamic> userData,
    String? contactName,
    String? originalPhone,
  }) {
    return ContactIndexModel.fromFirebaseUser(
      normalizedPhone: normalizedPhone,
      userData: userData,
      contactName: contactName,
      originalPhone: originalPhone,
    );
  }

  /// 🔧 Rehber kişisinden ContactIndexModel oluştur
  static ContactIndexModel _createContactIndexModelFromContact({
    required String normalizedPhone,
    required String contactName,
    String? originalPhone,
  }) {
    return ContactIndexModel.fromContact(
      normalizedPhone: normalizedPhone,
      contactName: contactName,
      originalPhone: originalPhone,
    );
  }

  /// 🔧 Etkili görüntüleme adını al (UI için)
  static String _getEffectiveDisplayName(ContactIndexModel contact) {
    return contact.effectiveDisplayName;
  }
}

/// 📡 Senkronizasyon event modeli
class ContactsSyncEvent {
  final SyncPhase? phase;
  final String? message;
  final int? totalContacts;
  final int? registeredCount;
  final String? error;
  final bool isCompleted;
  final bool hasError;

  const ContactsSyncEvent._({
    this.phase,
    this.message,
    this.totalContacts,
    this.registeredCount,
    this.error,
    required this.isCompleted,
    required this.hasError,
  });

  factory ContactsSyncEvent.started() {
    return const ContactsSyncEvent._(
      phase: SyncPhase.starting,
      message: 'Senkronizasyon başlatılıyor...',
      isCompleted: false,
      hasError: false,
    );
  }

  factory ContactsSyncEvent.progress({
    required SyncPhase phase,
    required String message,
  }) {
    return ContactsSyncEvent._(
      phase: phase,
      message: message,
      isCompleted: false,
      hasError: false,
    );
  }

  factory ContactsSyncEvent.completed(int totalContacts, int registeredCount) {
    return ContactsSyncEvent._(
      phase: SyncPhase.completed,
      message: 'Tamamlandı: $totalContacts kişi ($registeredCount kayıtlı)',
      totalContacts: totalContacts,
      registeredCount: registeredCount,
      isCompleted: true,
      hasError: false,
    );
  }

  factory ContactsSyncEvent.error(String error) {
    return ContactsSyncEvent._(
      error: error,
      message: 'Hata: $error',
      isCompleted: true,
      hasError: true,
    );
  }
}

/// 📊 Senkronizasyon aşamaları
enum SyncPhase {
  starting,
  readingContacts,
  processing,
  checkingFirebase,
  savingToDatabase,
  completed,
}
