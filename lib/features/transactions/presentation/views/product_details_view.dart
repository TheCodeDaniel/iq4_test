import 'package:flutter/material.dart';
import 'package:iq_test/core/widgets/price_tag.dart';
import 'package:iq_test/core/widgets/rating_bar.dart';
import 'package:iq_test/features/transactions/data/models/product_model.dart';
import 'package:iq_test/features/transactions/presentation/widgets/info_row.dart';
import 'package:iq_test/features/transactions/presentation/widgets/product_image_gallery.dart';
import 'package:iq_test/features/transactions/presentation/widgets/stock_badge.dart';

class ProductDetailsView extends StatelessWidget {
  final ProductModel product;
  const ProductDetailsView({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductImageGallery(product: product),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.title, style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text(
                    product.brand,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  PriceTag(product: product, large: true),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      RatingBar(rating: product.rating, size: 20),
                      const SizedBox(width: 16),
                      StockBadge(product: product),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Chip(label: Text(product.category), avatar: const Icon(Icons.category, size: 16)),
                  const SizedBox(height: 16),
                  Text('Description', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(product.description, style: theme.textTheme.bodyMedium),
                  _buildAdditionalInfo(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfo() {
    final hasInfo =
        product.warrantyInformation.isNotEmpty ||
        product.shippingInformation.isNotEmpty ||
        product.returnPolicy.isNotEmpty;

    if (!hasInfo) return const SizedBox.shrink();

    return Column(
      children: [
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        if (product.warrantyInformation.isNotEmpty)
          InfoRow(icon: Icons.verified_user_outlined, label: product.warrantyInformation),
        if (product.shippingInformation.isNotEmpty)
          InfoRow(icon: Icons.local_shipping_outlined, label: product.shippingInformation),
        if (product.returnPolicy.isNotEmpty)
          InfoRow(icon: Icons.assignment_return_outlined, label: product.returnPolicy),
      ],
    );
  }
}
