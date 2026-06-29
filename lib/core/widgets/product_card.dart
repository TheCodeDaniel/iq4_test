import 'package:flutter/material.dart';
import 'package:iq_test/core/widgets/cached_image.dart';
import 'package:iq_test/features/transactions/data/models/product_model.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final bool isSelected;
  final bool enableHero;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.isSelected = false,
    this.enableHero = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected ? BorderSide(color: theme.colorScheme.primary, width: 2) : BorderSide.none,
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildThumbnail(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        style: theme.textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.brand,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // PriceTag(product: product),
                      const SizedBox(height: 6),
                      // Row(
                      //   children: [
                      //     RatingBar(rating: product.rating, size: 14),
                      //     const Spacer(),
                      //     _StockIndicator(inStock: product.isInStock),
                      //   ],
                      // ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    final image = CachedImage(
      imageUrl: product.thumbnail,
      width: 100,
      height: 100,
      borderRadius: BorderRadius.circular(8),
    );

    if (!enableHero) return image;

    return Hero(tag: 'product_image_${product.id}', child: image);
  }
}

// class _StockIndicator extends StatelessWidget {
//   final bool inStock;

//   const _StockIndicator({required this.inStock});

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Icon(inStock ? Icons.check_circle : Icons.cancel, size: 12, color: inStock ? Colors.green : Colors.red),
//         const SizedBox(width: 4),
//         Text(
//           inStock ? 'In Stock' : 'Out of Stock',
//           style: Theme.of(
//             context,
//           ).textTheme.bodySmall?.copyWith(fontSize: 11, color: inStock ? Colors.green : Colors.red),
//         ),
//       ],
//     );
//   }
// }
