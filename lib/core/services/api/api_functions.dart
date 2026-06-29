import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:iq_test/core/services/api/api_handler.dart';

/// Wrapper service that adds internet connectivity checks before making API calls.
/// Ensures all HTTP requests only proceed when network is available, showing toast on failure.
/// Implemented as singleton to maintain consistent connectivity state.
class ApiFunction {
  // --- Singleton boilerplate ---
  ApiFunction._internal();
  static final ApiFunction _instance = ApiFunction._internal();
  factory ApiFunction() => _instance;

  /// Latest connectivity check result
  List<ConnectivityResult> connectivityResult = [];
  final Connectivity connectivity = Connectivity();

  /// Checks device internet connectivity before making API requests.
  /// Shows toast notification when no internet is available.
  /// Returns true if WiFi or mobile data is connected, false otherwise.
  Future<bool> getConnectivityResult() async {
    try {
      connectivityResult = await connectivity.checkConnectivity();

      // Check for active WiFi or mobile data connection
      if (connectivityResult.contains(ConnectivityResult.wifi) ||
          connectivityResult.contains(ConnectivityResult.mobile)) {
        // Cancel any existing "No Internet" toast when connection is restored
        await Fluttertoast.cancel();
        return true;
      } else {
        Fluttertoast.showToast(msg: "No Internet Available");
        return false;
      }
    } on PlatformException catch (_) {
      // Platform-specific error (e.g., permissions denied)
      Fluttertoast.showToast(msg: "No Internet Available");
      return false;
    }
  }

  /// Performs GET request with connectivity check.
  /// Returns null if no internet connection is available.
  /// Throws exception on API errors (caught and handled by ApiHandler).
  Future<dynamic> getApiCall({
    required String apiName,
    dynamic queryParameters,
    Options? options,
    Function(BadApiResponse data)? onBadResponse,
    CancelToken? cancelToken,
  }) async {
    // Only proceed if internet is available
    if (await getConnectivityResult()) {
      return await ApiHandler().get(
        apiName,
        queryParameters: queryParameters,
        onBadResponse: onBadResponse,
        options: options,
        cancelToken: cancelToken,
      );
    }
    return null; // Explicit null return when no connectivity
  }

  /// Performs POST request with connectivity check.
  /// Used for creating resources or submitting data.
  Future<dynamic> postApiCall({
    required String apiName,
    dynamic params,
    Function(BadApiResponse data)? onBadResponse,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    if (await getConnectivityResult()) {
      return await ApiHandler().post(
        apiName,
        data: params,
        onBadResponse: onBadResponse,
        options: options,
        cancelToken: cancelToken,
      );
    }
    return null;
  }

  /// Performs PATCH request with connectivity check.
  /// Used for partial updates to existing resources.
  Future<dynamic> patchApiCall({
    required String apiName,
    dynamic params,
    Function(BadApiResponse data)? onBadResponse,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    if (await getConnectivityResult()) {
      return await ApiHandler().patch(
        apiName,
        data: params,
        onBadResponse: onBadResponse,
        options: options,
        cancelToken: cancelToken,
      );
    }
    return null;
  }

  /// Performs PUT request with connectivity check.
  /// Used for complete replacement of existing resources.
  Future<dynamic> putApiCall({
    required String apiName,
    dynamic params,
    Function(BadApiResponse data)? onBadResponse,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    if (await getConnectivityResult()) {
      return await ApiHandler().put(
        apiName,
        data: params,
        onBadResponse: onBadResponse,
        options: options,
        cancelToken: cancelToken,
      );
    }
    return null;
  }

  /// Performs DELETE request with connectivity check.
  /// Used for removing resources from the server.
  Future<dynamic> deleteApiCall({
    required String apiName,
    dynamic params,
    Function(BadApiResponse data)? onBadResponse,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    if (await getConnectivityResult()) {
      return await ApiHandler().delete(
        apiName,
        data: params,
        onBadResponse: onBadResponse,
        options: options,
        cancelToken: cancelToken,
      );
    }
    return null;
  }
}

String apiErrorFilter(BadApiResponse res) {
  return "Request current unavailable, please try again later";
}
