import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iq_test/features/transactions/presentation/bloc/product_events.dart';
import 'package:iq_test/features/transactions/presentation/bloc/products_state.dart';
import 'package:iq_test/features/transactions/data/models/product_model.dart';
import 'package:iq_test/features/transactions/data/repository/products_repository.dart';

const int _pageSize = 20;
const Duration _debounceDuration = Duration(milliseconds: 300);

class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  final ProductRepository _repository;
  Timer? _searchDebounce;

  ProductsBloc({ProductRepository? repository})
    : _repository = repository ?? ProductRepository(),
      super(const ProductsState()) {
    on<LoadProducts>(_onLoadProducts);
    on<LoadMoreProducts>(_onLoadMoreProducts);
    on<SearchProducts>(_onSearchProducts);
    on<SelectCategory>(_onSelectCategory);
    on<ClearFilters>(_onClearFilters);
    on<RefreshProducts>(_onRefreshProducts);
    on<SelectProduct>(_onSelectProduct);
  }

  Future<void> _onLoadProducts(LoadProducts event, Emitter<ProductsState> emit) async {
    emit(state.copyWith(status: ProductsStatus.loading, errorMessage: () => null));

    try {
      final results = await Future.wait([
        _fetchProducts(skip: 0),
        if (state.categories.isEmpty) _repository.getCategories(),
      ]);

      final fetchResult = results[0];
      final categories = results.length > 1 ? results[1] as List<String> : state.categories;

      // Handle cache-aware response for plain getProducts
      if (fetchResult is ProductsResult) {
        emit(
          state.copyWith(
            status: ProductsStatus.loaded,
            products: fetchResult.response.products,
            categories: categories,
            currentSkip: fetchResult.response.products.length,
            total: fetchResult.response.total,
            hasReachedMax: !fetchResult.response.hasMore,
            isFromCache: fetchResult.isFromCache,
          ),
        );
      } else {
        final productsResponse = fetchResult as ProductsResponse;
        emit(
          state.copyWith(
            status: ProductsStatus.loaded,
            products: productsResponse.products,
            categories: categories,
            currentSkip: productsResponse.products.length,
            total: productsResponse.total,
            hasReachedMax: !productsResponse.hasMore,
            isFromCache: false,
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(status: ProductsStatus.error, errorMessage: () => e.toString()));
    }
  }

  Future<void> _onLoadMoreProducts(LoadMoreProducts event, Emitter<ProductsState> emit) async {
    if (state.hasReachedMax || state.isLoadingMore) return;

    emit(state.copyWith(isLoadingMore: true));

    try {
      final result = await _fetchProducts(skip: state.currentSkip);
      final response = result is ProductsResult ? result.response : result as ProductsResponse;

      emit(
        state.copyWith(
          products: [...state.products, ...response.products],
          currentSkip: state.currentSkip + response.products.length,
          hasReachedMax: !response.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onSearchProducts(SearchProducts event, Emitter<ProductsState> emit) async {
    _searchDebounce?.cancel();

    final query = event.query.trim();
    emit(state.copyWith(searchQuery: query));

    if (query.isEmpty && state.selectedCategory == null) {
      add(const LoadProducts());
      return;
    }

    final completer = Completer<void>();

    _searchDebounce = Timer(_debounceDuration, () {
      _performSearch(emit, query).then((_) => completer.complete());
    });

    await completer.future;
  }

  Future<void> _performSearch(Emitter<ProductsState> emit, String query) async {
    emit(state.copyWith(status: ProductsStatus.loading, errorMessage: () => null));

    try {
      final result = await _fetchProducts(skip: 0);
      final response = result is ProductsResult ? result.response : result as ProductsResponse;

      emit(
        state.copyWith(
          status: ProductsStatus.loaded,
          products: response.products,
          currentSkip: response.products.length,
          total: response.total,
          hasReachedMax: !response.hasMore,
          isFromCache: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: ProductsStatus.error, errorMessage: () => e.toString()));
    }
  }

  Future<void> _onSelectCategory(SelectCategory event, Emitter<ProductsState> emit) async {
    final isSameCategory = state.selectedCategory == event.category;
    emit(state.copyWith(selectedCategory: () => isSameCategory ? null : event.category));
    add(const LoadProducts());
  }

  Future<void> _onClearFilters(ClearFilters event, Emitter<ProductsState> emit) async {
    emit(state.copyWith(searchQuery: '', selectedCategory: () => null));
    add(const LoadProducts());
  }

  Future<void> _onRefreshProducts(RefreshProducts event, Emitter<ProductsState> emit) async {
    await _repository.clearCache();
    emit(state.copyWith(isFromCache: false));
    add(const LoadProducts());
  }

  Future<void> _onSelectProduct(SelectProduct event, Emitter<ProductsState> emit) async {
    final existing = state.products.where((p) => p.id == event.productId);
    if (existing.isNotEmpty) {
      emit(state.copyWith(selectedProduct: () => existing.first));
      return;
    }

    try {
      final product = await _repository.getProductById(id: event.productId);
      emit(state.copyWith(selectedProduct: () => product));
    } catch (e) {
      // Keep current state if fetch fails
    }
  }

  /// Unified fetch method that respects current search query and category filters.
  /// Returns [ProductsResult] for plain getProducts (cache-aware), [ProductsResponse] otherwise.
  Future<dynamic> _fetchProducts({required int skip}) {
    final query = state.searchQuery;
    final category = state.selectedCategory;

    if (query.isNotEmpty && category != null) {
      return _repository.getProductsByCategory(category: category, limit: 100, skip: 0).then((response) {
        final filtered = response.products.where((p) => p.title.toLowerCase().contains(query.toLowerCase())).toList();
        final paged = filtered.skip(skip).take(_pageSize).toList();
        return ProductsResponse(products: paged, total: filtered.length, skip: skip, limit: _pageSize);
      });
    } else if (query.isNotEmpty) {
      return _repository.searchProducts(query: query, limit: _pageSize, skip: skip);
    } else if (category != null) {
      return _repository.getProductsByCategory(category: category, limit: _pageSize, skip: skip);
    } else {
      return _repository.getProducts(limit: _pageSize, skip: skip);
    }
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }
}
