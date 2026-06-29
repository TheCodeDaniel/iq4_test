import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iq_test/core/extensions/navigation_extensions.dart';
import 'package:iq_test/core/widgets/empty_state.dart';
import 'package:iq_test/core/widgets/error_state.dart';
import 'package:iq_test/core/widgets/product_card.dart';
import 'package:iq_test/core/widgets/shimmer_loading.dart';
import 'package:iq_test/core/widgets/staggered_list_item.dart';
import 'package:iq_test/features/transactions/presentation/bloc/product_events.dart';
import 'package:iq_test/features/transactions/presentation/bloc/products_bloc.dart';
import 'package:iq_test/features/transactions/presentation/bloc/products_state.dart';
import 'package:iq_test/features/transactions/presentation/views/product_details_view.dart';

class ProductsListView extends StatelessWidget {
  final ScrollController scrollController;
  final int? selectedProductId;
  final ValueChanged<int>? onProductSelected;

  const ProductsListView({super.key, required this.scrollController, this.selectedProductId, this.onProductSelected});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductsBloc, ProductsState>(
      builder: (context, state) {
        switch (state.status) {
          case ProductsStatus.initial:
          case ProductsStatus.loading:
            return const ShimmerLoading();
          case ProductsStatus.error:
            return ErrorState(
              message: state.errorMessage ?? 'Something went wrong.',
              onRetry: () {
                context.read<ProductsBloc>().add(const LoadProducts());
              },
            );
          case ProductsStatus.loaded:
            if (state.products.isEmpty) {
              return const EmptyState();
            }
            return RefreshIndicator(
              onRefresh: () async {
                context.read<ProductsBloc>().add(const RefreshProducts());
              },
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: state.products.length + (state.isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= state.products.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final product = state.products[index];
                  return StaggeredListItem(
                    index: index,
                    child: ProductCard(
                      product: product,
                      isSelected: product.id == selectedProductId,
                      onTap: () {
                        context.push(ProductDetailsView(product: product));
                      },
                    ),
                  );
                },
              ),
            );
        }
      },
    );
  }
}
