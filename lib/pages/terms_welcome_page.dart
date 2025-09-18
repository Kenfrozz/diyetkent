import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'auth_wrapper.dart';

class TermsWelcomePage extends StatefulWidget {
  const TermsWelcomePage({super.key});

  @override
  State<TermsWelcomePage> createState() => _TermsWelcomePageState();
}

class _TermsWelcomePageState extends State<TermsWelcomePage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isAcceptButtonEnabled = false;

  // DiyetKent marka renkleri
  static const Color primaryColor = Color(0xFF00796B);
  static const Color secondaryColor = Color(0xFF26A69A);
  static const Color accentColor = Color(0xFF80CBC4);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();

    // Kullanıcının sayfada biraz kalmasını sağlamak için buton gecikmesi
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isAcceptButtonEnabled = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _launchTermsUrl() async {
    final Uri url = Uri.parse('https://diyetkent.com/hizmet-kosullari');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hizmet koşulları sayfası açılamadı'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _launchPrivacyUrl() async {
    final Uri url = Uri.parse('https://diyetkent.com/gizlilik-politikasi');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gizlilik politikası sayfası açılamadı'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _acceptTermsAndContinue() async {
    // SharedPreferences'a onay durumunu kaydet
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('terms_accepted', true);
    await prefs.setString('terms_accepted_date', DateTime.now().toIso8601String());

    // Auth Wrapper'a geri dön - artık login'i gösterecek
    if (mounted) {
      // Ana auth akışını yeniden başlat
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const AuthWrapper(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;

    // Geri tuşu ile çıkışı engelle
    return PopScope(
      canPop: false,
      child: Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.08,
                vertical: isSmallScreen ? 16 : 24,
              ),
              child: Column(
                children: [
                  // Logo ve başlık bölümü
                  Expanded(
                    flex: isSmallScreen ? 2 : 3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo placeholder (gerçek logo eklenebilir)
                        Container(
                          width: isSmallScreen ? 100 : 120,
                          height: isSmallScreen ? 100 : 120,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [primaryColor, secondaryColor],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.restaurant_menu,
                            color: Colors.white,
                            size: 60,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 20 : 30),
                        Text(
                          'DiyetKent\'e',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 28 : 32,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        Text(
                          'Hoş Geldiniz',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 24 : 28,
                            fontWeight: FontWeight.w300,
                            color: primaryColor.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // İçerik kartı
                  Expanded(
                    flex: isSmallScreen ? 3 : 4,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 5),
                          ),
                        ],
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.security,
                            size: isSmallScreen ? 40 : 48,
                            color: secondaryColor,
                          ),
                          SizedBox(height: isSmallScreen ? 16 : 20),
                          Text(
                            'Gizliliğiniz Bizim İçin Önemli',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 18 : 20,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 16),
                          Text(
                            'DiyetKent\'i kullanmaya başlamadan önce hizmet koşullarımızı ve gizlilik politikamızı incelemenizi öneririz.',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: isSmallScreen ? 16 : 24),
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: isSmallScreen ? 13 : 14,
                                color: Colors.grey[600],
                                height: 1.8,
                              ),
                              children: [
                                const TextSpan(
                                  text: 'Devam ederek ',
                                ),
                                TextSpan(
                                  text: 'Hizmet Koşulları',
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                    decorationColor: primaryColor.withValues(alpha: 0.4),
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = _launchTermsUrl,
                                ),
                                const TextSpan(
                                  text: ' ve\n',
                                ),
                                TextSpan(
                                  text: 'Gizlilik Politikası',
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                    decorationColor: primaryColor.withValues(alpha: 0.4),
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = _launchPrivacyUrl,
                                ),
                                const TextSpan(
                                  text: '\'nı kabul etmiş olursunuz.',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Buton bölümü
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: AnimatedOpacity(
                        opacity: _isAcceptButtonEnabled ? 1.0 : 0.5,
                        duration: const Duration(milliseconds: 300),
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isAcceptButtonEnabled ? _acceptTermsAndContinue : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              elevation: _isAcceptButtonEnabled ? 4 : 0,
                              shadowColor: primaryColor.withValues(alpha: 0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Kabul Et ve Devam Et',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (_isAcceptButtonEnabled) ...[
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 18,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }
}