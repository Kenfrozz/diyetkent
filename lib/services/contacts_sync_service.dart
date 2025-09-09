import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../database/drift_service.dart';
import '../models/contact_index_model.dart';
import 'contacts_service.dart' as local_contacts;
import 'firebase_usage_tracker.dart';

/// ContactsSyncService
/// - UI'dan bağımsız, arkaplanda rehberi tarar
/// - Telefonları normalize eder, Firestore'da whereIn chunkları ile kayıtlıları bulur
/// - Sonuçları Isar ContactIndexModel'e yazar
/// - UI sadece Isar'dan veri okur
class ContactsSyncService {
  static bool _isRunning = false;
  static DateTime? _lastRunAt;

  /// 🚀 Optimize edilmiş arkaplan senkronu (büyük rehberler için)
  static Future<void> runFullSync({
    int? contactReadLimit,
    int chunkSize = 25, // 🔥 OPTİMİZASYON: 10 → 25 (Firebase maliyet %60 azaldı)
    Duration throttle = const Duration(milliseconds: 50), // Daha hızlı throttle
    bool showProgress = true,
  }) async {
    if (_isRunning) {
      debugPrint('⚠️ Rehber senkronizasyonu zaten çalışıyor, atlanıyor...');
      return;
    }
    _isRunning = true;
    final startTime = DateTime.now();
    
    try {
      // Büyük rehberler için limit uygula
      final effectiveLimit = contactReadLimit ?? 2000; // Maks 2000 kişi
      if (showProgress) {
        debugPrint('🔄 Rehber senkronizasyonu başlıyor (limit: $effectiveLimit)...');
      }
      
      // Rehber verisini çek
      final List<Contact> contacts = await local_contacts.ContactsService
              .getContacts(limit: effectiveLimit)
          .timeout(const Duration(seconds: 90), onTimeout: () => <Contact>[]);
          
      if (contacts.isEmpty) {
        debugPrint('⚠️ Rehber boş, senkronizasyon iptal edildi');
        return;
      }
      
      if (showProgress) {
        debugPrint('📋 ${contacts.length} kişi yüklendi, işleme başlıyor...');
      }

      // Tüm telefonları normalize ederek topla
      final Map<String, String?> phoneToName = {};
      for (final c in contacts) {
        for (final p in c.phones) {
          final n =
              local_contacts.ContactsService.normalizePhoneNumber(p.number);
          if (n != null) {
            phoneToName[n] = c.displayName;
          }
        }
      }

      final List<String> allPhones = phoneToName.keys.toList();
      if (allPhones.isEmpty) {
        debugPrint('⚠️ Normalize edilebilir telefon numarası bulunamadı');
        return;
      }
      
      if (showProgress) {
        debugPrint('🔍 ${allPhones.length} benzersiz telefon numarası normalize edildi');
      }

      final Map<String, Map<String, dynamic>> found = {};

      // 🚀 Optimize edilmiş Firestore sorguları
      final col = FirebaseFirestore.instance.collection('users');
      final totalChunks = (allPhones.length / chunkSize).ceil();
      
      for (int i = 0; i < allPhones.length; i += chunkSize) {
        final chunk = allPhones.sublist(
            i,
            (i + chunkSize > allPhones.length)
                ? allPhones.length
                : i + chunkSize);
                
        if (showProgress) {
          final currentChunk = (i / chunkSize).floor() + 1;
          debugPrint('🔥 Firebase sorgusu: $currentChunk/$totalChunks (${chunk.length} numara)');
        }

        // 1) normalizedPhone
        try {
          final snapN =
              await col.where('normalizedPhone', whereIn: chunk).get();
          await FirebaseUsageTracker.incrementRead(snapN.docs.length);
          for (final doc in snapN.docs) {
            final data = doc.data();
            final normalized = data['normalizedPhone'] as String?;
            if (normalized == null) continue;
            found[normalized] = data;
          }
        } catch (e) {
          debugPrint('ContactsSync normalizedPhone sorgu hatası: $e');
        }

        // 2) phoneNumber alanı ile kalanları dene
        final remaining = chunk.where((p) => !found.containsKey(p)).toList();
        if (remaining.isNotEmpty) {
          try {
            final snapP =
                await col.where('phoneNumber', whereIn: remaining).get();
            await FirebaseUsageTracker.incrementRead(snapP.docs.length);
            for (final doc in snapP.docs) {
              final data = doc.data();
              final normalized =
                  (data['normalizedPhone'] as String?) ?? data['phoneNumber'];
              if (normalized == null) continue;
              found[normalized] = data;
            }
          } catch (e) {
            debugPrint('ContactsSync phoneNumber sorgu hatası: $e');
          }
        }

        // 🚀 PERFORMANS: Dinamik throttling
        if (throttle.inMilliseconds > 0 && i > 0) {
          // İlk sorgular daha hızlı, sonrakiler yavaşlat
          final dynamicDelay = i > 100 
              ? Duration(milliseconds: throttle.inMilliseconds * 2)
              : throttle;
          await Future.delayed(dynamicDelay);
        }
      }

      // Isar'a yazma: kayıtlı/kayıtsız ayır
      final List<ContactIndexModel> toSave = [];
      for (final phone in allPhones) {
        final name = phoneToName[phone];
        final data = found[phone];
        if (data != null) {
          final uid = (data['uid'] as String?) ?? '';
          toSave.add(ContactIndexModel.create(
            normalizedPhone: phone,
            contactName: name,
            isRegistered: true,
            registeredUid: uid.isNotEmpty ? uid : (data['id'] as String?),
          ));
        } else {
          toSave.add(ContactIndexModel.create(
            normalizedPhone: phone,
            contactName: name,
            isRegistered: false,
            registeredUid: null,
          ));
        }
      }

      // Toplu kaydetme için chunk'lara böl
      const saveChunkSize = 100;
      for (int i = 0; i < toSave.length; i += saveChunkSize) {
        final saveChunk = toSave.sublist(
          i,
          (i + saveChunkSize > toSave.length) ? toSave.length : i + saveChunkSize,
        );
        await DriftService.saveContactIndexes(saveChunk);
        
        if (showProgress && toSave.length > saveChunkSize) {
          debugPrint('💾 Kayıt edildi: ${i + saveChunk.length}/${toSave.length}');
        }
      }
      
      _lastRunAt = DateTime.now();
      final duration = _lastRunAt!.difference(startTime);
      
      if (showProgress) {
        debugPrint('✅ Rehber senkronizasyonu tamamlandı!');
        debugPrint('🕰️ Süre: ${duration.inSeconds} saniye');
        debugPrint('📋 Toplam: ${toSave.length} kişi');
        debugPrint('🟢 Kayıtlı: ${toSave.where((e) => e.isRegistered).length}');
        debugPrint('🔴 Kayıtsız: ${toSave.where((e) => !e.isRegistered).length}');
      }
    } catch (e) {
      debugPrint('❌ ContactsSyncService.runFullSync hata: $e');
    } finally {
      _isRunning = false;
    }
  }

