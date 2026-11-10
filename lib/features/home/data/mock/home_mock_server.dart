import '../../../activity/data/mock/activity_invite_mock_repository.dart';
import '../../../../core/storage/mock_json_store.dart';
import '../../../activity/data/activity_publication_repository.dart';
import '../enum/home_mock_scenario_enum.dart';
import '../model/home_model.dart';
import '../request-model/home_invite_request_model.dart';
import '../request-model/home_list_request_model.dart';
import '../server/home_server.dart';

/// 模拟首页请求，并从本地 JSON 恢复邀约状态。
class HomeMockServer implements HomeServer {
  HomeMockServer({
    MockJsonStore? store,
    this.scenario = HomeMockScenarioEnum.success,
    this.delay = const Duration(milliseconds: 500),
  }) : _store = store ?? MockJsonStore();

  final MockJsonStore _store;
  final HomeMockScenarioEnum scenario;
  final Duration delay;
  bool _hasFailed = false;

  @override
  Future<HomeModel> getHome({required HomeListRequestModel params}) async {
    await Future<void>.delayed(delay);
    if (scenario == HomeMockScenarioEnum.failOnce && !_hasFailed) {
      _hasFailed = true;
      throw StateError('Mock home request failed');
    }
    final catalog = await _store.seed(
      'home/catalog',
      (json) => HomeModel.fromJson(json as Map<String, dynamic>),
    );
    if (scenario == HomeMockScenarioEnum.empty || params.city != '深圳') {
      return HomeModel(categories: catalog.categories);
    }
    final invited = await ActivityInviteMockRepository(_store).invitedIds();
    final published = await ActivityPublicationRepository(_store).load();
    final viewerId = await _store.read(
      'user/account',
      (json) => ((json as Map)['profile'] as Map)['id'] as String,
    );
    return HomeModel(
      categories: catalog.categories,
      activities: [
        ...published.map(HomeActivityModel.fromJson),
        ...catalog.activities,
      ],
      companions: catalog.companions
          .where((companion) => companion.id != viewerId)
          .map(
            (companion) =>
                companion.copyWith(isInvited: invited.contains(companion.id)),
          )
          .toList(),
    );
  }

  @override
  Future<void> submitInvite({required HomeInviteRequestModel params}) async {
    await Future<void>.delayed(delay);
    await ActivityInviteMockRepository(_store).submit(params);
  }
}
