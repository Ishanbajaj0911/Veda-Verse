import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:veda_verse/ml/dosha_predictor.dart';
import 'package:veda_verse/ml/vikriti.dart';

void main() {
  late DoshaPredictor predictor;
  late Map<String, dynamic> json;
  const n = 18;

  setUpAll(() {
    json = jsonDecode(File('assets/ml/dosha_model.json').readAsStringSync()) as Map<String, dynamic>;
    predictor = DoshaPredictor.fromJson(json);
  });

  test('model v3 shape: 18 questions x 3 options plus 3 optional banks', () {
    expect(predictor.version, 3);
    expect(predictor.classes, ['Vata', 'Pitta', 'Kapha']);
    expect(predictor.nQuestions, n);
    expect(predictor.nFeatures, 90);
    expect(predictor.coef.length, 3);
    expect(predictor.coef[0].length, 90);
    expect(predictor.questions.length, n);
    expect(predictor.tieBreakerBanks.length, 3);
    for (final b in predictor.tieBreakerBanks) {
      expect(b.questions.length, 6);
      expect(b.pair.length, 2);
    }
  });

  test('every question has 3 options in English and Hindi', () {
    for (final q in [...predictor.questions, ...predictor.vikritiQuestions]) {
      expect(q.options.length, 3, reason: q.title);
      expect(q.titleHi, isNotNull, reason: q.title);
      expect(q.optionsHi?.length, 3, reason: q.title);
    }
    expect(predictor.vikritiQuestions.length, 6);
  });

  test('dropped questions are gone', () {
    final titles = predictor.questions.map((q) => q.title.toLowerCase()).join(' | ');
    for (final gone in ['complexion', 'color of hair', 'wealth', 'dreams', 'nails', 'teeth', 'eyeball', 'social']) {
      expect(titles.contains(gone), isFalse, reason: gone);
    }
  });

  test('all-Vata answers predict Vata, all-Pitta Pitta, all-Kapha Kapha', () {
    final allA = predictor.predict(List.filled(n, 0));
    final allB = predictor.predict(List.filled(n, 1));
    final allC = predictor.predict(List.filled(n, 2));
    expect(allA.type, 'Vata');
    expect(allB.type, 'Pitta');
    expect(allC.type, 'Kapha');
    expect(allA['Vata'], greaterThan(0.9));
    expect(allB['Pitta'], greaterThan(0.9));
    expect(allC['Kapha'], greaterThan(0.9));
  });

  test('probabilities sum to 1', () {
    final p = predictor.predict(List.generate(n, (i) => i % 3));
    final sum = p.probabilities.values.fold<double>(0, (a, b) => a + b);
    expect(sum, closeTo(1.0, 1e-9));
  });

  test('evenly mixed answers give Tridoshic', () {
    expect(predictor.predict(List.generate(n, (i) => i % 3)).type, 'Tridoshic');
  });

  test('half Vata half Pitta gives a dual Vata-Pitta type', () {
    for (final answers in [
      List.generate(n, (i) => i.isEven ? 0 : 1),
      List.generate(n, (i) => i < n ~/ 2 ? 0 : 1),
    ]) {
      final p = predictor.predict(answers);
      expect(p.type, anyOf('Vata-Pitta', 'Pitta-Vata'));
      expect(p['Kapha'], lessThan(0.15));
    }
  });

  test('2:1 Vata:Pitta answers give single Vata', () {
    final p = predictor.predict([...List.filled(12, 0), ...List.filled(6, 1)]);
    expect(p.type, 'Vata');
    expect(p['Pitta'], greaterThan(0.05));
  });

  test('optional tie-breaker answers still move the prediction', () {
    final base = List.generate(n, (i) => i < n ~/ 2 ? 0 : 1);
    final before = predictor.predict(base);
    final bank = predictor.tieBreakerBankFor(before);
    final toFirst = predictor.predict(base, tieBreakerBank: bank, tieBreakerAnswers: List.filled(6, 0));
    final toSecond = predictor.predict(base, tieBreakerBank: bank, tieBreakerAnswers: List.filled(6, 1));
    expect(toFirst[bank.pair[0]], greaterThan(before[bank.pair[0]]));
    expect(toSecond[bank.pair[1]], greaterThan(before[bank.pair[1]]));
  });

  test('matches the Python (scikit-learn) reference outputs exported with the model', () {
    final samples = (json['sample_io'] as List).cast<Map<String, dynamic>>();
    expect(samples, isNotEmpty);
    for (final s in samples) {
      final answers = (s['answers'] as List).cast<int>();
      final bank = s['tiebreaker_bank'] as int?;
      final p = predictor.predict(
        answers,
        tieBreakerBank: bank == null ? null : predictor.tieBreakerBanks[bank],
        tieBreakerAnswers: (s['tiebreaker_answers'] as List?)?.cast<int>(),
      );
      final ref = (s['probs'] as List).map((v) => (v as num).toDouble()).toList();
      expect(p['Vata'], closeTo(ref[0], 1e-5));
      expect(p['Pitta'], closeTo(ref[1], 1e-5));
      expect(p['Kapha'], closeTo(ref[2], 1e-5));
    }
  });

  test('rejects malformed input', () {
    expect(() => predictor.predict([0, 1, 2]), throwsArgumentError);
    expect(() => predictor.predict(List.filled(30, 0)), throwsArgumentError);
    expect(
      () => predictor.predict(List.filled(n, 0),
          tieBreakerBank: predictor.tieBreakerBanks[0], tieBreakerAnswers: [0, 1]),
      throwsArgumentError,
    );
  });

  group('Explaining a result', () {
    test('every question has a short trait phrase per option', () {
      for (final q in predictor.questions) {
        expect(q.traits?.length, 3, reason: q.title);
      }
    });

    test('names the answers that pushed hardest toward the dosha', () {
      final answers = List.filled(n, 0);
      final p = predictor.predict(answers);
      final why = predictor.explain(answers, p);
      expect(why, startsWith('Mostly from your '));
      final top = predictor.topReasons(answers, 'Vata');
      expect(top.length, 3);
      for (final q in top) {
        expect(why, contains(predictor.questions[q].traits![0]));
      }
      // The strongest pushes are the most important questions.
      expect(top, contains(0), reason: 'body build is the strongest Vata signal');
    });

    test('only answers that point to the dosha count', () {
      // One Pitta answer among Kapha ones: it must not explain Kapha.
      final answers = [1, ...List.filled(n - 1, 2)];
      expect(predictor.topReasons(answers, 'Kapha', count: n), isNot(contains(0)));
      expect(predictor.topReasons(answers, 'Pitta'), [0]);
    });

    test('dual and tridoshic results get matching sentences', () {
      final dual = List.generate(n, (i) => i < n ~/ 2 ? 0 : 1);
      final pd = predictor.predict(dual);
      expect(predictor.explain(dual, pd), matches(RegExp(r'^(Vata|Pitta) mostly from your .+; (Vata|Pitta) from your .+\.$')));
      final even = List.generate(n, (i) => i % 3);
      expect(predictor.explain(even, predictor.predict(even)), contains('spread evenly'));
    });
  });

  group('Vikriti (last 2 weeks)', () {
    List<List<String>> labels() => [for (final q in predictor.vikritiQuestions) q.options];

    test('a clear majority marks that dosha as raised and lists its signs', () {
      final v = VikritiResult.fromAnswers([1, 1, 1, 0, 2, 1], labels());
      expect(v.raised, 'Pitta');
      expect(v.votes, {'Vata': 1, 'Pitta': 4, 'Kapha': 1});
      expect(v.signs.length, 4);
      expect(v.signs.first, predictor.vikritiQuestions[0].options[1]);
      expect(v.summary, startsWith('Pitta is raised right now'));
      expect(v.percent.values.reduce((a, b) => a + b), 100);
    });

    test('exactly half the answers is enough', () {
      expect(VikritiResult.fromAnswers([2, 2, 2, 0, 1, 0], labels()).raised, 'Kapha');
    });

    test('a tie or a weak lead raises nothing', () {
      expect(VikritiResult.fromAnswers([0, 0, 1, 1, 2, 2], labels()).raised, isNull);
      expect(VikritiResult.fromAnswers([0, 0, 0, 1, 1, 1], labels()).raised, isNull);
      expect(VikritiResult.fromAnswers([0, 0, 1, 1, 2, 2], labels()).summary,
          'No single dosha stands out right now.');
    });

    test('rejects malformed input', () {
      expect(() => VikritiResult.fromAnswers([0, 1], labels()), throwsArgumentError);
      expect(() => VikritiResult.fromAnswers([0, 1, 2, 3, 0, 1], labels()), throwsArgumentError);
    });
  });
}
