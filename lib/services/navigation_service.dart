import 'package:flutter/material.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Future<dynamic>? push(String routeName, {Object? arguments}) {
    if (navigatorKey.currentState != null) {
      return navigatorKey.currentState!.pushNamed(routeName, arguments: arguments);
    }
    return null;
  }

  static Future<dynamic>? pushReplacementNamed(String routeName, {Object? arguments}) {
    if (navigatorKey.currentState != null) {
      return navigatorKey.currentState!.pushReplacementNamed(routeName, arguments: arguments);
    }
    return null;
  }

  static void goBack() {
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.pop();
    }
  }
}
