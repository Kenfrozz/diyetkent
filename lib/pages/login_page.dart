import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'dart:async';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_setup_page.dart';
import '../services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // E.164 format doğrulama için yeni değişkenler
  String _completePhoneNumber = '';
  PhoneNumber? _validatedPhoneNumber;
  bool _isPhoneNumberValid = false;

  // SMS durumu takibi için yeni değişkenler
  bool _isSendingSms = false;
  String? _smsStatus;

  // Gelişmiş hata yönetimi için yeni değişkenler
  int _retryAttempts = 0;
  static const int maxRetryAttempts = 3;

  @override
  void initState() {
    super.initState();
    _loadSavedPhoneNumber();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  /// Kayıtlı telefon numarasını SharedPreferences'tan yükle
  Future<void> _loadSavedPhoneNumber() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPhone = prefs.getString('last_phone_number');
      if (savedPhone != null && savedPhone.isNotEmpty) {
        setState(() {
          _completePhoneNumber = savedPhone;
          _phoneController.text = savedPhone;
          _validatePhoneNumber(savedPhone);
        });
      }
    } catch (e) {
      debugPrint('❌ Telefon numarası yükleme hatası: $e');
    }
  }

  /// Telefon numarasını SharedPreferences'a kaydet
  Future<void> _savePhoneNumber(String phoneNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_phone_number', phoneNumber);
      debugPrint('✅ Telefon numarası kaydedildi: $phoneNumber');
    } catch (e) {
      debugPrint('❌ Telefon numarası kaydetme hatası: $e');
    }
  }

  /// E.164 format doğrulama fonksiyonu
  void _validatePhoneNumber(String phoneNumber) {
    try {
      if (phoneNumber.isEmpty) {
        setState(() {
          _isPhoneNumberValid = false;
          _validatedPhoneNumber = null;
        });
        return;
      }

      // E.164 formatını kontrol et
      final phone = PhoneNumber.parse(phoneNumber);
      setState(() {
        _validatedPhoneNumber = phone;
        _isPhoneNumberValid = phone.isValid();
      });

      if (_isPhoneNumberValid) {
        // Geçerli numara ise kaydet
        _savePhoneNumber(phone.international);
      }
    } catch (e) {
      setState(() {
        _isPhoneNumberValid = false;
        _validatedPhoneNumber = null;
      });
    }
  }

  /// SnackBar ile hata mesajı göster
  void _showSnackBarError(String message, {bool withRetry = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        duration: const Duration(seconds: 4),
        action: withRetry && _retryAttempts < maxRetryAttempts
            ? SnackBarAction(
                label: 'Tekrar Dene',
                textColor: Colors.white,
                onPressed: _retryLastAction,
              )
            : null,
      ),
    );
  }

  /// AlertDialog ile kritik hata mesajı göster
  void _showCriticalErrorDialog(String title, String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tamam'),
            ),
            if (_retryAttempts < maxRetryAttempts)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _retryLastAction();
                },
                child: const Text('Tekrar Dene'),
              ),
          ],
        );
      },
    );
  }

  /// Son işlemi tekrar dene (retry mekanizması)
  void _retryLastAction() {
    if (_retryAttempts >= maxRetryAttempts) {
      _showCriticalErrorDialog(
        'Çok Fazla Deneme',
        'Maksimum deneme sayısına ulaştınız. Lütfen daha sonra tekrar deneyin.',
      );
      return;
    }

    _retryAttempts++;
    setState(() {
      _error = null;
      _smsStatus = null;
    });

    if (!_codeSent) {
      _handleSubmit(); // Tekrar SMS gönder
    } else {
      _resendCode(); // Kodu tekrar gönder
    }
  }

  /// SnackBar ile başarı mesajı göster
  void _showSnackBarSuccess(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[600],
        duration: const Duration(seconds: 3),
      ),
    );
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
            // İçerik kartı - Responsive tasarım
            Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width > 600 ? 40 : 20,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width > 600 ? 400 : double.infinity,
                  ),
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
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          child: FilledButton.icon(
                                            onPressed: (_isLoading || _isSendingSms || !_isPhoneNumberValid)
                                                ? null
                                                : _handleSubmit,
                                            style: FilledButton.styleFrom(
                                              backgroundColor: _isPhoneNumberValid
                                                  ? const Color(0xFF00796B)
                                                  : Colors.grey[400],
                                              disabledBackgroundColor: Colors.grey[300],
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(14),
                                              ),
                                              elevation: _isPhoneNumberValid ? 2 : 0,
                                            ),
                                            icon: (_isLoading || _isSendingSms)
                                                ? const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                                  )
                                                : Icon(
                                                    Icons.sms,
                                                    color: (_isLoading || _isSendingSms || !_isPhoneNumberValid)
                                                        ? Colors.grey[600]
                                                        : Colors.white,
                                                  ),
                                            label: Text(
                                              (_isLoading || _isSendingSms)
                                                  ? 'Gönderiliyor…'
                                                  : 'SMS Gönder',
                                              style: TextStyle(
                                                color: (_isLoading || _isSendingSms || !_isPhoneNumberValid)
                                                    ? Colors.grey[600]
                                                    : Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
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
                                            child: FilledButton.icon(
                                              onPressed: _isLoading
                                                  ? null
                                                  : _handleSubmit,
                                              style: FilledButton.styleFrom(
                                                backgroundColor: const Color(0xFF00796B),
                                                padding: const EdgeInsets.symmetric(vertical: 14),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(14),
                                                ),
                                                elevation: 2,
                                              ),
                                              icon: _isLoading
                                                  ? const SizedBox(
                                                      width: 16,
                                                      height: 16,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white,
                                                      ),
                                                    )
                                                  : const Icon(
                                                      Icons.verified,
                                                      color: Colors.white,
                                                    ),
                                              label: Text(
                                                _isLoading
                                                    ? 'Doğrulanıyor…'
                                                    : 'Doğrula',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          TextButton.icon(
                                            onPressed: (_resendSeconds == 0 && !_isLoading)
                                                ? _resendCode
                                                : null,
                                            style: TextButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 14,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(14),
                                              ),
                                            ),
                                            icon: Icon(
                                              Icons.refresh,
                                              size: 16,
                                              color: (_resendSeconds == 0 && !_isLoading)
                                                  ? const Color(0xFF00796B)
                                                  : Colors.grey,
                                            ),
                                            label: Text(
                                              _resendSeconds == 0
                                                  ? 'Tekrar Gönder'
                                                  : 'Tekrar (${_resendSeconds.toString().padLeft(2, '0')}s)',
                                              style: TextStyle(
                                                color: (_resendSeconds == 0 && !_isLoading)
                                                    ? const Color(0xFF00796B)
                                                    : Colors.grey,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
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
                    // SMS durum mesajı gösterimi
                    if (_smsStatus != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          children: [
                            if (_isSendingSms) ...[
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF4CAF50),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ] else
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFF4CAF50),
                                size: 16,
                              ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _smsStatus!,
                                style: TextStyle(
                                  color: Colors.green[800],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
        decoration: InputDecoration(
          labelText: 'Telefon Numarası',
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(
              color: _isPhoneNumberValid
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFF00796B),
              width: 2
            ),
          ),
          errorBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
          suffixIcon: _completePhoneNumber.isNotEmpty
              ? Icon(
                  _isPhoneNumberValid ? Icons.check_circle : Icons.error,
                  color: _isPhoneNumberValid
                      ? const Color(0xFF4CAF50)
                      : Colors.red,
                )
              : null,
          helperText: _isPhoneNumberValid && _validatedPhoneNumber != null
              ? 'Geçerli numara: ${_validatedPhoneNumber!.international}'
              : null,
          helperStyle: const TextStyle(color: Color(0xFF4CAF50), fontSize: 12),
        ),
        initialCountryCode: 'TR',
        pickerDialogStyle: PickerDialogStyle(
          searchFieldInputDecoration: const InputDecoration(
            labelText: 'Ülke ara',
            border: OutlineInputBorder(),
          ),
        ),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        disableLengthCheck: false, // Uzunluk kontrolünü aktif et
        showDropdownIcon: true,
        dropdownDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        flagsButtonMargin: const EdgeInsets.symmetric(horizontal: 8),
        showCountryFlag: true,
        showCursor: true,
        cursorColor: const Color(0xFF00796B),
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.done,
        onChanged: (phone) {
          final completeNumber = phone.completeNumber;
          setState(() {
            _completePhoneNumber = completeNumber;
            _phoneController.text = completeNumber;
          });

          // Gerçek zamanlı E.164 doğrulama
          _validatePhoneNumber(completeNumber);
        },
        onCountryChanged: (country) {
          // Ülke değiştiğinde mevcut numara varsa tekrar doğrula
          if (_completePhoneNumber.isNotEmpty) {
            _validatePhoneNumber(_completePhoneNumber);
          }
        },
        validator: (value) {
          if (value == null || value.completeNumber.isEmpty) {
            return 'Telefon numarası gerekli';
          }

          // phone_numbers_parser ile detaylı doğrulama
          try {
            final phone = PhoneNumber.parse(value.completeNumber);
            if (!phone.isValid()) {
              return 'Geçersiz telefon numarası formatı';
            }
            return null;
          } catch (e) {
            return 'Lütfen geçerli bir telefon numarası girin';
          }
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
    setState(() {
      _isSendingSms = true;
      _smsStatus = 'SMS gönderiliyor...';
      _error = null;
    });

    try {
      // E.164 formatında doğrulanmış telefon numarasını kullan
      String phoneNumber;
      if (_validatedPhoneNumber != null && _isPhoneNumberValid) {
        phoneNumber = _validatedPhoneNumber!.international;
      } else {
        // Fallback - mevcut implementasyon
        phoneNumber = _phoneController.text.startsWith('+')
            ? _phoneController.text
            : '+${_phoneController.text}';
      }

      debugPrint('🔥 SMS gönderiliyor: $phoneNumber');

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint('✅ Otomatik doğrulama tamamlandı');
          setState(() {
            _smsStatus = 'Otomatik doğrulama başarılı';
            _isSendingSms = false;
          });
          await _signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('❌ SMS doğrulama başarısız: ${e.code} - ${e.message}');
          if (mounted) {
            setState(() {
              _isSendingSms = false;
              _smsStatus = null;
            });

            final errorMessage = _getLocalizedErrorMessage(e.code, e.message);

            // Kritik hatalar için AlertDialog kullan
            if (e.code == 'quota-exceeded' ||
                e.code == 'app-not-authorized' ||
                e.code == 'captcha-check-failed') {
              _showCriticalErrorDialog('SMS Doğrulama Hatası', errorMessage);
            } else {
              // Diğer hatalar için SnackBar kullan (retry seçeneği ile)
              _showSnackBarError(errorMessage, withRetry: true);
            }
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('✅ SMS başarıyla gönderildi. Verification ID: $verificationId');
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
              _codeSent = true;
              _isSendingSms = false;
              _smsStatus = 'SMS başarıyla gönderildi';
              _retryAttempts = 0; // Başarılı olduğu için retry sayısını sıfırla
              _startResendCountdown();
            });

            // Başarı mesajı göster
            _showSnackBarSuccess('SMS doğrulama kodu gönderildi!');
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('⏱️ SMS otomatik alma süresi doldu');
          _verificationId = verificationId;
          if (mounted) {
            setState(() {
              _isSendingSms = false;
              _smsStatus = null;
            });
          }
        },
        timeout: const Duration(seconds: 60), // 60 saniye timeout
      );
    } catch (e) {
      debugPrint('❌ SMS gönderim hatası: $e');
      if (mounted) {
        setState(() {
          _isSendingSms = false;
          _smsStatus = null;
        });

        // Ağ bağlantısı hataları için farklı mesaj
        final errorMessage = e.toString().toLowerCase().contains('network') ||
                e.toString().toLowerCase().contains('internet')
            ? 'İnternet bağlantısı sorunu. Lütfen bağlantınızı kontrol edin.'
            : 'SMS gönderilemedi. Lütfen daha sonra tekrar deneyin.';

        _showSnackBarError(errorMessage, withRetry: true);
      }
    }
  }

  /// Firebase Auth hata kodlarını Türkçe mesajlara çevir
  String _getLocalizedErrorMessage(String? errorCode, String? originalMessage) {
    switch (errorCode) {
      case 'invalid-phone-number':
        return 'Geçersiz telefon numarası formatı';
      case 'too-many-requests':
        return 'Çok fazla istek gönderdiniz. Lütfen daha sonra tekrar deneyin.';
      case 'quota-exceeded':
        return 'SMS kotası aşıldı. Lütfen daha sonra tekrar deneyin.';
      case 'captcha-check-failed':
        return 'Güvenlik doğrulaması başarısız. Uygulamayı yeniden başlatın.';
      case 'missing-phone-number':
        return 'Telefon numarası eksik';
      case 'app-not-authorized':
        return 'Uygulama yetkilendirilmemiş';
      case 'network-request-failed':
        return 'Ağ bağlantısı sorunu. İnternet bağlantınızı kontrol edin.';
      default:
        return originalMessage ?? 'Bilinmeyen bir hata oluştu';
    }
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
    try {
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final user = userCredential.user;

      if (user != null) {
        // Başarı mesajı göster
        _showSnackBarSuccess('Telefon numarası başarıyla doğrulandı!');

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
    } catch (e) {
      debugPrint('❌ Giriş hatası: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (e is FirebaseAuthException) {
          final errorMessage = _getLocalizedErrorMessage(e.code, e.message);
          _showSnackBarError(errorMessage, withRetry: false);
        } else {
          _showSnackBarError('Giriş yapılırken bir hata oluştu.', withRetry: false);
        }
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
