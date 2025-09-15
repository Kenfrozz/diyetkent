import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/google_backup_widget.dart';
import '../services/google_backup_service.dart';
import '../services/auto_backup_service.dart';

/// Google Backup yönetim sayfası
/// Kullanıcı buradan tüm yedekleme işlemlerini yönetebilir
class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _debugInfo;

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  /// Debug bilgilerini yükle
  Future<void> _loadDebugInfo() async {
    setState(() => _isLoading = true);

    try {
      final debugInfo = await AutoBackupService.getDebugInfo();
      setState(() {
        _debugInfo = debugInfo;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Debug info yükleme hatası: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Sayfayı yenile
  Future<void> _refreshPage() async {
    await _loadDebugInfo();
  }

  /// Test yedeklemesi
  Future<void> _performTestBackup() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test yedeklemesi başlatılıyor...'),
        backgroundColor: Colors.blue,
      ),
    );

    try {
      await AutoBackupService.triggerManualAutoBackup();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test yedeklemesi tamamlandı!'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadDebugInfo();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test yedekleme hatası: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yedekleme ve Geri Yükleme'),
        backgroundColor: const Color(0xFF00796B),
        actions: [
          IconButton(
            onPressed: _refreshPage,
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshPage,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ana Yedekleme Widget'ı
                    const GoogleBackupWidget(),

                    const SizedBox(height: 24),

                    // Bilgi Kartları
                    _buildInfoSection(),

                    const SizedBox(height: 24),

                    // Gelişmiş Ayarlar
                    _buildAdvancedSettings(),

                    const SizedBox(height: 24),

                    // Debug Bilgileri (sadece debug modda)
                    if (_debugInfo != null) _buildDebugSection(),
                  ],
                ),
              ),
            ),
    );
  }

  /// Bilgi kartları bölümü
  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Yedekleme Hakkında',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF00796B),
          ),
        ),
        const SizedBox(height: 16),

        // Güvenlik kartı
        Card(
          child: ListTile(
            leading: const Icon(Icons.security, color: Color(0xFF00796B), size: 32),
            title: const Text('256-bit AES Şifreleme'),
            subtitle: const Text(
              'Verileriniz telefonunuzdan çıkmadan önce şifrelenir. '
              'Google bile verilerinizi okuyamaz.'
            ),
            trailing: const Icon(Icons.verified_user, color: Colors.green),
          ),
        ),

        const SizedBox(height: 8),

        // Otomatik yedekleme kartı
        Card(
          child: ListTile(
            leading: const Icon(Icons.schedule, color: Color(0xFF00796B), size: 32),
            title: const Text('Akıllı Otomatik Yedekleme'),
            subtitle: const Text(
              'Her gece saat 03:00\'da WiFi bağlantısı varsa ve '
              'batarya yeterli ise otomatik yedek alınır.'
            ),
            trailing: const Icon(Icons.wifi, color: Colors.blue),
          ),
        ),

        const SizedBox(height: 8),

        // Ücretsiz depolama kartı
        Card(
          child: ListTile(
            leading: const Icon(Icons.cloud_circle, color: Color(0xFF00796B), size: 32),
            title: const Text('15 GB Ücretsiz Depolama'),
            subtitle: const Text(
              'Google Drive\'ın ücretsiz 15 GB alanını kullanır. '
              'DiyetKent verileri genelde 1-5 MB yer kaplar.'
            ),
            trailing: const Icon(Icons.free_cancellation, color: Colors.green),
          ),
        ),
      ],
    );
  }

  /// Gelişmiş ayarlar bölümü
  Widget _buildAdvancedSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gelişmiş Ayarlar',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF00796B),
          ),
        ),
        const SizedBox(height: 16),

        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.bug_report, color: Colors.orange),
                title: const Text('Test Yedeklemesi'),
                subtitle: const Text('Anında test yedeklemesi başlat'),
                trailing: ElevatedButton(
                  onPressed: _performTestBackup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Test Et'),
                ),
              ),

              const Divider(height: 1),

              ListTile(
                leading: const Icon(Icons.history, color: Colors.blue),
                title: const Text('Yedekleme Geçmişi'),
                subtitle: const Text('Yedekleme log\'larını görüntüle'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  _showBackupHistory();
                },
              ),

              const Divider(height: 1),

              ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.grey),
                title: const Text('Yedeklenen Veriler'),
                subtitle: const Text('Hangi veriler yedekleniyor?'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  _showDataTypesDialog();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Debug bilgileri bölümü
  Widget _buildDebugSection() {
    if (_debugInfo == null) return const SizedBox.shrink();

    final serviceStatus = _debugInfo!['service_status'] as Map<String, dynamic>;
    final conditions = _debugInfo!['conditions'] as Map<String, dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sistem Durumu',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),

        Card(
          color: Colors.grey.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDebugRow('Servis Durumu', serviceStatus['isInitialized'] ? 'Aktif' : 'Pasif'),
                _buildDebugRow('Yedekleme Durumu', serviceStatus['isBackingUp'] ? 'Çalışıyor' : 'Boşta'),
                _buildDebugRow('Zamanlayıcı', serviceStatus['hasActiveTimer'] ? 'Aktif' : 'Pasif'),

                const Divider(),

                _buildDebugRow('Google Bağlantısı', conditions['google_connected'] ? 'Bağlı' : 'Bağlı Değil'),
                _buildDebugRow('Otomatik Yedekleme', conditions['auto_backup_enabled'] ? 'Açık' : 'Kapalı'),
                _buildDebugRow('WiFi Durumu', conditions['wifi_available'] ? 'Bağlı' : 'Bağlı Değil'),

                if (conditions['last_backup'] != null)
                  _buildDebugRow(
                    'Son Yedekleme',
                    _formatDebugDate(DateTime.parse(conditions['last_backup']))
                  ),

                if (conditions['hours_since_backup'] != null)
                  _buildDebugRow(
                    'Son Yedeklemeden Beri',
                    '${conditions['hours_since_backup']} saat'
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Debug row oluştur
  Widget _buildDebugRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// Debug tarih formatı
  String _formatDebugDate(DateTime date) {
    return DateFormat('dd.MM.yyyy HH:mm').format(date);
  }

  /// Yedekleme geçmişini göster
  void _showBackupHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📋 Yedekleme Geçmişi'),
        content: FutureBuilder<DateTime?>(
          future: GoogleBackupService.getLastBackupTime(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Text('Henüz yedek alınmamış.');
            }

            final lastBackup = snapshot.data!;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Son Yedekleme:'),
                Text(
                  DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR').format(lastBackup),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  'Gelecekte burada tüm yedekleme geçmişi gösterilecek.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            );
          },
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

  /// Yedeklenen veri türleri dialog'u
  void _showDataTypesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📦 Yedeklenen Veriler'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DataTypeItem(
                icon: Icons.chat,
                title: 'Sohbetler',
                description: 'Tüm bireysel ve grup sohbetleriniz',
                included: true,
              ),
              _DataTypeItem(
                icon: Icons.message,
                title: 'Mesajlar',
                description: 'Metin mesajları ve reply referansları',
                included: true,
              ),
              _DataTypeItem(
                icon: Icons.contacts,
                title: 'Kişiler',
                description: 'Telefon rehberi ve DiyetKent kullanıcıları',
                included: true,
              ),
              _DataTypeItem(
                icon: Icons.local_hospital,
                title: 'Sağlık Verileri',
                description: 'BMI, kilo takibi, sağlık profili',
                included: true,
              ),
              _DataTypeItem(
                icon: Icons.label,
                title: 'Etiketler',
                description: 'Oluşturduğunuz etiketler ve kategoriler',
                included: true,
              ),
              _DataTypeItem(
                icon: Icons.settings,
                title: 'Ayarlar',
                description: 'Uygulama ayarları ve tercihler',
                included: true,
              ),
              Divider(),
              _DataTypeItem(
                icon: Icons.image,
                title: 'Medya Dosyaları',
                description: 'Fotoğraf, video ve ses dosyaları',
                included: false,
                note: 'Medya dosyaları yerel olarak saklanır',
              ),
              _DataTypeItem(
                icon: Icons.call,
                title: 'Arama Kayıtları',
                description: 'Sesli ve görüntülü arama geçmişi',
                included: false,
                note: 'Gelecek sürümde eklenecek',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anladım'),
          ),
        ],
      ),
    );
  }
}

/// Veri türü öğesi widget'ı
class _DataTypeItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool included;
  final String? note;

  const _DataTypeItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.included,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: included ? const Color(0xFF00796B) : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: included ? Colors.black : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      included ? Icons.check_circle : Icons.cancel,
                      size: 16,
                      color: included ? Colors.green : Colors.red,
                    ),
                  ],
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (note != null)
                  Text(
                    note!,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}