import 'package:flutter_app_framework/features/square/data/model/square_post.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('social count bases roundtrip and older snapshots default to zero', () {
    const post = SquarePost(
      id: 'p',
      author: 'a',
      avatar: '',
      text: 't',
      photos: [],
      likeCount: 12,
      commentCount: 7,
    );
    final restored = SquarePost.fromJson(post.toJson());
    expect(restored.likeCount, 12);
    expect(restored.commentCount, 7);
    final old = post.toJson()
      ..remove('likeCount')
      ..remove('commentCount');
    expect(SquarePost.fromJson(old).likeCount, 0);
    expect(SquarePost.fromJson(old).commentCount, 0);
  });
}
