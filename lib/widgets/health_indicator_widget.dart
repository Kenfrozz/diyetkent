import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/health_service.dart';
import '../services/step_counter_service.dart';
import '../models/health_data_model.dart';
import '../models/user_model.dart';
import '../database/drift_service.dart';
import '../pages/health_page.dart';
import 'dart:async';

class HealthIndicatorWidget extends StatefulWidget {
  const HealthIndicatorWidget({super.key});

  @override
  State<HealthIndicatorWidget> createState() => _HealthIndicatorWidgetState();
}

class _HealthIndicatorWidgetState extends State<HealthIndicatorWidget> {
  UserModel? _currentUser;
  HealthDataModel? _todayHealth;
  bool _isLoading = true;
  Timer? _updateTimer;
  int _currentStepCount = 0;

  @override
  void initState() {
    super.initState();
    _loadHealthData();
    _startPeriodicUpdate();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _startPeriodicUpdate() {
    // Her 10 saniyede bir güncelle
    _updateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _updateStepCount();
      }
    });
  }

  Future<void> _updateStepCount() async {
    try {
      final stepCount = StepCounterService.todayStepCount;
      if (mounted && stepCount != _currentStepCount) {
        setState(() {
          _currentStepCount = stepCount;
        });
      }
    } catch (e) {
      debugPrint('❌ Adım sayısı güncelleme hatası: $e');
    }
  }

  Future<void> _loadHealthData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Kullanıcı bilgilerini yükle
      final currentUser = await DriftService.getUser(user.uid);
      
      // Bugünkü sağlık verilerini yükle
      final todayHealth = await HealthService.getTodayHealthData();

      // İlk adım sayısını al
      final stepCount = StepCounterService.todayStepCount;

      if (mounted) {
        setState(() {
          _currentUser = currentUser;
          _todayHealth = todayHealth;
          _currentStepCount = stepCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Sağlık verisi yükleme hatası: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _openHealthPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const HealthPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.withValues(alpha: 0.6),
              Colors.purple.withValues(alpha: 0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _openHealthPage,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF25D366).withValues(alpha: 0.15), // WhatsApp yeşil tonu
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: const Color(0xFF25D366).withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF25D366).withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Kilo ikonu
            _buildHealthCard(
              icon: Icons.monitor_weight,
              value: _getWeightDisplay(),
              unit: 'kg',
            ),
            
            const SizedBox(width: 16),
            
            // Ayırıcı çizgi
            Container(
              width: 1,
              height: 24,
              color: const Color(0xFF128C7E).withValues(alpha: 0.4),
            ),
            
            const SizedBox(width: 16),
            
            // Adım sayısı ikonu
            _buildHealthCard(
              icon: Icons.directions_walk,
              value: _getCurrentStepDisplay(),
              unit: 'adım',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthCard({
    required IconData icon,
    required String value,
    required String unit,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: const Color(0xFF128C7E), // WhatsApp koyu yeşil
          size: 18,
        ),
        const SizedBox(width: 6),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF25D366),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              unit,
              style: const TextStyle(
                color: Color(0xFF128C7E),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }


  String _getWeightDisplay() {
    // Önce bugünkü sağlık verisinden
    if (_todayHealth?.weight != null) {
      return _todayHealth!.weight!.toStringAsFixed(1);
    }
    
    // Sonra kullanıcı modelinden
    if (_currentUser?.currentWeight != null) {
      return _currentUser!.currentWeight!.toStringAsFixed(1);
    }
    
    return '--';
  }

  String _getStepDisplay() {
    // Önce bugünkü sağlık verisinden
    if (_todayHealth?.stepCount != null) {
      return _formatStepCount(_todayHealth!.stepCount!);
    }
    
    // Sonra kullanıcı modelinden
    if (_currentUser?.todayStepCount != null && _currentUser!.todayStepCount! > 0) {
      return _formatStepCount(_currentUser!.todayStepCount!);
    }
    
    return '0';
  }

  String _getCurrentStepDisplay() {
    // Önce gerçek zamanlı adım sayısından
    if (_currentStepCount > 0) {
      return _formatStepCount(_currentStepCount);
    }
    
    // Fallback olarak eski metod
    return _getStepDisplay();
  }


  String _formatStepCount(int stepCount) {
    if (stepCount >= 1000) {
      double k = stepCount / 1000;
      return '${k.toStringAsFixed(k.truncateToDouble() == k ? 0 : 1)}K';
    }
    return stepCount.toString();
  }
}
