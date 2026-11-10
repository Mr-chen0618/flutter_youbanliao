import 'package:flutter/material.dart';

import '../../features/activity/presentation/pages/activity_detail_page.dart';
import '../../features/messages/presentation/pages/chat_page.dart';
import '../../features/user/presentation/pages/user_detail_page.dart';
import '../../features/example/presentation/pages/example_page.dart';
import '../../features/home/presentation/pages/companion_list_page.dart';
import '../../features/home/presentation/providers/companion_list_provider.dart';
import 'app_navigator.dart';
import 'route_names.dart';

class AppRouter {
  const AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final name = settings.name ?? '';
    final id = settings.arguments;
    if (id is String && id.isNotEmpty) {
      if (name == RouteNames.activityDetail(id)) {
        return _pageRoute(settings, ActivityDetailPage(activityId: id));
      }
      if (name == RouteNames.userDetail(id)) {
        return _pageRoute(settings, UserDetailPage(userId: id));
      }
      if (name == RouteNames.chat(id)) {
        return _pageRoute(settings, ChatPage(threadId: id));
      }
    }
    switch (settings.name) {
      case RouteNames.companionList:
        final arguments = settings.arguments;
        return _pageRoute(
          settings,
          CompanionListPage(
            arguments: arguments is CompanionListArguments
                ? arguments
                : (city: '深圳', categoryId: 'outdoors'),
          ),
        );
      case RouteNames.example:
        return _pageRoute(settings, const ExamplePage());
      default:
        return _pageRoute(settings, const ExamplePage());
    }
  }

  static PageRoute<T> _pageRoute<T>(RouteSettings settings, Widget page) {
    return AppPageRoute<T>(builder: (_) => page, settings: settings);
  }
}
