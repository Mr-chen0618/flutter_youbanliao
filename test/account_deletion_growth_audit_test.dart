import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app_framework/core/storage/mock_json_store.dart';
import 'package:flutter_app_framework/features/auth/data/mock/auth_mock_repository.dart';
import 'package:flutter_app_framework/features/auth/data/request-model/phone_login_request.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('expired deletion removes account growth and uploaded video reference', () async {
    final dir = await Directory.systemTemp.createTemp('deletion_growth_audit_');
    addTearDown(() => dir.delete(recursive: true));
    var now = DateTime(2026, 11, 1);
    final store = MockJsonStore(directory: () async => dir);
    final auth = AuthMockRepository(store, now: () => now, delay: Duration.zero);
    const phone = '14444000031';
    await auth.sendCode(phone);
    final account = await auth.login(const PhoneLoginRequest(phone, '8888'));
    final path = 'accounts/${account.accountId}/user/growth';
    await store.write(path, {'video': {'path': '/synthetic/private-video.mp4', 'status': 'pending'}, 'identityPending': true});
    await auth.deleteAccount(account.accountId);
    now = now.add(const Duration(days: 8));
    await auth.sendCode(phone);
    final fresh = await auth.login(const PhoneLoginRequest(phone, '8888'));
    expect(fresh.accountId, isNot(account.accountId));
    expect(await store.exists(path), isFalse, reason: 'permanently deleted account must not retain profile video reference/identity flags');
  });
}
