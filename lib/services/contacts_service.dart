import 'package:flutter_contacts/flutter_contacts.dart';
import 'dart:async';
import '../database/drift_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'firebase_usage_tracker.dart';

class ContactsService {
  // Oturum içi önbellek: numara -> kullanıcı verisi ya da not-found
  static final Map<String, Map<String, dynamic>> _registeredCache = {};
  static final Set<String> _notFoundCache = <String>{};
  static DateTime _lastCacheClean = DateTime.now();

  static void _maybeCleanCaches() {
    // 6 saatte bir basit temizleme (çok büyümeyi engelle)
    final now = DateTime.now();
    if (now.difference(_lastCacheClean).inHours >= 6) {
      _registeredCache.clear();
      _notFoundCache.clear();
      _lastCacheClean = now;
    }
  }

  // Rehber erişimi sadece Android/iOS'ta desteklenir
  static bool get _isContactsSupported {
    if (kIsWeb) return false;
    // defaultTargetPlatform kullanarak platformu kontrol et
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  static Future<bool> requestContactsPermission() async {
    if (!_isContactsSupported) return false;
    final permission = Permission.contacts;
    final status = await permission.status;

    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      final result = await permission.request();
      return result.isGranted;
    } else if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    return false;
  }

  static Future<List<Contact>> getContacts({int? limit}) async {
    try {
      if (!_isContactsSupported) return [];
      final hasPermission = await requestContactsPermission();
      if (!hasPermission) {
        throw Exception('Rehber izni verilmedi');
      }

      // 🚀 PERFORMANS: Büyük rehberlerde pagination ile yükleme
      if (limit != null && limit > 500) {
        debugPrint('⚡ Büyük rehber tespit edildi, parçalı yükleme başlatılıyor...');
        return await _getContactsPaginated(limit: limit);
      }

      // Küçük rehberler için normal yükleme
      final contacts = await FlutterContacts.getContacts(
              withProperties: true, withPhoto: false)
          .timeout(const Duration(seconds: 60));

      if (limit != null && contacts.length > limit) {
        return contacts.sublist(0, limit);
      }
      return contacts;
    } on TimeoutException {
      debugPrint('Rehber okuma zaman aşımına uğradı');
      return [];
    } catch (e) {
      debugPrint('Rehber okuma hatası: $e');
      return [];
    }
  }

  // 🚀 Parçalı rehber yükleme metodu
  static Future<List<Contact>> _getContactsPaginated({required int limit}) async {
    try {
      final List<Contact> allContacts = [];
      const int chunkSize = 500; // Her seferinde 500 kişi yükle
      int offset = 0;
      
      while (allContacts.length < limit) {
        final remaining = limit - allContacts.length;
        final currentChunkSize = remaining < chunkSize ? remaining : chunkSize;
        
        debugPrint('📋 Rehber yükleniyor: ${allContacts.length}/$limit');
        
        // Bu parça için kişileri yükle
        final chunk = await FlutterContacts.getContacts(
          withProperties: true, 
          withPhoto: false,
        ).timeout(const Duration(seconds: 30));
        
        if (chunk.isEmpty) break; // Daha fazla kişi yok
        
        // Offset uygula ve chunk boyutunu sınırla
        final startIndex = offset;
        final endIndex = (startIndex + currentChunkSize) > chunk.length 
            ? chunk.length 
            : startIndex + currentChunkSize;
            
        if (startIndex >= chunk.length) break;
        
        allContacts.addAll(chunk.sublist(startIndex, endIndex));
        offset += currentChunkSize;
        
        // UI'nin donmaması için kısa bir bekleme
        await Future.delayed(const Duration(milliseconds: 50));
      }
      
      debugPrint('✅ Toplam ${allContacts.length} kişi yüklendi');
      return allContacts;
    } catch (e) {
      debugPrint('❌ Parçalı rehber yükleme hatası: $e');
      return [];
    }
  }

