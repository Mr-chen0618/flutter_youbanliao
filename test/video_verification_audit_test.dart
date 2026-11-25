import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_app_framework/features/user/presentation/pages/verification_center_page.dart';
import 'package:flutter_app_framework/features/user/presentation/providers/growth_provider.dart';
import 'package:flutter_app_framework/shared/widgets/images/app_image.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app_framework/features/square/data/model/square_video_catalog.dart';
import 'package:flutter_app_framework/features/user/data/model/growth_state.dart';

void main() {
  for (final kind in ['empty', 'pending', 'real', 'identity', 'both']) {
    testWidgets('verification icons reflect $kind without duplicate state assets', (tester) async {
      final data = GrowthState(
        realPerson: kind == 'pending', identityPending: kind == 'pending',
        realPersonVerified: kind == 'real' || kind == 'both',
        identityVerified: kind == 'identity' || kind == 'both',
      );
      await tester.pumpWidget(ProviderScope(overrides: [
        growthProvider.overrideWith((ref) async => data),
      ], child: ScreenUtilInit(designSize: const Size(375, 812), builder: (_, child) => const MaterialApp(home: VerificationCenterPage()))));
      await tester.pumpAndSettle();
      final badges = tester.widgetList<AppImage>(find.byType(AppImage)).where((image) => image.key != null).toList();
      expect(badges.length, 2);
      expect(badges[0].src, endsWith('img${data.realPersonVerified ? 5 : 6}.svg'));
      expect(badges[1].src, endsWith('img${data.identityVerified ? 8 : 9}.svg'));
      expect(find.text('已认证'), findsNWidgets((data.realPersonVerified ? 1 : 0) + (data.identityVerified ? 1 : 0)));
      if (kind == 'pending') expect(find.text('审核中'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });
  }

  test('all ten immutable media IDs bind existing distinct seeded publishers', () {
    final seed = jsonDecode(File('assets/mock/home/catalog.json').readAsStringSync()) as Map;
    final users = {for (final item in seed['companions'] as List) item['id']: item};
    expect(squareVideoIds.length, 10);
    expect(squareVideoAuthorIds.keys.toSet(), squareVideoIds.toSet());
    expect(squareVideoAuthorIds.values.toSet().length, 10);
    for (final id in squareVideoIds) {
      final user = users[squareVideoAuthorIds[id]] as Map;
      expect((user['name'] as String).isNotEmpty, isTrue);
      expect(File(user['avatar'] as String).existsSync(), isTrue);
      expect(File('assets/square/videos/$id.mp4').existsSync(), isTrue);
    }
  });
  test('legacy submissions never become approved; explicit results remain separate', () {
    for (final flags in [{}, {'realPerson': true, 'identityPending': true}]) {
      final state = GrowthState.fromJson(Map<String, dynamic>.from(flags));
      expect(state.realPersonVerified, isFalse);
      expect(state.identityVerified, isFalse);
    }
    final real = GrowthState.fromJson({'realPersonVerified': true});
    expect(real.realPersonVerified, isTrue);
    expect(real.identityVerified, isFalse);
    final identity = GrowthState.fromJson({'identityVerified': true});
    expect(identity.identityVerified, isTrue);
    expect(identity.realPersonVerified, isFalse);
  });
}
