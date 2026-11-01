import 'package:veda_verse/l10n/lang.dart';

/// Current imbalance (Vikriti) from the quiz's 6 "last 2 weeks" questions,
/// supported by the concerns the user picked in "Your story" (intake step 2).
///
/// Deliberately a transparent vote count, not a model:
///  * each quiz answer is one vote for Vata, Pitta or Kapha (options are in
///    that order);
///  * each intake concern is half a vote for the dosha it points to, so the
///    quiz stays the main signal and the concerns break near-ties.
/// A dosha counts as raised when its votes are worth at least half the quiz
/// answers (3 of 6) and it leads strictly. A rough fortnight never changes the
/// lifelong Prakriti.
class VikritiResult {
  /// Votes per dosha, keyed Vata / Pitta / Kapha.
  final Map<String, double> votes;

  /// The raised dosha, or null when no single dosha stands out.
  final String? raised;

  /// What points to the raised dosha, quiz answers first then intake
  /// concerns, e.g. "Acidity or burning", "acidity". Empty when [raised] is
  /// null.
  final List<String> signs;

  const VikritiResult({required this.votes, required this.raised, required this.signs});

  static const doshas = ['Vata', 'Pitta', 'Kapha'];

  /// Weight of one intake concern relative to one quiz answer.
  static const concernWeight = 0.5;

  /// Intake concern -> (dosha it usually points to, short phrase for text).
  static const concerns = <String, (String, String)>{
    'Can’t sleep': ('Vata', 'poor sleep'),
    'Always stressed': ('Vata', 'stress'),
    'Acidity': ('Pitta', 'acidity'),
    'Back pain': ('Vata', 'back pain'),
    'Low energy': ('Kapha', 'low energy'),
    'Weight gain': ('Kapha', 'weight gain'),
    'Skin issues': ('Pitta', 'skin issues'),
    'Irregular periods': ('Vata', 'irregular periods'),
  };

  double get total => votes.values.fold(0.0, (a, b) => a + b);

  /// Whole percentages that sum to 100.
  Map<String, int> get percent {
    final t = total;
    if (t == 0) return {for (final d in doshas) d: 0};
    final v = (votes['Vata']! * 100 / t).round();
    final p = (votes['Pitta']! * 100 / t).round();
    return {'Vata': v, 'Pitta': p, 'Kapha': 100 - v - p};
  }

  /// [answers] holds one option index (0 Vata, 1 Pitta, 2 Kapha) per question;
  /// [optionLabels] are the matching question options, used for [signs].
  /// [intakeConcerns] are the "Your story" picks; unknown ones are ignored.
  factory VikritiResult.fromAnswers(
    List<int> answers,
    List<List<String>> optionLabels, {
    Iterable<String> intakeConcerns = const [],
  }) {
    if (answers.length != optionLabels.length) {
      throw ArgumentError('Expected ${optionLabels.length} answers, got ${answers.length}');
    }
    final votes = {for (final d in doshas) d: 0.0};
    for (final a in answers) {
      if (a < 0 || a > 2) throw ArgumentError('Answer $a out of range');
      votes[doshas[a]] = votes[doshas[a]]! + 1;
    }
    final known = [for (final c in intakeConcerns) if (concerns.containsKey(c)) concerns[c]!];
    for (final (dosha, _) in known) {
      votes[dosha] = votes[dosha]! + concernWeight;
    }
    final ranked = votes.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = ranked[0], second = ranked[1];
    // Raised = votes worth at least half the quiz answers (3 of 6) and a
    // strict lead. Concerns can only help a dosha over that line.
    final raised =
        (answers.isNotEmpty && top.value * 2 >= answers.length && top.value > second.value) ? top.key : null;
    final signs = raised == null
        ? const <String>[]
        : [
            for (var i = 0; i < answers.length; i++)
              if (doshas[answers[i]] == raised) optionLabels[i][answers[i]],
            for (final (dosha, phrase) in known)
              if (dosha == raised) phrase,
          ];
    return VikritiResult(votes: votes, raised: raised, signs: signs);
  }

  /// The first [n] [signs] for a sentence, in the app's language:
  /// "acidity or burning and skin issues" / "एसिडिटी या जलन और त्वचा की परेशानी".
  String shownSigns([int n = 2]) => Lang.hi
      ? signs.take(n).map(tr).join(' ${tr('and')} ')
      : signs.take(n).map((s) => s.toLowerCase()).join(' and ');

  /// One plain sentence for the Dosha tab and result screen.
  String get summary {
    if (raised == null) return tr('No single dosha stands out right now.');
    return trf('{dosha} is raised right now — matches your {signs}.', {'dosha': tr(raised!), 'signs': shownSigns()});
  }
}
