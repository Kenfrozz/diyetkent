import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import '../services/google_backup_service.dart';

/// Google Backup ayarları widget'ı
/// Ayarlar sayfasında kullanılacak
class GoogleBackupWidget extends StatefulWidget {
  const GoogleBackupWidget({super.key});

  @override
  State<GoogleBackupWidget> createState() => _GoogleBackupWidgetState();
}

class _GoogleBackupWidgetState extends State<GoogleBackupWidget> {
  GoogleSignInAccount? _currentUser;
  DateTime? _lastBackupTime;
  bool _autoBackupEnabled = false;
  bool _isLoading = false;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _loadBackupStatus();
  }

  /// Yedekleme durumunu yükle
  Future<void> _loadBackupStatus() async {
    setState(() => _isLoading = true);

    try {
      _currentUser = await GoogleBackupService.getCurrentUser();
      _isConnected = await GoogleBackupService.isGoogleConnected();
      _lastBackupTime = await GoogleBackupService.getLastBackupTime();
      _autoBackupEnabled = await GoogleBackupService.isAutoBackupEnabled();
    } catch (e) {
      debugPrint('❌ Backup status yükleme hatası: $e');
    }

    setState(() => _isLoading = false);
  }

  /// Google hesabına bağlan
  Future<void> _connectToGoogle() async {
    setState(() => _isLoading = true);

    try {
      final account = await GoogleBackupService.signInToGoogle();
      if (account != null) {
        setState(() {
          _currentUser = account;
          _isConnected = true;
        });

        // Bağlantı sonrası ilk yedekleme seçeneği sun
        _showFirstBackupDialog();
      } else {
        _showErrorSnackBar('Google bağlantısı başarısız oldu');
      }
    } catch (e) {
      _showErrorSnackBar('Bağlantı hatası: $e');
    }

    setState(() => _isLoading = false);
  }

  /// Google bağlantısını kes
  Future<void> _disconnectGoogle() async {
    final confirm = await _showDisconnectConfirmDialog();
    if (!confirm) return;

    setState(() => _isLoading = true);

    try {
      await GoogleBackupService.signOutFromGoogle();
      setState(() {
        _currentUser = null;
        _isConnected = false;
        _lastBackupTime = null;
        _autoBackupEnabled = false;
      });

      _showSuccessSnackBar('Google bağlantısı kesildi');
    } catch (e) {
      _showErrorSnackBar('Bağlantı kesme hatası: $e');
    }

    setState(() => _isLoading = false);
  }

  /// Manuel yedekleme
  Future<void> _manualBackup() async {
    if (!_isConnected) {
      _showErrorSnackBar('Önce Google hesabınızı bağlayın');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await GoogleBackupService.createBackup();

      if (result.success) {
        setState(() {
          _lastBackupTime = DateTime.now();
        });

        final sizeKB = (result.backupSize! / 1024).toStringAsFixed(1);
        final durationSeconds = result.duration!.inSeconds;

        _showSuccessSnackBar('Yedekleme başarılı! ($sizeKB KB, $durationSeconds s)');
      } else {
        _showErrorSnackBar('Yedekleme hatası: ${result.error}');
      }
    } catch (e) {
      _showErrorSnackBar('Yedekleme hatası: $e');
    }

    setState(() => _isLoading = false);
  }

  /// Yedeği geri yükle
  Future<void> _restoreBackup() async {
    if (!_isConnected) {
      _showErrorSnackBar('Önce Google hesabınızı bağlayın');
      return;
    }

    final confirm = await _showRestoreConfirmDialog();
    if (!confirm) return;

    setState(() => _isLoading = true);

    try {
      final result = await GoogleBackupService.restoreBackup();

      if (result.success) {
        _showSuccessSnackBar(
          'Geri yükleme başarılı! ${result.restoredItemCount} öğe geri yüklendi'
        );
      } else {
        _showErrorSnackBar('Geri yükleme hatası: ${result.error}');
      }
    } catch (e) {
      _showErrorSnackBar('Geri yükleme hatası: $e');
    }

    setState(() => _isLoading = false);
  }

  /// Otomatik yedeklemeyi aç/kapat
  Future<void> _toggleAutoBackup(bool enabled) async {
    if (!_isConnected && enabled) {
      _showErrorSnackBar('Önce Google hesabınızı bağlayın');
      return;
    }

    setState(() => _autoBackupEnabled = enabled);
    await GoogleBackupService.setAutoBackupEnabled(enabled);

    final message = enabled ? 'Otomatik yedekleme açıldı' : 'Otomatik yedekleme kapatıldı';
    _showSuccessSnackBar(message);
  }

  /// İlk yedekleme dialog'u
  Future<void> _showFirstBackupDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Google Hesabı Bağlandı!'),
        content: const Text(
          'Şimdi ilk yedeklemenizi oluşturmak ister misiniz? '
          'Bu işlem birkaç saniye sürecektir.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Şimdi Değil'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _manualBackup();
            },
            child: const Text('Hemen Yedekle'),
          ),
        ],
      ),
    );
  }

  /// Bağlantı kesme onayı
  Future<bool> _showDisconnectConfirmDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Bağlantıyı Kes'),
        content: const Text(
          'Google hesabı bağlantısını kesmek istediğinizden emin misiniz? '
          'Otomatik yedekleme devre dışı kalacak.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Bağlantıyı Kes'),
          ),
        ],
      ),
    ) ?? false;
  }

  /// Geri yükleme onayı
  Future<bool> _showRestoreConfirmDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Yedeği Geri Yükle'),
        content: const Text(
          'Bu işlem mevcut verilerinizin üzerine yazacak. '
          'Devam etmek istediğinizden emin misiniz?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Geri Yükle'),
          ),
        ],
      ),
    ) ?? false;
  }

  /// Başarı mesajı
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Hata mesajı
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Tarih formatla
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dakika önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} saat önce';
    } else if (difference.inDays == 1) {
      return 'Dün ${DateFormat.Hm().format(date)}';
    } else {
      return DateFormat('dd.MM.yyyy HH:mm').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Column(
        children: [
          // Başlık
          ListTile(
            leading: const Icon(Icons.cloud_upload, color: Color(0xFF00796B), size: 32),
            title: const Text(
              'Google Yedekleme',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            subtitle: _isConnected && _currentUser != null
                ? Text('Bağlı: ${_currentUser!.email}')
                : const Text('Bağlantı yok • Verilerinizi güvende tutun'),
            trailing: _isConnected
                ? TextButton(
                    onPressed: _disconnectGoogle,
                    child: const Text('Bağlantıyı Kes', style: TextStyle(color: Colors.red)),
                  )
                : ElevatedButton.icon(
                    onPressed: _connectToGoogle,
                    icon: const Icon(Icons.link, size: 18),
                    label: const Text('Google\'a Bağlan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00796B),
                      foregroundColor: Colors.white,
                    ),
                  ),
          ),

          if (_isConnected) ...[
            const Divider(height: 1),

            // Manuel Yedekleme
            ListTile(
              leading: const Icon(Icons.backup, color: Color(0xFF00796B)),
              title: const Text('Şimdi Yedekle'),
              subtitle: _lastBackupTime != null
                  ? Text('Son yedek: ${_formatDate(_lastBackupTime!)}')
                  : const Text('Henüz yedek alınmamış'),
              trailing: IconButton(
                onPressed: _manualBackup,
                icon: const Icon(Icons.play_arrow),
                tooltip: 'Manuel yedekleme başlat',
              ),
            ),

            // Otomatik Yedekleme
            SwitchListTile(
              secondary: const Icon(Icons.schedule, color: Color(0xFF00796B)),
              title: const Text('Otomatik Yedekleme'),
              subtitle: const Text('Her gece WiFi\'da otomatik yedekle'),
              value: _autoBackupEnabled,
              onChanged: _toggleAutoBackup,
              activeColor: const Color(0xFF00796B),
            ),

            // Geri Yükleme
            ListTile(
              leading: const Icon(Icons.restore, color: Colors.orange),
              title: const Text('Yedeği Geri Yükle'),
              subtitle: const Text('Google Drive\'dan veriyi geri yükle'),
              trailing: IconButton(
                onPressed: _restoreBackup,
                icon: const Icon(Icons.download),
                tooltip: 'Yedeği geri yükle',
              ),
            ),
          ],

          if (!_isConnected)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(
                    Icons.cloud_off,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Google Yedekleme Kapalı',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Verilerinizi güvende tutmak için Google Drive yedeklemesini açın. '
                    'Telefonunuz kaybolsa bile tüm sohbetlerinizi kurtarabilirsiniz.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.security, size: 16, color: Color(0xFF00796B)),
                      const SizedBox(width: 4),
                      const Expanded(
                        child: Text(
                          '256-bit şifreleme ile güvenli',
                          style: TextStyle(fontSize: 12, color: Color(0xFF00796B)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.wifi, size: 16, color: Color(0xFF00796B)),
                      const SizedBox(width: 4),
                      const Expanded(
                        child: Text(
                          'Sadece WiFi\'da yedekleme',
                          style: TextStyle(fontSize: 12, color: Color(0xFF00796B)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.drive_folder_upload, size: 16, color: Color(0xFF00796B)),
                      const SizedBox(width: 4),
                      const Expanded(
                        child: Text(
                          '15 GB Google Drive ücretsiz',
                          style: TextStyle(fontSize: 12, color: Color(0xFF00796B)),
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
  }
}

/// Ana sayfada gösterilecek basit yedekleme durumu widget'ı
class BackupStatusWidget extends StatelessWidget {
  const BackupStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getBackupStatus(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!;
        final isConnected = data['connected'] as bool;
        final lastBackup = data['lastBackup'] as DateTime?;

        if (!isConnected) {
          return Container(
            margin: const EdgeInsets.all(8.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.cloud_off, color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Yedekleme kapalı',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/settings'),
                  child: const Text('Aç', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.all(8.0),
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_done, color: Colors.green.shade700, size: 16),
              const SizedBox(width: 4),
              Text(
                lastBackup != null
                    ? 'Son yedek: ${_formatShortDate(lastBackup)}'
                    : 'Yedekleme açık',
                style: const TextStyle(fontSize: 12, color: Colors.green),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getBackupStatus() async {
    final isConnected = await GoogleBackupService.isGoogleConnected();
    final lastBackup = await GoogleBackupService.getLastBackupTime();

    return {
      'connected': isConnected,
      'lastBackup': lastBackup,
    };
  }

  String _formatShortDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}dk önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}sa önce';
    } else if (difference.inDays == 1) {
      return 'Dün';
    } else {
      return '${difference.inDays} gün önce';
    }
  }
}