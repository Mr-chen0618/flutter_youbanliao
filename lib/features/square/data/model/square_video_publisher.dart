/// 视频模拟发布者，来源为公共用户目录，不伪造认证结论。
class SquareVideoPublisher {
  const SquareVideoPublisher({
    required this.id,
    required this.name,
    required this.avatar,
    required this.signature,
  });
  final String id, name, avatar, signature;
  factory SquareVideoPublisher.fromJson(Map<String, dynamic> json) =>
      SquareVideoPublisher(
        id: json['id'] as String,
        name: json['name'] as String,
        avatar: json['avatar'] as String,
        signature: json['signature'] as String? ?? '',
      );
}
