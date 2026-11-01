// Every tr('…') / trf('…') text in lib/ must have a Hindi entry, keep its
// {placeholders}, and never interpolate with $ (use trf instead).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:veda_verse/l10n/hi.dart';
import 'package:veda_verse/l10n/hi_ai.dart';
import 'package:veda_verse/l10n/hi_care.dart';
import 'package:veda_verse/l10n/hi_core.dart';
import 'package:veda_verse/l10n/hi_engine.dart';
import 'package:veda_verse/l10n/hi_home.dart';
import 'package:veda_verse/l10n/hi_quiz.dart';
import 'package:veda_verse/l10n/lang.dart';

/// Undoes Dart string escapes so the key matches the runtime string.
String _unescape(String s) => s.replaceAllMapped(RegExp(r'\\(.)'), (m) => switch (m[1]) {
      'n' => '\n',
      't' => '\t',
      _ => m[1]!,
    });

const _lit = r'''(?:'(?:[^'\\\n]|\\.)*'|"(?:[^"\\\n]|\\.)*")''';

/// (file, text) for every literal passed to tr/trf, including adjacent
/// string literals ('a' 'b').
List<(String, String)> _keys() {
  final call = RegExp('\\btrf?\\(\\s*((?:$_lit\\s*)+)[,)]');
  final one = RegExp(_lit);
  final sep = Platform.pathSeparator;
  final out = <(String, String)>[];
  for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
    if (!f.path.endsWith('.dart') || f.path.contains('${sep}l10n$sep')) continue;
    for (final m in call.allMatches(f.readAsStringSync())) {
      final text = one.allMatches(m[1]!).map((p) => _unescape(p[0]!.substring(1, p[0]!.length - 1))).join();
      out.add((f.path, text));
    }
  }
  return out;
}

void main() {
  final keys = _keys();

  test('the app has translatable text', () => expect(keys.length, greaterThan(50)));

  test('every tr() text has a Hindi translation', () {
    final missing = {for (final (f, k) in keys) if (!hiStrings.containsKey(k)) '$f: $k'};
    expect(missing, isEmpty, reason: 'add these to a lib/l10n/hi_*.dart file');
  });

  test(r'no $ interpolation inside tr(); use trf with {placeholders}', () {
    final bad = {for (final (f, k) in keys) if (RegExp(r'\$[{a-zA-Z_]').hasMatch(k)) '$f: $k'};
    expect(bad, isEmpty);
  });

  test('Hindi keeps every {placeholder}', () {
    final bad = <String>[];
    hiStrings.forEach((en, hi) {
      for (final p in RegExp(r'\{[a-zA-Z0-9_]+\}').allMatches(en)) {
        if (!hi.contains(p[0]!)) bad.add('$en -> $hi (missing ${p[0]})');
      }
    });
    expect(bad, isEmpty);
  });

  test('Hindi entries are not empty and not just the English again', () {
    final bad = [
      for (final e in hiStrings.entries)
        if (e.value.trim().isEmpty || (e.value == e.key && e.key.contains(RegExp('[A-Za-z]{3}')))) e.key,
    ];
    expect(bad, isEmpty);
  });

  test('a text shared by two areas has the same Hindi in both', () {
    final areas = {'core': hiCore, 'home': hiHome, 'quiz': hiQuiz, 'ai': hiAi, 'care': hiCare, 'engine': hiEngine};
    final seen = <String, (String, String)>{};
    final clash = <String>[];
    areas.forEach((area, map) {
      map.forEach((en, hi) {
        final prev = seen[en];
        if (prev != null && prev.$2 != hi) clash.add('"$en": ${prev.$1}="${prev.$2}" vs $area="$hi"');
        seen[en] ??= (area, hi);
      });
    });
    expect(clash, isEmpty);
  });

  test('tr and trf switch with the language', () {
    addTearDown(() => Lang.notifier.value = Lang.en);
    Lang.notifier.value = Lang.hiCode;
    final some = hiStrings.entries.firstWhere((e) => !e.key.contains('{'));
    expect(tr(some.key), some.value);
    expect(tr('no such text xyz'), 'no such text xyz', reason: 'falls back to English');
    Lang.notifier.value = Lang.en;
    expect(tr(some.key), some.key);
    expect(trf('{a} and {b}', {'a': 1, 'b': 'x'}), '1 and x');
  });
}
