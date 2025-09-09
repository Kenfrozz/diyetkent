// Validation result class
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  
  const ValidationResult({
    required this.isValid,
    this.errorMessage,
  });
  
  static const ValidationResult valid = ValidationResult(isValid: true);
  
  static ValidationResult invalid(String message) {
    return ValidationResult(
      isValid: false,
      errorMessage: message,
    );
  }
}

// Form field validation rules
class FormValidators {
  // Yaş doğrulaması (18-100 yaş arası)
  static ValidationResult validateAge(int? age) {
    if (age == null) {
      return ValidationResult.invalid('Yaş gereklidir');
    }
    
    if (age < 18) {
      return ValidationResult.invalid('Yaş 18\'den küçük olamaz');
    }
    
    if (age > 100) {
      return ValidationResult.invalid('Yaş 100\'den büyük olamaz');
    }
    
    return ValidationResult.valid;
  }

  // Boy doğrulaması (cm cinsinden)
  static ValidationResult validateHeight(double? height) {
    if (height == null) {
      return ValidationResult.invalid('Boy gereklidir');
    }
    
    if (height < 100) {
      return ValidationResult.invalid('Boy 100 cm\'den küçük olamaz');
    }
    
    if (height > 250) {
      return ValidationResult.invalid('Boy 250 cm\'den büyük olamaz');
    }
    
    return ValidationResult.valid;
  }

  // Kilo doğrulaması (kg cinsinden)
  static ValidationResult validateWeight(double? weight) {
    if (weight == null) {
      return ValidationResult.invalid('Kilo gereklidir');
    }
    
    if (weight < 30) {
      return ValidationResult.invalid('Kilo 30 kg\'dan küçük olamaz');
    }
    
    if (weight > 300) {
      return ValidationResult.invalid('Kilo 300 kg\'dan büyük olamaz');
    }
    
    return ValidationResult.valid;
  }

  // BMI hesaplama ve doğrulama
  static ValidationResult validateBMI(double? height, double? weight) {
    if (height == null || weight == null) {
      return ValidationResult.invalid('Boy ve kilo değerleri gereklidir');
    }
    
    final heightValidation = validateHeight(height);
    if (!heightValidation.isValid) {
      return heightValidation;
    }
    
    final weightValidation = validateWeight(weight);
    if (!weightValidation.isValid) {
      return weightValidation;
    }
    
    final bmi = calculateBMI(height, weight);
    if (bmi < 10) {
      return ValidationResult.invalid('Hesaplanan BMI çok düşük (${bmi.toStringAsFixed(1)})');
    }
    
    if (bmi > 60) {
      return ValidationResult.invalid('Hesaplanan BMI çok yüksek (${bmi.toStringAsFixed(1)})');
    }
    
    return ValidationResult.valid;
  }

  // BMI hesaplama utility fonksiyonu
  static double calculateBMI(double height, double weight) {
    final heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  // BMI kategorisi belirleme
  static String getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Zayıf';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Fazla Kilolu';
    return 'Obez';
  }

  // BMI risk seviyesi (0-5 arası)
  static int getBMIRiskLevel(double bmi) {
    if (bmi < 16.0) return 4; // Çok zayıf - yüksek risk
    if (bmi < 18.5) return 2; // Zayıf - orta risk
    if (bmi < 25.0) return 0; // Normal - düşük risk
    if (bmi < 30.0) return 2; // Fazla kilolu - orta risk
    if (bmi < 35.0) return 3; // Obez - yüksek risk
    return 5; // Aşırı obez - çok yüksek risk
  }

