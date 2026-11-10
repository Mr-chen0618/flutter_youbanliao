/// 对聊天或动态提交的举报信息。
class ReportRequestModel {
  const ReportRequestModel({
    required this.targetId,
    required this.targetType,
    required this.reason,
    required this.description,
    this.photos = const [],
  });
  final String targetId, targetType, reason, description;
  final List<String> photos;
  Map<String, dynamic> toJson() => {
    'targetId': targetId,
    'targetType': targetType,
    'reason': reason,
    'description': description,
    'photos': photos,
    'submittedAt': DateTime.now().toIso8601String(),
  };
}
