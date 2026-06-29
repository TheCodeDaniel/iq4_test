import 'package:flutter/material.dart';
import 'package:iq_test/widgets/custom_pin_screen.dart';

class PinLockView extends StatefulWidget {
  const PinLockView({super.key});

  @override
  State<PinLockView> createState() => _PinLockViewState();
}

class _PinLockViewState extends State<PinLockView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: SafeArea(child: CustomPinScreen()));
  }
}
