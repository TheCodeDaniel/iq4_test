import 'package:flutter/material.dart';
import 'package:iq_test/core/widgets/transactions_list_tile.dart';

class TransactionsListView extends StatefulWidget {
  const TransactionsListView({super.key});

  @override
  State<TransactionsListView> createState() => _TransactionsListViewState();
}

class _TransactionsListViewState extends State<TransactionsListView> {
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
              Expanded(child: ListView.builder(itemBuilder: (context, index) => TransactionsListTile(), itemCount: 5)),
            ],
          ),
        ),
      ),
    );
  }
}
