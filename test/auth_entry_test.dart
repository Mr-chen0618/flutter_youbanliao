import 'teen_mode_test_fixture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_framework/features/auth/data/repository/auth_repository.dart';
import 'package:flutter_app_framework/features/auth/presentation/pages/auth_entry_page.dart';
import 'package:flutter_app_framework/features/auth/presentation/pages/phone_login_page.dart';
import 'package:flutter_app_framework/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class EntryAuth extends Fake implements AuthRepository {}

void main() {
  testWidgets(
    'welcome requires consent, opens phone flow and returns without authenticating',
    (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      var entered = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [disabledTeenModeOverride],
          child: Application(
            startPage: AuthEntryPage(
              auth: EntryAuth(),
              onSignedIn: () => entered = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('welcome-phone-login')));
      await tester.pumpAndSettle();
      expect(find.text('请先阅读并同意用户协议和隐私政策'), findsOneWidget);
      expect(find.byType(PhoneLoginPage), findsNothing);
      await tester.tap(find.byKey(const ValueKey('welcome-agreement')));
      await tester.tap(find.byKey(const ValueKey('welcome-phone-login')));
      await tester.pumpAndSettle();
      expect(find.byType(PhoneLoginPage), findsOneWidget);
      expect(entered, isFalse);
      await tester.tap(find.byTooltip('返回'));
      await tester.pumpAndSettle();
      expect(find.byType(PhoneLoginPage), findsNothing);
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
      expect(entered, isFalse);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
      expect(tester.takeException(), isNull);
    },
  );
}
