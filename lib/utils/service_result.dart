/// Generic service result wrapper for API responses
class ServiceResult<T> {
  final bool isSuccess;
  final T? data;
  final String? error;
  final String? message;

  const ServiceResult({
    required this.isSuccess,
    this.data,
    this.error,
    this.message,
  });

  /// Create a successful result
  factory ServiceResult.success(T data, {String? message}) {
    return ServiceResult(
      isSuccess: true,
      data: data,
      message: message,
    );
  }

  /// Create a failed result
  factory ServiceResult.failure(String error, {String? message}) {
    return ServiceResult<T>(
      isSuccess: false,
      error: error,
      message: message,
    );
  }

  /// Check if result has data
  bool get hasData => data != null;

  /// Check if result has error
  bool get hasError => error != null;

  /// Get data or throw if not successful
  T get requireData {
    if (!isSuccess || data == null) {
      throw StateError('ServiceResult does not contain valid data. Error: $error');
    }
    return data!;
  }

  @override
  String toString() {
    return 'ServiceResult{isSuccess: $isSuccess, data: $data, error: $error, message: $message}';
  }
}

/// Extension methods for ServiceResult
extension ServiceResultExtensions<T> on ServiceResult<T> {
  /// Map the data to a different type if successful
  ServiceResult<R> map<R>(R Function(T) mapper) {
    if (isSuccess && data != null) {
      try {
        return ServiceResult.success(mapper(data!), message: message);
      } catch (e) {
        return ServiceResult.failure('Mapping failed: $e');
      }
    }
    return ServiceResult.failure(error ?? 'No data to map');
  }

  /// Execute action if successful
  void whenSuccess(void Function(T) action) {
    if (isSuccess && data != null) {
      action(data!);
    }
  }

  /// Execute action if failed
  void whenFailure(void Function(String) action) {
    if (!isSuccess && error != null) {
      action(error!);
    }
  }

  /// Fold the result into a single value
  R fold<R>(
    R Function(T data) onSuccess,
    R Function(String error) onFailure,
  ) {
    if (isSuccess && data != null) {
      return onSuccess(data!);
    }
    return onFailure(error ?? 'Unknown error');
  }
}