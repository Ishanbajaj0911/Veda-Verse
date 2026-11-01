// Yoga tab: session detail, booking and cancelling, the "ask your Vaidya
// first" step, and the guided practice timer. Also opens the detail, the
// sheets and the practice screens in Hindi at 390x844 and fails on overflow
// or English words left on screen.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veda_verse/content/sessions.dart';
import 'package:veda_verse/engine/plan_engine.dart';
import 'package:veda_verse/l10n/lang.dart';
import 'package:veda_verse/screens/practice_screen.dart';
import 'package:veda_verse/screens/session_screen.dart';
import 'package:veda_verse/screens/yoga_screen.dart';
import 'package:veda_verse/state/app_state.dart';
import 'package:veda_verse/theme/vv.dart';

/// Words that may stay in Latin letters in Hindi (proper nouns and units),
/// as in test/screens_hindi_test.dart.
const _allowedLatin = ['VedaVerse', 'Veda', 'Verse', 'Ayu Buddy', 'Aarav', 'Mehta', 'Dr.'];

List<String> _englishLeft(WidgetTester t) {
  final out = <String>{};
  for (final r in t.widgetList<RichText>(find.byType(RichText))) {
    var s = r.text.toPlainText();
    for (final a in _allowedLatin) {
      s = s.replaceAll(a, ' ');
    }
    if (RegExp('[A-Za-z]{3,}').hasMatch(s)) out.add(r.text.toPlainText().replaceAll('\n', ' '));
  }
  return out.toList();
}

Future<void> _loadFonts() async {
  final romie = FontLoader('Romie');
  for (final f in ['Romie-300', 'Romie-300Italic', 'Romie-500', 'Romie-500Italic', 'Romie-700']) {
    romie.addFont(rootBundle.load('assets/fonts/$f.otf'));
  }
  await romie.load();
  final manrope = FontLoader('Manrope')..addFont(rootBundle.load('assets/fonts/Manrope-Variable.ttf'));
  await manrope.load();
}

Future<void> _pump(WidgetTester t, Widget screen) async {
  await t.pumpWidget(MaterialApp(theme: Vv.theme(), home: Scaffold(body: screen)));
  await t.pump(const Duration(milliseconds: 300));
}

Future<void> _settle(WidgetTester t) async {
  for (var i = 0; i < 6; i++) {
    await t.pump(const Duration(milliseconds: 150));
  }
}

RankedSession _ranked(String titleEn) =>
    rankSessions([...nearSessions, ...onlineSessions], AppState.instance.engineInput).firstWhere((r) => r.session.titleEn == titleEn);

Finder _key(String k) => find.byKey(ValueKey(k));

void _noEnglish(WidgetTester t, String where) => expect(_englishLeft(t), isEmpty, reason: 'English left on $where');

