import 'dart:convert';
import 'dart:developer' as developer;
import 'package:uuid/uuid.dart';
import '../models/pre_consultation_form_model.dart';
import '../database/drift_service.dart';
import '../utils/form_validators.dart';
import '../utils/risk_calculator.dart';

// Service result wrapper
class ServiceResult<T> {
  final bool success;
  final T? data;
  final String? errorMessage;
  final String? errorCode;
  
  const ServiceResult._({
    required this.success,
    this.data,
    this.errorMessage,
    this.errorCode,
  });
  
  factory ServiceResult.success(T data) {
    return ServiceResult._(success: true, data: data);
  }
  
  factory ServiceResult.failure({
    required String errorMessage,
    String? errorCode,
  }) {
    return ServiceResult._(
      success: false,
      errorMessage: errorMessage,
      errorCode: errorCode,
    );
  }
}

// Form draft/autosave data
class FormDraft {
  final String userId;
  final String formId;
  final Map<String, dynamic> data;
  final DateTime lastSaved;
  
  const FormDraft({
    required this.userId,
    required this.formId,
    required this.data,
    required this.lastSaved,
  });
  
  factory FormDraft.fromJson(Map<String, dynamic> json) {
    return FormDraft(
      userId: json['userId'],
      formId: json['formId'],
      data: json['data'],
      lastSaved: DateTime.fromMillisecondsSinceEpoch(json['lastSaved']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'formId': formId,
      'data': data,
      'lastSaved': lastSaved.millisecondsSinceEpoch,
    };
  }
}

// Consultation Form Service (Singleton)
class ConsultationFormService {
  static final ConsultationFormService _instance = ConsultationFormService._internal();
  
  factory ConsultationFormService() {
    return _instance;
  }
  
  ConsultationFormService._internal();
  
  static const String _logTag = 'ConsultationFormService';
  static const Uuid _uuid = Uuid();
  
  // Form draft storage (temporary storage)
  final Map<String, FormDraft> _drafts = {};
  
  // ========== CRUD OPERATIONS ==========
  
  // Form kaydetme
  Future<ServiceResult<PreConsultationFormModel>> saveForm(PreConsultationFormModel form) async {
    try {
      developer.log('Saving consultation form: ${form.formId}', name: _logTag);
      
      // Form tamamlanma yüzdesini hesapla
      form.calculateCompletionPercentage();
      
      // Risk skorunu hesapla
      await _calculateAdvancedRiskScore(form);
      
      // Veritabanına kaydet
      await DriftService.savePreConsultationForm(form);
      
      // Başarılı kayıttan sonra draft'ı temizle
      _drafts.remove('${form.userId}_${form.formId}');
      
      developer.log('Form saved successfully: ${form.formId}', name: _logTag);
      return ServiceResult.success(form);
      
    } catch (e) {
      developer.log('Error saving form: $e', name: _logTag, level: 1000);
      return ServiceResult.failure(
        errorMessage: 'Form kaydedilirken hata oluştu: $e',
        errorCode: 'SAVE_ERROR',
      );
    }
  }
  
  // Form getirme
  Future<ServiceResult<PreConsultationFormModel>> getForm(String formId) async {
    try {
      developer.log('Getting consultation form: $formId', name: _logTag);
      
      final form = await DriftService.getPreConsultationForm(formId);
      
      if (form == null) {
        return ServiceResult.failure(
          errorMessage: 'Form bulunamadı',
          errorCode: 'FORM_NOT_FOUND',
        );
      }
      
      return ServiceResult.success(form);
      
    } catch (e) {
      developer.log('Error getting form: $e', name: _logTag, level: 1000);
      return ServiceResult.failure(
        errorMessage: 'Form getirilirken hata oluştu: $e',
        errorCode: 'GET_ERROR',
      );
    }
  }
  
