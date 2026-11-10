import '../../../../core/storage/mock_json_store.dart';
import '../repository/report_repository.dart';
import '../request-model/report_request_model.dart';

/// 将举报保存到本地文件，按目标类型区分业务来源。
class ReportMockRepository implements ReportRepository {
  const ReportMockRepository(this.store);
  final MockJsonStore store;
  @override
  Future<void> submit(ReportRequestModel request) => store.update(
    'report/reports',
    (json) => json as Map<String, dynamic>,
    (json) => {
      'items': [...json['items'] as List, request.toJson()],
    },
  );
}
