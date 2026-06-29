import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:iq_test/core/services/api/api_constants.dart';
import 'package:iq_test/core/services/api/api_functions.dart';
import 'package:iq_test/core/services/local_storage/product_cache_services.dart';
import 'package:iq_test/features/transactions/data/models/product_model.dart';

class ProductRepository {
  final ApiFunction _apiFunction;
  final ProductCacheService _cacheService;

  ProductRepository({ApiFunction? apiFunction, ProductCacheService? cacheService})
    : _apiFunction = apiFunction ?? ApiFunction(),
      _cacheService = cacheService ?? ProductCacheService();

  /// Fetches products with cache-first strategy.
  /// Returns [ProductsResult] containing data and whether it came from cache.
  Future<ProductsResult> getProducts({
    int limit = 20,
    int skip = 0,
    bool forceRefresh = false,
    CancelToken? cancelToken,
  }) async {
    final cacheKey = 'all_${limit}_$skip';

    // Try cache first (only for first page and not force refresh)
    if (!forceRefresh && skip == 0) {
      final cached = await _cacheService.getCachedProducts(cacheKey: cacheKey);
      if (cached != null) {
        final response = ProductsResponse.fromJson(cached);
        // Fetch fresh data in background
        _refreshInBackground(cacheKey: cacheKey, limit: limit, skip: skip);
        return ProductsResult(response: response, isFromCache: true);
      }
    }

    try {
      final response = await _apiFunction.getApiCall(
        apiName: ApiConstants.products,
        queryParameters: {'limit': limit, 'skip': skip},
        onBadResponse: (data) => throw apiErrorFilter(data),
        cancelToken: cancelToken,
      );

      if (response == null) throw Exception('No internet connection');
      final parsed = ProductsResponse.fromJson(response as Map<String, dynamic>);

      // Cache first page results
      if (skip == 0) {
        _cacheProducts(cacheKey: cacheKey, response: response);
      }

      return ProductsResult(response: parsed, isFromCache: false);
    } catch (e, stack) {
      debugPrintStack(stackTrace: stack, label: 'ProductRepository.getProducts');

      // Fallback to cache on error
      final cached = await _cacheService.getCachedProducts(cacheKey: 'all_${limit}_0');
      if (cached != null) {
        return ProductsResult(response: ProductsResponse.fromJson(cached), isFromCache: true);
      }
      rethrow;
    }
  }

  Future<ProductsResponse> searchProducts({
    required String query,
    int limit = 20,
    int skip = 0,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _apiFunction.getApiCall(
        apiName: ApiConstants.productSearch,
        queryParameters: {'q': query, 'limit': limit, 'skip': skip},
        onBadResponse: (data) => throw apiErrorFilter(data),
        cancelToken: cancelToken,
      );

      if (response == null) throw Exception('No internet connection');
      return ProductsResponse.fromJson(response as Map<String, dynamic>);
    } catch (e, stack) {
      debugPrintStack(stackTrace: stack, label: 'ProductRepository.searchProducts');
      rethrow;
    }
  }

  Future<List<String>> getCategories({CancelToken? cancelToken}) async {
    // Try cache first
    final cached = await _cacheService.getCachedCategories();
    if (cached != null) return cached;

    try {
      final response = await _apiFunction.getApiCall(
        apiName: ApiConstants.productCategories,
        onBadResponse: (data) => throw apiErrorFilter(data),
        cancelToken: cancelToken,
      );

      if (response == null) throw Exception('No internet connection');
      final list = response as List<dynamic>;
      final categories = list
          .map((e) {
            if (e is Map<String, dynamic>) return e['slug'] as String? ?? '';
            return e.toString();
          })
          .where((s) => s.isNotEmpty)
          .toList();

      // Cache categories
      _cacheService.cacheCategories(categories);
      return categories;
    } catch (e, stack) {
      debugPrintStack(stackTrace: stack, label: 'ProductRepository.getCategories');
      rethrow;
    }
  }

  Future<ProductsResponse> getProductsByCategory({
    required String category,
    int limit = 20,
    int skip = 0,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _apiFunction.getApiCall(
        apiName: '${ApiConstants.productsByCategory}/$category',
        queryParameters: {'limit': limit, 'skip': skip},
        onBadResponse: (data) => throw apiErrorFilter(data),
        cancelToken: cancelToken,
      );

      if (response == null) throw Exception('No internet connection');
      return ProductsResponse.fromJson(response as Map<String, dynamic>);
    } catch (e, stack) {
      debugPrintStack(stackTrace: stack, label: 'ProductRepository.getProductsByCategory($category)');
      rethrow;
    }
  }

  Future<ProductModel> getProductById({required int id, CancelToken? cancelToken}) async {
    try {
      final response = await _apiFunction.getApiCall(
        apiName: '${ApiConstants.products}/$id',
        onBadResponse: (data) => throw apiErrorFilter(data),
        cancelToken: cancelToken,
      );

      if (response == null) throw Exception('No internet connection');
      return ProductModel.fromJson(response as Map<String, dynamic>);
    } catch (e, stack) {
      debugPrintStack(stackTrace: stack, label: 'ProductRepository.getProductById($id)');
      rethrow;
    }
  }

  /// Clear all cached data (for pull-to-refresh)
  Future<void> clearCache() async {
    await _cacheService.clearAll();
  }

  void _cacheProducts({required String cacheKey, required Map<String, dynamic> response}) {
    final products = (response['products'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];
    final total = (response['total'] as num?)?.toInt() ?? 0;
    _cacheService.cacheProducts(cacheKey: cacheKey, productsJson: products, total: total);
  }

  Future<void> _refreshInBackground({required String cacheKey, required int limit, required int skip}) async {
    try {
      final response = await _apiFunction.getApiCall(
        apiName: ApiConstants.products,
        queryParameters: {'limit': limit, 'skip': skip},
      );
      if (response != null) {
        _cacheProducts(cacheKey: cacheKey, response: response as Map<String, dynamic>);
      }
    } catch (_) {
      // Silent fail for background refresh
    }
  }
}

/// Wraps a [ProductsResponse] with metadata about data source.
class ProductsResult {
  final ProductsResponse response;
  final bool isFromCache;

  const ProductsResult({required this.response, required this.isFromCache});
}
