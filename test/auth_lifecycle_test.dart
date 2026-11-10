import 'dart:io';
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
    'two phone accounts isolate private state and deletion cannot resurrect former identity',
    () async {
      final repository = auth();
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
      await repository.deleteAccount(a.accountId);
      final reopened = auth();
      await reopened.sendCode('14444000001');
      final fresh = await reopened.login(
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
