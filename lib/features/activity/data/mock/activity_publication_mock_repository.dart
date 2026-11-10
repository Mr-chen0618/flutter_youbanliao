import '../repository/activity_publication_repository.dart';
import '../../../../core/storage/mock_json_store.dart';
import '../request-model/activity_draft.dart';

/// 在原始活动目录上补充当前账号创建的活动。
class ActivityPublicationMockRepository
    implements ActivityPublicationRepository {
  const ActivityPublicationMockRepository(this.store);

  final MockJsonStore store;
  static const _path = 'activity/published';

  @override
  Future<List<Map<String, dynamic>>> load() => store.read(_path, _decode);

  @override
  Future<void> publish(ActivityDraft draft, String ownerId) {
    final now = DateTime.now();
    return store.update(
      _path,
      _decode,
      (items) => {
        'items': [
          {
            ...draft.toJson(),
            'id': 'local-${now.microsecondsSinceEpoch}',
            'ownerId': ownerId,
            'time': now.toIso8601String(),
            'image': draft.photos.firstOrNull ?? '',
            'status': 'recruiting',
          },
          ...items,
        ],
      },
    );
  }

  List<Map<String, dynamic>> _decode(Object? json) =>
      ((json as Map<String, dynamic>)['items'] as List? ?? const [])
          .cast<Map<String, dynamic>>();
}
