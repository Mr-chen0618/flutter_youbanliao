import 'dart:convert';
import 'dart:io';
import 'package:flutter_app_framework/core/storage/mock_json_store.dart';
import 'package:flutter_app_framework/features/square/data/model/square_comment.dart';
import 'package:flutter_app_framework/features/square/data/square_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('legacy comments preserve text without inventing identity or time', () {
    final state = SquareState.fromJson({
      'posts': [],
      'comments': {
        'post': ['旧评论'],
      },
    });
    final comment = state.comments['post']!.single;
    expect(comment.text, '旧评论');
    expect(comment.authorId, isEmpty);
    expect(comment.createdAt, isNull);
    expect(comment.authorName, '历史用户');
    expect(
      SquareState.fromJson(
        jsonDecode(jsonEncode(state.toJson())) as Map<String, dynamic>,
      ).comments['post']!.single.text,
      '旧评论',
    );
  });
  test(
    'typed comment identity and time survive new repository and store',
    () async {
      final directory = await Directory.systemTemp.createTemp('typed_comment_');
      addTearDown(() => directory.delete(recursive: true));
      final repo = SquareMockRepository(
        MockJsonStore(directory: () async => directory),
      );
      final feed = await repo.load();
      final id = feed.posts.first.id;
      final time = DateTime(2026, 11, 9, 12, 34);
      await repo.save(
        feed.copyWith(
          comments: {
            id: [
              SquareComment(
                text: '一起参加',
                authorId: 'account-a',
                authorName: '小明',
                authorAvatar: 'assets/mock/media/IMG025.jpg',
                createdAt: time,
              ),
              const SquareComment.legacy('旧评论'),
            ],
          },
        ),
      );
      final restored = await SquareMockRepository(
        MockJsonStore(directory: () async => directory),
      ).load();
      final comments = restored.comments[id]!;
      expect(comments, hasLength(2));
      expect(comments.first.text, '一起参加');
      expect(comments.first.authorId, 'account-a');
      expect(comments.first.authorName, '小明');
      expect(comments.first.authorAvatar, 'assets/mock/media/IMG025.jpg');
      expect(comments.first.createdAt, time);
      expect(comments.last.createdAt, isNull);
    },
  );
}
