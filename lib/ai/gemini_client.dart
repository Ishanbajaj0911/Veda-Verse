import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show Uint8List, visibleForTesting;
import 'package:http/http.dart' as http;
import 'package:veda_verse/ai/ai_key.dart';
import 'package:veda_verse/state/app_state.dart';

/// A document or photo the user shared (lab report, prescription, …).
class Attachment {
  final String name;
  final String mimeType;
  final Uint8List bytes;
  const Attachment(this.name, this.mimeType, this.bytes);

  /// Types Gemini can read inline. Word, Excel and other formats are not.
  static const supported = {
    'pdf': 'application/pdf',
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
    'heic': 'image/heic',
    'heif': 'image/heif',
    'txt': 'text/plain',
  };

  /// Inline requests are capped at 20 MB including base64 overhead.
  static const maxBytes = 12 * 1024 * 1024;

  static String? mimeFor(String fileName) {
    final dot = fileName.lastIndexOf('.');
    return dot < 0 ? null : supported[fileName.substring(dot + 1).toLowerCase()];
  }

  bool get isImage => mimeType.startsWith('image/');
}

/// One turn of the Ayu Buddy conversation.
class ChatTurn {
  final bool fromUser;
  final String text;

  /// Files shared with this turn. Only the latest user turn's files are sent
  /// to Gemini; earlier ones are mentioned by name to keep requests small.
  final List<Attachment> attachments;
  const ChatTurn(this.fromUser, this.text, {this.attachments = const []});
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

/// Ayu Buddy's Gemini backend, with backup keys.
///
/// Keys, in order:
///  * [apiKey] passed to the constructor (tests, the "Save and test" check)
///    is used alone;
///  * otherwise the keys saved in Settings ([AiKey], up to 3, on-device secure
///    storage), then build-time keys from `--dart-define-from-file=env.json`
///    (GEMINI_API_KEY, GEMINI_API_KEY_2, GEMINI_API_KEY_3), if any.
/// With none, [configured] is false and the app stays offline.
///
/// Each request tries every key with the main model, then the lite model. A
/// rejected key (400/401/403) skips straight to the next key; a free-limit
/// hit (429), server error or timeout tries the lite model, then the next key.
/// The key that last worked is tried first next time.
class GeminiClient {
  GeminiClient({http.Client? client, String? apiKey})
      : _http = client ?? http.Client(),
        _fixedKey = apiKey;

  static const envKey = String.fromEnvironment('GEMINI_API_KEY');
  static const envKeys = [
    envKey,
    String.fromEnvironment('GEMINI_API_KEY_2'),
    String.fromEnvironment('GEMINI_API_KEY_3'),
  ];

  // Tried in order; the lite model answers when the main one is overloaded.
  static const models = ['gemini-flash-latest', 'gemini-flash-lite-latest'];

  final http.Client _http;
  final String? _fixedKey;

  /// The key that answered last, tried first on the next request.
  static String? _lastGood;

  /// Read on every call, so saving or removing a key in Settings takes
  /// effect immediately everywhere. Placeholder or malformed values are
  /// ignored rather than tried.
  List<String> get keys {
    final fixed = _fixedKey;
    if (fixed != null) return fixed.isEmpty ? const [] : [fixed];
    final all = <String>[];
    for (final k in [...AiKey.keys, ...envKeys]) {
      if (AiKey.looksValid(k) && !all.contains(k)) all.add(k);
    }
    final good = _lastGood;
    if (good != null && all.remove(good)) all.insert(0, good);
    return all;
  }

  bool get configured => keys.isNotEmpty;

