import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app_framework/main.dart';

void main() {
  testWidgets(
    'outside touch and scroll dismiss keyboard without consuming controls or text',
    (tester) async {
      final first = FocusNode(), second = FocusNode();
      final text = TextEditingController();
      var taps = 0;
      await tester.pumpWidget(
        Application(
          startPage: Scaffold(
            body: ListView(
              children: [
                TextField(
                  key: const ValueKey('first'),
                  focusNode: first,
                  controller: text,
                ),
                TextField(key: const ValueKey('second'), focusNode: second),
                TextButton(onPressed: () => taps++, child: const Text('操作按钮')),
                const SizedBox(
                  key: ValueKey('blank'),
                  height: 100,
                  width: double.infinity,
                  child: ColoredBox(color: Colors.white),
                ),
                const SizedBox(height: 1200),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('first')));
      await tester.pump();
      await tester.enterText(find.byKey(const ValueKey('first')), '保留内容');
      await tester.tap(find.byKey(const ValueKey('second')));
      await tester.pump();
      expect(second.hasFocus, isTrue);
      await tester.tap(find.byKey(const ValueKey('blank')));
      await tester.pump();
      expect(second.hasFocus, isFalse);
      expect(text.text, '保留内容');
      await tester.tap(find.byKey(const ValueKey('first')));
      await tester.pump();
      await tester.tap(find.text('操作按钮'));
      await tester.pump();
      expect(taps, 1);
      expect(first.hasFocus, isFalse);
      await tester.tap(find.byKey(const ValueKey('first')));
      await tester.pump();
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(first.hasFocus, isFalse);
      expect(text.text, '保留内容');
      await tester.pumpWidget(const SizedBox.shrink());
      first.dispose();
      second.dispose();
      text.dispose();
    },
  );
}
