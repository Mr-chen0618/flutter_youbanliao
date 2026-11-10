import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app_framework/core/storage/mock_json_store.dart';
import 'package:flutter_app_framework/features/activity/data/activity_detail_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'join enforces gender, own event, duplicate and legacy unrestricted data at repository boundary',
    () async {
      final directory = await Directory.systemTemp.createTemp('join_guards_');
      addTearDown(() => directory.delete(recursive: true));
      final store = MockJsonStore(directory: () async => directory);
      final account = await store.read(
        'user/account',
        (v) => Map<String, dynamic>.from(v as Map),
      );
      final viewer = account['profile'] as Map;
      viewer['gender'] = '女';
      account['isSignedIn'] = true;
      await store.write('user/account', account);
      Map<String, dynamic> event(String id, String? gender, String owner) => {
        'id': id,
        'title': id,
        'description': '隔离活动',
        'image': '',
        'time': '2026-11-09',
        'location': '深圳',
        'ownerId': owner,
        'gender': ?gender,
      };
      await store.write('activity/published', {
        'items': [
          event('male', '仅男生', 'U002'),
          event('female', '仅女生', 'U002'),
          event('any', '不限', 'U002'),
          event('legacy', null, 'U002'),
          event('own', '不限', viewer['id'] as String),
        ],
      });
      final repo = ActivityDetailRepository(store);
      await expectLater(repo.join('male'), throwsStateError);
      await expectLater(repo.join('own'), throwsStateError);
      await expectLater(repo.join('missing'), throwsStateError);
      await repo.join('female');
      await expectLater(repo.join('female'), throwsStateError);
      await repo.join('any');
      await repo.join('legacy');
      expect(await repo.joinedIds(), containsAll(['female', 'any', 'legacy']));
      expect(await repo.joinedIds(), isNot(contains('male')));
      final reopened = ActivityDetailRepository(
        MockJsonStore(directory: () async => directory),
      );
      expect(await reopened.joinedIds(), hasLength(3));
      account['isSignedIn'] = false;
      await store.write('user/account', account);
      await expectLater(repo.join('male'), throwsStateError);
    },
  );
}
