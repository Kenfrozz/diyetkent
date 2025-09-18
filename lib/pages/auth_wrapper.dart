import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Firestore doğrudan kullanılmıyor; UI Isar'dan besleniyor
import 'login_page.dart';
import 'home_page.dart';
import 'profile_setup_page.dart';
import 'terms_welcome_page.dart';
import '../services/user_service.dart';
import '../database/drift_service.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Önce hizmet koşullarının kabul edilip edilmediğini kontrol et
    return FutureBuilder<bool>(
      future: _checkTermsAccepted(),
      builder: (context, termsSnapshot) {
        if (termsSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF00796B)),
            ),
          );
        }

        // Hizmet koşulları kabul edilmemişse
        if (termsSnapshot.data != true) {
          return const TermsWelcomePage();
        }

        // Hizmet koşulları kabul edilmiş, normal auth akışına devam
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            // Loading durumu
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: Color(0xFF00796B)),
                ),
              );
            }

            // Kullanıcı giriş yapmamış
            if (!snapshot.hasData || snapshot.data == null) {
              return const LoginPage();
            }

        // Kullanıcı giriş yapmış, önce yerel (Isar) kontrol et, yoksa senkronize et
        final user = snapshot.data!;
        return FutureBuilder<bool>(
          future: _ensureUserDataAndRole(user.uid),
          builder: (context, ensureSnapshot) {
            if (ensureSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: Color(0xFF00796B)),
                ),
              );
            }

            return FutureBuilder(
              future: DriftService.getUserByUserId(user.uid),
              builder: (context, localUserSnap) {
                if (localUserSnap.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF00796B)),
                    ),
                  );
                }

                final localUser = localUserSnap.data;
                if (localUser == null ||
                    !_isProfileComplete({
                      'name': localUser.name,
                      'about': localUser.about,
                    })) {
                  return ProfileSetupPage(
                    userId: user.uid,
                    phoneNumber: user.phoneNumber ?? '',
                    existingData: localUser?.toMap(),
                  );
                }
                return const HomePage();
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  bool _isProfileComplete(Map<String, dynamic>? userData) {
    if (userData == null) return false;

    final name = userData['name'] as String?;
    final about = userData['about'] as String?;

    return name != null &&
        name.trim().isNotEmpty &&
        about != null &&
        about.trim().isNotEmpty;
  }

  // Hizmet koşullarının kabul edilip edilmediğini kontrol et
  Future<bool> _checkTermsAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('terms_accepted') ?? false;
  }

  // Kullanıcı verilerini ve rollerini senkronize et
  Future<bool> _ensureUserDataAndRole(String userId) async {
    try {
      // Önce kullanıcı verilerini kontrol et
      await UserService.ensureLocalUser(userId);

      // Sonra rolünü kontrol et ve gerekirse oluştur
      await UserService.ensureCurrentUserRole();

      return true;
    } catch (e) {
      debugPrint('❌ Kullanıcı veri/rol senkronizasyonu başarısız: $e');
      return false;
    }
  }
}
