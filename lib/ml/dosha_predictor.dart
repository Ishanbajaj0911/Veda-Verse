import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart' show rootBundle;

/// Result of a dosha prediction.
class DoshaPrediction {
  /// Probability for each class, keyed by dosha name (Vata, Pitta, Kapha).
  final Map<String, double> probabilities;

  /// Dominant dosha (highest probability).
  final String dominant;

  /// Human readable type: "Pitta", "Vata-Pitta" or "Tridoshic".
  final String type;

  /// Whether a tie-breaker round was included in this prediction.
  final bool usedTieBreaker;

  const DoshaPrediction({
    required this.probabilities,
    required this.dominant,
    required this.type,
    this.usedTieBreaker = false,
  });

  /// Classes ordered from most to least likely.
  List<MapEntry<String, double>> get ranked {
    final list = probabilities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list;
  }

  /// Probability of the dominant dosha.
  double get confidence => probabilities[dominant] ?? 0.0;

  double operator [](String dosha) => probabilities[dosha] ?? 0.0;

  @override
  String toString() => 'DoshaPrediction($type, $probabilities)';
}

/// A set of 6 two-way questions that separate two specific doshas.
class TieBreakerBank {
  final int index;
  final List<String> pair; // [first dosha, second dosha]
  final List<TieBreakerQuestion> questions;

  const TieBreakerBank({
    required this.index,
    required this.pair,
    required this.questions,
  });

  String get title => '${pair[0]} vs ${pair[1]}';
}

class TieBreakerQuestion {
  final String title;
  final List<String> options; // option 0 = pair[0] trait, option 1 = pair[1] trait
  final String? titleHi;
  final List<String>? optionsHi;
  const TieBreakerQuestion({required this.title, required this.options, this.titleHi, this.optionsHi});
}

/// A quiz question with options in [Vata, Pitta, Kapha] order, plus optional
/// Hindi text. Used for the base Prakriti questions and the Vikriti ones.
class QuizQuestion {
  final String title;
  final List<String> options;
  final String? titleHi;
  final List<String>? optionsHi;

  /// Short phrase per option for explanations, e.g. "slim build".
  final List<String>? traits;
  const QuizQuestion({required this.title, required this.options, this.titleHi, this.optionsHi, this.traits});

  factory QuizQuestion.fromJson(Map<String, dynamic> q) => QuizQuestion(
        title: q['title'] as String,
        options: (q['options'] as List).cast<String>(),
        titleHi: q['title_hi'] as String?,
        optionsHi: (q['options_hi'] as List?)?.cast<String>(),
        traits: (q['traits'] as List?)?.cast<String>(),
      );
}

/// Pure-Dart inference for the multinomial logistic regression model trained
/// by `ml/train_dosha_model.py` and shipped as `assets/ml/dosha_model.json`.
///
///  1. [predict] from the base answers (18 in model v3).
///  2. Optional: if [needsTieBreaker] is true, a client may ask the bank from
///     [tieBreakerBankFor] and call [predict] again with `tieBreakerBank` /
///     `tieBreakerAnswers`. The app currently does not.
///
/// [vikritiQuestions] ("the last 2 weeks") are not model inputs; score them
/// with [VikritiResult.fromAnswers].
///
/// No runtime dependency (no TensorFlow Lite, no server), so it runs
/// identically on web, desktop and mobile.
class DoshaPredictor {
  final List<String> classes;
  final int nQuestions;
  final int optionsPerQuestion;
  final int nFeatures;
  final List<double> intercept; // [nClasses]
  final List<List<double>> coef; // [nClasses][nFeatures]
  final List<double> questionImportance;
  final List<QuizQuestion> questions;
  final List<QuizQuestion> vikritiQuestions;
  final List<TieBreakerBank> tieBreakerBanks;
  final double confidenceThreshold;
  final double testAccuracy;
  final int version;

  /// If the second-strongest dosha holds at least this share of the mix, the
  /// result is reported as a dual type (e.g. Vata-Pitta).
  static const double dualThreshold = 0.30;

  /// If every dosha holds at least this share of the mix, the result is
  /// reported as Tridoshic (balanced constitution).
  static const double tridoshicThreshold = 0.25;

  static const int tieBreakerQuestionsPerBank = 6;

  int get _baseFeatures => nQuestions * optionsPerQuestion;

  DoshaPredictor._({
    required this.classes,
    required this.nQuestions,
    required this.optionsPerQuestion,
    required this.nFeatures,
    required this.intercept,
    required this.coef,
    required this.questionImportance,
    required this.questions,
    required this.vikritiQuestions,
    required this.tieBreakerBanks,
    required this.confidenceThreshold,
    required this.testAccuracy,
    required this.version,
  });

