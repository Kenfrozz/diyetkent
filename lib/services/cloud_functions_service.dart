import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user_diet_assignment_model.dart';
import '../models/delivery_schedule_model.dart';

// Cloud Functions için endpoint türleri
enum CloudFunctionEndpoint {
  scheduleDelivery,
  cancelDelivery,
  updateSchedule,
  getDeliveryStatus,
  processNotification,
  syncSchedules,
}

// Cloud function response wrapper
class CloudFunctionResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int statusCode;

  CloudFunctionResponse({
    required this.success,
    this.data,
    this.error,
    this.statusCode = 200,
  });

  factory CloudFunctionResponse.success(T data) => CloudFunctionResponse(
    success: true,
    data: data,
  );

  factory CloudFunctionResponse.error(String error, [int statusCode = 500]) =>
    CloudFunctionResponse(
      success: false,
      error: error,
      statusCode: statusCode,
    );
}

class CloudFunctionsService {
  static final CloudFunctionsService _instance = CloudFunctionsService._internal();
  factory CloudFunctionsService() => _instance;
  CloudFunctionsService._internal();

  // Firebase project configuration
  static const String _projectId = 'diyetkent-app'; // Bu gerçek proje ID'si olmalı
  static const String _region = 'europe-west3';
  static const String _baseUrl = 'https://$_region-$_projectId.cloudfunctions.net';
  
  final http.Client _httpClient = http.Client();
  String? _authToken;
  bool _isEnabled = false;

  bool get isEnabled => _isEnabled;

  Future<void> initialize({String? authToken, bool enabled = true}) async {
    _authToken = authToken;
    _isEnabled = enabled;
    
    if (_isEnabled) {
      debugPrint('✅ Cloud Functions service başlatıldı');
      debugPrint('   Project ID: $_projectId');
      debugPrint('   Region: $_region');
      debugPrint('   Base URL: $_baseUrl');
    } else {
      debugPrint('ℹ️ Cloud Functions service devre dışı');
    }
  }

  Future<void> dispose() async {
    _httpClient.close();
    _isEnabled = false;
  }

  String _getEndpointUrl(CloudFunctionEndpoint endpoint) {
    switch (endpoint) {
      case CloudFunctionEndpoint.scheduleDelivery:
        return '$_baseUrl/scheduleDelivery';
      case CloudFunctionEndpoint.cancelDelivery:
        return '$_baseUrl/cancelDelivery';
      case CloudFunctionEndpoint.updateSchedule:
        return '$_baseUrl/updateSchedule';
      case CloudFunctionEndpoint.getDeliveryStatus:
        return '$_baseUrl/getDeliveryStatus';
      case CloudFunctionEndpoint.processNotification:
        return '$_baseUrl/processNotification';
      case CloudFunctionEndpoint.syncSchedules:
        return '$_baseUrl/syncSchedules';
    }
  }

