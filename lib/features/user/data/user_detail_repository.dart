import 'mock/user_detail_mock_repository.dart';

export 'model/user_detail.dart';
export 'mock/user_detail_mock_repository.dart';

// 兼容原有构造入口。
typedef UserDetailRepository = UserDetailMockRepository;
