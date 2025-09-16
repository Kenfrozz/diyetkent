import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'pages/auth_wrapper.dart';
import 'pages/tags_page_new.dart';
import 'pages/settings_page.dart';
import 'pages/backup_page.dart';
import 'pages/chat_page.dart';
import 'pages/archived_chats_page.dart';
import 'pages/story_viewer_page.dart';
import 'models/story_model.dart';
import 'providers/optimized_chat_provider.dart';
import 'providers/tag_provider.dart';
import 'providers/story_provider.dart';
import 'providers/group_provider.dart';
// Removed pre_consultation_form_provider (dietitian panel removed)
import 'database/drift_service.dart';
import 'services/user_service.dart';
import 'services/firebase_usage_tracker.dart';
import 'services/media_cache_manager.dart';
import 'services/contacts_manager.dart';
import 'services/step_counter_service.dart';
import 'services/firebase_background_sync_service.dart';
import 'services/connection_aware_sync_service.dart';
import 'services/auto_backup_service.dart';
import 'models/chat_model.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

// Background message handler - global fonksiyon olmalı
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase'i initialize et
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } on FirebaseException catch (e) {
      if (e.code != 'duplicate-app') rethrow;
    }

  }

  debugPrint('📱 Background message alındı: ${message.messageId}');
  debugPrint('📋 Background message data: ${message.data}');

  // Background'da gelen mesajları işle
  // Burada yerel bildirim gösterebilir veya veri işleme yapabilirsiniz
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };

  try {
    // Firebase'i başlat; duplicate-app durumunu görmezden gel
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } on FirebaseException catch (e) {
      if (e.code == 'duplicate-app') {
        // Mevcut default app'i kullan
        Firebase.app();
      } else {
        rethrow;
      }
    }

    // Intl yerel tarih/saat formatları (günlük ayraç için gerekli)
    try {
      await initializeDateFormatting('tr_TR', null);
      Intl.defaultLocale = 'tr_TR';
    } catch (e) {
      debugPrint('⚠️ Intl yerel veri başlatma hatası: $e');
    }

    // 🔥 MALIYET OPTIMIZASYONU: Firestore settings optimize et
    try {
      if (!kIsWeb) {
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
          // Cache size maximum 100MB (104857600 bytes) 
          cacheSizeBytes: 100 * 1024 * 1024, // 100MB
        );
        debugPrint('✅ Firestore cache ayarları optimize edildi (100MB)');
      }
    } catch (e) {
      debugPrint('⚠️ Firestore ayarlama hatası: $e');
    }

    // App Check'i bloklamadan arka planda başlat (sadece debug'da etkin)
    unawaited(() async {
      try {
        if (kDebugMode && !kIsWeb) {
          await FirebaseAppCheck.instance.activate(
            androidProvider: AndroidProvider.debug,
            appleProvider: AppleProvider.debug,
          );
          debugPrint('✅ Firebase App Check (debug) aktivated');
        } else {
          // Üretimde Play Integrity/App Attest kurulu değilse 403 hatasını engellemek için şimdilik devre dışı
          debugPrint('ℹ️ App Check üretimde devre dışı (yapılandırılmadı)');
        }
      } catch (e) {
        debugPrint('⚠️ Firebase App Check activation failed: $e');
      }
    }());

    // Background message handler'ı kaydet
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 🔥 MALIYET OPTIMIZASYONU: Bu işlemleri arka planda başlat
    unawaited(FirebaseUsageTracker.initialize());
    unawaited(MediaCacheManager.performAutoCleanup());

    // Initialize Drift database
    await DriftService.initialize();
    debugPrint('✅ Drift database initialized successfully!');

    // 🚀 Merkezi rehber yöneticisini başlat (arkaplanda çalışır)
    unawaited(ContactsManager.initialize());

    // 📱 Adım sayar servisini başlat (arkaplanda çalışır)
    unawaited(StepCounterService.initialize());

    // 🔄 PERFORMANS OPTİMİZASYONU: Firebase Background Sync Service başlat
    // Bu servis UI'dan Firebase bağımlılığını kaldırır ve maliyeti %70 azaltır
    unawaited(FirebaseBackgroundSyncService.initialize());

    // 🌐 CONNECTION-AWARE SYNC: Akıllı bağlantı yönetimi
    // Veri kullanımını optimize eder, battery tasarrufu sağlar
    unawaited(ConnectionAwareSyncService.initialize());

    // ☁️ AUTO BACKUP SERVICE: Otomatik Google Drive yedekleme
    // Her gece saat 03:00'da WiFi varsa otomatik yedek alır
    // unawaited(AutoBackupService.initialize()); // Temporarily disabled

    runApp(const MyApp());
  } catch (e, st) {
    // Başlangıçta bir hata olursa siyah ekran yerine anlamlı bir ekran göster
    // ve hatayı console'a yaz.
    // ignore: avoid_print
    debugPrint('❌ Startup error: $e');
    debugPrint(st.toString());
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF00796B)),
                  const SizedBox(height: 16),
                  const Text(
                    'Uygulama başlatılırken bir hata oluştu. Lütfen tekrar deneyin.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    e.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    UserService.setUserOnline(); // Uygulama açıldığında online yap
    UserService.startOnlineStatusUpdater();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    UserService.setUserOffline(); // Uygulama kapandığında offline yap
    UserService.stopOnlineStatusUpdater();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        UserService.setUserOnline(); // Uygulama aktif olduğunda online
        // 🔄 App foreground'a geldiğinde hızlı sync
        FirebaseBackgroundSyncService.onAppResumed();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        UserService.setUserOffline(); // Uygulama pasif olduğunda offline
        // 🔄 App background'a gittiğinde sync interval'ını artır
        FirebaseBackgroundSyncService.onAppPaused();
        break;
      case AppLifecycleState.detached:
        UserService.setUserOffline();
        FirebaseBackgroundSyncService.dispose(); // Cleanup
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => OptimizedChatProvider()), // 🔥 OPTIMIZE EDİLMİŞ
        ChangeNotifierProvider(create: (_) => TagProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => StoryProvider()),
        ChangeNotifierProvider(create: (_) => GroupProvider()),
      ],
      child: MaterialApp(
        title: 'DiyetKent',
        theme: ThemeData(
          primarySwatch: Colors.teal,
          primaryColor: const Color(0xFF00796B), // WhatsApp yeşili
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF00796B),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          tabBarTheme: const TabBarThemeData(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
          ),
        ),
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
        // Route sistem ekle
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/chat':
              final chat = settings.arguments as ChatModel;
              return MaterialPageRoute(
                builder: (context) => ChatPage(chat: chat),
              );
            case '/tags':
              return MaterialPageRoute(
                builder: (context) => const TagsPageNew(),
              );
            case '/archived':
              return MaterialPageRoute(
                builder: (context) => const ArchivedChatsPage(),
              );
            case '/settings':
              return MaterialPageRoute(
                builder: (context) => const SettingsPage(),
              );
            case '/backup':
              return MaterialPageRoute(
                builder: (context) => const BackupPage(),
              );
            case '/story-viewer':
              final args = settings.arguments as Map<String, dynamic>;
              final stories = args['stories'] as List<StoryModel>;
              final initialIndex = args['initialIndex'] as int? ?? 0;
              return MaterialPageRoute(
                builder: (context) => StoryViewerPage(
                  stories: stories,
                  initialIndex: initialIndex,
                ),
              );
            default:
              return null;
          }
        },
      ),
    );
  }
}
