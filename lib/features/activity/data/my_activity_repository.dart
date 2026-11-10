import 'mock/my_activity_mock_repository.dart';

export 'enum/activity_status.dart';
export 'model/my_activity.dart';
export 'mock/my_activity_mock_repository.dart';

// 兼容原有构造入口。
typedef MyActivityRepository = MyActivityMockRepository;
