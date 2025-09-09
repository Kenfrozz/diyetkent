import '../utils/timezone_helper.dart';
import '../utils/holiday_helper.dart';
import 'package:timezone/timezone.dart' as tz;

// Zamanlama kuralı türleri
enum ScheduleRule {
  daily,     // Her gün
  weekly,    // Haftalık
  monthly,   // Aylık
  custom,    // Özel cron expression
}

// Haftanın günleri
enum WeekDay {
  monday(1),
  tuesday(2),
  wednesday(3),
  thursday(4),
  friday(5),
  saturday(6),
  sunday(7);
  
  const WeekDay(this.value);
  final int value;
  
  static WeekDay fromValue(int value) {
    return WeekDay.values.firstWhere((day) => day.value == value);
  }
}

// Aylık teslimat tipi
enum MonthlyDeliveryType {
  specificDates,  // Belirli tarihler (1, 15 gibi)
  firstWeek,     // Ayın ilk haftası
  lastWeek,      // Ayın son haftası
  everyTwoWeeks, // İki haftada bir
}

// Delivery Schedule durumları
enum ScheduleStatus {
  active,     // Aktif
  paused,     // Duraklatılmış
  completed,  // Tamamlanmış
  cancelled,  // İptal edilmiş
}

// Cron Expression Parser ve Validator
class CronExpression {
  final String expression;
  final List<String> fields;
  
  // Cron formatı: dakika saat gün ay haftanın_günü
  // Örnek: "0 9 * * 1" = Her Pazartesi saat 09:00
  CronExpression(this.expression) : fields = expression.split(' ') {
    if (fields.length != 5) {
      throw ArgumentError('Cron expression must have 5 fields: $expression');
    }
  }
  
  String get minute => fields[0];
  String get hour => fields[1];
  String get dayOfMonth => fields[2];
  String get month => fields[3];
  String get dayOfWeek => fields[4];
  
  bool isValid() {
    try {
      _validateField(minute, 0, 59, 'minute');
      _validateField(hour, 0, 23, 'hour');
      _validateField(dayOfMonth, 1, 31, 'day of month');
      _validateField(month, 1, 12, 'month');
      _validateField(dayOfWeek, 0, 7, 'day of week');
      return true;
    } catch (e) {
      return false;
    }
  }
  
  void _validateField(String field, int min, int max, String fieldName) {
    if (field == '*') return;
    
    // Comma separated values: "1,3,5"
    if (field.contains(',')) {
      final values = field.split(',');
      for (final value in values) {
        final intValue = int.tryParse(value.trim());
        if (intValue == null || intValue < min || intValue > max) {
          throw ArgumentError('Invalid $fieldName value: $value');
        }
      }
      return;
    }
    
    // Range values: "1-5"
    if (field.contains('-')) {
      final parts = field.split('-');
      if (parts.length != 2) {
        throw ArgumentError('Invalid range format for $fieldName: $field');
      }
      final start = int.tryParse(parts[0].trim());
      final end = int.tryParse(parts[1].trim());
      if (start == null || end == null || start < min || end > max || start > end) {
        throw ArgumentError('Invalid range for $fieldName: $field');
      }
      return;
    }
    
    // Step values: "*/2" or "1-10/2"
    if (field.contains('/')) {
      final parts = field.split('/');
      if (parts.length != 2) {
        throw ArgumentError('Invalid step format for $fieldName: $field');
      }
      final step = int.tryParse(parts[1].trim());
      if (step == null || step <= 0) {
        throw ArgumentError('Invalid step value for $fieldName: ${parts[1]}');
      }
      
      // Validate the base part
      if (parts[0] != '*') {
        _validateField(parts[0], min, max, fieldName);
      }
      return;
    }
    
    // Single value
    final intValue = int.tryParse(field);
    if (intValue == null || intValue < min || intValue > max) {
      throw ArgumentError('Invalid $fieldName value: $field');
    }
  }
  
  @override
  String toString() => expression;
  
  @override
  bool operator ==(Object other) {
    return other is CronExpression && other.expression == expression;
  }
  
  @override
  int get hashCode => expression.hashCode;
}

