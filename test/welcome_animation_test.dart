import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_app_framework/shared/widgets/images/app_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app_framework/features/auth/presentation/widgets/welcome_animation.dart';
import 'package:flutter_app_framework/main.dart';
import 'package:flutter_svga/flutter_svga.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'welcome animation pauses in background, resumes and releases on leave',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: Application(startPage: Scaffold(body: WelcomeAnimation())),
        ),
      );
      // 解码在真实异步环境完成；不等待持续循环动画settle。
      for (
        var i = 0;
        i < 15 && find.byType(SVGAImage).evaluate().isEmpty;
        i++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 40)),
        );
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(find.byType(SVGAImage), findsOneWidget);
      final diagnostics = tester
          .widget<SVGAImage>(find.byType(SVGAImage))
          .toDiagnosticsNode()
          .getProperties();
      final controller =
          diagnostics.singleWhere((p) => p.name == 'controller').value
              as SVGAAnimationController;
      expect(controller.isAnimating, isTrue);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(controller.isAnimating, isFalse);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(controller.isAnimating, isTrue);
      final movie = controller.videoItem!;
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(movie.bitmapCache, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'decode failure keeps static fallback and late decode releases images',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: Application(
            startPage: Scaffold(
              body: WelcomeAnimation(
                decoder: () async =>
                    throw StateError('synthetic decode failure'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SVGAImage), findsNothing);
      expect(
        tester.widget<AppImage>(find.byType(AppImage)).src,
        'assets/auth/auth_brand_logo_image.png',
      );
      expect(tester.takeException(), isNull);
      final movie = (await tester.runAsync(
        () async => SVGAParser.shared.decodeFromBuffer(
          await File('assets/auth/auth_welcome.svga').readAsBytes(),
        ),
      ))!;
      expect(movie.bitmapCache, isNotEmpty);
      final pending = Completer<MovieEntity>();
      await tester.pumpWidget(
        ProviderScope(
          child: Application(
            startPage: Scaffold(
              body: WelcomeAnimation(
                key: const ValueKey('late'),
                decoder: () => pending.future,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      pending.complete(movie);
      await tester.pump();
      expect(movie.bitmapCache, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}
