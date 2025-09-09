import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pre_consultation_form_provider.dart';
import '../widgets/health_form_widgets.dart';
import '../widgets/responsive_form_components.dart';
import '../theme/pre_consultation_form_theme.dart';
import '../utils/form_validators.dart';

class PreConsultationFormPageProvider extends StatefulWidget {
  final String? formId;
  final String userId;
  final String? dietitianId;

  const PreConsultationFormPageProvider({
    super.key,
    this.formId,
    required this.userId,
    this.dietitianId,
  });

  @override
  State<PreConsultationFormPageProvider> createState() => _PreConsultationFormPageProviderState();
}

class _PreConsultationFormPageProviderState extends State<PreConsultationFormPageProvider> {
  final PageController _pageController = PageController();
  
  final List<GlobalKey<FormState>> _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];

  // Helper methods to parse JSON fields
  // TODO: Complete Drift migration - All formData.field.subfield patterns need to be updated
  // to use these JSON parsing helpers instead of direct property access
  Map<String, dynamic> _parsePersonalInfo(String? personalInfoJson) {
    if (personalInfoJson == null || personalInfoJson.isEmpty) return {};
    try {
      return jsonDecode(personalInfoJson) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  DateTime? _parseDateOfBirth(String? personalInfoJson) {
    final personalInfo = _parsePersonalInfo(personalInfoJson);
    final dateStr = personalInfo['dateOfBirth'];
    if (dateStr == null) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  String? _parseGender(String? personalInfoJson) {
    final personalInfo = _parsePersonalInfo(personalInfoJson);
    final gender = personalInfo['gender'];
    if (gender == 'male') return 'Erkek';
    if (gender == 'female') return 'Kadın';
    if (gender == 'other') return 'Diğer';
    return null;
  }

  double? _parseHeight(String? personalInfoJson) {
    final personalInfo = _parsePersonalInfo(personalInfoJson);
    final height = personalInfo['height'];
    if (height == null) return null;
    try {
      return double.parse(height.toString());
    } catch (e) {
      return null;
    }
  }

  double? _parseWeight(String? personalInfoJson) {
    final personalInfo = _parsePersonalInfo(personalInfoJson);
    final weight = personalInfo['weight'];
    if (weight == null) return null;
    try {
      return double.parse(weight.toString());
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> _parseMedicalHistory(String? medicalHistoryJson) {
    if (medicalHistoryJson == null || medicalHistoryJson.isEmpty) return {};
    try {
      return jsonDecode(medicalHistoryJson) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  Map<String, dynamic> _parseNutritionHabits(String? nutritionHabitsJson) {
    if (nutritionHabitsJson == null || nutritionHabitsJson.isEmpty) return {};
    try {
      return jsonDecode(nutritionHabitsJson) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  Map<String, dynamic> _parsePhysicalActivity(String? physicalActivityJson) {
    if (physicalActivityJson == null || physicalActivityJson.isEmpty) return {};
    try {
      return jsonDecode(physicalActivityJson) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  Map<String, dynamic> _parseGoals(String? goalsJson) {
    if (goalsJson == null || goalsJson.isEmpty) return {};
    try {
      return jsonDecode(goalsJson) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PreConsultationFormProvider>().initializeForm(
        formId: widget.formId,
        userId: widget.userId,
        dietitianId: widget.dietitianId,
      );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PreConsultationFormProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
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

        return Theme(
          data: PreConsultationFormTheme.lightTheme,
          child: Scaffold(
            backgroundColor: PreConsultationFormTheme.backgroundColor,
            appBar: AppBar(
              title: const Text('Ön Görüşme Formu'),
              actions: [
                if (provider.formData != null && !provider.formData!.isSubmitted)
                  TextButton.icon(
                    onPressed: () => _saveDraft(provider),
                    icon: const Icon(Icons.save_outlined, color: Colors.white),
                    label: const Text('Taslak Kaydet', style: TextStyle(color: Colors.white)),
                  ),
              ],
            ),
            body: Column(
              children: [
                // Progress Indicator
                ResponsiveProgressHeader(
                  currentStep: provider.currentStep,
                  stepTitles: provider.stepTitles,
                  stepDescriptions: provider.stepDescriptions,
                  completionPercentage: provider.completionPercentage,
                  extraInfo: provider.riskResult != null
                      ? _buildRiskIndicator(provider)
                      : null,
                ),
                
                // Form Content
                Expanded(
                  child: SizedBox(
                    width: PreConsultationFormTheme.getContentWidth(context),
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (page) {
                        if (page != provider.currentStep) {
                          provider.goToStep(page);
                        }
                      },
                      children: [
                        _buildPersonalInfoStep(provider),
                        _buildMedicalHistoryStep(provider),
                        _buildNutritionHabitsStep(provider),
                        _buildGoalsStep(provider),
                      ],
                    ),
                  ),
                ),
                
                // Navigation Buttons
                _buildNavigationButtons(provider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRiskIndicator(PreConsultationFormProvider provider) {
    if (provider.riskResult == null) return const SizedBox();
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PreConsultationFormTheme.spacingM,
        vertical: PreConsultationFormTheme.spacingS,
      ),
      decoration: BoxDecoration(
        color: PreConsultationFormTheme.getRiskColor(provider.riskResult!.severity),
        borderRadius: BorderRadius.circular(PreConsultationFormTheme.radiusL),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            PreConsultationFormTheme.getRiskIcon(provider.riskResult!.severity),
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: PreConsultationFormTheme.spacingS),
          Text(
            '${provider.riskResult!.severity} Risk',
            style: PreConsultationFormTheme.bodySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(PreConsultationFormProvider provider) {
    return Container(
      padding: PreConsultationFormTheme.responsivePadding(context),
      decoration: PreConsultationFormTheme.navigationButtonsDecoration,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (provider.currentStep > 0)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _previousStep(provider),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Geri'),
                ),
              ),
            if (provider.currentStep > 0) 
              const SizedBox(width: PreConsultationFormTheme.spacingM),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: provider.isSaving || provider.isSubmitting 
                    ? null 
                    : () => _nextStep(provider),
                icon: provider.isSaving || provider.isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(provider.currentStep == provider.stepTitles.length - 1
                        ? Icons.check
                        : Icons.arrow_forward),
                label: Text(provider.currentStep == provider.stepTitles.length - 1
                    ? 'Formu Gönder'
                    : 'İleri'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoStep(PreConsultationFormProvider provider) {
    final formData = provider.formData;
    if (formData == null) return const SizedBox();

    return SingleChildScrollView(
      padding: PreConsultationFormTheme.responsivePadding(context),
      child: Form(
        key: _formKeys[0],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveFormSection(
              title: 'Temel Bilgiler',
              icon: Icons.person_outline,
              subtitle: 'Kişisel bilgilerinizi girin',
              isRequired: true,
              children: [
                ResponsiveFormRow(
                  children: [
                    TextFormField(
                      initialValue: _parsePersonalInfo(formData.personalInfo)['firstName'] ?? '',
                      decoration: const InputDecoration(
                        labelText: 'Ad *',
                      ),
                      validator: FlutterFormValidators.required,
                      onChanged: (value) {
                        final personalInfo = _parsePersonalInfo(formData.personalInfo);
                        personalInfo['firstName'] = value;
                        provider.updatePersonalInfo(personalInfo);
                      },
                    ),
                    TextFormField(
                      initialValue: _parsePersonalInfo(formData.personalInfo)['lastName'] ?? '',
                      decoration: const InputDecoration(
                        labelText: 'Soyad *',
                      ),
                      validator: FlutterFormValidators.required,
                      onChanged: (value) {
                        final personalInfo = _parsePersonalInfo(formData.personalInfo);
                        personalInfo['lastName'] = value;
                        provider.updatePersonalInfo(personalInfo);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: PreConsultationFormTheme.spacingM),
                TextFormField(
                  initialValue: _parsePersonalInfo(formData.personalInfo)['email'] ?? '',
                  decoration: const InputDecoration(
                    labelText: 'E-posta *',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: FlutterFormValidators.email,
                  onChanged: (value) {
                    final personalInfo = _parsePersonalInfo(formData.personalInfo);
                    personalInfo['email'] = value;
                    provider.updatePersonalInfo(personalInfo);
                  },
                ),
                const SizedBox(height: PreConsultationFormTheme.spacingM),
                TextFormField(
                  initialValue: _parsePersonalInfo(formData.personalInfo)['phone'] ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Telefon *',
                    prefixIcon: Icon(Icons.phone_outlined),
                    hintText: '0(5xx) xxx xx xx',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: FlutterFormValidators.phone,
                  onChanged: (value) {
                    final personalInfo = _parsePersonalInfo(formData.personalInfo);
                    personalInfo['phone'] = value;
                    provider.updatePersonalInfo(personalInfo);
                  },
                ),
                const SizedBox(height: PreConsultationFormTheme.spacingM),
                ResponsiveFormRow(
                  children: [
                    InkWell(
                      onTap: () => _selectDate(context, provider),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Doğum Tarihi *',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _parseDateOfBirth(formData.personalInfo) != null
                              ? '${_parseDateOfBirth(formData.personalInfo)!.day.toString().padLeft(2, '0')}/${_parseDateOfBirth(formData.personalInfo)!.month.toString().padLeft(2, '0')}/${_parseDateOfBirth(formData.personalInfo)!.year}'
                              : 'Tarih seçin',
                          style: _parseDateOfBirth(formData.personalInfo) != null
                              ? null
                              : const TextStyle(color: PreConsultationFormTheme.textSecondary),
                        ),
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      value: _parseGender(formData.personalInfo),
                      decoration: const InputDecoration(
                        labelText: 'Cinsiyet *',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Kadın', child: Text('Kadın')),
                        DropdownMenuItem(value: 'Erkek', child: Text('Erkek')),
                        DropdownMenuItem(value: 'Belirtmek istemiyorum', child: Text('Belirtmek istemiyorum')),
                      ],
                      validator: FlutterFormValidators.required,
                      onChanged: (value) {
                        final personalInfo = _parsePersonalInfo(formData.personalInfo);
                        personalInfo['gender'] = value == 'Erkek' ? 'male' : value == 'Kadın' ? 'female' : 'other';
                        provider.updatePersonalInfo(personalInfo);
                      },
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
                        initialValue: (_parseHeight(formData.personalInfo) ?? 0) > 0 
                            ? _parseHeight(formData.personalInfo).toString() 
                            : '',
                        decoration: const InputDecoration(
                          labelText: 'Boy (cm) *',
                          border: OutlineInputBorder(),
                          suffixText: 'cm',
                        ),
                        keyboardType: TextInputType.number,
                        validator: FlutterFormValidators.positiveNumber,
                        onChanged: (value) {
                          final height = double.tryParse(value);
                          if (height != null) {
                            final personalInfo = _parsePersonalInfo(formData.personalInfo);
                            personalInfo['height'] = height;
                            provider.updatePersonalInfo(personalInfo);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        initialValue: (_parseWeight(formData.personalInfo) ?? 0) > 0 
                            ? _parseWeight(formData.personalInfo).toString() 
                            : '',
                        decoration: const InputDecoration(
                          labelText: 'Kilo (kg) *',
                          border: OutlineInputBorder(),
                          suffixText: 'kg',
                        ),
                        keyboardType: TextInputType.number,
                        validator: FlutterFormValidators.positiveNumber,
                        onChanged: (value) {
                          final weight = double.tryParse(value);
                          if (weight != null) {
                            final personalInfo = _parsePersonalInfo(formData.personalInfo);
                            personalInfo['weight'] = weight;
                            provider.updatePersonalInfo(personalInfo);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_parseHeight(formData.personalInfo) != null && _parseWeight(formData.personalInfo) != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'BMI: ${(_parseWeight(formData.personalInfo)! / ((_parseHeight(formData.personalInfo)! / 100) * (_parseHeight(formData.personalInfo)! / 100))).toStringAsFixed(1)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'İletişim Bilgileri',
              children: [
                TextFormField(
                  initialValue: _parsePersonalInfo(formData.personalInfo)['occupation'] ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Meslek',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.work_outline),
                  ),
                  onChanged: (value) {
                    final personalInfo = _parsePersonalInfo(formData.personalInfo);
                    personalInfo['occupation'] = value;
                    provider.updatePersonalInfo(personalInfo);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _parsePersonalInfo(formData.personalInfo)['address'] ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Adres',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  maxLines: 3,
                  onChanged: (value) {
                    final personalInfo = _parsePersonalInfo(formData.personalInfo);
                    personalInfo['address'] = value;
                    provider.updatePersonalInfo(personalInfo);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalHistoryStep(PreConsultationFormProvider provider) {
    final formData = provider.formData;
    if (formData == null) return const SizedBox();

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
                  selectedConditions: _parseMedicalHistory(formData.medicalHistory)['chronicDiseases'] ?? '',
                  onChanged: (conditions) {
                    final medicalHistory = _parseMedicalHistory(formData.medicalHistory);
                    medicalHistory['chronicDiseases'] = conditions;
                    provider.updateMedicalHistory(medicalHistory);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Kullanılan İlaçlar',
              children: [
                TextFormField(
                  initialValue: (_parseMedicalHistory(formData.medicalHistory)['currentMedications'] as List<dynamic>?)?.join(', ') ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Kullandığınız İlaçlar',
                    hintText: 'İlaçları virgülle ayırarak yazınız',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onChanged: (value) {
                    final medications = value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                    final medicalHistory = _parseMedicalHistory(formData.medicalHistory);
                    medicalHistory['currentMedications'] = medications;
                    provider.updateMedicalHistory(medicalHistory);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Alerjiler',
              children: [
                TextFormField(
                  initialValue: (_parseMedicalHistory(formData.medicalHistory)['allergies'] as List<dynamic>?)?.join(', ') ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Alerjileriniz',
                    hintText: 'Alerjileri virgülle ayırarak yazınız',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  onChanged: (value) {
                    final allergies = value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                    final medicalHistory = _parseMedicalHistory(formData.medicalHistory);
                    medicalHistory['allergies'] = allergies;
                    provider.updateMedicalHistory(medicalHistory);
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
                  value: _parseMedicalHistory(formData.medicalHistory)['isPregnant'] == true,
                  activeColor: const Color(0xFF00796B),
                  onChanged: (value) {
                    final medicalHistory = _parseMedicalHistory(formData.medicalHistory);
                    medicalHistory['isPregnant'] = value;
                    provider.updateMedicalHistory(medicalHistory);
                  },
                ),
                SwitchListTile(
                  title: const Text('Emziriyor musunuz?'),
                  value: _parseMedicalHistory(formData.medicalHistory)['isBreastfeeding'] == true,
                  activeColor: const Color(0xFF00796B),
                  onChanged: (value) {
                    final medicalHistory = _parseMedicalHistory(formData.medicalHistory);
                    medicalHistory['isBreastfeeding'] = value;
                    provider.updateMedicalHistory(medicalHistory);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _parseMedicalHistory(formData.medicalHistory)['additionalNotes'] ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Ek Notlar',
                    hintText: 'Sağlık durumunuzla ilgili eklemek istediğiniz notlar...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                  onChanged: (value) {
                    final medicalHistory = _parseMedicalHistory(formData.medicalHistory);
                    medicalHistory['additionalNotes'] = value;
                    provider.updateMedicalHistory(medicalHistory);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionHabitsStep(PreConsultationFormProvider provider) {
    final formData = provider.formData;
    if (formData == null) return const SizedBox();

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
                  double.tryParse(_parseNutritionHabits(formData.nutritionHabits)['mealsPerDay']?.toString() ?? '3') ?? 3.0,
                  min: 1,
                  max: 6,
                  divisions: 5,
                  onChanged: (value) {
                    final nutritionHabits = _parseNutritionHabits(formData.nutritionHabits);
                    nutritionHabits['mealsPerDay'] = value.round();
                    provider.updateNutritionHabits(nutritionHabits);
                  },
                ),
                _buildSliderTile(
                  'Günde kaç bardak su içiyorsunuz?',
                  double.tryParse(_parseNutritionHabits(formData.nutritionHabits)['waterIntake']?.toString() ?? '8') ?? 8.0,
                  min: 1,
                  max: 15,
                  divisions: 14,
                  onChanged: (value) {
                    final nutritionHabits = _parseNutritionHabits(formData.nutritionHabits);
                    nutritionHabits['waterIntake'] = value.round();
                    provider.updateNutritionHabits(nutritionHabits);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Beslenme Tercihleri',
              children: [
                DropdownButtonFormField<String>(
                  value: (_parseNutritionHabits(formData.nutritionHabits)['dietType'] ?? '').isNotEmpty == true 
                      ? _parseNutritionHabits(formData.nutritionHabits)['dietType'] ?? '' 
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
                    final nutritionHabits = _parseNutritionHabits(formData.nutritionHabits);
                    nutritionHabits['dietType'] = value;
                    provider.updateNutritionHabits(nutritionHabits);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: (_parseNutritionHabits(formData.nutritionHabits)['dislikedFoods'] as List<dynamic>?)?.join(', ') ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Sevmediğiniz Yiyecekler',
                    hintText: 'Virgül ile ayırın (örn: brokoli, balık, süt)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  onChanged: (value) {
                    final foods = value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                    final nutritionHabits = _parseNutritionHabits(formData.nutritionHabits);
                    nutritionHabits['dislikedFoods'] = foods;
                    provider.updateNutritionHabits(nutritionHabits);
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
                          groupValue: _parsePhysicalActivity(formData.physicalActivity)['exerciseFrequency'] ?? '',
                          activeColor: const Color(0xFF00796B),
                          onChanged: (value) {
                            final physicalActivity = _parsePhysicalActivity(formData.physicalActivity);
                            physicalActivity['exerciseFrequency'] = value;
                            provider.updatePhysicalActivity(physicalActivity);
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

  Widget _buildGoalsStep(PreConsultationFormProvider provider) {
    final formData = provider.formData;
    if (formData == null) return const SizedBox();

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
                  value: _parseGoals(formData.goals)['primaryGoal'] ?? '' == 'weightLoss' 
                      ? 'Kilo vermek' 
                      : _parseGoals(formData.goals)['primaryGoal'] ?? '' == 'weightGain' 
                          ? 'Kilo almak' 
                          : _parseGoals(formData.goals)['primaryGoal'] ?? '' == 'maintainWeight' 
                              ? 'Kilonu korumak' 
                              : _parseGoals(formData.goals)['primaryGoal'] ?? '' == 'muscleGain' 
                                  ? 'Kas yapmak' 
                                  : _parseGoals(formData.goals)['primaryGoal'] ?? '' == 'improveHealth' 
                                      ? 'Sağlığımı iyileştirmek' 
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
                    final goals = _parseGoals(formData.goals);
                    goals['primaryGoal'] = value == 'Kilo vermek' 
                        ? 'weightLoss' 
                        : value == 'Kilo almak' 
                            ? 'weightGain' 
                            : value == 'Kilonu korumak' 
                                ? 'maintainWeight' 
                                : value == 'Kas yapmak' 
                                    ? 'muscleGain' 
                                    : 'improveHealth';
                    provider.updateGoals(goals);
                  },
                ),
                const SizedBox(height: 16),
                if (_parseGoals(formData.goals)['primaryGoal'] ?? '' == 'weightLoss' || 
                    _parseGoals(formData.goals)['primaryGoal'] ?? '' == 'weightGain')
                  TextFormField(
                    initialValue: (double.tryParse(_parseGoals(formData.goals)['targetWeight']?.toString() ?? '0') ?? 0) > 0 
                        ? _parseGoals(formData.goals)['targetWeight']?.toString() ?? '' 
                        : '',
                    decoration: const InputDecoration(
                      labelText: 'Hedef Kilo (kg)',
                      border: OutlineInputBorder(),
                      suffixText: 'kg',
                    ),
                    keyboardType: TextInputType.number,
                    validator: FlutterFormValidators.positiveNumber,
                    onChanged: (value) {
                      final weight = double.tryParse(value);
                      if (weight != null) {
                        final goals = _parseGoals(formData.goals);
                        goals['targetWeight'] = weight;
                        provider.updateGoals(goals);
                      }
                    },
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _parseGoals(formData.goals)['specificMotivation'] ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Motivasyonunuz / Neden?',
                    hintText: 'Bu hedefe ulaşmak için motivasyonunuz nedir?',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onChanged: (value) {
                    final goals = _parseGoals(formData.goals);
                    goals['specificMotivation'] = value;
                    provider.updateGoals(goals);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Zaman Çizelgesi',
              children: [
                DropdownButtonFormField<String>(
                  value: (_parseGoals(formData.goals)['timeFrame'] ?? '').isNotEmpty 
                      ? '${_parseGoals(formData.goals)['timeFrame'] ?? ''} hafta' 
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Ne kadar sürede hedefinize ulaşmak istiyorsunuz?',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: '1 ay', child: Text('1 ay')),
                    DropdownMenuItem(value: '3 ay', child: Text('3 ay')),
                    DropdownMenuItem(value: '6 ay', child: Text('6 ay')),
                    DropdownMenuItem(value: '1 yıl', child: Text('1 yıl')),
                    DropdownMenuItem(value: '1 yıldan fazla', child: Text('1 yıldan fazla')),
                  ],
                  onChanged: (value) {
                    final goals = _parseGoals(formData.goals);
                    goals['timeFrame'] = value;
                    provider.updateGoals(goals);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Ek Bilgiler',
              children: [
                TextFormField(
                  initialValue: _parseGoals(formData.goals)['additionalNotes'] ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Ek Notlar',
                    hintText: 'Diyetisyeninizle paylaşmak istediğiniz diğer bilgiler...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                  onChanged: (value) {
                    final goals = _parseGoals(formData.goals);
                    goals['additionalNotes'] = value;
                    provider.updateGoals(goals);
                  },
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

  Future<void> _selectDate(BuildContext context, PreConsultationFormProvider provider) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _parseDateOfBirth(provider.formData?.personalInfo) ?? DateTime(1990),
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
    
    if (picked != null) {
      final personalInfo = _parsePersonalInfo(provider.formData?.personalInfo ?? '');
      personalInfo['dateOfBirth'] = picked.toIso8601String();
      provider.updatePersonalInfo(personalInfo);
    }
  }

  void _previousStep(PreConsultationFormProvider provider) {
    provider.previousStep();
    _pageController.animateToPage(
      provider.currentStep,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextStep(PreConsultationFormProvider provider) async {
    // Validate current step
    if (!_formKeys[provider.currentStep].currentState!.validate()) {
      return;
    }

    if (provider.currentStep < provider.stepTitles.length - 1) {
      // Go to next step
      provider.nextStep();
      _pageController.animateToPage(
        provider.currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      
      // Auto-save draft
      await provider.saveDraft();
    } else {
      // Submit form
      await _submitForm(provider);
    }
  }

  void _saveDraft(PreConsultationFormProvider provider) async {
    final success = await provider.saveDraft();
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Taslak kaydedildi'),
          backgroundColor: Color(0xFF00796B),
          duration: Duration(seconds: 2),
        ),
      );
    } else if (provider.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error!),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _submitForm(PreConsultationFormProvider provider) async {
    final success = await provider.submitForm();
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Form başarıyla gönderildi!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      
      // Navigate back or to success page
      Navigator.of(context).pop(provider.formData);
    } else if (provider.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error!),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

}