// Opens every screen with the app in Hindi at phone size (390x844). Fails on
// any exception (e.g. Hindi text overflowing) and on English text left on
// screen. Set VV_SHOTS=<dir> to also save PNG screenshots.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veda_verse/app_shell.dart';
import 'package:veda_verse/l10n/lang.dart';
import 'package:veda_verse/ml/dosha_predictor.dart';
import 'package:veda_verse/screens/booking_screen.dart';
import 'package:veda_verse/screens/consent_screen.dart';
import 'package:veda_verse/screens/health_summary_screen.dart';
import 'package:veda_verse/screens/help_screen.dart';
import 'package:veda_verse/screens/my_data_screen.dart';
import 'package:veda_verse/screens/intake_screen.dart';
import 'package:veda_verse/screens/login_screen.dart';
import 'package:veda_verse/screens/plans_screen.dart';
import 'package:veda_verse/screens/prakriti_quiz_screen.dart';
import 'package:veda_verse/screens/prakriti_result_screen.dart';
import 'package:veda_verse/screens/profile_menu_screen.dart';
import 'package:veda_verse/screens/program_screen.dart';
import 'package:veda_verse/screens/scan_screen.dart';
import 'package:veda_verse/screens/settings_screen.dart';
import 'package:veda_verse/screens/vaidya_screen.dart';
import 'package:veda_verse/screens/welcome_screen.dart';
import 'package:veda_verse/state/app_state.dart';
import 'package:veda_verse/theme/vv.dart';

final _shots = Platform.environment['VV_SHOTS'];

/// Words that stay in Latin letters in Hindi too: brand and product names,
/// people's names, lab test names, units, and the demo user's own entries.
/// Only add proper nouns, lab test names and units here, never ordinary words.
/// Longer entries first: each is removed in order before checking.
const allowedLatin = [
  'you@example.com', 'Google Pay', 'VedaVerse', 'Veda', 'Verse', 'Ayu Buddy', 'Gemini', 'Google', 'Tele-MANAS', 'MANAS',
  'Aarav', 'Mehta', 'Amlodipine', 'Peanuts', 'example.com', 'vedaverse.app',
  'Dr.', 'Rohan', 'Kapoor', 'Suresh', 'Paliwal', 'Meera', 'Sharma', 'Anjali', 'Nair', 'BAMS', 'PCOS', 'UPI', 'DPDP',
  'English', // the language's own name in the language switch
  'mg/dL', 'mIU/L', 'g/dL', 'mmol/L', 'pg/mL', 'ng/mL', 'HbA1c', 'TSH', 'Hemoglobin', 'Haemoglobin',
];

Future<void> _loadFonts() async {
  final romie = FontLoader('Romie');
  for (final f in ['Romie-300', 'Romie-300Italic', 'Romie-500', 'Romie-500Italic', 'Romie-700']) {
    romie.addFont(rootBundle.load('assets/fonts/$f.otf'));
  }
  await romie.load();
  final manrope = FontLoader('Manrope')..addFont(rootBundle.load('assets/fonts/Manrope-Variable.ttf'));
  await manrope.load();
}

/// Visible text that still has English words in it.
List<String> englishLeft(WidgetTester t) {
  final out = <String>{};
  for (final r in t.widgetList<RichText>(find.byType(RichText))) {
    var s = r.text.toPlainText();
    for (final a in allowedLatin) {
      s = s.replaceAll(a, ' ');
    }
    if (RegExp('[A-Za-z]{3,}').hasMatch(s)) out.add(r.text.toPlainText().replaceAll('\n', ' '));
  }
  return out.toList();
}

