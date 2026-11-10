import '../repository/my_activity_repository.dart';
import '../../../../core/storage/mock_json_store.dart';
import '../enum/activity_status.dart';
import '../model/my_activity.dart';
import 'activity_publication_mock_repository.dart';

/// 读取发布和参加的组队列表。
class MyActivityMockRepository implements MyActivityRepository {
  const MyActivityMockRepository(this.store);

  final MockJsonStore store;

  @override
  Future<List<MyActivity>> load({Set<String> joinedIds = const {}}) async {
    final accountId = await store.read(
      'user/account',
      (value) => ((value as Map)['profile'] as Map)['id'] as String,
    );
    final catalog = await store.seed(
      'home/catalog',
      (json) => (json as Map<String, dynamic>)['activities'] as List,
    );
    final records = await store.seed(
      'activity/my_activities',
      (json) => json as List,
    );
    final published = await ActivityPublicationMockRepository(store).load();
    return [
          for (final item in published)
            if (item['ownerId'] == accountId || joinedIds.contains(item['id']))
              {...item, 'cover': item['image'], 'joined': false},
          if (accountId == 'U001') ...records,
          for (final item in catalog.cast<Map<String, dynamic>>())
            if (joinedIds.contains(item['id']) &&
                !records.any((record) => (record as Map)['id'] == item['id']))
              {...item, 'cover': item['image'], 'joined': true},
        ]
        .cast<Map<String, dynamic>>()
        .map(
          (entry) => (
            id: entry['id'] as String,
            title: entry['title'] as String,
            cover: entry['cover'] as String,
            status:
                ActivityStatus.values.asNameMap()[entry['status']] ??
                ActivityStatus.unknown,
            category: entry['category'] as String,
            joined:
                (entry['joined'] as bool) || joinedIds.contains(entry['id']),
            time: entry['time'] as String,
            location: entry['location'] as String,
            description: entry['description'] as String,
          ),
        )
        .toList(growable: false);
  }
}