  // Form güncelleme
  Future<ServiceResult<PreConsultationFormModel>> updateForm(PreConsultationFormModel form) async {
    try {
      developer.log('Updating consultation form: ${form.formId}', name: _logTag);
      
      // Form tamamlanma yüzdesini hesapla
      form.calculateCompletionPercentage();
      
      // Risk skorunu hesapla
      await _calculateAdvancedRiskScore(form);
      
      // Güncelleme zamanını ayarla
      form.updatedAt = DateTime.now();
      
      // Veritabanını güncelle
      await DriftService.updatePreConsultationForm(form);
      
      developer.log('Form updated successfully: ${form.formId}', name: _logTag);
      return ServiceResult.success(form);
      
    } catch (e) {
      developer.log('Error updating form: $e', name: _logTag, level: 1000);
      return ServiceResult.failure(
        errorMessage: 'Form güncellenirken hata oluştu: $e',
        errorCode: 'UPDATE_ERROR',
      );
    }
  }
  
  // Form silme
  Future<ServiceResult<bool>> deleteForm(String formId) async {
    try {
      developer.log('Deleting consultation form: $formId', name: _logTag);
      
      await DriftService.deletePreConsultationForm(formId);
      
      // İlgili draft'ları da temizle
      _drafts.removeWhere((key, draft) => draft.formId == formId);
      
      developer.log('Form deleted successfully: $formId', name: _logTag);
      return ServiceResult.success(true);
      
    } catch (e) {
      developer.log('Error deleting form: $e', name: _logTag, level: 1000);
      return ServiceResult.failure(
        errorMessage: 'Form silinirken hata oluştu: $e',
        errorCode: 'DELETE_ERROR',
      );
    }
  }
  
  // ========== USER OPERATIONS ==========
  
  // Kullanıcının formlarını getirme
  Future<ServiceResult<List<PreConsultationFormModel>>> getUserForms(String userId) async {
    try {
      developer.log('Getting forms for user: $userId', name: _logTag);
      
      final forms = await DriftService.getUserPreConsultationForms(userId);
      
      return ServiceResult.success(forms);
      
    } catch (e) {
      developer.log('Error getting user forms: $e', name: _logTag, level: 1000);
      return ServiceResult.failure(
        errorMessage: 'Kullanıcı formları getirilirken hata oluştu: $e',
        errorCode: 'GET_USER_FORMS_ERROR',
      );
    }
  }
  
  // Kullanıcının son formunu getirme
  Future<ServiceResult<PreConsultationFormModel?>> getUserLatestForm(String userId) async {
    try {
      developer.log('Getting latest form for user: $userId', name: _logTag);
      
      final form = await DriftService.getUserLatestPreConsultationForm(userId);
      
      return ServiceResult.success(form);
      
    } catch (e) {
      developer.log('Error getting user latest form: $e', name: _logTag, level: 1000);
      return ServiceResult.failure(
        errorMessage: 'Son form getirilirken hata oluştu: $e',
        errorCode: 'GET_LATEST_FORM_ERROR',
      );
    }
  }
  
  // Kullanıcının tamamlanmamış formlarını getirme
  Future<ServiceResult<List<PreConsultationFormModel>>> getUserIncompleteForms(String userId) async {
    try {
      developer.log('Getting incomplete forms for user: $userId', name: _logTag);
      
      final forms = await DriftService.getIncompletePreConsultationForms(userId);
      
      return ServiceResult.success(forms);
      
    } catch (e) {
      developer.log('Error getting incomplete forms: $e', name: _logTag, level: 1000);
      return ServiceResult.failure(
        errorMessage: 'Tamamlanmamış formlar getirilirken hata oluştu: $e',
        errorCode: 'GET_INCOMPLETE_FORMS_ERROR',
      );
    }
  }
  
  // ========== DIETITIAN OPERATIONS ==========
  
