import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Service for managing local file storage for diet files and PDFs
class LocalFileStorageService {
  static const String _dietPdfsFolder = 'diet_pdfs';
  static const String _dietTemplatesFolder = 'diet_templates';
  static const String _userUploadsFolder = 'user_uploads';
  static const String _tempFolder = 'temp';

  /// Initialize storage directories
  static Future<void> initializeStorage() async {
    try {
      await _createDirectoryIfNotExists(_dietPdfsFolder);
      await _createDirectoryIfNotExists(_dietTemplatesFolder);
      await _createDirectoryIfNotExists(_userUploadsFolder);
      await _createDirectoryIfNotExists(_tempFolder);
    } catch (e) {
      throw Exception('Failed to initialize storage: $e');
    }
  }

  /// Get application documents directory
  static Future<Directory> _getAppDocumentsDirectory() async {
    return await getApplicationDocumentsDirectory();
  }

  /// Create directory if it doesn't exist
  static Future<Directory> _createDirectoryIfNotExists(String folderName) async {
    final appDir = await _getAppDocumentsDirectory();
    final directory = Directory(path.join(appDir.path, folderName));
    
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    
    return directory;
  }

  /// Save PDF file to diet PDFs folder
  static Future<File> saveDietPdf(File pdfFile, String fileName) async {
    try {
      final dietPdfsDir = await _createDirectoryIfNotExists(_dietPdfsFolder);
      final destinationPath = path.join(dietPdfsDir.path, fileName);
      
      return await pdfFile.copy(destinationPath);
    } catch (e) {
      throw Exception('Failed to save diet PDF: $e');
    }
  }

  /// Save DOCX template to templates folder
  static Future<File> saveDietTemplate(File docxFile, String fileName) async {
    try {
      final templatesDir = await _createDirectoryIfNotExists(_dietTemplatesFolder);
      final destinationPath = path.join(templatesDir.path, fileName);
      
      return await docxFile.copy(destinationPath);
    } catch (e) {
      throw Exception('Failed to save diet template: $e');
    }
  }

  /// Save user uploaded file to user uploads folder
  static Future<File> saveUserUpload(File file, String fileName) async {
    try {
      final uploadsDir = await _createDirectoryIfNotExists(_userUploadsFolder);
      final destinationPath = path.join(uploadsDir.path, fileName);
      
      return await file.copy(destinationPath);
    } catch (e) {
      throw Exception('Failed to save user upload: $e');
    }
  }

  /// Save temporary file
  static Future<File> saveTempFile(File file, String fileName) async {
    try {
      final tempDir = await _createDirectoryIfNotExists(_tempFolder);
      final destinationPath = path.join(tempDir.path, fileName);
      
      return await file.copy(destinationPath);
    } catch (e) {
      throw Exception('Failed to save temporary file: $e');
    }
  }

