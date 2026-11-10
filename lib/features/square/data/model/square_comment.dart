/// 动态评论保留提交时身份快照；历史字符串不虚构作者或发布时间。
class SquareComment {
  const SquareComment({
    required this.text,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    this.createdAt,
  });
  const SquareComment.legacy(this.text)
    : authorId = '',
      authorName = '历史用户',
      authorAvatar = '',
      createdAt = null;
  final String text, authorId, authorName, authorAvatar;
  final DateTime? createdAt;
  factory SquareComment.fromJson(Object? json) {
    if (json is String) return SquareComment.legacy(json);
    final data = json as Map<String, dynamic>;
    return SquareComment(
      text: data['text'] as String,
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? '历史用户',
      authorAvatar: data['authorAvatar'] as String? ?? '',
      createdAt: DateTime.tryParse(data['createdAt'] as String? ?? ''),
    );
  }
  Map<String, dynamic> toJson() => {
    'text': text,
    'authorId': authorId,
    'authorName': authorName,
    'authorAvatar': authorAvatar,
    'createdAt': createdAt?.toIso8601String(),
  };
}
