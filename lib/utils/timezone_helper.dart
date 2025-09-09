import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter/foundation.dart';

class TimezoneHelper {
  static bool _isInitialized = false;
  static late tz.Location _currentTimezone;
  
  // Türkiye saat dilimleri
  static const String turkeyTimezone = 'Europe/Istanbul';
  static const String utcTimezone = 'UTC';
  
  // Initialize timezone data
  static Future<void> initialize([String? timezoneName]) async {
    if (_isInitialized) return;
    
    try {
      tz_data.initializeTimeZones();
      
      // Default to Turkey timezone or system timezone
      final timezone = timezoneName ?? turkeyTimezone;
      _currentTimezone = tz.getLocation(timezone);
      _isInitialized = true;
      
      debugPrint('✅ Timezone initialized: ${_currentTimezone.name}');
    } catch (e) {
      // Fallback to UTC if timezone not found
      debugPrint('⚠️ Timezone init error, falling back to UTC: $e');
      _currentTimezone = tz.getLocation(utcTimezone);
      _isInitialized = true;
    }
  }

  // Get current timezone location
  static tz.Location get currentTimezone {
    if (!_isInitialized) {
      throw StateError('TimezoneHelper not initialized. Call initialize() first.');
    }
    return _currentTimezone;
  }

  // Set current timezone
  static void setTimezone(String timezoneName) {
    try {
      _currentTimezone = tz.getLocation(timezoneName);
      debugPrint('🌍 Timezone değiştirildi: $timezoneName');
    } catch (e) {
      debugPrint('❌ Invalid timezone: $timezoneName, error: $e');
      throw ArgumentError('Invalid timezone: $timezoneName');
    }
  }

  // Convert DateTime to current timezone
  static tz.TZDateTime toCurrentTimezone(DateTime dateTime) {
    if (!_isInitialized) initialize();
    
    if (dateTime is tz.TZDateTime) {
      return dateTime.toLocal();
    }
    
    return tz.TZDateTime.from(dateTime, _currentTimezone);
  }

  // Convert to specific timezone
  static tz.TZDateTime toTimezone(DateTime dateTime, String timezoneName) {
    if (!_isInitialized) initialize();
    
    final location = tz.getLocation(timezoneName);
    return tz.TZDateTime.from(dateTime, location);
  }

  // Get current time in current timezone
  static tz.TZDateTime now() {
    if (!_isInitialized) initialize();
    return tz.TZDateTime.now(_currentTimezone);
  }

  // Get current time in UTC
  static tz.TZDateTime nowUtc() {
    if (!_isInitialized) initialize();
    return tz.TZDateTime.now(tz.UTC);
  }

  // Check if timezone observes daylight saving time
  static bool isDaylightSavingTime(DateTime dateTime) {
    if (!_isInitialized) initialize();
    
    final tzDateTime = toCurrentTimezone(dateTime);
    final january = tz.TZDateTime(_currentTimezone, tzDateTime.year, 1, 1);
    final july = tz.TZDateTime(_currentTimezone, tzDateTime.year, 7, 1);
    
    return tzDateTime.timeZoneOffset != january.timeZoneOffset ||
           tzDateTime.timeZoneOffset != july.timeZoneOffset;
  }

  // Get timezone offset in minutes
  static int getTimezoneOffsetMinutes(DateTime dateTime) {
    final tzDateTime = toCurrentTimezone(dateTime);
    return tzDateTime.timeZoneOffset.inMinutes;
  }

