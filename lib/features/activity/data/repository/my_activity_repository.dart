import '../model/my_activity.dart';

abstract interface class MyActivityRepository {
  Future<List<MyActivity>> load({Set<String> joinedIds = const {}});
}
