import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/health_service.dart';
// Removed diet_file_service (dietitian panel removed)
import '../services/step_counter_service.dart';
import '../services/export_service.dart';
import '../models/health_data_model.dart';
// Removed diet_file_model (dietitian panel removed)
import '../models/user_model.dart';
import '../database/drift_service.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:permission_handler/permission_handler.dart';

class HealthPage extends StatefulWidget {
  const HealthPage({super.key});

  @override
  State<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> with TickerProviderStateMixin {
  late TabController _tabController;
  
  UserModel? _currentUser;
  List<HealthDataModel> _healthHistory = [];
  // Removed diet files (dietitian panel removed)
  Map<String, dynamic> _healthStats = {};
  
  bool _isLoading = true;
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Adım sayar izin kontrolü
      final permissionStatus = await StepCounterService.getPermissionStatus();
      if (permissionStatus != PermissionStatus.granted) {
        if (mounted) {
          _showPermissionDialog();
        }
      }

      // Paralel veri yükleme
      final results = await Future.wait([
        DriftService.getUser(user.uid),
        HealthService.getUserHealthData(limit: 60),
        // DietFileService removed (dietitian panel removed)
        HealthService.getHealthStats(days: 30),
      ]);

      if (mounted) {
        setState(() {
          _currentUser = results[0] as UserModel?;
          _healthHistory = results[1] as List<HealthDataModel>;
          // Diet files removed (dietitian panel removed)
          _healthStats = results[2] as Map<String, dynamic>; // Index adjusted after diet files removal
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Sağlık sayfası veri yükleme hatası: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showAddDataDialog() async {
    final currentHeight = _currentUser?.currentHeight ?? 0.0;
    final currentWeight = _currentUser?.currentWeight ?? 0.0;
    
    _heightController.text = currentHeight > 0 ? currentHeight.toString() : '';
    _weightController.text = currentWeight > 0 ? currentWeight.toString() : '';

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sağlık Verisi Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _heightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Boy (cm)',
                hintText: 'Örn: 175',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Kilo (kg)',
                hintText: 'Örn: 70.5',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => _saveHealthData(),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveHealthData() async {
    final heightText = _heightController.text.trim();
    final weightText = _weightController.text.trim();

    if (heightText.isEmpty && weightText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az bir değer girmelisiniz')),
      );
      return;
    }

    try {
      final height = heightText.isNotEmpty ? double.parse(heightText) : null;
      final weight = weightText.isNotEmpty ? double.parse(weightText) : null;

      final success = await HealthService.updateHeightWeight(
        height: height,
        weight: weight,
      );

      if (success) {
        if (mounted) {
          Navigator.pop(context);
          _loadAllData(); // Verileri yenile
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sağlık verisi kaydedildi')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kayıt başarısız oldu')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sağlık Bilgilerim'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () => _showExportDialog(),
            tooltip: 'Verileri Export Et',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddDataDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Özet', icon: Icon(Icons.dashboard)),
            Tab(text: 'Geçmiş', icon: Icon(Icons.history)),
            Tab(text: 'Diyet Dosyaları', icon: Icon(Icons.folder)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSummaryTab(),
                _buildHistoryTab(),
                _buildDietFilesTab(),
              ],
            ),
    );
  }

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCurrentStatsCard(),
          const SizedBox(height: 16),
          _buildSwipeableMetricsCards(),
          const SizedBox(height: 16),
          _buildRiskIndicators(),
          const SizedBox(height: 16),
          _buildTargetComparison(),
          const SizedBox(height: 16),
          _buildStatsCard(),
        ],
      ),
    );
  }

