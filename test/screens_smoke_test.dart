// Pumps every screen at phone size (390x844) and fails on any exception,
// e.g. a RenderFlex overflow. Set VV_SHOTS=<dir> to also save PNG screenshots.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veda_verse/app_shell.dart';
import 'package:veda_verse/ml/dosha_predictor.dart';
import 'package:veda_verse/screens/booking_screen.dart';
import 'package:veda_verse/screens/consent_screen.dart';
import 'package:veda_verse/screens/health_summary_screen.dart';
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

Future<void> _loadFonts() async {
  final romie = FontLoader('Romie');
  for (final f in ['Romie-300', 'Romie-300Italic', 'Romie-500', 'Romie-500Italic', 'Romie-700']) {
    romie.addFont(rootBundle.load('assets/fonts/$f.otf'));
  }
  await romie.load();
  final manrope = FontLoader('Manrope')..addFont(rootBundle.load('assets/fonts/Manrope-Variable.ttf'));
  await manrope.load();
}

Future<void> _shot(WidgetTester tester, String name) async {
  if (_shots == null) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('shot')));
  await tester.runAsync(() async {
    final img = await boundary.toImage(pixelRatio: 1);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    final dir = Directory(_shots!)..createSync(recursive: true);
    File('${dir.path}/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
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
  expect(tester.takeException(), isNull, reason: 'exception on $name');
  await _shot(tester, name);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadFonts();
  });

  setUp(() {
    final v = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    if (Platform.environment['VV_SMALL'] != null) {
      // Narrow edge-to-edge Android phone: 360x797 dp with status and gesture bars.
      v.physicalSize = const Size(1080, 2392);
      v.devicePixelRatio = 3;
      v.padding = const FakeViewPadding(top: 96, bottom: 72);
      v.viewPadding = const FakeViewPadding(top: 96, bottom: 72);
    } else {
      // Phone frame used by the design file.
      v.physicalSize = const Size(390, 844);
      v.devicePixelRatio = 1;
    }
  });

  testWidgets('01 welcome', (t) => _pump(t, const WelcomeScreen(), '01_welcome'));
  testWidgets('02 login', (t) => _pump(t, const LoginScreen(), '02_login'));
  testWidgets('11 consent', (t) => _pump(t, const ConsentScreen(), '11_consent'));

  for (var step = 0; step < 4; step++) {
    testWidgets('03 intake step ${step + 1}', (t) => _pump(t, const IntakeScreen(), '03_intake_${step + 1}', act: () async {
          for (var i = 0; i < step; i++) {
            await t.tap(find.text('Continue'));
            await t.pump(const Duration(milliseconds: 400));
          }
        }));
  }

  testWidgets('new user sees 0% and no guessed dosha before the quiz', (t) async {
    AppState.instance.prediction = null;
    expect(AppState.instance.mix, {'Vata': 0, 'Pitta': 0, 'Kapha': 0});
    await _pump(t, const AppShell(initialIndex: Tabs.dosha), '06_dosha_new_user');
    expect(find.text('0%'), findsNWidgets(3));
    expect(find.text('Not checked yet', findRichText: true), findsOneWidget);
    expect(find.textContaining('Vata dominant', findRichText: true), findsNothing);
    expect(find.textContaining('Pitta is running high', findRichText: true), findsNothing);

    // After the quiz the real mix replaces the zeros.
    final m = await DoshaPredictor.load();
    AppState.instance.update((s) => s.prediction = m.predict(List.filled(m.nQuestions, 0)));
    await t.pump();
    expect(find.text('0%'), findsNothing);
    expect(find.text('Vata dominant', findRichText: true), findsOneWidget);
    AppState.instance.prediction = null;
  });

  testWidgets('full quiz: 24 questions, shuffled options, Prakriti + Vikriti result', (t) async {
    AppState.instance
      ..prediction = null
      ..vikritiAnswers = null;
    final m = await DoshaPredictor.load();
    await _pump(t, const PrakritiQuizScreen(), '12_quiz_flow');
    expect(find.text('0/24'), findsOneWidget);

    // Lifelong answers: always the Vata option. Last 2 weeks: always Pitta.
    final picks = [
      for (final q in m.questions) q.options[0],
      for (final q in m.vikritiQuestions) q.options[1],
    ];
    for (var page = 0; page < 8; page++) {
      for (final label in picks.sublist(page * 3, page * 3 + 3)) {
        final f = find.text(label);
        await t.ensureVisible(f);
        await t.tap(f);
        await t.pump(const Duration(milliseconds: 50));
      }
      await t.tap(find.text(page == 7 ? 'See my Prakriti' : 'Next'));
      await t.pump(const Duration(milliseconds: 400));
    }
    await t.pump(const Duration(milliseconds: 400));

    final s = AppState.instance;
    expect(s.prediction?.type, 'Vata', reason: 'the model sees only the 18 lifelong answers');
    expect(s.vikriti?.raised, 'Pitta', reason: 'last-2-weeks answers are scored separately');
    expect(find.textContaining('Pitta is raised', findRichText: true), findsOneWidget);
    expect(t.takeException(), isNull);
    s
      ..prediction = null
      ..vikritiAnswers = null;
  });

  testWidgets('quiz options are not always shown in Vata, Pitta, Kapha order', (t) async {
    final m = await DoshaPredictor.load();
    await _pump(t, const PrakritiQuizScreen(), '12_quiz_order');
    var reordered = 0;
    for (final q in m.questions.take(3)) {
      final ys = [for (final o in q.options) t.getTopLeft(find.text(o)).dy];
      final xs = [for (final o in q.options) t.getTopLeft(find.text(o)).dx];
      final sameRow = ys.every((y) => (y - ys.first).abs() < 40);
      if (sameRow && !(xs[0] < xs[1] && xs[1] < xs[2])) reordered++;
    }
    expect(reordered, greaterThan(0));
  });

  const tabs = ['04_home', '05_learn', '06_dosha', '08_yoga', '09_vaidya', '07_buddy'];
  for (var i = 0; i < tabs.length; i++) {
    testWidgets('tab ${tabs[i]}', (t) => _pump(t, AppShell(initialIndex: i), tabs[i]));
  }
  for (var i = 0; i < Tabs.buddy; i++) {
    testWidgets('floating button opens Ayu Buddy from ${tabs[i]}', (t) async {
      await _pump(t, AppShell(initialIndex: i), 'fab_${tabs[i]}', act: () async {
        await t.tap(find.byType(BuddyFab), warnIfMissed: true);
      });
      expect(t.state<AppShellState>(find.byType(AppShell)).index, Tabs.buddy);
      expect(find.byType(BuddyFab), findsNothing);
    });
  }
  testWidgets('07 buddy: chat and voice are one screen', (t) async {
    await _pump(t, const AppShell(initialIndex: Tabs.buddy), '07_buddy_voice', act: () async {
      expect(find.text('Chat'), findsNothing);
      expect(find.text('Voice'), findsNothing);
      await t.tap(find.bySemanticsLabel('Speak'));
      await t.pump(const Duration(seconds: 9)); // start-up gives up after its time limits
    });
    // No speech service in tests, so the voice bar explains instead of failing.
    expect(find.text('Voice isn’t available here. Please type instead.'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget, reason: 'typing still works');
  });
  testWidgets('14 scan: sample report without a Gemini key', (t) async {
    AppState.instance.labReport = null;
    await _pump(t, const ScanScreen(), '14_scan_sample', act: () async {
      await t.tap(find.text('See a sample report'));
      await t.pump(const Duration(milliseconds: 300));
    });
    expect(find.text('SAMPLE'), findsOneWidget);
    expect(find.textContaining('2 values are outside the printed range', findRichText: true), findsOneWidget);
    AppState.instance.labReport = null;
  });
  testWidgets('health summary for the Vaidya', (t) async {
    await _pump(t, const HealthSummaryScreen(), 'health_summary', act: () async {
      await t.pump(const Duration(milliseconds: 500));
    });
    expect(find.text('Health and safety'.toUpperCase()), findsOneWidget);
    expect(find.textContaining('Amlodipine'), findsWidgets);
  });
  testWidgets('07 buddy guardrail', (t) => _pump(t, const AppShell(initialIndex: Tabs.buddy), '07_buddy_guardrail', act: () async {
        await t.enterText(find.byType(TextField), 'Can I take ashwagandha with my BP tablet?');
        await t.testTextInput.receiveAction(TextInputAction.send);
        await t.pump(const Duration(milliseconds: 300));
        await t.enterText(find.byType(TextField), 'I have chest pain');
        await t.testTextInput.receiveAction(TextInputAction.send);
      }));

  testWidgets('10 profile', (t) => _pump(t, const ProfileMenuScreen(), '10_profile'));
  testWidgets('12 quiz', (t) => _pump(t, const PrakritiQuizScreen(), '12_quiz', act: () async {
        await t.pump(const Duration(milliseconds: 300));
        await t.tap(find.text('Slim and light, my bones show'));
        await t.pump(const Duration(milliseconds: 200));
      }));
  testWidgets('13 result', (t) async {
    final m = await DoshaPredictor.load();
    final p = m.predict(List.filled(m.nQuestions, 0));
    await _pump(t, PrakritiResultScreen(prediction: p, why: m.explain(List.filled(m.nQuestions, 0), p)), '13_result');
  });
  testWidgets('13 result dual', (t) async {
    final m = await DoshaPredictor.load();
    final p = m.predict([...List.filled(9, 0), ...List.filled(9, 1)]);
    await _pump(t, PrakritiResultScreen(prediction: p, why: m.explain([...List.filled(9, 0), ...List.filled(9, 1)], p)), '13_result_dual');
  });
  testWidgets('14 scan', (t) => _pump(t, const ScanScreen(), '14_scan'));
  testWidgets('15 booking', (t) => _pump(t, BookingScreen(vaidya: vaidyas.first), '15_booking'));
  testWidgets('16 plans', (t) => _pump(t, const PlansScreen(), '16_plans'));
  testWidgets('17 settings', (t) => _pump(t, const SettingsScreen(), '17_settings'));
  testWidgets('19 program', (t) => _pump(t, const ProgramScreen(), '19_program'));
}
