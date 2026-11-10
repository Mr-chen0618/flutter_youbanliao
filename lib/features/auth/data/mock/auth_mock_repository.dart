import '../../../../core/storage/mock_json_store.dart';
import '../../../../core/storage/account_mock_json_store.dart';
import '../../../../core/utils/input_validator.dart';
import '../../../user/data/model/member_profile.dart';
import '../../../user/data/model/user_state.dart';
import '../model/auth_session.dart';
import '../repository/auth_repository.dart';
import '../request-model/phone_login_request.dart';

/// 本地短信认证演示：验证码不发送短信，固定 8888。
class AuthMockRepository implements AuthRepository {
  AuthMockRepository(
    this.store, {
    this.delay = const Duration(milliseconds: 250),
  });
  final MockJsonStore store;
  final Duration delay;
  final _codes = <String, DateTime>{};
  Map<String, dynamic> _decode(Object? value) =>
      Map<String, dynamic>.from(value as Map);
  Future<void>? _initialization;
  Future<void> _init() => _initialization ??= _initialize().catchError((
    Object error,
    StackTrace stack,
  ) {
    _initialization = null;
    Error.throwWithStackTrace(error, stack);
  });
  Future<void> _initialize() async {
    if (await store.exists('auth/accounts')) {
      await _ensureReviewAccount();
      await _ensureBusinessIds();
      return;
    }
    // 只有实际已有账号文件才迁移，打包种子不是已登录会话。
    final legacy = await store.exists('user/account');
    final accounts = <String, dynamic>{};
    String? active;
    if (legacy) {
      final user = await store.read('user/account', _decode);
      final id = (user['profile'] as Map)['id'] as String;
      for (final path in AccountMockJsonStore.privatePaths) {
        if (await store.exists(path)) {
          final data = await store.read(path, _decode);
          if (path == 'user/account') data['profileCompleted'] = true;
          await store.write('accounts/$id/$path', data);
        }
      }
      // 演示老账号手机号固定，登录页会明确显示供回归使用。
      accounts['13800138000'] = id;
      if (user['isSignedIn'] != false) active = id;
    }
    await store.write('auth/session', {'accountId': active});
    await store.write('auth/accounts', {'accounts': accounts});
    await _ensureReviewAccount();
    await _ensureBusinessIds();
  }

  static const reviewPhone = '17000000888';

  /// 单调业务号避免暴露时间戳；旧ID及映射保持原样。
  String _allocateId(Map<String, dynamic> json, Map<String, dynamic> accounts) {
    var next = json['nextAccountNumber'] as int? ?? 10000000;
    do {
      next++;
    } while (accounts.values.contains('$next') ||
        (json['businessIds'] as Map? ?? {}).values.contains('$next'));
    json['nextAccountNumber'] = next;
    return '$next';
  }

  /// 幂等补齐审核账号，仅创建资料，不生成报名、消息或互动行为。
  Future<void> _ensureReviewAccount() async {
    late String id;
    await store.update('auth/accounts', _decode, (json) {
      final accounts = Map<String, dynamic>.from(json['accounts'] as Map);
      id = accounts[reviewPhone] as String? ?? _allocateId(json, accounts);
      accounts[reviewPhone] = id;
      return {...json, 'accounts': accounts};
    });
    final path = 'accounts/$id/user/account';
    if (!await store.exists(path)) {
      final profile = MemberProfile(
        id: id,
        name: '审核体验员',
        avatar: 'assets/auth/auth_profile_default_avatar_image.png',
        signature: '',
        gender: '男',
        birthday: DateTime(2000, 1, 1),
        city: '',
        interests: const [],
        tags: const [],
        following: 0,
        followers: 0,
        friends: 0,
      );
      await store.initialize(
        path,
        UserState(profile, isSignedIn: false, profileCompleted: true).toJson(),
      );
    } else {
      await store.update(path, _decode, (json) {
        final user = UserState.fromJson(json);
        if (user.profileCompleted) return json;
        final current = user.profile;
        return user
            .copyWith(
              profileCompleted: true,
              profile: current.copyWith(
                name: current.name.isEmpty ? '审核体验员' : current.name,
                avatar: current.avatar.isEmpty
                    ? 'assets/auth/auth_profile_default_avatar_image.png'
                    : current.avatar,
                gender: current.gender.isEmpty ? '男' : current.gender,
                birthday: current.birthday ?? DateTime(2000, 1, 1),
              ),
            )
            .toJson();
      });
    }
  }