// Next Run Calculator - Bir sonraki çalışma zamanını hesaplar
class NextRunCalculator {
  static DateTime? calculateNext(CronExpression cron, DateTime from) {
    try {
      DateTime candidate = DateTime(
        from.year,
        from.month,
        from.day,
        from.hour,
        from.minute,
      );
      
      // Bir dakika sonradan başla
      candidate = candidate.add(const Duration(minutes: 1));
      
      // Maksimum 4 yıl içinde ara
      final maxDate = from.add(const Duration(days: 365 * 4));
      
      while (candidate.isBefore(maxDate)) {
        if (_matchesCron(cron, candidate)) {
          return candidate;
        }
        candidate = candidate.add(const Duration(minutes: 1));
      }
      
      return null; // Bulunamadı
    } catch (e) {
      return null;
    }
  }
  
  static List<DateTime> calculateNextN(CronExpression cron, DateTime from, int count) {
    final List<DateTime> results = [];
    DateTime current = from;
    
    for (int i = 0; i < count; i++) {
      final next = calculateNext(cron, current);
      if (next == null) break;
      results.add(next);
      current = next;
    }
    
    return results;
  }
  
  static bool _matchesCron(CronExpression cron, DateTime dateTime) {
    return _matchesField(cron.minute, dateTime.minute) &&
           _matchesField(cron.hour, dateTime.hour) &&
           _matchesField(cron.dayOfMonth, dateTime.day) &&
           _matchesField(cron.month, dateTime.month) &&
           _matchesField(cron.dayOfWeek, dateTime.weekday % 7); // Pazar = 0
  }
  
  static bool _matchesField(String cronField, int value) {
    if (cronField == '*') return true;
    
    // Comma separated
    if (cronField.contains(',')) {
      final values = cronField.split(',').map((v) => int.tryParse(v.trim())).where((v) => v != null);
      return values.contains(value);
    }
    
    // Range
    if (cronField.contains('-') && !cronField.contains('/')) {
      final parts = cronField.split('-');
      final start = int.tryParse(parts[0].trim());
      final end = int.tryParse(parts[1].trim());
      if (start != null && end != null) {
        return value >= start && value <= end;
      }
    }
    
    // Step
    if (cronField.contains('/')) {
      final parts = cronField.split('/');
      final step = int.tryParse(parts[1].trim());
      if (step == null) return false;
      
      if (parts[0] == '*') {
        return value % step == 0;
      } else if (parts[0].contains('-')) {
        final rangeParts = parts[0].split('-');
        final start = int.tryParse(rangeParts[0].trim());
        final end = int.tryParse(rangeParts[1].trim());
        if (start != null && end != null && value >= start && value <= end) {
          return (value - start) % step == 0;
        }
      }
    }
    
    // Single value
    final intValue = int.tryParse(cronField);
    return intValue == value;
  }
}

// Delivery Schedule Model

class DeliverySchedule {
  
  ScheduleRule rule = ScheduleRule.weekly;
  
  
  ScheduleStatus status = ScheduleStatus.active;
  
  // Günlük teslimat için
  int dailyHour = 9;
  int dailyMinute = 0;
  
  // Haftalık teslimat için
  List<int> weeklyDays = <int>[]; // WeekDay.value listesi
  int weeklyHour = 9;
  int weeklyMinute = 0;
  
  // Aylık teslimat için  
  
  MonthlyDeliveryType monthlyType = MonthlyDeliveryType.specificDates;
  List<int> monthlyDates = <int>[]; // Ayın günleri (1-31)
  int monthlyHour = 9;
  int monthlyMinute = 0;
  
  // Özel cron expression
  String? cronExpression;
  
  // Zamanlama meta verileri
  DateTime? nextDeliveryTime;
  DateTime? lastDeliveryTime;
  int totalDeliveries = 0;
  int failedDeliveries = 0;
  
  // Tatil ve özel durumlar
  bool skipWeekends = false;
  bool skipHolidays = false;
  List<String> holidayDates = <String>[]; // YYYY-MM-DD formatında
  
  // Timezone desteği
  String timezone = 'Europe/Istanbul';
  
  DeliverySchedule();
  
  DeliverySchedule.daily({
    this.dailyHour = 9,
    this.dailyMinute = 0,
    this.skipWeekends = false,
    this.skipHolidays = false,
    this.timezone = 'Europe/Istanbul',
  }) {
    rule = ScheduleRule.daily;
  }
  
