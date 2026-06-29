import 'package:flutter/material.dart';

extension NavigationExtension on BuildContext {
  Future<T?> push<T>(Widget page) {
    return Navigator.of(this).push(MaterialPageRoute(builder: (_) => page));
  }

  Future<T?> pushNamed<T>(String name, {Object? arguments}) {
    return Navigator.of(this).pushNamed(name, arguments: arguments);
  }

  Future<T?> pushReplacement<T, TO>(Widget page) {
    return Navigator.of(this).pushReplacement(MaterialPageRoute(builder: (_) => page));
  }

  Future<T?> pushAndRemoveUntil<T>(Widget page) {
    return Navigator.of(this).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => page), (route) => false);
  }

  Future<T?> pushWithTag<T>(Widget page, String tag) {
    return Navigator.of(this).push(
      MaterialPageRoute(
        builder: (_) => page,
        settings: RouteSettings(name: tag),
      ),
    );
  }

  Future<T?> pushReplacementWithTag<T, TO>(Widget page, String tag) {
    return Navigator.of(this).pushReplacement(
      MaterialPageRoute(
        builder: (_) => page,
        settings: RouteSettings(name: tag),
      ),
    );
  }

  void popUntilNotTagged(String tag) {
    Navigator.of(this).popUntil((route) => route.settings.name != tag);
  }

  /// Pops the widgets on screen
  void pop<T extends Object?>({T? result, int? count}) {
    final navigator = Navigator.of(this);
    if (count != null && count > 1) {
      for (var i = 0; i < count; i++) {
        if (navigator.canPop()) {
          navigator.pop(result);
        } else {
          break;
        }
      }
    } else {
      if (navigator.canPop()) {
        navigator.pop(result);
      }
    }
  }

  void popOrNavigateTo(Widget fallbackPage) {
    final navigator = Navigator.of(this);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacement(MaterialPageRoute(builder: (_) => fallbackPage));
    }
  }
}
