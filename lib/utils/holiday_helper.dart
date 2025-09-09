import 'package:flutter/foundation.dart';

enum HolidayType {
  national,
  religious, 
  regional,
  custom,
}

class Holiday {
  final String name;
  final DateTime date;
  final HolidayType type;
  final String? description;
  final bool isRecurring;
  final String countryCode;

  Holiday({
    required this.name,
    required this.date,
    required this.type,
    this.description,
    this.isRecurring = false,
    this.countryCode = 'TR',
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'date': date.toIso8601String(),
    'type': type.name,
    'description': description,
    'isRecurring': isRecurring,
    'countryCode': countryCode,
  };

  factory Holiday.fromMap(Map<String, dynamic> map) => Holiday(
    name: map['name'],
    date: DateTime.parse(map['date']),
    type: HolidayType.values.firstWhere((e) => e.name == map['type']),
    description: map['description'],
    isRecurring: map['isRecurring'] ?? false,
    countryCode: map['countryCode'] ?? 'TR',
  );

  @override
  String toString() => 'Holiday($name, $date, $type)';
}

class HolidayHelper {
  static final Map<String, List<Holiday>> _holidayCache = {};
  static final Map<String, List<Holiday>> _customHolidays = {};

  // Türkiye resmi tatilleri (2024)
  static List<Holiday> getTurkeyHolidays(int year) {
    final cacheKey = 'TR_$year';
    if (_holidayCache.containsKey(cacheKey)) {
      return _holidayCache[cacheKey]!;
    }

    final holidays = <Holiday>[
      // Sabit tatiller
      Holiday(
        name: 'Yılbaşı',
        date: DateTime(year, 1, 1),
        type: HolidayType.national,
        description: 'Miladi Yılbaşı',
        isRecurring: true,
      ),
      Holiday(
        name: '23 Nisan Ulusal Egemenlik ve Çocuk Bayramı',
        date: DateTime(year, 4, 23),
        type: HolidayType.national,
        description: 'Ulusal Egemenlik ve Çocuk Bayramı',
        isRecurring: true,
      ),
      Holiday(
        name: '1 Mayıs İşçi ve Dayanışma Günü',
        date: DateTime(year, 5, 1),
        type: HolidayType.national,
        description: 'Emek ve Dayanışma Günü',
        isRecurring: true,
      ),
      Holiday(
        name: '19 Mayıs Atatürk\'ü Anma, Gençlik ve Spor Bayramı',
        date: DateTime(year, 5, 19),
        type: HolidayType.national,
        description: 'Atatürk\'ü Anma, Gençlik ve Spor Bayramı',
        isRecurring: true,
      ),
      Holiday(
        name: '30 Ağustos Zafer Bayramı',
        date: DateTime(year, 8, 30),
        type: HolidayType.national,
        description: 'Zafer Bayramı',
        isRecurring: true,
      ),
      Holiday(
        name: '29 Ekim Cumhuriyet Bayramı',
        date: DateTime(year, 10, 29),
        type: HolidayType.national,
        description: 'Cumhuriyet Bayramı',
        isRecurring: true,
      ),
    ];

    // Dini bayramları ekle (yıla göre değişir)
    holidays.addAll(_getReligiousHolidays(year));

    _holidayCache[cacheKey] = holidays;
    return holidays;
  }