  DeliverySchedule.weekly({
    required List<WeekDay> days,
    this.weeklyHour = 9,
    this.weeklyMinute = 0,
    this.skipHolidays = false,
    this.timezone = 'Europe/Istanbul',
  }) {
    rule = ScheduleRule.weekly;
    weeklyDays = days.map((day) => day.value).toList();
  }
  
  DeliverySchedule.monthly({
    this.monthlyType = MonthlyDeliveryType.specificDates,
    List<int>? dates,
    this.monthlyHour = 9,
    this.monthlyMinute = 0,
    this.skipHolidays = false,
    this.timezone = 'Europe/Istanbul',
  }) {
    rule = ScheduleRule.monthly;
    monthlyDates = dates ?? [1, 15];
  }
  
  DeliverySchedule.custom({
    required String cron,
    this.skipHolidays = false,
    this.timezone = 'Europe/Istanbul',
  }) {
    rule = ScheduleRule.custom;
    cronExpression = cron;
  }
  
  // Validation
  bool isValid() {
    switch (rule) {
      case ScheduleRule.daily:
        return dailyHour >= 0 && dailyHour <= 23 && dailyMinute >= 0 && dailyMinute <= 59;
      case ScheduleRule.weekly:
        return weeklyDays.isNotEmpty && 
               weeklyDays.every((day) => day >= 1 && day <= 7) &&
               weeklyHour >= 0 && weeklyHour <= 23 && 
               weeklyMinute >= 0 && weeklyMinute <= 59;
      case ScheduleRule.monthly:
        return monthlyDates.isNotEmpty && 
               monthlyDates.every((date) => date >= 1 && date <= 31) &&
               monthlyHour >= 0 && monthlyHour <= 23 && 
               monthlyMinute >= 0 && monthlyMinute <= 59;
      case ScheduleRule.custom:
        return cronExpression?.isNotEmpty == true && 
               CronExpression(cronExpression!).isValid();
    }
  }
  
  // Bir sonraki teslimat zamanını hesapla
  DateTime? calculateNextDelivery({DateTime? from}) {
    final now = from ?? DateTime.now();
    
    if (!isValid()) return null;
    
    switch (rule) {
      case ScheduleRule.daily:
        return _calculateNextDaily(now);
      case ScheduleRule.weekly:
        return _calculateNextWeekly(now);
      case ScheduleRule.monthly:
        return _calculateNextMonthly(now);
      case ScheduleRule.custom:
        if (cronExpression != null) {
          return NextRunCalculator.calculateNext(CronExpression(cronExpression!), now);
        }
        return null;
    }
  }
  
  DateTime? _calculateNextDaily(DateTime from) {
    var next = DateTime(from.year, from.month, from.day, dailyHour, dailyMinute);
    
    if (next.isBefore(from)) {
      next = next.add(const Duration(days: 1));
    }
    
    // Hafta sonu kontrolü
    while (skipWeekends && (next.weekday == DateTime.saturday || next.weekday == DateTime.sunday)) {
      next = next.add(const Duration(days: 1));
    }
    
    // Tatil kontrolü
    while (skipHolidays && _isHoliday(next)) {
      next = next.add(const Duration(days: 1));
      // Hafta sonu kontrolü tekrar
      while (skipWeekends && (next.weekday == DateTime.saturday || next.weekday == DateTime.sunday)) {
        next = next.add(const Duration(days: 1));
      }
    }
    
    return next;
  }
  
  DateTime? _calculateNextWeekly(DateTime from) {
    var next = DateTime(from.year, from.month, from.day, weeklyHour, weeklyMinute);
    
    // Bu haftada uygun gün var mı kontrol et
    for (int i = 0; i < 7; i++) {
      final candidate = next.add(Duration(days: i));
      if (weeklyDays.contains(candidate.weekday) && candidate.isAfter(from)) {
        if (!skipHolidays || !_isHoliday(candidate)) {
          return candidate;
        }
      }
    }
    
    // Sonraki haftalara bak
    next = next.add(Duration(days: 7 - next.weekday + 1));
    for (int week = 0; week < 52; week++) { // Maksimum 1 yıl ara
      for (final dayValue in weeklyDays) {
        final candidate = DateTime(
          next.year,
          next.month,
          next.day + (dayValue - 1),
          weeklyHour,
          weeklyMinute,
        );
        
        if (!skipHolidays || !_isHoliday(candidate)) {
          return candidate;
        }
      }
      next = next.add(const Duration(days: 7));
    }
    
    return null;
  }
  
