import 'square_post.dart';
import 'square_comment.dart';

class SquareState {
  const SquareState(
    this.posts, {
    this.likes = const {},
    this.following = const {},
    this.comments = const {},
    this.videoLiked = false,
    this.videoSaved = false,
  });
  final List<SquarePost> posts;
  final bool videoLiked;
  final bool videoSaved;
  final Set<String> likes;
  final Set<String> following;
  final Map<String, List<SquareComment>> comments;

  SquareState copyWith({
    List<SquarePost>? posts,
    bool? videoLiked,
    bool? videoSaved,
    Set<String>? likes,
    Set<String>? following,
    Map<String, List<SquareComment>>? comments,
  }) => SquareState(
    posts ?? this.posts,
    videoLiked: videoLiked ?? this.videoLiked,
    videoSaved: videoSaved ?? this.videoSaved,
    likes: likes ?? this.likes,
    following: following ?? this.following,
    comments: comments ?? this.comments,
  );
  factory SquareState.fromJson(Map<String, dynamic> json) => SquareState(
    List.unmodifiable(
      (json['posts'] as List).map(
        (item) => SquarePost.fromJson(item as Map<String, dynamic>),
      ),
    ),
    videoLiked: json['videoLiked'] as bool? ?? false,
    videoSaved: json['videoSaved'] as bool? ?? false,
    likes: Set.unmodifiable(
      List<String>.from(json['likes'] as List? ?? const []),
    ),
    following: Set.unmodifiable(
      List<String>.from(json['following'] as List? ?? const []),
    ),
    comments: Map.unmodifiable(
      (json['comments'] as Map? ?? const {}).map(
        (key, value) => MapEntry(
          key as String,
          List<SquareComment>.unmodifiable(
            (value as List).map(SquareComment.fromJson),
          ),
        ),
      ),
    ),
  );

  Map<String, dynamic> toJson() => {
    'videoLiked': videoLiked,
    'videoSaved': videoSaved,
    'posts': posts.map((post) => post.toJson()).toList(),
    'likes': likes.toList(),
    'following': following.toList(),
    'comments': comments.map(
      (key, values) =>
          MapEntry(key, values.map((comment) => comment.toJson()).toList()),
    ),
  };
}
