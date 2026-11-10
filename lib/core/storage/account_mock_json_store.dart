import 'mock_json_store.dart';

/// 实例终生绑定账号；退出后的延迟写不会落到另一个账号目录。
class AccountMockJsonStore extends MockJsonStore {
  AccountMockJsonStore(this.base, this.accountId);
  final MockJsonStore base;
  final String accountId;
  final _initializing = <String, Future<void>>{};
  static const privatePaths = [
    'user/account',
    'messages/inbox',
    'square/feed',
    'activity/participation',
    'home/invites',
    'report/reports',
  ];
  String _key(String path) =>
      privatePaths.contains(path) ? 'accounts/$accountId/$path' : path;
  Future<void> _checkActive() async {
    if (await base.exists('accounts/$accountId/deleted')) {
      throw StateError('账号已注销');
    }
  }

  Future<void> _ensure(String path) async {
    try {
      await _initializing.putIfAbsent(path, () => _initializePath(path));
    } catch (_) {
      _initializing.remove(path);
      rethrow;
    }
  }

  Future<void> _initializePath(String path) async {
    final key = _key(path);
    if (key == path || await base.exists(key)) return;
    final json = await base.seed(
      path,
      (value) => Map<String, dynamic>.from(value as Map),
    );
    // 打包动态是公共样本，归属由当前账号决定，不将U001当作所有人的本人。
    if (path == 'square/feed') {
      json['posts'] = (json['posts'] as List)
          .map(
            (post) => {
              ...Map<String, dynamic>.from(post as Map),
              'isMine': post['authorId'] == accountId,
            },
          )
          .toList();
    }
    if (accountId != 'U001') {
      switch (path) {
        case 'messages/inbox':
          json['notices'] = {};
          json['noticeUnread'] = {};
          json['threads'] = [];
          json['blocked'] = {};
          json['reports'] = [];
          json['readNotices'] = [];
        case 'square/feed':
          json['likes'] = [];
          json['following'] = [];
          json['comments'] = {};
        case 'activity/participation':
          json['joinedIds'] = [];
          json['followedIds'] = [];
        case 'home/invites':
          json['ids'] = [];
          json['drafts'] = {};
        case 'report/reports':
          json['items'] = [];
      }
    }
    await base.initialize(key, json);
  }

  @override
  Future<T> seed<T>(String path, T Function(Object?) decode) =>
      base.seed(path, decode);
  @override
  Future<T> read<T>(String path, T Function(Object?) decode) async {
    await _checkActive();
    await _ensure(path);
    return base.read(_key(path), decode);
  }

  @override
  Future<void> write(String path, Map<String, dynamic> data) async {
    await _checkActive();
    await _ensure(path);
    await base.write(_key(path), data);
  }

  @override
  Future<void> update<T>(
    String path,
    T Function(Object?) decode,
    Map<String, dynamic> Function(T) change,
  ) async {
    await _checkActive();
    await _ensure(path);
    await base.update(_key(path), decode, change);
  }
}