  DateTime? _calculateNextMonthly(DateTime from) {
    
    // Bu ay içinde uygun tarih var mı kontrol et
    final daysInThisMonth = DateTime(from.year, from.month + 1, 0).day;
    for (final date in monthlyDates) {
      if (date <= daysInThisMonth) {
        final candidate = DateTime(from.year, from.month, date, monthlyHour, monthlyMinute);
        if (candidate.isAfter(from) && (!skipHolidays || !_isHoliday(candidate))) {
          return candidate;
        }
      }
    }
    
    // Sonraki aylara bak
    for (int monthOffset = 1; monthOffset <= 12; monthOffset++) {
      final year = from.year + ((from.month + monthOffset - 1) ~/ 12);
      final month = ((from.month + monthOffset - 1) % 12) + 1;
      final daysInMonth = DateTime(year, month + 1, 0).day;
      
      for (final date in monthlyDates) {
        if (date <= daysInMonth) {
          final candidate = DateTime(year, month, date, monthlyHour, monthlyMinute);
          if (!skipHolidays || !_isHoliday(candidate)) {
            return candidate;
          }
        }
      }
    }
    
    return null;
  }
  
  bool _isHoliday(DateTime date) {
    // Önce özel tatil listesini kontrol et
    final dateStr = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    if (holidayDates.contains(dateStr)) return true;
    
    // Sistem tatillerini kontrol et (HolidayHelper kullanarak)
    if (skipHolidays) {
      return HolidayHelper.isHoliday(date);
    }
    
    return false;
  }

  // Timezone-aware teslimat zamanı hesaplama
  tz.TZDateTime? calculateNextDeliveryTimezone() {
    final nextTime = calculateNextDelivery();
    if (nextTime == null) return null;
    
    try {
      return TimezoneHelper.toTimezone(nextTime, timezone);
    } catch (e) {
      // Fallback to system timezone
      return TimezoneHelper.toCurrentTimezone(nextTime);
    }
  }

  // Tatil ve hafta sonu kontrolü ile sonraki geçerli teslimat zamanı
  tz.TZDateTime? calculateNextValidDeliveryTime() {
    var nextTime = calculateNextDeliveryTimezone();
    if (nextTime == null) return null;

    // Geçerli bir teslimat zamanı bulana kadar ilerle
    int attempts = 0;
    const maxAttempts = 30; // Sonsuz döngüyü önlemek için

    while (attempts < maxAttempts) {
      if (_isValidDeliveryTime(nextTime!)) {
        return nextTime;
      }

      // Bir sonraki olası zamana geç
      nextTime = _getNextDeliveryTimeAfter(nextTime);
      if (nextTime == null) break;

      attempts++;
    }

    return nextTime; // Geçerli zaman bulunamasa bile son hesaplananı döndür
  }

  bool _isValidDeliveryTime(tz.TZDateTime dateTime) {
    // Hafta sonu kontrolü
    if (skipWeekends && HolidayHelper.isWeekend(dateTime)) {
      return false;
    }

    // Tatil kontrolü
    if (skipHolidays && HolidayHelper.isHoliday(dateTime)) {
      return false;
    }

    // Özel tatil tarihleri kontrolü
    if (holidayDates.isNotEmpty) {
      final dateString = '${dateTime.year.toString().padLeft(4, '0')}-'
                       '${dateTime.month.toString().padLeft(2, '0')}-'
                       '${dateTime.day.toString().padLeft(2, '0')}';
      if (holidayDates.contains(dateString)) {
        return false;
      }
    }

    return true;
  }

