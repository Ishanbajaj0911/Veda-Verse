import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veda_verse/ml/dosha_predictor.dart';
import 'package:veda_verse/state/app_state.dart';

/// Saves the quiz result and today's plan ticks on the device
/// (SharedPreferences: app storage on Android/iOS, localStorage on web), so
/// closing the app no longer loses them. Firestore replaces this later.
///
/// Only raw answers are stored. On start the Prakriti is recomputed with the
/// bundled model, and answers saved for a different model version are
/// discarded instead of being misread.
class QuizStore {
  QuizStore._();

  static const _kVersion = 'vv.model_version';
  static const _kPrakriti = 'vv.prakriti_answers';
  static const _kVikriti = 'vv.vikriti_answers';
  static const _kDoneDate = 'vv.done_date';
  static const _kDone = 'vv.done_ids';

  static String _enc(List<int>? xs) => xs == null ? '' : xs.join(',');

  static List<int>? _dec(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      return s.split(',').map(int.parse).toList();
    } on FormatException {
      return null;
    }
  }

  /// Loads saved data into [s]. Never throws: storage can be unavailable
  /// (private browsing, blocked site data), and then the app simply starts
  /// fresh.
  static Future<void> restore(AppState s, {DoshaPredictor? model}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final m = model ?? await DoshaPredictor.load();
      final pa = _dec(prefs.getString(_kPrakriti));
      final va = _dec(prefs.getString(_kVikriti));
      bool valid(List<int> a, int n, int maxOpt) => a.length == n && a.every((x) => x >= 0 && x <= maxOpt);
      if (prefs.getInt(_kVersion) == m.version && pa != null && valid(pa, m.nQuestions, m.optionsPerQuestion - 1)) {
        s.prakritiAnswers = pa;
        s.prediction = m.predict(pa);
        if (va != null && valid(va, m.vikritiQuestions.length, 2)) {
          s.vikritiAnswers = va;
          s.vikritiLabels = [for (final q in m.vikritiQuestions) q.options];
        }
      }
      final today = AppState.dayKey(DateTime.now());
      if (prefs.getString(_kDoneDate) == today) {
        s.doneDate = today;
        s.dinacharyaDone = (prefs.getStringList(_kDone) ?? const []).toSet();
      }
    } catch (e) {
      debugPrint('QuizStore.restore: $e');
    }
  }

  /// Writes the current quiz result and ticks. Never throws.
  static Future<void> save(AppState s) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final m = await DoshaPredictor.load();
      await prefs.setInt(_kVersion, m.version);
      await prefs.setString(_kPrakriti, _enc(s.prakritiAnswers));
      await prefs.setString(_kVikriti, _enc(s.vikritiAnswers));
      await prefs.setString(_kDoneDate, s.doneDate);
      await prefs.setStringList(_kDone, s.dinacharyaDone.toList());
    } catch (e) {
      debugPrint('QuizStore.save: $e');
    }
  }

  /// Restores saved data, then saves again whenever the app state changes.
  static Future<void> attach(AppState s) async {
    await restore(s);
    s.addListener(() => save(s));
  }
}
