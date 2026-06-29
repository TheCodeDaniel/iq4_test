import 'package:flutter/material.dart';
import 'package:iq_test/features/transactions/data/models/product_model.dart';

class PriceTag extends StatelessWidget {
  final ProductModel product;
  final bool large;

  const PriceTag({super.key, required this.product, this.large = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!product.hasPriceAvailable) {
      return Text(
        'Price unavailable',
        style: (large ? theme.textTheme.titleMedium : theme.textTheme.bodyMedium)?.copyWith(color: Colors.red),
      );
    }

    final discountedStyle = (large ? theme.textTheme.titleLarge : theme.textTheme.titleMedium)?.copyWith(
      fontWeight: FontWeight.bold,
    );

    if (!product.hasDiscount) {
      return Text('\$${product.price.toStringAsFixed(2)}', style: discountedStyle);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text('\$${product.discountedPrice.toStringAsFixed(2)}', style: discountedStyle),
        const SizedBox(width: 6),
        Text(
          '\$${product.price.toStringAsFixed(2)}',
          style: (large ? theme.textTheme.bodyMedium : theme.textTheme.bodySmall)?.copyWith(
            decoration: TextDecoration.lineThrough,
          ),
        ),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: Colors.brown.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
          child: Text(
            '-${product.discountPercentage.toStringAsFixed(0)}%',
            style: TextStyle(fontSize: large ? 13 : 11, fontWeight: FontWeight.w600, color: Colors.brown),
          ),
        ),
      ],
    );
  }
}