Future<void> _pump(WidgetTester tester, Widget screen, String name, {Future<void> Function()? act}) async {
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: Vv.theme(),
      home: RepaintBoundary(key: const ValueKey('shot'), child: screen),
    ),
  );
  await tester.pump(const Duration(milliseconds: 400));
  if (act != null) await act();
  await tester.pump(const Duration(milliseconds: 400));
  expect(tester.takeException(), isNull, reason: 'exception on $name (Hindi)');
  if (_shots != null) {
    final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('shot')));
    await tester.runAsync(() async {
      final img = await boundary.toImage(pixelRatio: 1);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      final dir = Directory(_shots!)..createSync(recursive: true);
      File('${dir.path}/hi_$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }
  expect(englishLeft(tester), isEmpty, reason: 'English text left on $name');
}

Future<void> _withQuiz() async {
  final m = await DoshaPredictor.load();
  AppState.instance
    ..prakritiAnswers = List.filled(m.nQuestions, 0)
    ..prediction = m.predict(List.filled(m.nQuestions, 0))
    ..vikritiAnswers = List.filled(m.vikritiQuestions.length, 1)
    ..vikritiLabels = [for (final q in m.vikritiQuestions) q.options];
  addTearDown(() => AppState.instance
    ..prediction = null
    ..prakritiAnswers = null
    ..vikritiAnswers = null);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadFonts();
  });

  setUp(() {
    Lang.notifier.value = Lang.hiCode;
    final v = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    v.physicalSize = const Size(390, 844);
    v.devicePixelRatio = 1;
  });
  tearDown(() => Lang.notifier.value = Lang.en);

  testWidgets('welcome', (t) => _pump(t, const WelcomeScreen(), 'welcome'));
  testWidgets('login', (t) => _pump(t, const LoginScreen(), 'login'));
  testWidgets('sign up', (t) => _pump(t, const LoginScreen(), 'signup', act: () async {
        await t.tap(find.text(tr('Create an account')));
        await t.pump(const Duration(milliseconds: 300));
      }));
  testWidgets('consent', (t) => _pump(t, const ConsentScreen(), 'consent'));
  for (var step = 0; step < 4; step++) {
    testWidgets('intake step ${step + 1}', (t) => _pump(t, const IntakeScreen(), 'intake_${step + 1}', act: () async {
          for (var i = 0; i < step; i++) {
            await t.tap(find.text(tr('Continue')));
            await t.pump(const Duration(milliseconds: 400));
          }
        }));
  }

  const tabs = ['home', 'learn', 'dosha', 'yoga', 'vaidya', 'buddy'];
  for (var i = 0; i < tabs.length; i++) {
    testWidgets('tab ${tabs[i]} before the quiz', (t) {
      AppState.instance.prediction = null;
      return _pump(t, AppShell(initialIndex: i), 'tab_${tabs[i]}');
    });
    testWidgets('tab ${tabs[i]} after the quiz', (t) async {
      await _withQuiz();
      await _pump(t, AppShell(initialIndex: i), 'tab_${tabs[i]}_quiz');
    });
  }

  testWidgets('buddy safety cards and offline answer', (t) => _pump(t, const AppShell(initialIndex: Tabs.buddy), 'buddy_cards', act: () async {
        // Typed in Hindi: the user's own words are never translated.
        for (final q in ['क्या मैं BP की गोली के साथ अश्वगंधा ले सकती हूँ?', 'मेरे सीने में दर्द है', 'रात के खाने में क्या खाऊँ?']) {
          await t.enterText(find.byType(TextField), q);
          await t.testTextInput.receiveAction(TextInputAction.send);
          await t.pump(const Duration(milliseconds: 300));
        }
      }));

  testWidgets('quiz first page', (t) => _pump(t, const PrakritiQuizScreen(), 'quiz', act: () async {
        await t.pump(const Duration(milliseconds: 300));
      }));
  testWidgets('quiz last page', (t) => _pump(t, const PrakritiQuizScreen(), 'quiz_last', act: () async {
        await t.pump(const Duration(milliseconds: 300));
        final m = await DoshaPredictor.load();
        final picks = [
          for (final q in m.questions) q.optionsHi?[0] ?? q.options[0],
          for (final q in m.vikritiQuestions) q.optionsHi?[1] ?? q.options[1],
        ];
        for (var page = 0; page < 7; page++) {
          for (final label in picks.sublist(page * 3, page * 3 + 3)) {
            final f = find.text(label);
            await t.ensureVisible(f);
            await t.tap(f);
            await t.pump(const Duration(milliseconds: 50));
          }
          await t.tap(find.text(tr('Next')));
          await t.pump(const Duration(milliseconds: 400));
        }
      }));
  testWidgets('result', (t) async {
    final m = await DoshaPredictor.load();
    final a = List.filled(m.nQuestions, 0);
    final p = m.predict(a);
    await _pump(t, PrakritiResultScreen(prediction: p, why: m.explain(a, p)), 'result');
  });
  testWidgets('result dual', (t) async {
    final m = await DoshaPredictor.load();
    final a = [...List.filled(9, 0), ...List.filled(9, 1)];
    final p = m.predict(a);
    await _pump(t, PrakritiResultScreen(prediction: p, why: m.explain(a, p)), 'result_dual');
  });
  testWidgets('profile', (t) => _pump(t, const ProfileMenuScreen(), 'profile'));
  testWidgets('settings', (t) => _pump(t, const SettingsScreen(), 'settings'));
  testWidgets('plans', (t) => _pump(t, const PlansScreen(), 'plans'));
  testWidgets('program', (t) => _pump(t, const ProgramScreen(), 'program'));
  testWidgets('booking', (t) => _pump(t, BookingScreen(vaidya: vaidyas.first), 'booking'));
  testWidgets('scan', (t) => _pump(t, const ScanScreen(), 'scan'));
  testWidgets('scan sample report', (t) async {
    AppState.instance.labReport = null;
    addTearDown(() => AppState.instance.labReport = null);
    await _pump(t, const ScanScreen(), 'scan_sample', act: () async {
      await t.tap(find.text(tr('See a sample report')));
      await t.pump(const Duration(milliseconds: 300));
    });
  });
  testWidgets('health summary', (t) async {
    await _withQuiz();
    await _pump(t, const HealthSummaryScreen(), 'health_summary', act: () async {
      await t.pump(const Duration(milliseconds: 500));
    });
  });
  testWidgets('help & safety', (t) => _pump(t, const HelpScreen(), 'help'));
  testWidgets('your data', (t) => _pump(t, const MyDataScreen(), 'my_data'));
  testWidgets('AI safety log', (t) => _pump(t, const AiHistoryScreen(), 'ai_log'));
}