  static String? normalizePhoneNumber(String phoneNumber) {
    try {
      // 1) Temizle: sadece rakam ve +
      String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      if (cleaned.isEmpty) return null;

      // 2) 00 ile başlayan uluslararası formatı + ile değiştir
      if (cleaned.startsWith('00')) {
        cleaned = '+${cleaned.substring(2)}';
      }

      // 3) Türkiye özel: 0 başlıyorsa +90'a çevir
      if (cleaned.startsWith('0')) {
        cleaned = '+90${cleaned.substring(1)}';
      }

      // 4) 90 ile başlıyorsa + ekle
      if (cleaned.startsWith('90') && !cleaned.startsWith('+')) {
        cleaned = '+$cleaned';
      }

      // 5) + ile başlıyorsa olduğu gibi bırak, aksi halde TR ekle
      if (!cleaned.startsWith('+')) {
        cleaned = '+90$cleaned';
      }

      // 6) Çoklu + veya hatalı durumları normalize et
      cleaned = cleaned.replaceAll(RegExp(r'^\++'), '+');

      return cleaned;
    } catch (e) {
      debugPrint('Telefon numarası formatlanırken hata: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getRegisteredContacts(
      {int? contactReadLimit}) async {
    try {
      _maybeCleanCaches();
      
      // 🚀 PERFORMANS: Büyük rehberler için sınırlama
      final effectiveLimit = contactReadLimit ?? 1000; // Varsayılan limit
      debugPrint('📱 Rehber yükleme başlıyor (limit: $effectiveLimit)');
      
      // Rehber okuma zaten timeout'lu; yine de üst katmanda da koruma
      final contacts = await getContacts(limit: effectiveLimit)
          .timeout(const Duration(seconds: 90), onTimeout: () => <Contact>[]);
      
      if (contacts.isEmpty) {
        debugPrint('⚠️ Rehber boş veya izin verilmedi');
        return [];
      }
      
      debugPrint('📋 ${contacts.length} kişi yüklendi, Firebase kontrolü başlıyor...');
      final registeredContacts = <Map<String, dynamic>>[];

      // Rehberdeki telefonları normalize edip küçük parçalara ayırarak
      // Firestore'a whereIn ile sor.
      final Set<String> normalizedPhones = {};
      for (final c in contacts) {
        for (final p in c.phones) {
          final n = normalizePhoneNumber(p.number);
          if (n != null) normalizedPhones.add(n);
        }
      }

      final List<String> phoneList = normalizedPhones.toList();
      debugPrint('🔍 ${phoneList.length} telefon numarası normalize edildi');
      final Map<String, Map<String, dynamic>> registeredPhones = {};

      // 0) Önbellekten besle
      final List<String> toQuery = [];
      for (final phone in phoneList) {
        if (_registeredCache.containsKey(phone)) {
          registeredPhones[phone] = _registeredCache[phone]!;
        } else if (!_notFoundCache.contains(phone)) {
          toQuery.add(phone);
        }
      }

      // 🚀 PERFORMANS: whereIn sorguları için daha büyük chunk boyutu
      const int chunkSize = 10; // Firebase whereIn limiti
      for (int i = 0; i < toQuery.length; i += chunkSize) {
        final chunk = toQuery.sublist(
            i, (i + chunkSize > toQuery.length) ? toQuery.length : i + chunkSize);
        
        debugPrint('🔥 Firebase sorgusu: ${i + 1}-${i + chunk.length}/${toQuery.length}');
        // Önce normalizedPhone ile dene
        final col = FirebaseFirestore.instance.collection('users');
        final snapNormalized =
            await col.where('normalizedPhone', whereIn: chunk).get();
        await FirebaseUsageTracker.incrementRead(snapNormalized.docs.length);
        debugPrint('✅ ${snapNormalized.docs.length} kayıtlı kullanıcı bulundu');

        for (final doc in snapNormalized.docs) {
          final data = doc.data();
          final uid = data['uid'] ?? doc.id;
          final displayName =
              data['name'] ?? data['displayName'] ?? 'İsimsiz Kullanıcı';
          final phoneNumber = data['phoneNumber'] as String?;
          final normalized = data['normalizedPhone'] as String?;
          if (normalized != null) {
            registeredPhones[normalized] = {
              'uid': uid,
              'displayName': displayName,
              'phoneNumber': phoneNumber ?? normalized,
              'photoURL': data['profileImageUrl'] ?? data['photoURL'],
              'isOnline': data['isOnline'] ?? false,
              'lastSeen': data['lastSeen'],
              'isRegistered': true,
            };
            _registeredCache[normalized] = registeredPhones[normalized]!;
          }
        }

        // Ayrıca phoneNumber alanında eşleşmeyenler için tek seferde sorgula
        final remainingForPhone = chunk
            .where((p) => !registeredPhones.containsKey(p))
            .toList(growable: false);
        if (remainingForPhone.isNotEmpty) {
          final snapPhone =
              await col.where('phoneNumber', whereIn: remainingForPhone).get();
          await FirebaseUsageTracker.incrementRead(snapPhone.docs.length);
          for (final doc in snapPhone.docs) {
            final data = doc.data();
            final uid = data['uid'] ?? doc.id;
            final displayName =
                data['name'] ?? data['displayName'] ?? 'İsimsiz Kullanıcı';
            final phoneNumber = data['phoneNumber'] as String?;
            final String? normalized =
                (data['normalizedPhone'] as String?) ?? phoneNumber;
            if (normalized != null &&
                !registeredPhones.containsKey(normalized)) {
              registeredPhones[normalized] = {
                'uid': uid,
                'displayName': displayName,
                'phoneNumber': phoneNumber ?? normalized,
                'photoURL': data['profileImageUrl'] ?? data['photoURL'],
                'isOnline': data['isOnline'] ?? false,
                'lastSeen': data['lastSeen'],
                'isRegistered': true,
              };
              _registeredCache[normalized] = registeredPhones[normalized]!;
            }
          }
        }
      }

      // Bulunamayanları negatif önbelleğe ekle
      for (final p in phoneList) {
        if (!registeredPhones.containsKey(p)) {
          _notFoundCache.add(p);
        }
      }

      // Rehberdeki kişileri kontrol et
      for (final contact in contacts) {
        final contactName = contact.displayName;

        for (final phone in contact.phones) {
          final normalizedPhone = normalizePhoneNumber(phone.number);
          if (normalizedPhone != null) {
            if (registeredPhones.containsKey(normalizedPhone)) {
              // Kayıtlı kullanıcı
              final userData = registeredPhones[normalizedPhone]!;
              registeredContacts.add({
                'uid': userData['uid'],
                'displayName': userData['displayName'],
                'phoneNumber': userData['phoneNumber'],
                'photoURL': userData['photoURL'],
                'isOnline': userData['isOnline'],
                'lastSeen': userData['lastSeen'],
                'isRegistered': userData['isRegistered'],
                'contactName': contactName,
                'originalPhoneNumber': phone.number,
                'normalizedPhoneNumber': normalizedPhone,
              });
            } else {
              // Kayıtlı olmayan kişi
              registeredContacts.add({
                'uid': null,
                'displayName': contactName,
                'contactName': contactName,
                'phoneNumber': normalizedPhone,
                'originalPhoneNumber': phone.number,
                'normalizedPhoneNumber': normalizedPhone,
                'photoURL': null,
                'isOnline': false,
                'lastSeen': null,
                'isRegistered': false,
              });
            }
          }
        }
      }

      // Tekrar eden kayıtları temizle (aynı telefon numarası)
      final uniqueContacts = <String, Map<String, dynamic>>{};
      for (final contact in registeredContacts) {
        final phone = contact['normalizedPhoneNumber'] as String;
        if (!uniqueContacts.containsKey(phone) ||
            (contact['isRegistered'] == true &&
                uniqueContacts[phone]!['isRegistered'] == false)) {
          uniqueContacts[phone] = contact;
        }
      }

      return uniqueContacts.values.toList();
    } catch (e) {
      debugPrint('Kayıtlı kişiler alınırken hata: $e');
      return [];
    }
  }

  /// Sorguya göre rehberden kişi ara; sonuçları kayıt durumlarıyla döndür
  static Future<List<Map<String, dynamic>>> getRegisteredContactsByQuery({
    required String query,
    int limit = 200,
  }) async {
    try {
      _maybeCleanCaches();
      if (!_isContactsSupported) return [];

      final hasPermission = await requestContactsPermission();
      if (!hasPermission) return [];

      final List<Contact> contacts = await searchContacts(
        query: query,
        limit: limit,
      ).timeout(const Duration(seconds: 60), onTimeout: () => <Contact>[]);

      final Set<String> normalizedPhones = {};
      for (final c in contacts) {
        for (final p in c.phones) {
          final n = normalizePhoneNumber(p.number);
          if (n != null) normalizedPhones.add(n);
        }
      }

      final List<String> phoneList = normalizedPhones.toList();
      final Map<String, Map<String, dynamic>> registeredPhones = {};

      final List<String> toQuery = [];
      for (final phone in phoneList) {
        if (_registeredCache.containsKey(phone)) {
          registeredPhones[phone] = _registeredCache[phone]!;
        } else if (!_notFoundCache.contains(phone)) {
          toQuery.add(phone);
        }
      }

      for (int i = 0; i < toQuery.length; i += 10) {
        final chunk = toQuery.sublist(
            i, (i + 10 > toQuery.length) ? toQuery.length : i + 10);
        final col = FirebaseFirestore.instance.collection('users');

        final snapNormalized =
            await col.where('normalizedPhone', whereIn: chunk).get();
        await FirebaseUsageTracker.incrementRead(snapNormalized.docs.length);
        for (final doc in snapNormalized.docs) {
          final data = doc.data();
          final uid = data['uid'] ?? doc.id;
          final displayName =
              data['name'] ?? data['displayName'] ?? 'İsimsiz Kullanıcı';
          final phoneNumber = data['phoneNumber'] as String?;
          final normalized = data['normalizedPhone'] as String?;
          if (normalized != null) {
            registeredPhones[normalized] = {
              'uid': uid,
              'displayName': displayName,
              'phoneNumber': phoneNumber ?? normalized,
              'photoURL': data['profileImageUrl'] ?? data['photoURL'],
              'isOnline': data['isOnline'] ?? false,
              'lastSeen': data['lastSeen'],
              'isRegistered': true,
            };
            _registeredCache[normalized] = registeredPhones[normalized]!;
          }
        }

        final remainingForPhone = chunk
            .where((p) => !registeredPhones.containsKey(p))
            .toList(growable: false);
        if (remainingForPhone.isNotEmpty) {
          final snapPhone =
              await col.where('phoneNumber', whereIn: remainingForPhone).get();
          await FirebaseUsageTracker.incrementRead(snapPhone.docs.length);
          for (final doc in snapPhone.docs) {
            final data = doc.data();
            final uid = data['uid'] ?? doc.id;
            final displayName =
                data['name'] ?? data['displayName'] ?? 'İsimsiz Kullanıcı';
            final phoneNumber = data['phoneNumber'] as String?;
            final String? normalized =
                (data['normalizedPhone'] as String?) ?? phoneNumber;
            if (normalized != null &&
                !registeredPhones.containsKey(normalized)) {
              registeredPhones[normalized] = {
                'uid': uid,
                'displayName': displayName,
                'phoneNumber': phoneNumber ?? normalized,
                'photoURL': data['profileImageUrl'] ?? data['photoURL'],
                'isOnline': data['isOnline'] ?? false,
                'lastSeen': data['lastSeen'],
                'isRegistered': true,
              };
              _registeredCache[normalized] = registeredPhones[normalized]!;
            }
          }
        }
      }

      for (final p in phoneList) {
        if (!registeredPhones.containsKey(p)) {
          _notFoundCache.add(p);
        }
      }

      final List<Map<String, dynamic>> result = [];
      for (final contact in contacts) {
        final contactName = contact.displayName;
        for (final phone in contact.phones) {
          final normalizedPhone = normalizePhoneNumber(phone.number);
          if (normalizedPhone != null) {
            if (registeredPhones.containsKey(normalizedPhone)) {
              final userData = registeredPhones[normalizedPhone]!;
              result.add({
                'uid': userData['uid'],
                'displayName': userData['displayName'],
                'phoneNumber': userData['phoneNumber'],
                'photoURL': userData['photoURL'],
                'isOnline': userData['isOnline'],
                'lastSeen': userData['lastSeen'],
                'isRegistered': userData['isRegistered'],
                'contactName': contactName,
                'originalPhoneNumber': phone.number,
                'normalizedPhoneNumber': normalizedPhone,
              });
            } else {
              result.add({
                'uid': null,
                'displayName': contactName,
                'contactName': contactName,
                'phoneNumber': normalizedPhone,
                'originalPhoneNumber': phone.number,
                'normalizedPhoneNumber': normalizedPhone,
                'photoURL': null,
                'isOnline': false,
                'lastSeen': null,
                'isRegistered': false,
              });
            }
          }
        }
      }

      final uniqueContacts = <String, Map<String, dynamic>>{};
      for (final contact in result) {
        final phone = contact['normalizedPhoneNumber'] as String;
        if (!uniqueContacts.containsKey(phone) ||
            (contact['isRegistered'] == true &&
                uniqueContacts[phone]!['isRegistered'] == false)) {
          uniqueContacts[phone] = contact;
        }
      }

      return uniqueContacts.values.toList();
    } catch (e) {
      debugPrint('Kayıtlı kişiler (sorgu) alınırken hata: $e');
      return [];
    }
  }

  /// Hızlı arama: sistem rehberinde isim/telefonla arama yap, limit uygula
  static Future<List<Contact>> searchContacts({
    required String query,
    int limit = 200,
  }) async {
    try {
      if (!_isContactsSupported) return [];
      final hasPermission = await requestContactsPermission();
      if (!hasPermission) return [];

      final all = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      ).timeout(const Duration(seconds: 60));
      final q = _normalizeText(query.trim().toLowerCase());
      final qDigits = query.replaceAll(RegExp('[^0-9+]'), '');
      final contacts = all
          .where((c) {
            final name = _normalizeText(c.displayName.toLowerCase());
            final nameHit = name.contains(q);
            final phoneHit = c.phones.any((p) {
              final cleaned = p.number.replaceAll(RegExp('[^0-9+]'), '');
              final rawLower = _normalizeText(p.number.toLowerCase());
              final digitsOk = qDigits.isNotEmpty && cleaned.contains(qDigits);
              final rawOk = rawLower.contains(q);
              return digitsOk || rawOk;
            });
            return nameHit || phoneHit;
          })
          .take(limit)
          .toList();
      if (contacts.length > limit) {
        return contacts.sublist(0, limit);
      }
      return contacts;
    } catch (e) {
      debugPrint('Rehber arama hatası: $e');
      return [];
    }
  }

  // Türkçe karakterleri sadeleştirerek diacritics-insensitive arama sağlar
  static String _normalizeText(String input) {
    const map = {
      'ç': 'c',
      'ğ': 'g',
      'ı': 'i',
      'i̇': 'i',
      'ö': 'o',
      'ş': 's',
      'ü': 'u',
      'Ç': 'c',
      'Ğ': 'g',
      'İ': 'i',
      'I': 'i',
      'Ö': 'o',
      'Ş': 's',
      'Ü': 'u',
    };
    final runes = input.runes.toList();
    final buffer = StringBuffer();
    for (final r in runes) {
      final ch = String.fromCharCode(r);
      buffer.write(map[ch] ?? ch);
    }
    return buffer.toString();
  }

  // Sadece uygulamayı kullanan rehber kişilerini getir
  static Future<List<Map<String, dynamic>>> getRegisteredContactsOnly() async {
    final allContacts = await getRegisteredContacts();
    return allContacts
        .where((contact) => contact['isRegistered'] == true)
        .toList();
  }

  static Future<void> inviteContact(
    String phoneNumber,
    String contactName,
  ) async {
    // Davet gönderme fonksiyonu - SMS, WhatsApp vs. entegrasyonu burada olacak
    debugPrint('$contactName ($phoneNumber) kişisine davet gönderiliyor...');
  }

  // Kullanıcı ID'sine göre rehberdeki ismini getir
  static Future<String?> getContactNameByUid(String userId) async {
    // Önce yerelden dene (Firebase maliyetini azalt)
    try {
      final local = await DriftService.getUserByUserId(userId);
      if (local != null) {
        if (local.name != null && local.name!.isNotEmpty) {
          return local.name;
        }
      }
    } catch (_) {}

    try {
      // Son çare: kullanıcı dokümanından isim alanlarını getir
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data();
        return data?['name'] ?? data?['displayName'] ?? data?['username'];
      }
    } catch (e) {
      debugPrint('❌ Rehber adı alma hatası: $e');
    }
    return null;
  }

  /// Telefon numarasına göre rehberdeki ismi döndürür. Bulamazsa null döner.
  static Future<String?> getContactNameByPhone(String phoneNumber) async {
    final normalized = ContactsService.normalizePhoneNumber(phoneNumber);
    if (normalized == null) return null;
    final contacts = await ContactsService.getContacts();
    for (final contact in contacts) {
      for (final phone in contact.phones) {
        final contactNormalized = ContactsService.normalizePhoneNumber(
          phone.number,
        );
        if (contactNormalized == normalized) {
          return contact.displayName;
        }
      }
    }
    return null;
  }

  /// Telefon numarasına göre rehberdeki kişiyi döndürür. Bulamazsa null döner.
  static Future<Contact?> getContactByPhone(String phoneNumber) async {
    final normalized = ContactsService.normalizePhoneNumber(phoneNumber);
    if (normalized == null) return null;

    final contacts = await ContactsService.getContacts();
    for (final contact in contacts) {
      for (final phone in contact.phones) {
        final contactNormalized = ContactsService.normalizePhoneNumber(
          phone.number,
        );
        if (contactNormalized == normalized) {
          return contact;
        }
      }
    }
    return null;
  }
}