  static DoshaPredictor? _cached;

  /// Loads (and caches) the model from the app bundle.
  static Future<DoshaPredictor> load({
    String assetPath = 'assets/ml/dosha_model.json',
  }) async {
    if (_cached != null) return _cached!;
    final raw = await rootBundle.loadString(assetPath);
    _cached = DoshaPredictor.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    return _cached!;
  }

  factory DoshaPredictor.fromJson(Map<String, dynamic> json) {
    final classes = (json['classes'] as List).cast<String>();
    final coef = (json['coef'] as List)
        .map((row) => (row as List).map((v) => (v as num).toDouble()).toList())
        .toList();
    final nQuestions = json['n_questions'] as int;
    final perQ = json['options_per_question'] as int;
    final nFeatures = (json['n_features'] as int?) ?? nQuestions * perQ;
    assert(coef.length == classes.length);
    assert(coef.every((row) => row.length == nFeatures));

    final banks = <TieBreakerBank>[];
    final rawBanks = (json['tiebreaker_banks'] as List?) ?? const [];
    for (var k = 0; k < rawBanks.length; k++) {
      final bk = rawBanks[k] as Map<String, dynamic>;
      banks.add(TieBreakerBank(
        index: k,
        pair: (bk['pair'] as List).cast<String>(),
        questions: (bk['questions'] as List)
            .map((q) => TieBreakerQuestion(
                  title: q['title'] as String,
                  options: (q['options'] as List).cast<String>(),
                  titleHi: q['title_hi'] as String?,
                  optionsHi: (q['options_hi'] as List?)?.cast<String>(),
                ))
            .toList(),
      ));
    }

    return DoshaPredictor._(
      classes: classes,
      nQuestions: nQuestions,
      optionsPerQuestion: perQ,
      nFeatures: nFeatures,
      intercept:
          (json['intercept'] as List).map((v) => (v as num).toDouble()).toList(),
      coef: coef,
      questionImportance: ((json['question_importance'] as List?) ?? const [])
          .map((v) => (v as num).toDouble())
          .toList(),
      questions: ((json['questions'] as List?) ?? const [])
          .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
          .toList(),
      vikritiQuestions: ((json['vikriti_questions'] as List?) ?? const [])
          .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
          .toList(),
      tieBreakerBanks: banks,
      confidenceThreshold:
          ((json['confidence_threshold'] as num?) ?? 0.7).toDouble(),
      testAccuracy: ((json['test_accuracy_stage1'] ??
                  json['test_accuracy_adaptive'] ??
                  json['test_accuracy'] ??
                  0) as num)
          .toDouble(),
      version: (json['version'] as int?) ?? 1,
    );
  }

  /// True when the base-question prediction is not confident enough and a
  /// tie-breaker round should be asked.
  bool needsTieBreaker(DoshaPrediction p) =>
      tieBreakerBanks.isNotEmpty &&
      !p.usedTieBreaker &&
      p.confidence < confidenceThreshold;

  /// The bank covering the two leading doshas of [p].
  TieBreakerBank tieBreakerBankFor(DoshaPrediction p) {
    final top = p.ranked;
    final want = {top[0].key, top[1].key};
    return tieBreakerBanks.firstWhere(
      (b) => b.pair.toSet().containsAll(want),
      orElse: () => throw StateError('No tie-breaker bank for $want'),
    );
  }

