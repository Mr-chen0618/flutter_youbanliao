/// Named routes used by the application router.
class RouteNames {
  const RouteNames._();

  static const String companionList = '/companions';
  static String activityDetail(String id) => '/activity/$id';
  static String userDetail(String id) => '/users/$id';
  static String chat(String id) => '/chat/$id';

  static const String example = '/example';
}
