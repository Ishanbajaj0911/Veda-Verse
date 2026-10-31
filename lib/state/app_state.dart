import 'package:flutter/foundation.dart';
import 'package:veda_verse/ml/dosha_predictor.dart';

/// In-memory app state for the demo build. Firebase persistence comes later.
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
  int streak = 7;
  Set<int> dinacharyaDone = {0};

  String get firstName => name.trim().split(' ').first;
  String get initial => name.trim().isEmpty ? 'A' : name.trim()[0].toUpperCase();

  bool get flaggedForVaidya =>
      conditions.any((c) => c != 'None of these') ||
      (gender == 'Female' && pregnancy != 'No');

  String get prakritiLabel {
    final p = prediction;
    if (p == null) return 'Vata dominant';
    if (p.type == 'Tridoshic') return 'Tridoshic';
    if (p.type.contains('-')) return p.type;
    return '${p.dominant} dominant';
  }

  /// Vata / Pitta / Kapha shares as whole percentages (sum to 100).
  Map<String, int> get mix {
    final p = prediction;
    if (p == null) return {'Vata': 45, 'Pitta': 30, 'Kapha': 25};
    final v = (p['Vata'] * 100).round();
    final pi = (p['Pitta'] * 100).round();
    return {'Vata': v, 'Pitta': pi, 'Kapha': 100 - v - pi};
  }

  void update(void Function(AppState s) fn) {
    fn(this);
    notifyListeners();
  }
}
