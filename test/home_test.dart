// Home, Dosha tab, 12-week program and Prakriti result: no made-up personal
// data for a new account, every tappable element goes somewhere, and the
// Hindi versions have no English left and no overflow at 390x844.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veda_verse/app_shell.dart';
import 'package:veda_verse/l10n/lang.dart';
import 'package:veda_verse/ml/dosha_predictor.dart';
import 'package:veda_verse/screens/prakriti_quiz_screen.dart';
import 'package:veda_verse/screens/prakriti_result_screen.dart';
import 'package:veda_verse/screens/profile_menu_screen.dart';
import 'package:veda_verse/screens/program_screen.dart';
import 'package:veda_verse/state/app_state.dart';
import 'package:veda_verse/theme/vv.dart';

/// Latin words allowed in Hindi: names, brands, units (same idea as
/// test/screens_hindi_test.dart).
const _allowedLatin = [
  'you@example.com', 'Google Pay', 'VedaVerse', 'Veda', 'Verse', 'Ayu Buddy', 'Gemini', 'Google', 'Tele-MANAS', 'MANAS',
  'Aarav', 'Mehta', 'Amlodipine', 'Peanuts', 'example.com', 'vedaverse.app',
  'Dr.', 'Rohan', 'Kapoor', 'Suresh', 'Paliwal', 'Meera', 'Sharma', 'Anjali', 'Nair', 'BAMS', 'PCOS', 'UPI', 'DPDP',
  'English',
  'mg/dL', 'mIU/L', 'g/dL', 'mmol/L', 'pg/mL', 'ng/mL', 'HbA1c', 'TSH', 'Hemoglobin', 'Haemoglobin',
];

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

/// A brand-new account: nothing done yet.
void _newAccount() {
  AppState.instance
    ..name = 'Aarav Mehta'
    ..gender = 'Female'
    ..prediction = null
    ..prakritiAnswers = null
    ..vikritiAnswers = null
    ..bookings = []
    ..joinedSessions = {}
    ..savedArticles = {}
    ..dinacharyaDone = {}
    ..doneDate = ''
    ..streak = 0;
}

Future<void> _withQuiz() async {
  final m = await DoshaPredictor.load();
  AppState.instance
    ..prakritiAnswers = List.filled(m.nQuestions, 0)
    ..prediction = m.predict(List.filled(m.nQuestions, 0))
    ..vikritiAnswers = List.filled(m.vikritiQuestions.length, 1)
    ..vikritiLabels = [for (final q in m.vikritiQuestions) q.options];
}

Booking _tomorrowConsult() {
  final t = DateTime.now().add(const Duration(days: 1));
  return Booking(vaidya: 'Dr. Rohan Kapoor', when: DateTime(t.year, t.month, t.day, 10, 30), mode: 'Video');
}

Future<void> _pump(WidgetTester t, Widget screen) async {
  await t.pumpWidget(const SizedBox()); // drop any routes from a previous pump
  await t.pumpWidget(MaterialApp(theme: Vv.theme(), home: screen));
  await t.pump(const Duration(milliseconds: 400));
  expect(t.takeException(), isNull);
}

int _tab(WidgetTester t) => t.state<AppShellState>(find.byType(AppShell)).index;

/// Lets a pushed route finish its transition (its first frame is offstage).
Future<void> _settle(WidgetTester t) async {
  await t.pump();
  await t.pump(const Duration(milliseconds: 400));
}

