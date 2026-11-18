import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app_framework/main.dart';
import 'package:flutter_app_framework/core/storage/mock_json_store.dart';
import 'package:flutter_app_framework/features/user/data/profile_repository.dart';
import 'package:flutter_app_framework/features/user/presentation/pages/profile_field_page.dart';
import 'package:flutter_app_framework/features/square/data/model/square_post.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'extended profile fields persist through a new store and old snapshots remain readable',
    () async {
      final dir = await Directory.systemTemp.createTemp('profile_v4_');
      addTearDown(() => dir.delete(recursive: true));
      MockJsonStore store() => MockJsonStore(directory: () async => dir);
      final repo = ProfileMockRepository(store());
      final initial = await repo.load();
      final changed = initial.copyWith(
        profile: initial.profile.copyWith(
          photos: ['/private/tmp/photo.png'],
          heightCm: 171,
          weightKg: 63,
          occupation: '护士',
          education: '大专',
          hometown: '广东｜深圳',
          relationshipStatus: '单身',
        ),
      );
      await repo.save(changed);
      final restored = (await ProfileMockRepository(store()).load()).profile;
      expect(restored.photos, ['/private/tmp/photo.png']);
      expect(restored.heightCm, 171);
      expect(restored.weightKg, 63);
      expect(restored.occupation, '护士');
      expect(restored.education, '大专');
      expect(restored.hometown, '广东｜深圳');
      expect(restored.relationshipStatus, '单身');
      expect(
        MemberProfile.fromJson(
          initial.profile.toJson()
            ..remove('photos')
            ..remove('heightCm'),
        ).photos,
        isEmpty,
      );
    },
  );
  test(
    'pending and rejected posts retain review status while public filtering excludes them',
    () {
      final base = {
        'id': 'p',
        'author': 'a',
        'avatar': '',
        'text': '内容',
        'photos': [],
      };
      for (final status in ['pending', 'rejected']) {
        final post = SquarePost.fromJson({...base, 'reviewStatus': status});
        expect(post.isPublic, isFalse);
        expect(
          SquarePost.fromJson(post.toJson()).reviewStatus,
          post.reviewStatus,
        );
        expect(post.reviewStatus, isNotNull);
      }
      expect(SquarePost.fromJson(base).isPublic, isTrue);
      expect(
        SquarePost.fromJson({...base, 'isPrivate': true}).isPublic,
        isFalse,
      );
    },
  );
  for (final title in ['修改昵称', '编辑个性签名']) {
    testWidgets(
      '$title rejects empty and unchanged; cancel preserves draft; discard exits',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: Application(
              startPage: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ProfileFieldPage(
                          title: title,
                          initial: '原有内容',
                          limit: 100,
                        ),
                      ),
                    ),
                    child: const Text('打开'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('打开'));
        await tester.pumpAndSettle();
        final save = find.widgetWithText(FilledButton, '保存');
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(find.text('内容未修改'), findsOneWidget);
        expect(find.byType(ProfileFieldPage), findsOneWidget);
        await tester.enterText(find.byType(TextField), '   ');
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(find.byType(ProfileFieldPage), findsOneWidget);
        await tester.enterText(find.byType(TextField), '新的内容');
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.textContaining('未保存'), findsOneWidget);
        await tester.tap(find.text('取消'));
        await tester.pumpAndSettle();
        expect(find.text('新的内容'), findsOneWidget);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        await tester.tap(find.text('放弃'));
        await tester.pumpAndSettle();
        expect(find.byType(ProfileFieldPage), findsNothing);
        await tester.pump(const Duration(seconds: 3));
      },
    );
  }
}
