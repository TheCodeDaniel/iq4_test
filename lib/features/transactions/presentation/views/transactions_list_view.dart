import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iq_test/core/widgets/cache_banner.dart';
import 'package:iq_test/features/transactions/presentation/bloc/product_events.dart';
import 'package:iq_test/features/transactions/presentation/bloc/products_bloc.dart';
import 'package:iq_test/features/transactions/presentation/bloc/products_state.dart';
import 'package:iq_test/features/transactions/presentation/widgets/products_list_view.dart';

class TransactionsListView extends StatefulWidget {
  const TransactionsListView({super.key});

  @override
  State<TransactionsListView> createState() => _TransactionsListViewState();
}

class _TransactionsListViewState extends State<TransactionsListView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final bloc = context.read<ProductsBloc>();
    if (bloc.state.status == ProductsStatus.initial) {
      bloc.add(const LoadProducts());
    }
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    if (currentScroll >= maxScroll - 200) {
      context.read<ProductsBloc>().add(const LoadMoreProducts());
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text("Your Transactions", style: TextStyle(color: Colors.black)),
        ),
        body: SafeArea(
          child: Column(
            children: [
              BlocBuilder<ProductsBloc, ProductsState>(
                buildWhen: (prev, curr) => prev.isFromCache != curr.isFromCache,
                builder: (context, state) {
                  if (!state.isFromCache) return const SizedBox.shrink();
                  return CacheBanner(onRefresh: () => context.read<ProductsBloc>().add(const RefreshProducts()));
                },
              ),
              // Expanded(child: ListView.builder(itemBuilder: (context, index) => TransactionsListTile(), itemCount: 5)),
              Expanded(child: ProductsListView(scrollController: _scrollController)),
            ],
          ),
        ),
      ),
    );
  }
}
