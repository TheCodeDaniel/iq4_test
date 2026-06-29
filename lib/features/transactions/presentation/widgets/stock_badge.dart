import 'package:flutter/material.dart';
import 'package:iq_test/features/transactions/data/models/product_model.dart';

class StockBadge extends StatelessWidget {
  final ProductModel product;

  const StockBadge({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = product.isInStock ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(
        product.isInStock ? 'In Stock (${product.stock})' : 'Out of Stock',
        style: theme.textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