  Widget _buildCurrentStatsCard() {
    final height = _currentUser?.currentHeight ?? 0.0;
    final weight = _currentUser?.currentWeight ?? 0.0;
    final bmi = _currentUser?.currentBMI;
    final stepCount = _currentUser?.todayStepCount ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mevcut Durum',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Boy',
                    height > 0 ? '${height.toInt()} cm' : '--',
                    Icons.height,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Kilo',
                    weight > 0 ? '${weight.toStringAsFixed(1)} kg' : '--',
                    Icons.monitor_weight,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'BMI',
                    bmi != null ? bmi.toStringAsFixed(1) : '--',
                    Icons.calculate,
                    _getBMIColor(bmi),
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Bugün Adım',
                    _formatStepCount(stepCount),
                    Icons.directions_walk,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final averageSteps = _healthStats['averageSteps'] ?? 0;
    final totalSteps = _healthStats['totalSteps'] ?? 0;
    final weightChange = _healthStats['weightChange'] ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Son 30 Gün İstatistikleri',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Ortalama Adım',
                    _formatStepCount(averageSteps),
                    Icons.trending_up,
                    Colors.purple,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Toplam Adım',
                    _formatStepCount(totalSteps),
                    Icons.directions_walk,
                    Colors.indigo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatItem(
              'Kilo Değişimi',
              '${weightChange >= 0 ? '+' : ''}${weightChange.toStringAsFixed(1)} kg',
              weightChange >= 0 ? Icons.trending_up : Icons.trending_down,
              weightChange >= 0 ? Colors.red : Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildSwipeableMetricsCards() {
    final PageController pageController = PageController();
    int currentPage = 0;

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'Sağlık Metrikleri',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 320,
              child: PageView(
                controller: pageController,
                onPageChanged: (index) {
                  setState(() {
                    currentPage = index;
                  });
                },
                children: [
                  _buildAnimatedMetricCard(
                    title: 'BMI Trend',
                    icon: Icons.health_and_safety,
                    color: const Color(0xFF00796B),
                    child: _buildCompactBMIChart(),
                  ),
                  _buildAnimatedMetricCard(
                    title: 'Kilo Takibi',
                    icon: Icons.monitor_weight,
                    color: Colors.blue,
                    child: _buildCompactWeightChart(),
                  ),
                  _buildAnimatedMetricCard(
                    title: 'Günlük Aktivite',
                    icon: Icons.directions_walk,
                    color: Colors.orange,
                    child: _buildCompactStepsChart(),
                  ),
                  _buildAnimatedMetricCard(
                    title: 'Vücut Kompozisyonu',
                    icon: Icons.pie_chart,
                    color: Colors.purple,
                    child: _buildCompactBodyCompositionChart(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Page indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPageIndicator(0, currentPage),
                _buildPageIndicator(1, currentPage),
                _buildPageIndicator(2, currentPage),
                _buildPageIndicator(3, currentPage),
              ],
            ),
            const SizedBox(height: 8),
            // Navigation buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: currentPage > 0
                      ? () {
                          pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      : null,
                  icon: const Icon(Icons.chevron_left),
                  label: const Text('Önceki'),
                ),
                TextButton.icon(
                  onPressed: currentPage < 3
                      ? () {
                          pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      : null,
                  icon: const Icon(Icons.chevron_right),
                  label: const Text('Sonraki'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnimatedMetricCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.1),
                Colors.white,
              ],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator(int pageIndex, int currentPage) {
    final isActive = pageIndex == currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF00796B) : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildCompactBMIChart() {
    final bmiData = _healthHistory
        .where((h) => h.bmi != null)
        .take(7)
        .toList()
        .reversed
        .toList();

    if (bmiData.isEmpty) {
      return const Center(
        child: Text(
          'BMI verisi yok',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final currentBMI = bmiData.first.bmi!;
    final bmiColor = _getBMIColor(currentBMI);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentBMI.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: bmiColor,
                  ),
                ),
                Text(
                  bmiData.first.bmiCategory,
                  style: TextStyle(
                    fontSize: 14,
                    color: bmiColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bmiColor.withValues(alpha: 0.2),
              ),
              child: Icon(
                Icons.favorite,
                color: bmiColor,
                size: 30,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SizedBox(
            height: 120,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: bmiData.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        entry.value.bmi!,
                      );
                    }).toList(),
                    isCurved: true,
                    color: bmiColor,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: bmiColor.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactWeightChart() {
    final weightData = _healthHistory
        .where((h) => h.weight != null)
        .take(7)
        .toList()
        .reversed
        .toList();

    if (weightData.isEmpty) {
      return const Center(
        child: Text(
          'Kilo verisi yok',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final currentWeight = weightData.first.weight!;
    final previousWeight = weightData.length > 1 ? weightData[1].weight! : currentWeight;
    final weightChange = currentWeight - previousWeight;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${currentWeight.toStringAsFixed(1)} kg',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  '${weightChange > 0 ? '+' : ''}${weightChange.toStringAsFixed(1)} kg',
                  style: TextStyle(
                    fontSize: 14,
                    color: weightChange > 0 ? Colors.red : Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withValues(alpha: 0.2),
              ),
              child: const Icon(
                Icons.monitor_weight,
                color: Colors.blue,
                size: 30,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SizedBox(
            height: 120,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: weightData.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        entry.value.weight!,
                      );
                    }).toList(),
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactStepsChart() {
    final stepCount = _currentUser?.todayStepCount ?? 0;
    final stepGoal = 10000; // Hedef adım sayısı
    final progress = stepCount / stepGoal;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatStepCount(stepCount),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                Text(
                  'Hedef: ${_formatStepCount(stepGoal)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.orange.withValues(alpha: 0.2),
              ),
              child: const Icon(
                Icons.directions_walk,
                color: Colors.orange,
                size: 30,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Center(
            child: SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                children: [
                  // Background circle
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 12,
                      backgroundColor: Colors.orange.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation(Colors.orange.withValues(alpha: 0.2)),
                    ),
                  ),
                  // Progress circle
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      strokeWidth: 12,
                      backgroundColor: Colors.transparent,
                      valueColor: const AlwaysStoppedAnimation(Colors.orange),
                    ),
                  ),
                  // Center text
                  Center(
                    child: Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactBodyCompositionChart() {
    // Mock data - gerçek implementasyonda kullanıcı verilerini kullan
    final bodyFatPercentage = 18.5;
    final muscleMassPercentage = 45.2;
    final waterPercentage = 58.7;

    return Column(
      children: [
        const Text(
          'Vücut Kompozisyonu',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _buildCompositionItem(
                  'Yağ Oranı',
                  '${bodyFatPercentage.toStringAsFixed(1)}%',
                  bodyFatPercentage / 100,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCompositionItem(
                  'Kas Kütlesi',
                  '${muscleMassPercentage.toStringAsFixed(1)}%',
                  muscleMassPercentage / 100,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCompositionItem(
                  'Su Oranı',
                  '${waterPercentage.toStringAsFixed(1)}%',
                  waterPercentage / 100,
                  Colors.blue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompositionItem(String label, String value, double progress, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: SizedBox(
            width: 60,
            child: Stack(
              children: [
                // Background
                Container(
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                // Progress
                Align(
                  alignment: Alignment.bottomCenter,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeInOut,
                    height: progress * 100,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    if (_healthHistory.isEmpty) {
      return const Center(
        child: Text('Henüz sağlık verisi bulunmuyor'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _healthHistory.length,
      itemBuilder: (context, index) {
        final health = _healthHistory[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.withValues(alpha: 0.2),
              child: Text(
                DateFormat('dd').format(health.recordDate),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              DateFormat('dd MMMM yyyy', 'tr_TR').format(health.recordDate),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (health.height != null || health.weight != null)
                  Text(
                    '${health.height != null ? 'Boy: ${health.height!.toInt()} cm' : ''}'
                    '${health.height != null && health.weight != null ? ' • ' : ''}'
                    '${health.weight != null ? 'Kilo: ${health.weight!.toStringAsFixed(1)} kg' : ''}',
                  ),
                if (health.bmi != null)
                  Text('BMI: ${health.bmi!.toStringAsFixed(1)}'),
                if (health.stepCount != null)
                  Text('Adım: ${_formatStepCount(health.stepCount!)}'),
              ],
            ),
            trailing: health.bmi != null
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getBMIColor(health.bmi).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      health.bmiCategory,
                      style: TextStyle(
                        color: _getBMIColor(health.bmi),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildDietFilesTab() {
    // Diet files feature removed (dietitian panel removed)
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Diyet dosyası özelliği kaldırıldı'),
          SizedBox(height: 8),
          Text(
            'Bu özellik artık mevcut değil',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // Diet file functionality removed (dietitian panel removed)

  Color _getBMIColor(double? bmi) {
    if (bmi == null) return Colors.grey;
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }

  String _formatStepCount(int stepCount) {
    if (stepCount >= 1000) {
      return '${(stepCount / 1000).toStringAsFixed(1)}K';
    }
    return stepCount.toString();
  }

  Future<void> _showPermissionDialog() async {
    final permissionStatus = await StepCounterService.getPermissionStatus();
    
    String title;
    String content;
    List<Widget> actions;

    if (permissionStatus == PermissionStatus.permanentlyDenied) {
      title = 'İzin Gerekli';
      content = '${StepCounterService.getPermissionStatusMessage()}\n\nLütfen uygulama ayarlarından "Fiziksel Aktivite" iznini etkinleştirin.';
      actions = [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            await StepCounterService.openSettings();
          },
          child: const Text('Ayarlara Git'),
        ),
      ];
    } else {
      title = 'Adım Sayar İzni';
      content = StepCounterService.getPermissionStatusMessage();
      actions = [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            final granted = await StepCounterService.requestPermission();
            if (mounted) {
              if (granted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Adım sayar izni verildi!')),
                );
                // StepCounterService'i yeniden başlat
                await StepCounterService.restart();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Adım sayar izni reddedildi')),
                );
              }
            }
          },
          child: const Text('İzin Ver'),
        ),
      ];
    }

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: actions,
        ),
      );
    }
  }

  Widget _buildRiskIndicators() {
    final currentBMI = _currentUser?.currentBMI;
    final height = _currentUser?.currentHeight ?? 0.0;
    final weight = _currentUser?.currentWeight ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFF00796B),
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Sağlık Risk Göstergeleri',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _showRiskInfoDialog(),
                  icon: const Icon(Icons.info_outline),
                  iconSize: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildRiskIndicator(
                    title: 'BMI Durumu',
                    value: currentBMI?.toStringAsFixed(1) ?? '--',
                    risk: _getBMIRiskLevel(currentBMI),
                    color: _getBMIColor(currentBMI),
                    subtitle: _getBMICategory(currentBMI),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRiskIndicator(
                    title: 'Kalp Sağlığı',
                    value: _calculateHeartRisk(currentBMI, weight),
                    risk: _getHeartRiskLevel(currentBMI),
                    color: _getHeartRiskColor(currentBMI),
                    subtitle: 'Kardiyovasküler',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildRiskIndicator(
                    title: 'Metabolizma',
                    value: '${_calculateBMR(height, weight).toStringAsFixed(0)} kcal',
                    risk: 'normal',
                    color: Colors.green,
                    subtitle: 'Bazal Metabolizma',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRiskIndicator(
                    title: 'Aktivite Skoru',
                    value: _getActivityScore(),
                    risk: _getActivityRisk(),
                    color: _getActivityColor(),
                    subtitle: 'Günlük Hareket',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskIndicator({
    required String title,
    required String value,
    required String risk,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetComparison() {
    final currentWeight = _currentUser?.currentWeight ?? 0.0;
    final targetWeight = currentWeight * 0.9; // Placeholder: 10% weight loss goal
    final stepCount = _currentUser?.todayStepCount ?? 0;
    const targetSteps = 10000;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.track_changes,
                  color: Color(0xFF00796B),
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'Hedef Karşılaştırması',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildComparisonItem(
              title: 'Kilo Hedefi',
              current: currentWeight,
              target: targetWeight,
              unit: 'kg',
              isHigherBetter: currentWeight > targetWeight,
            ),
            const SizedBox(height: 12),
            _buildComparisonItem(
              title: 'Günlük Adım',
              current: stepCount.toDouble(),
              target: targetSteps.toDouble(),
              unit: 'adım',
              isHigherBetter: true,
            ),
            const SizedBox(height: 12),
            _buildProgressIndicator(
              title: 'Adım Hedefi',
              current: stepCount,
              target: targetSteps,
              color: const Color(0xFF00796B),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonItem({
    required String title,
    required double current,
    required double target,
    required String unit,
    required bool isHigherBetter,
  }) {
    final difference = current - target;
    final isOnTrack = isHigherBetter ? difference >= 0 : difference <= 0;
    final trendIcon = isOnTrack 
        ? Icons.trending_up 
        : Icons.trending_down;
    final trendColor = isOnTrack ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: trendColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: trendColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${current.toStringAsFixed(current == current.toInt() ? 0 : 1)} $unit',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '/ ${target.toStringAsFixed(target == target.toInt() ? 0 : 1)} $unit',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              Icon(
                trendIcon,
                color: trendColor,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                '${difference.abs().toStringAsFixed(1)} $unit',
                style: TextStyle(
                  fontSize: 12,
                  color: trendColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator({
    required String title,
    required int current,
    required int target,
    required Color color,
  }) {
    final progress = (current / target).clamp(0.0, 1.0);
    final percentage = (progress * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: color.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
        ),
      ],
    );
  }

  String _getBMIRiskLevel(double? bmi) {
    if (bmi == null) return 'unknown';
    if (bmi < 18.5) return 'low';
    if (bmi < 25) return 'normal';
    if (bmi < 30) return 'medium';
    return 'high';
  }

  String _getBMICategory(double? bmi) {
    if (bmi == null) return 'Bilinmiyor';
    if (bmi < 18.5) return 'Zayıf';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Fazla Kilo';
    return 'Obez';
  }

  String _calculateHeartRisk(double? bmi, double weight) {
    if (bmi == null) return 'Değerlendirilemez';
    if (bmi < 25) return 'Düşük Risk';
    if (bmi < 30) return 'Orta Risk';
    return 'Yüksek Risk';
  }

  String _getHeartRiskLevel(double? bmi) {
    if (bmi == null) return 'unknown';
    if (bmi < 25) return 'low';
    if (bmi < 30) return 'medium';
    return 'high';
  }

  Color _getHeartRiskColor(double? bmi) {
    if (bmi == null) return Colors.grey;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }

  double _calculateBMR(double height, double weight) {
    // Mifflin-St Jeor Equation for women (default)
    // BMR = 10 × weight(kg) + 6.25 × height(cm) - 5 × age(years) - 161
    // Using average age of 30 for simplicity
    if (height == 0 || weight == 0) return 0;
    return (10 * weight) + (6.25 * height) - (5 * 30) - 161;
  }

  String _getActivityScore() {
    final stepCount = _currentUser?.todayStepCount ?? 0;
    if (stepCount >= 15000) return 'Mükemmel';
    if (stepCount >= 10000) return 'İyi';
    if (stepCount >= 7000) return 'Orta';
    if (stepCount >= 3000) return 'Düşük';
    return 'Çok Düşük';
  }

  String _getActivityRisk() {
    final stepCount = _currentUser?.todayStepCount ?? 0;
    if (stepCount >= 10000) return 'low';
    if (stepCount >= 7000) return 'medium';
    return 'high';
  }

  Color _getActivityColor() {
    final stepCount = _currentUser?.todayStepCount ?? 0;
    if (stepCount >= 10000) return Colors.green;
    if (stepCount >= 7000) return Colors.orange;
    return Colors.red;
  }

  void _showRiskInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Risk Göstergeleri Hakkında'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'BMI Durumu:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Yeşil: Normal (18.5-24.9)\n• Sarı: Fazla kilo (25-29.9)\n• Kırmızı: Obezite (30+)'),
              SizedBox(height: 12),
              Text(
                'Kalp Sağlığı:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('BMI değerlerine göre kardiyovasküler risk değerlendirmesi'),
              SizedBox(height: 12),
              Text(
                'Aktivite Skoru:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Günlük adım sayısına göre aktivite seviyesi'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
    if (_healthHistory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Export için sağlık verisi bulunmuyor'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.file_download, color: Color(0xFF00796B)),
            SizedBox(width: 8),
            Text('Veri Export'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sağlık verilerinizi hangi formatta export etmek istiyorsunuz?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              '${_healthHistory.length} kayıt export edilecek',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _exportToCSV();
            },
            icon: const Icon(Icons.table_chart),
            label: const Text('CSV'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF00796B),
            ),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _exportToPDF();
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('PDF'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToCSV() async {
    if (_currentUser == null) {
      _showErrorMessage('Kullanıcı bilgileri yüklenemedi');
      return;
    }

    try {
      _showLoadingDialog('CSV dosyası hazırlanıyor...');
      
      await ExportService.exportHealthDataToCSV(
        healthData: _healthHistory,
        user: _currentUser!,
      );
      
      if (mounted) {
        Navigator.pop(context); // Loading dialog'ı kapat
        _showSuccessMessage('CSV dosyası başarıyla oluşturuldu ve paylaşıldı!');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Loading dialog'ı kapat
        _showErrorMessage('CSV export hatası: $e');
      }
    }
  }

  Future<void> _exportToPDF() async {
    if (_currentUser == null) {
      _showErrorMessage('Kullanıcı bilgileri yüklenemedi');
      return;
    }

    try {
      _showLoadingDialog('PDF raporu hazırlanıyor...');
      
      await ExportService.exportHealthDataToPDF(
        healthData: _healthHistory,
        user: _currentUser!,
        // chartKey: _chartKey, // Grafik screenshot'ı için gereklirse eklenebilir
      );
      
      if (mounted) {
        Navigator.pop(context); // Loading dialog'ı kapat
        _showSuccessMessage('PDF raporu başarıyla oluşturuldu ve paylaşıldı!');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Loading dialog'ı kapat
        _showErrorMessage('PDF export hatası: $e');
      }
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