  /// İyileştirme: Kısmi sync. Belirli telefon listesi için çalışır
  static Future<void> syncPhones(Set<String> normalizedPhones,
      {int chunkSize = 10}) async {
    if (normalizedPhones.isEmpty) return;
    final col = FirebaseFirestore.instance.collection('users');
    final Map<String, Map<String, dynamic>> found = {};
    final List<String> phones = normalizedPhones.toList();
    for (int i = 0; i < phones.length; i += chunkSize) {
      final chunk = phones.sublist(
          i, (i + chunkSize > phones.length) ? phones.length : i + chunkSize);
      try {
        final snapN = await col.where('normalizedPhone', whereIn: chunk).get();
        await FirebaseUsageTracker.incrementRead(snapN.docs.length);
        for (final doc in snapN.docs) {
          final data = doc.data();
          final normalized = data['normalizedPhone'] as String?;
          if (normalized == null) continue;
          found[normalized] = data;
        }
      } catch (_) {}
      final remaining = chunk.where((p) => !found.containsKey(p)).toList();
      if (remaining.isNotEmpty) {
        try {
          final snapP =
              await col.where('phoneNumber', whereIn: remaining).get();
          await FirebaseUsageTracker.incrementRead(snapP.docs.length);
          for (final doc in snapP.docs) {
            final data = doc.data();
            final normalized =
                (data['normalizedPhone'] as String?) ?? data['phoneNumber'];
            if (normalized == null) continue;
            found[normalized] = data;
          }
        } catch (_) {}
      }
    }

    final List<ContactIndexModel> toSave = [];
    for (final phone in phones) {
      final data = found[phone];
      if (data != null) {
        toSave.add(ContactIndexModel.create(
          normalizedPhone: phone,
          contactName: null,
          isRegistered: true,
          registeredUid: (data['uid'] as String?) ?? (data['id'] as String?),
        ));
      } else {
        toSave.add(ContactIndexModel.create(
          normalizedPhone: phone,
          contactName: null,
          isRegistered: false,
        ));
      }
    }

    await DriftService.saveContactIndexes(toSave);
  }

  static DateTime? get lastRunAt => _lastRunAt;
  static bool get isRunning => _isRunning;
}