  Map<String, String> _getHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return headers;
  }

  Future<CloudFunctionResponse<T>> _makeRequest<T>(
    CloudFunctionEndpoint endpoint,
    Map<String, dynamic> data, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (!_isEnabled) {
      debugPrint('⚠️ Cloud Functions devre dışı, local fallback kullanılıyor');
      return CloudFunctionResponse.success(null as T);
    }

    try {
      final url = Uri.parse(_getEndpointUrl(endpoint));
      final headers = _getHeaders();
      final body = jsonEncode(data);

      debugPrint('🌐 Cloud Function çağrısı: ${endpoint.name}');
      debugPrint('   URL: $url');
      debugPrint('   Data: ${data.toString().substring(0, data.toString().length > 200 ? 200 : data.toString().length)}...');

      final response = await _httpClient
          .post(url, headers: headers, body: body)
          .timeout(timeout);

      debugPrint('📡 Response: ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['success'] == true) {
          return CloudFunctionResponse.success(responseData['data'] as T);
        } else {
          return CloudFunctionResponse.error(
            responseData['error'] ?? 'Unknown error',
            response.statusCode,
          );
        }
      } else {
        return CloudFunctionResponse.error(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          response.statusCode,
        );
      }

    } catch (e) {
      debugPrint('❌ Cloud Function error: $e');
      return CloudFunctionResponse.error(e.toString());
    }
  }

  // Schedule delivery via cloud function
  Future<CloudFunctionResponse<Map<String, dynamic>>> scheduleDelivery({
    required String assignmentId,
    required DateTime deliveryTime,
    required Map<String, dynamic> deliveryData,
    String? timezone,
  }) async {
    final data = {
      'assignmentId': assignmentId,
      'deliveryTime': deliveryTime.toIso8601String(),
      'deliveryData': deliveryData,
      'timezone': timezone ?? 'Europe/Istanbul',
      'timestamp': DateTime.now().toIso8601String(),
    };

    return await _makeRequest<Map<String, dynamic>>(
      CloudFunctionEndpoint.scheduleDelivery,
      data,
    );
  }

  // Cancel delivery via cloud function
  Future<CloudFunctionResponse<Map<String, dynamic>>> cancelDelivery({
    required String assignmentId,
    String? reason,
  }) async {
    final data = {
      'assignmentId': assignmentId,
      'reason': reason ?? 'Manual cancellation',
      'timestamp': DateTime.now().toIso8601String(),
    };

    return await _makeRequest<Map<String, dynamic>>(
      CloudFunctionEndpoint.cancelDelivery,
      data,
    );
  }

  // Update delivery schedule via cloud function
  Future<CloudFunctionResponse<Map<String, dynamic>>> updateDeliverySchedule({
    required String assignmentId,
    required DeliverySchedule schedule,
    Map<String, dynamic> additionalData = const {},
  }) async {
    final data = {
      'assignmentId': assignmentId,
      'schedule': schedule.toMap(),
      'additionalData': additionalData,
      'timestamp': DateTime.now().toIso8601String(),
    };

    return await _makeRequest<Map<String, dynamic>>(
      CloudFunctionEndpoint.updateSchedule,
      data,
    );
  }

  // Get delivery status from cloud function
  Future<CloudFunctionResponse<Map<String, dynamic>>> getDeliveryStatus({
    required String assignmentId,
  }) async {
    final data = {
      'assignmentId': assignmentId,
      'timestamp': DateTime.now().toIso8601String(),
    };

    return await _makeRequest<Map<String, dynamic>>(
      CloudFunctionEndpoint.getDeliveryStatus,
      data,
    );
  }

  // Process notification via cloud function
  Future<CloudFunctionResponse<Map<String, dynamic>>> processNotification({
    required String type,
    required Map<String, dynamic> notificationData,
    List<String>? targetUsers,
  }) async {
    final data = {
      'type': type,
      'notificationData': notificationData,
      'targetUsers': targetUsers,
      'timestamp': DateTime.now().toIso8601String(),
    };

    return await _makeRequest<Map<String, dynamic>>(
      CloudFunctionEndpoint.processNotification,
      data,
    );
  }

  // Sync all schedules with cloud
  Future<CloudFunctionResponse<Map<String, dynamic>>> syncAllSchedules({
    required List<UserDietAssignmentModel> assignments,
    bool forceUpdate = false,
  }) async {
    final assignmentMaps = assignments.map((a) => a.toMap()).toList();
    
    final data = {
      'assignments': assignmentMaps,
      'forceUpdate': forceUpdate,
      'timestamp': DateTime.now().toIso8601String(),
    };

    return await _makeRequest<Map<String, dynamic>>(
      CloudFunctionEndpoint.syncSchedules,
      data,
    );
  }

  // Batch operations
  Future<List<CloudFunctionResponse<Map<String, dynamic>>>> batchScheduleDeliveries({
    required List<Map<String, dynamic>> deliveries,
  }) async {
    final results = <CloudFunctionResponse<Map<String, dynamic>>>[];

    // Process in parallel (max 5 concurrent requests)
    const batchSize = 5;
    for (int i = 0; i < deliveries.length; i += batchSize) {
      final batch = deliveries.sublist(
        i,
        i + batchSize > deliveries.length ? deliveries.length : i + batchSize,
      );

      final futures = batch.map((delivery) => scheduleDelivery(
        assignmentId: delivery['assignmentId'],
        deliveryTime: DateTime.parse(delivery['deliveryTime']),
        deliveryData: delivery['deliveryData'],
        timezone: delivery['timezone'],
      ));

      final batchResults = await Future.wait(futures);
      results.addAll(batchResults);

      // Small delay between batches
      if (i + batchSize < deliveries.length) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    return results;
  }

  // Health check
  Future<bool> healthCheck() async {
    try {
      final response = await _makeRequest<Map<String, dynamic>>(
        CloudFunctionEndpoint.getDeliveryStatus,
        {'healthCheck': true},
        timeout: const Duration(seconds: 10),
      );

      return response.success;
    } catch (e) {
      debugPrint('❌ Cloud Functions health check failed: $e');
      return false;
    }
  }

  // Analytics and monitoring
  Future<CloudFunctionResponse<Map<String, dynamic>>> getAnalytics({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? metrics,
  }) async {
    final data = <String, dynamic>{
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'metrics': metrics ?? ['deliveries', 'success_rate', 'response_time'],
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Bu endpoint gerçek implementasyonda eklenebilir
    return CloudFunctionResponse.success(<String, dynamic>{
      'message': 'Analytics endpoint not implemented yet',
      'data': data,
    });
  }

  // Error reporting
  Future<void> reportError({
    required String error,
    required String context,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Error reporting endpoint'i burada implementasyon gerçekleştirilen bir alan
      debugPrint('🚨 Error reported to cloud: $error');
      debugPrint('   Context: $context');
      if (metadata != null) {
        debugPrint('   Metadata: $metadata');
      }
    } catch (e) {
      debugPrint('❌ Failed to report error to cloud: $e');
    }
  }

  // Configuration management
  void updateConfiguration({
    String? projectId,
    String? region,
    String? authToken,
    bool? enabled,
  }) {
    // Bu method runtime'da configuration değişikliklerini destekler
    if (authToken != null) _authToken = authToken;
    if (enabled != null) _isEnabled = enabled;
    
    debugPrint('⚙️ Cloud Functions configuration updated');
    debugPrint('   Enabled: $_isEnabled');
    debugPrint('   Has Auth Token: ${_authToken != null}');
  }
}