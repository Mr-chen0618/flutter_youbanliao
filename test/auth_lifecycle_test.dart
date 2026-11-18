import 'dart:io';
import 'package:flutter_app_framework/features/auth/data/model/auth_login_restriction.dart';
import 'package:flutter_app_framework/features/user/presentation/bloc/user_bloc.dart';
import 'package:flutter_app_framework/features/user/presentation/bloc/user_event.dart';
import 'package:flutter_app_framework/features/user/data/profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app_framework/core/storage/mock_json_store.dart';
import 'package:flutter_app_framework/core/storage/account_mock_json_store.dart';
import 'package:flutter_app_framework/features/auth/data/mock/auth_mock_repository.dart';
import 'package:flutter_app_framework/features/auth/data/request-model/phone_login_request.dart';

Map<String, dynamic> object(Object? v) => Map<String, dynamic>.from(v as Map);
MemberProfile profile(String id) => MemberProfile(
  id: id,
  name: '测试搭子',
  avatar: 'assets/mock/media/IMG025.jpg',
  signature: '',
  gender: '女',
  birthday: DateTime(2000, 1, 2),
  city: '深圳',
  interests: [],
  tags: [],
  following: 0,
  followers: 0,
  friends: 0,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  MockJsonStore store() => MockJsonStore(directory: () async => directory);
  AuthMockRepository auth() =>
      AuthMockRepository(store(), delay: Duration.zero);
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('auth_quality_');
  });
  tearDown(() async {
    await directory.delete(recursive: true);
  });

  test(
    'registered gender cannot be changed through a direct business event',
    () async {
      final repository = ProfileMockRepository(store());
      final initial = (await repository.load()).copyWith(
        profileCompleted: true,
      );
      final bloc = UserBloc(repository, initial);
      addTearDown(bloc.close);
      final next = bloc.stream.first;
      bloc.add(
        UserProfileEdited(
          (p) => p.copyWith(name: '新昵称', gender: p.gender == '男' ? '女' : '男'),
        ),
      );
      final result = await next;
      expect(result.profile.gender, initial.profile.gender);
      expect(result.profile.name, '新昵称');
    },
  );

  test(
    'registration rejects invalid fields without marking profile completed',
    () async {
      final repository = auth();
      await repository.sendCode('14444000011');
      final session = await repository.login(
        const PhoneLoginRequest('14444000011', '8888'),
      );
      final valid = profile(session.accountId);
      final now = DateTime.now();
      for (final invalid in [
        valid.copyWith(avatar: ''),
        valid.copyWith(gender: ''),
        valid.copyWith(name: '123456'),
        valid.copyWith(birthday: DateTime(now.year, now.month, now.day)),
        valid.copyWith(birthday: DateTime(now.year + 1)),
      ]) {
        await expectLater(
          repository.completeProfile(session.accountId, invalid),
          throwsStateError,
        );
        expect((await auth().restore())?.profileCompleted, isFalse);
      }
      await repository.completeProfile(session.accountId, valid);
      await expectLater(
        repository.completeProfile(
          session.accountId,
          valid.copyWith(name: '第二次保存'),
        ),
        throwsStateError,
      );
      final restored = await ProfileMockRepository(
        AccountMockJsonStore(store(), session.accountId),
      ).load();
      expect(restored.profile.name, valid.name);
      expect(restored.profile.avatar, valid.avatar);
      expect(restored.profile.birthday, valid.birthday);
    },
  );

  test(
    'fresh installation does not authenticate from bundled U001; pending profile survives reopening',
    () async {
      final repository = auth();
      expect(await repository.restore(), isNull);
      await repository.sendCode('14444000001');
      final session = await repository.login(
        const PhoneLoginRequest('14444000001', '8888'),
      );
      expect(session.profileCompleted, isFalse);
      final restored = await auth().restore();
      expect(restored?.accountId, session.accountId);
      expect(restored?.profileCompleted, isFalse);
      await repository.completeProfile(
        session.accountId,
        profile(session.accountId),
      );
      expect((await auth().restore())?.profileCompleted, isTrue);
      await repository.signOut();
      expect(await auth().restore(), isNull);
      final reopened = auth();
      await reopened.sendCode('14444000001');
      final again = await reopened.login(
        const PhoneLoginRequest('14444000001', '8888'),
      );
      expect(again.accountId, session.accountId);
      expect(again.profileCompleted, isTrue);
    },
  );

  test(
    'verification requires request, correct code and rejects immediate resend',
    () async {
      final repository = auth();
      await expectLater(
        repository.login(const PhoneLoginRequest('14444000001', '8888')),
        throwsStateError,
      );
      await expectLater(repository.sendCode('123'), throwsStateError);
      await repository.sendCode('14444000001');
      await expectLater(repository.sendCode('14444000001'), throwsStateError);
      await expectLater(
        repository.login(const PhoneLoginRequest('14444000001', '999999')),
        throwsStateError,
      );
      await repository.login(const PhoneLoginRequest('14444000001', '8888'));
      await expectLater(
        repository.login(const PhoneLoginRequest('14444000001', '8888')),
        throwsStateError,
      );
    },
  );

  test(
    'two accounts stay isolated; deletion can recover within seven days and expires to new identity',
    () async {
      var clock = DateTime(2026, 11, 17);
      AuthMockRepository clockAuth() =>
          AuthMockRepository(store(), delay: Duration.zero, now: () => clock);
      final repository = clockAuth();
      await repository.sendCode('14444000001');
      final a = await repository.login(
        const PhoneLoginRequest('14444000001', '8888'),
      );
      await repository.completeProfile(a.accountId, profile(a.accountId));
      final aStore = AccountMockJsonStore(store(), a.accountId);
      await aStore.write('home/invites', {
        'ids': ['U002'],
        'drafts': {},
      });
      await aStore.write('report/reports', {
        'items': [
          {'targetId': 'private-a'},
        ],
      });
      await repository.signOut();
      await repository.sendCode('14444000002');
      final b = await repository.login(
        const PhoneLoginRequest('14444000002', '8888'),
      );
      expect(b.accountId, isNot(a.accountId));
      final bStore = AccountMockJsonStore(store(), b.accountId);
      expect((await bStore.read('home/invites', object))['ids'], isEmpty);
      expect((await bStore.read('report/reports', object))['items'], isEmpty);
      expect((await aStore.read('home/invites', object))['ids'], ['U002']);
      await expectLater(
        repository.deleteAccount(a.accountId),
        throwsStateError,
      );
      expect((await repository.restore())!.accountId, b.accountId);
      await repository.sendCode('14444000001');
      await repository.login(const PhoneLoginRequest('14444000001', '8888'));
      await repository.deleteAccount(a.accountId);
      expect(await clockAuth().restore(), isNull);
      final reopened = clockAuth();
      await reopened.sendCode('14444000001');
      await expectLater(
        reopened.login(const PhoneLoginRequest('14444000001', '8888')),
        throwsA(isA<AuthAccountPendingDeletion>()),
      );
      expect(await clockAuth().restore(), isNull);
      expect((await aStore.read('home/invites', object))['ids'], ['U002']);
      await expectLater(
        reopened.recoverAccount(
          b.accountId,
          const PhoneLoginRequest('14444000001', '8888'),
        ),
        throwsStateError,
      );
      await expectLater(
        reopened.recoverAccount(
          a.accountId,
          const PhoneLoginRequest('14444000001', '1111'),
        ),
        throwsStateError,
      );
      expect(await clockAuth().restore(), isNull);
      final recovered = await reopened.recoverAccount(
        a.accountId,
        const PhoneLoginRequest('14444000001', '8888'),
      );
      expect(recovered.accountId, a.accountId);
      expect(recovered.profileCompleted, isTrue);
      final state = await aStore.read('user/account', object);
      expect(state['isDeleted'], isFalse);
      expect(state['isSignedIn'], isTrue);
      expect((await clockAuth().restore())!.accountId, a.accountId);
      await reopened.deleteAccount(a.accountId);
      final registry = await store().read('auth/accounts', object);
      final firstDeadline =
          (registry['pendingDeletions'] as Map)[a.accountId]['deadline'];
      clock = clock.add(const Duration(days: 1));
      await reopened.deleteAccount(a.accountId);
      expect(
        ((await store().read('auth/accounts', object))['pendingDeletions']
            as Map)[a.accountId]['deadline'],
        firstDeadline,
      );
      clock = clock.add(const Duration(days: 6));
      final expired = clockAuth();
      await expired.sendCode('14444000001');
      final fresh = await expired.login(
        const PhoneLoginRequest('14444000001', '8888'),
      );
      expect(fresh.accountId, isNot(a.accountId));
      expect(fresh.profileCompleted, isFalse);
      final freshStore = AccountMockJsonStore(store(), fresh.accountId);
      expect((await freshStore.read('home/invites', object))['ids'], isEmpty);
      expect(
        await store().exists('accounts/${a.accountId}/user/account'),
        isFalse,
      );
      expect((await bStore.read('home/invites', object))['ids'], isEmpty);
      expect(
        await store().exists('accounts/${b.accountId}/user/account'),
        isTrue,
      );
    },
  );

  test(
    'existing real snapshot migrates whereas signed-out legacy stays signed out',
    () async {
      final legacy = await store().seed('user/account', object);
      legacy['isSignedIn'] = false;
      await store().write('user/account', legacy);
      final repository = auth();
      expect(await repository.restore(), isNull);
      await repository.sendCode('13800138000');
      final result = await repository.login(
        const PhoneLoginRequest('13800138000', '8888'),
      );
      expect(result.accountId, 'U001');
      expect(result.profileCompleted, isTrue);
    },
  );
}
