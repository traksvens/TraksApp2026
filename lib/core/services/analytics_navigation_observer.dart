import 'package:flutter/material.dart';
import 'analytics_service.dart';

class AnalyticsNavigationObserver extends NavigatorObserver {
  static final Set<String> _trackedRoutes = {};

  static void resetTrackedRoutes() {
    _trackedRoutes.clear();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _trackRoute(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) {
      _trackRoute(previousRoute);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) {
      _trackRoute(newRoute);
    }
  }

  void _trackRoute(Route<dynamic> route) {
    final String? routeName = _getRouteName(route);
    if (routeName != null && !_trackedRoutes.contains(routeName)) {
      _trackedRoutes.add(routeName);
      AnalyticsHelper.trackPageView(
        routeName,
        screenClass: route.settings.name ?? route.toString(),
      );
    }
  }

  String? _getRouteName(Route<dynamic> route) {
    if (route.settings.name != null) {
      return route.settings.name;
    }

    if (route is MaterialPageRoute) {
      final widget = route.builder;
      return widget.toString().replaceAll('Widget:', '').trim();
    }

    return route.toString();
  }
}

class PageViewTracker {
  static void trackCurrentPage(String pageName) {
    AnalyticsHelper.trackPageView(pageName);
  }
}