  // Dini bayramlar (Hicri takvime göre değişir)
  static List<Holiday> _getReligiousHolidays(int year) {
    // Bu tarihlerin tam hesaplaması için astronomik hesaplama gerekir
    // Burada yaklaşık tarihleri veriyoruz
    final holidays = <Holiday>[];

    // 2024 yılı için örnek tarihleri
    if (year == 2024) {
      // Ramazan Bayramı (3 gün)
      holidays.addAll([
        Holiday(
          name: 'Ramazan Bayramı 1. Gün',
          date: DateTime(2024, 4, 10),
          type: HolidayType.religious,
          description: 'Ramazan Bayramı',
          isRecurring: false,
        ),
        Holiday(
          name: 'Ramazan Bayramı 2. Gün',
          date: DateTime(2024, 4, 11),
          type: HolidayType.religious,
          description: 'Ramazan Bayramı',
          isRecurring: false,
        ),
        Holiday(
          name: 'Ramazan Bayramı 3. Gün',
          date: DateTime(2024, 4, 12),
          type: HolidayType.religious,
          description: 'Ramazan Bayramı',
          isRecurring: false,
        ),
        // Kurban Bayramı (4 gün)
        Holiday(
          name: 'Kurban Bayramı 1. Gün',
          date: DateTime(2024, 6, 16),
          type: HolidayType.religious,
          description: 'Kurban Bayramı',
          isRecurring: false,
        ),
        Holiday(
          name: 'Kurban Bayramı 2. Gün',
          date: DateTime(2024, 6, 17),
          type: HolidayType.religious,
          description: 'Kurban Bayramı',
          isRecurring: false,
        ),
        Holiday(
          name: 'Kurban Bayramı 3. Gün',
          date: DateTime(2024, 6, 18),
          type: HolidayType.religious,
          description: 'Kurban Bayramı',
          isRecurring: false,
        ),
        Holiday(
          name: 'Kurban Bayramı 4. Gün',
          date: DateTime(2024, 6, 19),
          type: HolidayType.religious,
          description: 'Kurban Bayramı',
          isRecurring: false,
        ),
      ]);
    } else if (year == 2025) {
      // 2025 yılı için örnek tarihleri
      holidays.addAll([
        Holiday(
          name: 'Ramazan Bayramı 1. Gün',
          date: DateTime(2025, 3, 31),
          type: HolidayType.religious,
          description: 'Ramazan Bayramı',
          isRecurring: false,
        ),
        Holiday(
          name: 'Ramazan Bayramı 2. Gün',
          date: DateTime(2025, 4, 1),
          type: HolidayType.religious,
          description: 'Ramazan Bayramı',
          isRecurring: false,
        ),
        Holiday(
          name: 'Ramazan Bayramı 3. Gün',
          date: DateTime(2025, 4, 2),
          type: HolidayType.religious,
          description: 'Ramazan Bayramı',
          isRecurring: false,
        ),
        Holiday(
          name: 'Kurban Bayramı 1. Gün',
          date: DateTime(2025, 6, 6),
          type: HolidayType.religious,
          description: 'Kurban Bayramı',
          isRecurring: false,
        ),
        Holiday(
          name: 'Kurban Bayramı 2. Gün',
          date: DateTime(2025, 6, 7),
          type: HolidayType.religious,
          description: 'Kurban Bayramı',
          isRecurring: false,
        ),
        Holiday(
          name: 'Kurban Bayramı 3. Gün',
          date: DateTime(2025, 6, 8),
          type: HolidayType.religious,
          description: 'Kurban Bayramı',
          isRecurring: false,
        ),
        Holiday(
          name: 'Kurban Bayramı 4. Gün',
          date: DateTime(2025, 6, 9),
          type: HolidayType.religious,
          description: 'Kurban Bayramı',
          isRecurring: false,
        ),
      ]);
    }

    return holidays;
  }

  // Özel tatil ekleme
  static void addCustomHoliday(Holiday holiday) {
    final key = '${holiday.countryCode}_${holiday.date.year}';
    _customHolidays[key] ??= [];
    _customHolidays[key]!.add(holiday);
  }

  // Özel tatil silme
  static void removeCustomHoliday(String name, int year, String countryCode) {
    final key = '${countryCode}_$year';
    _customHolidays[key]?.removeWhere((h) => h.name == name);
  }

  // Tüm tatilleri getir (resmi + özel)
  static List<Holiday> getAllHolidays(int year, [String countryCode = 'TR']) {
    final holidays = <Holiday>[];
    
    // Resmi tatilleri ekle
    if (countryCode == 'TR') {
      holidays.addAll(getTurkeyHolidays(year));
    }
    
    // Özel tatilleri ekle
    final customKey = '${countryCode}_$year';
    if (_customHolidays.containsKey(customKey)) {
      holidays.addAll(_customHolidays[customKey]!);
    }
    
    // Tarihe göre sırala
    holidays.sort((a, b) => a.date.compareTo(b.date));
    
    return holidays;
  }

