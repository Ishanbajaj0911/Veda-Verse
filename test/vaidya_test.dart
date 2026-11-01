// Vaidya tab and booking: search and filters, the real upcoming consult,
// booking, cancelling, past slots, and Hindi at 390x844. Set VV_SHOTS=<dir>
// to also save PNG screenshots.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veda_verse/app_shell.dart';
import 'package:veda_verse/l10n/lang.dart';
import 'package:veda_verse/screens/booking_screen.dart';
import 'package:veda_verse/screens/vaidya_screen.dart';
import 'package:veda_verse/state/app_state.dart';
import 'package:veda_verse/theme/vv.dart';

const _allowedLatin = [
  'VedaVerse', 'Ayu Buddy', 'Gemini', 'Google', 'Aarav', 'Mehta',
  'Dr.', 'Rohan', 'Kapoor', 'Suresh', 'Paliwal', 'Meera', 'Sharma', 'Anjali', 'Nair', 'BAMS', 'PCOS', 'UPI',
];

/// Visible text that still has English words in it.
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

void _size(double h, {double w = 390}) {
  final v = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
  v.physicalSize = Size(w, h);
  v.devicePixelRatio = 1;
}

Future<void> _pump(WidgetTester t, Widget w) async {
  await t.pumpWidget(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: Vv.theme(),
    home: RepaintBoundary(key: const ValueKey('shot'), child: w),
  ));
  await t.pump(const Duration(milliseconds: 400));
}

final _shots = Platform.environment['VV_SHOTS'];

