import 'package:firebase_auth/firebase_auth.dart';
import '../database/drift_service.dart';
import '../models/user_model.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Mevcut kullanıcıyı getir
  static User? get currentUser => _auth.currentUser;

  // Mevcut kullanıcının ID'sini getir
  static String? get currentUserId => _auth.currentUser?.uid;

  // Kullanıcı durumunu dinle
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Kullanıcı giriş yapmış mı kontrolü
  static bool get isSignedIn => _auth.currentUser != null;

  // Kullanıcı telefon numarası doğrulaması
  static Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
  }

  // SMS kodu ile giriş
  static Future<UserCredential> signInWithCredential(
    PhoneAuthCredential credential,
  ) async {
    return await _auth.signInWithCredential(credential);
  }

  // Kullanıcı bilgilerini Isar'a kaydet
  static Future<void> saveUserToIsar({
    required String userId,
    required String name,
    required String about,
    required String phoneNumber,
    String? profileImageUrl,
  }) async {
    final user = UserModel.create(
      userId: userId,
      name: name,
      about: about,
      phoneNumber: phoneNumber,
      profileImageUrl: profileImageUrl,
      isOnline: true,
      lastSeen: DateTime.now(),
    );
    
    await DriftService.saveUser(user);
  }

  // Kullanıcı bilgilerini Isar'dan getir
  static Future<UserModel?> getUserFromIsar(
    String userId,
  ) async {
    return await DriftService.getUserById(userId);
  }

  // Kullanıcı online durumunu güncelle
  static Future<void> updateOnlineStatus(bool isOnline) async {
    final user = _auth.currentUser;
    if (user != null) {
      final existingUser = await DriftService.getUserById(user.uid);
      if (existingUser != null) {
        existingUser.isOnline = isOnline;
        existingUser.lastSeen = DateTime.now();
        existingUser.updatedAt = DateTime.now();
        await DriftService.updateUser(existingUser);
      }
    }
  }

  // Çıkış yap
  static Future<void> signOut() async {
    await updateOnlineStatus(false);
    try {
      await DriftService.clearAll();
    } catch (_) {}
    await _auth.signOut();
  }

  // Kullanıcı profil bilgilerini güncelle
  static Future<void> updateUserProfile({
    required String name,
    required String about,
    String? profileImageUrl,
  }) async {
    final user = _auth.currentUser;
    if (user != null) {
      final existingUser = await DriftService.getUserById(user.uid);
      if (existingUser != null) {
        existingUser.name = name;
        existingUser.about = about;
        existingUser.updatedAt = DateTime.now();
        
        if (profileImageUrl != null) {
          existingUser.profileImageUrl = profileImageUrl;
        }
        
        await DriftService.updateUser(existingUser);
      }
    }
  }

  // Telefon numarası formatla
  static String formatPhoneNumber(String phoneNumber) {
    // +90 ile başlıyorsa sadece onu döndür
    if (phoneNumber.startsWith('+90')) {
      return phoneNumber;
    }

    // 90 ile başlıyorsa + ekle
    if (phoneNumber.startsWith('90')) {
      return '+$phoneNumber';
    }

    // Sadece 10 haneli numara ise +90 ekle
    if (phoneNumber.length == 10) {
      return '+90$phoneNumber';
    }

    return phoneNumber;
  }

}
