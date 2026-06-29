import 'package:flutter/material.dart';
import 'package:iq_test/core/widgets/cached_image.dart';
import 'package:iq_test/features/transactions/data/models/product_model.dart';

class ProductImageGallery extends StatelessWidget {
  final ProductModel product;

  const ProductImageGallery({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 300,
          child: product.images.isNotEmpty
              ? PageView.builder(
                  itemCount: product.images.length,
                  itemBuilder: (context, index) {
                    final image = CachedImage(
                      imageUrl: product.images[index],
                      width: double.infinity,
                      height: 300,
                      fit: BoxFit.contain,
                    );
                    if (index == 0) {
                      return Hero(tag: 'product_image_${product.id}', child: image);
                    }
                    return image;
                  },
                )
              : Hero(
                  tag: 'product_image_${product.id}',
                  child: CachedImage(
                    imageUrl: product.thumbnail,
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.contain,
                  ),
                ),
        ),
        if (product.images.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.swipe, size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text('${product.images.length} images', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
      ],
    );
  }
}
