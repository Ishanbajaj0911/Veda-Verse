import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veda_verse/l10n/hi.dart';

/// The app's display language: 'EN' (English) or 'HI' (Hindi).
///
/// Chosen on the Welcome or Login screen, or in Settings, and saved on the
/// device. Every screen reads its text through [tr], and the app redraws
/// itself whenever [notifier] changes (see `VedaVerseApp` in main.dart).
class Lang {
  Lang._();

  static const en = 'EN', hiCode = 'HI';
  static const _key = 'vv.language';

  static final notifier = ValueNotifier<String>(en);

  static String get code => notifier.value;
  static bool get hi => notifier.value == hiCode;

  /// Loads the saved choice at start-up. Never throws.
  static Future<void> load() async {
    try {
      final v = (await SharedPreferences.getInstance()).getString(_key);
      if (v == en || v == hiCode) notifier.value = v!;
    } catch (e) {
      debugPrint('Lang.load failed');
    }
  }

  /// Switches the whole app to [code] and remembers it.
  static Future<void> set(String code) async {
    if (code != en && code != hiCode) return;
    notifier.value = code;
    try {
      await (await SharedPreferences.getInstance()).setString(_key, code);
    } catch (e) {
      debugPrint('Lang.set failed');
    }
  }
}

/// Text in the current language. [en] is the English text and the lookup key
/// into the Hindi dictionary (lib/l10n/hi_*.dart); missing entries fall back
/// to English. test/l10n_test.dart checks every `tr('…')` in lib/ has one.
String tr(String en) => Lang.hi ? (hiStrings[en] ?? en) : en;

/// [tr] with `{name}` placeholders, e.g.
/// `trf('{n} sound like you', {'n': 3})`.
String trf(String en, Map<String, Object?> args) {
  var s = tr(en);
  args.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
  return s;
}
