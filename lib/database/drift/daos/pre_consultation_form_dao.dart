import 'dart:convert';
import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/pre_consultation_forms_table.dart';

part 'pre_consultation_form_dao.g.dart';

@DriftAccessor(tables: [PreConsultationFormsTable])
class PreConsultationFormDao extends DatabaseAccessor<AppDatabase> with _$PreConsultationFormDaoMixin {
  PreConsultationFormDao(super.db);

  // ============ BASIC CRUD OPERATIONS ============

  // Get all forms
  Future<List<PreConsultationFormData>> getAllForms() {
    return select(preConsultationFormsTable).get();
  }

  // Watch all forms
  Stream<List<PreConsultationFormData>> watchAllForms() {
    return (select(preConsultationFormsTable)
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .watch();
  }

  // Get form by ID
  Future<PreConsultationFormData?> getFormById(int id) {
    return (select(preConsultationFormsTable)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  // Get form by form ID
  Future<PreConsultationFormData?> getFormByFormId(String formId) {
    return (select(preConsultationFormsTable)..where((t) => t.formId.equals(formId))).getSingleOrNull();
  }

  // Watch form by form ID
  Stream<PreConsultationFormData?> watchFormByFormId(String formId) {
    return (select(preConsultationFormsTable)..where((t) => t.formId.equals(formId))).watchSingleOrNull();
  }

  // Save or update form (upsert)
  Future<int> saveForm(PreConsultationFormsTableCompanion form) {
    return into(preConsultationFormsTable).insertOnConflictUpdate(form);
  }

  // Batch save forms
  Future<void> saveForms(List<PreConsultationFormsTableCompanion> formList) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(preConsultationFormsTable, formList);
    });
  }

  // Update form
  Future<bool> updateForm(PreConsultationFormsTableCompanion form) {
    return update(preConsultationFormsTable).replace(form);
  }

  // Delete form by ID
  Future<int> deleteForm(int id) {
    return (delete(preConsultationFormsTable)..where((t) => t.id.equals(id))).go();
  }

  // Delete form by form ID
  Future<int> deleteFormByFormId(String formId) {
    return (delete(preConsultationFormsTable)..where((t) => t.formId.equals(formId))).go();
  }

  // ============ USER-SPECIFIC OPERATIONS ============

