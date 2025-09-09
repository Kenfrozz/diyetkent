import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../models/user_model.dart';
import 'docx_parser_service.dart';
import 'template_processor_service.dart';

/// Service for generating PDF files from DOCX templates with user data
class PdfGenerationService {
  /// Generate PDF from DOCX template with user data
  static Future<File> generateDietPdfFromTemplate({
    required File docxTemplate,
    required UserModel user,
    required DateTime startDate,
    required DateTime endDate,
    required DateTime controlDate,
    String? dietitianName,
    String? packageName,
    String? additionalNotes,
    String? customFileName,
  }) async {
    try {
      // Step 1: Parse DOCX template
      final templateContent = await DocxParserService.parseDocxTemplate(docxTemplate);
      
      // Step 2: Process template with user data
      final processedContent = TemplateProcessorService.processTemplate(
        templateContent,
        user: user,
        startDate: startDate,
        endDate: endDate,
        controlDate: controlDate,
        dietitianName: dietitianName,
        packageName: packageName,
        additionalNotes: additionalNotes,
      );

      // Step 3: Generate PDF
      return await generatePdfFromText(
        content: processedContent,
        user: user,
        startDate: startDate,
        endDate: endDate,
        fileName: customFileName,
        title: packageName ?? 'Diyet Programı',
      );
    } catch (e) {
      throw Exception('PDF generation failed: $e');
    }
  }

  /// Generate PDF directly from processed text content
  static Future<File> generatePdfFromText({
    required String content,
    required UserModel user,
    required DateTime startDate,
    required DateTime endDate,
    String? fileName,
    String? title,
    String? subtitle,
  }) async {
    try {
      // Create PDF document
      final pdf = pw.Document();

      // Generate filename if not provided
      fileName ??= TemplateProcessorService.generateFileName(user, startDate, endDate);

      // Add PDF pages
      await _addContentToPdf(
        pdf: pdf,
        content: content,
        user: user,
        title: title ?? 'Diyet Programı',
        subtitle: subtitle,
      );

      // Save to file
      return await _savePdfToFile(pdf, fileName);
    } catch (e) {
      throw Exception('PDF generation from text failed: $e');
    }
  }