  // E-mail doğrulaması
  static ValidationResult validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return ValidationResult.invalid('E-mail adresi gereklidir');
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(email)) {
      return ValidationResult.invalid('Geçerli bir e-mail adresi girin');
    }
    
    return ValidationResult.valid;
  }

  // Telefon numarası doğrulaması (Türkiye formatı)
  static ValidationResult validatePhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) {
      return ValidationResult.invalid('Telefon numarası gereklidir');
    }
    
    // Sadece rakam, +, -, (, ), boşluk karakterlerini kabul et
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Türkiye telefon formatları: +905xxxxxxxxx, 05xxxxxxxxx, 5xxxxxxxxx
    final phoneRegex = RegExp(r'^(\+90|90|0)?5\d{9}$');
    
    if (!phoneRegex.hasMatch(cleanPhone)) {
      return ValidationResult.invalid('Geçerli bir telefon numarası girin (05xxxxxxxxx)');
    }
    
    return ValidationResult.valid;
  }

  // Zorunlu metin alanı doğrulaması
  static ValidationResult validateRequiredText(String? text, {String fieldName = 'Alan'}) {
    if (text == null || text.trim().isEmpty) {
      return ValidationResult.invalid('$fieldName gereklidir');
    }
    
    if (text.trim().length < 2) {
      return ValidationResult.invalid('$fieldName en az 2 karakter olmalıdır');
    }
    
    return ValidationResult.valid;
  }

  // Opsiyonel metin alanı doğrulaması (minimum uzunluk kontrolü)
  static ValidationResult validateOptionalText(String? text, {int minLength = 0, int maxLength = 1000}) {
    if (text == null || text.trim().isEmpty) {
      return ValidationResult.valid; // Opsiyonel alan boş olabilir
    }
    
    if (text.trim().length < minLength) {
      return ValidationResult.invalid('En az $minLength karakter olmalıdır');
    }
    
    if (text.trim().length > maxLength) {
      return ValidationResult.invalid('En fazla $maxLength karakter olabilir');
    }
    
    return ValidationResult.valid;
  }

  // Sayı aralığı doğrulaması
  static ValidationResult validateNumberRange(double? value, {
    required double min,
    required double max,
    String fieldName = 'Değer',
  }) {
    if (value == null) {
      return ValidationResult.invalid('$fieldName gereklidir');
    }
    
    if (value < min) {
      return ValidationResult.invalid('$fieldName $min\'den küçük olamaz');
    }
    
    if (value > max) {
      return ValidationResult.invalid('$fieldName $max\'den büyük olamaz');
    }
    
    return ValidationResult.valid;
  }

  // Tam sayı aralığı doğrulaması
  static ValidationResult validateIntegerRange(int? value, {
    required int min,
    required int max,
    String fieldName = 'Değer',
  }) {
    if (value == null) {
      return ValidationResult.invalid('$fieldName gereklidir');
    }
    
    if (value < min) {
      return ValidationResult.invalid('$fieldName $min\'den küçük olamaz');
    }
    
    if (value > max) {
      return ValidationResult.invalid('$fieldName $max\'den büyük olamaz');
    }
    
    return ValidationResult.valid;
  }

  // Su tüketimi doğrulaması (litre/gün)
  static ValidationResult validateWaterIntake(double? waterIntake) {
    return validateNumberRange(
      waterIntake,
      min: 0.5,
      max: 10.0,
      fieldName: 'Günlük su tüketimi',
    );
  }

  // Egzersiz sıklığı doğrulaması (hafta/gün)
  static ValidationResult validateExerciseFrequency(int? frequency) {
    return validateIntegerRange(
      frequency,
      min: 0,
      max: 7,
      fieldName: 'Haftalık egzersiz sıklığı',
    );
  }

  // Egzersiz süresi doğrulaması (dakika)
  static ValidationResult validateExerciseDuration(int? duration) {
    return validateIntegerRange(
      duration,
      min: 0,
      max: 480, // 8 saat
      fieldName: 'Egzersiz süresi',
    );
  }

  // Motivasyon seviyesi doğrulaması (1-10)
  static ValidationResult validateMotivationLevel(int? level) {
    return validateIntegerRange(
      level,
      min: 1,
      max: 10,
      fieldName: 'Motivasyon seviyesi',
    );
  }

  // Zaman çerçevesi doğrulaması (hafta)
  static ValidationResult validateTimeframe(int? weeks) {
    return validateIntegerRange(
      weeks,
      min: 1,
      max: 104, // 2 yıl
      fieldName: 'Hedef zaman çerçevesi',
    );
  }

  // Liste seçimi doğrulaması
  static ValidationResult validateListSelection(List<String>? items, {
    bool isRequired = false,
    int minItems = 0,
    int maxItems = 20,
    String fieldName = 'Seçim',
  }) {
    if (items == null || items.isEmpty) {
      if (isRequired) {
        return ValidationResult.invalid('$fieldName gereklidir');
      }
      return ValidationResult.valid;
    }
    
    if (items.length < minItems) {
      return ValidationResult.invalid('$fieldName için en az $minItems seçim yapılmalıdır');
    }
    
    if (items.length > maxItems) {
      return ValidationResult.invalid('$fieldName için en fazla $maxItems seçim yapılabilir');
    }
    
    return ValidationResult.valid;
  }

  // Tam form doğrulaması
  static List<ValidationResult> validateCompleteForm({
    required int? age,
    required double? height,
    required double? weight,
    required double? targetWeight,
    required String? occupation,
    String? phoneNumber,
    String? emergencyContact,
    double? waterIntake,
    int? exerciseFrequency,
    int? exerciseDuration,
    int? motivationLevel,
    int? timeframeWeeks,
  }) {
    final List<ValidationResult> results = [];
    
    results.add(validateAge(age));
    results.add(validateHeight(height));
    results.add(validateWeight(weight));
    results.add(validateRequiredText(occupation, fieldName: 'Meslek'));
    
    if (height != null && weight != null) {
      results.add(validateBMI(height, weight));
    }
    
    if (targetWeight != null) {
      results.add(validateWeight(targetWeight));
    }
    
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      results.add(validatePhoneNumber(phoneNumber));
    }
    
    if (emergencyContact != null && emergencyContact.isNotEmpty) {
      results.add(validatePhoneNumber(emergencyContact));
    }
    
    if (waterIntake != null) {
      results.add(validateWaterIntake(waterIntake));
    }
    
    if (exerciseFrequency != null) {
      results.add(validateExerciseFrequency(exerciseFrequency));
    }
    
    if (exerciseDuration != null) {
      results.add(validateExerciseDuration(exerciseDuration));
    }
    
    if (motivationLevel != null) {
      results.add(validateMotivationLevel(motivationLevel));
    }
    
    if (timeframeWeeks != null) {
      results.add(validateTimeframe(timeframeWeeks));
    }
    
    return results;
  }

  // Hata mesajlarını toplu olarak alma
  static List<String> getErrorMessages(List<ValidationResult> results) {
    return results
        .where((result) => !result.isValid)
        .map((result) => result.errorMessage!)
        .toList();
  }

  // Tüm validasyonların geçip geçmediğini kontrol etme
  static bool isAllValid(List<ValidationResult> results) {
    return results.every((result) => result.isValid);
  }
}