  // Diyetisyenin formlarını getirme
  Future<ServiceResult<List<PreConsultationFormModel>>> getDietitianForms(String dietitianId) async {
    try {
      developer.log('Getting forms for dietitian: $dietitianId', name: _logTag);
      
      final forms = await DriftService.getDietitianPreConsultationForms(dietitianId);
      
      return ServiceResult.success(forms);
      
    } catch (e) {
      developer.log('Error getting dietitian forms: $e', name: _logTag, level: 1000);
      return ServiceResult.failure(
        errorMessage: 'Diyetisyen formları getirilirken hata oluştu: $e',
        errorCode: 'GET_DIETITIAN_FORMS_ERROR',
      );
    }
  }
  
  // Bekleyen formları getirme (inceleme için)
  Future<ServiceResult<List<PreConsultationFormModel>>> getPendingForms(String dietitianId) async {
    try {
      developer.log('Getting pending forms for dietitian: $dietitianId', name: _logTag);
      
      final forms = await DriftService.getPendingPreConsultationForms(dietitianId);
      
      return ServiceResult.success(forms);
      
    } catch (e) {
      developer.log('Error getting pending forms: $e', name: _logTag, level: 1000);
      return ServiceResult.failure(
        errorMessage: 'Bekleyen formlar getirilirken hata oluştu: $e',
        errorCode: 'GET_PENDING_FORMS_ERROR',
      );
    }
  }
  
  // Risk seviyesine göre formları getirme
  Future<ServiceResult<List<PreConsultationFormModel>>> getFormsByRiskLevel(
    String dietitianId,
    String riskLevel,
  ) async {
    try {
      developer.log('Getting forms by risk level: $riskLevel for dietitian: $dietitianId', name: _logTag);
      
      final forms = await DriftService.getPreConsultationFormsByRiskLevel(dietitianId, riskLevel);
      
      return ServiceResult.success(forms);
      
    } catch (e) {
      developer.log('Error getting forms by risk level: $e', name: _logTag, level: 1000);
      return ServiceResult.failure(
        errorMessage: 'Risk seviyesine göre formlar getirilirken hata oluştu: $e',
        errorCode: 'GET_FORMS_BY_RISK_ERROR',
      );
    }
  }
  
  // ========== FORM CREATION & INITIALIZATION ==========
  
  // Yeni form oluşturma
  Future<ServiceResult<PreConsultationFormModel>> createNewForm({
    required String userId,
    required String dietitianId,
  }) async {
    try {
      developer.log('Creating new form for user: $userId, dietitian: $dietitianId', name: _logTag);
      
      final formId = _uuid.v4();
      
      final form = PreConsultationFormModel.create(
        formId: formId,
        userId: userId,
        dietitianId: dietitianId,
        personalInfo: PersonalInfo(),
        medicalHistory: MedicalHistory(),
        nutritionHabits: NutritionHabits(),
        physicalActivity: PhysicalActivity(),
        goals: Goals(),
      );
      
      // Form'u veritabanına kaydet
      await DriftService.savePreConsultationForm(form);
      
      developer.log('New form created: $formId', name: _logTag);
      return ServiceResult.success(form);
      
    } catch (e) {
      developer.log('Error creating form: $e', name: _logTag, level: 1000);
      return ServiceResult.failure(
        errorMessage: 'Yeni form oluşturulurken hata oluştu: $e',
        errorCode: 'CREATE_FORM_ERROR',
      );
    }
  }
  
  // Form template'i oluşturma (önceden tanımlanmış alanlarla)
  Future<ServiceResult<PreConsultationFormModel>> createFormFromTemplate({
    required String userId,
    required String dietitianId,
    String templateType = 'standard',
  }) async {
    try {
      developer.log('Creating form from template: $templateType', name: _logTag);
      
      final form = await createNewForm(userId: userId, dietitianId: dietitianId);
      if (!form.success) return form;
      
      // Template'e göre ön tanımlı değerleri ayarla
      await _applyFormTemplate(form.data!, templateType);
      
      return ServiceResult.success(form.data!);
      
    } catch (e) {
      developer.log('Error creating form from template: $e', name: _logTag, level: 1000);
      return ServiceResult.failure(
        errorMessage: 'Template\'den form oluşturulurken hata oluştu: $e',
        errorCode: 'CREATE_FROM_TEMPLATE_ERROR',
      );
    }
  }
  
