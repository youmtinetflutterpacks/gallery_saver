import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/main.dart';

void main() {
  testWidgets('Verify UI is displayed', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());

    expect(
      find.byWidgetPredicate(
        (Widget widget) {
          return widget is Text && (widget.data?.startsWith('Take photo') ?? false);
        },
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (Widget widget) {
          return widget is Text && (widget.data?.startsWith('Record video') ?? false);
        },
      ),
      findsOneWidget,
    );
  });
}
