import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/bulk_diet_upload_service.dart';
import '../services/auth_service.dart';

class BulkDietUploadPage extends StatefulWidget {
  const BulkDietUploadPage({super.key});

  @override
  State<BulkDietUploadPage> createState() => _BulkDietUploadPageState();
}

class _BulkDietUploadPageState extends State<BulkDietUploadPage> {
  String? _selectedFolderPath;
  Map<String, dynamic>? _folderAnalysis;
  bool _isAnalyzing = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  final List<String> _uploadLogs = [];
  final BulkDietUploadService _uploadService = BulkDietUploadService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Toplu Diyet Paketi Yükleme'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInstructionsCard(),
            const SizedBox(height: 20),
            _buildFolderSelectionSection(),
            if (_folderAnalysis != null) ...[
              const SizedBox(height: 20),
              _buildAnalysisSection(),
            ],
            if (_isUploading) ...[
              const SizedBox(height: 20),
              _buildUploadProgressSection(),
            ],
            if (_uploadLogs.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildUploadLogsSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Klasör Yapısı Rehberi',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Doğru klasör yapısı:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Text(
                '''Paket Adı/
├── Diyet1/
│   ├── 21_25bmi/
│   │   └── diyet_dosyasi.docx
│   ├── 26_29bmi/
│   │   └── diyet_dosyasi.docx
│   └── ...
├── Diyet2/
│   └── ...
└── ...''',
                style: TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.folder, color: Colors.orange[700], size: 16),
                const SizedBox(width: 4),
                const Text('Ana klasör → Paket adı', style: TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.folder_open, color: Colors.blue[700], size: 16),
                const SizedBox(width: 4),
                const Text('Alt klasörler → Diyet türleri', style: TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.folder_special, color: Colors.green[700], size: 16),
                const SizedBox(width: 4),
                const Text('BMI klasörleri → 21_25bmi, 26_29bmi, 30_33bmi, 34_37bmi', style: TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderSelectionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Klasör Seçimi',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_selectedFolderPath != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.folder, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Seçilen Klasör:',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            _selectedFolderPath!,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isAnalyzing || _isUploading ? null : _selectFolder,
                    icon: const Icon(Icons.folder_open),
                    label: Text(_selectedFolderPath == null ? 'Klasör Seç' : 'Farklı Klasör Seç'),
                  ),
                ),
                if (_selectedFolderPath != null) ...[
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isAnalyzing || _isUploading ? null : _analyzeFolder,
                    icon: _isAnalyzing 
                      ? const SizedBox(
                          width: 16, 
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.analytics),
                    label: Text(_isAnalyzing ? 'Analiz Ediliyor...' : 'Analiz Et'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisSection() {
    final analysis = _folderAnalysis!;
    final isValid = analysis['isValid'] == true;
    final packages = analysis['packages'] as List<Map<String, dynamic>>? ?? [];
    final errors = analysis['errors'] as List<String>? ?? [];
    final warnings = analysis['warnings'] as List<String>? ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isValid ? Icons.check_circle : Icons.error,
                  color: isValid ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Analiz Sonucu',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isValid ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isValid ? Colors.green[200]! : Colors.red[200]!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isValid ? 'Klasör yapısı doğru! ✓' : 'Klasör yapısında hatalar var! ✗',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isValid ? Colors.green[800] : Colors.red[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('${packages.length} paket bulundu'),
                  Text('${analysis['totalDiets'] ?? 0} diyet türü'),
                  Text('${analysis['totalFiles'] ?? 0} dosya'),
                ],
              ),
            ),

            // Packages
            if (packages.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Bulunan Paketler:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...packages.map((package) => _buildPackageCard(package)),
            ],

            // Errors
            if (errors.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildMessageList('Hatalar', errors, Icons.error, Colors.red),
            ],

            // Warnings
            if (warnings.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildMessageList('Uyarılar', warnings, Icons.warning, Colors.orange),
            ],

            // Upload button
            if (isValid) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isUploading ? null : _startUpload,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Paketleri Yükle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPackageCard(Map<String, dynamic> package) {
    final diets = package['diets'] as List<Map<String, dynamic>>? ?? [];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    package['name'] ?? 'Bilinmeyen Paket',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${diets.length} diyet türü'),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: diets.map((diet) {
                final bmiRanges = diet['bmiRanges'] as List<String>? ?? [];
                return Chip(
                  label: Text(
                    '${diet['name']} (${bmiRanges.length} BMI)',
                    style: const TextStyle(fontSize: 11),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(String title, List<String> messages, IconData icon, MaterialColor color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...messages.map((message) => Padding(
          padding: const EdgeInsets.only(left: 28, bottom: 4),
          child: Text(
            '• $message',
            style: TextStyle(color: color[700]),
          ),
        )),
      ],
    );
  }

  Widget _buildUploadProgressSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_upload, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Yükleme İlerliyor...',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text('${(_uploadProgress * 100).toStringAsFixed(0)}%'),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: _uploadProgress),
            const SizedBox(height: 8),
            if (_uploadLogs.isNotEmpty)
              Text(
                _uploadLogs.last,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadLogsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Yükleme Günlüğü',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              height: 200,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ListView.builder(
                itemCount: _uploadLogs.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      _uploadLogs[index],
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectFolder() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      
      if (selectedDirectory != null) {
        setState(() {
          _selectedFolderPath = selectedDirectory;
          _folderAnalysis = null;
          _uploadLogs.clear();
        });
      }
    } catch (e) {
      _showError('Klasör seçimi sırasında hata: $e');
    }
  }

  Future<void> _analyzeFolder() async {
    if (_selectedFolderPath == null) return;

    setState(() {
      _isAnalyzing = true;
      _folderAnalysis = null;
    });

    try {
      final analysis = await _uploadService.analyzeFolderStructure(_selectedFolderPath!);
      setState(() {
        _folderAnalysis = analysis;
      });
    } catch (e) {
      _showError('Klasör analizi sırasında hata: $e');
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  Future<void> _startUpload() async {
    if (_selectedFolderPath == null || _folderAnalysis == null) return;

    final currentUser = AuthService.currentUser;
    if (currentUser == null) {
      _showError('Giriş yapmış kullanıcı bulunamadı');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadLogs.clear();
    });

    try {
      await _uploadService.uploadBulkDietPackages(
        folderPath: _selectedFolderPath!,
        analysis: _folderAnalysis!,
        dietitianId: currentUser.uid,
        onProgress: (current, total, message) {
          setState(() {
            _uploadProgress = current / total;
            if (message.isNotEmpty) {
              _uploadLogs.add('${DateTime.now().toString().substring(11, 19)} - $message');
            }
          });
        },
      );

      _showSuccess('Tüm paketler başarıyla yüklendi!');
      
      // Clear the form
      setState(() {
        _selectedFolderPath = null;
        _folderAnalysis = null;
        _uploadProgress = 0.0;
      });

    } catch (e) {
      _showError('Yükleme sırasında hata: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}