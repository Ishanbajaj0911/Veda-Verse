import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:veda_verse/state/app_state.dart';

/// One turn of the Ayu Buddy conversation.
class ChatTurn {
  final bool fromUser;
  final String text;
  const ChatTurn(this.fromUser, this.text);
}

class GeminiReply {
  final String text;
  final String? source;
  const GeminiReply(this.text, {this.source});
}

class GeminiException implements Exception {
  final String message;
  const GeminiException(this.message);

  @override
  String toString() => 'GeminiException: $message';
}

/// Ayu Buddy's Gemini backend. The key is passed at build time with
/// `--dart-define-from-file=env.json` (GEMINI_API_KEY) and never committed.
class GeminiClient {
  GeminiClient({http.Client? client, String? apiKey})
      : _http = client ?? http.Client(),
        _key = apiKey ?? envKey;

  static const envKey = String.fromEnvironment('GEMINI_API_KEY');

  // Tried in order; the lite model answers when the main one is overloaded.
  static const models = ['gemini-flash-latest', 'gemini-flash-lite-latest'];

  final http.Client _http;
  final String _key;

  bool get configured => _key.isNotEmpty;

  /// [history] ends with the user's latest message. [voice] asks for a short
  /// reply that reads well aloud, in Hindi when [hindi] is set.
  Future<GeminiReply> ask(List<ChatTurn> history, {bool voice = false, bool hindi = false}) async {
    if (!configured) throw const GeminiException('GEMINI_API_KEY is not set');
    final body = jsonEncode({
      'systemInstruction': {
        'parts': [
          {'text': systemPrompt(AppState.instance, voice: voice, hindi: hindi)},
        ],
      },
      'contents': _contents(history),
    });

    GeminiException? last;
    for (final model in models) {
      try {
        final res = await _http
            .post(
              Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent'),
              headers: {'Content-Type': 'application/json', 'x-goog-api-key': _key},
              body: body,
            )
            .timeout(const Duration(seconds: 30));
        if (res.statusCode == 200) return parse(res.body);
        last = GeminiException('$model returned ${res.statusCode}: ${_errorMessage(res.body)}');
        // A bad key or request won't work on the next model either.
        if (const [400, 401, 403].contains(res.statusCode)) break;
      } on TimeoutException {
        last = GeminiException('$model timed out');
      } on GeminiException catch (e) {
        last = e;
      } on Exception catch (e) {
        last = GeminiException('$model request failed: $e');
      }
    }
    throw last!;
  }

  /// Gemini wants alternating roles starting with the user, so leading model
  /// turns are dropped and consecutive same-role turns merged.
  static List<Map<String, Object>> _contents(List<ChatTurn> history) {
    final out = <({bool user, String text})>[];
    for (final t in history.length > 20 ? history.sublist(history.length - 20) : history) {
      if (out.isEmpty && !t.fromUser) continue;
      if (out.isNotEmpty && out.last.user == t.fromUser) {
        out.last = (user: t.fromUser, text: '${out.last.text}\n${t.text}');
      } else {
        out.add((user: t.fromUser, text: t.text));
      }
    }
    return [
      for (final t in out)
        {
          'role': t.user ? 'user' : 'model',
          'parts': [
            {'text': t.text},
          ],
        },
    ];
  }

  /// Pulls the answer text and an optional trailing "Source: …" line.
  static GeminiReply parse(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final candidates = json['candidates'] as List?;
    final parts = candidates == null || candidates.isEmpty ? null : (candidates.first['content']?['parts'] as List?);
    final text = [
      for (final p in parts ?? const [])
        if (p['thought'] != true && p['text'] is String) p['text'] as String,
    ].join().replaceAll(RegExp(r'\*\*|__|^#+\s*', multiLine: true), '').trim();
    if (text.isEmpty) throw const GeminiException('empty reply');

    final lines = text.split('\n');
    final lastLine = lines.last.trim();
    final m = RegExp(r'^sources?\s*:\s*(.+)$', caseSensitive: false).firstMatch(lastLine);
    if (m == null || lines.length < 2) return GeminiReply(text);
    return GeminiReply(lines.sublist(0, lines.length - 1).join('\n').trim(), source: m.group(1)!.trim());
  }

  static String _errorMessage(String body) {
    try {
      return (jsonDecode(body)['error']?['message'] as String?) ?? body;
    } on FormatException {
      return body;
    }
  }

  static String systemPrompt(AppState s, {bool voice = false, bool hindi = false}) {
    final mix = s.mix.entries.map((e) => '${e.key} ${e.value}%').join(', ');
    String list(Iterable<String> xs) => xs.isEmpty ? 'none' : xs.join(', ');
    return '''
You are Ayu Buddy, the Ayurveda wellness guide inside the VedaVerse app. You explain Ayurveda and suggest gentle daily-routine, food, sleep, yoga and breathing habits.

User profile: ${s.firstName}, ${s.age}, ${s.gender}. Prakriti: ${s.prakritiLabel} ($mix). Main concerns: ${list(s.issues)}. Conditions: ${list(s.conditions)}. Medicines: ${list(s.medicines)}. Allergies: ${list(s.allergies)}.

Rules:
- Never diagnose, prescribe, or give doses of herbs, supplements or medicines. Never advise on combining herbs with medicines; say a Vaidya on VedaVerse should review that.
- Respect the user's conditions and allergies in every suggestion.
- If the user describes emergency symptoms (chest pain, trouble breathing, fainting, thoughts of self-harm), tell them to call 112 or 108 right away and say nothing else.
- Reply in the same language and script as the user's latest message: English if it is in English, Hinglish (Hindi in Latin letters) if it is Hinglish, Devanagari Hindi if it is Devanagari.
- Be warm and practical. Keep answers under 110 words. Plain text only: no markdown, asterisks, headings or bullet symbols.
- When the answer draws on a classical text you are sure of, end with one final line exactly like "Source: Charaka Samhita · Sutrasthana". Otherwise leave that line out.
${voice ? '- The user is speaking and your reply will be read aloud: keep it under 70 words, in ${hindi ? 'Hindi written in Devanagari script' : 'simple English'}, and leave out the Source line.' : ''}''';
  }
}
