import 'dart:convert';

import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:veda_verse/ai/gemini_client.dart';

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
  test('falls back to the lite model when the main one is overloaded', () async {
    final hits = <String>[];
    final client = GeminiClient(
      apiKey: 'k',
      client: MockClient((req) async {
        hits.add(req.url.path);
        expect(req.headers['x-goog-api-key'], 'k');
        return hits.length == 1
            ? http.Response('{"error":{"message":"high demand"}}', 503)
            : http.Response(_reply('Eat a warm, light dinner.\nSource: Charaka Samhita · Sutrasthana'), 200);
      }),
    );
    final r = await client.ask(const [ChatTurn(true, 'Dinner tips?')]);
    expect(hits, [
      '/v1beta/models/${GeminiClient.models[0]}:generateContent',
      '/v1beta/models/${GeminiClient.models[1]}:generateContent',
    ]);
    expect(r.text, 'Eat a warm, light dinner.');
    expect(r.source, 'Charaka Samhita · Sutrasthana');
  });

  test('a rejected key does not retry other models', () async {
    var calls = 0;
    final client = GeminiClient(
      apiKey: 'bad',
      client: MockClient((_) async {
        calls++;
        return http.Response('{"error":{"message":"API key not valid"}}', 400);
      }),
    );
    await expectLater(client.ask(const [ChatTurn(true, 'hi')]), throwsA(isA<GeminiException>()));
    expect(calls, 1);
  });

  test('sends alternating turns starting with the user', () async {
    late List contents;
    final client = GeminiClient(
      apiKey: 'k',
      client: MockClient((req) async {
        contents = jsonDecode(req.body)['contents'] as List;
        return http.Response(_reply('ok'), 200);
      }),
    );
    await client.ask(const [
      ChatTurn(false, 'Namaste!'),
      ChatTurn(true, 'a'),
      ChatTurn(true, 'b'),
      ChatTurn(false, 'c'),
      ChatTurn(true, 'd'),
    ]);
    expect([for (final c in contents) c['role']], ['user', 'model', 'user']);
    expect(contents.first['parts'][0]['text'], 'a\nb');
  });

  test('parse strips markdown and skips thought parts', () {
    final body = jsonEncode({
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': 'thinking…', 'thought': true},
              {'text': '**Abhyanga** helps Vata.'},
            ],
          },
        },
      ],
    });
    final r = GeminiClient.parse(body);
    expect(r.text, 'Abhyanga helps Vata.');
    expect(r.source, isNull);
  });

  test('a shared document is sent inline with the latest message only', () async {
    late List contents;
    final client = GeminiClient(
      apiKey: 'k',
      client: MockClient((req) async {
        contents = jsonDecode(req.body)['contents'] as List;
        return http.Response(_reply('ok'), 200);
      }),
    );
    final pdf = Attachment('report.pdf', 'application/pdf', Uint8List.fromList([1, 2, 3]));
    final photo = Attachment('old.jpg', 'image/jpeg', Uint8List.fromList([9, 9]));
    await client.ask([
      ChatTurn(true, 'earlier photo', attachments: [photo]),
      const ChatTurn(false, 'noted'),
      ChatTurn(true, '', attachments: [pdf]),
    ]);
    final first = contents.first['parts'] as List;
    expect(first.any((p) => p.containsKey('inlineData')), isFalse, reason: 'earlier files are not re-sent');
    expect(first.last['text'], contains('[shared earlier: old.jpg]'));
    final last = contents.last['parts'] as List;
    expect(last.first['inlineData'], {'mimeType': 'application/pdf', 'data': base64Encode([1, 2, 3])});
    expect(last.last['text'], 'Please explain this in simple words.');
  });

  test('only PDFs, photos and text files are accepted', () {
    expect(Attachment.mimeFor('Report.PDF'), 'application/pdf');
    expect(Attachment.mimeFor('scan.jpeg'), 'image/jpeg');
    expect(Attachment.mimeFor('notes.docx'), isNull);
    expect(Attachment.mimeFor('noextension'), isNull);
  });

  test('without a key it refuses instead of calling the network', () async {
    final client = GeminiClient(apiKey: '', client: MockClient((_) async => fail('no request expected')));
    expect(client.configured, isFalse);
    await expectLater(client.ask(const [ChatTurn(true, 'hi')]), throwsA(isA<GeminiException>()));
  });
}
