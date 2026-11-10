import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/mock_json_store.dart';
import '../../data/mock/report_mock_repository.dart';
import '../../data/repository/report_repository.dart';

final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => ReportMockRepository(ref.watch(mockJsonStoreProvider)),
);
