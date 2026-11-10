import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/logger/app_logger.dart';

class AppNavigator {
  AppNavigator._();

  static final Set<String> _pushingRoutes = <String>{};

  static Future<T?> push<T>(
    BuildContext context, {
    required Widget page,
    Object? arguments,
    String? name,
  }) async {
    final routeName = name ?? page.runtimeType.toString();

    if (RouteObserverService.contains(routeName) ||
        _pushingRoutes.contains(routeName)) {
      AppLogger.info('$routeName 已在栈中或正在跳转，忽略重复请求');
      return null;
    }

    _pushingRoutes.add(routeName);
    try {
      return Navigator.of(context, rootNavigator: false).push<T>(
        AppPageRoute<T>(
          builder: (_) => page,
          settings: RouteSettings(name: routeName, arguments: arguments),
        ),
      );
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pushingRoutes.remove(routeName);
      });
    }
  }

  static Future<T?> pushAndRemoveUntil<T>(
    BuildContext context, {
    required Widget page,
    Object? arguments,
    RoutePredicate? predicate,
    String? name,
  }) {
    final routeName = name ?? page.runtimeType.toString();
    return Navigator.of(context, rootNavigator: false).pushAndRemoveUntil<T>(
      AppPageRoute<T>(
        builder: (_) => page,
        settings: RouteSettings(name: routeName, arguments: arguments),
      ),
      predicate ?? (_) => false,
    );
  }

  static Future<T?> pushReplacement<T, TO>(
    BuildContext context, {
    required Widget page,
    Object? arguments,
    String? name,
    TO? result,
  }) {
    final routeName = name ?? page.runtimeType.toString();
    return Navigator.of(context, rootNavigator: false).pushReplacement<T, TO>(
      AppPageRoute<T>(
        builder: (_) => page,
        settings: RouteSettings(name: routeName, arguments: arguments),
      ),
      result: result,
    );
  }

  static Future<T?> pushTransparent<T>(
    BuildContext context, {
    required Widget page,
    Color barrierColor = Colors.black54,
    Duration duration = const Duration(milliseconds: 200),
    bool dismissible = true,
  }) {
    return Navigator.of(context, rootNavigator: false).push<T>(
      PageRouteBuilder<T>(
        opaque: false,
        barrierColor: barrierColor,
        barrierDismissible: dismissible,
        transitionDuration: duration,
        reverseTransitionDuration: duration,
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  static void popTimes(BuildContext context, {int count = 1}) {
    if (count <= 0) return;

    var popped = 0;
    Navigator.of(context, rootNavigator: false).popUntil((route) {
      if (popped < count && route.isFirst == false) {
        popped++;
        return false;
      }
      return true;
    });
  }

  static void getArguments<T>(
    BuildContext context, {
    required ValueChanged<T?> onChanged,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      onChanged(args is T ? args : null);
    });
  }

  static Future<T?> pushNamed<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) async {
    if (RouteObserverService.contains(routeName) ||
        _pushingRoutes.contains(routeName)) {
      AppLogger.info('$routeName 已在栈中或正在跳转，忽略重复请求');
      return null;
    }

    _pushingRoutes.add(routeName);

    try {
      return Navigator.of(
        context,
        rootNavigator: false,
      ).pushNamed<T>(routeName, arguments: arguments);
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pushingRoutes.remove(routeName);
      });
    }
  }

  static Future<T?> pushReplacementNamed<T, TO>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    TO? result,
  }) {
    return Navigator.of(
      context,
      rootNavigator: false,
    ).pushReplacementNamed<T, TO>(
      routeName,
      arguments: arguments,
      result: result,
    );
  }

  static Future<T?> pushNamedAndRemoveUntil<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    RoutePredicate? predicate,
  }) {
    return Navigator.of(
      context,
      rootNavigator: false,
    ).pushNamedAndRemoveUntil<T>(
      routeName,
      predicate ?? (_) => false,
      arguments: arguments,
    );
  }
}

class AppPageRoute<T> extends MaterialPageRoute<T> {
  AppPageRoute({required super.builder, super.settings});

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (!Platform.isAndroid) {
      return Theme.of(context).pageTransitionsTheme.buildTransitions<T>(
        this,
        context,
        animation,
        secondaryAnimation,
        child,
      );
    }

    final tween = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).chain(CurveTween(curve: Curves.ease));

    return SlideTransition(position: animation.drive(tween), child: child);
  }
}

class RouteObserverService extends NavigatorObserver {
  static final List<String> pageStack = <String>[];

  bool _isPage(Route<dynamic> route) => route is PageRoute<dynamic>;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_isPage(route)) {
      final name = route.settings.name;
      if (name != null) pageStack.add(name);
      AppLogger.info('stack push: $name => $pageStack');
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_isPage(route) && pageStack.isNotEmpty) {
      pageStack.removeLast();
      AppLogger.info('stack pop => $pageStack');
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_isPage(route)) {
      pageStack.remove(route.settings.name);
      AppLogger.info('stack remove: ${route.settings.name} => $pageStack');
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null && _isPage(oldRoute) && pageStack.isNotEmpty) {
      pageStack.removeLast();
    }

    if (newRoute != null && _isPage(newRoute)) {
      final name = newRoute.settings.name;
      if (name != null) pageStack.add(name);
    }
    AppLogger.info('stack replace => $pageStack');
  }

  static bool contains(String name) => pageStack.contains(name);
}