  /// [answers] holds one option index (0 = Vata option, 1 = Pitta option,
  /// 2 = Kapha option) per base question, in question order.
  ///
  /// [tieBreakerBank] and [tieBreakerAnswers] (6 values, 0 = first dosha of
  /// the pair, 1 = second) are optional and come from the adaptive round.
  DoshaPrediction predict(
    List<int> answers, {
    TieBreakerBank? tieBreakerBank,
    List<int>? tieBreakerAnswers,
  }) {
    if (answers.length != nQuestions) {
      throw ArgumentError(
        'Expected $nQuestions answers, got ${answers.length}',
      );
    }
    if ((tieBreakerBank == null) != (tieBreakerAnswers == null)) {
      throw ArgumentError('Provide both tieBreakerBank and tieBreakerAnswers');
    }
    if (tieBreakerAnswers != null &&
        tieBreakerAnswers.length != tieBreakerQuestionsPerBank) {
      throw ArgumentError(
        'Expected $tieBreakerQuestionsPerBank tie-breaker answers, '
        'got ${tieBreakerAnswers.length}',
      );
    }

    // Active one-hot feature indices (sparse): base block + optional bank.
    final active = <int>[];
    for (var q = 0; q < nQuestions; q++) {
      final a = answers[q];
      if (a < 0 || a >= optionsPerQuestion) {
        throw ArgumentError('Answer $a out of range at question $q');
      }
      active.add(q * optionsPerQuestion + a);
    }
    if (tieBreakerBank != null) {
      final base = _baseFeatures +
          tieBreakerBank.index * tieBreakerQuestionsPerBank * 2;
      for (var j = 0; j < tieBreakerQuestionsPerBank; j++) {
        final a = tieBreakerAnswers![j];
        if (a < 0 || a > 1) {
          throw ArgumentError('Tie-breaker answer $a out of range at $j');
        }
        active.add(base + j * 2 + a);
      }
    }

    // logit_c = b_c + sum over active features of coef[c][f]
    final logits = List<double>.generate(classes.length, (c) {
      var z = intercept[c];
      for (final f in active) {
        z += coef[c][f];
      }
      return z;
    });

    // Softmax (numerically stable)
    final maxLogit = logits.reduce(math.max);
    final exps = logits.map((z) => math.exp(z - maxLogit)).toList();
    final sum = exps.fold<double>(0, (s, e) => s + e);
    final probs = <String, double>{
      for (var c = 0; c < classes.length; c++) classes[c]: exps[c] / sum,
    };

    final ranked = probs.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = ranked[0], second = ranked[1], third = ranked[2];

    String type;
    if (third.value >= tridoshicThreshold) {
      type = 'Tridoshic';
    } else if (second.value >= dualThreshold) {
      type = '${top.key}-${second.key}';
    } else {
      type = top.key;
    }

    return DoshaPrediction(
      probabilities: probs,
      dominant: top.key,
      type: type,
      usedTieBreaker: tieBreakerBank != null,
    );
  }

  /// The answers that pushed hardest toward [dosha], strongest first.
  ///
  /// The model is logistic regression, so each answer adds a fixed weight to
  /// every dosha's score. An answer's push toward [dosha] is its weight for
  /// [dosha] minus its average weight over all doshas; only answers with a
  /// positive push are returned, at most [count]. Returns question indices.
  List<int> topReasons(List<int> answers, String dosha, {int count = 3}) {
    if (answers.length != nQuestions) {
      throw ArgumentError('Expected $nQuestions answers, got ${answers.length}');
    }
    final c = classes.indexOf(dosha);
    if (c < 0) throw ArgumentError('Unknown dosha $dosha');
    final pushes = <(int, double)>[];
    for (var q = 0; q < nQuestions; q++) {
      final f = q * optionsPerQuestion + answers[q];
      var mean = 0.0;
      for (final row in coef) {
        mean += row[f];
      }
      mean /= coef.length;
      final push = coef[c][f] - mean;
      if (push > 0) pushes.add((q, push));
    }
    pushes.sort((a, b) => b.$2.compareTo(a.$2));
    return [for (final p in pushes.take(count)) p.$1];
  }

  /// One plain sentence explaining [p] from the user's [answers], e.g.
  /// "Mostly from your slim build, dry skin and light sleep."
  String explain(List<int> answers, DoshaPrediction p) {
    String phrases(String dosha, int n) {
      final qs = topReasons(answers, dosha, count: n);
      final ts = [
        for (final q in qs)
          if (questions.length > q && (questions[q].traits?.length ?? 0) > answers[q]) questions[q].traits![answers[q]],
      ];
      if (ts.isEmpty) return '';
      if (ts.length == 1) return ts.first;
      return '${ts.sublist(0, ts.length - 1).join(', ')} and ${ts.last}';
    }

    if (p.type == 'Tridoshic') {
      return 'Your answers are spread evenly across Vata, Pitta and Kapha.';
    }
    if (p.type.contains('-')) {
      final a = p.ranked[0].key, b = p.ranked[1].key;
      final pa = phrases(a, 2), pb = phrases(b, 2);
      if (pa.isEmpty || pb.isEmpty) return '';
      return '$a mostly from your $pa; $b from your $pb.';
    }
    final top = phrases(p.dominant, 3);
    return top.isEmpty ? '' : 'Mostly from your $top.';
  }

  /// Convenience for the quiz screen, which stores answers as "A"/"B"/"C".
  DoshaPrediction predictFromLetters(
    List<String> letters, {
    TieBreakerBank? tieBreakerBank,
    List<String>? tieBreakerLetters,
  }) {
    return predict(
      letters.map(_letterIndex).toList(),
      tieBreakerBank: tieBreakerBank,
      tieBreakerAnswers: tieBreakerLetters?.map(_letterIndex).toList(),
    );
  }

  static int _letterIndex(String l) => l.toUpperCase().codeUnitAt(0) - 65;
}
