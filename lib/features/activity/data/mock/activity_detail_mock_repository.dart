import '../repository/activity_detail_repository.dart';
import '../../../../core/storage/mock_json_store.dart';
import 'activity_publication_mock_repository.dart';
import '../model/activity_detail.dart';

/// 按 ID 查询目录并串行保存报名和关注。
class ActivityDetailMockRepository implements ActivityDetailRepository {
  const ActivityDetailMockRepository(this.store);

  final MockJsonStore store;
  static const _participation = 'activity/participation';

  static Map<String, dynamic> _object(Object? json) =>
      json as Map<String, dynamic>;

  static ActivityPublisher _publisher(Map<String, dynamic> json) => (
    id: json['id'] as String,
    name: json['name'] as String,
    avatar: json['avatar'] as String,
  );

  @override
  Future<ActivityDetail?> load(String id) async {
    final catalog = await store.seed('home/catalog', _object);
    final activities = [
      ...await ActivityPublicationMockRepository(store).load(),
      ...(catalog['activities'] as List).cast<Map<String, dynamic>>(),
    ];
    final activity = activities.where((item) => item['id'] == id).firstOrNull;
    if (activity == null) return null;
    final account = await store.read('user/account', _object);
    final viewer = _publisher(_object(account['profile']));
    final publishers = (catalog['companions'] as List)
        .cast<Map<String, dynamic>>()
        .map(_publisher);
    final ownerId = activity['ownerId'];
    final owner = ownerId == viewer.id
        ? viewer
        : publishers.where((person) => person.id == ownerId).firstOrNull;
    final state = await store.read(_participation, _object);
    return ActivityDetail(
      activity,
      publisher: owner,
      viewer: viewer,
      viewerGender: (account['profile'] as Map)['gender'] as String?,
      joined: (state['joinedIds'] as List).contains(id),
      followed: (await followedIds()).contains(ownerId),
    );
  }

  @override
  Future<Set<String>> joinedIds() => store.read(
    _participation,
    (json) => Set<String>.from(_object(json)['joinedIds'] as List),
  );

  @override
  Future<void> join(String id) async {
    final account = await store.read('user/account', _object);
    if (account['isSignedIn'] == false) throw StateError('请先登录');
    final activity = await load(id);
    if (activity == null) throw StateError('活动不存在');
    if (activity.joinBlockedReason case final reason?) throw StateError(reason);
    await store.update(_participation, _object, (json) {
      final ids = Set<String>.from(json['joinedIds'] as List);
      if (!ids.add(id)) throw StateError('已报名，请勿重复提交');
      return {...json, 'joinedIds': ids.toList()};
    });
  }

  @override
  Future<Set<String>> followedIds() async {
    // 旧版广场按昵称存储关注，仅迁移一次，之后所有入口共享用户 ID。
    final feed = await store.read('square/feed', _object);
    final names = Set<String>.from(feed['following'] as List? ?? const []);
    final posts = (feed['posts'] as List).cast<Map<String, dynamic>>();
    await store.update(_participation, _object, (json) {
      if (json['squareFollowingMigrated'] == true) return json;
      final ids = Set<String>.from(json['followedIds'] as List);
      for (final post in posts) {
        if (names.contains(post['author']) && post['authorId'] is String) {
          ids.add(post['authorId'] as String);
        }
      }
      return {
        ...json,
        'followedIds': ids.toList(),
        'squareFollowingMigrated': true,
      };
    });
    return store.read(
      _participation,
      (json) => Set<String>.from(_object(json)['followedIds'] as List),
    );
  }

  @override
  Future<void> follow(String id, bool value) async {
    await followedIds();
    await _set('followedIds', id, value);
  }

  Future<void> _set(String key, String id, bool value) =>
      store.update(_participation, _object, (json) {
        final ids = Set<String>.from(json[key] as List);
        if (value) {
          ids.add(id);
        } else {
          ids.remove(id);
        }
        return {...json, key: ids.toList()};
      });
}
