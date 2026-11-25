import 'dart:async';
import 'package:flutter_app_framework/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_app_framework/features/auth/data/model/auth_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:flutter_app_framework/features/messages/presentation/providers/messages_provider.dart';
import 'package:flutter_app_framework/features/square/presentation/providers/square_provider.dart';
import 'package:flutter_app_framework/features/square/presentation/widgets/square_video_feed.dart';
import 'package:flutter_app_framework/features/square/presentation/providers/square_video_publishers_provider.dart';
import 'package:flutter_app_framework/features/square/data/model/square_video_catalog.dart';

class AuditMessages extends MessagesNotifier {
  @override
  MessagesState build() => const MessagesState([]);
}
class AuditSquare extends SquareNotifier {
  @override
  SquareState build() => const SquareState([]);
}
class AuditVideoPlatform extends VideoPlayerPlatform {
  int next = 0;
  final assets = <int, String>{};
  final playing = <int>{};
  final disposed = <int>{};
  @override Future<void> init() async {}
  @override Future<int?> create(DataSource dataSource) async { assets[++next] = dataSource.asset!; return next; }
  @override Stream<VideoEvent> videoEventsFor(int id) => Stream.value(VideoEvent(eventType: VideoEventType.initialized, duration: const Duration(minutes: 1), size: const Size(500, 800)));
  @override Future<void> dispose(int id) async { disposed.add(id); playing.remove(id); }
  @override Future<void> play(int id) async { playing.add(id); }
  @override Future<void> pause(int id) async { playing.remove(id); }
  @override Future<void> setLooping(int id, bool value) async {}
  @override Future<void> setVolume(int id, double value) async {}
  @override Future<void> setPlaybackSpeed(int id, double value) async {}
  @override Future<void> seekTo(int id, Duration value) async {}
  @override Future<Duration> getPosition(int id) async => Duration.zero;
  @override Widget buildView(int id) => const SizedBox.expand();
}
void main() {
  testWidgets('blocked current and last publishers release players; empty and restored accounts stay aligned', (tester) async {
    final old = VideoPlayerPlatform.instance;
    final platform = AuditVideoPlatform();
    VideoPlayerPlatform.instance = platform;
    addTearDown(() => VideoPlayerPlatform.instance = old);
    var accountId = 'audit-A';
    final container = ProviderContainer(overrides: [
      authSessionProvider.overrideWith((ref) async => AuthSession(accountId)),
      messagesProvider.overrideWith(AuditMessages.new),
      squareProvider.overrideWith(AuditSquare.new),
      squareVideoPublishersProvider.overrideWith((ref) async => {}),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(container: container,
      child: ScreenUtilInit(designSize: const Size(375, 812), builder: (_, child) => const MaterialApp(home: Scaffold(body: SquareVideoFeed(isActive: true))))));
    await tester.pumpAndSettle();
    final messages = container.read(messagesProvider.notifier);
    final firstPlayer = platform.next;
    expect(platform.assets[firstPlayer], contains(squareVideoIds.first));
    messages.blockAuthor(squareVideoAuthorIds[squareVideoIds.first]!, 'first', '');
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.runAsync(() async { await Future<void>.delayed(const Duration(milliseconds: 20)); });
    expect(platform.disposed, contains(firstPlayer));
    expect(platform.assets[platform.next], contains(squareVideoIds[1]));
    expect(platform.playing.contains(firstPlayer), isFalse);
    for (final id in squareVideoIds.skip(1).take(8)) {
      messages.blockAuthor(squareVideoAuthorIds[id]!, id, '');
    }
    await tester.pumpAndSettle();
    expect(platform.assets[platform.next], contains(squareVideoIds.last));
    final lastPlayer = platform.next;
    messages.blockAuthor(squareVideoAuthorIds[squareVideoIds.last]!, 'last', '');
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.runAsync(() async { await Future<void>.delayed(const Duration(milliseconds: 20)); });
    expect(platform.disposed, contains(lastPlayer));
    expect(platform.playing, isEmpty);
    expect(find.byType(PageView), findsNothing);
    for (final key in container.read(messagesProvider).blocked.keys.toList()) { messages.unblock(key); }
    await tester.pumpAndSettle();
    expect(find.byType(PageView), findsOneWidget);
    expect(platform.assets[platform.next], contains(squareVideoIds.first));
    messages.blockAuthor(squareVideoAuthorIds[squareVideoIds.first]!, 'first', '');
    await tester.pumpAndSettle();
    final previousAccountPlayer = platform.next;
    accountId = 'audit-B';
    container.invalidate(messagesProvider);
    container.invalidate(authSessionProvider);
    await tester.pumpAndSettle();
    await tester.runAsync(() async { await Future<void>.delayed(const Duration(milliseconds: 20)); });
    expect(platform.disposed, contains(previousAccountPlayer));
    expect(platform.assets[platform.next], contains(squareVideoIds.first));
    expect(container.read(messagesProvider).blocked, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await tester.runAsync(() async { await Future<void>.delayed(const Duration(milliseconds: 20)); });
    expect(platform.playing, isEmpty);
  });
}
