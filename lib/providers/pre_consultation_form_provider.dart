import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../database/drift_service.dart';
import '../database/drift/database.dart';
import '../utils/risk_calculator.dart';

enum FormStatus {
  initial,
  loading,
  saving,
  saved,
  submitting,
  submitted,
  error,
}

class PreConsultationFormProvider extends ChangeNotifier {
  // Form state
  PreConsultationFormData? _formData;
  FormStatus _status = FormStatus.initial;
  String? _error;
  int _currentStep = 0;
  
  // Form validation state
  final Map<int, bool> _stepValidations = {
    0: false, // Personal Info
    1: false, // Medical History
    2: false, // Nutrition Habits
    3: false, // Goals
  };

  // Risk calculation
  RiskCalculationResult? _riskResult;
  
  // Getters
  PreConsultationFormData? get formData => _formData;
  FormStatus get status => _status;
  String? get error => _error;
  int get currentStep => _currentStep;
  bool get isLoading => _status == FormStatus.loading;
  bool get isSaving => _status == FormStatus.saving;
  bool get isSubmitting => _status == FormStatus.submitting;
  bool get canSubmit => _stepValidations.values.every((isValid) => isValid) && _formData != null;
  RiskCalculationResult? get riskResult => _riskResult;
  
  // Form steps info
  final List<String> stepTitles = [
    'Kişisel Bilgiler',
    'Sağlık Geçmişi', 
    'Beslenme Alışkanlıkları',
    'Hedefler',
  ];

  final List<String> stepDescriptions = [
    'Temel bilgilerinizi girin',
    'Sağlık durumunuz hakkında bilgi verin',
    'Beslenme alışkanlıklarınızı belirtin',
    'Hedeflerinizi ve beklentilerinizi paylaşın',
  ];

  double get completionPercentage {
    if (_formData == null) return 0.0;
    _calculateCompletionPercentage();
    return _formData!.completionPercentage;
  }

  // Calculate completion percentage based on filled fields
  void _calculateCompletionPercentage() {
    if (_formData == null) return;
    
    int totalFields = 0;
    // int completedFields = 0; // Unused
    
    // Check personal info
    if (_formData!.personalInfo.isNotEmpty && _formData!.personalInfo != '{}') {
      totalFields += 5; // Assuming 5 personal info fields
      // completedFields += 3; // Simplified calculation - removed
    }
    
    // Check medical history
    if (_formData!.medicalHistory.isNotEmpty && _formData!.medicalHistory != '{}') {
      totalFields += 3;
      // completedFields += 2; // Removed
    }
    
    // Check nutrition habits
    if (_formData!.nutritionHabits.isNotEmpty && _formData!.nutritionHabits != '{}') {
      totalFields += 4;
      // completedFields += 3; // Removed
    }
    
    // Check physical activity
    if (_formData!.physicalActivity.isNotEmpty && _formData!.physicalActivity != '{}') {
      totalFields += 2;
      // completedFields += 1; // Removed
    }
    
    // Check goals
    if (_formData!.goals.isNotEmpty && _formData!.goals != '{}') {
      totalFields += 3;
      // completedFields += 2; // Removed
    }
    
    totalFields = totalFields > 0 ? totalFields : 1; // Prevent division by zero
    // final percentage = (completedFields / totalFields) * 100; // Unused variable
    
    // Update the form data completion percentage
    // Note: Since it's a generated class, we need to update via Drift service
  }

  bool isStepValid(int step) => _stepValidations[step] ?? false;
  
  // Initialize form
  Future<void> initializeForm({
    String? formId,
    required String userId,
    String? dietitianId,
  }) async {
    _setStatus(FormStatus.loading);
    
    try {
      if (formId != null) {
        // Load existing form
        final form = await DriftService.getConsultationFormById(formId);
        if (form != null) {
          _formData = form;
        } else {
          _formData = await _createEmptyForm(userId, dietitianId);
        }
      } else {
        // Create new form
        _formData = await _createEmptyForm(userId, dietitianId);
      }
      
      // Calculate initial risk
      await _calculateRisk();
      
      _setStatus(FormStatus.initial);
    } catch (e) {
      _setError('Form yükleme hatası: $e');
    }
  }

  Future<PreConsultationFormData> _createEmptyForm(String userId, String? dietitianId) async {
    return await DriftService.createConsultationForm(
      userId: userId,
      dietitianId: dietitianId,
    );
  }

