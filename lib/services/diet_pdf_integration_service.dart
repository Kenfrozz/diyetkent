import 'dart:io';
import '../models/user_model.dart';
import '../models/user_diet_assignment_model.dart';
import '../database/drift_service.dart';
import 'pdf_generation_service.dart';
import 'local_file_storage_service.dart';
import 'template_processor_service.dart';

/// Integration service that combines PDF generation with diet management system
class DietPdfIntegrationService {
  
  /// Generate personalized diet PDF for a user assignment
  static Future<File> generatePersonalizedDietPdf({
    required UserDietAssignmentModel assignment,
    required File dietTemplate,
    String? customNotes,
  }) async {
    try {
      // Get user data
      final user = await DriftService.getUserById(assignment.userId);
      if (user == null) {
        throw Exception('User not found: ${assignment.userId}');
      }

      // Get package data
      final package = await DriftService.getDietPackage(assignment.packageId);
      if (package == null) {
        throw Exception('Diet package not found: ${assignment.packageId}');
      }

      // Get dietitian data (if available)
      final dietitian = await DriftService.getUserById(assignment.dietitianId);

      // Calculate dates based on assignment
      final startDate = assignment.startDate;
      final endDate = assignment.endDate;
      final controlDate = assignment.nextCheckDate ?? endDate.add(const Duration(days: 3));

      // Generate PDF
      final pdfFile = await PdfGenerationService.generateDietPdfFromTemplate(
        docxTemplate: dietTemplate,
        user: user,
        startDate: startDate,
        endDate: endDate,
        controlDate: controlDate,
        dietitianName: dietitian?.name,
        packageName: package.name,
        additionalNotes: customNotes,
      );

      // Save to permanent storage
      final fileName = TemplateProcessorService.generateFileName(user, startDate, endDate);
      final savedFile = await LocalFileStorageService.saveDietPdf(pdfFile, fileName);

      // Update assignment with PDF path
      assignment.generatedPdfPath = savedFile.path;
      assignment.pdfGeneratedAt = DateTime.now();
      await DriftService.saveUserDietAssignment(assignment);

      return savedFile;
    } catch (e) {
      throw Exception('Failed to generate personalized diet PDF: $e');
    }
  }

  /// Generate multiple PDFs for bulk diet assignments
  static Future<List<Map<String, dynamic>>> generateBulkDietPdfs({
    required List<UserDietAssignmentModel> assignments,
    required Map<String, File> dietTemplates, // BMI range -> template file
    Function(int current, int total)? onProgress,
  }) async {
    final results = <Map<String, dynamic>>[];
    int current = 0;

    for (final assignment in assignments) {
      current++;
      onProgress?.call(current, assignments.length);

      try {
        // Get user for BMI calculation
        final user = await DriftService.getUserById(assignment.userId);
        if (user == null) {
          results.add({
            'assignmentId': assignment.assignmentId,
            'success': false,
            'error': 'User not found',
          });
          continue;
        }

        // Determine BMI range and get appropriate template
        final bmiRange = _getBmiRangeForUser(user);
        final template = dietTemplates[bmiRange];
        
        if (template == null) {
          results.add({
            'assignmentId': assignment.assignmentId,
            'success': false,
            'error': 'No template found for BMI range: $bmiRange',
          });
          continue;
        }

        // Generate PDF
        final pdfFile = await generatePersonalizedDietPdf(
          assignment: assignment,
          dietTemplate: template,
        );

        results.add({
          'assignmentId': assignment.assignmentId,
          'success': true,
          'pdfFile': pdfFile,
          'fileName': pdfFile.path.split('/').last,
        });

      } catch (e) {
        results.add({
          'assignmentId': assignment.assignmentId,
          'success': false,
          'error': e.toString(),
        });
      }
    }

    return results;
  }

  /// Get BMI range classification for template selection
  static String _getBmiRangeForUser(UserModel user) {
    final bmi = user.currentBMI;
    if (bmi == null) return '21_25bmi'; // Default to normal range

    if (bmi >= 21 && bmi <= 25) return '21_25bmi';
    if (bmi >= 26 && bmi <= 29) return '26_29bmi';
    if (bmi >= 30 && bmi <= 33) return '30_33bmi';
    if (bmi >= 34 && bmi <= 37) return '34_37bmi';
    
    // Handle edge cases
    if (bmi < 21) return '21_25bmi'; // Underweight -> normal template
    return '34_37bmi'; // Severely obese -> highest range template
  }

  /// Create diet assignment with automatic PDF generation
  static Future<UserDietAssignmentModel> createAssignmentWithPdf({
    required String userId,
    required String dietitianId,
    required String packageId,
    required DateTime startDate,
    required File dietTemplate,
    String? customNotes,
  }) async {
    try {
      // Create assignment
      final assignment = UserDietAssignmentModel.create(
        assignmentId: 'assign_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        dietitianId: dietitianId,
        packageId: packageId,
        startDate: startDate,
        endDate: startDate.add(const Duration(days: 30)), // Default 30 days
        status: AssignmentStatus.active,
      );

      // Save assignment first
      await DriftService.saveUserDietAssignment(assignment);

      // Generate PDF
      await generatePersonalizedDietPdf(
        assignment: assignment,
        dietTemplate: dietTemplate,
        customNotes: customNotes,
      );

      return assignment;
    } catch (e) {
      throw Exception('Failed to create assignment with PDF: $e');
    }
  }

