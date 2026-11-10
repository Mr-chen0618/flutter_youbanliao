import 'mock/activity_detail_mock_repository.dart';

export 'model/activity_detail.dart';
export 'mock/activity_detail_mock_repository.dart';

// 兼容原有构造入口。
typedef ActivityDetailRepository = ActivityDetailMockRepository;
