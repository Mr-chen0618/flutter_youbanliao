import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'teen_mode_test_fixture.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app_framework/main.dart';
import 'package:flutter_app_framework/features/example/presentation/pages/example_page.dart';

void main() {
  testWidgets('Application smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [disabledTeenModeOverride],
        child: const Application(startPage: ExamplePage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ExamplePage'), findsOneWidget);
  });
}
