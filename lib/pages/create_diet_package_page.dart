import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/diet_package_model.dart';
import '../services/diet_package_service.dart';

class CreateDietPackagePage extends StatefulWidget {
  const CreateDietPackagePage({super.key});

  @override
  State<CreateDietPackagePage> createState() => _CreateDietPackagePageState();
}

class _CreateDietPackagePageState extends State<CreateDietPackagePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  
  DietPackageType _selectedType = DietPackageType.weightLoss;
  bool _isPublic = false;
  bool _isLoading = false;
  
  // Paket parametreleri
  int _numberOfFiles = 4; // varsayılan 4 dosya
  int _daysPerFile = 7;   // varsayılan 7 gün
  double _weightChangePerFile = -2.0; // varsayılan -2kg

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // Toplam süre hesaplama
  int get _totalDuration => _numberOfFiles * _daysPerFile;
  
  // Toplam hedef kilo değişimi
  double get _totalWeightChange => _numberOfFiles * _weightChangePerFile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Diyet Paketi'),
        elevation: 0,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Temel bilgiler
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              
              // Paket parametreleri
              _buildParametersSection(),
              const SizedBox(height: 24),
              
              // Kaydet butonu
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Temel Bilgiler',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Paket adı
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Paket Adı *',
                hintText: '1 Aylık Kilo Verme Paketi',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Paket adı gerekli';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Açıklama
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Açıklama *',
                hintText: 'Bu paket ile 1 ayda sağlıklı şekilde kilo verebilirsiniz...',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Açıklama gerekli';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Tür ve fiyat
            Row(
              children: [
                // Paket türü
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<DietPackageType>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Paket Türü',
                      border: OutlineInputBorder(),
                    ),
                    items: DietPackageType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(_getTypeDisplayName(type)),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedType = value!),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Fiyat
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Fiyat (₺)',
                      hintText: '0',
                      border: OutlineInputBorder(),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Public checkbox
            CheckboxListTile(
              title: const Text('Herkese Açık Paket'),
              subtitle: const Text('Diğer diyetisyenler bu paketi görebilir'),
              value: _isPublic,
              onChanged: (value) => setState(() => _isPublic = value ?? false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParametersSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paket Parametreleri',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Dosya sayısı
            Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Kaç dosya olsun?',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _numberOfFiles,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(8, (index) => index + 1)
                        .map((number) => DropdownMenuItem(
                              value: number,
                              child: Text('$number dosya'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _numberOfFiles = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Her dosyanın süresi
            Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Her dosya kaç gün sürsün?',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _daysPerFile,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: [3, 5, 7, 10, 14]
                        .map((days) => DropdownMenuItem(
                              value: days,
                              child: Text('$days gün'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _daysPerFile = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Kilo değişimi
            Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Her dosyada hedef kilo değişimi:',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    initialValue: _weightChangePerFile.toString(),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      suffixText: 'kg',
                      hintText: '-2.0',
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
                    ],
                    onChanged: (value) {
                      final newValue = double.tryParse(value) ?? _weightChangePerFile;
                      setState(() {
                        _weightChangePerFile = newValue;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Özet bilgi
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.teal.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.teal.shade600),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Paket Özeti',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade800,
                          ),
                        ),
                        Text(
                          '$_numberOfFiles dosya • $_totalDuration gün • ${_totalWeightChange.toStringAsFixed(1)} kg hedef',
                          style: TextStyle(color: Colors.teal.shade700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _savePackage,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Paketi Oluştur',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  String _getTypeDisplayName(DietPackageType type) {
    switch (type) {
      case DietPackageType.weightLoss: return 'Kilo Verme';
      case DietPackageType.weightGain: return 'Kilo Alma';
      case DietPackageType.maintenance: return 'Koruma';
      case DietPackageType.diabetic: return 'Diyabet';
      case DietPackageType.sports: return 'Spor';
      case DietPackageType.custom: return 'Özel';
    }
  }

  Future<void> _savePackage() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final package = DietPackageModel.create(
        packageId: '', // Service tarafından otomatik atanacak
        dietitianId: '', // Service tarafından otomatik atanacak
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        durationDays: _totalDuration,
        price: double.tryParse(_priceController.text) ?? 0.0,
        numberOfFiles: _numberOfFiles,
        daysPerFile: _daysPerFile,
        targetWeightChangePerFile: _weightChangePerFile,
        isPublic: _isPublic,
      );

      final success = await DietPackageService.createDietPackage(package);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Diyet paketi başarıyla oluşturuldu!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true); // Başarılı olduğunu belirt
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Paket oluşturulurken hata oluştu'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}