  // ========== DRAFT & AUTOSAVE OPERATIONS ==========
  
  // Draft kaydetme (otomatik kaydetme için)
  Future<ServiceResult<bool>> saveDraft(PreConsultationFormModel form) async {
    try {
      developer.log('Saving draft for form: ${form.formId}', name: _logTag);
      
      final draftKey = '${form.userId}_${form.formId}';
      final draft = FormDraft(
        userId: form.userId,
        formId: form.formId,
        data: form.toMap(),
        lastSaved: DateTime.now(),
      );
      
      _drafts[draftKey] = draft;
      
      developer.log('Draft saved for form: ${form.formId}', name: _logTag);
      return ServiceResult.success(true);
      
    } catch (e) {
      developer.log('Error saving draft: $e', name: _logTag, level: 1000);
      return ServiceResult.failure(
        errorMessage: 'Taslak kaydedilirken hata oluştu: $e',
        errorCode: 'SAVE_DRAFT_ERROR',
      );
    }
  }
  
  // Draft getirme
  ServiceResult<FormDraft?> getDraft(String userId, String formId) {
    try {
      final draftKey = '${userId}_$formId';
      final draft = _drafts[draftKey];
      
      return ServiceResult.success(draft);
      
    } catch (e) {
      developer.log('Error getting draft: $e', name: _logTag, level: 1000);
      return ServiceResult.failure(
        errorMessage: 'Taslak getirilirken hata oluştu: $e',
        errorCode: 'GET_DRAFT_ERROR',
      );
    }
  }
  
  // Tüm draft'ları temizleme
  void clearAllDrafts() {
    _drafts.clear();
    developer.log('All drafts cleared', name: _logTag);
  }
  
  // Eski draft'ları temizleme (24 saatten eski)
  void clearOldDrafts() {
    final cutoffDate = DateTime.now().subtract(const Duration(hours: 24));
    _drafts.removeWhere((key, draft) => draft.lastSaved.isBefore(cutoffDate));
    developer.log('Old drafts cleared', name: _logTag);
  }
  
  // ========== VALIDATION OPERATIONS ==========
  
  // Form validasyonu
  Future<ServiceResult<List<String>>> validateForm(PreConsultationFormModel form) async {
    try {
      developer.log('Validating form: ${form.formId}', name: _logTag);
      
      final validationResults = FormValidators.validateCompleteForm(
        age: form.personalInfo.age,
        height: form.personalInfo.height,
        weight: form.personalInfo.currentWeight,
        targetWeight: form.personalInfo.targetWeight,
        occupation: form.personalInfo.occupation,
        phoneNumber: form.personalInfo.phoneNumber,
        emergencyContact: form.personalInfo.emergencyContact,
        waterIntake: form.nutritionHabits.waterIntakePerDay,
        exerciseFrequency: form.physicalActivity.exerciseFrequencyPerWeek,
        exerciseDuration: form.physicalActivity.exerciseDurationMinutes,
        motivationLevel: form.goals.motivationLevel,
        timeframeWeeks: form.goals.timeframeWeeks,
      );
      
      final errors = FormValidators.getErrorMessages(validationResults);
      
      return ServiceResult.success(errors);
      
    } catch (e) {
      developer.log('Error validating form: $e', name: _logTag, level: 1000);
      return ServiceResult.failure(
        errorMessage: 'Form doğrulanırken hata oluştu: $e',
        errorCode: 'VALIDATION_ERROR',
      );
    }
  }
  
