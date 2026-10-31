import 'package:flutter_test/flutter_test.dart';
import 'package:veda_verse/main.dart';

void main() {
  testWidgets('app boots to the welcome screen', (WidgetTester tester) async {
    await tester.pumpWidget(const VedaVerseApp());
    await tester.pump();
    expect(find.text('Find my rhythm'), findsOneWidget);
    expect(find.text('VEDAVERSE IS FOR'), findsOneWidget);
  });
}
