import '../repository/user_detail_repository.dart';
import '../../../activity/data/mock/activity_invite_mock_repository.dart';
import '../../../../core/storage/mock_json_store.dart';
import '../../../activity/data/mock/activity_publication_mock_repository.dart';
import '../../../home/data/model/home_category_model.dart';
import '../../../activity/data/model/home_activity_model.dart';
import '../model/home_companion_model.dart';
import '../model/user_detail.dart';

class UserDetailMockRepository implements UserDetailRepository {
  const UserDetailMockRepository(this.store);

  final MockJsonStore store;

  static Map<String, dynamic> _object(Object? value) =>
      value as Map<String, dynamic>;

  /// 根据用户 ID 读取资料、活动及邀约状态。
  @override
  Future<UserDetail?> load(String id) async {
    final catalog = await store.seed('home/catalog', _object);
    final account = await store.read('user/account', _object);
    final profile = _object(account['profile']);
    final isSelf = id == profile['id'];
    final entry = isSelf
        ? {
            ...profile,
            'photos': [profile['avatar']],
            'heightCm': 0,
            'weightKg': 0,
            'age': profile['age'] ?? 0,
            'categoryIds': <String>[],
          }
        : (catalog['companions'] as List)
              .cast<Map<String, dynamic>>()
              .where((item) => item['id'] == id)
              .firstOrNull;
    if (entry == null) return null;

    final invites = await ActivityInviteMockRepository(store).invitedIds();
    return UserDetail(
      person: HomeCompanionModel.fromJson(entry),
      signature: entry['signature'] as String? ?? '',
      tags: List<String>.from(entry['tags'] as List? ?? const []),
      categories: (catalog['categories'] as List)
          .cast<Map<String, dynamic>>()
          .map(HomeCategoryModel.fromJson)
          .toList(),
      activities:
          [
                ...await ActivityPublicationMockRepository(store).load(),
                ...(catalog['activities'] as List).cast<Map<String, dynamic>>(),
              ]
              .where((item) => item['ownerId'] == id)
              .map(HomeActivityModel.fromJson)
              .toList(),
      isSelf: isSelf,
      isInvited: invites.contains(id),
    );
  }
}
