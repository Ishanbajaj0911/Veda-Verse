import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:veda_verse/ml/dosha_predictor.dart';

void main() {
  late DoshaPredictor predictor;

  setUpAll(() {
    final raw = File('assets/ml/dosha_model.json').readAsStringSync();
    predictor = DoshaPredictor.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  });

  test('model shape matches the 30 x 3 quiz plus 3 tie-breaker banks', () {
    expect(predictor.classes, ['Vata', 'Pitta', 'Kapha']);
    expect(predictor.nQuestions, 30);
    expect(predictor.nFeatures, 126);
    expect(predictor.coef.length, 3);
    expect(predictor.coef[0].length, 126);
    expect(predictor.tieBreakerBanks.length, 3);
    for (final b in predictor.tieBreakerBanks) {
      expect(b.questions.length, 6);
      expect(b.pair.length, 2);
    }
  });

  test('all-A answers predict Vata, all-B Pitta, all-C Kapha', () {
    final allA = predictor.predict(List.filled(30, 0));
    final allB = predictor.predict(List.filled(30, 1));
    final allC = predictor.predict(List.filled(30, 2));
    expect(allA.type, 'Vata');
    expect(allB.type, 'Pitta');
    expect(allC.type, 'Kapha');
    expect(allA['Vata'], greaterThan(0.95));
    expect(allB['Pitta'], greaterThan(0.95));
    expect(allC['Kapha'], greaterThan(0.95));
    expect(predictor.needsTieBreaker(allA), isFalse);
  });

  test('probabilities sum to 1', () {
    final p = predictor.predict(List.generate(30, (i) => i % 3));
    final sum = p.probabilities.values.fold<double>(0, (a, b) => a + b);
    expect(sum, closeTo(1.0, 1e-9));
  });

  test('evenly mixed answers give Tridoshic and request a tie-breaker', () {
    final p = predictor.predict(List.generate(30, (i) => i % 3));
    expect(p.type, 'Tridoshic');
    expect(predictor.needsTieBreaker(p), isTrue);
  });

  test('half Vata half Pitta gives a dual type and the Vata/Pitta bank', () {
    for (final answers in [
      List.generate(30, (i) => i.isEven ? 0 : 1),
      List.generate(30, (i) => i < 15 ? 0 : 1),
    ]) {
      final p = predictor.predict(answers);
      expect(p.type, anyOf('Vata-Pitta', 'Pitta-Vata'));
      expect(p['Kapha'], lessThan(0.1));
      expect(predictor.needsTieBreaker(p), isTrue);
      expect(predictor.tieBreakerBankFor(p).pair.toSet(), {'Vata', 'Pitta'});
    }
  });

  test('tie-breaker answers move the prediction toward the chosen dosha', () {
    final base = List.generate(30, (i) => i < 15 ? 0 : 1);
    final before = predictor.predict(base);
    final bank = predictor.tieBreakerBankFor(before);
    final first = bank.pair[0]; // option 0 trait
    final second = bank.pair[1]; // option 1 trait

    final towardFirst = predictor.predict(base,
        tieBreakerBank: bank, tieBreakerAnswers: List.filled(6, 0));
    final towardSecond = predictor.predict(base,
        tieBreakerBank: bank, tieBreakerAnswers: List.filled(6, 1));

    expect(towardFirst[first], greaterThan(before[first]));
    expect(towardSecond[second], greaterThan(before[second]));
    expect(towardFirst.usedTieBreaker, isTrue);
    expect(predictor.needsTieBreaker(towardFirst), isFalse,
        reason: 'only one tie-breaker round is ever asked');
  });

  test('2:1 Vata:Pitta answers give single Vata with a visible Pitta share', () {
    final p = predictor.predict([...List.filled(20, 0), ...List.filled(10, 1)]);
    expect(p.type, 'Vata');
    expect(p['Pitta'], greaterThan(0.05));
    expect(predictor.needsTieBreaker(p), isFalse);
  });

  test('matches the Python (scikit-learn) model output', () {
    // Reference values from ml/ (same model JSON, numpy softmax).
    void check(DoshaPrediction p, List<double> ref) {
      expect(p['Vata'], closeTo(ref[0], 0.0015));
      expect(p['Pitta'], closeTo(ref[1], 0.0015));
      expect(p['Kapha'], closeTo(ref[2], 0.0015));
    }

    check(predictor.predict(List.generate(30, (i) => i.isEven ? 0 : 1)),
        [0.4030, 0.5479, 0.0491]);
    check(predictor.predict(List.generate(30, (i) => i % 3)),
        [0.3746, 0.3022, 0.3233]);
    check(predictor.predict([...List.filled(20, 0), ...List.filled(10, 1)]),
        [0.8567, 0.1125, 0.0308]);
    check(predictor.predict([...List.filled(15, 0), ...List.filled(15, 1)]),
        [0.5765, 0.3781, 0.0454]);

    final vp = predictor.tieBreakerBanks[0];
    expect(vp.pair, ['Vata', 'Pitta']);
    check(
      predictor.predict([...List.filled(15, 0), ...List.filled(15, 1)],
          tieBreakerBank: vp, tieBreakerAnswers: [0, 0, 0, 0, 1, 0]),
      [0.6467, 0.3108, 0.0425],
    );
    check(
      predictor.predict([...List.filled(15, 0), ...List.filled(15, 1)],
          tieBreakerBank: vp, tieBreakerAnswers: [1, 1, 1, 1, 1, 1]),
      [0.4627, 0.4947, 0.0426],
    );

    final pk = predictor.tieBreakerBanks[1];
    expect(pk.pair, ['Pitta', 'Kapha']);
    check(
      predictor.predict([...List.filled(15, 1), ...List.filled(15, 2)],
          tieBreakerBank: pk, tieBreakerAnswers: [1, 1, 1, 0, 1, 1]),
      [0.0398, 0.4890, 0.4711],
    );
  });

  test('letters map A/B/C to option indices', () {
    final fromLetters = predictor.predictFromLetters(List.filled(30, 'B'));
    final fromInts = predictor.predict(List.filled(30, 1));
    expect(fromLetters.probabilities, fromInts.probabilities);
  });

  test('rejects malformed input', () {
    expect(() => predictor.predict([0, 1, 2]), throwsArgumentError);
    expect(
      () => predictor.predict(List.filled(30, 0),
          tieBreakerBank: predictor.tieBreakerBanks[0],
          tieBreakerAnswers: [0, 1]),
      throwsArgumentError,
    );
    expect(
      () => predictor.predict(List.filled(30, 0), tieBreakerAnswers: [0, 0, 0, 0, 0, 0]),
      throwsArgumentError,
    );
  });
}
