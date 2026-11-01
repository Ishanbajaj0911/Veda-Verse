import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veda_verse/app_shell.dart';
import 'package:veda_verse/l10n/lang.dart';
import 'package:veda_verse/main.dart';
import 'package:veda_verse/ml/dosha_predictor.dart';
import 'package:veda_verse/screens/consent_screen.dart';
import 'package:veda_verse/screens/intake_screen.dart';
import 'package:veda_verse/screens/login_screen.dart';
import 'package:veda_verse/state/accounts.dart';
import 'package:veda_verse/state/app_state.dart';
import 'package:veda_verse/theme/vv.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final s = AppState.instance;
  late DoshaPredictor model;

  setUpAll(() {
    Accounts.attach(s); // saves on every change, as in the app
    model = DoshaPredictor.fromJson(
        jsonDecode(File('assets/ml/dosha_model.json').readAsStringSync()) as Map<String, dynamic>);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    if (Accounts.current != null) await Accounts.logOut();
    Lang.notifier.value = Lang.en;
  });

  group('accounts', () {
    test('sign up gives a unique id and a blank profile', () async {
      s.issues = {'Can’t sleep'}; // picked on the welcome screen
      expect(await Accounts.signUp('Asha@Example.com ', 'secret1', confirm: 'secret1'), isNull);
      final a = Accounts.current!;
      expect(a.id, matches(RegExp(r'^VV-[0-9A-F]{8}$')));
      expect(a.email, 'asha@example.com');
      expect(s.accountId, a.id);
      expect(s.name, isEmpty);
      expect(s.age, 0);
      expect(s.gender, isEmpty);
      expect(s.medicines, isEmpty);
      expect(s.prediction, isNull);
      expect(s.onboarded, isFalse);
      expect(s.issues, {'Can’t sleep'}, reason: 'welcome picks pre-fill "Your story"');

      await Accounts.logOut();
      expect(await Accounts.signUp('ravi@example.com', 'secret2'), isNull);
      expect(Accounts.current!.id, isNot(a.id));
      expect((await Accounts.all()).length, 2);
    });

    test('sign up and log in check their inputs', () async {
      expect(await Accounts.signUp('not-an-email', 'secret1'), Accounts.errEmail);
      expect(await Accounts.signUp('a@b.co', '123'), Accounts.errPassword);
      expect(await Accounts.signUp('a@b.co', 'secret1', confirm: 'secret2'), Accounts.errMismatch);
      expect(await Accounts.signUp('a@b.co', 'secret1'), isNull);
      await Accounts.logOut();
      expect(await Accounts.signUp('A@B.co', 'other12'), Accounts.errExists);
      expect(await Accounts.logIn('x@b.co', 'secret1'), Accounts.errNoAccount);
      expect(await Accounts.logIn('a@b.co', 'wrong12'), Accounts.errWrongPassword);
      expect(Accounts.current, isNull);
      expect(await Accounts.logIn('a@b.co', 'secret1'), isNull);
    });

    test('the password itself is never stored', () async {
      await Accounts.signUp('a@b.co', 'MySecret99');
      final prefs = await SharedPreferences.getInstance();
      final all = prefs.getKeys().map((k) => '${prefs.get(k)}').join(' ');
      expect(all, isNot(contains('MySecret99')));
    });

    test('each account keeps its own profile and quiz result', () async {
      await Accounts.signUp('asha@example.com', 'secret1');
      final ashaId = Accounts.current!.id;
      final answers = List.filled(model.nQuestions, 2);
      s.update((st) {
        st.name = 'Asha Rao';
        st.age = 31;
        st.gender = 'Female';
        st.medicines = ['Metformin'];
        st.prakritiAnswers = answers;
        st.prediction = model.predict(answers);
      });
      await Accounts.finishOnboarding();
      await Accounts.logOut();
      expect(s.name, isEmpty, reason: 'nothing of Asha stays on screen after log out');
      expect(s.prediction, isNull);

      await Accounts.signUp('ravi@example.com', 'secret2');
      expect(s.name, isEmpty, reason: 'Ravi does not see Asha');
      expect(s.prediction, isNull);
      s.update((st) => st.name = 'Ravi');
      await Accounts.logOut();

      expect(await Accounts.logIn('asha@example.com', 'secret1'), isNull);
      expect(s.accountId, ashaId);
      expect(s.name, 'Asha Rao');
      expect(s.age, 31);
      expect(s.medicines, ['Metformin']);
      expect(s.onboarded, isTrue);
      await DoshaPredictor.load(); // QuizStore restores with the bundled model
      expect(s.prakritiAnswers, answers);
      expect(s.prediction?.type, model.predict(answers).type);
    });

    test('the last account opens again at start-up', () async {
      await Accounts.signUp('asha@example.com', 'secret1');
      s.update((st) => st.name = 'Asha');
      expect(await Accounts.restoreSession(), isFalse, reason: 'not onboarded yet');
      await Accounts.finishOnboarding();
      expect(await Accounts.restoreSession(), isTrue);
      expect(s.name, 'Asha');
      await Accounts.logOut();
      expect(await Accounts.restoreSession(), isFalse);
    });
  });

  group('more account data', () {
    test('bookings, saved articles and yoga sessions stay with their account', () async {
      await Accounts.signUp('asha@example.com', 'secret1');
      final when = DateTime(2030, 1, 2, 18, 30);
      s.update((st) {
        st.bookings.add(Booking(vaidya: 'Dr. Rohan Kapoor', when: when, mode: 'Video'));
        st.savedArticles.add('agni');
        st.joinedSessions.add('Desk-break stretches');
      });
      await Accounts.logOut();
      expect(s.bookings, isEmpty);
      await Accounts.signUp('ravi@example.com', 'secret2');
      expect(s.bookings, isEmpty, reason: 'Ravi sees none of Asha’s bookings');
      await Accounts.logOut();
      await Accounts.logIn('asha@example.com', 'secret1');
      expect(s.bookings.single.vaidya, 'Dr. Rohan Kapoor');
      expect(s.bookings.single.when, when);
      expect(s.upcoming, hasLength(1));
      expect(s.savedArticles, {'agni'});
      expect(s.joinedSessions, {'Desk-break stretches'});
    });

    test('delete removes the account and everything saved under it', () async {
      await Accounts.signUp('asha@example.com', 'secret1');
      final id = Accounts.current!.id;
      s.update((st) => st.name = 'Asha');
      await Accounts.signUp('x@example.com', 'secret1').then((_) => Accounts.logOut());
      await Accounts.logIn('asha@example.com', 'secret1');
      await Accounts.deleteCurrent();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys().where((k) => k.contains(id)), isEmpty);
      expect(await Accounts.logIn('asha@example.com', 'secret1'), Accounts.errNoAccount);
      expect((await Accounts.all()).map((a) => a.email), ['x@example.com'], reason: 'other accounts stay');
      expect(await Accounts.restoreSession(), isFalse);
      expect(s.name, isEmpty);
    });
  });

  group('screens', () {
    Future<void> pump(WidgetTester t, Widget w) async {
      final v = t.platformDispatcher.views.first;
      v.physicalSize = const Size(390, 844);
      v.devicePixelRatio = 1;
      addTearDown(v.reset);
      await t.pumpWidget(MaterialApp(theme: Vv.theme(), home: w));
      await t.pump();
    }

    testWidgets('login needs an email and password, then sign up opens consent', (t) async {
      await pump(t, const LoginScreen());
      await t.ensureVisible(find.text('Log in').last);
      await t.tap(find.text('Log in').last);
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await t.pump();
      expect(find.text(Accounts.errEmail), findsOneWidget);
      expect(find.byType(ConsentScreen), findsNothing);

      await t.ensureVisible(find.text('Create an account'));
      await t.tap(find.text('Create an account'));
      await t.pump();
      final fields = find.byType(TextField);
      await t.enterText(fields.at(0), 'new@example.com');
      await t.enterText(fields.at(1), 'secret1');
      await t.enterText(fields.at(2), 'secret1');
      await t.ensureVisible(find.text('Create account'));
      await t.tap(find.text('Create account'));
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      await t.pumpAndSettle();
      expect(find.byType(ConsentScreen), findsOneWidget);
      expect(Accounts.current?.email, 'new@example.com');
    });

    testWidgets('consent needs the 18+ box ticked', (t) async {
      await pump(t, const ConsentScreen());
      await t.tap(find.text('I agree, continue'));
      await t.pumpAndSettle(); // scrolls to the 18+ box
      expect(find.text('Tick the 18+ box first'), findsOneWidget);
      expect(find.text('Please tick this box to continue.', skipOffstage: false), findsOneWidget);
      expect(find.byType(IntakeScreen), findsNothing);
      await t.tap(find.byType(Checkbox));
      await t.pumpAndSettle();

      await t.tap(find.text('I agree, continue'));
      await t.pumpAndSettle();
      expect(find.byType(IntakeScreen), findsOneWidget);
    });

    testWidgets('every intake step must be answered before moving on', (t) async {
      await t.runAsync(() => Accounts.signUp('new@example.com', 'secret1'));
      s.issues = {};
      await pump(t, const IntakeScreen());
      Future<void> next() async {
        await t.tap(find.byType(VvButton).first);
        await t.pumpAndSettle();
      }
      Future<void> tapText(String s) async {
        await t.ensureVisible(find.text(s));
        await t.pumpAndSettle();
        await t.tap(find.text(s));
        await t.pump();
      }


      // Step 1: nothing filled in.
      await next();
      expect(find.text('Please enter your name'), findsOneWidget);
      expect(find.text('Enter your age in years (1–120)'), findsOneWidget);
      expect(find.text('Please choose one'), findsOneWidget);
      expect(find.text('1/4'), findsOneWidget);
      await t.enterText(find.byType(TextField).at(0), 'Meera');
      await t.enterText(find.byType(TextField).at(1), '200');
      await tapText('Female');
      await next();
      expect(find.text('Enter your age in years (1–120)'), findsOneWidget);
      await t.enterText(find.byType(TextField).at(1), '29');
      await next();
      expect(find.text('2/4'), findsOneWidget);

      // Step 2: a concern and "since when".
      await next();
      expect(find.text('Pick at least one'), findsOneWidget);
      expect(find.text('Please choose how long'), findsOneWidget);
      await tapText('Acidity');
      await tapText('3+ mo');
      await next();
      expect(find.text('3/4'), findsOneWidget);

      // Step 3: conditions, and pregnancy for women.
      await next();
      expect(find.text('Pick at least one, or None of these'), findsOneWidget);
      await tapText('None of these');
      await next();
      expect(find.text('Please choose one'), findsOneWidget);
      await tapText('No');
      await next();
      expect(find.text('4/4'), findsOneWidget);

      // Step 4: allergies and medicines, or say there are none.
      await next();
      expect(find.text('Add an allergy, or tap No allergies'), findsOneWidget);
      expect(find.text('Add a medicine, or tap No medicines'), findsOneWidget);
      await tapText('No allergies');
      await t.enterText(find.byType(TextField).at(1), 'Vitamin D'); // typed, Enter not pressed
      await t.runAsync(() async {
        await t.tap(find.byType(VvButton).first);
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await t.pumpAndSettle();
      expect(find.byType(AppShell), findsOneWidget);
      expect(s.name, 'Meera');
      expect(s.age, 29);
      expect(s.allergies, isEmpty);
      expect(s.medicines, ['Vitamin D']);
      expect(s.onboarded, isTrue);
    });

    testWidgets('the EN / हिंदी switch turns the whole screen to Hindi', (t) async {
      await t.pumpWidget(const VedaVerseApp());
      await t.pump();
      expect(find.text('Find my rhythm'), findsOneWidget);
      await t.tap(find.text('हिंदी'));
      await t.pump();
      expect(Lang.hi, isTrue);
      expect(find.text('मेरी लय खोजें'), findsOneWidget);
      expect(find.text('नींद नहीं आती'), findsOneWidget);
      await t.tap(find.text('मेरी लय खोजें'));
      await t.pumpAndSettle();
      expect(find.text('लॉग इन करें'), findsWidgets);
      await t.tap(find.text('EN').last);
      await t.pump();
      expect(find.text('Log in'), findsWidgets);
    });
  });
}
