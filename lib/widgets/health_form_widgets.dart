import 'package:flutter/material.dart';

// Health Condition Selector Widget
class HealthConditionSelector extends StatefulWidget {
  final List<String> selectedConditions;
  final void Function(List<String>) onChanged;
  final bool readOnly;
  
  const HealthConditionSelector({
    super.key,
    required this.selectedConditions,
    required this.onChanged,
    this.readOnly = false,
  });

  @override
  State<HealthConditionSelector> createState() => _HealthConditionSelectorState();
}

class _HealthConditionSelectorState extends State<HealthConditionSelector> {
  static const List<String> _commonConditions = [
    'Diabetes Mellitus (Şeker Hastalığı)',
    'Hipertansiyon (Yüksek Tansiyon)',
    'Hipotansiyon (Düşük Tansiyon)',
    'Kalp Hastalığı',
    'Tiroid Bozuklukları',
    'Böbrek Hastalığı',
    'Karaciğer Hastalığı',
    'Gastrointestinal Sorunlar',
    'Anemi',
    'Kolesterol Yüksekliği',
    'Astım',
    'Depresyon/Anksiyete',
    'Artrit',
    'Osteoporoz',
    'PCOS (Polikistik Over Sendromu)',
    'Diğer',
  ];
  
  final TextEditingController _customController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kronik Hastalıklarınız',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: const Color(0xFFE91D7C),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Mevcut sağlık durumlarınızı seçin:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),
        
        // Common conditions
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _commonConditions.map((condition) {
            final isSelected = widget.selectedConditions.contains(condition);
            return FilterChip(
              label: Text(
                condition,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: widget.readOnly ? null : (selected) {
                _toggleCondition(condition);
              },
              selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              checkmarkColor: Theme.of(context).primaryColor,
            );
          }).toList(),
        ),
        
        const SizedBox(height: 16),
        
