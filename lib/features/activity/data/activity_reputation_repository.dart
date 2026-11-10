import 'mock/activity_reputation_mock_repository.dart';

export 'model/activity_reputation.dart';
export 'mock/activity_reputation_mock_repository.dart';

// 兼容原有构造入口。
typedef ActivityReputationRepository = ActivityReputationMockRepository;