  tz.TZDateTime? _getNextDeliveryTimeAfter(tz.TZDateTime current) {
    switch (rule) {
      case ScheduleRule.daily:
        return current.add(const Duration(days: 1));
      
      case ScheduleRule.weekly:
        // Bir sonraki haftalık teslimat gününe geç
        for (int i = 1; i <= 7; i++) {
          final nextDay = current.add(Duration(days: i));
          if (weeklyDays.contains(nextDay.weekday)) {
            return tz.TZDateTime(
              nextDay.location,
              nextDay.year,
              nextDay.month,
              nextDay.day,
              weeklyHour,
              weeklyMinute,
            );
          }
        }
        return null;
        
      case ScheduleRule.monthly:
        // Bir sonraki aylık teslimat zamanına geç
        final nextMonth = tz.TZDateTime(
          current.location,
          current.month == 12 ? current.year + 1 : current.year,
          current.month == 12 ? 1 : current.month + 1,
          1,
          monthlyHour,
          monthlyMinute,
        );
        return _calculateMonthlyDeliveryTime(nextMonth);
        
      case ScheduleRule.custom:
        if (cronExpression != null) {
          // Basit artırma - gerçek cron hesaplama daha karmaşık
          return current.add(const Duration(days: 1));
        }
        return null;
    }
  }

  tz.TZDateTime? _calculateMonthlyDeliveryTime(tz.TZDateTime month) {
    switch (monthlyType) {
      case MonthlyDeliveryType.specificDates:
        if (monthlyDates.isEmpty) return null;
        
        // Bu ay için geçerli tarihleri kontrol et
        for (final date in monthlyDates) {
          final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
          if (date <= daysInMonth) {
            return tz.TZDateTime(
              month.location,
              month.year,
              month.month,
              date,
              monthlyHour,
              monthlyMinute,
            );
          }
        }
        return null;
        
      case MonthlyDeliveryType.firstWeek:
        // İlk hafta implementasyonu
        return tz.TZDateTime(
          month.location,
          month.year,
          month.month,
          7, // İlk hafta sonu
          monthlyHour,
          monthlyMinute,
        );
        
      case MonthlyDeliveryType.lastWeek:
        // Son hafta implementasyonu
        final lastDay = DateTime(month.year, month.month + 1, 0).day;
        return tz.TZDateTime(
          month.location,
          month.year,
          month.month,
          lastDay - 6, // Son haftanın başı
          monthlyHour,
          monthlyMinute,
        );
        
      case MonthlyDeliveryType.everyTwoWeeks:
        // İki haftada bir implementasyonu
        return tz.TZDateTime(
          month.location,
          month.year,
          month.month,
          14, // Ayın ortası civarı
          monthlyHour,
          monthlyMinute,
        );
    }
  }

  // Çalışma saatleri kontrolü
  bool isWithinBusinessHours(tz.TZDateTime dateTime) {
    return TimezoneHelper.isBusinessHour(dateTime, timezone);
  }

  // Bir sonraki çalışma günü teslimat zamanı
  tz.TZDateTime? getNextBusinessDayDelivery(tz.TZDateTime dateTime) {
    return TimezoneHelper.getNextBusinessDay(dateTime, timezone);
  }
  
  // Helper methods
  List<WeekDay> get selectedWeekDays {
    return weeklyDays.map((value) => WeekDay.fromValue(value)).toList();
  }
  
  void setWeeklyDays(List<WeekDay> days) {
    weeklyDays = days.map((day) => day.value).toList();
  }
  
  String get displayText {
    switch (rule) {
      case ScheduleRule.daily:
        return skipWeekends 
            ? 'Hafta içi her gün ${_timeText(dailyHour, dailyMinute)}'
            : 'Her gün ${_timeText(dailyHour, dailyMinute)}';
      case ScheduleRule.weekly:
        final dayNames = selectedWeekDays.map((day) => _dayName(day)).join(', ');
        return 'Haftalık: $dayNames ${_timeText(weeklyHour, weeklyMinute)}';
      case ScheduleRule.monthly:
        return 'Aylık: ${monthlyDates.join(', ')}. günler ${_timeText(monthlyHour, monthlyMinute)}';
      case ScheduleRule.custom:
        return 'Özel: $cronExpression';
    }
  }
  
