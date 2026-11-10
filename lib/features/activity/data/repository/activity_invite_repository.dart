import '../request-model/activity_invite_request_model.dart';

/// 查询已有邀约并向目标搭子提交活动信息。
abstract interface class ActivityInviteRepository {
  Future<Set<String>> invitedIds();
  Future<void> submit(ActivityInviteRequestModel request);
}