  // Belirli bir tarihin tatil olup olmadığını kontrol et
  static bool isHoliday(DateTime date, [String countryCode = 'TR']) {
    final holidays = getAllHolidays(date.year, countryCode);
    return holidays.any((h) => isSameDay(h.date, date));
  }

  // Belirli bir tarihin hafta sonu olup olmadığını kontrol et
  static bool isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  // Belirli bir tarihin çalışma günü olup olmadığını kontrol et
  static bool isWorkingDay(DateTime date, [String countryCode = 'TR']) {
    return !isWeekend(date) && !isHoliday(date, countryCode);
  }

  // Bir sonraki çalışma gününü bul
  static DateTime getNextWorkingDay(DateTime date, [String countryCode = 'TR']) {
    var nextDay = date.add(const Duration(days: 1));
    
    while (!isWorkingDay(nextDay, countryCode)) {
      nextDay = nextDay.add(const Duration(days: 1));
    }
    
    return nextDay;
  }

  // Önceki çalışma gününü bul
  static DateTime getPreviousWorkingDay(DateTime date, [String countryCode = 'TR']) {
    var prevDay = date.subtract(const Duration(days: 1));
    
    while (!isWorkingDay(prevDay, countryCode)) {
      prevDay = prevDay.subtract(const Duration(days: 1));
    }
    
    return prevDay;
  }

  // Belirli bir ay içindeki çalışma günü sayısını hesapla
  static int getWorkingDaysInMonth(int year, int month, [String countryCode = 'TR']) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    int workingDays = 0;
    
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      if (isWorkingDay(date, countryCode)) {
        workingDays++;
      }
    }
    
    return workingDays;
  }

  // Belirli bir tarih aralığındaki çalışma günü sayısını hesapla
  static int getWorkingDaysBetween(
    DateTime startDate,
    DateTime endDate,
    [String countryCode = 'TR']
  ) {
    int workingDays = 0;
    var currentDate = startDate;
    
    while (currentDate.isBefore(endDate) || isSameDay(currentDate, endDate)) {
      if (isWorkingDay(currentDate, countryCode)) {
        workingDays++;
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }
    
    return workingDays;
  }

  // Belirli bir tarih aralığındaki tatilleri getir
  static List<Holiday> getHolidaysBetween(
    DateTime startDate,
    DateTime endDate,
    [String countryCode = 'TR']
  ) {
    final holidays = <Holiday>[];
    
    for (int year = startDate.year; year <= endDate.year; year++) {
      final yearHolidays = getAllHolidays(year, countryCode);
      
      for (final holiday in yearHolidays) {
        if ((holiday.date.isAfter(startDate) || isSameDay(holiday.date, startDate)) &&
            (holiday.date.isBefore(endDate) || isSameDay(holiday.date, endDate))) {
          holidays.add(holiday);
        }
      }
    }
    
    return holidays;
  }

  // İki tarihin aynı gün olup olmadığını kontrol et
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  // Tatil türüne göre filtrele
  static List<Holiday> getHolidaysByType(
    int year,
    HolidayType type,
    [String countryCode = 'TR']
  ) {
    final holidays = getAllHolidays(year, countryCode);
    return holidays.where((h) => h.type == type).toList();
  }

  // Yılın belirli bir gününün hangi tatil olduğunu bul
  static Holiday? getHolidayByDate(DateTime date, [String countryCode = 'TR']) {
    final holidays = getAllHolidays(date.year, countryCode);
    
    try {
      return holidays.firstWhere((h) => isSameDay(h.date, date));
    } catch (e) {
      return null;
    }
  }

  // Cache temizleme
  static void clearCache() {
    _holidayCache.clear();
    debugPrint('🗑️ Holiday cache temizlendi');
  }

  // İstatistikler
  static Map<String, int> getHolidayStats(int year, [String countryCode = 'TR']) {
    final holidays = getAllHolidays(year, countryCode);
    
    final stats = <String, int>{};
    
    for (final type in HolidayType.values) {
      stats[type.name] = holidays.where((h) => h.type == type).length;
    }
    
    stats['total'] = holidays.length;
    
    return stats;
  }
}