// Flutter form validators (TextField için kullanım)
class FlutterFormValidators {
  // Age validator
  static String? age(String? value) {
    if (value == null || value.isEmpty) return 'Yaş gereklidir';
    final intValue = int.tryParse(value);
    final result = FormValidators.validateAge(intValue);
    return result.isValid ? null : result.errorMessage;
  }

  // Height validator
  static String? height(String? value) {
    if (value == null || value.isEmpty) return 'Boy gereklidir';
    final doubleValue = double.tryParse(value);
    final result = FormValidators.validateHeight(doubleValue);
    return result.isValid ? null : result.errorMessage;
  }

  // Weight validator
  static String? weight(String? value) {
    if (value == null || value.isEmpty) return 'Kilo gereklidir';
    final doubleValue = double.tryParse(value);
    final result = FormValidators.validateWeight(doubleValue);
    return result.isValid ? null : result.errorMessage;
  }

  // Email validator
  static String? email(String? value) {
    final result = FormValidators.validateEmail(value);
    return result.isValid ? null : result.errorMessage;
  }

  // Phone validator
  static String? phone(String? value) {
    final result = FormValidators.validatePhoneNumber(value);
    return result.isValid ? null : result.errorMessage;
  }

  // Required text validator
  static String? requiredText(String? value, {String fieldName = 'Alan'}) {
    final result = FormValidators.validateRequiredText(value, fieldName: fieldName);
    return result.isValid ? null : result.errorMessage;
  }

  // Optional text validator
  static String? optionalText(String? value, {int minLength = 0, int maxLength = 1000}) {
    final result = FormValidators.validateOptionalText(value, minLength: minLength, maxLength: maxLength);
    return result.isValid ? null : result.errorMessage;
  }
  
  // Required field validator (getter style for consistency)
  static String? required(String? value) {
    return requiredText(value);
  }
  
  // Positive number validator (getter style for consistency)
  static String? positiveNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Bu alan zorunludur';
    }

    final number = double.tryParse(value.trim());
    if (number == null) {
      return 'Geçerli bir sayı giriniz';
    }

    if (number <= 0) {
      return 'Pozitif bir sayı giriniz';
    }

    return null;
  }
}