  // Form gönderim kontrolü
  Future<ServiceResult<bool>> canSubmitForm(PreConsultationFormModel form) async {
    try {
      final validationResult = await validateForm(form);
      if (!validationResult.success) return ServiceResult.failure(errorMessage: validationResult.errorMessage!);
      
      final errors = validationResult.data!;
      final canSubmit = errors.isEmpty && form.completionPercentage >= 80.0;
      
      if (!canSubmit) {
        return ServiceResult.failure(
          errorMessage: 'Form gönderim için hazır değil (${form.completionPercentageText} tamamlandı)',
          errorCode: 'FORM_NOT_READY',
        );
      }
      
      return ServiceResult.success(true);
      
    } catch (e) {
      developer.log('Error checking form submission: $e', name: _logTag, level: 1000);
      return ServiceResult.failure(
        errorMessage: 'Form gönderim kontrolü yapılırken hata oluştu: $e',
        errorCode: 'SUBMIT_CHECK_ERROR',
      );
    }
  }
  
  // Form gönderimi
  Future<ServiceResult<PreConsultationFormModel>> submitForm(String formId) async {
    try {
      developer.log('Submitting form: $formId', name: _logTag);
      
      // Form'u getir
      final formResult = await getForm(formId);
      if (!formResult.success) return ServiceResult.failure(errorMessage: formResult.errorMessage!);
      
      final form = formResult.data!;
      
      // Gönderim kontrolü
      final canSubmitResult = await canSubmitForm(form);
      if (!canSubmitResult.success) return ServiceResult.failure(errorMessage: canSubmitResult.errorMessage!);
      
      // Form'u gönder
      form.submitForm();
      
      // Güncelle
      final updateResult = await updateForm(form);
      if (!updateResult.success) return ServiceResult.failure(errorMessage: updateResult.errorMessage!);
      
      developer.log('Form submitted successfully: $formId', name: _logTag);
      return ServiceResult.success(form);
      
    } catch (e) {
      developer.log('Error submitting form: $e', name: _logTag, level: 1000);
      return ServiceResult.failure(
        errorMessage: 'Form gönderilirken hata oluştu: $e',
        errorCode: 'SUBMIT_ERROR',
      );
    }
  }
  
  // Form inceleme
  Future<ServiceResult<PreConsultationFormModel>> reviewForm(String formId, String reviewNotes) async {
    try {
      developer.log('Reviewing form: $formId', name: _logTag);
      
      // Form'u getir
      final formResult = await getForm(formId);
      if (!formResult.success) return ServiceResult.failure(errorMessage: formResult.errorMessage!);
      
      final form = formResult.data!;
      
      // İnceleme işlemi
      form.reviewForm(notes: reviewNotes);
      
      // Güncelle
      final updateResult = await updateForm(form);
      if (!updateResult.success) return ServiceResult.failure(errorMessage: updateResult.errorMessage!);
      
      developer.log('Form reviewed successfully: $formId', name: _logTag);
      return ServiceResult.success(form);
      
    } catch (e) {
      developer.log('Error reviewing form: $e', name: _logTag, level: 1000);
      return ServiceResult.failure(
        errorMessage: 'Form incelenirken hata oluştu: $e',
        errorCode: 'REVIEW_ERROR',
      );
    }
  }
  
  // ========== EXPORT OPERATIONS ==========
  
  // JSON export
  Future<ServiceResult<String>> exportToJson(String formId) async {
    try {
      developer.log('Exporting form to JSON: $formId', name: _logTag);
      
      final formResult = await getForm(formId);
      if (!formResult.success) return ServiceResult.failure(errorMessage: formResult.errorMessage!);
      
      final form = formResult.data!;
      final jsonString = jsonEncode(form.toMap());
      
      return ServiceResult.success(jsonString);
      
    } catch (e) {
      developer.log('Error exporting to JSON: $e', name: _logTag, level: 1000);
      return ServiceResult.failure(
        errorMessage: 'JSON export işlemi sırasında hata oluştu: $e',
        errorCode: 'JSON_EXPORT_ERROR',
      );
    }
  }
  
