import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:veda_verse/ai/gemini_client.dart';
import 'package:veda_verse/screens/buddy_screen.dart';
import 'package:veda_verse/state/app_state.dart';
import 'package:veda_verse/theme/vv.dart';

class _FakeDialer extends Fake with MockPlatformInterfaceMixin implements UrlLauncherPlatform {
  final launched = <String>[];
  @override
  LinkDelegate? get linkDelegate => null;
  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launched.add(url);
    return true;
  }

  @override
  Future<bool> canLaunch(String url) async => true;
  @override
  Future<bool> supportsMode(PreferredLaunchMode mode) async => true;
  @override
  Future<bool> supportsCloseForMode(PreferredLaunchMode mode) async => false;
}

String _reply(String text) => jsonEncode({
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': text},
            ],
          },
        },
      ],
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _FakeDialer dialer;
  late List<String> requests;

  setUpAll(() async {
    final romie = FontLoader('Romie');
    for (final f in ['Romie-300', 'Romie-300Italic', 'Romie-500', 'Romie-500Italic', 'Romie-700']) {
      romie.addFont(rootBundle.load('assets/fonts/$f.otf'));
    }
    await romie.load();
    await (FontLoader('Manrope')..addFont(rootBundle.load('assets/fonts/Manrope-Variable.ttf'))).load();
  });

  setUp(() {
    dialer = _FakeDialer();
    UrlLauncherPlatform.instance = dialer;
    requests = [];
    final v = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    v.physicalSize = const Size(390, 844);
    v.devicePixelRatio = 1;
    AppState.instance
      ..allergies = ['Peanuts']
      ..medicines = ['Amlodipine 5 mg'];
  });

  GeminiClient gemini(String answer) => GeminiClient(
        apiKey: 'test',
        client: MockClient((req) async {
          requests.add(req.body);
          return http.Response(_reply(answer), 200);
        }),
      );

  Future<void> open(WidgetTester t, {GeminiClient? ai}) async {
    await t.pumpWidget(MaterialApp(theme: Vv.theme(), home: Scaffold(body: BuddyScreen(ai: ai ?? GeminiClient(apiKey: '')))));
    await t.pump();
  }

  Future<void> say(WidgetTester t, String text) async {
    await t.enterText(find.byType(TextField), text);
    await t.testTextInput.receiveAction(TextInputAction.send);
    await t.pump(const Duration(milliseconds: 300));
    await t.pump(const Duration(milliseconds: 300));
  }

  testWidgets('a medicine question gets the Vaidya card and never reaches Gemini', (t) async {
    await open(t, ai: gemini('should not be shown'));
    await say(t, 'Can I take ashwagandha with my BP tablet?');
    expect(find.text('NEEDS A VAIDYA'), findsOneWidget);
    expect(find.textContaining('Amlodipine 5 mg', findRichText: true), findsOneWidget);
    expect(requests, isEmpty);
    expect(t.takeException(), isNull);
  });

  testWidgets('an emergency gets the 108 card and the button dials 108', (t) async {
    await open(t, ai: gemini('should not be shown'));
    await say(t, 'my chest feels tight and heavy');
    expect(find.text('CALL 108 NOW'), findsOneWidget);
    await t.ensureVisible(find.text('Call 108').last);
    await t.pumpAndSettle();
    await t.tap(find.text('Call 108').last);
    await t.pump();
    expect(dialer.launched, contains('tel:108'));
    await t.ensureVisible(find.text('Call 112'));
    await t.pumpAndSettle();
    await t.tap(find.text('Call 112'));
    await t.pump();
    expect(dialer.launched, contains('tel:112'));
    expect(requests, isEmpty);
  });

  testWidgets('the banner button dials 108', (t) async {
    await open(t);
    await t.tap(find.text('Call 108'));
    await t.pump();
    expect(dialer.launched, ['tel:108']);
  });

  testWidgets('self-harm gets the Tele-MANAS 14416 card', (t) async {
    await open(t, ai: gemini('should not be shown'));
    await say(t, 'I want to kill myself');
    expect(find.text('YOU ARE NOT ALONE'), findsOneWidget);
    await t.ensureVisible(find.text('Call Tele-MANAS 14416'));
    await t.pumpAndSettle();
    await t.tap(find.text('Call Tele-MANAS 14416'));
    await t.pump();
    expect(dialer.launched, contains('tel:14416'));
    expect(requests, isEmpty);
  });

  testWidgets('Hindi messages get Hindi cards', (t) async {
    await open(t);
    await say(t, 'मैं आत्महत्या करना चाहता हूँ');
    expect(find.text('आप अकेले नहीं हैं'), findsOneWidget);
    await say(t, 'सांस नहीं आ रही');
    expect(find.text('अभी 108 पर कॉल करें'), findsOneWidget);
  });

  testWidgets('a blocked question is never sent to Gemini later as history', (t) async {
    await open(t, ai: gemini('Keep a fixed bedtime and dim the lights an hour before.'));
    await say(t, 'Can I take ashwagandha for sleep?');
    await say(t, 'what else helps me sleep better at night?');
    expect(requests.length, 1);
    expect(requests.single, isNot(contains('ashwagandha')));
    expect(requests.single, contains('sleep better'));
    expect(find.text('Keep a fixed bedtime and dim the lights an hour before.'), findsOneWidget);
  });

  testWidgets('a Gemini answer with a dose is replaced by the Vaidya card', (t) async {
    await open(t, ai: gemini('Take 500 mg of ashwagandha powder at night.'));
    await say(t, 'what helps me relax in the evening?');
    expect(find.textContaining('500 mg'), findsNothing);
    expect(find.text('NEEDS A VAIDYA'), findsOneWidget);
    // The exchange is dropped from later history too.
    await say(t, 'and in the morning?');
    expect(requests.length, 2);
    expect(requests.last, isNot(contains('relax in the evening')));
  });

  testWidgets('the prompt limits Buddy to suggestions and uses Indian numbers', (t) async {
    await open(t, ai: gemini('ok'));
    await say(t, 'tips for a calm mind');
    final body = jsonDecode(requests.single) as Map<String, dynamic>;
    final prompt = body['systemInstruction']['parts'][0]['text'] as String;
    expect(prompt, contains('You ONLY give everyday wellness suggestions'));
    expect(prompt, contains('108'));
    expect(prompt, contains('Tele-MANAS 14416'));
    expect(prompt, isNot(contains('Source:')));
  });

  testWidgets('offline answers come from the user\'s plan, respect allergies, cite nothing', (t) async {
    AppState.instance.allergies = ['Milk'];
    await open(t); // no key -> offline
    await say(t, 'how do I sleep better?');
    final answer = find.textContaining('For poor sleep');
    expect(answer, findsOneWidget);
    final text = (t.widget<Text>(answer)).data!.toLowerCase();
    expect(text, isNot(contains('milk')));
    expect(find.textContaining('Source'), findsNothing);
  });

  testWidgets('everyday questions still get answered', (t) async {
    await open(t, ai: gemini('Try 10 minutes of Anulom Vilom before bed.'));
    await say(t, 'which pillow is best for back pain');
    expect(find.text('NEEDS A VAIDYA'), findsNothing);
    expect(find.text('Try 10 minutes of Anulom Vilom before bed.'), findsOneWidget);
  });
}
