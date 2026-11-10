import '../request-model/activity_draft.dart';

abstract interface class ActivityPublicationRepository {
  Future<List<Map<String, dynamic>>> load();
  Future<void> publish(ActivityDraft draft, String ownerId);
}