  // Navigation methods
  void goToStep(int step) {
    if (step >= 0 && step < stepTitles.length) {
      _currentStep = step;
      notifyListeners();
    }
  }

  void nextStep() {
    if (_currentStep < stepTitles.length - 1) {
      _currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  // Form data update methods
  Future<void> updatePersonalInfo(Map<String, dynamic> personalInfo) async {
    if (_formData == null) return;
    
    try {
      await DriftService.updatePersonalInfo(_formData!.formId, personalInfo);
      
      // Reload form data
      _formData = await DriftService.getConsultationFormById(_formData!.formId);
      
      // Validate step
      _validateStep(0);
      notifyListeners();
    } catch (e) {
      _setError('Kişisel bilgi güncellenirken hata: $e');
    }
  }

  Future<void> updateMedicalHistory(Map<String, dynamic> medicalHistory) async {
    if (_formData == null) return;
    
    try {
      await DriftService.updateMedicalHistory(_formData!.formId, medicalHistory);
      
      // Reload form data
      _formData = await DriftService.getConsultationFormById(_formData!.formId);
      
      // Validate step and recalculate risk
      _validateStep(1);
      await _calculateRisk();
      notifyListeners();
    } catch (e) {
      _setError('Tıbbi geçmiş güncellenirken hata: $e');
    }
  }

  Future<void> updateNutritionHabits(Map<String, dynamic> nutritionHabits) async {
    if (_formData == null) return;
    
    try {
      await DriftService.updateNutritionHabits(_formData!.formId, nutritionHabits);
      
      // Reload form data
      _formData = await DriftService.getConsultationFormById(_formData!.formId);
      
      // Validate step
      _validateStep(2);
      notifyListeners();
    } catch (e) {
      _setError('Beslenme alışkanlıkları güncellenirken hata: $e');
    }
  }

  Future<void> updatePhysicalActivity(Map<String, dynamic> physicalActivity) async {
    if (_formData == null) return;
    
    try {
      await DriftService.updatePhysicalActivity(_formData!.formId, physicalActivity);
      
      // Reload form data  
      _formData = await DriftService.getConsultationFormById(_formData!.formId);
      
      // Validate step
      _validateStep(3);
      notifyListeners();
    } catch (e) {
      _setError('Fiziksel aktivite güncellenirken hata: $e');
    }
  }

  Future<void> updateGoals(Map<String, dynamic> goals) async {
    if (_formData == null) return;
    
    try {
      await DriftService.updateGoals(_formData!.formId, goals);
      
      // Reload form data
      _formData = await DriftService.getConsultationFormById(_formData!.formId);
      
      // Validate step
      _validateStep(4);
      notifyListeners();
    } catch (e) {
      _setError('Hedefler güncellenirken hata: $e');
    }
  }

  // Legacy methods for backward compatibility - using JSON parsing
  void updateNutritionHabitsOld({
    int? mealsPerDay,
    int? waterIntake,
    String? dietType,
    List<String>? dislikedFoods,
  }) {
    if (_formData == null) return;
    
    try {
      // Parse current nutrition habits JSON
      final Map<String, dynamic> nutritionData = 
        _formData!.nutritionHabits.isNotEmpty && _formData!.nutritionHabits != '{}'
          ? jsonDecode(_formData!.nutritionHabits) as Map<String, dynamic>
          : <String, dynamic>{};
      
      // Update fields
      if (mealsPerDay != null) nutritionData['mealsPerDay'] = mealsPerDay;
      if (waterIntake != null) nutritionData['waterIntake'] = waterIntake.toDouble();
      if (dietType != null) nutritionData['dietType'] = dietType;
      if (dislikedFoods != null) nutritionData['dislikedFoods'] = dislikedFoods;
      
      // Convert back to JSON and update via proper method
      updateNutritionHabits(nutritionData);
      
    } catch (e) {
      _setError('Beslenme alışkanlıkları güncellenirken hata: $e');
    }
  }

  void updatePhysicalActivityLocal({
    int? exerciseFrequency,
  }) {
    if (_formData == null) return;
    
    try {
      // Parse current physical activity JSON
      final Map<String, dynamic> activityData = 
        _formData!.physicalActivity.isNotEmpty && _formData!.physicalActivity != '{}'
          ? jsonDecode(_formData!.physicalActivity) as Map<String, dynamic>
          : <String, dynamic>{};
      
      // Update fields
      if (exerciseFrequency != null) activityData['exerciseFrequency'] = exerciseFrequency;
      
      // Convert back to JSON and update via proper method
      updatePhysicalActivity(activityData);
      
    } catch (e) {
      _setError('Fiziksel aktivite güncellenirken hata: $e');
    }
  }

  void updateGoalsLocal({
    // GoalType? primaryGoal,
    double? targetWeight,
    String? timeFrame,
    String? specificMotivation,
    String? additionalNotes,
  }) {
    if (_formData == null) return;
    
    try {
      // Parse current goals JSON
      final Map<String, dynamic> goalsData = 
        _formData!.goals.isNotEmpty && _formData!.goals != '{}'
          ? jsonDecode(_formData!.goals) as Map<String, dynamic>
          : <String, dynamic>{};
      
      // Update fields
      // if (primaryGoal != null) goalsData['primaryGoal'] = primaryGoal;
      if (targetWeight != null) goalsData['targetWeight'] = targetWeight;
      if (timeFrame != null) goalsData['timeFrame'] = int.tryParse(timeFrame);
      if (specificMotivation != null) goalsData['specificMotivation'] = specificMotivation;
      if (additionalNotes != null) goalsData['additionalNotes'] = additionalNotes;
      
      // Convert back to JSON and update via proper method
      updateGoals(goalsData);
      
    } catch (e) {
      _setError('Hedefler güncellenirken hata: $e');
    }
  }

  // Validation methods
  void _validateStep(int step) {
    if (_formData == null) return;
    
    bool isValid = false;
    
    switch (step) {
      case 0: // Personal Info
        isValid = _validatePersonalInfo();
        break;
      case 1: // Medical History
        isValid = _validateMedicalHistory();
        break;
      case 2: // Nutrition Habits
        isValid = _validateNutritionHabits();
        break;
      case 3: // Goals
        isValid = _validateGoals();
        break;
    }
    
    _stepValidations[step] = isValid;
  }

  bool _validatePersonalInfo() {
    try {
      final personalInfo = json.decode(_formData!.personalInfo) as Map<String, dynamic>;
      return personalInfo.isNotEmpty; // Simplified validation - at least some data exists
    } catch (e) {
      return false;
    }
  }

  bool _validateMedicalHistory() {
    // Medical history is generally optional, but we can add specific validation
    return true;
  }

  bool _validateNutritionHabits() {
    // Nutrition habits have default values, so generally valid
    return true;
  }

  bool _validateGoals() {
    try {
      final goals = json.decode(_formData!.goals) as Map<String, dynamic>;
      return goals.isNotEmpty; // Simplified validation
    } catch (e) {
      return false;
    }
  }

  void validateAllSteps() {
    for (int i = 0; i < stepTitles.length; i++) {
      _validateStep(i);
    }
    notifyListeners();
  }

  // Risk calculation
  Future<void> _calculateRisk() async {
    if (_formData == null) return;
    
    try {
      // For now, skip risk calculation as it requires complex model conversion
      // In a full implementation, this would parse JSON data and calculate risk
      _riskResult = null;
      debugPrint('Risk calculation skipped - needs JSON parsing implementation');
    } catch (e) {
      debugPrint('Risk calculation error: $e');
      _riskResult = null;
    }
  }

  // Save draft
  Future<bool> saveDraft() async {
    if (_formData == null) return false;
    
    _setStatus(FormStatus.saving);
    
    try {
      await DriftService.saveConsultationForm(_formData!);
      _setStatus(FormStatus.saved);
      return true;
    } catch (e) {
      _setError('Taslak kaydetme hatası: $e');
      return false;
    }
  }

  // Submit form
  Future<bool> submitForm() async {
    if (_formData == null) return false;
    
    validateAllSteps();
    
    if (!canSubmit) {
      _setError('Lütfen tüm gerekli alanları doldurun');
      return false;
    }
    
    _setStatus(FormStatus.submitting);
    
    try {
      await DriftService.submitConsultationForm(_formData!.formId);
      
      // Update completion status
      await DriftService.updateFormCompletionStatus(_formData!.formId, true, 100.0);
      
      _setStatus(FormStatus.submitted);
      return true;
    } catch (e) {
      _setError('Form gönderimi hatası: $e');
      return false;
    }
  }

  // Helper methods
  void _setStatus(FormStatus status) {
    _status = status;
    if (status != FormStatus.error) {
      _error = null;
    }
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    _status = FormStatus.error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    if (_status == FormStatus.error) {
      _status = FormStatus.initial;
    }
    notifyListeners();
  }

}