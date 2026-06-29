import 'package:flutter/material.dart';
import 'package:iq_test/extensions/context_extensions.dart';
import 'package:iconsax/iconsax.dart';

class CustomPinScreen extends StatefulWidget {
  final Function(String value)? onPinComplete;
  final Function()? onPhoneAuthComplete;
  final String? title;
  final String? description;
  final bool? canPop;
  final int? pinLength;

  final bool? showActionBtn;
  const CustomPinScreen({
    super.key,
    this.onPinComplete,
    this.onPhoneAuthComplete,
    this.title,
    this.description,
    this.canPop,
    // button
    this.showActionBtn,
    this.pinLength,
  });

  @override
  State<CustomPinScreen> createState() => _CustomPinScreenState();
}

class _CustomPinScreenState extends State<CustomPinScreen> {
  // Store the PIN digits as a list of strings.
  List<String> pin = [];
  String pinDigits() => pin.join('');

  // Called when a numeric button is pressed.
  void _onKeyPressed(String value) {
    // add new pin string to list
    if (pin.length < (widget.pinLength ?? 6)) {
      setState(() {
        pin.add(value);
      });
      if ((pin.length) == (widget.pinLength ?? 6)) widget.onPinComplete?.call(pinDigits());
    }
  }

  // Called when the delete (x) button is pressed.
  void _onDelete() {
    if (pin.isNotEmpty) {
      setState(() {
        pin.removeLast();
      });
    }
  }

  // Build the row of six circles representing the PIN digits.
  Widget _buildPinCircles() {
    List<Widget> circles = [];
    for (int i = 0; i < (widget.pinLength ?? 6); i++) {
      bool filled = i < pin.length;
      circles.add(
        AnimatedContainer(
          duration: Duration(milliseconds: 150),
          curve: Curves.easeIn,
          margin: EdgeInsets.symmetric(horizontal: 8.0),
          width: context.isSmallPhone ? 14 : 16,
          height: context.isSmallPhone ? 14 : 16,
          decoration: BoxDecoration(shape: BoxShape.circle, color: filled ? Colors.green : Colors.grey[300]),
        ),
      );
    }
    return Row(mainAxisAlignment: MainAxisAlignment.center, spacing: 10, children: circles);
  }

  // Build an individual keypad button.
  Widget _buildKeypadButton(String? label, {required VoidCallback onPressed, Widget? icon, Color? btnColor}) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.all(context.isSmallPhone ? 5.0 : 8.0),
        child: GestureDetector(
          onTap: () {
            onPressed.call();
          },
          child: Container(
            height: 80,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: btnColor ?? Color.fromRGBO(251, 251, 252, 1), shape: BoxShape.circle),
            child: icon ?? Text(label ?? '', style: TextStyle(fontSize: 24)),
          ),
        ),
      ),
    );
  }

  // Build the custom keypad layout.
  Widget _buildKeypad() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // First row: 1, 2, 3
        Row(
          children: [
            _buildKeypadButton('1', onPressed: () => _onKeyPressed('1')),
            _buildKeypadButton('2', onPressed: () => _onKeyPressed('2')),
            _buildKeypadButton('3', onPressed: () => _onKeyPressed('3')),
          ],
        ),
        // Second row: 4, 5, 6
        Row(
          children: [
            _buildKeypadButton('4', onPressed: () => _onKeyPressed('4')),
            _buildKeypadButton('5', onPressed: () => _onKeyPressed('5')),
            _buildKeypadButton('6', onPressed: () => _onKeyPressed('6')),
          ],
        ),
        // Third row: 7, 8, 9
        Row(
          children: [
            _buildKeypadButton('7', onPressed: () => _onKeyPressed('7')),
            _buildKeypadButton('8', onPressed: () => _onKeyPressed('8')),
            _buildKeypadButton('9', onPressed: () => _onKeyPressed('9')),
          ],
        ),

        // Fourth row: Custom button, 0, and delete (x) button
        Row(
          children: [
            // if (widget.showActionBtn == true) _buildKeypadButton('C', icon: unlockIcon, onPressed: _onCustomButton),
            // if (widget.showActionBtn != true)
            //   _buildKeypadButton('', onPressed: () {}, btnColor: AppColors.greyTwo.withValues(alpha: 0.3)),
            // _buildKeypadButton('0', onPressed: () => _onKeyPressed('0')),
            _buildKeypadButton("x", icon: Icon(Iconsax.back_square), onPressed: _onDelete),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: widget.canPop == true ? Icon(Icons.arrow_back_ios) : null,
        automaticallyImplyLeading: widget.canPop == true ? true : false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 20,
                children: [
                  Text(
                    widget.title ?? "Passcode Required",
                    style: TextStyle(fontSize: context.isSmallPhone ? 22 : 24, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    widget.description ?? "Enter your 6-digit passcode to continue.",
                    style: TextStyle(color: Colors.grey, fontSize: context.isSmallPhone ? 12 : 14),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: context.screenHeight * 0.05),
                  // Display the PIN circles at the top.
                  _buildPinCircles(),
                  SizedBox(height: 40),
                ],
              ),
            ),
            // Display the custom keypad.
            _buildKeypad(),
          ],
        ),
      ),
    );
  }
}
