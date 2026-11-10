import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app_framework/core/storage/mock_json_store.dart';
import 'package:flutter_app_framework/features/activity/data/mock/activity_invite_mock_repository.dart';
import 'package:flutter_app_framework/features/activity/data/request-model/activity_invite_request_model.dart';
import 'package:flutter_app_framework/features/activity/data/request-model/activity_draft.dart';

Map<String, dynamic> object(Object? v) => Map<String, dynamic>.from(v as Map);

class _FaultStore extends MockJsonStore {
  _FaultStore(Directory dir) : super(directory: () async => dir);
  String? failPath;
  @override
  Future<void> update<T>(
    String path,
    T Function(Object?) decode,
    Map<String, dynamic> Function(T) change,
  ) {
    if (path == failPath) {
      failPath = null;
      return Future.error(StateError('写入失败'));
    }
    return super.update(path, decode, change);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final fault in [null, 'messages/inbox', 'home/invites']) {
    test(
      'invitation reaches stable peer exactly once across failure $fault and reopening',
      () async {
        final dir = await Directory.systemTemp.createTemp('invite_delivery_');
        addTearDown(() => dir.delete(recursive: true));
        final store = _FaultStore(dir);
        final catalog = await store.seed('home/catalog', object);
        final person = (catalog['companions'] as List)
            .cast<Map<String, dynamic>>()
            .first;
        final peer = person['id'] as String;
        final draft = ActivityDraft(
          title: '独立测试球局',
          description: '球馆见',
          categoryId: 'sports',
          category: '运动',
          eventTime: DateTime(2027, 2, 3, 15, 30),
          location: '深圳体育馆',
        );
        final request = ActivityInviteRequestModel(
          companionId: peer,
          draft: draft,
        );
        final repo = ActivityInviteMockRepository(store);
        store.failPath = fault;
        if (fault != null) {
          await expectLater(repo.submit(request), throwsStateError);
          expect(await repo.invitedIds(), isNot(contains(peer)));
        }
        await repo.submit(request);
        // 重建仓库和Store后重试同一请求，不能仅在内存去重。
        final reopened = MockJsonStore(directory: () async => dir);
        await ActivityInviteMockRepository(reopened).submit(request);
        expect(
          await ActivityInviteMockRepository(reopened).invitedIds(),
          contains(peer),
        );
        final json = await reopened.read('messages/inbox', object);
        final matching = (json['threads'] as List)
            .where((t) => t['peerId'] == peer)
            .toList();
        expect(matching, hasLength(1));
        final cards = (matching.single['entries'] as List)
            .where(
              (e) => e['kind'] == 'invitation' && e['content'] == draft.title,
            )
            .toList();
        expect(cards, hasLength(1));
        expect(cards.single['isMine'], isTrue);
        expect(cards.single['invitation']['description'], draft.description);
        expect(cards.single['invitation']['category'], draft.category);
        expect(cards.single['invitation']['meetingPoint'], draft.location);
        expect(cards.single['invitation']['time'], '15:30');
        expect((json['threads'] as List).first['peerId'], peer);
      },
    );
  }
}
