import 'package:equatable/equatable.dart';

sealed class ProductsEvent extends Equatable {
  const ProductsEvent();

  @override
  List<Object?> get props => [];
}

class LoadProducts extends ProductsEvent {
  const LoadProducts();
}

class LoadMoreProducts extends ProductsEvent {
  const LoadMoreProducts();
}

class SearchProducts extends ProductsEvent {
  final String query;
  const SearchProducts(this.query);

  @override
  List<Object?> get props => [query];
}

class SelectCategory extends ProductsEvent {
  final String? category;
  const SelectCategory(this.category);

  @override
  List<Object?> get props => [category];
}

class ClearFilters extends ProductsEvent {
  const ClearFilters();
}

class RefreshProducts extends ProductsEvent {
  const RefreshProducts();
}

class SelectProduct extends ProductsEvent {
  final int productId;
  const SelectProduct(this.productId);

  @override
  List<Object?> get props => [productId];
}
