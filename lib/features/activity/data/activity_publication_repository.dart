import 'mock/activity_publication_mock_repository.dart';

export 'request-model/activity_draft.dart';
export 'mock/activity_publication_mock_repository.dart';

// 兼容原有构造入口。
typedef ActivityPublicationRepository = ActivityPublicationMockRepository;
