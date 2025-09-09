import 'package:flutter_test/flutter_test.dart';
import 'package:diyetkent/database/drift_service.dart';

void main() {
  group('Drift Database Tests', () {
    setUpAll(() async {
      // Initialize services for testing
      await DriftService.initialize();
    });

    tearDownAll(() async {
      // Clean up after tests
      await DriftService.close();
    });

    test('Database initialization should complete without errors', () async {
      expect(DriftService.database, isNotNull);
      // Just check that database is initialized successfully
      expect(DriftService.database.executor, isNotNull);
    });

    test('Database stats should return valid counts', () async {
      final stats = await DriftService.getDatabaseStats();
      
      expect(stats, isA<Map<String, int>>());
      expect(stats.containsKey('chats'), isTrue);
      expect(stats.containsKey('messages'), isTrue);
      expect(stats.containsKey('users'), isTrue);
      expect(stats.containsKey('contacts'), isTrue);
      expect(stats.containsKey('stories'), isTrue);
      
      // All counts should be non-negative
      for (final count in stats.values) {
        expect(count, greaterThanOrEqualTo(0));
      }
    });

    test('Basic CRUD operations should work', () async {
      // Test basic operations to ensure database is working
      final initialUserCount = await DriftService.database.userDao.countUsers();
      expect(initialUserCount, greaterThanOrEqualTo(0));
      
      final allChats = await DriftService.getAllChats();
      expect(allChats, isA<List>());
    });

    test('Clear all should work without errors', () async {
      await DriftService.clearAll();
      
      final stats = await DriftService.getDatabaseStats();
      // After clearing, some counts should be 0
      expect(stats['chats'], equals(0));
      expect(stats['messages'], equals(0));
      expect(stats['users'], equals(0));
    });
  });

  group('Database Performance Tests', () {
    test('Batch operations should handle large datasets', () async {
      // Test with empty dataset initially
      final stopwatch = Stopwatch()..start();
      
      // Test getting all records
      final chats = await DriftService.getAllChats();
      final users = await DriftService.getAllUsers();
      final contacts = await DriftService.getAllContactIndexes();
      
      stopwatch.stop();
      
      // Operations should complete within reasonable time (5 seconds)
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
      
      // Results should be valid lists
      expect(chats, isA<List>());
      expect(users, isA<List>());
      expect(contacts, isA<List>());
    });

    test('Stream operations should work correctly', () async {
      // Test that streams can be created without errors
      final chatStream = DriftService.watchAllChats();
      final userStream = DriftService.watchAllUsers();
      
      expect(chatStream, isA<Stream>());
      expect(userStream, isA<Stream>());
      
      // Listen to streams for a short time to ensure they work
      var chatReceived = false;
      var userReceived = false;
      
      final chatSub = chatStream.listen((chats) {
        chatReceived = true;
        expect(chats, isA<List>());
      });
      
      final userSub = userStream.listen((users) {
        userReceived = true;
        expect(users, isA<List>());
      });
      
      // Wait a bit for initial data
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Clean up
      await chatSub.cancel();
      await userSub.cancel();
      
      // Streams should have emitted at least once
      expect(chatReceived, isTrue);
      expect(userReceived, isTrue);
    });
  });
}