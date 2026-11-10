import '../model/activity_reputation.dart';

abstract interface class ActivityReputationRepository {
  Future<ActivityReputation> load();
}
