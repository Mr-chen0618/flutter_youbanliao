import 'dart:io';
import 'package:flutter_app_framework/features/square/data/model/square_comment.dart';

import 'package:flutter_app_framework/core/storage/mock_json_store.dart';
import 'package:flutter_app_framework/features/activity/data/activity_detail_repository.dart';
import 'package:flutter_app_framework/features/activity/data/activity_publication_repository.dart';
import 'package:flutter_app_framework/features/activity/data/my_activity_repository.dart';
import 'package:flutter_app_framework/features/home/data/mock/home_mock_server.dart';
import 'package:flutter_app_framework/features/home/data/request-model/home_invite_request_model.dart';
import 'package:flutter_app_framework/features/home/data/request-model/home_list_request_model.dart';
import 'package:flutter_app_framework/features/messages/data/messages_repository.dart';
import 'package:flutter_app_framework/features/square/data/square_repository.dart';
import 'package:flutter_app_framework/features/user/data/profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('业务快照写入后可由新仓库恢复', () async {
    final directory = await Directory.systemTemp.createTemp('companion_mock_');
    addTearDown(() => directory.delete(recursive: true));
    MockJsonStore openStore() =>
        MockJsonStore(directory: () async => directory);
    final store = openStore();

    final profiles = ProfileMockRepository(store);
    final user = await profiles.load();
    await profiles.save(
      user.copyWith(profile: user.profile.copyWith(name: '本地昵称')),
    );

    final messages = MessagesMockRepository(store);
    final inbox = await messages.load();
    final thread = inbox.threads.first;
    await messages.save(inbox.copyWith(blocked: {thread.id: thread}));

    final square = SquareMockRepository(store);
    final feed = await square.load();
    final id = feed.posts.first.id;
    await Future.wait([
      square.save(feed.copyWith(likes: {id})),
      square.save(
        feed.copyWith(
          likes: {id},
          videoLiked: true,
          videoSaved: true,
          comments: {
            id: [const SquareComment.legacy('本地评论')],
          },
        ),
      ),
    ]);

    final reopened = openStore();
    expect((await ProfileMockRepository(reopened).load()).profile.name, '本地昵称');
    expect(
      (await MessagesMockRepository(reopened).load()).blocked[thread.id]?.name,
      thread.name,
    );
    final restoredFeed = await SquareMockRepository(reopened).load();
    expect(restoredFeed.likes, contains(id));
    expect(restoredFeed.videoLiked, isTrue);
    expect(restoredFeed.videoSaved, isTrue);
    expect(SquareState.fromJson({'posts': []}).videoLiked, isFalse);
    expect(SquareState.fromJson({'posts': []}).videoSaved, isFalse);
    expect(restoredFeed.comments[id]?.map((comment) => comment.text), ['本地评论']);
  });

  test('广场旧关注迁移一次，用户和活动共用 ID 且取消后不复活', () async {
    final directory = await Directory.systemTemp.createTemp(
      'follow_migration_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final store = MockJsonStore(directory: () async => directory);
    final square = SquareMockRepository(store);
    final feed = await square.load();
    final post = feed.posts.firstWhere((post) => post.authorId != null);
    await square.save(feed.copyWith(following: {post.author}));
    final activities = ActivityDetailRepository(store);
    expect(await activities.followedIds(), contains(post.authorId));
    await activities.follow(post.authorId!, false);
    final reopened = ActivityDetailRepository(
      MockJsonStore(directory: () async => directory),
    );
    expect(await reopened.followedIds(), isNot(contains(post.authorId)));
    await reopened.follow(post.authorId!, true);
    expect(await activities.followedIds(), contains(post.authorId));
  });

  test('发布活动可从首页、详情和我的活动读取，邀约保留表单', () async {
    final directory = await Directory.systemTemp.createTemp('activity_forms_');
    addTearDown(() => directory.delete(recursive: true));
    final store = MockJsonStore(directory: () async => directory);
    final draft = ActivityDraft(
      title: '周末羽毛球',
      description: '球馆见',
      categoryId: 'sports',
      category: '羽毛球',
      eventTime: DateTime(2027, 1, 1, 12),
      location: '宝安体育馆',
    );
    await ActivityPublicationRepository(store).publish(draft, 'U001');
    final reopened = MockJsonStore(directory: () async => directory);
    final server = HomeMockServer(store: reopened, delay: Duration.zero);
    final home = await server.getHome(
      params: const HomeListRequestModel(city: '深圳'),
    );
    final published = home.activities.first;
    expect(published.title, draft.title);
    final detail = await ActivityDetailRepository(reopened).load(published.id);
    expect(detail?.eventTime, draft.eventTime);
    expect(detail?.isOwn, isTrue);
    expect(
      (await MyActivityRepository(reopened).load()).first.id,
      published.id,
    );

    await server.submitInvite(
      params: HomeInviteRequestModel(companionId: 'U002', draft: draft),
    );
    final invites = await reopened.read(
      'home/invites',
      (json) => json as Map<String, dynamic>,
    );
    expect(invites['ids'], contains('U002'));
    expect(invites['drafts']['U002']['title'], draft.title);
  });

  test('并发更新邀约保留每条记录', () async {
    final directory = await Directory.systemTemp.createTemp(
      'companion_invites_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final store = MockJsonStore(directory: () async => directory);
    List<String> decode(Object? json) =>
        List<String>.from((json as Map<String, dynamic>)['ids'] as List);

    await Future.wait([
      for (final id in ['U002', 'U003'])
        store.update(
          'home/invites',
          decode,
          (ids) => {
            'ids': [...ids, id],
          },
        ),
    ]);
    expect(await store.read('home/invites', decode), ['U002', 'U003']);
  });
}
