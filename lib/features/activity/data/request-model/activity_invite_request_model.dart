import 'activity_draft.dart';

class ActivityInviteRequestModel {
  const ActivityInviteRequestModel({required this.companionId, this.draft});

  final String companionId;
  final ActivityDraft? draft;

  Map<String, dynamic> toJson() => {
    'companionId': companionId,
    if (draft != null) 'activity': draft!.toJson(),
  };
}
