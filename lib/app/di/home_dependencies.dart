import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/mock_json_store.dart';

import '../../features/home/data/enum/home_mock_scenario_enum.dart';
import '../../features/home/data/mock/home_mock_server.dart';
import '../../features/home/data/server/home_server.dart';

final homeServerProvider = Provider<HomeServer>((ref) {
  const scenario = String.fromEnvironment('HOME_MOCK_SCENARIO');
  return HomeMockServer(
    store: ref.watch(mockJsonStoreProvider),
    scenario: HomeMockScenarioEnum.fromValue(scenario),
  );
});
