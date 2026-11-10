/// 对用户、活动、聊天或动态提交的举报信息与目标快照。
class ReportRequestModel {
  const ReportRequestModel({
    required this.targetId,
    required this.targetType,
    required this.reason,
    required this.description,
    this.photos = const [],
    this.targetName,
    this.targetAvatar,
    this.targetSummary,
  });
  final String targetId, targetType, reason, description;
  final List<String> photos;
  final String? targetName, targetAvatar, targetSummary;
  Map<String, dynamic> toJson() => {
    'targetId': targetId,
    'targetType': targetType,
    if (targetName != null) 'targetName': targetName,
    if (targetAvatar != null) 'targetAvatar': targetAvatar,
    if (targetSummary != null) 'targetSummary': targetSummary,
    'reason': reason,
    'description': description,
    'photos': photos,
    'submittedAt': DateTime.now().toIso8601String(),
  };
}
