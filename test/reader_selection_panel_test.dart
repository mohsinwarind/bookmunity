import 'package:bookmunity/features/dictionary/dictionary_service.dart';
import 'package:bookmunity/features/dictionary/dictionary_view.dart';
import 'package:bookmunity/features/reader/data/reader_bridge.dart';
import 'package:bookmunity/features/reader/presentation/widgets/selection_panels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _body = '''
[{"word":"incomprehensibilities","phonetic":"/ˌɪnkɒmpɹɪˌhɛnsɪˈbɪlɪtiz/ /ˌɪnkɑmpɹəˌhɛnsəˈbɪlətiz/",
  "meanings":[{"partOfSpeech":"noun","definitions":[{"definition":"The quality or state of being impossible to understand, explained here at deliberately great length so the preview must wrap and truncate rather than overflow."}]}]}]
''';

Widget _panel(ReaderSelection selection, double width) {
  return ProviderScope(
    overrides: [
      definitionProvider.overrideWith(
        (ref, word) async => DictionaryFound(DictionaryEntry.parse(_body)!),
      ),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: width,
            child: SelectionToolbar(
              selection: selection,
              onHighlight: (_) {},
              onNote: () {},
              onCopy: () {},
              onSearch: () {},
              onDefine: (_) {},
              onClose: () {},
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  // A 320dp phone with the reader's 12dp side insets.
  const width = 296.0;

  Future<void> pumpAt(WidgetTester tester, ReaderSelection selection) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_panel(selection, width));
    await tester.pumpAndSettle();
  }

  testWidgets('word definition panel fits a narrow phone', (tester) async {
    await pumpAt(
      tester,
      const ReaderSelection(
        cfiRange: 'epubcfi(/6/4!/4/2,/1:0,/1:5)',
        text: 'incomprehensibilities',
        chapterTitle: 'One',
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('More'), findsOneWidget);
    expect(find.text('Define'), findsOneWidget);
    expect(find.byTooltip('Highlight Yellow'), findsOneWidget);
  });

  testWidgets('passage panel fits a narrow phone', (tester) async {
    await pumpAt(
      tester,
      const ReaderSelection(
        cfiRange: 'epubcfi(/6/4!/4/2,/1:0,/1:90)',
        text:
            'It was the best of times, it was the worst of times, it was the age of wisdom.',
        chapterTitle: 'One',
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Define'), findsNothing);
    expect(find.text('Note'), findsOneWidget);
  });
}
