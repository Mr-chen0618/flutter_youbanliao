import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/mock_json_store.dart';
import '../../../../shared/widgets/feedback/app_toast.dart';
import '../../data/square_repository.dart';
import '../../data/model/square_comment.dart';
import '../../../user/data/model/member_profile.dart';

export '../../data/square_repository.dart' show SquareState;

final squareRepositoryProvider = Provider<SquareRepository>(
  (ref) => SquareMockRepository(ref.watch(mockJsonStoreProvider)),
);
final squareInitialProvider = FutureProvider<SquareState>(
  (ref) => ref.watch(squareRepositoryProvider).load(),
);
final squareProvider = NotifierProvider<SquareNotifier, SquareState>(
  SquareNotifier.new,
);

class SquareNotifier extends Notifier<SquareState> {
  final _random = Random.secure();

  @override
  SquareState build() {
    final repository = ref.watch(squareRepositoryProvider);
    listenSelf((previous, next) {
      if (previous != null) {
        ref
            .read(mockWritesProvider.notifier)
            .save('square', () => repository.save(next));
      }
    });
    return ref.watch(squareInitialProvider).requireValue;
  }

  /// 从同一文件队列读取最新快照，失败保留当前交互状态。
  Future<void> refresh() async {
    try {
      final repository = ref.read(squareRepositoryProvider);
      final snapshot = state;
      final next = await repository.load();
      if (ref.mounted && identical(state, snapshot)) state = next;
    } catch (error) {
      AppToast.showError(error);
    }
  }

  /// 将视频互动同步到动态模块的磁盘快照。
  void toggleVideoLike() =>
      state = state.copyWith(videoLiked: !state.videoLiked);
  void toggleVideoSave() =>
      state = state.copyWith(videoSaved: !state.videoSaved);

  void toggleLike(String id) =>
      state = state.copyWith(likes: _toggle(state.likes, id));
  void toggleFollow(String author) =>
      state = state.copyWith(following: _toggle(state.following, author));

  Set<String> _toggle(Set<String> values, String value) => Set.unmodifiable(
    values.contains(value) ? ({...values}..remove(value)) : {...values, value},
  );

  void comment(String id, String text, {MemberProfile? profile}) {
    if (text.trim().isEmpty) return;
    state = state.copyWith(
      comments: Map<String, List<SquareComment>>.unmodifiable({
        ...state.comments,
        id: List<SquareComment>.unmodifiable([
          ...?state.comments[id],
          SquareComment(
            text: text.trim(),
            authorId: profile?.id ?? '',
            authorName: profile?.name ?? '历史用户',
            authorAvatar: profile?.avatar ?? '',
            createdAt: DateTime.now(),
          ),
        ]),
      }),
    );
  }

  void publish(
    String text,
    List<String> photos,
    bool isPrivate, {
    String? authorId,
    required String author,
    required String avatar,
    required String location,
  }) {
    if (text.trim().isEmpty) return;
    final now = DateTime.now();
    final post = SquarePost(
      publishedAt: now,
      id: 'mine-${now.microsecondsSinceEpoch}-${_random.nextInt(1 << 32)}',
      authorId: authorId,
      author: author,
      avatar: avatar,
      text: text.trim(),
      photos: List.unmodifiable(photos),
      isMine: true,
      isPrivate: isPrivate,
      location: location,
    );
    state = state.copyWith(posts: List.unmodifiable([post, ...state.posts]));
  }

  void delete(String id) => state = state.copyWith(
    posts: List.unmodifiable(
      state.posts.where((post) => post.id != id || !post.isMine),
    ),
  );
}
