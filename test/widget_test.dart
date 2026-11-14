import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bookmunity/design/brutal_theme.dart';
import 'package:bookmunity/screens/design_gallery.dart';

void main() {
  testWidgets('design gallery renders the component set', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: brutalTheme(dark: false), home: const DesignGallery()),
    );

    expect(find.text('Design system'), findsOneWidget);
    expect(find.text('Add book'), findsOneWidget);
    expect(find.text('Chips'), findsOneWidget);

    // Dark theme toggle rebuilds without errors.
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