  String _timeText(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
  
  String _dayName(WeekDay day) {
    switch (day) {
      case WeekDay.monday: return 'Pzt';
      case WeekDay.tuesday: return 'Sal';
      case WeekDay.wednesday: return 'Çar';
      case WeekDay.thursday: return 'Per';
      case WeekDay.friday: return 'Cum';
      case WeekDay.saturday: return 'Cmt';
      case WeekDay.sunday: return 'Paz';
    }
  }
  
  // Pause/Resume
  void pause() {
    status = ScheduleStatus.paused;
  }
  
  void resume() {
    status = ScheduleStatus.active;
    nextDeliveryTime = calculateNextDelivery();
  }
  
  void cancel() {
    status = ScheduleStatus.cancelled;
    nextDeliveryTime = null;
  }
  
  void complete() {
    status = ScheduleStatus.completed;
    nextDeliveryTime = null;
  }
  
  // Statistics
  double get successRate {
    if (totalDeliveries == 0) return 1.0;
    return (totalDeliveries - failedDeliveries) / totalDeliveries;
  }
  
  void recordDelivery({bool success = true}) {
    totalDeliveries++;
    if (!success) {
      failedDeliveries++;
    }
    lastDeliveryTime = DateTime.now();
    
    if (status == ScheduleStatus.active) {
      nextDeliveryTime = calculateNextDelivery();
    }
  }
  
  Map<String, dynamic> toMap() {
    return {
      'rule': rule.name,
      'status': status.name,
      'dailyHour': dailyHour,
      'dailyMinute': dailyMinute,
      'weeklyDays': weeklyDays,
      'weeklyHour': weeklyHour,
      'weeklyMinute': weeklyMinute,
      'monthlyType': monthlyType.name,
      'monthlyDates': monthlyDates,
      'monthlyHour': monthlyHour,
      'monthlyMinute': monthlyMinute,
      'cronExpression': cronExpression,
      'nextDeliveryTime': nextDeliveryTime?.millisecondsSinceEpoch,
      'lastDeliveryTime': lastDeliveryTime?.millisecondsSinceEpoch,
      'totalDeliveries': totalDeliveries,
      'failedDeliveries': failedDeliveries,
      'skipWeekends': skipWeekends,
      'skipHolidays': skipHolidays,
      'holidayDates': holidayDates,
      'timezone': timezone,
    };
  }
  
  factory DeliverySchedule.fromMap(Map<String, dynamic> map) {
    final schedule = DeliverySchedule();
    
    schedule.rule = ScheduleRule.values.firstWhere(
      (e) => e.name == map['rule'],
      orElse: () => ScheduleRule.weekly,
    );
    schedule.status = ScheduleStatus.values.firstWhere(
      (e) => e.name == map['status'],
      orElse: () => ScheduleStatus.active,
    );
    
    schedule.dailyHour = map['dailyHour'] ?? 9;
    schedule.dailyMinute = map['dailyMinute'] ?? 0;
    schedule.weeklyDays = List<int>.from(map['weeklyDays'] ?? []);
    schedule.weeklyHour = map['weeklyHour'] ?? 9;
    schedule.weeklyMinute = map['weeklyMinute'] ?? 0;
    schedule.monthlyType = MonthlyDeliveryType.values.firstWhere(
      (e) => e.name == map['monthlyType'],
      orElse: () => MonthlyDeliveryType.specificDates,
    );
    schedule.monthlyDates = List<int>.from(map['monthlyDates'] ?? []);
    schedule.monthlyHour = map['monthlyHour'] ?? 9;
    schedule.monthlyMinute = map['monthlyMinute'] ?? 0;
    schedule.cronExpression = map['cronExpression'];
    
    if (map['nextDeliveryTime'] != null) {
      schedule.nextDeliveryTime = DateTime.fromMillisecondsSinceEpoch(map['nextDeliveryTime']);
    }
    if (map['lastDeliveryTime'] != null) {
      schedule.lastDeliveryTime = DateTime.fromMillisecondsSinceEpoch(map['lastDeliveryTime']);
    }
    
    schedule.totalDeliveries = map['totalDeliveries'] ?? 0;
    schedule.failedDeliveries = map['failedDeliveries'] ?? 0;
    schedule.skipWeekends = map['skipWeekends'] ?? false;
    schedule.skipHolidays = map['skipHolidays'] ?? false;
    schedule.holidayDates = List<String>.from(map['holidayDates'] ?? []);
    schedule.timezone = map['timezone'] ?? 'Europe/Istanbul';
    
    return schedule;
  }
}