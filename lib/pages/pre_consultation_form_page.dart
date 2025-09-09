import 'package:flutter/material.dart';
import '../models/pre_consultation_form_model.dart';
import '../services/consultation_form_service.dart';
import '../utils/form_validators.dart';
import '../widgets/health_form_widgets.dart';

class PreConsultationFormPage extends StatefulWidget {
  final String? formId;
  final String userId;
  final String? dietitianId;

  const PreConsultationFormPage({
    super.key,
    this.formId,
    required this.userId,
    this.dietitianId,
  });

  @override
  State<PreConsultationFormPage> createState() => _PreConsultationFormPageState();
}

class _PreConsultationFormPageState extends State<PreConsultationFormPage> {
  final ConsultationFormService _formService = ConsultationFormService();
  final PageController _pageController = PageController();
  
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isSaving = false;
  
  final List<GlobalKey<FormState>> _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];

  late PreConsultationFormModel _formData;
  
  final List<String> _stepTitles = [
    'Kişisel Bilgiler',
    'Sağlık Geçmişi', 
    'Beslenme Alışkanlıkları',
    'Hedefler',
  ];

  final List<String> _stepDescriptions = [
    'Temel bilgilerinizi girin',
    'Sağlık durumunuz hakkında bilgi verin',
    'Beslenme alışkanlıklarınızı belirtin',
    'Hedeflerinizi ve beklentilerinizi paylaşın',
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _initializeForm() async {
    setState(() => _isLoading = true);
    
    try {
      if (widget.formId != null) {
        // Mevcut formu yükle
        final result = await _formService.getForm(widget.formId!);
        if (result.success && result.data != null) {
          _formData = result.data!;
        } else {
          _formData = _createEmptyForm();
        }
      } else {
        // Yeni form oluştur
        _formData = _createEmptyForm();
      }
    } catch (e) {
      _formData = _createEmptyForm();
      _showErrorSnackBar('Form yükleme hatası: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  PreConsultationFormModel _createEmptyForm() {
    return PreConsultationFormModel.create(
      formId: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      userId: widget.userId,
      dietitianId: widget.dietitianId ?? '',
      personalInfo: PersonalInfo(),
      medicalHistory: MedicalHistory(),
      nutritionHabits: NutritionHabits(),
      physicalActivity: PhysicalActivity(),
      goals: Goals(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Ön Görüşme Formu'),
          backgroundColor: const Color(0xFF00796B),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF00796B),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ön Görüşme Formu'),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_formData.isSubmitted)
            TextButton.icon(
              onPressed: _saveDraft,
              icon: const Icon(Icons.save_outlined, color: Colors.white),
              label: const Text('Taslak Kaydet', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Progress Indicator
          Container(
            color: const Color(0xFF00796B),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Adım ${_currentStep + 1} / ${_stepTitles.length}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      '${((_currentStep + 1) / _stepTitles.length * 100).round()}% Tamamlandı',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (_currentStep + 1) / _stepTitles.length,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _stepTitles[_currentStep],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _stepDescriptions[_currentStep],
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Form Content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // Disable swipe
              children: [
                _buildPersonalInfoStep(),
                _buildMedicalHistoryStep(),
                _buildNutritionHabitsStep(),
                _buildGoalsStep(),
              ],
            ),
          ),
          
          // Navigation Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _previousStep,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Geri'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF00796B),
                        side: const BorderSide(color: Color(0xFF00796B)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _nextStep,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(_currentStep == _stepTitles.length - 1
                            ? Icons.check
                            : Icons.arrow_forward),
                    label: Text(_currentStep == _stepTitles.length - 1
                        ? 'Formu Gönder'
                        : 'İleri'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00796B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKeys[0],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionCard(
              title: 'Temel Bilgiler',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _formData.personalInfo.firstName,
                        decoration: const InputDecoration(
                          labelText: 'Ad *',
                          border: OutlineInputBorder(),
                        ),
                        validator: FlutterFormValidators.required,
                        onSaved: (value) => _formData.personalInfo.firstName = value ?? '',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        initialValue: _formData.personalInfo.lastName,
                        decoration: const InputDecoration(
                          labelText: 'Soyad *',
                          border: OutlineInputBorder(),
                        ),
                        validator: FlutterFormValidators.required,
                        onSaved: (value) => _formData.personalInfo.lastName = value ?? '',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _formData.personalInfo.email,
                  decoration: const InputDecoration(
                    labelText: 'E-posta *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: FlutterFormValidators.email,
                  onSaved: (value) => _formData.personalInfo.email = value ?? '',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _formData.personalInfo.phone,
                  decoration: const InputDecoration(
                    labelText: 'Telefon *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone_outlined),
                    hintText: '0(5xx) xxx xx xx',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: FlutterFormValidators.phone,
                  onSaved: (value) => _formData.personalInfo.phone = value ?? '',
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Doğum Tarihi *',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            _formData.personalInfo.dateOfBirth != null
                                ? '${_formData.personalInfo.dateOfBirth!.day.toString().padLeft(2, '0')}/${_formData.personalInfo.dateOfBirth!.month.toString().padLeft(2, '0')}/${_formData.personalInfo.dateOfBirth!.year}'
                                : 'Tarih seçin',
                            style: _formData.personalInfo.dateOfBirth != null
                                ? null
                                : const TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _formData.personalInfo.gender == Gender.male 
                            ? 'Erkek' 
                            : _formData.personalInfo.gender == Gender.female 
                                ? 'Kadın' 
                                : _formData.personalInfo.gender == Gender.other 
                                    ? 'Belirtmek istemiyorum' 
                                    : null,
                        decoration: const InputDecoration(
                          labelText: 'Cinsiyet *',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Kadın', child: Text('Kadın')),
                          DropdownMenuItem(value: 'Erkek', child: Text('Erkek')),
                          DropdownMenuItem(value: 'Belirtmek istemiyorum', child: Text('Belirtmek istemiyorum')),
                        ],
                        validator: FlutterFormValidators.required,
                        onChanged: (value) => setState(() {
                          _formData.personalInfo.gender = value == 'Erkek' 
                              ? Gender.male 
                              : value == 'Kadın' 
                                  ? Gender.female 
                                  : Gender.other;
                        }),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Fiziksel Bilgiler',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _formData.personalInfo.height != null && _formData.personalInfo.height! > 0 
                            ? _formData.personalInfo.height.toString() 
                            : '',
                        decoration: const InputDecoration(
                          labelText: 'Boy (cm) *',
                          border: OutlineInputBorder(),
                          suffixText: 'cm',
                        ),
                        keyboardType: TextInputType.number,
                        validator: FlutterFormValidators.positiveNumber,
                        onSaved: (value) => _formData.personalInfo.height = 
                            double.tryParse(value ?? '') ?? 0,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        initialValue: _formData.personalInfo.weight != null && _formData.personalInfo.weight! > 0 
                            ? _formData.personalInfo.weight.toString() 
                            : '',
                        decoration: const InputDecoration(
                          labelText: 'Kilo (kg) *',
                          border: OutlineInputBorder(),
                          suffixText: 'kg',
                        ),
                        keyboardType: TextInputType.number,
                        validator: FlutterFormValidators.positiveNumber,
                        onSaved: (value) => _formData.personalInfo.weight = 
                            double.tryParse(value ?? '') ?? 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                BMICalculator(
                  height: _formData.personalInfo.height,
                  weight: _formData.personalInfo.weight,
                  onChanged: (height, weight) {
                    setState(() {
                      _formData.personalInfo.height = height;
                      _formData.personalInfo.weight = weight;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'İletişim Bilgileri',
              children: [
                TextFormField(
                  initialValue: _formData.personalInfo.occupation,
                  decoration: const InputDecoration(
                    labelText: 'Meslek',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.work_outline),
                  ),
                  onSaved: (value) => _formData.personalInfo.occupation = value ?? '',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _formData.personalInfo.address,
                  decoration: const InputDecoration(
                    labelText: 'Adres',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  maxLines: 3,
                  onSaved: (value) => _formData.personalInfo.address = value ?? '',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalHistoryStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKeys[1],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionCard(
              title: 'Kronik Hastalıklar',
              children: [
                HealthConditionSelector(
                  selectedConditions: _formData.medicalHistory.chronicDiseases,
                  onChanged: (conditions) {
                    setState(() {
                      _formData.medicalHistory.chronicDiseases = conditions;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Kullanılan İlaçlar',
              children: [
                MedicationInput(
                  medications: _formData.medicalHistory.currentMedications,
                  onChanged: (medications) {
                    setState(() {
                      _formData.medicalHistory.currentMedications = medications;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Alerjiler',
              children: [
                AllergyTags(
                  allergies: _formData.medicalHistory.allergies,
                  onChanged: (allergies) {
                    setState(() {
                      _formData.medicalHistory.allergies = allergies;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Ek Bilgiler',
              children: [
                SwitchListTile(
                  title: const Text('Hamile misiniz?'),
                  value: _formData.medicalHistory.isPregnant,
                  activeColor: const Color(0xFF00796B),
                  onChanged: (value) {
                    setState(() {
                      _formData.medicalHistory.isPregnant = value;
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Emziriyor musunuz?'),
                  value: _formData.medicalHistory.isBreastfeeding,
                  activeColor: const Color(0xFF00796B),
                  onChanged: (value) {
                    setState(() {
                      _formData.medicalHistory.isBreastfeeding = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _formData.medicalHistory.additionalNotes,
                  decoration: const InputDecoration(
                    labelText: 'Ek Notlar',
                    hintText: 'Sağlık durumunuzla ilgili eklemek istediğiniz notlar...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                  onSaved: (value) => _formData.medicalHistory.additionalNotes = value ?? '',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionHabitsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKeys[2],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionCard(
              title: 'Öğün Alışkanlıkları',
              children: [
                _buildSliderTile(
                  'Günlük kaç öğün yiyorsunuz?',
                  _formData.nutritionHabits.mealsPerDay.toDouble(),
                  min: 1,
                  max: 6,
                  divisions: 5,
                  onChanged: (value) {
                    setState(() {
                      _formData.nutritionHabits.mealsPerDay = value.round();
                    });
                  },
                ),
                _buildSliderTile(
                  'Günde kaç bardak su içiyorsunuz?',
                  _formData.nutritionHabits.waterIntakePerDay.toDouble(),
                  min: 1,
                  max: 15,
                  divisions: 14,
                  onChanged: (value) {
                    setState(() {
                      _formData.nutritionHabits.waterIntakePerDay = value.toDouble();
                      _formData.nutritionHabits.waterIntake = value.toDouble();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Beslenme Tercihleri',
              children: [
                DropdownButtonFormField<String>(
                  value: _formData.nutritionHabits.dietType?.isNotEmpty == true 
                      ? _formData.nutritionHabits.dietType 
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Diyet Türü',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Karışık', child: Text('Karışık (Her şey)')),
                    DropdownMenuItem(value: 'Vejetaryen', child: Text('Vejetaryen')),
                    DropdownMenuItem(value: 'Vegan', child: Text('Vegan')),
                    DropdownMenuItem(value: 'Ketojenik', child: Text('Ketojenik')),
                    DropdownMenuItem(value: 'Mediteran', child: Text('Mediteran')),
                    DropdownMenuItem(value: 'Diğer', child: Text('Diğer')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _formData.nutritionHabits.dietType = value ?? '';
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _formData.nutritionHabits.dislikedFoods.join(', '),
                  decoration: const InputDecoration(
                    labelText: 'Sevmediğiniz Yiyecekler',
                    hintText: 'Virgül ile ayırın (örn: brokoli, balık, süt)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  onSaved: (value) {
                    _formData.nutritionHabits.dislikedFoods = 
                        value?.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList() ?? [];
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Aktivite Seviyesi',
              children: [
                Column(
                  children: [
                    const Text('Haftalık egzersiz sıklığınız nedir?'),
                    const SizedBox(height: 8),
                    Column(
                      children: [
                        'Hiç egzersiz yapmıyorum',
                        'Haftada 1-2 gün',
                        'Haftada 3-4 gün',
                        'Haftada 5+ gün',
                        'Günlük egzersiz yapıyorum',
                      ].asMap().entries.map((entry) {
                        return RadioListTile<int>(
                          title: Text(entry.value),
                          value: entry.key,
                          groupValue: _formData.physicalActivity.exerciseFrequency,
                          activeColor: const Color(0xFF00796B),
                          onChanged: (value) {
                            setState(() {
                              _formData.physicalActivity.exerciseFrequency = value ?? 0;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKeys[3],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionCard(
              title: 'Hedefleriniz',
              children: [
                DropdownButtonFormField<String>(
                  value: _formData.goals.primaryGoal == GoalType.weightLoss 
                      ? 'Kilo vermek' 
                      : _formData.goals.primaryGoal == GoalType.weightGain 
                          ? 'Kilo almak' 
                          : _formData.goals.primaryGoal == GoalType.maintainWeight 
                              ? 'Kilonu korumak' 
                              : _formData.goals.primaryGoal == GoalType.muscleGain 
                                  ? 'Kas yapmak' 
                                  : _formData.goals.primaryGoal == GoalType.improveHealth 
                                      ? 'Sağlıklı beslenme' 
                                      : _formData.goals.primaryGoal == GoalType.manageCondition 
                                          ? 'Hastalık yönetimi' 
                                          : null,
                  decoration: const InputDecoration(
                    labelText: 'Birincil Hedefiniz *',
                    border: OutlineInputBorder(),
                  ),
                  validator: FlutterFormValidators.required,
                  items: const [
                    DropdownMenuItem(value: 'Kilo vermek', child: Text('Kilo vermek')),
                    DropdownMenuItem(value: 'Kilo almak', child: Text('Kilo almak')),
                    DropdownMenuItem(value: 'Kilonu korumak', child: Text('Mevcut kilonu korumak')),
                    DropdownMenuItem(value: 'Kas yapmak', child: Text('Kas kütlesi artırmak')),
                    DropdownMenuItem(value: 'Sağlıklı beslenme', child: Text('Sağlıklı beslenme alışkanlığı')),
                    DropdownMenuItem(value: 'Hastalık yönetimi', child: Text('Hastalık yönetimi')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _formData.goals.primaryGoal = value == 'Kilo vermek' 
                          ? GoalType.weightLoss 
                          : value == 'Kilo almak' 
                              ? GoalType.weightGain 
                              : value == 'Kilonu korumak' 
                                  ? GoalType.maintainWeight 
                                  : value == 'Kas yapmak' 
                                      ? GoalType.muscleGain 
                                      : value == 'Sağlıklı beslenme' 
                                          ? GoalType.improveHealth 
                                          : GoalType.manageCondition;
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (_formData.goals.primaryGoal == GoalType.weightLoss || _formData.goals.primaryGoal == GoalType.weightGain)
                  TextFormField(
                    initialValue: _formData.goals.targetWeight != null && _formData.goals.targetWeight! > 0 
                        ? _formData.goals.targetWeight.toString() 
                        : '',
                    decoration: const InputDecoration(
                      labelText: 'Hedef Kilo (kg)',
                      border: OutlineInputBorder(),
                      suffixText: 'kg',
                    ),
                    keyboardType: TextInputType.number,
                    validator: FlutterFormValidators.positiveNumber,
                    onSaved: (value) => _formData.goals.targetWeight = 
                        double.tryParse(value ?? '') ?? 0,
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _formData.goals.specificMotivation,
                  decoration: const InputDecoration(
                    labelText: 'Motivasyonunuz / Neden?',
                    hintText: 'Bu hedefe ulaşmak için motivasyonunuz nedir?',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onSaved: (value) => _formData.goals.specificMotivation = value ?? '',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Zaman Çizelgesi',
              children: [
                DropdownButtonFormField<String>(
                  value: _formData.goals.timeFrame != null 
                      ? '${_formData.goals.timeFrame} hafta'
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Ne kadar sürede hedefinize ulaşmak istiyorsunuz?',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: '4 hafta', child: Text('1 ay')),
                    DropdownMenuItem(value: '12 hafta', child: Text('3 ay')),
                    DropdownMenuItem(value: '24 hafta', child: Text('6 ay')),
                    DropdownMenuItem(value: '52 hafta', child: Text('1 yıl')),
                    DropdownMenuItem(value: '104 hafta', child: Text('1 yıldan fazla')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _formData.goals.timeFrame = int.tryParse(value?.replaceAll(' hafta', '') ?? '12');
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Ek Bilgiler',
              children: [
                TextFormField(
                  initialValue: _formData.goals.additionalNotes,
                  decoration: const InputDecoration(
                    labelText: 'Ek Notlar',
                    hintText: 'Diyetisyeninizle paylaşmak istediğiniz diğer bilgiler...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                  onSaved: (value) => _formData.goals.additionalNotes = value ?? '',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00796B),
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSliderTile(
    String title,
    double value, {
    required double min,
    required double max,
    int? divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(min.round().toString()),
            Expanded(
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: divisions,
                activeColor: const Color(0xFF00796B),
                inactiveColor: const Color(0xFF00796B).withValues(alpha: 0.3),
                onChanged: onChanged,
              ),
            ),
            Text(max.round().toString()),
          ],
        ),
        Center(
          child: Chip(
            label: Text('${value.round()}'),
            backgroundColor: const Color(0xFF00796B),
            labelStyle: const TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _formData.personalInfo.dateOfBirth ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00796B),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _formData.personalInfo.dateOfBirth) {
      setState(() {
        _formData.personalInfo.dateOfBirth = picked;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextStep() async {
    // Validate current step
    if (!_formKeys[_currentStep].currentState!.validate()) {
      return;
    }

    // Save current step data
    _formKeys[_currentStep].currentState!.save();

    if (_currentStep < _stepTitles.length - 1) {
      // Go to next step
      setState(() {
        _currentStep++;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      
      // Auto-save draft
      _saveDraft();
    } else {
      // Submit form
      await _submitForm();
    }
  }

  void _saveDraft() async {
    try {
      // Save all current form data
      for (final key in _formKeys) {
        key.currentState?.save();
      }

      final result = await _formService.saveDraft(_formData);
      
      if (result.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Taslak kaydedildi'),
              backgroundColor: Color(0xFF00796B),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      _showErrorSnackBar('Taslak kaydetme hatası: $e');
    }
  }

  Future<void> _submitForm() async {
    setState(() => _isSaving = true);
    
    try {
      // Validate all steps
      bool isValid = true;
      for (int i = 0; i < _formKeys.length; i++) {
        if (!_formKeys[i].currentState!.validate()) {
          isValid = false;
          // Go to first invalid step
          if (i < _currentStep) {
            setState(() {
              _currentStep = i;
            });
            _pageController.animateToPage(
              _currentStep,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
          break;
        }
        _formKeys[i].currentState!.save();
      }

      if (!isValid) {
        setState(() => _isSaving = false);
        _showErrorSnackBar('Lütfen tüm gerekli alanları doldurun');
        return;
      }

      // Submit form
      final result = await _formService.submitForm(_formData.formId);
      
      if (result.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Form başarıyla gönderildi!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          
          // Navigate back or to success page
          Navigator.of(context).pop(result.data);
        }
      } else {
        _showErrorSnackBar(result.errorMessage ?? 'Form gönderimi başarısız');
      }
    } catch (e) {
      _showErrorSnackBar('Form gönderimi hatası: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}