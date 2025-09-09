import 'package:intl/intl.dart';
import '../models/user_model.dart';

/// Service for processing template variables and replacing them with user data
class TemplateProcessorService {
  static final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');
  static final DateFormat _longDateFormat = DateFormat('dd MMMM yyyy', 'tr_TR');

  /// Replace template variables in text with actual user data
  static String processTemplate(
    String templateContent, {
    required UserModel user,
    required DateTime startDate,
    required DateTime endDate,
    required DateTime controlDate,
    String? dietitianName,
    String? packageName,
    String? additionalNotes,
  }) {
    String processedContent = templateContent;

    // Calculate derived values
    final currentWeight = user.currentWeight ?? 0.0;
    final targetWeight = _calculateIdealWeight(user);
    final maxWeight = _calculateMaxWeight(user);
    final bmi = user.currentBMI ?? 0.0;

    // Template variable mappings
    final variables = {
      'userName': user.name ?? 'Kullanıcı',
      'userAge': (user.age ?? 0).toString(),
      'userHeight': (user.currentHeight ?? 0).toString(),
      'currentWeight': currentWeight.toStringAsFixed(1),
      'targetWeight': targetWeight.toStringAsFixed(1),
      'maxWeight': maxWeight.toStringAsFixed(1),
      'bmi': bmi.toStringAsFixed(1),
      'startDate': _dateFormat.format(startDate),
      'endDate': _dateFormat.format(endDate),
      'controlDate': _dateFormat.format(controlDate),
      'startDateLong': _longDateFormat.format(startDate),
      'endDateLong': _longDateFormat.format(endDate),
      'controlDateLong': _longDateFormat.format(controlDate),
      'dietitianName': dietitianName ?? 'Diyetisyen',
      'packageName': packageName ?? 'Diyet Paketi',
      'additionalNotes': additionalNotes ?? '',
      
      // BMI classification
      'bmiClassification': _getBmiClassification(bmi),
      
      // Date calculations
      'durationDays': endDate.difference(startDate).inDays.toString(),
      'daysTillControl': controlDate.difference(DateTime.now()).inDays.toString(),
      
      // Weight goals
      'weightToLose': (currentWeight - targetWeight).toStringAsFixed(1),
      'weightDifference': (currentWeight - targetWeight).abs().toStringAsFixed(1),
      
      // Current date and time
      'currentDate': _dateFormat.format(DateTime.now()),
      'currentDateLong': _longDateFormat.format(DateTime.now()),
      'currentYear': DateTime.now().year.toString(),
      'currentMonth': DateTime.now().month.toString(),
      
      // Phone and contact info
      'userPhone': user.phoneNumber ?? '',
    };

    // Replace all template variables
    variables.forEach((key, value) {
      // Replace both {{key}} and {{ key }} (with spaces)
      processedContent = processedContent.replaceAll(
        RegExp(r'\{\{\s*' + key + r'\s*\}\}', caseSensitive: false),
        value,
      );
    });

    return processedContent;
  }

  /// Calculate ideal weight based on user's age and height
  static double _calculateIdealWeight(UserModel user) {
    final height = user.currentHeight;
    final age = user.age;
    
    if (height == null || age == null || height <= 0) {
      return user.currentWeight ?? 70.0; // Default fallback
    }
    
    final heightInMeters = height / 100;
    
    // BMI-based ideal weight calculation by age groups
    double idealBmi;
    if (age < 35) {
      idealBmi = 21.0;
    } else if (age <= 45) {
      idealBmi = 22.0;
    } else {
      idealBmi = 23.0;
    }
    
    return heightInMeters * heightInMeters * idealBmi;
  }

  /// Calculate maximum recommended weight based on user's age and height
  static double _calculateMaxWeight(UserModel user) {
    final height = user.currentHeight;
    final age = user.age;
    
    if (height == null || age == null || height <= 0) {
      return (user.currentWeight ?? 70.0) * 1.2; // Default fallback
    }
    
    final heightInMeters = height / 100;
    
    // Maximum BMI by age groups
    double maxBmi;
    if (age < 35) {
      maxBmi = 27.0;
    } else if (age <= 45) {
      maxBmi = 28.0;
    } else {
      maxBmi = 30.0;
    }
    
    return heightInMeters * heightInMeters * maxBmi;
  }

  /// Get BMI classification in Turkish
  static String _getBmiClassification(double bmi) {
    if (bmi < 18.5) {
      return 'Zayıf';
    } else if (bmi < 25.0) {
      return 'Normal';
    } else if (bmi < 30.0) {
      return 'Fazla Kilolu';
    } else if (bmi < 35.0) {
      return 'Obez (1. Derece)';
    } else if (bmi < 40.0) {
      return 'Obez (2. Derece)';
    } else {
      return 'Morbid Obez';
    }
  }

  /// Generate filename for processed PDF
  static String generateFileName(
    UserModel user,
    DateTime startDate,
    DateTime endDate,
  ) {
    final userName = (user.name ?? 'Kullanici')
        .replaceAll(RegExp(r'[^\w\s-]'), '') // Remove special characters
        .replaceAll(RegExp(r'\s+'), ' ')     // Normalize spaces
        .trim();
    
    final startDateStr = _dateFormat.format(startDate);
    final endDateStr = _dateFormat.format(endDate);
    
    return '$userName - $startDateStr - $endDateStr.pdf';
  }

  /// Validate that all required user data exists for template processing
  static Map<String, dynamic> validateUserDataForTemplate(UserModel user) {
    final issues = <String>[];
    final warnings = <String>[];

    // Required fields
    if (user.name == null || user.name!.isEmpty) {
      issues.add('Kullanıcı adı eksik');
    }
    
    if (user.currentHeight == null || user.currentHeight! <= 0) {
      issues.add('Boy bilgisi eksik veya geçersiz');
    }
    
    if (user.currentWeight == null || user.currentWeight! <= 0) {
      issues.add('Kilo bilgisi eksik veya geçersiz');
    }
    
    if (user.age == null || user.age! <= 0) {
      warnings.add('Yaş bilgisi eksik veya geçersiz');
    }

    // Optional but recommended fields
    if (user.phoneNumber == null || user.phoneNumber!.isEmpty) {
      warnings.add('Telefon numarası eksik');
    }

    return {
      'isValid': issues.isEmpty,
      'issues': issues,
      'warnings': warnings,
      'canProceed': issues.isEmpty,
    };
  }

  /// Get a preview of how template variables will be replaced
  static Map<String, String> getTemplatePreview(
    UserModel user,
    DateTime startDate,
    DateTime endDate,
    DateTime controlDate, {
    String? dietitianName,
    String? packageName,
  }) {
    final currentWeight = user.currentWeight ?? 0.0;
    final targetWeight = _calculateIdealWeight(user);
    final bmi = user.currentBMI ?? 0.0;

    return {
      'userName': user.name ?? 'Kullanıcı',
      'currentWeight': currentWeight.toStringAsFixed(1),
      'targetWeight': targetWeight.toStringAsFixed(1),
      'bmi': bmi.toStringAsFixed(1),
      'startDate': _dateFormat.format(startDate),
      'endDate': _dateFormat.format(endDate),
      'controlDate': _dateFormat.format(controlDate),
      'bmiClassification': _getBmiClassification(bmi),
      'fileName': generateFileName(user, startDate, endDate),
    };
  }
}