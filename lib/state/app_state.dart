import 'package:flutter/foundation.dart';
import 'package:veda_verse/ai/health_ai.dart';
import 'package:veda_verse/engine/plan_engine.dart';
import 'package:veda_verse/ml/dosha_predictor.dart';
import 'package:veda_verse/ml/vikriti.dart';

/// App state for the demo build. The quiz result and today's plan ticks are
/// saved on the device by QuizStore (lib/state/quiz_store.dart); the rest is
/// in memory. Firebase persistence comes later.
class AppState extends ChangeNotifier {
  AppState._();
  static final AppState instance = AppState._();

  String name = 'Aarav Mehta';
  int age = 27;
  String gender = 'Female';
  String language = 'EN';
  Set<String> issues = {'Can’t sleep', 'Always stressed'};
  String since = '1–3 mo';
  Set<String> conditions = {'High BP'};
  String pregnancy = 'No';
  List<String> allergies = ['Peanuts'];
  List<String> medicines = ['Amlodipine 5 mg'];
  Set<String> welcomeTiles = {'Can’t sleep', 'Always stressed'};

  // Consent toggles
  bool consentStore = true;
  bool consentVaidya = true;
  bool consentAi = false;
  bool consentNotify = true;

  DoshaPrediction? prediction;

  /// Raw answers to the quiz's 18 Prakriti questions ([V, P, K] index). Saved
  /// on the device so the result survives a restart, and used to explain it.
  List<int>? prakritiAnswers;

  /// Raw answers to the quiz's 6 "last 2 weeks" questions ([V, P, K] index)
  /// and their option labels. Null until the quiz is done.
  List<int>? vikritiAnswers;
  List<List<String>> vikritiLabels = const [];

  /// The latest lab report read by Gemini (or the labelled sample).
  LabReport? labReport;

  /// Questions Ayu Buddy stopped (Vaidya / emergency cards), for the
  /// Vaidya's case sheet.
  final List<BuddyFlag> buddyFlags = [];

  int streak = 7;

  /// Ids of today's Dinacharya items the user ticked (see plan_engine.dart),
  /// and the day they belong to (yyyy-mm-dd). Ticks reset on a new day.
  Set<String> dinacharyaDone = {};
  String doneDate = '';

  static String dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Ticks or unticks a plan item for today.
  void toggleDone(String id) {
    final today = dayKey(DateTime.now());
    if (doneDate != today) {
      dinacharyaDone = {};
      doneDate = today;
    }
    dinacharyaDone.contains(id) ? dinacharyaDone.remove(id) : dinacharyaDone.add(id);
    notifyListeners();
  }

  /// Today's ticks only; yesterday's never carry over.
  Set<String> get doneToday => doneDate == dayKey(DateTime.now()) ? dinacharyaDone : const {};

  /// Current imbalance: the quiz's "last 2 weeks" answers plus the "Your
  /// story" concerns. Recomputed on read, so editing the intake updates it.
  VikritiResult? get vikriti {
    final a = vikritiAnswers;
    if (a == null) return null;
    return VikritiResult.fromAnswers(a, vikritiLabels, intakeConcerns: issues);
  }

  /// Snapshot for the rule engine (daily plan, yoga ranking).
  EngineInput get engineInput => EngineInput(
        prakriti: prediction,
        vikriti: vikriti,
        concerns: issues,
        conditions: conditions,
        gender: gender,
        pregnancy: pregnancy,
        allergies: allergies,
        medicines: medicines,
        ritu: rituKeyFor(DateTime.now()),
      );

  String get firstName => name.trim().split(' ').first;
  String get initial => name.trim().isEmpty ? 'A' : name.trim()[0].toUpperCase();

  bool get flaggedForVaidya =>
      conditions.any((c) => c != 'None of these') ||
      (gender == 'Female' && pregnancy != 'No');

  /// True once the user has finished the Prakriti quiz.
  bool get hasPrakriti => prediction != null;

  /// "Vata dominant", "Vata-Pitta", "Tridoshic", or "Not checked yet"
  /// before the quiz. Nothing is guessed for a new user.
  String get prakritiLabel {
    final p = prediction;
    if (p == null) return 'Not checked yet';
    if (p.type == 'Tridoshic') return 'Tridoshic';
    if (p.type.contains('-')) return p.type;
    return '${p.dominant} dominant';
  }

  /// Vata / Pitta / Kapha shares as whole percentages. All 0 until the quiz
  /// is done; after it they sum to 100.
  Map<String, int> get mix {
    final p = prediction;
    if (p == null) return {'Vata': 0, 'Pitta': 0, 'Kapha': 0};
    final v = (p['Vata'] * 100).round();
    final pi = (p['Pitta'] * 100).round();
    return {'Vata': v, 'Pitta': pi, 'Kapha': 100 - v - pi};
  }

  void update(void Function(AppState s) fn) {
    fn(this);
    notifyListeners();
  }
}