  // Format timezone offset as string (+03:00)
  static String getTimezoneOffsetString(DateTime dateTime) {
    final offset = getTimezoneOffsetMinutes(dateTime);
    final hours = offset ~/ 60;
    final minutes = offset.abs() % 60;
    final sign = offset >= 0 ? '+' : '-';
    
    return '$sign${hours.abs().toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  // Get all available timezones
  static List<String> getAllTimezones() {
    if (!_isInitialized) initialize();
    return tz.timeZoneDatabase.locations.keys.toList()..sort();
  }

  // Get common timezones
  static List<String> getCommonTimezones() {
    return [
      'Europe/Istanbul',
      'UTC',
      'Europe/London',
      'Europe/Paris',
      'Europe/Berlin',
      'America/New_York',
      'America/Los_Angeles',
      'Asia/Tokyo',
      'Asia/Shanghai',
      'Australia/Sydney',
      'Pacific/Auckland',
    ];
  }

  // Convert between timezones
  static tz.TZDateTime convertTimezone(
    DateTime dateTime,
    String fromTimezone,
    String toTimezone,
  ) {
    if (!_isInitialized) initialize();
    
    final fromLocation = tz.getLocation(fromTimezone);
    final toLocation = tz.getLocation(toTimezone);
    
    final fromTZDateTime = tz.TZDateTime.from(dateTime, fromLocation);
    return tz.TZDateTime.from(fromTZDateTime, toLocation);
  }

  // Get business hours for timezone
  static Map<String, int> getBusinessHours(String timezoneName) {
    // Default business hours (can be customized per timezone/country)
    switch (timezoneName) {
      case 'Europe/Istanbul':
        return {'start': 9, 'end': 18}; // 09:00 - 18:00
      case 'America/New_York':
        return {'start': 9, 'end': 17}; // 09:00 - 17:00
      case 'Asia/Tokyo':
        return {'start': 9, 'end': 18}; // 09:00 - 18:00
      default:
        return {'start': 9, 'end': 17}; // Default
    }
  }

  // Check if time is within business hours
  static bool isBusinessHour(DateTime dateTime, [String? timezoneName]) {
    final timezone = timezoneName ?? _currentTimezone.name;
    final businessHours = getBusinessHours(timezone);
    final tzDateTime = timezoneName != null
        ? toTimezone(dateTime, timezoneName)
        : toCurrentTimezone(dateTime);
    
    return tzDateTime.hour >= businessHours['start']! &&
           tzDateTime.hour < businessHours['end']!;
  }

  // Get next business day
  static tz.TZDateTime getNextBusinessDay(DateTime dateTime, [String? timezoneName]) {
    var tzDateTime = timezoneName != null
        ? toTimezone(dateTime, timezoneName)
        : toCurrentTimezone(dateTime);
    
    // Skip weekends
    while (tzDateTime.weekday == DateTime.saturday || 
           tzDateTime.weekday == DateTime.sunday) {
      tzDateTime = tzDateTime.add(const Duration(days: 1));
    }
    
    // Set to business hour start
    final businessHours = getBusinessHours(tzDateTime.location.name);
    tzDateTime = tz.TZDateTime(
      tzDateTime.location,
      tzDateTime.year,
      tzDateTime.month,
      tzDateTime.day,
      businessHours['start']!,
    );
    
    return tzDateTime;
  }

  // Calculate delivery time considering timezone and business hours
  static tz.TZDateTime calculateDeliveryTime(
    DateTime baseTime,
    Duration deliveryWindow, {
    bool respectBusinessHours = true,
    String? targetTimezone,
  }) {
    var deliveryTime = targetTimezone != null
        ? toTimezone(baseTime, targetTimezone)
        : toCurrentTimezone(baseTime);
    
    deliveryTime = deliveryTime.add(deliveryWindow);
    
    if (respectBusinessHours && !isBusinessHour(deliveryTime, targetTimezone)) {
      // Move to next business day
      deliveryTime = getNextBusinessDay(deliveryTime, targetTimezone);
    }
    
    return deliveryTime;
  }

  // Format timezone-aware time for display
  static String formatTimezoneAware(DateTime dateTime, {
    String? timezoneName,
    bool showTimezone = true,
    String format = 'dd/MM/yyyy HH:mm',
  }) {
    final tzDateTime = timezoneName != null
        ? toTimezone(dateTime, timezoneName)
        : toCurrentTimezone(dateTime);
    
    var formatted = _formatDateTime(tzDateTime, format);
    
    if (showTimezone) {
      final offsetString = getTimezoneOffsetString(tzDateTime);
      formatted += ' ($offsetString)';
    }
    
    return formatted;
  }

  static String _formatDateTime(tz.TZDateTime dateTime, String format) {
    // Simple date formatting - you might want to use intl package for more complex formatting
    return format
        .replaceAll('yyyy', dateTime.year.toString())
        .replaceAll('MM', dateTime.month.toString().padLeft(2, '0'))
        .replaceAll('dd', dateTime.day.toString().padLeft(2, '0'))
        .replaceAll('HH', dateTime.hour.toString().padLeft(2, '0'))
        .replaceAll('mm', dateTime.minute.toString().padLeft(2, '0'))
        .replaceAll('ss', dateTime.second.toString().padLeft(2, '0'));
  }

  // Get timezone info
  static Map<String, dynamic> getTimezoneInfo([String? timezoneName]) {
    final timezone = timezoneName ?? _currentTimezone.name;
    final location = tz.getLocation(timezone);
    final now = tz.TZDateTime.now(location);
    
    return {
      'name': timezone,
      'abbreviation': now.timeZoneName,
      'offset': now.timeZoneOffset.inMinutes,
      'offsetString': getTimezoneOffsetString(now),
      'isDST': isDaylightSavingTime(now),
    };
  }
}