/// Scrolls the detail to the bottom, checking the text on the way.
Future<void> _scrollDetail(WidgetTester t, String where, {bool hindi = false}) async {
  for (var i = 0; i < 4; i++) {
    if (hindi) _noEnglish(t, '$where (scroll $i)');
    await t.drag(find.byType(ListView).last, const Offset(0, -400));
    await t.pump(const Duration(milliseconds: 200));
  }
  if (hindi) _noEnglish(t, '$where (bottom)');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(_loadFonts);

  setUp(() {
    final v = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    v.physicalSize = const Size(390, 844);
    v.devicePixelRatio = 1;
    AppState.instance
      ..name = 'Aarav Mehta'
      ..conditions = {}
      ..gender = 'Male'
      ..pregnancy = 'No'
      ..joinedSessions = {};
  });
  tearDown(() {
    Lang.notifier.value = Lang.en;
    AppState.instance
      ..conditions = {}
      ..joinedSessions = {};
  });

  test('every session has copy and a picture; startable ones have steps', () {
    for (final s in [...nearSessions, ...onlineSessions]) {
      final info = sessionInfo[s.titleEn];
      expect(info, isNotNull, reason: s.titleEn);
      expect(info!.benefits.length, inInclusiveRange(3, 4));
      expect(info.bring, isNotEmpty);
      if (s.ctaEn == 'Start') expect(practices[s.titleEn], isNotEmpty, reason: s.titleEn);
    }
    for (final steps in practices.values) {
      for (final st in steps) {
        expect(st.seconds, greaterThan(0));
        expect(RegExp('[A-Za-z]{3,}').hasMatch(st.name.$2 + st.how.$2), isFalse, reason: st.name.$1);
      }
    }
  });

  testWidgets('a card opens its detail', (t) async {
    await _pump(t, const YogaScreen());
    expect(find.byType(SessionPicture), findsWidgets);
    await t.tap(find.text('Sunrise Hatha by the lake'));
    await _settle(t);
    expect(find.byType(SessionScreen), findsOneWidget);
    expect(find.text('WHY WE PICKED THIS'), findsOneWidget);
    expect(find.text('ABOUT'), findsOneWidget);
    await _scrollDetail(t, 'sunrise detail');
    expect(find.text('Start the day calm and alert'), findsOneWidget);
    expect(find.text('Your own mat or a thick towel'), findsOneWidget);
  });

  testWidgets('book from the detail, then cancel', (t) async {
    await _pump(t, SessionScreen(ranked: _ranked('Sunrise Hatha by the lake')));
    await t.tap(_key('session-main'));
    await _settle(t);
    expect(find.text('Free to join. Nothing to pay.'), findsWidgets);
    await t.tap(_key('session-confirm'));
    await _settle(t);
    expect(AppState.instance.joinedSessions, contains('Sunrise Hatha by the lake'));
    expect(find.text('Joined ✓'), findsNWidgets(2)); // badge + button
    await t.tap(_key('session-cancel'));
    await _settle(t);
    await t.tap(_key('session-cancel-confirm'));
    await _settle(t);
    expect(AppState.instance.joinedSessions, isNot(contains('Sunrise Hatha by the lake')));
    expect(find.text('Joined ✓'), findsNothing);
    expect(_key('session-main'), findsOneWidget);

  });

  testWidgets('book from a card: paid note, booked state, cancel', (t) async {
    await _pump(t, const YogaScreen());
    const title = 'Gentle spine & back therapy';
    await t.scrollUntilVisible(_key('session-cta-$title'), 300, scrollable: find.byType(Scrollable).first);
    await t.tap(_key('session-cta-$title'));
    await _settle(t);
    expect(find.text('Pay at the studio when you arrive. Nothing is charged in the app.'), findsOneWidget);
    await t.tap(_key('session-confirm'));
    await _settle(t);
    expect(AppState.instance.joinedSessions, contains(title));
    expect(find.text('Booked ✓'), findsNWidgets(2)); // badge + button on the card
    await t.tap(_key('session-cta-$title'));
    await _settle(t);
    expect(find.text('CANCEL THIS BOOKING?'), findsOneWidget);
    await t.tap(_key('session-cancel-confirm'));
    await _settle(t);
    expect(AppState.instance.joinedSessions, isEmpty);
    expect(find.text('Booked ✓'), findsNothing);

  });

  testWidgets('a caution session asks first', (t) async {
    AppState.instance.conditions = {'High BP'};
    const title = 'Power vinyasa flow';
    expect(_ranked(title).caution, isTrue);
    await _pump(t, const YogaScreen());
    await t.scrollUntilVisible(_key('session-cta-$title'), 300, scrollable: find.byType(Scrollable).first);
    await t.tap(_key('session-cta-$title'));
    await _settle(t);
    expect(find.textContaining('You noted: High BP.'), findsOneWidget);
    expect(_key('session-confirm'), findsNothing, reason: 'no booking before the user confirms');
    // "Not now" closes without booking.
    await t.tap(find.text('Not now'));
    await _settle(t);
    expect(AppState.instance.joinedSessions, isEmpty);
    // Going ahead leads to the normal confirm step.
    await t.tap(_key('session-cta-$title'));
    await _settle(t);
    await t.tap(_key('session-caution-continue'));
    await _settle(t);
    await t.tap(_key('session-confirm'));
    await _settle(t);
    expect(AppState.instance.joinedSessions, contains(title));

  });

  testWidgets('the detail of a caution session shows why', (t) async {
    AppState.instance.conditions = {'Heart condition'};
    await _pump(t, SessionScreen(ranked: _ranked('Surya Namaskar · 12 rounds')));
    expect(_key('session-caution-box'), findsOneWidget);
    expect(find.text('Ask your Vaidya first'), findsNWidgets(2)); // box + button
    await t.tap(_key('session-main'));
    await _settle(t);
    expect(find.textContaining('You noted: Heart condition.'), findsNWidgets(2)); // box + sheet
    await t.tap(_key('session-caution-continue'));
    await _settle(t);
    expect(find.byType(PracticeScreen), findsOneWidget);
  });

  testWidgets('practice counts down; next, previous, pause and finish work', (t) async {
    await _pump(t, const PracticeScreen(titleEn: 'Desk-break stretches'));
    String clock() => t.widget<Text>(_key('practice-clock')).data!;
    String name() => t.widget<Text>(_key('practice-name')).data!;
    expect(find.text('Step 1 of 8'), findsOneWidget);
    expect(name(), 'Settle and breathe');
    expect(clock(), '0:30');

    await t.tap(_key('practice-play'));
    await t.pump(const Duration(seconds: 3));
    expect(clock(), '0:27');
    await t.tap(_key('practice-play')); // pause

    expect(clock(), '0:27');

    await t.tap(_key('practice-next'));
    await t.pump();
    expect(name(), 'Neck turns');
    expect(clock(), '0:45');
    await t.tap(_key('practice-prev'));
    await t.pump();
    expect(name(), 'Settle and breathe');
    expect(clock(), '0:30');

    // Running out of time moves on by itself.
    await t.tap(_key('practice-play'));
    await t.pump(const Duration(seconds: 31));
    expect(name(), 'Neck turns');
    expect(find.text('Step 2 of 8'), findsOneWidget);

    await t.tap(_key('practice-finish'));
    await t.pump();
    expect(find.text('Well done'), findsOneWidget);
    await t.pump(const Duration(seconds: 3)); // the timer is stopped: nothing changes
    expect(find.text('Well done'), findsOneWidget);
    await t.tap(_key('practice-mark'));
    await t.pump();
    expect(AppState.instance.joinedSessions, contains('Desk-break stretches'));
    expect(_key('practice-marked'), findsOneWidget);
  });

  testWidgets('the last step finishes, and leaving mid-practice leaves no timer', (t) async {
    await _pump(t, const PracticeScreen(titleEn: 'Surya Namaskar · 12 rounds'));
    expect(find.text('Step 1 of 12'), findsOneWidget);
    await t.tap(_key('practice-play'));
    await t.pump(const Duration(seconds: 12 * 20 + 1));
    expect(find.text('Well done'), findsOneWidget);

    await t.tap(find.text('Do it again'));
    await t.pump();
    await t.tap(_key('practice-play'));
    await t.pump(const Duration(seconds: 2));
    // Dispose while the timer runs: dispose() must cancel it, or the test
    // fails with "A Timer is still pending".
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('the Yoga tab, detail, sheets and practice in English fit 390x844', (t) async {
    AppState.instance.conditions = {'High BP'};
    for (final mode in ['Near you', 'Online']) {
      await _pump(t, const YogaScreen());
      await t.tap(find.text(mode));
      await t.pump(const Duration(milliseconds: 200));
      for (final p in ['Free', 'Paid']) {
        await t.tap(find.descendant(of: find.byType(VvChip), matching: find.text(p)));
        await t.pump(const Duration(milliseconds: 200));
      }
    }
    for (final s in [...nearSessions, ...onlineSessions]) {
      await _pump(t, SessionScreen(ranked: _ranked(s.titleEn)));
      await _scrollDetail(t, s.titleEn);
    }
    for (final title in practices.keys) {
      await _pump(t, PracticeScreen(key: ValueKey(title), titleEn: title));
      for (var i = 0; i < practices[title]!.length; i++) {
        await t.tap(_key('practice-next'));
        await t.pump();
      }
      expect(find.text('Well done'), findsOneWidget);
    }
  });

  group('Hindi', () {
    setUp(() => Lang.notifier.value = Lang.hiCode);

    testWidgets('Yoga tab with booked and caution cards', (t) async {
      AppState.instance
        ..conditions = {'High BP'}
        ..joinedSessions = {'Sunrise Hatha by the lake', 'Desk-break stretches'};
      await _pump(t, const YogaScreen());
      for (var i = 0; i < 4; i++) {
        _noEnglish(t, 'near tab');
        await t.drag(find.byType(ListView).first, const Offset(0, -300));
        await t.pump(const Duration(milliseconds: 200));
      }
      await t.drag(find.byType(ListView).first, const Offset(0, 2000));
      await t.pump(const Duration(milliseconds: 200));
      await t.tap(find.text(tr('Online')));
      await t.pump(const Duration(milliseconds: 200));
      await t.drag(find.byType(ListView).first, const Offset(0, 2000));
      await t.pump(const Duration(milliseconds: 200));
      for (var i = 0; i < 4; i++) {
        _noEnglish(t, 'online tab');
        await t.drag(find.byType(ListView).first, const Offset(0, -300));
        await t.pump(const Duration(milliseconds: 200));
      }
    });

    testWidgets('every session detail', (t) async {
      AppState.instance.conditions = {'High BP', 'Heart condition'};
      for (final s in [...nearSessions, ...onlineSessions]) {
        await _pump(t, SessionScreen(ranked: _ranked(s.titleEn)));
        await _scrollDetail(t, s.titleEn, hindi: true);
      }
      AppState.instance.joinedSessions = {'Gentle spine & back therapy'};
      await _pump(t, SessionScreen(ranked: _ranked('Gentle spine & back therapy')));
      _noEnglish(t, 'booked detail');
    });

    testWidgets('booking, cancel and caution sheets', (t) async {
      await _pump(t, SessionScreen(ranked: _ranked('Shirodhara session')));
      await t.tap(_key('session-main'));
      await _settle(t);
      _noEnglish(t, 'booking sheet');
      await t.tap(_key('session-confirm'));
      await _settle(t);
      _noEnglish(t, 'booked detail');
      await t.tap(_key('session-cancel'));
      await _settle(t);
      _noEnglish(t, 'cancel sheet');
      await t.tap(_key('session-cancel-confirm'));
      await _settle(t);


      AppState.instance.conditions = {'High BP'};
      await _pump(t, SessionScreen(ranked: _ranked('Pranayama for acidity')));
      AppState.instance.conditions = {'Heart condition'};
      await _pump(t, SessionScreen(ranked: _ranked('Power vinyasa flow')));
      await t.tap(_key('session-main'));
      await _settle(t);
      expect(find.textContaining(tr('Heart condition')), findsNWidgets(2)); // box + sheet
      _noEnglish(t, 'caution sheet');
    });

    testWidgets('every practice step and the finish screen', (t) async {
      for (final title in practices.keys) {
        await _pump(t, PracticeScreen(key: ValueKey(title), titleEn: title));
        for (var i = 0; i < practices[title]!.length; i++) {
          _noEnglish(t, '$title step ${i + 1}');
          await t.tap(_key('practice-next'));
          await t.pump();
        }
        _noEnglish(t, '$title finished');
        if (title != 'Yoga Nidra for deep sleep') {
          await t.tap(_key('practice-mark'));
          await t.pump();
          _noEnglish(t, '$title marked');
        }
      }
    });
  });
}
