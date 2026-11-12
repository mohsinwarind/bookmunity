import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bookmunity/design/brutal_theme.dart';
import 'package:bookmunity/screens/design_gallery.dart';

void main() {
  testWidgets('design gallery renders the brutalist component set', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: brutalTheme(dark: false), home: const DesignGallery()),
    );

    expect(find.text('DESIGN SYSTEM'), findsOneWidget);
    expect(find.text('IMPORT +'), findsOneWidget);
    expect(find.text('CHIPS'), findsOneWidget);
  });
}
