import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/health_service.dart';
import '../services/step_counter_service.dart';
import '../models/health_data_model.dart';
import '../models/user_model.dart';
import '../database/drift_service.dart';
import '../pages/health_page.dart';
import 'dart:async';

class AppBarHealthIndicators extends StatefulWidget {
  const AppBarHealthIndicators({super.key});

  @override
  State<AppBarHealthIndicators> createState() => _AppBarHealthIndicatorsState();
}

class _AppBarHealthIndicatorsState extends State<AppBarHealthIndicators> {
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

      final currentUser = await DriftService.getUser(user.uid);
      final todayHealth = await HealthService.getTodayHealthData();
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
    final theme = Theme.of(context);
    final appBarTheme = theme.appBarTheme;
    
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  appBarTheme.iconTheme?.color ?? theme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Kilo göstergesi
          GestureDetector(
            onTap: _openHealthPage,
            child: _buildCircularHealthIndicator(
              icon: Icons.monitor_weight,
              label: 'Kilo',
              value: _getWeightDisplay(),
              unit: 'kg',
              theme: theme,
            ),
          ),
          
          // Adım sayısı göstergesi
          GestureDetector(
            onTap: _openHealthPage,
            child: _buildCircularHealthIndicator(
              icon: Icons.directions_walk,
              label: 'Adım Sayısı',
              value: _getCurrentStepDisplay(),
              unit: 'adım',
              theme: theme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularHealthIndicator({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required ThemeData theme,
  }) {
    final appBarTheme = theme.appBarTheme;
    final backgroundColor = appBarTheme.backgroundColor ?? theme.primaryColor;
    final foregroundColor = appBarTheme.foregroundColor ?? 
                           appBarTheme.iconTheme?.color ?? 
                           theme.colorScheme.onPrimary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Yuvarlak gösterge
        Container(
          width: 75,
          height: 75,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: foregroundColor.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: foregroundColor,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: foregroundColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Label
        Text(
          label,
          style: TextStyle(
            color: foregroundColor.withValues(alpha: 0.85),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _getWeightDisplay() {
    if (_todayHealth?.weight != null) {
      return _todayHealth!.weight!.toStringAsFixed(1);
    }
    
    if (_currentUser?.currentWeight != null) {
      return _currentUser!.currentWeight!.toStringAsFixed(1);
    }
    
    return '--';
  }

  String _getCurrentStepDisplay() {
    if (_currentStepCount > 0) {
      return _formatStepCount(_currentStepCount);
    }
    
    return _getStepDisplay();
  }

  String _getStepDisplay() {
    if (_todayHealth?.stepCount != null) {
      return _formatStepCount(_todayHealth!.stepCount!);
    }
    
    if (_currentUser?.todayStepCount != null && _currentUser!.todayStepCount! > 0) {
      return _formatStepCount(_currentUser!.todayStepCount!);
    }
    
    return '0';
  }

  String _formatStepCount(int stepCount) {
    if (stepCount >= 1000) {
      double k = stepCount / 1000;
      return '${k.toStringAsFixed(k.truncateToDouble() == k ? 0 : 1)}K';
    }
    return stepCount.toString();
  }
}