/// Scrolls the screen's main list until [key] is built, then taps it.
Future<void> _tapKey(WidgetTester t, String key) async {
  final f = find.byKey(ValueKey(key));
  await t.scrollUntilVisible(f, 250, scrollable: find.byType(Scrollable).first);
  await t.ensureVisible(f);
  await t.pump();
  await t.tap(f, warnIfMissed: true);
  await _settle(t);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_loadFonts);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ProgramProgress.instance.debugReset();
    _newAccount();
    final v = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    v.physicalSize = const Size(390, 844);
    v.devicePixelRatio = 1;
  });
  tearDown(() {
    Lang.notifier.value = Lang.en;
    _newAccount();
  });

  group('Home', () {
    testWidgets('a new account sees no made-up plan and is sent to the quiz', (t) async {
      await _pump(t, const AppShell());
      expect(find.textContaining('Rohan'), findsNothing, reason: 'no Vaidya plan without a booking');
      expect(find.textContaining('follow-up in 14 days'), findsNothing);
      expect(find.text('START YOUR STREAK TODAY'), findsOneWidget);
      expect(find.textContaining('DAY STREAK'), findsNothing);
      expect(find.text('0 of 5 done'), findsOneWidget);
      expect(find.text('Find your Prakriti'), findsOneWidget);
      await _tapKey(t, 'home-next');
      expect(find.byType(PrakritiQuizScreen), findsOneWidget);
    });

    testWidgets('with a booking the upcoming consult shows and opens the Vaidya tab', (t) async {
      AppState.instance
        ..bookings = [_tomorrowConsult()]
        ..streak = 3;
      await _pump(t, const AppShell());
      expect(find.text('Consult with Dr. Rohan Kapoor'), findsOneWidget);
      expect(find.text('Tomorrow, 10:30 am · Video'), findsOneWidget);
      expect(find.text('3-DAY STREAK'), findsOneWidget);
      expect(find.text('1 of 5 done'), findsOneWidget, reason: 'the Vaidya step is done');
      await _tapKey(t, 'home-next');
      expect(_tab(t), Tabs.vaidya);
    });

    testWidgets('after the quiz, with no booking, it suggests a Vaidya', (t) async {
      await _withQuiz();
      await _pump(t, const AppShell());
      expect(find.text('Talk to a Vaidya'), findsOneWidget);
      expect(find.text('Find your Prakriti'), findsNothing);
      await _tapKey(t, 'home-next');
      expect(_tab(t), Tabs.vaidya);
    });

    testWidgets('a past consult offers a follow-up', (t) async {
      await _withQuiz();
      AppState.instance.bookings = [Booking(vaidya: 'Dr. Anjali Nair', when: DateTime(2026, 3, 4, 9), mode: 'Phone')];
      await _pump(t, const AppShell());
      expect(find.text('Consult with Dr. Anjali Nair'), findsOneWidget);
      expect(find.text('Done on 4 Mar · book a follow-up'), findsOneWidget);
    });

    testWidgets('path steps reflect real progress', (t) async {
      await _withQuiz();
      AppState.instance
        ..joinedSessions = {'Morning Hatha'}
        ..toggleDone('x');
      await _pump(t, const AppShell());
      expect(find.text('3 of 5 done'), findsOneWidget);
    });

    final tabTaps = {
      'home-today': Tabs.dosha,
      'home-tile-Learn': Tabs.learn,
      'home-tile-Dosha': Tabs.dosha,
      'home-tile-Yoga': Tabs.yoga,
      'home-tile-Vaidya': Tabs.vaidya,
      'home-buddy': Tabs.buddy,
      'home-path-Plan': Tabs.dosha,
      'home-path-Learn': Tabs.learn,
      'home-path-Yoga': Tabs.yoga,
      'home-path-Vaidya': Tabs.vaidya,
      'home-explore': Tabs.learn,
      'home-story-0': Tabs.learn,
    };
    tabTaps.forEach((key, tab) {
      testWidgets('$key opens tab $tab', (t) async {
        await _pump(t, const AppShell());
        await _tapKey(t, key);
        expect(_tab(t), tab);
      });
    });

    testWidgets('path Quiz step opens the quiz before it is done, the Dosha tab after', (t) async {
      await _pump(t, const AppShell());
      await _tapKey(t, 'home-path-Quiz');
      expect(find.byType(PrakritiQuizScreen), findsOneWidget);

      await _withQuiz();
      await _pump(t, const AppShell());
      await _tapKey(t, 'home-path-Quiz');
      expect(_tab(t), Tabs.dosha);
    });

    testWidgets('avatar opens the profile', (t) async {
      await _pump(t, const AppShell());
      await t.tap(find.byType(VvAvatar).first);
      await _settle(t);
      expect(find.byType(ProfileMenuScreen), findsOneWidget);
    });

    testWidgets('journal arrows move the stories', (t) async {
      await _pump(t, const AppShell());
      final first = find.textContaining('how to eat and live this season');
      await t.scrollUntilVisible(first, 250, scrollable: find.byType(Scrollable).first);
      expect(first, findsOneWidget);
      await _tapKey(t, 'home-story-next');
      expect(first, findsNothing);
      expect(find.textContaining('Veda Letter #12'), findsOneWidget);
      await _tapKey(t, 'home-story-prev');
      expect(first, findsOneWidget);
    });

    testWidgets('share copies the shloka and says so', (t) async {
      String? copied;
      t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String?;
        return null;
      });
      addTearDown(() => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
      await _pump(t, const AppShell());
      await _tapKey(t, 'home-share');
      expect(copied, contains('स्वस्थस्य'));
      expect(find.textContaining('Copied.'), findsOneWidget);
    });
  });

  group('Dosha tab', () {
    testWidgets('a new account: no streak badge, card opens the quiz, program not started', (t) async {
      await _pump(t, const AppShell(initialIndex: Tabs.dosha));
      expect(find.text('0 days'), findsNothing);
      expect(find.text('Updated today'), findsNothing);
      expect(find.textContaining('Week 3 of 12', findRichText: true), findsNothing);
      expect(find.textContaining('12 weeks', findRichText: true), findsOneWidget);
      await t.tap(find.text('Not checked yet', findRichText: true));
      await _settle(t);
      expect(find.byType(PrakritiQuizScreen), findsOneWidget);
    });

    testWidgets('program card shows the real week and opens the program', (t) async {
      await ProgramProgress.instance.ensureLoaded();
      ProgramProgress.instance.start = DateTime.now().subtract(const Duration(days: 16));
      AppState.instance.streak = 5;
      await _pump(t, const AppShell(initialIndex: Tabs.dosha));
      expect(find.text('5 days'), findsOneWidget);
      final card = find.textContaining('Week 3 of 12', findRichText: true);
      expect(card, findsOneWidget);
      await t.ensureVisible(card);
      await t.tap(card);
      await _settle(t);
      expect(find.byType(ProgramScreen), findsOneWidget);
      expect(find.text('WEEK 3 OF 12 · DAY 3'), findsOneWidget);
    });

    testWidgets('men do not see the PCOS program', (t) async {
      AppState.instance.gender = 'Male';
      await _pump(t, const AppShell(initialIndex: Tabs.dosha));
      expect(find.text('LIFESTYLE PROGRAM'), findsNothing);
    });
  });

  group('Program', () {
    testWidgets('starts blank at week 1 day 1 and every control works', (t) async {
      await _pump(t, const ProgramScreen());
      Future<void> show(Finder f, {bool up = false}) =>
          t.scrollUntilVisible(f, up ? -200 : 200, scrollable: find.byType(Scrollable).first);
      expect(find.text('WEEK 1 OF 12 · DAY 1'), findsOneWidget);
      expect(find.text('Ready to begin?', findRichText: true), findsOneWidget);
      expect(find.text('0/5 today'), findsOneWidget);
      await show(find.text('Not started yet'));
      await show(find.text('No signs selected'));
      for (final fake in ['84 cm', '6.8 h', '3 / 5', 'Logged at 2 pm', '9 days']) {
        expect(find.text(fake), findsNothing);
      }

      await show(find.text('Start the program'), up: true);
      await t.tap(find.text('Start the program'));
      await t.pump();
      expect(find.text('This week: notice your patterns', findRichText: true), findsOneWidget);

      await t.tap(find.text('Breakfast by 9 am'));
      await t.pump();
      expect(find.text('1/5 today'), findsOneWidget);

      final log = find.text('Log period started today');
      await show(log);
      await t.tap(log);
      await t.pump();
      expect(find.text('Logged today ✓ · tap to undo'), findsOneWidget);
      expect(find.textContaining('Last period:'), findsOneWidget);

      await show(find.text('1 / 84'));
      final sign = find.text('Acne after age 20');
      await show(sign);
      await t.tap(sign);
      await t.pump();
      expect(find.text('1 sign noted'), findsOneWidget);

      // Saved for this account.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('vv.program'), contains('"signs":[3]'));

      final vaidya = find.text('Talk to a Vaidya or doctor');
      await show(vaidya);
      await t.tap(vaidya);
      await _settle(t);
      expect(_tab(t), Tabs.vaidya);
    });

    testWidgets('cycle chart and average come from logged periods', (t) async {
      await ProgramProgress.instance.ensureLoaded();
      final now = DateTime.now();
      ProgramProgress.instance
        ..start = now.subtract(const Duration(days: 60))
        ..periods = [now.subtract(const Duration(days: 60)), now.subtract(const Duration(days: 30)), now];
      await _pump(t, const ProgramScreen());
      expect(find.text('WEEK 9 OF 12 · DAY 5'), findsOneWidget);
      await t.scrollUntilVisible(find.text('Logged today ✓ · tap to undo'), 200, scrollable: find.byType(Scrollable).first);
      expect(find.text('30'), findsNWidgets(2), reason: 'two 30-day cycles in the chart');
      await t.scrollUntilVisible(find.text('Average cycle'), 200, scrollable: find.byType(Scrollable).first);
      expect(find.text('30 days'), findsOneWidget, reason: 'average cycle tile');
    });
  });

  testWidgets('result: Confirm with a Vaidya opens the Vaidya list', (t) async {
    final m = await DoshaPredictor.load();
    final p = m.predict(List.filled(m.nQuestions, 0));
    await _pump(t, PrakritiResultScreen(prediction: p));
    expect(t.getSize(find.byKey(const ValueKey('result-vaidya'))).height, greaterThanOrEqualTo(44));
    await t.tap(find.byKey(const ValueKey('result-vaidya')));
    await _settle(t);
    expect(_tab(t), Tabs.vaidya);
  });

  group('Hindi', () {
    setUp(() => Lang.notifier.value = Lang.hiCode);

    Future<void> check(WidgetTester t, Widget screen, String name) async {
      await _pump(t, screen);
      expect(t.takeException(), isNull, reason: 'overflow on $name');
      expect(_englishLeft(t), isEmpty, reason: 'English left on $name');
    }

    testWidgets('home, new account', (t) => check(t, const AppShell(), 'home'));
    testWidgets('home, with a consult and the quiz', (t) async {
      await _withQuiz();
      AppState.instance
        ..bookings = [_tomorrowConsult()]
        ..streak = 4;
      await check(t, const AppShell(), 'home booked');
      expect(find.text('कल, सुबह 10:30 · वीडियो'), findsOneWidget);
    });
    testWidgets('home, after a share', (t) async {
      t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
      addTearDown(() => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
      await _pump(t, const AppShell());
      await _tapKey(t, 'home-share');
      expect(_englishLeft(t), isEmpty);
    });
    testWidgets('dosha, new account', (t) => check(t, const AppShell(initialIndex: Tabs.dosha), 'dosha'));
    testWidgets('dosha, program started', (t) async {
      await ProgramProgress.instance.ensureLoaded();
      ProgramProgress.instance.start = DateTime.now().subtract(const Duration(days: 20));
      AppState.instance.streak = 2;
      await check(t, const AppShell(initialIndex: Tabs.dosha), 'dosha program');
    });
    testWidgets('program, not started', (t) => check(t, const ProgramScreen(), 'program'));
    testWidgets('program, with logs', (t) async {
      await ProgramProgress.instance.ensureLoaded();
      final now = DateTime.now();
      ProgramProgress.instance
        ..start = now.subtract(const Duration(days: 80))
        ..periods = [now.subtract(const Duration(days: 80)), now.subtract(const Duration(days: 40)), now]
        ..signs = {0, 2}
        ..ticks = {AppState.dayKey(now): {0, 1, 2}};
      await check(t, const ProgramScreen(), 'program logs');
      for (final y in [0.0, 400, 800, 1200]) {
        await t.drag(find.byType(ListView).first, Offset(0, -y.toDouble()));
        await t.pump();
        expect(t.takeException(), isNull);
        expect(_englishLeft(t), isEmpty);
      }
    });
    testWidgets('result', (t) async {
      final m = await DoshaPredictor.load();
      await check(t, PrakritiResultScreen(prediction: m.predict(List.filled(m.nQuestions, 0))), 'result');
    });
  });
}