  // Get forms by user ID
  Future<List<PreConsultationFormData>> getFormsByUserId(String userId) {
    return (select(preConsultationFormsTable)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Watch forms by user ID
  Stream<List<PreConsultationFormData>> watchFormsByUserId(String userId) {
    return (select(preConsultationFormsTable)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .watch();
  }

  // Get latest form by user ID
  Future<PreConsultationFormData?> getLatestFormByUserId(String userId) {
    return (select(preConsultationFormsTable)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])
          ..limit(1))
        .getSingleOrNull();
  }

  // Get forms by dietitian ID
  Future<List<PreConsultationFormData>> getFormsByDietitianId(String dietitianId) {
    return (select(preConsultationFormsTable)
          ..where((t) => t.dietitianId.equals(dietitianId))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Watch forms by dietitian ID
  Stream<List<PreConsultationFormData>> watchFormsByDietitianId(String dietitianId) {
    return (select(preConsultationFormsTable)
          ..where((t) => t.dietitianId.equals(dietitianId))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .watch();
  }

  // ============ STATUS-BASED OPERATIONS ============

  // Get forms by completion status
  Future<List<PreConsultationFormData>> getFormsByCompletionStatus(bool isCompleted) {
    return (select(preConsultationFormsTable)
          ..where((t) => t.isCompleted.equals(isCompleted))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Get forms by submission status
  Future<List<PreConsultationFormData>> getFormsBySubmissionStatus(bool isSubmitted) {
    return (select(preConsultationFormsTable)
          ..where((t) => t.isSubmitted.equals(isSubmitted))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Get forms by review status
  Future<List<PreConsultationFormData>> getFormsByReviewStatus(bool isReviewed) {
    return (select(preConsultationFormsTable)
          ..where((t) => t.isReviewed.equals(isReviewed))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Get pending forms for review (submitted but not reviewed)
  Future<List<PreConsultationFormData>> getPendingFormsForReview() {
    return (select(preConsultationFormsTable)
          ..where((t) => t.isSubmitted.equals(true) & t.isReviewed.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.submittedAt, mode: OrderingMode.asc)]))
        .get();
  }

  // Watch pending forms for review
  Stream<List<PreConsultationFormData>> watchPendingFormsForReview() {
    return (select(preConsultationFormsTable)
          ..where((t) => t.isSubmitted.equals(true) & t.isReviewed.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.submittedAt, mode: OrderingMode.asc)]))
        .watch();
  }

  // ============ RISK-BASED OPERATIONS ============

  // Get forms by risk level
  Future<List<PreConsultationFormData>> getFormsByRiskLevel(String riskLevel) {
    return (select(preConsultationFormsTable)
          ..where((t) => t.riskLevel.equals(riskLevel))
          ..orderBy([(t) => OrderingTerm(expression: t.riskScore, mode: OrderingMode.desc)]))
        .get();
  }

  // Get forms with high risk
  Future<List<PreConsultationFormData>> getHighRiskForms() {
    return getFormsByRiskLevel('high');
  }

  // Get forms above risk score threshold
  Future<List<PreConsultationFormData>> getFormsAboveRiskScore(double riskScore) {
    return (select(preConsultationFormsTable)
          ..where((t) => t.riskScore.isBiggerThanValue(riskScore))
          ..orderBy([(t) => OrderingTerm(expression: t.riskScore, mode: OrderingMode.desc)]))
        .get();
  }

  // ============ UPDATE OPERATIONS ============

  // Update form completion status
  Future<int> updateFormCompletionStatus(String formId, bool isCompleted, double completionPercentage) {
    return (update(preConsultationFormsTable)..where((t) => t.formId.equals(formId)))
        .write(PreConsultationFormsTableCompanion(
      isCompleted: Value(isCompleted),
      completionPercentage: Value(completionPercentage),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update form submission status
  Future<int> updateFormSubmissionStatus(String formId, bool isSubmitted) {
    return (update(preConsultationFormsTable)..where((t) => t.formId.equals(formId)))
        .write(PreConsultationFormsTableCompanion(
      isSubmitted: Value(isSubmitted),
      submittedAt: Value(isSubmitted ? DateTime.now() : null),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update form review status
  Future<int> updateFormReviewStatus(String formId, bool isReviewed, String? reviewNotes) {
    return (update(preConsultationFormsTable)..where((t) => t.formId.equals(formId)))
        .write(PreConsultationFormsTableCompanion(
      isReviewed: Value(isReviewed),
      reviewNotes: Value.absentIfNull(reviewNotes),
      reviewedAt: Value(isReviewed ? DateTime.now() : null),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update risk assessment
  Future<int> updateRiskAssessment(String formId, double riskScore, String riskLevel, List<String> riskFactors) {
    return (update(preConsultationFormsTable)..where((t) => t.formId.equals(formId)))
        .write(PreConsultationFormsTableCompanion(
      riskScore: Value(riskScore),
      riskLevel: Value(riskLevel),
      riskFactors: Value(jsonEncode(riskFactors)),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update personal info
  Future<int> updatePersonalInfo(String formId, Map<String, dynamic> personalInfo) {
    return (update(preConsultationFormsTable)..where((t) => t.formId.equals(formId)))
        .write(PreConsultationFormsTableCompanion(
      personalInfo: Value(jsonEncode(personalInfo)),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update medical history
  Future<int> updateMedicalHistory(String formId, Map<String, dynamic> medicalHistory) {
    return (update(preConsultationFormsTable)..where((t) => t.formId.equals(formId)))
        .write(PreConsultationFormsTableCompanion(
      medicalHistory: Value(jsonEncode(medicalHistory)),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update nutrition habits
  Future<int> updateNutritionHabits(String formId, Map<String, dynamic> nutritionHabits) {
    return (update(preConsultationFormsTable)..where((t) => t.formId.equals(formId)))
        .write(PreConsultationFormsTableCompanion(
      nutritionHabits: Value(jsonEncode(nutritionHabits)),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update physical activity
  Future<int> updatePhysicalActivity(String formId, Map<String, dynamic> physicalActivity) {
    return (update(preConsultationFormsTable)..where((t) => t.formId.equals(formId)))
        .write(PreConsultationFormsTableCompanion(
      physicalActivity: Value(jsonEncode(physicalActivity)),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update goals
  Future<int> updateGoals(String formId, Map<String, dynamic> goals) {
    return (update(preConsultationFormsTable)..where((t) => t.formId.equals(formId)))
        .write(PreConsultationFormsTableCompanion(
      goals: Value(jsonEncode(goals)),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Update dynamic sections
  Future<int> updateDynamicSections(String formId, List<Map<String, dynamic>> dynamicSections) {
    return (update(preConsultationFormsTable)..where((t) => t.formId.equals(formId)))
        .write(PreConsultationFormsTableCompanion(
      dynamicSections: Value(jsonEncode(dynamicSections)),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // ============ JSON HELPER METHODS ============

  // Parse personal info from JSON string
  Map<String, dynamic> parsePersonalInfo(String jsonString) {
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  // Parse medical history from JSON string
  Map<String, dynamic> parseMedicalHistory(String jsonString) {
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  // Parse nutrition habits from JSON string
  Map<String, dynamic> parseNutritionHabits(String jsonString) {
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  // Parse physical activity from JSON string
  Map<String, dynamic> parsePhysicalActivity(String jsonString) {
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  // Parse goals from JSON string
  Map<String, dynamic> parseGoals(String jsonString) {
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  // Parse dynamic sections from JSON string
  List<Map<String, dynamic>> parseDynamicSections(String jsonString) {
    try {
      return List<Map<String, dynamic>>.from(jsonDecode(jsonString));
    } catch (e) {
      return [];
    }
  }

  // Parse risk factors from JSON string
  List<String> parseRiskFactors(String jsonString) {
    try {
      return List<String>.from(jsonDecode(jsonString));
    } catch (e) {
      return [];
    }
  }

  // ============ SEARCH AND FILTER OPERATIONS ============

  // Search forms by user name or form ID
  Future<List<PreConsultationFormData>> searchForms(String query) {
    final lowerQuery = query.toLowerCase();
    return (select(preConsultationFormsTable)
          ..where((t) => t.formId.lower().contains(lowerQuery) |
              t.userId.lower().contains(lowerQuery)))
        .get();
  }

  // Get forms within date range
  Future<List<PreConsultationFormData>> getFormsInDateRange(DateTime from, DateTime to) {
    return (select(preConsultationFormsTable)
          ..where((t) => t.createdAt.isBetweenValues(from, to))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Get submitted forms within date range
  Future<List<PreConsultationFormData>> getSubmittedFormsInDateRange(DateTime from, DateTime to) {
    return (select(preConsultationFormsTable)
          ..where((t) => t.isSubmitted.equals(true) & t.submittedAt.isBetweenValues(from, to))
          ..orderBy([(t) => OrderingTerm(expression: t.submittedAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Get forms with completion percentage above threshold
  Future<List<PreConsultationFormData>> getFormsAboveCompletionThreshold(double threshold) {
    return (select(preConsultationFormsTable)
          ..where((t) => t.completionPercentage.isBiggerThanValue(threshold))
          ..orderBy([(t) => OrderingTerm(expression: t.completionPercentage, mode: OrderingMode.desc)]))
        .get();
  }

  // ============ PAGINATION OPERATIONS ============

  // Get forms with pagination
  Future<List<PreConsultationFormData>> getFormsPaginated({
    required int limit,
    int? offset,
    String? orderBy = 'createdAt',
    bool ascending = false,
    String? userId,
    String? dietitianId,
    bool? isCompleted,
    bool? isSubmitted,
    bool? isReviewed,
  }) {
    var query = select(preConsultationFormsTable);
    
    // Add filters
    if (userId != null) {
      query = query..where((t) => t.userId.equals(userId));
    }
    if (dietitianId != null) {
      query = query..where((t) => t.dietitianId.equals(dietitianId));
    }
    if (isCompleted != null) {
      query = query..where((t) => t.isCompleted.equals(isCompleted));
    }
    if (isSubmitted != null) {
      query = query..where((t) => t.isSubmitted.equals(isSubmitted));
    }
    if (isReviewed != null) {
      query = query..where((t) => t.isReviewed.equals(isReviewed));
    }
    
    // Add ordering
    switch (orderBy) {
      case 'createdAt':
        query = query..orderBy([(t) => OrderingTerm(
          expression: t.createdAt, 
          mode: ascending ? OrderingMode.asc : OrderingMode.desc
        )]);
        break;
      case 'submittedAt':
        query = query..orderBy([(t) => OrderingTerm(
          expression: t.submittedAt, 
          mode: ascending ? OrderingMode.asc : OrderingMode.desc
        )]);
        break;
      case 'reviewedAt':
        query = query..orderBy([(t) => OrderingTerm(
          expression: t.reviewedAt, 
          mode: ascending ? OrderingMode.asc : OrderingMode.desc
        )]);
        break;
      case 'completionPercentage':
        query = query..orderBy([(t) => OrderingTerm(
          expression: t.completionPercentage, 
          mode: ascending ? OrderingMode.asc : OrderingMode.desc
        )]);
        break;
      case 'riskScore':
        query = query..orderBy([(t) => OrderingTerm(
          expression: t.riskScore, 
          mode: ascending ? OrderingMode.asc : OrderingMode.desc
        )]);
        break;
    }
    
    // Add pagination
    query = query..limit(limit);
    if (offset != null && offset > 0) {
      query = query..limit(limit, offset: offset);
    }
    
    return query.get();
  }

  // ============ COUNT OPERATIONS ============

  // Count total forms
  Future<int> countForms() {
    final query = selectOnly(preConsultationFormsTable)..addColumns([preConsultationFormsTable.id.count()]);
    return query.map((row) => row.read(preConsultationFormsTable.id.count()) ?? 0).getSingle();
  }

  // Count forms by user ID
  Future<int> countFormsByUserId(String userId) {
    final query = selectOnly(preConsultationFormsTable)
      ..where(preConsultationFormsTable.userId.equals(userId))
      ..addColumns([preConsultationFormsTable.id.count()]);
    return query.map((row) => row.read(preConsultationFormsTable.id.count()) ?? 0).getSingle();
  }

  // Count forms by dietitian ID
  Future<int> countFormsByDietitianId(String dietitianId) {
    final query = selectOnly(preConsultationFormsTable)
      ..where(preConsultationFormsTable.dietitianId.equals(dietitianId))
      ..addColumns([preConsultationFormsTable.id.count()]);
    return query.map((row) => row.read(preConsultationFormsTable.id.count()) ?? 0).getSingle();
  }

  // Count completed forms
  Future<int> countCompletedForms() {
    final query = selectOnly(preConsultationFormsTable)
      ..where(preConsultationFormsTable.isCompleted.equals(true))
      ..addColumns([preConsultationFormsTable.id.count()]);
    return query.map((row) => row.read(preConsultationFormsTable.id.count()) ?? 0).getSingle();
  }

  // Count submitted forms
  Future<int> countSubmittedForms() {
    final query = selectOnly(preConsultationFormsTable)
      ..where(preConsultationFormsTable.isSubmitted.equals(true))
      ..addColumns([preConsultationFormsTable.id.count()]);
    return query.map((row) => row.read(preConsultationFormsTable.id.count()) ?? 0).getSingle();
  }

  // Count pending forms for review
  Future<int> countPendingFormsForReview() {
    final query = selectOnly(preConsultationFormsTable)
      ..where(preConsultationFormsTable.isSubmitted.equals(true) & preConsultationFormsTable.isReviewed.equals(false))
      ..addColumns([preConsultationFormsTable.id.count()]);
    return query.map((row) => row.read(preConsultationFormsTable.id.count()) ?? 0).getSingle();
  }

  // Count forms by risk level
  Future<int> countFormsByRiskLevel(String riskLevel) {
    final query = selectOnly(preConsultationFormsTable)
      ..where(preConsultationFormsTable.riskLevel.equals(riskLevel))
      ..addColumns([preConsultationFormsTable.id.count()]);
    return query.map((row) => row.read(preConsultationFormsTable.id.count()) ?? 0).getSingle();
  }

  // ============ UTILITY OPERATIONS ============

  // Clear all forms
  Future<int> clearAll() {
    return delete(preConsultationFormsTable).go();
  }

  // Clear forms by user ID
  Future<int> clearFormsByUserId(String userId) {
    return (delete(preConsultationFormsTable)..where((t) => t.userId.equals(userId))).go();
  }

  // Clear forms by dietitian ID
  Future<int> clearFormsByDietitianId(String dietitianId) {
    return (delete(preConsultationFormsTable)..where((t) => t.dietitianId.equals(dietitianId))).go();
  }

  // Clear old unsubmitted forms (older than specified days)
  Future<int> clearOldUnsubmittedForms(int daysOld) {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    return (delete(preConsultationFormsTable)
          ..where((t) => t.isSubmitted.equals(false) & t.createdAt.isSmallerThanValue(cutoffDate)))
        .go();
  }

  // Get form statistics
  Future<Map<String, int>> getFormStatistics() async {
    final total = await countForms();
    final completed = await countCompletedForms();
    final submitted = await countSubmittedForms();
    final pending = await countPendingFormsForReview();
    final highRisk = await countFormsByRiskLevel('high');
    
    return {
      'total': total,
      'completed': completed,
      'submitted': submitted,
      'pending': pending,
      'highRisk': highRisk,
    };
  }

  // Get forms summary by date range
  Future<Map<String, dynamic>> getFormsSummaryByDateRange(DateTime from, DateTime to) async {
    final formsInRange = await getFormsInDateRange(from, to);
    final submittedInRange = await getSubmittedFormsInDateRange(from, to);
    
    final completionRates = <double>[];
    final riskScores = <double>[];
    
    for (final form in formsInRange) {
      completionRates.add(form.completionPercentage);
      riskScores.add(form.riskScore);
    }
    
    final avgCompletionRate = completionRates.isEmpty ? 0.0 : 
        completionRates.reduce((a, b) => a + b) / completionRates.length;
    final avgRiskScore = riskScores.isEmpty ? 0.0 : 
        riskScores.reduce((a, b) => a + b) / riskScores.length;
    
    return {
      'totalForms': formsInRange.length,
      'submittedForms': submittedInRange.length,
      'averageCompletionRate': avgCompletionRate,
      'averageRiskScore': avgRiskScore,
      'dateRange': {'from': from, 'to': to},
    };
  }
}