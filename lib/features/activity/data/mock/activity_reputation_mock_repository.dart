import '../../../../core/storage/mock_json_store.dart';
import '../repository/activity_reputation_repository.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../model/activity_reputation.dart';

/// 从打包的 JSON 读取活动信誉样本。
class ActivityReputationMockRepository implements ActivityReputationRepository {
  const ActivityReputationMockRepository([this.store]);
  final MockJsonStore? store;

  @override
  Future<ActivityReputation> load() async {
    if (store case final source?) {
      final id = await source.read(
        'user/account',
        (value) => ((value as Map)['profile'] as Map)['id'],
      );
      if (id != 'U001') {
        return (score: 100, records: const <ReputationRecord>[]);
      }
    }
    final raw = await rootBundle.loadString(
      'assets/mock/activity/reputation.json',
    );
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return (
      score: json['score'] as int,
      records: (json['records'] as List)
          .cast<Map<String, dynamic>>()
          .map(
            (entry) => (
              title: entry['title'] as String,
              date: entry['date'] as String,
              change: entry['change'] as int,
            ),
          )
          .toList(growable: false),
    );
  }
}
