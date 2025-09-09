import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'dart:async';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_setup_page.dart';
import '../services/user_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _codeSent = false;
  String? _verificationId;
  String? _error;
  // Resend countdown
  Timer? _resendTimer;
  int _resendSeconds = 0; // 0 -> hemen tekrar gönderebilir

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Üst dekoratif alan
            Container(
              height: 220,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00796B), Color(0xFF26A69A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
            ),
            // İçerik kartı
            Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    const Text(
                      'DiyetKent',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Güvenli giriş',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Form(
                          key: _formKey,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: !_codeSent
                                ? Column(
                                    key: const ValueKey('phone'),
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      ..._buildPhoneInput(),
                                      const SizedBox(height: 20),
                                      SizedBox(
                                        height: 52,
                                        child: FilledButton.icon(
                                          onPressed:
                                              _isLoading ? null : _handleSubmit,
                                          style: FilledButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF00796B),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                          ),
                                          icon: _isLoading
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : const Icon(Icons.sms,
                                                  color: Colors.white),
                                          label: Text(
                                            _isLoading
                                                ? 'Gönderiliyor…'
                                                : 'SMS Gönder',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    key: const ValueKey('code'),
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      ..._buildCodeInput(),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: _isLoading
                                                  ? null
                                                  : _handleSubmit,
                                              style: OutlinedButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 14),
                                                side: const BorderSide(
                                                    color: Color(0xFF00796B)),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                ),
                                              ),
                                              icon: _isLoading
                                                  ? const SizedBox(
                                                      width: 16,
                                                      height: 16,
                                                      child:
                                                          CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color:
                                                            Color(0xFF00796B),
                                                      ),
                                                    )
                                                  : const Icon(Icons.verified,
                                                      color: Color(0xFF00796B)),
                                              label: Text(
                                                _isLoading
                                                    ? 'Doğrulanıyor…'
                                                    : 'Doğrula',
                                                style: const TextStyle(
                                                    color: Color(0xFF00796B),
                                                    fontSize: 16),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          TextButton(
                                            onPressed: (_resendSeconds == 0 &&
                                                    !_isLoading)
                                                ? _resendCode
                                                : null,
                                            child: Text(
                                              _resendSeconds == 0
                                                  ? 'Tekrar Gönder'
                                                  : 'Tekrar Gönder (00:${_resendSeconds.toString().padLeft(2, '0')})',
                                              style: TextStyle(
                                                color: (_resendSeconds == 0 &&
                                                        !_isLoading)
                                                    ? const Color(0xFF00796B)
                                                    : Colors.grey,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Text(
                          _error!,
                          style:
                              TextStyle(color: Colors.red[800], fontSize: 14),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    const Text(
                      'Devam ederek Kullanım Şartları\'nı ve Gizlilik Politikası\'nı kabul etmiş olursunuz.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPhoneInput() {
    return [
      const Text(
        'Telefon numaranızı girin',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        'Size SMS ile doğrulama kodu göndereceğiz',
        style: TextStyle(fontSize: 14, color: Colors.grey),
      ),
      const SizedBox(height: 24),
      IntlPhoneField(
        decoration: const InputDecoration(
          labelText: 'Telefon Numarası',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Color(0xFF00796B), width: 2),
          ),
        ),
        initialCountryCode: 'TR',
        searchText: 'Ülke ara',
        autovalidateMode: AutovalidateMode.onUserInteraction,
        disableLengthCheck: true,
        onChanged: (phone) {
          // Tüm ülke kodlarını destekler, E.164 formatını saklarız
          _phoneController.text = phone.completeNumber; // +905xx... gibi
        },
        onCountryChanged: (c) {},
        validator: (value) {
          if (value == null || value.completeNumber.isEmpty) {
            return 'Telefon numarası gerekli';
          }
          final digits = value.completeNumber.replaceAll(RegExp(r'\D'), '');
          if (digits.length < 8) {
            return 'Lütfen geçerli bir telefon numarası girin';
          }
          return null;
        },
      ),
    ];
  }

  List<Widget> _buildCodeInput() {
    return [
      const Text(
        'Doğrulama kodunu girin',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        '${_phoneController.text} numarasına gönderilen 6 haneli kodu girin',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14, color: Colors.grey),
      ),
      const SizedBox(height: 24),
      PinCodeTextField(
        appContext: context,
        length: 6,
        controller: _codeController,
        animationType: AnimationType.fade,
        keyboardType: TextInputType.number,
        enableActiveFill: true,
        cursorColor: const Color(0xFF00796B),
        pinTheme: PinTheme(
          shape: PinCodeFieldShape.box,
          borderRadius: BorderRadius.circular(10),
          fieldHeight: 50,
          fieldWidth: 44,
          inactiveColor: Colors.grey,
          activeColor: const Color(0xFF00796B),
          selectedColor: const Color(0xFF26A69A),
          activeFillColor: Colors.grey.shade100,
          selectedFillColor: Colors.white,
          inactiveFillColor: Colors.white,
        ),
        animationDuration: const Duration(milliseconds: 200),
        onChanged: (_) {},
        validator: (v) {
          if (v == null || v.length != 6) return '6 haneli kod gerekli';
          return null;
        },
        onCompleted: (_) async {
          if (!_isLoading) await _handleSubmit();
        },
      ),
    ];
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      if (!_codeSent) {
        await _sendVerificationCode();
      } else {
        await _verifyCode();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendVerificationCode() async {
    final phoneNumber = _phoneController.text.startsWith('+')
        ? _phoneController.text
        : '+${_phoneController.text}';

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Otomatik doğrulama (Android'de)
        await _signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        if (mounted) {
          setState(() {
            _error = 'Doğrulama başarısız: ${e.message}';
          });
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        if (mounted) {
          setState(() {
            _verificationId = verificationId;
            _codeSent = true;
            _startResendCountdown();
          });
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<void> _verifyCode() async {
    if (_verificationId == null) return;

    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: _codeController.text,
    );

    await _signInWithCredential(credential);
  }

  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    final userCredential = await FirebaseAuth.instance.signInWithCredential(
      credential,
    );
    final user = userCredential.user;

    if (user != null) {
      // FCM token kaydı NotificationService.initialize ile yapılır

      // Kullanıcı bilgilerini kontrol et
      await UserService.ensureLocalUser(user.uid);
      final local = await UserService.getLocalUser(user.uid);

      if (mounted) {
        // Profil setup sayfasına yönlendir (her durumda)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileSetupPage(
              userId: user.uid,
              phoneNumber: user.phoneNumber ?? '',
              existingData: local?.toMap(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _resendCode() async {
    if (mounted) {
      setState(() {
        _error = null;
      });
    }
    // Yeniden SMS gönder ve sayacı tekrar başlat
    await _sendVerificationCode();
  }

  void _startResendCountdown({int seconds = 60}) {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = seconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_resendSeconds <= 1) {
        t.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds -= 1);
      }
    });
  }
}
