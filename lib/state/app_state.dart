import 'package:flutter/foundation.dart';
import 'package:veda_verse/ai/health_ai.dart';
import 'package:veda_verse/engine/plan_engine.dart';
import 'package:veda_verse/l10n/lang.dart';
import 'package:veda_verse/ml/dosha_predictor.dart';
import 'package:veda_verse/ml/vikriti.dart';

/// App state for the logged-in account. The profile is saved per account by
/// Accounts (lib/state/accounts.dart), the quiz result and today's ticks by
/// QuizStore. Lab reports and Buddy flags stay in memory. Firebase later.
///
/// The field defaults are demo data used by tests and screenshots; a new
/// account starts blank (see [resetForNewAccount]).
class AppState extends ChangeNotifier {
  AppState._();
  static final AppState instance = AppState._();

  /// The logged-in account ("VV-…") and its email. Empty when logged out.
  String accountId = '';
  String email = '';

  /// True once this account finished consent and the 4 intake steps.
  bool onboarded = false;

  String name = 'Aarav Mehta';
  int age = 27;
  String gender = 'Female';

  /// 'EN' or 'HI'. Set it with Lang.set, which redraws the app.
  String get language => Lang.code;
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

  /// Vaidya consults this account booked, oldest first.
  List<Booking> bookings = [];

  /// Learn articles the user saved (article ids).
  Set<String> savedArticles = {};

  /// Yoga sessions the user booked or joined (YogaSession.titleEn).
  Set<String> joinedSessions = {};

  /// Booked consults that haven't ended yet (a consult lasts 30 minutes),
  /// soonest first.
  List<Booking> get upcoming {
    final now = DateTime.now().subtract(const Duration(minutes: 30));
    return bookings.where((b) => b.when.isAfter(now)).toList()..sort((a, b) => a.when.compareTo(b.when));
  }

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
        pregnancy: pregnancy.isEmpty ? 'No' : pregnancy,
        allergies: allergies,
        medicines: medicines,
        ritu: rituKeyFor(DateTime.now()),
      );

  String get firstName => name.trim().split(' ').first;
  String get initial => name.trim().isEmpty ? 'A' : name.trim()[0].toUpperCase();

  bool get flaggedForVaidya =>
      conditions.any((c) => c != 'None of these') ||
      (gender == 'Female' && (pregnancy == 'Pregnant' || pregnancy == 'Breastfeeding'));

  /// True once the user has finished the Prakriti quiz.
  bool get hasPrakriti => prediction != null;

  /// "Vata dominant", "Vata-Pitta", "Tridoshic", or "Not checked yet"
  /// before the quiz. Nothing is guessed for a new user. In Hindi when the
  /// app is in Hindi ("वात प्रधान", "वात-पित्त", "त्रिदोषज").
  String get prakritiLabel {
    final p = prediction;
    if (p == null) return tr('Not checked yet');
    if (p.type == 'Tridoshic') return tr('Tridoshic');
    if (p.type.contains('-')) return p.type.split('-').map(tr).join('-');
    return trf('{dosha} dominant', {'dosha': tr(p.dominant)});
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

  /// A brand-new account: every intake answer empty so the user must fill
  /// each one in. Keeps the welcome-screen picks, which pre-select "Your story".
  void resetForNewAccount({required String id, required String email}) {
    accountId = id;
    this.email = email;
    onboarded = false;
    name = '';
    age = 0;
    gender = '';
    since = '';
    conditions = {};
    pregnancy = '';
    allergies = [];
    medicines = [];
    consentStore = true;
    consentVaidya = true;
    consentAi = false;
    consentNotify = true;
    streak = 0;
    bookings = [];
    savedArticles = {};
    joinedSessions = {};
    _clearResults();
    notifyListeners();
  }

  /// Logged out: forget everything that belonged to the account.
  void clearAccount() {
    resetForNewAccount(id: '', email: '');
    issues = {};
    welcomeTiles = {};
  }

  void _clearResults() {
    prediction = null;
    prakritiAnswers = null;
    vikritiAnswers = null;
    vikritiLabels = const [];
    labReport = null;
    buddyFlags.clear();
    dinacharyaDone = {};
    doneDate = '';
  }

  /// The profile part saved per account (quiz answers are saved by QuizStore).
  Map<String, Object?> toProfile() => {
        'onboarded': onboarded,
        'name': name,
        'age': age,
        'gender': gender,
        'issues': issues.toList(),
        'since': since,
        'conditions': conditions.toList(),
        'pregnancy': pregnancy,
        'allergies': allergies,
        'medicines': medicines,
        'welcomeTiles': welcomeTiles.toList(),
        'consentStore': consentStore,
        'consentVaidya': consentVaidya,
        'consentAi': consentAi,
        'consentNotify': consentNotify,
        'streak': streak,
        'savedArticles': savedArticles.toList(),
        'joinedSessions': joinedSessions.toList(),
        'bookings': [for (final b in bookings) b.toJson()],
      };

  /// Loads a saved profile for account [id]. Unknown or missing fields fall
  /// back to empty, so an old or damaged save never crashes the app.
  void loadProfile(Map<String, Object?> p, {required String id, required String email}) {
    resetForNewAccount(id: id, email: email);
    List<String> strs(Object? v) => v is List ? [for (final x in v) if (x is String) x] : <String>[];
    String str(Object? v) => v is String ? v : '';
    onboarded = p['onboarded'] == true;
    name = str(p['name']);
    age = p['age'] is int ? p['age'] as int : 0;
    gender = str(p['gender']);
    issues = strs(p['issues']).toSet();
    since = str(p['since']);
    conditions = strs(p['conditions']).toSet();
    pregnancy = str(p['pregnancy']);
    allergies = strs(p['allergies']);
    medicines = strs(p['medicines']);
    welcomeTiles = strs(p['welcomeTiles']).toSet();
    consentStore = true;
    consentVaidya = p['consentVaidya'] != false;
    consentAi = p['consentAi'] == true;
    consentNotify = p['consentNotify'] != false;
    streak = p['streak'] is int ? p['streak'] as int : 0;
    savedArticles = strs(p['savedArticles']).toSet();
    joinedSessions = strs(p['joinedSessions']).toSet();
    bookings = [
      if (p['bookings'] is List)
        for (final b in p['bookings'] as List)
          if (Booking.fromJson(b) case final Booking ok) ok,
    ];
    notifyListeners();
  }
}

/// A Vaidya consult the user booked.
class Booking {
  /// The Vaidya's name, e.g. "Dr. Rohan Kapoor" (see `vaidyas`).
  final String vaidya;
  final DateTime when;

  /// 'Video', 'In clinic' or 'Phone' (English; shown with tr()).
  final String mode;

  /// The user agreed to share their health summary with this Vaidya.
  final bool shareSummary;

  const Booking({required this.vaidya, required this.when, required this.mode, this.shareSummary = true});

  Map<String, Object> toJson() => {'vaidya': vaidya, 'when': when.toIso8601String(), 'mode': mode, 'share': shareSummary};

  /// Null for anything that isn't a valid saved booking.
  static Booking? fromJson(Object? j) {
    if (j is! Map) return null;
    final when = DateTime.tryParse('${j['when']}');
    final vaidya = j['vaidya'];
    final mode = j['mode'];
    if (when == null || vaidya is! String || mode is! String) return null;
    return Booking(vaidya: vaidya, when: when, mode: mode, shareSummary: j['share'] != false);
  }
}
