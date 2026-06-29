import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

class ProductModel extends Equatable {
  final int id;
  final String title;
  final String description;
  final String category;
  final double price;
  final double discountPercentage;
  final double rating;
  final int stock;
  final String brand;
  final String thumbnail;
  final List<String> images;
  final String availabilityStatus;
  final String warrantyInformation;
  final String shippingInformation;
  final String returnPolicy;
  final List<String> tags;

  const ProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.discountPercentage,
    required this.rating,
    required this.stock,
    required this.brand,
    required this.thumbnail,
    required this.images,
    required this.availabilityStatus,
    required this.warrantyInformation,
    required this.shippingInformation,
    required this.returnPolicy,
    required this.tags,
  });

  double get discountedPrice {
    if (price <= 0) return 0;
    return price - (price * discountPercentage / 100);
  }

  bool get hasDiscount => discountPercentage > 0;

  bool get isInStock => stock > 0;

  bool get hasPriceAvailable => price > 0;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Validate and log warnings for missing/invalid data
    final rawPrice = (json['price'] as num?)?.toDouble() ?? -1;
    if (rawPrice < 0) {
      debugPrint('[WARNING] Product ${json['id']}: Missing or negative price');
    }

    final rawThumbnail = json['thumbnail'] as String? ?? '';
    if (rawThumbnail.isEmpty || !_isValidUrl(rawThumbnail)) {
      debugPrint('[WARNING] Product ${json['id']}: Missing or invalid thumbnail URL');
    }

    final rawImages =
        (json['images'] as List<dynamic>?)?.map((e) => e as String).where((url) => _isValidUrl(url)).toList() ?? [];
    if (rawImages.isEmpty) {
      debugPrint('[WARNING] Product ${json['id']}: No valid image URLs');
    }

    final rawBrand = json['brand'] as String?;
    if (rawBrand == null || rawBrand.isEmpty) {
      debugPrint('[WARNING] Product ${json['id']}: Missing brand, using default');
    }

    return ProductModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? 'Untitled Product',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'Uncategorized',
      price: rawPrice < 0 ? -1 : rawPrice,
      discountPercentage: (json['discountPercentage'] as num?)?.toDouble() ?? 0,
      rating: (json['rating'] as num?)?.toDouble().clamp(0, 5) ?? 0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      brand: (rawBrand != null && rawBrand.isNotEmpty) ? rawBrand : 'Unknown brand',
      thumbnail: rawThumbnail,
      images: rawImages,
      availabilityStatus: json['availabilityStatus'] as String? ?? 'Unknown',
      warrantyInformation: json['warrantyInformation'] as String? ?? '',
      shippingInformation: json['shippingInformation'] as String? ?? '',
      returnPolicy: json['returnPolicy'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  static bool _isValidUrl(String url) {
    return Uri.tryParse(url)?.hasAbsolutePath ?? false;
  }

  @override
  List<Object?> get props => [id];
}

class ProductsResponse {
  final List<ProductModel> products;
  final int total;
  final int skip;
  final int limit;

  const ProductsResponse({required this.products, required this.total, required this.skip, required this.limit});

  bool get hasMore => skip + limit < total;

  factory ProductsResponse.fromJson(Map<String, dynamic> json) {
    return ProductsResponse(
      products:
          (json['products'] as List<dynamic>?)?.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList() ??
          [],
      total: (json['total'] as num?)?.toInt() ?? 0,
      skip: (json['skip'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 0,
    );
  }
}
