import 'video_show.dart';

/// 增长状态字段在数据边界解析，缺少旧字段按未完成处理。
class GrowthState {
  const GrowthState({
    this.checks = const [],
    this.video,
    this.realPerson = false,
    this.identityPending = false,
    this.realPersonVerified = false,
    this.identityVerified = false,
    this.days = const {},
    this.claims = const {},
  });
  final List<String> checks;
  final VideoShow? video;
  final bool realPerson, identityPending;

  /// 可信审核结果；本地提交不设置已认证标记。
  final bool realPersonVerified, identityVerified;
  final Map<String, String?> days, claims;
  factory GrowthState.fromJson(Map<String, dynamic> json) => GrowthState(
    checks: List<String>.from(json['checks'] as List? ?? []),
    video: json['video'] == null ? null : VideoShow.fromJson(json['video']!),
    realPerson: json['realPerson'] == true,
    identityPending: json['identityPending'] == true,
    realPersonVerified: json['realPersonVerified'] == true,
    identityVerified: json['identityVerified'] == true,
    days: {
      for (final key in ['chat', 'discover', 'publish'])
        key: json['${key}Day'] as String?,
    },
    claims: {
      for (final key in ['chat', 'discover', 'publish'])
        key: json['${key}Claim'] as String?,
    },
  );
}