  Future<void> _ensureBusinessIds() async {
    late Map<String, dynamic> businessIds;
    await store.update('auth/accounts', _decode, (json) {
      final accounts = Map<String, dynamic>.from(json['accounts'] as Map);
      businessIds = Map<String, dynamic>.from(
        json['businessIds'] as Map? ?? {},
      );
      for (final id in accounts.values.cast<String>()) {
        if (id.startsWith('local-') && !businessIds.containsKey(id)) {
          businessIds[id] = _allocateId({
            ...json,
            'businessIds': businessIds,
          }, accounts);
          json['nextAccountNumber'] = int.parse(businessIds[id] as String);
        }
      }
      return {...json, 'businessIds': businessIds};
    });
    for (final entry in businessIds.entries) {
      final path = 'accounts/${entry.key}/user/account';
      if (!await store.exists(path)) continue;
      await store.update(path, _decode, (json) {
        final profile = Map<String, dynamic>.from(json['profile'] as Map);
        return {
          ...json,
          'profile': {...profile, 'businessId': entry.value},
        };
      });
    }
  }

  @override
  Future<AuthSession?> restore() async {
    await _init();
    final session = await store.read('auth/session', _decode);
    final id = session['accountId'] as String?;
    if (id == null) return null;
    final data = await AccountMockJsonStore(
      store,
      id,
    ).read('user/account', _decode);
    if (data['isDeleted'] == true || data['isSignedIn'] == false) return null;
    return AuthSession(id, profileCompleted: data['profileCompleted'] == true);
  }

  @override
  Future<void> sendCode(String phone) async {
    if (!InputValidator.isAcceptableLoginPhoneNumber(phone)) {
      throw StateError('请输入有效的手机号');
    }
    final now = DateTime.now();
    if (_codes[phone] case final sent?) {
      if (now.difference(sent).inSeconds < 60) throw StateError('请稍后重新获取验证码');
    }
    await Future<void>.delayed(delay);
    _codes[phone] = now;
  }

  @override
  Future<AuthSession> login(PhoneLoginRequest request) async {
    await _init();
    if (!InputValidator.isAcceptableLoginPhoneNumber(request.phone)) {
      throw StateError('请输入有效的手机号');
    }
    final sent = _codes[request.phone];
    if (sent == null || DateTime.now().difference(sent).inMinutes >= 5) {
      throw StateError('请先获取验证码，验证码五分钟内有效');
    }
    if (request.code != '8888') throw StateError('验证码不正确');
    await Future<void>.delayed(delay);
    String? id;
    await store.update('auth/accounts', _decode, (json) {
      final accounts = Map<String, dynamic>.from(json['accounts'] as Map);
      id = accounts[request.phone] as String?;
      id ??= _allocateId(json, accounts);
      accounts[request.phone] = id;
      return {...json, 'accounts': accounts};
    });
    final account = AccountMockJsonStore(store, id!);
    if (!await store.exists('accounts/$id/user/account')) {
      final profile = MemberProfile(
        id: id!,
        name: '',
        avatar: '',
        signature: '',
        gender: '',
        city: '',
        interests: const [],
        tags: const [],
        following: 0,
        followers: 0,
        friends: 0,
      );
      await store.write(
        'accounts/$id/user/account',
        UserState(profile, profileCompleted: false).toJson(),
      );
    }
    final user = UserState.fromJson(
      await account.read('user/account', _decode),
    );
    await account.write(
      'user/account',
      user.copyWith(isSignedIn: true).toJson(),
    );
    await store.write('auth/session', {'accountId': id});
    _codes.remove(request.phone);
    return AuthSession(id!, profileCompleted: user.profileCompleted);
  }

  @override
  Future<void> completeProfile(String accountId, MemberProfile profile) async {
    if (profile.id != accountId ||
        profile.avatar.isEmpty ||
        !['男', '女'].contains(profile.gender) ||
        !InputValidator.validateNickname(profile.name) ||
        profile.birthday == null ||
        !profile.birthday!.isBefore(
          DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
          ),
        ) ||
        profile.birthday!.year < 1900) {
      throw StateError('请完善头像、性别、昵称和生日');
    }
    final account = AccountMockJsonStore(store, accountId);
    final user = await account.read(
      'user/account',
      (v) => UserState.fromJson(_decode(v)),
    );
    if (user.profileCompleted) throw StateError('资料已完成，请前往编辑资料');
    await account.write(
      'user/account',
      user.copyWith(profile: profile, profileCompleted: true).toJson(),
    );
  }

  @override
  Future<void> signOut() async {
    await _init();
    await store.write('auth/session', {'accountId': null});
  }

  @override
  Future<void> deleteAccount(String accountId) async {
    await _init();
    await store.update('auth/accounts', _decode, (json) {
      final accounts = Map<String, dynamic>.from(json['accounts'] as Map)
        ..removeWhere((key, value) => value == accountId);
      return {...json, 'accounts': accounts};
    });
    await store.write('accounts/$accountId/deleted', {'deleted': true});
    await signOut();
    for (final path in AccountMockJsonStore.privatePaths) {
      await store.delete('accounts/$accountId/$path');
      if (accountId == 'U001') await store.delete(path);
    }
    await store.update(
      'activity/published',
      _decode,
      (json) => {
        ...json,
        'items': (json['items'] as List)
            .where((item) => item['ownerId'] != accountId)
            .toList(),
      },
    );
  }
}
