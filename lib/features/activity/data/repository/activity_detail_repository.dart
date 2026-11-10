import '../model/activity_detail.dart';

abstract interface class ActivityDetailRepository {
  Future<ActivityDetail?> load(String id);
  Future<Set<String>> joinedIds();
  Future<Set<String>> followedIds();
  Future<void> join(String id);
  Future<void> follow(String id, bool value);
}
