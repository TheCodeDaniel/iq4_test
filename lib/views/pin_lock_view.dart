import 'package:flutter/material.dart';
import 'package:iq_test/core/widgets/custom_pin_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:iq_test/extensions/navigation_extensions.dart';
import 'package:iq_test/views/transactions_list_view.dart';

class PinLockView extends StatefulWidget {
  const PinLockView({super.key});

  @override
  State<PinLockView> createState() => _PinLockViewState();
}

class _PinLockViewState extends State<PinLockView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: CustomPinScreen(onPinComplete: _handlePinCheck)),
    );
  }

  void _handlePinCheck(String value) {
    if (value == "123456") {
      // PIN is correct, navigate to the next screen or perform desired action
      Fluttertoast.showToast(msg: "PIN is correct! Proceeding to the next screen.");
      context.pushReplacement(TransactionsListView());
    } else {
      // PIN is incorrect, show an error message
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incorrect PIN. Please try again.')));
    }
  }
}
