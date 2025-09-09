import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/contact_indexes_table.dart';

part 'contact_index_dao.g.dart';

@DriftAccessor(tables: [ContactIndexesTable])
class ContactIndexDao extends DatabaseAccessor<AppDatabase> with _$ContactIndexDaoMixin {
  ContactIndexDao(super.db);

  // Get all contact indexes
  Future<List<ContactIndexData>> getAllContactIndexes() {
    return (select(contactIndexesTable)
          ..orderBy([(t) => OrderingTerm(expression: t.contactName, mode: OrderingMode.asc)]))
        .get();
  }

  // Watch all contact indexes
  Stream<List<ContactIndexData>> watchAllContactIndexes() {
    return (select(contactIndexesTable)
          ..orderBy([(t) => OrderingTerm(expression: t.contactName, mode: OrderingMode.asc)]))
        .watch();
  }

  // Get contact index by normalized phone
  Future<ContactIndexData?> getContactByNormalizedPhone(String normalizedPhone) {
    return (select(contactIndexesTable)..where((t) => t.normalizedPhone.equals(normalizedPhone)))
        .getSingleOrNull();
  }

  // Alias for compatibility
  Future<ContactIndexData?> getContactByPhone(String normalizedPhone) {
    return getContactByNormalizedPhone(normalizedPhone);
  }

  // Watch contact index by normalized phone
  Stream<ContactIndexData?> watchContactByNormalizedPhone(String normalizedPhone) {
    return (select(contactIndexesTable)..where((t) => t.normalizedPhone.equals(normalizedPhone)))
        .watchSingleOrNull();
  }

  // Get contact index by registered UID
  Future<ContactIndexData?> getContactByRegisteredUid(String registeredUid) {
    return (select(contactIndexesTable)..where((t) => t.registeredUid.equals(registeredUid)))
        .getSingleOrNull();
  }

  // Watch contact index by registered UID
  Stream<ContactIndexData?> watchContactByRegisteredUid(String registeredUid) {
    return (select(contactIndexesTable)..where((t) => t.registeredUid.equals(registeredUid)))
        .watchSingleOrNull();
  }

  // Save or update contact index (upsert)
  Future<int> saveContactIndex(ContactIndexesTableCompanion contactIndex) {
    return into(contactIndexesTable).insertOnConflictUpdate(contactIndex);
  }