        // Custom condition input
        if (!widget.readOnly) ...[
          TextField(
            controller: _customController,
            decoration: InputDecoration(
              labelText: 'Diğer sağlık durumu',
              hintText: 'Yukarıda bulunmayan bir durumunuz varsa yazın',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.add),
                onPressed: _addCustomCondition,
              ),
            ),
            onSubmitted: (_) => _addCustomCondition(),
          ),
        ],
        
        // Selected conditions summary
        if (widget.selectedConditions.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Seçili Durumlar (${widget.selectedConditions.length}):',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: widget.selectedConditions.map((condition) {
              return Chip(
                label: Text(
                  condition,
                  style: const TextStyle(fontSize: 12),
                ),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: widget.readOnly ? null : () => _removeCondition(condition),
                backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
  
  void _toggleCondition(String condition) {
    final newList = List<String>.from(widget.selectedConditions);
    if (newList.contains(condition)) {
      newList.remove(condition);
    } else {
      newList.add(condition);
    }
    widget.onChanged(newList);
  }
  
  void _removeCondition(String condition) {
    final newList = List<String>.from(widget.selectedConditions);
    newList.remove(condition);
    widget.onChanged(newList);
  }
  
  void _addCustomCondition() {
    final condition = _customController.text.trim();
    if (condition.isNotEmpty && !widget.selectedConditions.contains(condition)) {
      final newList = List<String>.from(widget.selectedConditions);
      newList.add(condition);
      widget.onChanged(newList);
      _customController.clear();
    }
  }
}

// Medication Input Widget
class MedicationInput extends StatefulWidget {
  final List<String> medications;
  final void Function(List<String>) onChanged;
  final bool readOnly;
  
  const MedicationInput({
    super.key,
    required this.medications,
    required this.onChanged,
    this.readOnly = false,
  });

  @override
  State<MedicationInput> createState() => _MedicationInputState();
}

class _MedicationInputState extends State<MedicationInput> {
  final TextEditingController _medicationController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _frequencyController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'İlaçlar',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Düzenli kullandığınız ilaçları ekleyin:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),
        
        // Current medications list
        if (widget.medications.isNotEmpty) ...[
          ...widget.medications.asMap().entries.map((entry) {
            final index = entry.key;
            final medication = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(medication),
                trailing: widget.readOnly ? null : IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeMedication(index),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
        ],
        
        // Add new medication form
        if (!widget.readOnly) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _medicationController,
                    decoration: const InputDecoration(
                      labelText: 'İlaç Adı *',
                      hintText: 'Örn: Aspirin',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _dosageController,
                          decoration: const InputDecoration(
                            labelText: 'Doz',
                            hintText: 'Örn: 100mg',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _frequencyController,
                          decoration: const InputDecoration(
                            labelText: 'Sıklık',
                            hintText: 'Örn: Günde 2 kez',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _addMedication,
                        icon: const Icon(Icons.add),
                        label: const Text('İlaç Ekle'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
  
  void _addMedication() {
    final name = _medicationController.text.trim();
    if (name.isEmpty) return;
    
    final dosage = _dosageController.text.trim();
    final frequency = _frequencyController.text.trim();
    
    String medicationInfo = name;
    if (dosage.isNotEmpty) medicationInfo += ' - $dosage';
    if (frequency.isNotEmpty) medicationInfo += ' ($frequency)';
    
    final newList = List<String>.from(widget.medications);
    newList.add(medicationInfo);
    widget.onChanged(newList);
    
    // Clear controllers
    _medicationController.clear();
    _dosageController.clear();
    _frequencyController.clear();
  }
  
  void _removeMedication(int index) {
    final newList = List<String>.from(widget.medications);
    newList.removeAt(index);
    widget.onChanged(newList);
  }
}

// Allergy Tags Widget
class AllergyTags extends StatefulWidget {
  final List<String> allergies;
  final void Function(List<String>) onChanged;
  final bool readOnly;
  
  const AllergyTags({
    super.key,
    required this.allergies,
    required this.onChanged,
    this.readOnly = false,
  });

  @override
  State<AllergyTags> createState() => _AllergyTagsState();
}

class _AllergyTagsState extends State<AllergyTags> {
  static const List<String> _commonAllergies = [
    'Gluten',
    'Laktozlar',
    'Fındık',
    'Badem',
    'Ceviz',
    'Fıstık',
    'Yumurta',
    'Süt',
    'Balık',
    'Deniz ürünleri',
    'Soya',
    'Çilek',
    'Kiwi',
    'Muz',
    'Çikolata',
    'Polen',
    'İlaç alerjisi',
  ];
  
  final TextEditingController _customAllergyController = TextEditingController();
  String _selectedSeverity = 'Hafif';
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alerjiler',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Bilinen alerjilerinizi seçin:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),
        
        // Common allergies
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _commonAllergies.map((allergy) {
            final isSelected = widget.allergies.any((a) => a.contains(allergy));
            return FilterChip(
              label: Text(
                allergy,
                style: const TextStyle(fontSize: 12),
              ),
              selected: isSelected,
              onSelected: widget.readOnly ? null : (selected) {
                _toggleAllergy(allergy);
              },
              selectedColor: Colors.red.withValues(alpha: 0.2),
              checkmarkColor: Colors.red,
            );
          }).toList(),
        ),
        
        const SizedBox(height: 16),
        
        // Custom allergy input
        if (!widget.readOnly) ...[
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _customAllergyController,
                  decoration: const InputDecoration(
                    labelText: 'Diğer alerji',
                    hintText: 'Alerji adını yazın',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedSeverity,
                  decoration: const InputDecoration(
                    labelText: 'Şiddet',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Hafif', 'Orta', 'Şiddetli', 'Anafilaksi'].map((severity) {
                    return DropdownMenuItem(
                      value: severity,
                      child: Text(severity),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSeverity = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _addCustomAllergy,
                icon: const Icon(Icons.add_circle),
                tooltip: 'Alerji Ekle',
              ),
            ],
          ),
        ],
        
        // Current allergies
        if (widget.allergies.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Mevcut Alerjiler (${widget.allergies.length}):',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 8),
          ...widget.allergies.map((allergy) {
            final severity = _extractSeverity(allergy);
            final allergyName = _extractAllergyName(allergy);
            
            return Card(
              margin: const EdgeInsets.only(bottom: 4),
              color: _getSeverityColor(severity).withValues(alpha: 0.1),
              child: ListTile(
                leading: Icon(
                  Icons.warning,
                  color: _getSeverityColor(severity),
                  size: 20,
                ),
                title: Text(
                  allergyName,
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: Text(
                  'Şiddet: $severity',
                  style: TextStyle(
                    fontSize: 12,
                    color: _getSeverityColor(severity),
                  ),
                ),
                trailing: widget.readOnly ? null : IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  color: Colors.red,
                  onPressed: () => _removeAllergy(allergy),
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
  
  void _toggleAllergy(String allergy) {
    final existingIndex = widget.allergies.indexWhere((a) => a.contains(allergy));
    final newList = List<String>.from(widget.allergies);
    
    if (existingIndex >= 0) {
      newList.removeAt(existingIndex);
    } else {
      newList.add('$allergy (Hafif)');
    }
    
    widget.onChanged(newList);
  }
  
  void _addCustomAllergy() {
    final allergy = _customAllergyController.text.trim();
    if (allergy.isEmpty) return;
    
    final allergyWithSeverity = '$allergy ($_selectedSeverity)';
    
    if (!widget.allergies.any((a) => a.contains(allergy))) {
      final newList = List<String>.from(widget.allergies);
      newList.add(allergyWithSeverity);
      widget.onChanged(newList);
      _customAllergyController.clear();
    }
  }
  
  void _removeAllergy(String allergy) {
    final newList = List<String>.from(widget.allergies);
    newList.remove(allergy);
    widget.onChanged(newList);
  }
  
  String _extractSeverity(String allergy) {
    final match = RegExp(r'\(([^)]+)\)').firstMatch(allergy);
    return match?.group(1) ?? 'Hafif';
  }
  
  String _extractAllergyName(String allergy) {
    return allergy.replaceAll(RegExp(r'\s*\([^)]*\)'), '');
  }
  
  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'Hafif':
        return Colors.orange;
      case 'Orta':
        return Colors.deepOrange;
      case 'Şiddetli':
        return Colors.red;
      case 'Anafilaksi':
        return Colors.red.shade700;
      default:
        return Colors.orange;
    }
  }
}

// BMI Calculator Widget
class BMICalculator extends StatelessWidget {
  final double? height; // cm
  final double? weight; // kg
  final void Function(double height, double weight)? onChanged;
  final bool readOnly;
  
  const BMICalculator({
    super.key,
    this.height,
    this.weight,
    this.onChanged,
    this.readOnly = false,
  });
  
  double? get bmi {
    if (height == null || weight == null || height! <= 0) return null;
    final heightInMeters = height! / 100;
    return weight! / (heightInMeters * heightInMeters);
  }
  
  String get bmiCategory {
    final bmiValue = bmi;
    if (bmiValue == null) return 'Hesaplanamadı';
    if (bmiValue < 18.5) return 'Zayıf';
    if (bmiValue < 25) return 'Normal';
    if (bmiValue < 30) return 'Fazla Kilolu';
    return 'Obez';
  }
  
  Color get bmiColor {
    final bmiValue = bmi;
    if (bmiValue == null) return Colors.grey;
    if (bmiValue < 18.5) return Colors.blue;
    if (bmiValue < 25) return Colors.green;
    if (bmiValue < 30) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BMI Hesaplayıcı',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: height?.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Boy (cm)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    readOnly: readOnly,
                    onChanged: (value) {
                      final newHeight = double.tryParse(value);
                      if (newHeight != null && weight != null) {
                        onChanged?.call(newHeight, weight!);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: weight?.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Kilo (kg)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    readOnly: readOnly,
                    onChanged: (value) {
                      final newWeight = double.tryParse(value);
                      if (newWeight != null && height != null) {
                        onChanged?.call(height!, newWeight);
                      }
                    },
                  ),
                ),
              ],
            ),
            
            if (bmi != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bmiColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: bmiColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BMI Değeri',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        Text(
                          bmi!.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: bmiColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Kategori',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        Text(
                          bmiCategory,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: bmiColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}