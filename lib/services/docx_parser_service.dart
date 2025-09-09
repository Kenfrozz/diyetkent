import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

/// Service for parsing DOCX templates and extracting content
class DocxParserService {
  /// Parse a DOCX file and extract text content with template variables
  static Future<String> parseDocxTemplate(File docxFile) async {
    try {
      // Read DOCX file as bytes
      final bytes = await docxFile.readAsBytes();
      return parseDocxFromBytes(bytes);
    } catch (e) {
      throw Exception('Failed to parse DOCX file: $e');
    }
  }

  /// Parse DOCX from bytes and extract text content
  static String parseDocxFromBytes(Uint8List bytes) {
    try {
      // DOCX is a ZIP archive, extract it
      final archive = ZipDecoder().decodeBytes(bytes);
      
      // Find the main document file (word/document.xml)
      ArchiveFile? documentXml;
      for (final file in archive) {
        if (file.name == 'word/document.xml') {
          documentXml = file;
          break;
        }
      }
      
      if (documentXml == null) {
        throw Exception('Could not find document.xml in DOCX file');
      }
      
      // Parse the XML content
      final xmlContent = String.fromCharCodes(documentXml.content as List<int>);
      final document = XmlDocument.parse(xmlContent);
      
      // Extract text content from paragraphs
      return _extractTextFromXml(document);
    } catch (e) {
      throw Exception('Failed to parse DOCX bytes: $e');
    }
  }

  /// Extract text content from XML document
  static String _extractTextFromXml(XmlDocument document) {
    final buffer = StringBuffer();
    
    // Find all paragraph (w:p) elements
    final paragraphs = document.findAllElements('w:p');
    
    for (final paragraph in paragraphs) {
      final paragraphText = _extractParagraphText(paragraph);
      if (paragraphText.isNotEmpty) {
        buffer.writeln(paragraphText);
      }
    }
    
    return buffer.toString().trim();
  }

  /// Extract text from a single paragraph element
  static String _extractParagraphText(XmlElement paragraph) {
    final buffer = StringBuffer();
    
    // Find all text runs (w:r) in the paragraph
    final runs = paragraph.findAllElements('w:r');
    
    for (final run in runs) {
      // Find text elements (w:t) in the run
      final textElements = run.findAllElements('w:t');
      for (final textElement in textElements) {
        buffer.write(textElement.innerText);
      }
    }
    
    return buffer.toString();
  }

  /// Extract template variables from text (e.g., {{userName}}, {{startDate}})
  static List<String> extractTemplateVariables(String text) {
    final regex = RegExp(r'\{\{([^}]+)\}\}');
    final matches = regex.allMatches(text);
    
    return matches.map((match) => match.group(1)!.trim()).toList();
  }

  /// Get template structure with variables for validation
  static Future<Map<String, dynamic>> analyzeTemplate(File docxFile) async {
    final content = await parseDocxTemplate(docxFile);
    final variables = extractTemplateVariables(content);
    
    return {
      'content': content,
      'variables': variables,
      'wordCount': content.split(' ').length,
      'characterCount': content.length,
      'hasTemplateVariables': variables.isNotEmpty,
    };
  }

  /// Validate that required template variables exist
  static bool validateTemplateVariables(
    String content,
    List<String> requiredVariables,
  ) {
    final foundVariables = extractTemplateVariables(content);
    
    for (final required in requiredVariables) {
      if (!foundVariables.contains(required)) {
        return false;
      }
    }
    
    return true;
  }

  /// Get common template variables used in diet files
  static List<String> getCommonDietTemplateVariables() {
    return [
      'userName',        // Kullanıcı adı soyadı
      'userAge',         // Kullanıcı yaşı
      'userHeight',      // Kullanıcı boyu (cm)
      'currentWeight',   // Mevcut kilo (kg)
      'targetWeight',    // Hedef kilo (kg)
      'maxWeight',       // Geçmemesi gereken kilo (kg)
      'bmi',             // BMI değeri
      'startDate',       // Başlangıç tarihi
      'endDate',         // Bitiş tarihi
      'controlDate',     // Kontrol tarihi
      'dietitianName',   // Diyetisyen adı
      'packageName',     // Paket adı
    ];
  }
}