  /// Get all diet PDFs for a user
  static Future<List<Map<String, dynamic>>> getUserDietPdfs(String userId) async {
    try {
      final assignments = await DriftService.getUserDietAssignments(userId);
      final pdfInfos = <Map<String, dynamic>>[];

      for (final assignment in assignments) {
        if (assignment.generatedPdfPath != null) {
          final file = File(assignment.generatedPdfPath!);
          if (await file.exists()) {
            final package = await DriftService.getDietPackage(assignment.packageId);
            final fileSize = await LocalFileStorageService.getFileSize(file);

            pdfInfos.add({
              'assignment': assignment,
              'file': file,
              'fileName': file.path.split('/').last,
              'fileSize': fileSize,
              'fileSizeReadable': LocalFileStorageService.getReadableFileSize(fileSize),
              'packageName': package?.name ?? 'Bilinmeyen Paket',
              'generatedAt': assignment.pdfGeneratedAt,
              'startDate': assignment.startDate,
              'endDate': assignment.endDate,
            });
          }
        }
      }

      // Sort by generation date (newest first)
      pdfInfos.sort((a, b) => (b['generatedAt'] as DateTime?)?.compareTo(
        a['generatedAt'] as DateTime? ?? DateTime.fromMillisecondsSinceEpoch(0)
      ) ?? 0);

      return pdfInfos;
    } catch (e) {
      throw Exception('Failed to get user diet PDFs: $e');
    }
  }

  /// Get all assignments that need PDF generation
  static Future<List<UserDietAssignmentModel>> getAssignmentsNeedingPdfGeneration() async {
    try {
      final activeAssignments = await DriftService.getAllActiveAssignments();
      return activeAssignments.where((assignment) => 
        assignment.generatedPdfPath == null || 
        !File(assignment.generatedPdfPath!).existsSync()
      ).toList();
    } catch (e) {
      return [];
    }
  }

  /// Regenerate PDF for an existing assignment
  static Future<File> regenerateDietPdf({
    required UserDietAssignmentModel assignment,
    required File dietTemplate,
    String? customNotes,
    bool deleteOldPdf = true,
  }) async {
    try {
      // Delete old PDF if requested and exists
      if (deleteOldPdf && assignment.generatedPdfPath != null) {
        final oldFile = File(assignment.generatedPdfPath!);
        if (await oldFile.exists()) {
          await LocalFileStorageService.deleteFile(oldFile);
        }
      }

      // Clear PDF reference
      assignment.generatedPdfPath = null;
      assignment.pdfGeneratedAt = null;

      // Generate new PDF
      return await generatePersonalizedDietPdf(
        assignment: assignment,
        dietTemplate: dietTemplate,
        customNotes: customNotes,
      );
    } catch (e) {
      throw Exception('Failed to regenerate diet PDF: $e');
    }
  }

  /// Preview PDF generation (without saving)
  static Future<Map<String, dynamic>> previewPdfGeneration({
    required UserModel user,
    required DateTime startDate,
    required DateTime endDate,
    required DateTime controlDate,
    String? packageName,
    String? dietitianName,
  }) async {
    try {
      // Validate user data
      final validation = TemplateProcessorService.validateUserDataForTemplate(user);
      if (!validation['isValid']) {
        return {
          'success': false,
          'errors': validation['issues'],
          'warnings': validation['warnings'],
        };
      }

      // Get template preview
      final preview = TemplateProcessorService.getTemplatePreview(
        user,
        startDate,
        endDate,
        controlDate,
        packageName: packageName,
        dietitianName: dietitianName,
      );

      return {
        'success': true,
        'preview': preview,
        'validation': validation,
        'bmiRange': _getBmiRangeForUser(user),
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Clean up orphaned PDF files (PDFs without corresponding assignments)
  static Future<int> cleanupOrphanedPdfs() async {
    try {
      final allPdfs = await LocalFileStorageService.getAllDietPdfs();
      final allAssignments = await DriftService.getAllActiveAssignments();
      
      final assignmentPdfPaths = allAssignments
          .where((a) => a.generatedPdfPath != null)
          .map((a) => a.generatedPdfPath!)
          .toSet();

      int deletedCount = 0;
      for (final pdf in allPdfs) {
        if (!assignmentPdfPaths.contains(pdf.path)) {
          if (await LocalFileStorageService.deleteFile(pdf)) {
            deletedCount++;
          }
        }
      }

      return deletedCount;
    } catch (e) {
      return 0;
    }
  }

  /// Get comprehensive diet PDF statistics
  static Future<Map<String, dynamic>> getDietPdfStatistics() async {
    try {
      final allAssignments = await DriftService.getAllActiveAssignments();
      final assignmentsWithPdf = allAssignments.where((a) => a.generatedPdfPath != null).length;
      final assignmentsWithoutPdf = allAssignments.length - assignmentsWithPdf;
      
      final allPdfs = await LocalFileStorageService.getAllDietPdfs();
      int totalPdfSize = 0;
      for (final pdf in allPdfs) {
        totalPdfSize += await LocalFileStorageService.getFileSize(pdf);
      }

      return {
        'totalAssignments': allAssignments.length,
        'assignmentsWithPdf': assignmentsWithPdf,
        'assignmentsWithoutPdf': assignmentsWithoutPdf,
        'totalPdfs': allPdfs.length,
        'totalPdfSize': totalPdfSize,
        'totalPdfSizeReadable': LocalFileStorageService.getReadableFileSize(totalPdfSize),
        'averagePdfSize': allPdfs.isNotEmpty ? (totalPdfSize / allPdfs.length).round() : 0,
        'coveragePercentage': allAssignments.isNotEmpty 
            ? (assignmentsWithPdf / allAssignments.length * 100).round() 
            : 0,
      };
    } catch (e) {
      return {
        'error': 'Failed to get statistics: $e',
      };
    }
  }
}