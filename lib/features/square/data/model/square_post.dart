class SquarePost {
  const SquarePost({
    required this.id,
    required this.author,
    required this.avatar,
    required this.text,
    required this.photos,
    this.isMine = false,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isPrivate = false,
    this.activityId,
    this.authorId,
    this.publishedAt,
    this.category = '运动',
    this.location = "深圳  |  18km  |  音乐",
  });

  final String id;
  final String author;
  final String avatar;
  final String text;
  final List<String> photos;
  final bool isMine;
  final int likeCount, commentCount;
  final bool isPrivate;
  final String? activityId;
  final String? authorId;
  final DateTime? publishedAt;
  final String location;
  final String category;
  factory SquarePost.fromJson(Map<String, dynamic> json) => SquarePost(
    id: json['id'] as String,
    author: json['author'] as String,
    avatar: json['avatar'] as String,
    text: json['text'] as String,
    photos: List<String>.unmodifiable(json['photos'] as List? ?? const []),
    isMine: json['isMine'] as bool? ?? false,
    likeCount: json['likeCount'] as int? ?? 0,
    commentCount: json['commentCount'] as int? ?? 0,
    isPrivate: json['isPrivate'] as bool? ?? false,
    activityId: json['activityId'] as String?,
    authorId: json['authorId'] as String?,
    publishedAt: DateTime.tryParse(json['publishedAt'] as String? ?? ''),
    location: json['location'] as String? ?? '',
    category: json['category'] as String? ?? '运动',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'author': author,
    'avatar': avatar,
    'text': text,
    'photos': photos,
    'isMine': isMine,
    'likeCount': likeCount,
    'commentCount': commentCount,
    'isPrivate': isPrivate,
    'activityId': activityId,
    if (authorId != null) 'authorId': authorId,
    if (publishedAt != null) 'publishedAt': publishedAt!.toIso8601String(),
    'location': location,
    'category': category,
  };
}
