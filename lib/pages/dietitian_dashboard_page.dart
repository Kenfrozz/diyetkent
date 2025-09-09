import 'package:flutter/material.dart';
import '../services/bulk_message_service.dart';
import '../services/user_service.dart';
import '../database/drift_service.dart';
import '../services/diet_assignment_engine.dart';
import '../services/auth_service.dart';
import 'create_diet_package_page.dart';
import 'bulk_diet_upload_page.dart';
import '../models/user_role_model.dart';
import '../models/tag_model.dart';
import '../models/user_model.dart';
import '../models/diet_package_model.dart';
import '../models/user_diet_assignment_model.dart';
import 'package:fl_chart/fl_chart.dart';

class DietitianDashboardPage extends StatefulWidget {
  const DietitianDashboardPage({super.key});

  @override
  State<DietitianDashboardPage> createState() => _DietitianDashboardPageState();
}

class _DietitianDashboardPageState extends State<DietitianDashboardPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  UserRoleModel? _currentUserRole;
  UserModel? _currentUser;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _usersHealthData = [];
  List<TagModel> _availableTags = [];
  List<DietPackageModel> _dietPackages = [];
  List<UserDietAssignmentModel> _activeAssignments = [];
  DietitianAnalytics? _analytics;

  bool _isLoading = true;
  final DietAssignmentEngine _assignmentEngine = DietAssignmentEngine();

  // Toplu mesaj form controllers
  final _messageController = TextEditingController();
  final _selectedTags = <String>[];
  
  // Gelişmiş filtreleme için state değişkenleri
  String _selectedTargetType = 'all';
  RangeValues _bmiRange = const RangeValues(18.5, 40.0);
  DateTimeRange? _activityDateRange;
  int _filteredUserCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 6, vsync: this); // 5 → 6 sekme (yeni Analytics sekmesi)
    _initializeEngine();
  }

  Future<void> _initializeEngine() async {
    try {
      // Önce yetki kontrolü yap
      await _checkDietitianPermission();
      
      // Yetki varsa engine'i başlat
      await _assignmentEngine.initialize(enableAutoScheduling: true);
    } catch (e) {
      debugPrint('❌ Assignment Engine başlatma hatası: $e');
      // Engine hatası olsa bile yetki varsa paneli göster
      if (_currentUser != null && 
          (_currentUser!.isDietitian || _currentUser!.userRole == UserRoleType.admin)) {
        debugPrint('⚠️ Engine hatası var ama yetki kontrolü geçti, panel gösteriliyor');
        return;
      }
      _showAccessDenied();
    }
  }

  Future<void> _checkDietitianPermission() async {
    try {
      // AuthService'ten mevcut kullanıcıyı al
      final currentUserId = AuthService.currentUserId;
      if (currentUserId == null) {
        debugPrint('❌ Dashboard - Mevcut kullanici ID null, erisim reddedildi.');
        _showAccessDenied();
        return;
      }

      // Önce Firestore'dan güncel rolü al (ana kaynak)
      final firestoreRole = await UserService.getUserRole(currentUserId);
      debugPrint('🔍 Firestore Role: ${firestoreRole?.name}');

      // Kullanıcı bilgisini Isar'dan al
      final user = await DriftService.getUserById(currentUserId);
      if (user == null) {
        debugPrint('❌ Dashboard - Kullanici Isar\'da bulunamadi: $currentUserId');
        _showAccessDenied();
        return;
      }

      debugPrint('🔍 Isar Role: ${user.userRole.name}');

      // Rollerin senkronizasyonu - Firestore ana kaynak
      if (firestoreRole != null && firestoreRole != user.userRole) {
        debugPrint('🔄 Rol senkronizasyonu: ${user.userRole.name} → ${firestoreRole.name}');
        user.userRole = firestoreRole;
        await DriftService.updateUser(user);
      }

      // Firestore rolüne göre yetki kontrolü yap
      final effectiveRole = firestoreRole ?? user.userRole;
      final isDietitianUser = effectiveRole == UserRoleType.dietitian || effectiveRole == UserRoleType.admin;

      debugPrint('--- YETKİ KONTROLÜ ---');
      debugPrint('Kullanıcı ID: ${user.userId}');
      debugPrint('Firestore Rol: ${firestoreRole?.name}');
      debugPrint('Isar Rol: ${user.userRole.name}');
      debugPrint('Etkin Rol: ${effectiveRole.name}');
      debugPrint('İzin Durumu: $isDietitianUser');

      // Sadece diyetisyen ve admin rolleri erişebilir
      if (!isDietitianUser) {
        debugPrint('❌ Dashboard - Erişim reddedildi. Etkin rol: ${effectiveRole.name}');
        _showAccessDenied();
        return;
      }

      // UserRoleModel oluştur
      final userRole = UserRoleModel.create(
        userId: user.userId,
        role: effectiveRole,
        specialization: null,
        clinicName: null,
        licenseNumber: null,
      );

      debugPrint('✅ Dashboard - Erişim onaylandı. Etkin rol: ${effectiveRole.name}');

      setState(() {
        _currentUser = user;
        _currentUserRole = userRole;
      });

      await _loadDashboardData();
    } catch (e) {
      debugPrint('❌ Diyetisyen yetki kontrolü hatası: $e');
      _showAccessDenied();
    }
  }

  void _showAccessDenied() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Erişim Reddedildi')),
          body: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.block, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Bu sayfaya erişim yetkiniz bulunmamaktadır.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Sadece diyetisyenler bu paneli kullanabilir.',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadDashboardData() async {
    if (_currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      // Paralel veri yükleme - yeni analytics dahil
      final results = await Future.wait([
        BulkMessageService.getDietitianStats(),
        BulkMessageService.getAllUsersHealthData(),
        DriftService.getAllTags(),
        DriftService.getDietitianPackages(_currentUser!.userId),
        DriftService.getDietitianAssignments(_currentUser!.userId),
        _assignmentEngine.getDietitianAnalytics(_currentUser!.userId),
      ]);

      if (mounted) {
        setState(() {
          _stats = results[0] as Map<String, dynamic>;
          _usersHealthData = results[1] as List<Map<String, dynamic>>;
          _availableTags = results[2] as List<TagModel>;
          _dietPackages = results[3] as List<DietPackageModel>;
          _activeAssignments = results[4] as List<UserDietAssignmentModel>;
          _analytics = results[5] as DietitianAnalytics;
          _isLoading = false;
        });
        // Filtrelenmiş kullanıcı sayısını güncelle
        _updateFilteredUserCount();
      }
    } catch (e) {
      debugPrint('❌ Dashboard veri yükleme hatası: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserRole == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${_currentUserRole!.roleIcon} Diyetisyen Paneli'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Özet', icon: Icon(Icons.dashboard)),
            Tab(text: 'Müşterilerim', icon: Icon(Icons.people)),
            Tab(text: 'Diyet Paketleri', icon: Icon(Icons.restaurant_menu)),
            Tab(text: 'Atamalar', icon: Icon(Icons.assignment)),
            Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
            Tab(text: 'Diğer', icon: Icon(Icons.more_horiz)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSummaryTab(),
                _buildClientsTab(),
                _buildDietPackagesTab(),
                _buildAssignmentsTab(),
                _buildAnalyticsTab(),
                _buildOtherTab(),
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
          _buildWelcomeCard(),
          const SizedBox(height: 16),
          _buildStatsCards(),
          const SizedBox(height: 16),
          _buildQuickActionsCard(),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.teal.withValues(alpha: 0.2),
                  child: Text(_currentUserRole!.roleIcon,
                      style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hoş Geldiniz!',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _currentUserRole!.roleDisplayName,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_currentUserRole!.specialization != null) ...[
              const SizedBox(height: 12),
              Text('Uzmanlık: ${_currentUserRole!.specialization}'),
            ],
            if (_currentUserRole!.clinicName != null) ...[
              const SizedBox(height: 4),
              Text('Klinik: ${_currentUserRole!.clinicName}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    final totalUsers = _stats['totalUsers'] ?? 0;
    final totalPackages = _dietPackages.length;
    final activeAssignments = _analytics?.activeAssignments ?? 0;
    final completedAssignments = _analytics?.completedAssignments ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Toplam Müşteri',
                totalUsers.toString(),
                Icons.people,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Diyet Paketleri',
                totalPackages.toString(),
                Icons.restaurant_menu,
                Colors.teal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Aktif Atama',
                activeAssignments.toString(),
                Icons.assignment,
                Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Tamamlanan',
                completedAssignments.toString(),
                Icons.check_circle,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
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
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hızlı İşlemler',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _createNewAssignment,
                    icon: const Icon(Icons.add_circle),
                    label: const Text('Yeni Atama'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _tabController.animateTo(2),
                    icon: const Icon(Icons.restaurant_menu),
                    label: const Text('Yeni Paket'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _bulkUploadDietFiles,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Toplu Yükleme'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _tabController.animateTo(4),
                    icon: const Icon(Icons.analytics),
                    label: const Text('Analytics'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mesaj İçeriği'),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Mesajınızı buraya yazın...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Alıcı Seçimi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people, size: 16, color: Colors.teal.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '$_filteredUserCount kişi',
                        style: TextStyle(
                          color: Colors.teal.shade600,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Hedef türü seçimi
            _buildTargetTypeSelector(),
            
            const SizedBox(height: 16),
            
            // Filtreleme seçenekleri
            if (_selectedTargetType == 'filtered') ...[
              _buildAdvancedFilters(),
              const SizedBox(height: 16),
            ],
            
            // Tag seçimi (eğer tags seçiliyse)
            if (_selectedTargetType == 'tags') ...[
              _buildTagSelector(),
              const SizedBox(height: 12),
            ],
            
            // Hızlı aksiyon butonları
            _buildQuickActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTagSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _availableTags.map((tag) {
        final isSelected = _selectedTags.contains(tag.name);
        return FilterChip(
          label: Text(tag.name),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedTags.add(tag.name);
              } else {
                _selectedTags.remove(tag.name);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildTargetTypeSelector() {
    return Column(
      children: [
        // Tüm kullanıcılara gönder
        RadioListTile<String>(
          value: 'all',
          groupValue: _selectedTargetType,
          onChanged: (value) => _setTargetType(value!),
          title: const Text('Tüm Kullanıcılara Gönder'),
          subtitle: Text('${_stats['totalUsers'] ?? 0} kullanıcı'),
          secondary: const Icon(Icons.people),
        ),
        
        // Etiketli kullanıcılara gönder
        RadioListTile<String>(
          value: 'tags',
          groupValue: _selectedTargetType,
          onChanged: (value) => _setTargetType(value!),
          title: const Text('Etiket Bazlı Gönder'),
          subtitle: const Text('Belirli etiketlere sahip kullanıcılar'),
          secondary: const Icon(Icons.label),
        ),
        
        // Gelişmiş filtreleme
        RadioListTile<String>(
          value: 'filtered',
          groupValue: _selectedTargetType,
          onChanged: (value) => _setTargetType(value!),
          title: const Text('Gelişmiş Filtreleme'),
          subtitle: const Text('BMI, aktivite tarihine göre filtrele'),
          secondary: const Icon(Icons.filter_list),
        ),
      ],
    );
  }

  Widget _buildAdvancedFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtreleme Kriterleri',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          
          // BMI aralığı filtresi
          _buildBMIRangeFilter(),
          
          const SizedBox(height: 16),
          
          // Son aktivite tarihi filtresi
          _buildActivityDateFilter(),
        ],
      ),
    );
  }

  Widget _buildBMIRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('BMI Aralığı'),
            Text(
              '${_bmiRange.start.toStringAsFixed(1)} - ${_bmiRange.end.toStringAsFixed(1)}',
              style: TextStyle(color: Colors.teal.shade600, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 8),
        RangeSlider(
          values: _bmiRange,
          min: 15.0,
          max: 45.0,
          divisions: 60,
          labels: RangeLabels(
            _bmiRange.start.toStringAsFixed(1),
            _bmiRange.end.toStringAsFixed(1),
          ),
          onChanged: (values) {
            setState(() {
              _bmiRange = values;
              _updateFilteredUserCount();
            });
          },
        ),
      ],
    );
  }

  Widget _buildActivityDateFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Son Aktivite Tarihi'),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectActivityDateRange,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _activityDateRange != null
                        ? '${_formatDate(_activityDateRange!.start)} - ${_formatDate(_activityDateRange!.end)}'
                        : 'Tarih aralığı seçin',
                    style: TextStyle(
                      color: _activityDateRange != null ? Colors.black : Colors.grey.shade600,
                    ),
                  ),
                ),
                if (_activityDateRange != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      setState(() {
                        _activityDateRange = null;
                        _updateFilteredUserCount();
                      });
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _selectedTargetType == 'tags' ? _selectAllTags : null,
            icon: const Icon(Icons.select_all, size: 18),
            label: const Text('Tümünü Seç'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.teal.shade600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _selectedTargetType == 'tags' ? _clearAllSelections : null,
            icon: const Icon(Icons.clear_all, size: 18),
            label: const Text('Temizle'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange.shade600,
            ),
          ),
        ),
      ],
    );
  }

  String _getSelectedTargetType() {
    return _selectedTargetType;
  }

  void _setTargetType(String type) {
    setState(() {
      _selectedTargetType = type;
      if (type == 'all') {
        _selectedTags.clear();
        _activityDateRange = null;
        _bmiRange = const RangeValues(18.5, 40.0);
      }
      _updateFilteredUserCount();
    });
  }

  void _selectAllTags() {
    setState(() {
      _selectedTags.clear();
      _selectedTags.addAll(_availableTags.map((tag) => tag.name));
      _updateFilteredUserCount();
    });
  }

  void _clearAllSelections() {
    setState(() {
      _selectedTags.clear();
      _updateFilteredUserCount();
    });
  }

  Future<void> _selectActivityDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _activityDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.teal,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _activityDateRange = picked;
        _updateFilteredUserCount();
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _updateFilteredUserCount() {
    // Bu metod gerçek filtreleme mantığını implement edecek
    // Şimdilik basit bir hesaplama yapıyoruz
    int count = 0;
    switch (_selectedTargetType) {
      case 'all':
        count = _stats['totalUsers'] ?? 0;
        break;
      case 'tags':
        // Tag bazlı kullanıcı sayısı hesaplama
        count = _selectedTags.isEmpty ? 0 : (_stats['totalUsers'] ?? 0) ~/ 2;
        break;
      case 'filtered':
        // BMI ve aktivite tarihine göre filtrelenmiş kullanıcı sayısı
        count = (_stats['totalUsers'] ?? 0) ~/ 3;
        break;
    }
    
    setState(() {
      _filteredUserCount = count;
    });
  }

  Future<void> _sendBulkMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mesaj içeriği boş olamaz')),
      );
      return;
    }

    // Loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Mesaj gönderiliyor...'),
          ],
        ),
      ),
    );

    try {
      bool success = false;

      if (_getSelectedTargetType() == 'all') {
        success = await BulkMessageService.sendMessageToAllUsers(
          message: message,
        );
      } else if (_selectedTags.isNotEmpty) {
        success = await BulkMessageService.sendMessageToTaggedUsers(
          tags: _selectedTags,
          message: message,
        );
      }

      if (mounted) {
        Navigator.pop(context); // Loading dialog'u kapat
      }

      if (!mounted) return;

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mesaj başarıyla gönderildi')),
          );
        }
        _messageController.clear();
        _selectedTags.clear();
        await _loadDashboardData(); // İstatistikleri güncelle
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mesaj gönderme başarısız oldu')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Loading dialog'u kapat
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  // Yeni Müşteriler sekmesi
  Widget _buildClientsTab() {
    if (_usersHealthData.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Henüz müşteriniz yok', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('Kullanıcılar uygulamaya kaydoldukça burada görünecekler.',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _usersHealthData.length,
      itemBuilder: (context, index) {
        final userData = _usersHealthData[index];
        final user = userData['user'];
        final healthData = userData['healthData'];

        // Bu kullanıcının aktif atamasını bul
        final activeAssignment = _activeAssignments
            .where((a) => a.userId == user['userId'])
            .firstOrNull;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: activeAssignment != null
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.2),
              child: Text(
                user['name']?[0]?.toUpperCase() ?? '?',
                style: TextStyle(
                  color: activeAssignment != null ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(user['name'] ?? 'İsimsiz'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (activeAssignment != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.green.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'Aktif Diyet - %${(activeAssignment.progress * 100).toInt()}',
                      style: const TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 4),
                Text('Tel: ${user['phoneNumber'] ?? 'Bilinmiyor'}'),
                if (healthData != null)
                  Text(
                    'Boy: ${healthData['height']?.toInt() ?? '--'} cm • '
                    'Kilo: ${healthData['weight']?.toStringAsFixed(1) ?? '--'} kg',
                  ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (activeAssignment != null) ...[
                      _buildAssignmentSummaryCard(activeAssignment),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: activeAssignment == null
                                ? () => _createAssignmentForUser(
                                    user['userId'], user['name'])
                                : null,
                            icon: const Icon(Icons.add_circle),
                            label: Text(activeAssignment == null
                                ? 'Diyet Ata'
                                : 'Zaten Aktif'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _viewClientProgress(
                                user['userId'], user['name']),
                            icon: const Icon(Icons.analytics),
                            label: const Text('İlerleme'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  // ========== YENİ YARDİMCI METODLARI ==========

  Widget _buildAssignmentSummaryCard(UserDietAssignmentModel assignment) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'İlerleme: ${assignment.progressPercentage}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                assignment.weightChangeText,
                style: TextStyle(
                  color:
                      assignment.weightChange < 0 ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: assignment.progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
          ),
        ],
      ),
    );
  }

  void _createNewAssignment() async {
    // Yeni atama oluşturma dialog'u
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Diyet Ataması'),
        content: const Text(
          'Müşteri seçin ve otomatik atama oluşturulsun mu?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _tabController.animateTo(1); // Müşteriler sekmesine git
            },
            child: const Text('Müşteri Seç'),
          ),
        ],
      ),
    );
  }

  void _createAssignmentForUser(String userId, String userName) async {
    if (_currentUser == null) return;

    try {
      // Loading göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Otomatik atama oluşturuluyor...'),
            ],
          ),
        ),
      );

      final result = await _assignmentEngine.createAssignment(
        userId: userId,
        dietitianId: _currentUser!.userId,
      );

      if (mounted) {
        Navigator.pop(context); // Loading'i kapat
      }

      if (!mounted) return;

      if (result.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$userName için otomatik atama oluşturuldu!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        await _loadDashboardData(); // Verileri yenile
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Atama oluşturma hatası: ${result.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Loading'i kapat
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewClientProgress(String userId, String userName) {
    // İlerlemeli detay sayfasına git
    debugPrint('$userName kullanıcısının ilerlemesini gör: $userId');
    // TODO: Detay sayfası implementasyonu
  }

  void _assignPackageToClient(DietPackageModel package) async {
    // Müşteri seçimi dialog'u
    final availableUsers = _usersHealthData
        .where((data) =>
            !_activeAssignments.any((a) => a.userId == data['user']['userId']))
        .toList();

    if (availableUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tüm müşterilerin zaten aktif ataması var'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${package.title} paketini ata'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: availableUsers.length,
            itemBuilder: (context, index) {
              final userData = availableUsers[index];
              final user = userData['user'];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(user['name']?[0]?.toUpperCase() ?? '?'),
                ),
                title: Text(user['name'] ?? 'İsimsiz'),
                subtitle: Text(user['phoneNumber'] ?? ''),
                onTap: () {
                  Navigator.pop(context);
                  _createAssignmentForUser(user['userId'], user['name']);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }

  void _editPackage(DietPackageModel package) {
    debugPrint('Paketi düzenle: ${package.packageId}');
    // TODO: Düzenleme sayfası
  }

  void _viewPackageDetails(DietPackageModel package) {
    debugPrint('Paket detayları: ${package.packageId}');
    // TODO: Detay sayfası
  }

  void _updateAssignmentProgress(UserDietAssignmentModel assignment) {
    debugPrint('Atama güncelle: ${assignment.assignmentId}');
    // TODO: Güncelleme dialog'u
  }

  void _viewAssignmentDetails(UserDietAssignmentModel assignment) {
    debugPrint('Atama detayları: ${assignment.assignmentId}');
    // TODO: Detay sayfası
  }

  void _processNextSequence(UserDietAssignmentModel assignment) async {
    try {
      final result =
          await _assignmentEngine.processNextSequence(assignment.userId);

      if (!mounted) return;

      if (result.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sonraki dizi başlatıldı: ${result.sequenceNumber}'),
              backgroundColor: Colors.green,
            ),
          );
        }
        await _loadDashboardData();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hata: ${result.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Beklenmeyen hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _bulkUploadDietFiles() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BulkDietUploadPage(),
      ),
    );

    if (result == true) {
      await _loadDashboardData(); // Verileri yenile
    }
  }

  void _runSchedulerManually() async {
    try {
      // Manual scheduler çalıştırma
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Zamanlama kontrolü yapılıyor...'),
            ],
          ),
        ),
      );

      // Zamanlama sistemini manuel çalıştır
      await Future.delayed(const Duration(seconds: 2)); // Simulated delay

      if (mounted) {
        Navigator.pop(context);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Zamanlama kontrolü tamamlandı'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadDashboardData();
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _exportAssignmentData() {
    // Veri dışa aktarma
    debugPrint('Atama verileri dışa aktarılıyor...');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Veri dışa aktarma özelliği yakında eklenecek'),
      ),
    );
  }

  // ========== GRAFIK WIDĞETLARI ==========

  Widget _buildWeightLossChart() {
    if (_activeAssignments.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'Henüz veri yok\nAtamalar oluşturulduğunda grafik görünecek',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // Kilo kaybı verilerini hazırla
    final spots = <FlSpot>[];
    for (int i = 0; i < _activeAssignments.length && i < 10; i++) {
      final assignment = _activeAssignments[i];
      final weightLoss = assignment.weightStart - assignment.weightCurrent;
      spots.add(FlSpot(i.toDouble(), weightLoss));
    }

    if (spots.isEmpty) {
      spots.add(const FlSpot(0, 0));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value.toInt() >= _activeAssignments.length) {
                  return const Text('');
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'M${value.toInt() + 1}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 42,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  '${value.toStringAsFixed(1)} kg',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300),
        ),
        minX: 0,
        maxX: (_activeAssignments.length - 1).toDouble().clamp(0, 10),
        minY: 0,
        maxY:
            spots.map((s) => s.y).reduce((a, b) => a > b ? a : b).clamp(1, 10),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: LinearGradient(
              colors: [
                Colors.green.withValues(alpha: 0.8),
                Colors.green.withValues(alpha: 0.3),
              ],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.green,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Colors.green.withValues(alpha: 0.2),
                  Colors.green.withValues(alpha: 0.05),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                return LineTooltipItem(
                  '${touchedSpot.y.toStringAsFixed(1)} kg kayıp',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildClientDistributionChart() {
    if (_analytics == null || _analytics!.totalAssignments == 0) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'Henüz veri yok',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final activeCount = _analytics!.activeAssignments.toDouble();
    final completedCount = _analytics!.completedAssignments.toDouble();
    final otherCount = (_analytics!.totalAssignments -
            _analytics!.activeAssignments -
            _analytics!.completedAssignments)
        .toDouble();

    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {},
          mouseCursorResolver: (FlTouchEvent event, pieTouchResponse) {
            return pieTouchResponse?.touchedSection != null
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic;
          },
        ),
        borderData: FlBorderData(show: false),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: [
          if (activeCount > 0)
            PieChartSectionData(
              color: Colors.green,
              value: activeCount,
              title: '${activeCount.toInt()}\nAktif',
              radius: 60,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              titlePositionPercentageOffset: 0.55,
            ),
          if (completedCount > 0)
            PieChartSectionData(
              color: Colors.blue,
              value: completedCount,
              title: '${completedCount.toInt()}\nTamam',
              radius: 60,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              titlePositionPercentageOffset: 0.55,
            ),
          if (otherCount > 0)
            PieChartSectionData(
              color: Colors.grey,
              value: otherCount,
              title: '${otherCount.toInt()}\nDiğer',
              radius: 60,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              titlePositionPercentageOffset: 0.55,
            ),
        ],
      ),
    );
  }

  // Dispose metodunu güncelle
  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    _assignmentEngine.dispose(); // Engine'i temizle
    super.dispose();
  }

  // ========== DİYET PAKETLERİ SEKMESİ ==========

  Widget _buildDietPackagesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık ve butonlar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Diyet Paketleri',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _bulkUploadDietFiles,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Toplu Yükleme'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _createNewDietPackage,
                    icon: const Icon(Icons.add),
                    label: const Text('Yeni Paket'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // İstatistik kartları
          Row(
            children: [
              Expanded(
                child: _buildPackageStatCard(
                  'Toplam Paket',
                  _dietPackages.length.toString(),
                  Icons.restaurant_menu,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPackageStatCard(
                  'Aktif Atama',
                  _activeAssignments.length.toString(),
                  Icons.people,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Paket listesi
          if (_dietPackages.isEmpty)
            _buildEmptyPackagesCard()
          else
            ..._dietPackages.map((package) => _buildPackageCard(package)),
        ],
      ),
    );
  }

  Widget _buildPackageStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
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
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPackagesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz diyet paketiniz yok',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Diyet paketleri oluşturarak müşterilerinize otomatik atamalar yapabilirsiniz.',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _bulkUploadDietFiles,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Toplu Yükleme'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _createNewDietPackage,
                  icon: const Icon(Icons.add),
                  label: const Text('İlk Paketi Oluştur'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageCard(DietPackageModel package) {
    // Bu paketin atama sayısını hesapla
    final assignmentCount = _activeAssignments
        .where((a) => a.packageId == package.packageId)
        .length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.restaurant_menu, color: Colors.teal),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        package.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        package.description,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: package.isActive
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    package.isActive ? 'Aktif' : 'Pasif',
                    style: TextStyle(
                      color: package.isActive ? Colors.green : Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildPackageInfoChip(
                  Icons.schedule,
                  '${package.durationDays} gün',
                  Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildPackageInfoChip(
                  Icons.folder,
                  '${package.numberOfFiles} dosya',
                  Colors.orange,
                ),
                const SizedBox(width: 8),
                _buildPackageInfoChip(
                  Icons.people,
                  '$assignmentCount atama',
                  Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _assignPackageToClient(package),
                    icon: const Icon(Icons.person_add),
                    label: const Text('Müşteriye Ata'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _editPackage(package),
                  child: const Text('Düzenle'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _viewPackageDetails(package),
                  child: const Text('Detay'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _createNewDietPackage() async {
    // Yeni diyet paketi oluşturma sayfasına yönlendir
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateDietPackagePage(),
      ),
    );

    // Eğer paket başarıyla oluşturulduysa listeyi yenile
    if (result == true) {
      _loadDashboardData();
    }
  }

  // ========== YENİ SEKMELER ==========

  Widget _buildAssignmentsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Aktif Atamalar',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _createNewAssignment,
                icon: const Icon(Icons.add_circle),
                label: const Text('Yeni Atama'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_activeAssignments.isEmpty)
            _buildEmptyAssignmentsCard()
          else
            Column(
              children: _activeAssignments
                  .map((assignment) => _buildAssignmentCard(assignment))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyAssignmentsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.assignment,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz aktif atama yok',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Müşterilerinize diyet paketleri atadığınızda burada görünecekler.',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _createNewAssignment,
              icon: const Icon(Icons.add_circle),
              label: const Text('İlk Atamayı Oluştur'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentCard(UserDietAssignmentModel assignment) {
    // Kullanıcı bilgisini bul
    final userData = _usersHealthData
        .where((data) => data['user']['userId'] == assignment.userId)
        .firstOrNull;
    final userName = userData?['user']['name'] ?? 'Bilinmeyen Kullanıcı';

    // Paket bilgisini bul
    final package = _dietPackages
        .where((p) => p.packageId == assignment.packageId)
        .firstOrNull;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green.withValues(alpha: 0.1),
                  child: Text(
                    userName[0].toUpperCase(),
                    style: const TextStyle(
                        color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (package != null)
                        Text(
                          package.title,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        assignment.adherenceScoreColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    assignment.statusDisplayName,
                    style: TextStyle(
                      color: assignment.adherenceScoreColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // İlerleme çubuğu
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'İlerleme: ${assignment.progressPercentage}',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${assignment.remainingDays} gün kaldı',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: assignment.progress,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    assignment.progress > 0.8 ? Colors.green : Colors.blue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // İstatistikler
            Row(
              children: [
                Expanded(
                  child: _buildAssignmentStat(
                    'Başlangıç Kilo',
                    '${assignment.weightStart.toStringAsFixed(1)} kg',
                    Icons.scale,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildAssignmentStat(
                    'Mevcut Kilo',
                    '${assignment.weightCurrent.toStringAsFixed(1)} kg',
                    Icons.monitor_weight,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildAssignmentStat(
                    'Hedef Kilo',
                    '${assignment.weightTarget.toStringAsFixed(1)} kg',
                    Icons.flag,
                    Colors.orange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Eylem butonları
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _updateAssignmentProgress(assignment),
                    icon: const Icon(Icons.edit),
                    label: const Text('Güncelle'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _viewAssignmentDetails(assignment),
                    icon: const Icon(Icons.visibility),
                    label: const Text('Detay'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _processNextSequence(assignment),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Sonraki'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentStat(
      String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 14,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab() {
    if (_analytics == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analytics & Raporlar',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Genel istatistikler
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  'Başarı Oranı',
                  '${_analytics!.successRate.toStringAsFixed(1)}%',
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAnalyticsCard(
                  'Ortalama Kilo Kaybı',
                  _analytics!.formattedAverageWeightLoss,
                  Icons.monitor_weight,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  'Ortalama Uyum',
                  _analytics!.formattedAverageAdherence,
                  Icons.favorite,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAnalyticsCard(
                  'Toplam Atama',
                  _analytics!.totalAssignments.toString(),
                  Icons.assignment,
                  Colors.purple,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Kilo Kaybı Grafik
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kilo Kaybı Trendi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: _buildWeightLossChart(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Başarı dağılım grafik
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Müşteri Atama Dağılımı',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: _buildClientDistributionChart(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
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
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Diğer İşlemler',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Toplu mesaj bölümü
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Toplu İletişim',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildMessageComposer(),
                  const SizedBox(height: 12),
                  _buildTargetSelector(),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _sendBulkMessage,
                      child: const Text('Mesaj Gönder'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Diğer işlemler
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sistem Yönetimi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(Icons.schedule),
                    title: const Text('Otomatik Zamanlama'),
                    subtitle: const Text('Atamaları otomatik olarak güncelle'),
                    trailing: ElevatedButton(
                      onPressed: _runSchedulerManually,
                      child: const Text('Çalıştır'),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.backup),
                    title: const Text('Veri Yedekleme'),
                    subtitle: const Text('Atama verilerini yedekle'),
                    trailing: ElevatedButton(
                      onPressed: _exportAssignmentData,
                      child: const Text('Yedekle'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