  /// Get all PDF files from diet PDFs folder
  static Future<List<File>> getAllDietPdfs() async {
    try {
      final dietPdfsDir = await _createDirectoryIfNotExists(_dietPdfsFolder);
      final entities = await dietPdfsDir.list().toList();
      
      return entities
          .whereType<File>()
          .where((file) => file.path.endsWith('.pdf'))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get all DOCX template files
  static Future<List<File>> getAllDietTemplates() async {
    try {
      final templatesDir = await _createDirectoryIfNotExists(_dietTemplatesFolder);
      final entities = await templatesDir.list().toList();
      
      return entities
          .whereType<File>()
          .where((file) => file.path.endsWith('.docx'))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Find PDF file by name
  static Future<File?> findDietPdf(String fileName) async {
    try {
      final dietPdfsDir = await _createDirectoryIfNotExists(_dietPdfsFolder);
      final filePath = path.join(dietPdfsDir.path, fileName);
      final file = File(filePath);
      
      return await file.exists() ? file : null;
    } catch (e) {
      return null;
    }
  }

  /// Find template file by name
  static Future<File?> findDietTemplate(String fileName) async {
    try {
      final templatesDir = await _createDirectoryIfNotExists(_dietTemplatesFolder);
      final filePath = path.join(templatesDir.path, fileName);
      final file = File(filePath);
      
      return await file.exists() ? file : null;
    } catch (e) {
      return null;
    }
  }

  /// Delete file from storage
  static Future<bool> deleteFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get file size in bytes
  static Future<int> getFileSize(File file) async {
    try {
      return await file.length();
    } catch (e) {
      return 0;
    }
  }

  /// Get human readable file size
  static String getReadableFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Clean up temporary files older than specified hours
  static Future<int> cleanupTempFiles({int maxAgeHours = 24}) async {
    try {
      final tempDir = await _createDirectoryIfNotExists(_tempFolder);
      final entities = await tempDir.list().toList();
      final cutoffTime = DateTime.now().subtract(Duration(hours: maxAgeHours));
      int deletedCount = 0;

      for (final entity in entities) {
        if (entity is File) {
          final stat = await entity.stat();
          if (stat.modified.isBefore(cutoffTime)) {
            try {
              await entity.delete();
              deletedCount++;
            } catch (_) {
              // Ignore deletion errors for individual files
            }
          }
        }
      }

      return deletedCount;
    } catch (e) {
      return 0;
    }
  }

  /// Get storage usage statistics
  static Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final pdfsDir = await _createDirectoryIfNotExists(_dietPdfsFolder);
      final templatesDir = await _createDirectoryIfNotExists(_dietTemplatesFolder);
      final uploadsDir = await _createDirectoryIfNotExists(_userUploadsFolder);
      final tempDir = await _createDirectoryIfNotExists(_tempFolder);

      final stats = {
        'dietPdfs': await _getDirectoryStats(pdfsDir),
        'dietTemplates': await _getDirectoryStats(templatesDir),
        'userUploads': await _getDirectoryStats(uploadsDir),
        'tempFiles': await _getDirectoryStats(tempDir),
      };

      // Calculate totals
      final totalFiles = stats.values.map((s) => s['fileCount'] as int).reduce((a, b) => a + b);
      final totalSize = stats.values.map((s) => s['totalSize'] as int).reduce((a, b) => a + b);

      stats['summary'] = {
        'totalFiles': totalFiles,
        'totalSize': totalSize,
        'totalSizeReadable': getReadableFileSize(totalSize),
      };

      return stats;
    } catch (e) {
      return {
        'error': 'Failed to get storage stats: $e',
      };
    }
  }

  /// Get directory statistics (file count and total size)
  static Future<Map<String, dynamic>> _getDirectoryStats(Directory dir) async {
    try {
      final entities = await dir.list().toList();
      final files = entities.whereType<File>();
      int totalSize = 0;
      int fileCount = 0;

      for (final file in files) {
        try {
          totalSize += await file.length();
          fileCount++;
        } catch (_) {
          // Skip files that can't be read
        }
      }

      return {
        'fileCount': fileCount,
        'totalSize': totalSize,
        'totalSizeReadable': getReadableFileSize(totalSize),
      };
    } catch (e) {
      return {
        'fileCount': 0,
        'totalSize': 0,
        'totalSizeReadable': '0 B',
      };
    }
  }

  /// Clear all files from a specific folder
  static Future<int> clearFolder(String folderName) async {
    try {
      final directory = await _createDirectoryIfNotExists(folderName);
      final entities = await directory.list().toList();
      int deletedCount = 0;

      for (final entity in entities) {
        try {
          await entity.delete(recursive: true);
          deletedCount++;
        } catch (_) {
          // Ignore individual deletion errors
        }
      }

      return deletedCount;
    } catch (e) {
      return 0;
    }
  }

  /// Get available disk space (approximate)
  static Future<Map<String, dynamic>?> getAvailableSpace() async {
    try {
      final appDir = await _getAppDocumentsDirectory();
      final stat = await appDir.stat();
      
      // Note: This is a simplified approach. For accurate disk space,
      // you might need platform-specific implementations
      return {
        'path': appDir.path,
        'lastModified': stat.modified.toString(),
        'note': 'Use platform-specific methods for accurate disk space information',
      };
    } catch (e) {
      return null;
    }
  }

  /// Generate unique filename with timestamp
  static String generateUniqueFileName(String baseName, String extension) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final cleanBaseName = baseName.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
    return '${cleanBaseName}_$timestamp.$extension';
  }

  /// Validate filename for safety
  static bool isValidFileName(String fileName) {
    // Check for dangerous characters and patterns
    final dangerousPatterns = [
      RegExp(r'[<>:"/\\|?*]'), // Windows forbidden characters
      RegExp(r'^\s*$'), // Empty or whitespace only
      RegExp(r'^\.|\.{2,}'), // Starting with dot or multiple dots
      RegExp(r'(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(\.|$)', caseSensitive: false), // Windows reserved names
    ];

    for (final pattern in dangerousPatterns) {
      if (pattern.hasMatch(fileName)) {
        return false;
      }
    }

    // Check length (most filesystems have limits)
    return fileName.isNotEmpty && fileName.length <= 255;
  }
}