import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/contact_index_model.dart';
import 'contacts_manager.dart';

/// 🎯 UI CONTACTS SERVICE
/// 
/// Bu servis UI katmanı için ContactsManager'ın basitleştirilmiş arayüzünü sağlar.
/// Tüm UI bileşenleri bu servisi kullanmalı, doğrudan ContactsManager'ı çağırmamalı.
/// 
/// KULLANIM ALANLARI:
/// ✅ NewChatPage - Yeni sohbet kişi listesi
/// ✅ CreateGroupPage - Grup üye seçimi
/// ✅ ForwardMessagePage - Mesaj iletme kişi listesi
/// ✅ CallPage - Arama başlatma kişi listesi
/// ✅ ve tüm gelecekteki özellikler...
class UIContactsService {
  /// 📞 Yeni sohbet için kişi listesi
  /// Sadece kayıtlı kullanıcıları döndürür
  static Future<List<ContactViewModel>> getContactsForNewChat({
    String? searchQuery,
    int? limit,
  }) async {
    try {
      final contacts = await ContactsManager.getContacts(
        onlyRegistered: true,
        searchQuery: searchQuery,
        limit: limit ?? 1000,
      );
      
      // Sadece uid'i olan contact'ları filtrele
      final validContacts = contacts.where((c) => c.registeredUid != null && c.registeredUid!.isNotEmpty).toList();
      
      return validContacts.map((contact) => ContactViewModel.fromContactIndex(contact)).toList();
    } catch (e) {
      debugPrint('❌ getContactsForNewChat hatası: $e');
      return [];
    }
  }

  /// 👥 Grup oluşturma için kişi listesi  
  /// Sadece kayıtlı kullanıcıları döndürür
  static Future<List<ContactViewModel>> getContactsForGroup({
    String? searchQuery,
    List<String>? excludeUids, // Halihazırda seçili olanları hariç tut
  }) async {
    try {
      final contacts = await ContactsManager.getContacts(
        onlyRegistered: true,
        searchQuery: searchQuery,
      );
      
      // Sadece uid'i olan contact'ları filtrele
      var validContacts = contacts.where((c) => c.registeredUid != null && c.registeredUid!.isNotEmpty).toList();
      
      if (excludeUids?.isNotEmpty == true) {
        validContacts = validContacts.where((c) => !excludeUids!.contains(c.registeredUid)).toList();
      }
      
      return validContacts.map((contact) => ContactViewModel.fromContactIndex(contact)).toList();
    } catch (e) {
      debugPrint('❌ getContactsForGroup hatası: $e');
      return [];
    }
  }

  /// ↗️ Mesaj iletme için kişi listesi
  /// Hem kayıtlı kullanıcılar hem de gruplar (gelecekte)
  static Future<List<ContactViewModel>> getContactsForForward({
    String? searchQuery,
  }) async {
    try {
      final contacts = await ContactsManager.getContacts(
        onlyRegistered: true,
        searchQuery: searchQuery,
        limit: 500, // İletme için limit
      );
      
      return contacts.map((contact) => ContactViewModel.fromContactIndex(contact)).toList();
    } catch (e) {
      debugPrint('❌ getContactsForForward hatası: $e');
      return [];
    }
  }

  /// 📞 Arama başlatma için kişi listesi
  /// Sadece kayıtlı kullanıcıları döndürür
  static Future<List<ContactViewModel>> getContactsForCall({
    String? searchQuery,
  }) async {
    try {
      final contacts = await ContactsManager.getContacts(
        onlyRegistered: true,
        searchQuery: searchQuery,
        limit: 200, // Arama için sınırlı liste
      );
      
      return contacts.map((contact) => ContactViewModel.fromContactIndex(contact)).toList();
    } catch (e) {
      debugPrint('❌ getContactsForCall hatası: $e');
      return [];
    }
  }

  /// 🔍 Genel arama
  /// Tüm kişileri arar (kayıtlı + kayıtsız)
  static Future<List<ContactViewModel>> searchAllContacts(String query) async {
    if (query.trim().isEmpty) {
      return getContactsForNewChat();
    }

    try {
      final contacts = await ContactsManager.searchContacts(query.trim());
      return contacts.map((contact) => ContactViewModel.fromContactIndex(contact)).toList();
    } catch (e) {
      debugPrint('❌ searchAllContacts hatası: $e');
      return [];
    }
  }

  /// 📱 Telefon numarasına göre kişi bul
  static Future<ContactViewModel?> findContactByPhone(String phoneNumber) async {
    try {
      final contact = await ContactsManager.findContactByPhone(phoneNumber);
      if (contact != null) {
        return ContactViewModel.fromContactIndex(contact);
      }
      return null;
    } catch (e) {
      debugPrint('❌ findContactByPhone hatası: $e');
      return null;
    }
  }