  // Batch save contact indexes
  Future<void> saveContactIndexes(List<ContactIndexesTableCompanion> contactIndexList) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(contactIndexesTable, contactIndexList);
    });
  }

  // Update contact index
  Future<bool> updateContactIndex(ContactIndexesTableCompanion contactIndex) {
    return update(contactIndexesTable).replace(contactIndex);
  }

  // Delete contact index
  Future<int> deleteContactIndex(String normalizedPhone) {
    return (delete(contactIndexesTable)..where((t) => t.normalizedPhone.equals(normalizedPhone))).go();
  }

  // Update contact basic info
  Future<int> updateContactInfo({
    required String normalizedPhone,
    String? contactName,
    String? originalPhone,
  }) {
    return (update(contactIndexesTable)..where((t) => t.normalizedPhone.equals(normalizedPhone)))
        .write(ContactIndexesTableCompanion(
      contactName: Value.absentIfNull(contactName),
      originalPhone: Value.absentIfNull(originalPhone),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update registration status
  Future<int> updateRegistrationStatus({
    required String normalizedPhone,
    required bool isRegistered,
    String? registeredUid,
    String? displayName,
    String? profileImageUrl,
  }) {
    return (update(contactIndexesTable)..where((t) => t.normalizedPhone.equals(normalizedPhone)))
        .write(ContactIndexesTableCompanion(
      isRegistered: Value(isRegistered),
      registeredUid: Value.absentIfNull(registeredUid),
      displayName: Value.absentIfNull(displayName),
      profileImageUrl: Value.absentIfNull(profileImageUrl),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update online status
  Future<int> updateOnlineStatus({
    required String normalizedPhone,
    required bool isOnline,
    DateTime? lastSeen,
  }) {
    return (update(contactIndexesTable)..where((t) => t.normalizedPhone.equals(normalizedPhone)))
        .write(ContactIndexesTableCompanion(
      isOnline: Value(isOnline),
      lastSeen: Value.absentIfNull(lastSeen ?? (isOnline ? null : DateTime.now())),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update sync timestamp
  Future<int> updateSyncTimestamp(String normalizedPhone) {
    return (update(contactIndexesTable)..where((t) => t.normalizedPhone.equals(normalizedPhone)))
        .write(ContactIndexesTableCompanion(
      lastSyncAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Get registered contacts
  Future<List<ContactIndexData>> getRegisteredContacts() {
    return (select(contactIndexesTable)
          ..where((t) => t.isRegistered.equals(true))
          ..orderBy([(t) => OrderingTerm(expression: t.displayName, mode: OrderingMode.asc)]))
        .get();
  }

  // Watch registered contacts
  Stream<List<ContactIndexData>> watchRegisteredContacts() {
    return (select(contactIndexesTable)
          ..where((t) => t.isRegistered.equals(true))
          ..orderBy([(t) => OrderingTerm(expression: t.displayName, mode: OrderingMode.asc)]))
        .watch();
  }

  // Get unregistered contacts
  Future<List<ContactIndexData>> getUnregisteredContacts() {
    return (select(contactIndexesTable)
          ..where((t) => t.isRegistered.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.contactName, mode: OrderingMode.asc)]))
        .get();
  }

  // Watch unregistered contacts
  Stream<List<ContactIndexData>> watchUnregisteredContacts() {
    return (select(contactIndexesTable)
          ..where((t) => t.isRegistered.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.contactName, mode: OrderingMode.asc)]))
        .watch();
  }

  // Get online contacts
  Future<List<ContactIndexData>> getOnlineContacts() {
    return (select(contactIndexesTable)
          ..where((t) => t.isOnline.equals(true) & t.isRegistered.equals(true))
          ..orderBy([(t) => OrderingTerm(expression: t.displayName, mode: OrderingMode.asc)]))
        .get();
  }

  // Watch online contacts
  Stream<List<ContactIndexData>> watchOnlineContacts() {
    return (select(contactIndexesTable)
          ..where((t) => t.isOnline.equals(true) & t.isRegistered.equals(true))
          ..orderBy([(t) => OrderingTerm(expression: t.displayName, mode: OrderingMode.asc)]))
        .watch();
  }

  // Search contacts by name
  Future<List<ContactIndexData>> searchContacts(String query) {
    final lowerQuery = query.toLowerCase();
    return (select(contactIndexesTable)
          ..where((t) => t.contactName.lower().contains(lowerQuery) |
              t.displayName.lower().contains(lowerQuery) |
              t.originalPhone.lower().contains(lowerQuery) |
              t.normalizedPhone.lower().contains(lowerQuery))
          ..orderBy([(t) => OrderingTerm(expression: t.contactName, mode: OrderingMode.asc)]))
        .get();
  }

  // Search registered contacts by name
  Future<List<ContactIndexData>> searchRegisteredContacts(String query) {
    final lowerQuery = query.toLowerCase();
    return (select(contactIndexesTable)
          ..where((t) => t.isRegistered.equals(true) & 
                        (t.contactName.lower().contains(lowerQuery) |
                         t.displayName.lower().contains(lowerQuery) |
                         t.originalPhone.lower().contains(lowerQuery)))
          ..orderBy([(t) => OrderingTerm(expression: t.displayName, mode: OrderingMode.asc)]))
        .get();
  }

  // Get contacts by phone numbers
  Future<List<ContactIndexData>> getContactsByPhones(List<String> normalizedPhones) {
    return (select(contactIndexesTable)
          ..where((t) => t.normalizedPhone.isIn(normalizedPhones))
          ..orderBy([(t) => OrderingTerm(expression: t.contactName, mode: OrderingMode.asc)]))
        .get();
  }

  // Get contacts needing sync
  Future<List<ContactIndexData>> getContactsNeedingSync({Duration? threshold}) {
    final thresholdTime = threshold != null 
        ? DateTime.now().subtract(threshold)
        : DateTime.now().subtract(const Duration(hours: 24));
        
    return (select(contactIndexesTable)
          ..where((t) => t.lastSyncAt.isNull() | 
                        t.lastSyncAt.isSmallerThanValue(thresholdTime))
          ..orderBy([(t) => OrderingTerm(expression: t.contactName, mode: OrderingMode.asc)]))
        .get();
  }

  // Get recently synced contacts
  Future<List<ContactIndexData>> getRecentlySyncedContacts({Duration? within}) {
    final sinceTime = within != null 
        ? DateTime.now().subtract(within)
        : DateTime.now().subtract(const Duration(hours: 1));
        
    return (select(contactIndexesTable)
          ..where((t) => t.lastSyncAt.isBiggerOrEqualValue(sinceTime))
          ..orderBy([(t) => OrderingTerm(expression: t.lastSyncAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Get contacts created in date range
  Future<List<ContactIndexData>> getContactsInDateRange(DateTime from, DateTime to) {
    return (select(contactIndexesTable)
          ..where((t) => t.createdAt.isBetweenValues(from, to))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Get contacts with pagination
  Future<List<ContactIndexData>> getContactsPaginated({
    required int limit,
    int? offset,
    bool? registeredOnly,
    String? orderBy = 'contactName',
    bool ascending = true,
  }) {
    var query = select(contactIndexesTable);
    
    // Add filter
    if (registeredOnly != null) {
      query = query..where((t) => t.isRegistered.equals(registeredOnly));
    }
    
    // Add ordering
    switch (orderBy) {
      case 'contactName':
        query = query..orderBy([(t) => OrderingTerm(
          expression: t.contactName, 
          mode: ascending ? OrderingMode.asc : OrderingMode.desc
        )]);
        break;
      case 'displayName':
        query = query..orderBy([(t) => OrderingTerm(
          expression: t.displayName, 
          mode: ascending ? OrderingMode.asc : OrderingMode.desc
        )]);
        break;
      case 'createdAt':
        query = query..orderBy([(t) => OrderingTerm(
          expression: t.createdAt, 
          mode: ascending ? OrderingMode.asc : OrderingMode.desc
        )]);
        break;
      case 'lastSeen':
        query = query..orderBy([(t) => OrderingTerm(
          expression: t.lastSeen, 
          mode: ascending ? OrderingMode.asc : OrderingMode.desc
        )]);
        break;
    }
    
    // Add pagination
    query = query..limit(limit);
    if (offset != null && offset > 0) {
      query = query..limit(limit, offset: offset);
    }
    
    return query.get();
  }

  // Count total contacts
  Future<int> countContacts({bool? registeredOnly}) {
    var query = selectOnly(contactIndexesTable);
    
    if (registeredOnly != null) {
      query = query..where(contactIndexesTable.isRegistered.equals(registeredOnly));
    }
    
    query = query..addColumns([contactIndexesTable.id.count()]);
    return query.map((row) => row.read(contactIndexesTable.id.count()) ?? 0).getSingle();
  }

  // Count registered contacts
  Future<int> countRegisteredContacts() {
    final query = selectOnly(contactIndexesTable)
      ..where(contactIndexesTable.isRegistered.equals(true))
      ..addColumns([contactIndexesTable.id.count()]);
    return query.map((row) => row.read(contactIndexesTable.id.count()) ?? 0).getSingle();
  }

  // Count unregistered contacts
  Future<int> countUnregisteredContacts() {
    final query = selectOnly(contactIndexesTable)
      ..where(contactIndexesTable.isRegistered.equals(false))
      ..addColumns([contactIndexesTable.id.count()]);
    return query.map((row) => row.read(contactIndexesTable.id.count()) ?? 0).getSingle();
  }

  // Count online contacts
  Future<int> countOnlineContacts() {
    final query = selectOnly(contactIndexesTable)
      ..where(contactIndexesTable.isOnline.equals(true) & 
              contactIndexesTable.isRegistered.equals(true))
      ..addColumns([contactIndexesTable.id.count()]);
    return query.map((row) => row.read(contactIndexesTable.id.count()) ?? 0).getSingle();
  }

  // Bulk update online status for multiple contacts
  Future<void> bulkUpdateOnlineStatus(Map<String, bool> phoneStatusMap) async {
    await batch((batch) {
      for (final entry in phoneStatusMap.entries) {
        final normalizedPhone = entry.key;
        final isOnline = entry.value;
        batch.update(
          contactIndexesTable,
          ContactIndexesTableCompanion(
            isOnline: Value(isOnline),
            lastSeen: Value(isOnline ? null : DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ),
          where: (t) => t.normalizedPhone.equals(normalizedPhone),
        );
      }
    });
  }

  // Bulk mark as synced
  Future<void> bulkMarkAsSynced(List<String> normalizedPhones) async {
    final now = DateTime.now();
    await batch((batch) {
      for (final phone in normalizedPhones) {
        batch.update(
          contactIndexesTable,
          ContactIndexesTableCompanion(
            lastSyncAt: Value(now),
            updatedAt: Value(now),
          ),
          where: (t) => t.normalizedPhone.equals(phone),
        );
      }
    });
  }

  // Clear outdated contacts
  Future<int> clearOutdatedContacts({Duration? olderThan}) {
    final thresholdTime = olderThan != null 
        ? DateTime.now().subtract(olderThan)
        : DateTime.now().subtract(const Duration(days: 30));
        
    return (delete(contactIndexesTable)
          ..where((t) => t.updatedAt.isSmallerThanValue(thresholdTime) & 
                        t.isRegistered.equals(false)))
        .go();
  }

  // Clear all contact indexes
  Future<int> clearAll() {
    return delete(contactIndexesTable).go();
  }
}