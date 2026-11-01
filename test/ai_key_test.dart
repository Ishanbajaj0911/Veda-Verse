import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:veda_verse/ai/ai_key.dart';
import 'package:veda_verse/ai/gemini_client.dart';
import 'package:veda_verse/theme/vv.dart';
import 'package:veda_verse/widgets/ai_key_card.dart';

String _key(String c) => 'AIza${c * 35}';
final _k1 = _key('a'), _k2 = _key('b'), _k3 = _key('c');

String _ok() => jsonEncode({
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': 'OK'},
            ],
          },
        },
      ],
    });

/// Fake Google: [status] decides the reply per (key, model).
http.Client _google(int Function(String key, String model) status, {List<String>? calls}) => MockClient((req) async {
      final key = req.headers['x-goog-api-key'] ?? '';
      final model = req.url.pathSegments.last.split(':').first;
      calls?.add('${key == _k1 ? 'k1' : key == _k2 ? 'k2' : key == _k3 ? 'k3' : '?'}/${model.contains('lite') ? 'lite' : 'main'}');
      final s = status(key, model);
      return http.Response(s == 200 ? _ok() : '{"error":{"message":"error $s"}}', s);
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    GeminiClient.resetPreference();
    await AiKey.clear();
  });

  group('saved keys', () {
    test('up to 3, trimmed, no duplicates, and they survive a restart', () async {
      expect(GeminiClient().configured, isFalse, reason: 'no key in tests means offline');
      expect(await AiKey.add('  $_k1  '), isTrue);
      expect(await AiKey.add(_k1), isFalse, reason: 'already saved');
      expect(await AiKey.add(_k2), isTrue);
      expect(await AiKey.add(_k3), isTrue);
      expect(await AiKey.add(_key('d')), isFalse, reason: 'only 3 keys');
      expect(AiKey.keys, [_k1, _k2, _k3]);

      await AiKey.load(); // "close and reopen the app"
      expect(AiKey.keys, [_k1, _k2, _k3]);

      await AiKey.removeAt(0);
      expect(AiKey.keys, [_k2, _k3]);
    });

    test('a single key saved by the earlier version is kept', () async {
      FlutterSecureStorage.setMockInitialValues({'vv.gemini_api_key': _k1});
      await AiKey.load();
      expect(AiKey.keys, [_k1]);
    });

    test('masking and format check', () {
      expect(AiKey.mask(_k1), 'AIza…aaaa');
      expect(AiKey.looksValid(_k1), isTrue);
      expect(AiKey.looksValid('AQ.${'Ab8R' * 12}xy'), isTrue, reason: 'newer AI Studio key format');
      expect(AiKey.looksValid('AQ.short'), isFalse);
      expect(AiKey.looksValid('paste-your-gemini-api-key-here'), isFalse);
      expect(AiKey.looksValid('AIza ${'x' * 35}'), isFalse);
    });
  });

  group('fallback between keys', () {
    setUp(() async {
      await AiKey.add(_k1);
      await AiKey.add(_k2);
      await AiKey.add(_k3);
    });

    test('key 1 works: nothing else is tried', () async {
      final calls = <String>[];
      await GeminiClient(client: _google((_, _) => 200, calls: calls)).generate(system: 's', prompt: 'p');
      expect(calls, ['k1/main']);
    });

    test('key 1 at its free limit: its lite model, then key 2', () async {
      final calls = <String>[];
      await GeminiClient(client: _google((k, _) => k == _k1 ? 429 : 200, calls: calls)).generate(system: 's', prompt: 'p');
      expect(calls, ['k1/main', 'k1/lite', 'k2/main']);
    });

    test('a rejected key skips straight to the next key', () async {
      final calls = <String>[];
      await GeminiClient(client: _google((k, _) => k == _k1 ? 400 : 200, calls: calls)).generate(system: 's', prompt: 'p');
      expect(calls, ['k1/main', 'k2/main']);
    });

    test('keys 1 and 2 both fail: key 3 answers', () async {
      final calls = <String>[];
      await GeminiClient(client: _google((k, _) => k == _k3 ? 200 : 503, calls: calls)).generate(system: 's', prompt: 'p');
      expect(calls, ['k1/main', 'k1/lite', 'k2/main', 'k2/lite', 'k3/main']);
    });

    test('the key that worked last is tried first next time', () async {
      final calls = <String>[];
      final client = GeminiClient(client: _google((k, _) => k == _k1 ? 429 : 200, calls: calls));
      await client.generate(system: 's', prompt: 'p');
      calls.clear();
      await client.generate(system: 's', prompt: 'p');
      expect(calls, ['k2/main']);
    });

    test('every key failing reports the last error', () async {
      await expectLater(
        GeminiClient(client: _google((_, _) => 429)).generate(system: 's', prompt: 'p'),
        throwsA(isA<GeminiException>().having((e) => e.message, 'message', contains('key 3'))),
      );
    });

    test('a key passed directly is used alone', () async {
      final calls = <String>[];
      await GeminiClient(apiKey: _k3, client: _google((_, _) => 200, calls: calls)).generate(system: 's', prompt: 'p');
      expect(calls, ['k3/main']);
      expect(GeminiClient(apiKey: '').configured, isFalse);
    });
  });

  test('testKey explains what went wrong in plain words', () async {
    expect(await GeminiClient.testKey(_k1, client: _google((_, _) => 200)), isNull);
    expect(await GeminiClient.testKey(_k1, client: _google((_, _) => 400)), contains('didn’t accept'));
    expect(await GeminiClient.testKey(_k1, client: _google((_, _) => 429)), contains('free limit'));
  });

  Future<void> pumpCard(WidgetTester t, http.Client client) async {
    await t.pumpWidget(MaterialApp(theme: Vv.theme(), home: Scaffold(body: ListView(children: [AiKeyCard(client: client)]))));
    await t.pump();
  }

  Future<void> addKey(WidgetTester t, String key) async {
    await t.enterText(find.byType(TextField), key);
    await t.tap(find.textContaining(RegExp('Save and test|Test and add backup')));
    await t.pump();
    await t.pump();
  }

  testWidgets('add a main key and two backups, then remove one', (t) async {
    await pumpCard(t, _google((_, _) => 200));
    expect(find.text('Offline mode'), findsOneWidget);

    await addKey(t, 'not a key');
    expect(find.textContaining('doesn’t look like a Gemini API key'), findsOneWidget);
    expect(AiKey.isSet, isFalse);

    await addKey(t, _k1);
    expect(find.text('Online AI · Gemini'), findsOneWidget);
    expect(find.text('Key 1 · main'), findsOneWidget);

    await addKey(t, _k2);
    await addKey(t, _k3);
    expect(find.text('Key 3 · backup'), findsOneWidget);
    expect(find.text('3 keys · backups ready'), findsOneWidget);
    expect(find.byType(TextField), findsNothing, reason: 'the list is full');

    await t.tap(find.byTooltip('Remove key 2'));
    await t.pump();
    expect(AiKey.keys, [_k1, _k3]);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('a key Google rejects is not saved', (t) async {
    await pumpCard(t, _google((_, _) => 400));
    await addKey(t, _k1);
    expect(AiKey.isSet, isFalse);
    expect(find.textContaining('didn’t accept'), findsOneWidget);
  });
}
