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
  testWidgets('07 buddy voice', (t) => _pump(t, const AppShell(initialIndex: Tabs.buddy), '07_buddy_voice', act: () async {
        await t.tap(find.text('Voice'));
      }));
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
        await t.tap(find.text('Thin/Lanky'));
        await t.pump(const Duration(milliseconds: 200));
      }));
  testWidgets('13 result', (t) async {
    final m = await DoshaPredictor.load();
    final p = m.predict(List.filled(30, 0));
    await _pump(t, PrakritiResultScreen(prediction: p), '13_result');
  });
  testWidgets('13 result dual', (t) async {
    final m = await DoshaPredictor.load();
    final p = m.predict([...List.filled(15, 0), ...List.filled(15, 1)]);
    await _pump(t, PrakritiResultScreen(prediction: p), '13_result_dual');
  });
  testWidgets('14 scan', (t) => _pump(t, const ScanScreen(), '14_scan'));
  testWidgets('15 booking', (t) => _pump(t, BookingScreen(vaidya: vaidyas.first), '15_booking'));
  testWidgets('16 plans', (t) => _pump(t, const PlansScreen(), '16_plans'));
  testWidgets('17 settings', (t) => _pump(t, const SettingsScreen(), '17_settings'));
  testWidgets('19 program', (t) => _pump(t, const ProgramScreen(), '19_program'));
}
