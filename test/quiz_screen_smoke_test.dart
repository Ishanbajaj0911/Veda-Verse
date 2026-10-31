import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veda_verse/screens/quiz_screen.dart';

Future<void> _answer(WidgetTester tester, String letter, String button) async {
  // Options are rendered as "A"/"B"/"C" avatars; tap the letter then advance.
  await tester.tap(find.text(letter));
  await tester.pumpAndSettle();
  await tester.tap(find.text(button));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('quiz screen renders and advances through questions',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: QuizScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Q1/30'), findsOneWidget);
    expect(find.text('Body Frame'), findsOneWidget);

    await _answer(tester, 'A', 'Next');

    expect(find.text('Q2/30'), findsOneWidget);
    expect(find.text('Type of Hair'), findsOneWidget);
  });

  testWidgets('confident answers go straight to the result screen',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: QuizScreen()));
    await tester.pumpAndSettle();

    for (var i = 0; i < 29; i++) {
      await _answer(tester, 'B', 'Next');
    }
    await _answer(tester, 'B', 'Submit');
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Your Dosha'), findsOneWidget);
    expect(find.text('Pitta'), findsWidgets);
    expect(find.textContaining('tie-breaker'), findsNothing);
  });

  testWidgets('split answers trigger the tie-breaker round, then a result',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: QuizScreen()));
    await tester.pumpAndSettle();

    for (var i = 0; i < 15; i++) {
      await _answer(tester, 'A', 'Next');
    }
    for (var i = 15; i < 29; i++) {
      await _answer(tester, 'B', 'Next');
    }
    await _answer(tester, 'B', 'Submit');
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Still on the quiz, now in the tie-breaker round for Vata vs Pitta.
    expect(find.text('Tie-breaker: Vata vs Pitta'), findsOneWidget);
    expect(find.text('Q1/6'), findsOneWidget);
    expect(find.text('Temperature'), findsOneWidget);

    // Answer all 6 toward Pitta (option B).
    for (var i = 0; i < 5; i++) {
      await _answer(tester, 'B', 'Next');
    }
    await _answer(tester, 'B', 'Submit');
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Your Dosha'), findsOneWidget);
    expect(find.textContaining('after tie-breaker round'), findsOneWidget);
    // 15 Vata + 15 Pitta + 6 Pitta tie-breakers -> dual type, Pitta leading.
    expect(find.text('Pitta-Vata'), findsOneWidget);
  });
}
