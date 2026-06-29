import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:iq_test/core/services/api/api_constants.dart';

/// Handles all HTTP API requests with proper error handling, authentication, and request cancellation.
/// Implemented as a singleton to reuse Dio instance and maintain consistent configuration.
class ApiHandler {
  // --- Singleton boilerplate ---
  ApiHandler._internal(this.dio);
  static final ApiHandler _instance = ApiHandler._internal(_createDio());
  factory ApiHandler({Dio? dio}) => dio == null ? _instance : ApiHandler._internal(dio);

  /// Shared Dio instance for all HTTP requests - reuses connections and configuration
  final Dio dio;

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: kDebugMode ? 120 : 60),
        receiveTimeout: const Duration(seconds: kDebugMode ? 120 : 60),
        responseType: ResponseType.json,
      ),
    );

    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(request: true, requestBody: true, responseBody: true, error: true));
    }
    return dio;
  }

  /// Builds request options with authentication header and content type.
  // Options _buildOptions(Options? options) {}

  /// Validates HTTP response status and extracts data.
  /// Throws DioException for non-2xx status codes.
  dynamic _handleResponse(Response response) {
    if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
      return response.data;
    } else {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'API request failed with status code ${response.statusCode}',
      );
    }
  }

  /// Logs error information for debugging purposes
  void onError(ErrorEntity eInfo) {
    if (kDebugMode) {
      print("error.code -> ${eInfo.code}, error.message -> ${eInfo.message}");
    }
  }

  /// Converts DioException to standardized ErrorEntity with appropriate error codes.
  /// Maps various network/API errors to user-friendly messages.
  ErrorEntity createErrorEntity(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return ErrorEntity(code: 01, message: 'Connection timeout.');
      case DioExceptionType.sendTimeout:
        return ErrorEntity(code: 02, message: 'Request send timeout.');
      case DioExceptionType.receiveTimeout:
        return ErrorEntity(code: 03, message: 'Receiving timeout occurred.');
      case DioExceptionType.cancel:
        return ErrorEntity(code: 04, message: 'Request cancelled.');
      case DioExceptionType.connectionError:
        return ErrorEntity(code: 05, message: "Failed to connect.");
      case DioExceptionType.badResponse:
        // Try to extract the real error message from the response data
        String message = "An error occurred. Try again later";
        final data = error.response?.data;
        if (data is Map && data['message'] != null) {
          message = data['message'];
        }
        return ErrorEntity(code: error.response?.statusCode ?? 000, message: message);
      case DioExceptionType.unknown:
        if (error.message?.contains('SocketException') ?? false) {
          return ErrorEntity(code: 06, message: "No Internet available.");
        }
        return ErrorEntity(code: 07, message: "Unexpected error occurred.");
      default:
        return ErrorEntity(code: 00, message: "Something went wrong.");
    }
  }

  /// ---- REST Methods ----
  /// Each method creates its own CancelToken for independent request cancellation.
  /// This allows cancelling individual requests without affecting others (industry standard).

  /// Performs HTTP GET request with authentication and error handling.
  /// Returns response data on success, calls onBadResponse callback on error.
  Future get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    Function(BadApiResponse value)? onBadResponse,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await dio.get(
        path,
        queryParameters: queryParameters,
        cancelToken: cancelToken ?? CancelToken(), // Create per-request cancel token
      );
      return _handleResponse(response);
    } on DioException catch (value) {
      _handleError(value, onBadResponse);
      rethrow; // Re-throw to allow caller to handle errors
    }
  }

  /// Performs HTTP POST request with automatic JSON encoding for non-FormData payloads.
  /// Supports both JSON objects and FormData for file uploads.
  Future post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    Function(BadApiResponse value)? onBadResponse,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await dio.post(
        path,
        data: (data is FormData) ? data : jsonEncode(data), // Handle both JSON and file uploads
        queryParameters: queryParameters,
        cancelToken: cancelToken ?? CancelToken(),
      );
      return _handleResponse(response);
    } on DioException catch (value) {
      _handleError(value, onBadResponse);
      rethrow;
    }
  }

  /// Performs HTTP PUT request for updating resources.
  /// Automatically encodes JSON data.
  Future put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    Function(BadApiResponse value)? onBadResponse,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await dio.put(
        path,
        data: (data is FormData) ? data : jsonEncode(data), // Consistent with POST/PATCH
        queryParameters: queryParameters,
        cancelToken: cancelToken ?? CancelToken(),
      );
      return _handleResponse(response);
    } on DioException catch (value) {
      _handleError(value, onBadResponse);
      rethrow;
    }
  }

  /// Performs HTTP DELETE request for removing resources.
  /// Supports optional request body (some APIs require it).
  Future delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    Function(BadApiResponse value)? onBadResponse,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await dio.delete(
        path,
        data: data != null ? jsonEncode(data) : null, // Consistent JSON encoding
        queryParameters: queryParameters,
        cancelToken: cancelToken ?? CancelToken(),
      );
      return _handleResponse(response);
    } on DioException catch (value) {
      _handleError(value, onBadResponse);
      rethrow;
    }
  }

  /// Performs HTTP PATCH request for partial resource updates.
  /// Supports both JSON objects and FormData.
  Future patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    Function(BadApiResponse value)? onBadResponse,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await dio.patch(
        path,
        data: (data is FormData) ? data : jsonEncode(data),
        queryParameters: queryParameters,
        cancelToken: cancelToken ?? CancelToken(),
      );
      return _handleResponse(response);
    } on DioException catch (value) {
      _handleError(value, onBadResponse);
      rethrow;
    }
  }

  /// ---- Shared error handler ----
  /// Processes DioException, logs it, and invokes optional error callback.
  /// Extracts error details from response for structured error handling.
  void _handleError(DioException value, Function(BadApiResponse value)? onBadResponse) {
    onError(createErrorEntity(value));
    // Pass structured error data to callback if provided
    onBadResponse?.call(BadApiResponse.fromJson({'code': value.response?.statusCode, 'data': value.response?.data}));
  }
}

/// Custom exception class for structured error handling across the app.
/// Provides both error code (for programmatic handling) and message (for user display).
class ErrorEntity implements Exception {
  final int code;
  final String message;

  ErrorEntity({required this.code, required this.message});

  @override
  String toString() => message.isEmpty ? "Exception" : "Exception: code $code, $message";
}

// Response model for failed API calls

class BadApiResponse {
  int? code;
  dynamic data;

  BadApiResponse({this.code, this.data});

  factory BadApiResponse.fromJson(Map<String, dynamic> json) =>
      BadApiResponse(code: json['code'] as int?, data: json['data']);

  Map<String, dynamic> toJson() => {'code': code, 'data': data};
}