Future<void> _shot(WidgetTester t, String name) async {
  if (_shots == null) return;
  final boundary = t.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('shot')));
  await t.runAsync(() async {
    final img = await boundary.toImage(pixelRatio: 1);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    final dir = Directory(_shots!)..createSync(recursive: true);
    File('${dir.path}/vaidya_$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

Widget get _tab => const Scaffold(body: VaidyaScreen());

/// Names of the Vaidya cards on screen (the list is tall enough to hold all).
Set<String> _listed(WidgetTester t) => {
      for (final v in vaidyas)
        if (t.any(find.text(v.name))) v.name,
    };

DateTime _tomorrowAt(int h, int m) {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day + 1, h, m);
}

Future<void> _settle(WidgetTester t) async {
  await t.pumpAndSettle();
  // Let any snackbar time out.
  await t.pump(const Duration(seconds: 5));
  await t.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_loadFonts);

  setUp(() {
    Lang.notifier.value = Lang.en;
    AppState.instance.bookings = [];
    _size(844);
  });
  tearDown(() {
    Lang.notifier.value = Lang.en;
    AppState.instance.bookings = [];
  });

  final rohan = vaidyas.firstWhere((v) => v.name == 'Dr. Rohan Kapoor');
  final anjali = vaidyas.firstWhere((v) => v.name == 'Dr. Anjali Nair');
  final suresh = vaidyas.firstWhere((v) => v.name == 'Dr. Suresh Paliwal');
  final meera = vaidyas.firstWhere((v) => v.name == 'Dr. Meera Sharma');

  test('every Vaidya has a distinct look, a mode and concern tags', () {
    final looks = {for (final v in vaidyas) (v.skin, v.hair, v.hairStyle, v.beard, v.tint)};
    expect(looks.length, vaidyas.length);
    for (final v in vaidyas) {
      expect(v.modes, isNotEmpty);
      expect(v.modes.every(consultModes.contains), isTrue);
      expect(v.concerns, isNotEmpty);
      if (v.offers('In clinic')) expect(v.clinic, isNotEmpty);
    }
  });

  testWidgets('a new account sees the empty upcoming card, not a made-up consult', (t) async {
    AppState.instance.resetForNewAccount(id: 'VV-TEST', email: 'new@example.com');
    await _pump(t, _tab);
    expect(find.text('No consults booked yet'), findsOneWidget);
    expect(find.text('UPCOMING CONSULT'), findsNothing);
    expect(find.textContaining('Google Meet'), findsNothing);
    await t.tap(find.text('Find a Vaidya'));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });

  testWidgets('booking a future slot saves it and shows it in Upcoming; cancel removes it', (t) async {
    await _pump(t, _tab);
    await t.tap(find.text('Book · ₹399'));
    await t.pumpAndSettle();
    expect(find.byType(BookingScreen), findsOneWidget);
    expect(find.byType(VaidyaScreen), findsNothing);

    await t.tap(find.text('Tomorrow'));
    await t.pump();
    await t.tap(find.text('10:30 am'));
    await t.pump();
    await t.tap(find.text('Confirm booking'));
    await _settle(t);

    final s = AppState.instance;
    expect(s.bookings, hasLength(1));
    expect(s.bookings.single.vaidya, 'Dr. Rohan Kapoor');
    expect(s.bookings.single.when, _tomorrowAt(10, 30));
    expect(s.bookings.single.mode, 'Video');
    expect(find.byType(VaidyaScreen), findsOneWidget);
    expect(find.text('UPCOMING CONSULT'), findsOneWidget);
    expect(find.text('Tomorrow · 10:30 am'), findsOneWidget);
    expect(find.text('Video consult'), findsOneWidget);
    expect(find.text('No consults booked yet'), findsNothing);

    // Honest join info, no fake link.
    await t.tap(find.text('How to join'));
    await t.pumpAndSettle();
    expect(find.textContaining('10 minutes before the start'), findsOneWidget);
    await t.tap(find.text('OK'));
    await t.pumpAndSettle();

    await t.tap(find.text('Cancel'));
    await t.pumpAndSettle();
    expect(find.text('Cancel this consult?'), findsOneWidget);
    await t.tap(find.text('Cancel consult'));
    await _settle(t);
    expect(s.bookings, isEmpty);
    expect(find.text('No consults booked yet'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('English tab with two bookings, and the booking screen', (t) async {
    AppState.instance.bookings = [
      Booking(vaidya: meera.name, when: _tomorrowAt(18, 30), mode: 'In clinic'),
      Booking(vaidya: anjali.name, when: _tomorrowAt(19, 30), mode: 'Video', shareSummary: false),
    ];
    await _pump(t, const AppShell(initialIndex: Tabs.vaidya));
    expect(t.takeException(), isNull);
    expect(find.text('Also booked'), findsOneWidget);
    await _shot(t, 'en_booked');
    await t.drag(find.byType(ListView).first, const Offset(0, -700));
    await t.pump(const Duration(milliseconds: 300));
    await _shot(t, 'en_list');
    await _pump(t, BookingScreen(vaidya: suresh));
    expect(t.takeException(), isNull);
    await _shot(t, 'en_booking_suresh');
  });

  testWidgets('phone and clinic consults show how they happen', (t) async {
    AppState.instance.bookings = [Booking(vaidya: rohan.name, when: _tomorrowAt(17, 0), mode: 'Phone')];
    await _pump(t, _tab);
    expect(find.text('Phone consult'), findsOneWidget);
    await t.tap(find.text('Call details'));
    await t.pumpAndSettle();
    expect(find.text('The Vaidya will call you at 5:00 pm.'), findsOneWidget);
    await t.tap(find.text('OK'));
    await t.pumpAndSettle();

    AppState.instance.update((s) => s.bookings = [Booking(vaidya: meera.name, when: _tomorrowAt(18, 30), mode: 'In clinic')]);
    await t.pump();
    await t.tap(find.text('Clinic address'));
    await t.pumpAndSettle();
    expect(find.text('Clinic: Vaishali Nagar, Jaipur'), findsOneWidget);
  });

  testWidgets('the same Vaidya and time cannot be booked twice', (t) async {
    AppState.instance.bookings = [Booking(vaidya: rohan.name, when: _tomorrowAt(10, 30), mode: 'Video')];
    await _pump(t, BookingScreen(vaidya: rohan));
    await t.tap(find.text('Tomorrow'));
    await t.pump();
    await t.tap(find.text('10:30 am'));
    await t.pump();
    await t.tap(find.text('Confirm booking'));
    await t.pump();
    expect(find.text('You already booked Dr. Rohan Kapoor at this time.'), findsOneWidget);
    expect(AppState.instance.bookings, hasLength(1));
    expect(find.byType(BookingScreen), findsOneWidget);
    await _settle(t);
  });

  testWidgets('search matches concerns in English and Hindi', (t) async {
    _size(2400);
    await _pump(t, _tab);
    expect(_listed(t), {for (final v in vaidyas) v.name});

    Future<Set<String>> search(String q) async {
      await t.enterText(find.byType(TextField), q);
      await t.pump();
      return _listed(t);
    }

    expect(await search('sleep'), {meera.name});
    expect(await search('नींद'), {meera.name});
    expect(await search('acidity'), {rohan.name});
    expect(await search('pcos'), {anjali.name});
    expect(await search('Paliwal'), {suresh.name});
    expect(await search('stress'), {rohan.name, meera.name});
    expect(await search('xyzzy'), isEmpty);
    expect(find.text('No Vaidya matches'), findsOneWidget);
    await t.tap(find.text('Clear filters'));
    await t.pump();
    expect(_listed(t), {for (final v in vaidyas) v.name});
  });

  testWidgets('each filter chip narrows the list, together with search', (t) async {
    _size(2400, w: 800); // all five chips fit on one row
    await _pump(t, _tab);
    Future<Set<String>> chip(String l) async {
      final c = find.widgetWithText(VvChip, l);
      await t.ensureVisible(c);
      await t.pump();
      await t.tap(c);
      await t.pump();
      return _listed(t);
    }

    expect(await chip('Available now'), {rohan.name, meera.name});
    expect(await chip('Video'), {rohan.name, anjali.name, meera.name});
    expect(await chip('In clinic'), {anjali.name, suresh.name, meera.name});
    expect(await chip('Free'), {suresh.name});
    expect(await chip('All'), {for (final v in vaidyas) v.name});

    await chip('Video');
    await t.enterText(find.byType(TextField), 'joints');
    await t.pump();
    expect(_listed(t), isEmpty, reason: 'the joints Vaidya has no video consults');
    await t.tap(find.text('Clear filters'));
    await t.pump();
    expect(_listed(t), hasLength(vaidyas.length));
    expect(t.takeException(), isNull);
  });

  testWidgets('card icons: chat sheet, phone and video preselect the mode', (t) async {
    await _pump(t, _tab);
    await t.tap(find.byTooltip('Message').first);
    await t.pumpAndSettle();
    expect(find.text('Messages open after you book a consult.'), findsOneWidget);
    Navigator.of(t.element(find.text('Messages open after you book a consult.'))).pop();
    await t.pumpAndSettle();

    await t.tap(find.byTooltip('Book a phone consult').first);
    await t.pumpAndSettle();
    expect(find.byType(BookingScreen), findsOneWidget);
    expect(find.textContaining(RegExp(r'^Phone · ')), findsOneWidget);
    await t.tap(find.byType(VvBackButton));
    await t.pumpAndSettle();

    await t.tap(find.byTooltip('Book a video consult').first);
    await t.pumpAndSettle();
    expect(find.textContaining(RegExp(r'^Video · ')), findsOneWidget);
  });

  test('past slots for today are hidden', () {
    final now = DateTime(2026, 11, 1, 13, 5);
    final today = DateTime(2026, 11, 1);
    final s = slotsFor(anjali, today, now);
    expect(s.every((d) => d.isAfter(now)), isTrue);
    expect(s.map(fmtTime), ['2:00 pm', '4:30 pm', '6:00 pm', '7:30 pm']);
    expect(slotsFor(anjali, DateTime(2026, 11, 2), now), hasLength(6));
    // Available now: one extra slot soon, still nothing in the past.
    expect(slotsFor(rohan, today, now).map(fmtTime), ['1:15 pm', '5:00 pm', '6:30 pm', '8:00 pm']);
    expect(slotsFor(anjali, today, DateTime(2026, 11, 1, 23)), isEmpty);
  });

  testWidgets('booking screen hides past times today and disables modes not offered', (t) async {
    final n = DateTime.now();
    await _pump(t, BookingScreen(vaidya: anjali, now: DateTime(n.year, n.month, n.day, 13, 5)));
    for (final gone in ['10:00 am', '11:30 am']) {
      expect(find.text(gone), findsNothing, reason: '$gone is in the past');
    }
    expect(find.text('2:00 pm'), findsOneWidget);

    // Anjali has no phone consults: tapping it changes nothing.
    await t.tap(find.text('Phone'));
    await t.pump();
    expect(find.textContaining(RegExp(r'^Video · Today 2:00 pm')), findsOneWidget);
    await t.tap(find.text('In clinic'));
    await t.pump();
    expect(find.text('Clinic: Panampilly Nagar, Kochi'), findsOneWidget);

    // Late at night today is over: tomorrow is picked.
    await _pump(t, BookingScreen(key: const ValueKey('late'), vaidya: anjali, now: DateTime(n.year, n.month, n.day, 23, 30)));
    expect(find.textContaining(RegExp(r'^Video · Tomorrow 10:00 am')), findsOneWidget);
    await t.tap(find.text('Today'));
    await t.pump();
    expect(find.text('No times left on this day. Please pick another day.'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  group('Hindi at 390x844', () {
    setUp(() => Lang.notifier.value = Lang.hiCode);

    testWidgets('Vaidya tab with a booking', (t) async {
      AppState.instance.bookings = [
        Booking(vaidya: meera.name, when: _tomorrowAt(18, 30), mode: 'In clinic'),
        Booking(vaidya: rohan.name, when: _tomorrowAt(20, 0), mode: 'Video'),
      ];
      await _pump(t, const AppShell(initialIndex: Tabs.vaidya));
      expect(t.takeException(), isNull);
      expect(_englishLeft(t), isEmpty);
      expect(find.text(tr('UPCOMING CONSULT')), findsOneWidget);
      await _shot(t, 'hi_booked');
      for (var i = 0; i < 6; i++) {
        await t.drag(find.byType(ListView).first, const Offset(0, -400));
        await t.pump(const Duration(milliseconds: 300));
        expect(t.takeException(), isNull);
        expect(_englishLeft(t), isEmpty, reason: 'after scrolling $i');
      }
      await t.drag(find.byType(ListView).first, const Offset(0, 4000));
      await t.pumpAndSettle();
      await t.tap(find.text(tr('Clinic address')));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expect(_englishLeft(t), isEmpty, reason: 'clinic sheet');
      await _shot(t, 'hi_clinic_sheet');
    });

    testWidgets('empty states', (t) async {
      await _pump(t, const AppShell(initialIndex: Tabs.vaidya));
      expect(find.text(tr('No consults booked yet')), findsOneWidget);
      await t.enterText(find.byType(TextField), 'xyzzy');
      await t.pump();
      expect(find.text(tr('No Vaidya matches')), findsOneWidget);
      expect(t.takeException(), isNull);
      expect(_englishLeft(t), isEmpty);
    });

    for (final v in vaidyas) {
      testWidgets('booking ${v.name}', (t) async {
        await _pump(t, BookingScreen(vaidya: v));
        expect(t.takeException(), isNull);
        expect(_englishLeft(t), isEmpty);
        for (final m in v.modes) {
          await t.tap(find.text(tr(m)));
          await t.pump();
          expect(t.takeException(), isNull);
          expect(_englishLeft(t), isEmpty, reason: m);
        }
        await t.drag(find.byType(ListView), const Offset(0, -600));
        await t.pump();
        expect(_englishLeft(t), isEmpty);
      });
    }
  });
}
