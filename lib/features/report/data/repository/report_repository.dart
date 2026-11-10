import '../request-model/report_request_model.dart';

abstract interface class ReportRepository {
  Future<void> submit(ReportRequestModel request);
}