  /// Add content to PDF document with proper formatting
  static Future<void> _addContentToPdf({
    required pw.Document pdf,
    required String content,
    required UserModel user,
    String? title,
    String? subtitle,
  }) async {
    // Split content into paragraphs
    final paragraphs = content.split('\n').where((p) => p.trim().isNotEmpty).toList();
    
    // Create PDF page(s)
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          final widgets = <pw.Widget>[];

          // Header section
          widgets.addAll(_buildPdfHeader(user, title, subtitle));

          // Content sections
          for (final paragraph in paragraphs) {
            widgets.add(_buildParagraph(paragraph.trim()));
          }

          // Footer
          widgets.add(pw.SizedBox(height: 20));
          widgets.add(_buildPdfFooter());

          return widgets;
        },
      ),
    );
  }

  /// Build PDF header section
  static List<pw.Widget> _buildPdfHeader(UserModel user, String? title, String? subtitle) {
    return [
      // Title
      if (title != null)
        pw.Container(
          alignment: pw.Alignment.center,
          margin: const pw.EdgeInsets.only(bottom: 10),
          child: pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),

      // Subtitle
      if (subtitle != null)
        pw.Container(
          alignment: pw.Alignment.center,
          margin: const pw.EdgeInsets.only(bottom: 20),
          child: pw.Text(
            subtitle,
            style: const pw.TextStyle(fontSize: 16, color: PdfColors.grey700),
          ),
        ),

      // User info section
      pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 20),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400),
          borderRadius: pw.BorderRadius.circular(5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Kişisel Bilgiler',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 5),
            pw.Text('Adı Soyadı: ${user.name ?? "Belirtilmemiş"}'),
            if (user.age != null) pw.Text('Yaş: ${user.age}'),
            if (user.currentHeight != null) pw.Text('Boy: ${user.currentHeight} cm'),
            if (user.currentWeight != null) pw.Text('Kilo: ${user.currentWeight} kg'),
            if (user.currentBMI != null) pw.Text('BMI: ${user.currentBMI!.toStringAsFixed(1)}'),
          ],
        ),
      ),

      pw.SizedBox(height: 20),
    ];
  }

  /// Build paragraph widget with proper text formatting
  static pw.Widget _buildParagraph(String text) {
    // Check if this looks like a heading (short line, possibly uppercase)
    final isHeading = text.length < 50 && 
                     (text == text.toUpperCase() || text.contains(':'));

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeading ? 14 : 12,
          fontWeight: isHeading ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: isHeading ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }

  /// Build PDF footer
  static pw.Widget _buildPdfFooter() {
    return pw.Container(
      alignment: pw.Alignment.center,
      child: pw.Column(
        children: [
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 10),
          pw.Text(
            'DiyetKent - Dijital Diyet Yönetim Sistemi',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
          pw.Text(
            'Oluşturulma Tarihi: ${DateTime.now().toString().substring(0, 19)}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }

  /// Save PDF document to file
  static Future<File> _savePdfToFile(pw.Document pdf, String fileName) async {
    try {
      // Get app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final pdfDirectory = Directory('${directory.path}/diet_pdfs');
      
      // Create directory if it doesn't exist
      if (!await pdfDirectory.exists()) {
        await pdfDirectory.create(recursive: true);
      }

      // Create file path
      final filePath = '${pdfDirectory.path}/$fileName';
      final file = File(filePath);

      // Generate and save PDF bytes
      final pdfBytes = await pdf.save();
      await file.writeAsBytes(pdfBytes);

      return file;
    } catch (e) {
      throw Exception('Failed to save PDF file: $e');
    }
  }

  /// Generate quick PDF for testing (without template)
  static Future<File> generateTestPdf({
    required UserModel user,
    String? customContent,
  }) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Test PDF', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Text('Kullanıcı: ${user.name ?? "Test User"}'),
            pw.Text('BMI: ${user.currentBMI?.toStringAsFixed(1) ?? "N/A"}'),
            pw.SizedBox(height: 20),
            pw.Text(customContent ?? 'Bu bir test PDF dosyasıdır.'),
          ],
        ),
      ),
    );

    final fileName = 'test_${DateTime.now().millisecondsSinceEpoch}.pdf';
    return await _savePdfToFile(pdf, fileName);
  }

  /// Get all generated PDF files
  static Future<List<File>> getAllGeneratedPdfs() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final pdfDirectory = Directory('${directory.path}/diet_pdfs');
      
      if (!await pdfDirectory.exists()) {
        return [];
      }

      final files = await pdfDirectory.list().toList();
      return files.whereType<File>().where((f) => f.path.endsWith('.pdf')).toList();
    } catch (e) {
      return [];
    }
  }

  /// Delete generated PDF file
  static Future<bool> deletePdf(File pdfFile) async {
    try {
      if (await pdfFile.exists()) {
        await pdfFile.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get PDF file size in readable format
  static String getFileSizeString(File file) {
    final bytes = file.lengthSync();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Validate PDF generation requirements
  static Map<String, dynamic> validatePdfRequirements({
    required UserModel user,
    File? docxTemplate,
  }) {
    final issues = <String>[];
    final warnings = <String>[];

    // Validate user data
    final userValidation = TemplateProcessorService.validateUserDataForTemplate(user);
    if (!userValidation['isValid']) {
      issues.addAll(userValidation['issues'] as List<String>);
    }
    warnings.addAll(userValidation['warnings'] as List<String>);

    // Validate template file if provided
    if (docxTemplate != null) {
      if (!docxTemplate.existsSync()) {
        issues.add('DOCX template file does not exist');
      } else if (!docxTemplate.path.endsWith('.docx')) {
        warnings.add('Template file might not be a valid DOCX file');
      }
    }

    return {
      'isValid': issues.isEmpty,
      'issues': issues,
      'warnings': warnings,
      'canProceed': issues.isEmpty,
    };
  }
}