  /// 🆔 UID'ye göre kişi bul
  static Future<ContactViewModel?> findContactByUid(String uid) async {
    try {
      final contacts = await ContactsManager.getContacts(onlyRegistered: true);
      final contact = contacts.where((c) => c.registeredUid == uid).isNotEmpty 
          ? contacts.where((c) => c.registeredUid == uid).first 
          : null;
      if (contact != null) {
        return ContactViewModel.fromContactIndex(contact);
      }
      return null;
    } catch (e) {
      debugPrint('❌ findContactByUid hatası: $e');
      return null;
    }
  }

  /// 🔄 Manuel senkronizasyon tetikleme
  static Future<void> refreshContacts() async {
    await ContactsManager.forceSync();
  }

  /// 📊 Kişi istatistikleri
  static Future<ContactsStats> getContactsStats() async {
    try {
      final allContacts = await ContactsManager.getContacts();
      final registeredContacts = allContacts.where((c) => c.isRegistered).toList();
      
      return ContactsStats(
        totalContacts: allContacts.length,
        registeredContacts: registeredContacts.length,
        unregisteredContacts: allContacts.length - registeredContacts.length,
      );
    } catch (e) {
      debugPrint('❌ getContactsStats hatası: $e');
      return const ContactsStats(totalContacts: 0, registeredContacts: 0, unregisteredContacts: 0);
    }
  }

  /// 📡 Senkronizasyon olaylarını dinle
  static Stream<ContactsSyncEvent> get syncEventStream => ContactsManager.syncEventStream;

  /// 📱 Kişi güncellemelerini dinle
  static Stream<List<ContactIndexModel>> get contactsStream => ContactsManager.contactsStream;
}

/// 🎨 UI için optimize edilmiş kişi modeli
class ContactViewModel {
  final String? uid;
  final String displayName;
  final String phoneNumber;
  final String? profileImageUrl;
  final bool isOnline;
  final DateTime? lastSeen;
  final bool isRegistered;
  final String? contactName;

  const ContactViewModel({
    this.uid,
    required this.displayName,
    required this.phoneNumber,
    this.profileImageUrl,
    this.isOnline = false,
    this.lastSeen,
    this.isRegistered = false,
    this.contactName,
  });

  factory ContactViewModel.fromContactIndex(ContactIndexModel contact) {
    return ContactViewModel(
      uid: contact.registeredUid,
      displayName: contact.effectiveDisplayName,
      phoneNumber: contact.normalizedPhone,
      profileImageUrl: contact.profileImageUrl,
      isOnline: contact.isOnline,
      lastSeen: contact.lastSeen,
      isRegistered: contact.isRegistered,
      contactName: contact.contactName,
    );
  }

  /// UI için avatar metnini hesapla
  String get avatarText {
    if (displayName.isNotEmpty) {
      return displayName[0].toUpperCase();
    }
    return '?';
  }

  /// Online durumu metni
  String get onlineStatusText {
    if (!isRegistered) return 'Uygulamayı kullanmıyor';
    if (isOnline) return 'Çevrimiçi';
    if (lastSeen != null) {
      final diff = DateTime.now().difference(lastSeen!);
      if (diff.inMinutes < 1) return 'Az önce görüldü';
      if (diff.inHours < 1) return '${diff.inMinutes} dakika önce görüldü';
      if (diff.inDays < 1) return '${diff.inHours} saat önce görüldü';
      return '${diff.inDays} gün önce görüldü';
    }
    return 'Bilinmiyor';
  }

  /// Mesajlaşmaya uygun mu?
  bool get canChat => isRegistered && uid != null;

  /// Arama yapılabilir mi?
  bool get canCall => isRegistered && uid != null;

  @override
  String toString() {
    return 'ContactViewModel(name: $displayName, phone: $phoneNumber, registered: $isRegistered)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContactViewModel && other.phoneNumber == phoneNumber;
  }

  @override
  int get hashCode => phoneNumber.hashCode;
}

/// 📊 Kişi istatistikleri
class ContactsStats {
  final int totalContacts;
  final int registeredContacts;
  final int unregisteredContacts;

  const ContactsStats({
    required this.totalContacts,
    required this.registeredContacts,
    required this.unregisteredContacts,
  });

  double get registeredPercentage {
    if (totalContacts == 0) return 0;
    return (registeredContacts / totalContacts) * 100;
  }

  @override
  String toString() {
    return 'ContactsStats(total: $totalContacts, registered: $registeredContacts, percentage: ${registeredPercentage.toStringAsFixed(1)}%)';
  }
}