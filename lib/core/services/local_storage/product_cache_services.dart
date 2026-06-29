import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ProductCacheService {
  static const String _productsBoxName = 'products_cache';
  static const String _productsKey = 'cached_products';
  static const String _categoriesKey = 'cached_categories';
  static const String _timestampKey = 'cache_timestamp';
  static const Duration _cacheExpiry = Duration(hours: 1);

  ProductCacheService._internal();
  static final ProductCacheService _instance = ProductCacheService._internal();
  factory ProductCacheService() => _instance;

  Box? _box;

  Future<Box> _getBox() async {
    _box ??= await Hive.openBox(_productsBoxName);
    return _box!;
  }

  /// Initialize Hive — call once in main.dart
  static Future<void> init() async {
    await Hive.initFlutter();
  }

  /// Cache products JSON list for a given cache key (e.g. "all", "category:phones", "search:iphone")
  Future<void> cacheProducts({
    required String cacheKey,
    required List<Map<String, dynamic>> productsJson,
    required int total,
  }) async {
    try {
      final box = await _getBox();
      final data = jsonEncode({'products': productsJson, 'total': total});
      await box.put('${_productsKey}_$cacheKey', data);
      await box.put('${_timestampKey}_$cacheKey', DateTime.now().millisecondsSinceEpoch);
    } catch (e, stack) {
      debugPrintStack(stackTrace: stack, label: 'ProductCacheService.cacheProducts');
    }
  }

  /// Retrieve cached products for a given cache key. Returns null if expired or missing.
  Future<Map<String, dynamic>?> getCachedProducts({required String cacheKey}) async {
    try {
      final box = await _getBox();
      final timestamp = box.get('${_timestampKey}_$cacheKey') as int?;
      if (timestamp == null) return null;

      final cachedAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (DateTime.now().difference(cachedAt) > _cacheExpiry) {
        await _clearKey(cacheKey);
        return null;
      }

      final data = box.get('${_productsKey}_$cacheKey') as String?;
      if (data == null) return null;

      return jsonDecode(data) as Map<String, dynamic>;
    } catch (e, stack) {
      debugPrintStack(stackTrace: stack, label: 'ProductCacheService.getCachedProducts');
      return null;
    }
  }

  /// Cache categories list
  Future<void> cacheCategories(List<String> categories) async {
    try {
      final box = await _getBox();
      await box.put(_categoriesKey, jsonEncode(categories));
      await box.put('${_timestampKey}_categories', DateTime.now().millisecondsSinceEpoch);
    } catch (e, stack) {
      debugPrintStack(stackTrace: stack, label: 'ProductCacheService.cacheCategories');
    }
  }

  /// Retrieve cached categories. Returns null if expired or missing.
  Future<List<String>?> getCachedCategories() async {
    try {
      final box = await _getBox();
      final timestamp = box.get('${_timestampKey}_categories') as int?;
      if (timestamp == null) return null;

      final cachedAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (DateTime.now().difference(cachedAt) > _cacheExpiry) {
        return null;
      }

      final data = box.get(_categoriesKey) as String?;
      if (data == null) return null;

      final decoded = jsonDecode(data) as List<dynamic>;
      return decoded.map((e) => e.toString()).toList();
    } catch (e, stack) {
      debugPrintStack(stackTrace: stack, label: 'ProductCacheService.getCachedCategories');
      return null;
    }
  }

  /// Check if data for a cache key is from cache (not expired)
  Future<bool> isCached({required String cacheKey}) async {
    try {
      final box = await _getBox();
      final timestamp = box.get('${_timestampKey}_$cacheKey') as int?;
      if (timestamp == null) return false;

      final cachedAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return DateTime.now().difference(cachedAt) <= _cacheExpiry;
    } catch (_) {
      return false;
    }
  }

  /// Clear cache for a specific key
  Future<void> _clearKey(String cacheKey) async {
    try {
      final box = await _getBox();
      await box.delete('${_productsKey}_$cacheKey');
      await box.delete('${_timestampKey}_$cacheKey');
    } catch (e, stack) {
      debugPrintStack(stackTrace: stack, label: 'ProductCacheService._clearKey');
    }
  }

  /// Clear all product cache (e.g. on pull-to-refresh)
  Future<void> clearAll() async {
    try {
      final box = await _getBox();
      await box.clear();
    } catch (e, stack) {
      debugPrintStack(stackTrace: stack, label: 'ProductCacheService.clearAll');
    }
  }
}