  // JSON import
  Future<ServiceResult<PreConsultationFormModel>> importFromJson(String jsonString) async {
    try {
      developer.log('Importing form from JSON', name: _logTag);
      
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      final form = PreConsultationFormModel.fromMap(jsonMap);
      
      // Yeni ID ata (çakışmaları önlemek için)
      form.formId = _uuid.v4();
      
      return ServiceResult.success(form);
      
    } catch (e) {
      developer.log('Error importing from JSON: $e', name: _logTag, level: 1000);
      return ServiceResult.failure(
        errorMessage: 'JSON import işlemi sırasında hata oluştu: $e',
        errorCode: 'JSON_IMPORT_ERROR',
      );
    }
  }
  
  // ========== STATISTICS & ANALYTICS ==========
  
  // Diyetisyen form istatistikleri
  Future<ServiceResult<Map<String, int>>> getDietitianStats(String dietitianId) async {
    try {
      developer.log('Getting stats for dietitian: $dietitianId', name: _logTag);
      
      final stats = await DriftService.getPreConsultationFormStats(dietitianId);
      
      return ServiceResult.success(stats);
      
    } catch (e) {
      developer.log('Error getting dietitian stats: $e', name: _logTag, level: 1000);
      return ServiceResult.failure(
        errorMessage: 'İstatistikler getirilirken hata oluştu: $e',
        errorCode: 'STATS_ERROR',
      );
    }
  }
  
  // Genel sistem istatistikleri
  Future<ServiceResult<Map<String, dynamic>>> getOverallStats() async {
    try {
      developer.log('Getting overall stats', name: _logTag);
      
      final stats = await DriftService.getOverallPreConsultationFormStats();
      
      return ServiceResult.success(stats);
      
    } catch (e) {
      developer.log('Error getting overall stats: $e', name: _logTag, level: 1000);
      return ServiceResult.failure(
        errorMessage: 'Genel istatistikler getirilirken hata oluştu: $e',
        errorCode: 'OVERALL_STATS_ERROR',
      );
    }
  }
  
  // ========== PRIVATE METHODS ==========
  
  // Gelişmiş risk hesaplama
  Future<void> _calculateAdvancedRiskScore(PreConsultationFormModel form) async {
    try {
      final riskResult = RiskCalculator.calculateRisk(form);
      
      form.riskScore = riskResult.score;
      form.riskLevel = riskResult.level;
      form.riskFactors = riskResult.factors.map((factor) => factor.description).toList();
      form.updatedAt = DateTime.now();
      
    } catch (e) {
      developer.log('Error calculating risk score: $e', name: _logTag, level: 1000);
      // Hata durumunda temel risk hesaplamayı kullan
      form.calculateRiskScore();
    }
  }
  
  // Form template uygulama
  Future<void> _applyFormTemplate(PreConsultationFormModel form, String templateType) async {
    switch (templateType) {
      case 'weightLoss':
        form.goals.primaryGoal = GoalType.weightLoss;
        form.goals.timeframeWeeks = 12;
        form.nutritionHabits.mealsPerDay = 3;
        form.nutritionHabits.snacksPerDay = 2;
        form.nutritionHabits.waterIntakePerDay = 2.5;
        break;
      case 'weightGain':
        form.goals.primaryGoal = GoalType.weightGain;
        form.goals.timeframeWeeks = 16;
        form.nutritionHabits.mealsPerDay = 4;
        form.nutritionHabits.snacksPerDay = 3;
        break;
      case 'health_improvement':
        form.goals.primaryGoal = GoalType.improveHealth;
        form.goals.timeframeWeeks = 8;
        form.physicalActivity.exerciseFrequencyPerWeek = 3;
        break;
      case 'standard':
      default:
        // Standart template - varsayılan değerler kullanılır
        break;
    }
  }
}