  /// Checks a key with a tiny request. Returns null if it works, or a
  /// short, user-friendly reason if it doesn't.
  static Future<String?> testKey(String key, {http.Client? client}) async {
    try {
      await GeminiClient(apiKey: key.trim(), client: client).generate(system: 'Reply with the single word OK.', prompt: 'ping');
      return null;
    } on GeminiException catch (e) {
      final m = e.message.toLowerCase();
      // Status codes first: a 429 body can also mention the key.
      if (m.contains('returned 429') || m.contains('quota') || m.contains('exhausted')) {
        return 'This key has reached its free limit for now. Try again later.';
      }
      if (RegExp(r'returned (400|401|403)').hasMatch(m) || m.contains('api key')) {
        return 'Google didn’t accept this key. Check you copied all of it.';
      }
      if (m.contains('timed out') || m.contains('failed')) return 'Couldn’t reach Google. Check your internet and try again.';
      return 'The key didn’t work right now. Please try again.';
    }
  }

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
    return parse(await _post(body));
  }

  /// One-off request for a task (reading a report, writing a summary).
  /// With [schema] (Gemini's OpenAPI-style schema) the reply is JSON and is
  /// returned decoded; otherwise the plain text is returned.
  Future<Object> generate({
    required String system,
    required String prompt,
    List<Attachment> files = const [],
    Map<String, Object>? schema,
  }) async {
    if (!configured) throw const GeminiException('GEMINI_API_KEY is not set');
    final body = jsonEncode({
      'systemInstruction': {
        'parts': [
          {'text': system},
        ],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            for (final f in files)
              {
                'inlineData': {'mimeType': f.mimeType, 'data': base64Encode(f.bytes)},
              },
            {'text': prompt},
          ],
        },
      ],
      if (schema != null)
        'generationConfig': {'responseMimeType': 'application/json', 'responseSchema': schema, 'temperature': 0},
    });
    final raw = await _post(body);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final parts = (json['candidates'] as List?)?.firstOrNull?['content']?['parts'] as List?;
    final text = [
      for (final p in parts ?? const [])
        if (p['thought'] != true && p['text'] is String) p['text'] as String,
    ].join().trim();
    if (text.isEmpty) throw const GeminiException('empty reply');
    if (schema == null) return text;
    try {
      return jsonDecode(text) as Object;
    } on FormatException {
      throw GeminiException('reply was not valid JSON: ${text.length > 80 ? text.substring(0, 80) : text}');
    }
  }

  /// Posts [body] to each model in turn, returning the first 200 response.
  Future<String> _post(String body) async {
    final all = keys;
    if (all.isEmpty) throw const GeminiException('no Gemini API key');
    GeminiException? last;
    for (final (i, key) in all.indexed) {
      final which = all.length > 1 ? ' (key ${i + 1})' : '';
      for (final model in models) {
        try {
          final res = await _http
              .post(
                Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent'),
                headers: {'Content-Type': 'application/json', 'x-goog-api-key': key},
                body: body,
              )
              .timeout(const Duration(seconds: 30));
          if (res.statusCode == 200) {
            if (_fixedKey == null) _lastGood = key;
            return res.body;
          }
          last = GeminiException('$model$which returned ${res.statusCode}: ${_errorMessage(res.body)}');
          // A rejected key fails on every model: move to the next key.
          if (const [400, 401, 403].contains(res.statusCode)) break;
        } on TimeoutException {
          last = GeminiException('$model$which timed out');
        } on GeminiException catch (e) {
          last = e;
        } on Exception catch (e) {
          last = GeminiException('$model$which request failed: $e');
        }
      }
    }
    throw last!;
  }

  /// Forgets which key worked last (tests).
  @visibleForTesting
  static void resetPreference() => _lastGood = null;

  /// Gemini wants alternating roles starting with the user, so leading model
  /// turns are dropped and consecutive same-role turns merged.
  static List<Map<String, Object>> _contents(List<ChatTurn> history) {
    final recent = history.length > 20 ? history.sublist(history.length - 20) : history;
    final lastUser = recent.lastIndexWhere((t) => t.fromUser);
    final out = <({bool user, String text, List<Attachment> files})>[];
    for (final (i, t) in recent.indexed) {
      if (out.isEmpty && !t.fromUser) continue;
      // Earlier files are named, not re-sent.
      final files = i == lastUser ? t.attachments : const <Attachment>[];
      final named = i == lastUser || t.attachments.isEmpty
          ? t.text
          : '${t.text}\n[shared earlier: ${t.attachments.map((a) => a.name).join(', ')}]'.trim();
      if (out.isNotEmpty && out.last.user == t.fromUser) {
        out.last = (user: t.fromUser, text: '${out.last.text}\n$named', files: [...out.last.files, ...files]);
      } else {
        out.add((user: t.fromUser, text: named, files: files));
      }
    }
    return [
      for (final t in out)
        {
          'role': t.user ? 'user' : 'model',
          'parts': [
            for (final f in t.files)
              {
                'inlineData': {'mimeType': f.mimeType, 'data': base64Encode(f.bytes)},
              },
            {'text': t.text.isEmpty ? 'Please explain this in simple words.' : t.text},
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
    final v = s.vikriti;
    final mix = s.hasPrakriti
        ? '${s.mix.entries.map((e) => '${e.key} ${e.value}%').join(', ')}; '
            'current imbalance (last 2 weeks): ${v == null ? 'not checked' : (v.raised == null ? 'none stands out' : '${v.raised} raised, signs: ${v.signs.join(', ')}')}'
        : 'quiz not taken yet, do not assume a dosha';
    String list(Iterable<String> xs) => xs.isEmpty ? 'none' : xs.join(', ');
    final flags = [
      if (s.gender == 'Female' && s.pregnancy != 'No') s.pregnancy.toLowerCase(),
      if (s.age < 18) 'under 18',
      ...s.conditions.where((c) => c != 'None of these').map((c) => c.toLowerCase()),
    ];
    return '''
You are Ayu Buddy, the Ayurveda wellness guide inside the VedaVerse app.

User profile: ${s.firstName}, ${s.age}, ${s.gender}. Prakriti: ${s.prakritiLabel} ($mix). Main concerns: ${list(s.issues)}. Conditions: ${list(s.conditions)}. Pregnancy: ${s.gender == 'Female' ? s.pregnancy : 'not applicable'}. Medicines: ${list(s.medicines)}. Allergies: ${list(s.allergies)}.

Scope. You ONLY give everyday wellness suggestions and basic information: daily routine (Dinacharya), food habits, sleep, stress, yoga and breathing, seasonal tips (Ritucharya), Ayurveda basics, the user's dosha, and how to use VedaVerse. For anything else, including diagnosis, treatment plans, medical tests beyond plain-word explanation, or unrelated topics, reply in one short sentence that you can only help with daily wellness suggestions, and point them to a Vaidya on VedaVerse or the right professional.

Safety rules:
- Never diagnose, never say the user has a disease, and never prescribe.
- Never advise on taking, stopping, changing, combining or dosing any medicine, herb, supplement, kadha, churna, alcohol or other substance. Say that a Vaidya on VedaVerse should guide that.
- Emergencies in India: for chest pain, trouble breathing, fainting, heavy bleeding or stroke signs, tell them to call 108 for an ambulance (112 also works) and say nothing else. For thoughts of suicide or self-harm, gently urge them to call Tele-MANAS 14416 (free, 24x7) or 108 now, and say nothing else.
- Respect the user's conditions and allergies in every suggestion.${flags.isEmpty ? '' : ' This user is flagged (${flags.join(', ')}): keep suggestions gentle and ask them to check any diet or routine change with their Vaidya first.'}
- If the user shares a document or photo (for example a lab report or prescription), explain in plain words what it shows: the test names and whether each value is inside the printed range. Never interpret it as a diagnosis and never comment on medicines in it; suggest discussing it with their Vaidya or doctor. If it is unreadable or not health-related, say so briefly.

Style:
- Reply in the same language and script as the user's latest message: English if it is in English, Hinglish (Hindi in Latin letters) if it is Hinglish, Devanagari Hindi if it is Devanagari.
- Be warm and practical. Give one to three concrete suggestions. Keep answers under 110 words. Plain text only: no markdown, asterisks, headings or bullet symbols.
- Do not cite book or chapter names.
${voice ? '- The user is speaking and your reply will be read aloud: keep it under 70 words and in ${hindi ? 'Hindi written in Devanagari script' : 'simple English'}.' : ''}''';
  }
}
