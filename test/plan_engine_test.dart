import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:veda_verse/engine/plan_engine.dart';
import 'package:veda_verse/ml/dosha_predictor.dart';
import 'package:veda_verse/ml/vikriti.dart';

void main() {
  late DoshaPredictor model;
  late List<List<String>> vLabels;

  setUpAll(() {
    model = DoshaPredictor.fromJson(
        jsonDecode(File('assets/ml/dosha_model.json').readAsStringSync()) as Map<String, dynamic>);
    vLabels = [for (final q in model.vikritiQuestions) q.options];
  });

  DoshaPrediction prakriti(int option) => model.predict(List.filled(model.nQuestions, option));
  VikritiResult vikriti(List<int> a, [Set<String> concerns = const {}]) =>
      VikritiResult.fromAnswers(a, vLabels, intakeConcerns: concerns);
  Set<String> ids(List<PlannedItem> plan) => {for (final p in plan) p.item.id};

  group('Vikriti uses the quiz and "Your story"', () {
    test('concerns break a near-tie', () {
      // Quiz alone: Pitta 2, Vata 2, Kapha 2 -> nothing stands out.
      expect(vikriti([1, 1, 0, 0, 2, 2]).raised, isNull);
      // Acidity and skin issues are Pitta concerns: 3 votes, a strict lead.
      final v = vikriti([1, 1, 0, 0, 2, 2], {'Acidity', 'Skin issues'});
      expect(v.raised, 'Pitta');
      expect(v.signs, containsAll(['acidity', 'skin issues']));
    });

    test('concerns never outvote the quiz', () {
      // Quiz says Kapha 4; two Vata concerns add only 1 vote.
      expect(vikriti([2, 2, 2, 2, 0, 1], {'Can’t sleep', 'Always stressed'}).raised, 'Kapha');
    });

    test('unknown concerns are ignored', () {
      expect(vikriti([0, 0, 1, 1, 2, 2], {'Something else'}).raised, isNull);
    });
  });

  group('Daily plan', () {
    test('targets the raised Vikriti dosha first, then the Prakriti', () {
      final input = EngineInput(prakriti: prakriti(0), vikriti: vikriti([1, 1, 1, 1, 0, 2]));
      expect(input.targets.first, 'Pitta');
      expect(input.targets, contains('Vata'));
      final plan = dailyPlan(input);
      expect(plan.length, 4);
      expect(plan.where((p) => p.item.balances.contains('Pitta')).length, greaterThanOrEqualTo(3));
    });

    test('concerns pull in matching items and explain why', () {
      final plan = dailyPlan(const EngineInput(concerns: {'Acidity'}));
      final matching = plan.where((p) => p.item.helps.contains('Acidity')).toList();
      // With no season set, every acidity item qualifies; the 2-food cap
      // still applies, and 2 non-food acidity items fill the rest.
      expect(matching.length, 4);
      expect(plan.where((p) => p.item.diet).length, 2);
      expect(matching.every((p) => p.reason == 'For your acidity'), isTrue);
    });

    test('items are sorted by time of day', () {
      final plan = dailyPlan(EngineInput(prakriti: prakriti(2), concerns: const {'Weight gain', 'Low energy'}));
      final mins = [for (final p in plan) p.item.minutes];
      expect(mins, orderedEquals([...mins]..sort()));
    });

    test('at most two food items', () {
      final plan = dailyPlan(const EngineInput(concerns: {'Acidity', 'Weight gain'}));
      expect(plan.where((p) => p.item.diet).length, lessThanOrEqualTo(2));
    });

    test('allergies remove matching food items', () {
      const sleepy = {'Can’t sleep'};
      expect(ids(dailyPlan(const EngineInput(concerns: sleepy, allergies: []), count: 20)), contains('warm_milk'));
      expect(ids(dailyPlan(const EngineInput(concerns: sleepy, allergies: ['Milk']), count: 20)), isNot(contains('warm_milk')));
      expect(ids(dailyPlan(const EngineInput(allergies: ['Sesame seeds']), count: 20)), isNot(contains('oil_massage')));
    });

    test('conditions and pregnancy remove unsafe items', () {
      const kapha = {'Weight gain', 'Low energy'};
      expect(ids(dailyPlan(const EngineInput(concerns: kapha), count: 20)), contains('brisk_walk'));
      expect(ids(dailyPlan(const EngineInput(concerns: kapha, conditions: {'Heart condition'}), count: 20)),
          isNot(contains('brisk_walk')));
      final pregnant = ids(dailyPlan(
          const EngineInput(concerns: kapha, gender: 'Female', pregnancy: 'Pregnant'),
          count: 20));
      expect(pregnant, isNot(contains('brisk_walk')));
      expect(pregnant, isNot(contains('no_day_nap')));
      expect(ids(dailyPlan(const EngineInput(concerns: {'Acidity'}, conditions: {'Asthma'}), count: 20)),
          isNot(contains('sheetali')));
    });

    test('season: winter items rise in Hemanta, cooling items drop out', () {
      const pitta = {'Acidity', 'Skin issues'};
      final summer = ids(dailyPlan(const EngineInput(concerns: pitta, ritu: 'Grishma')));
      final winter = ids(dailyPlan(const EngineInput(concerns: pitta, ritu: 'Hemanta')));
      expect(summer, containsAll(['sheetali', 'cool_drink']));
      expect(winter, isNot(contains('sheetali')));
      expect(winter, isNot(contains('cool_drink')));
      expect(winter, isNot(contains('noon_shade')));
      // Year-round acidity advice still applies in winter.
      expect(ids(dailyPlan(const EngineInput(concerns: pitta, ritu: 'Hemanta'), count: 20)), contains('less_spicy'));
    });

    test('season-only picks say which Ritu they suit', () {
      final plan = dailyPlan(EngineInput(prakriti: prakriti(0), ritu: 'Hemanta'));
      expect(ids(plan), anyOf(contains('warm_feet'), contains('oil_massage')));
      expect(plan.map((p) => p.reason), contains('Suits Hemanta (early winter)'));
    });

    test('no season given means no season effect', () {
      expect(ids(dailyPlan(const EngineInput(concerns: {'Acidity'}))), contains('sheetali'));
    });

    test('every month maps to a Ritu', () {
      for (var m = 1; m <= 12; m++) {
        expect(ritus.keys, contains(rituKeyFor(DateTime(2026, m, 15))));
      }
      expect(rituKeyFor(DateTime(2026, 11, 1)), 'Hemanta');
    });

    test('pregnancy only counts for women', () {
      expect(const EngineInput(gender: 'Male', pregnancy: 'Pregnant').flags, isEmpty);
    });

    test('a Vaidya note appears for conditions, pregnancy or medicines', () {
      expect(vaidyaNote(const EngineInput()), isNull);
      expect(vaidyaNote(const EngineInput(conditions: {'None of these'})), isNull);
      final note = vaidyaNote(const EngineInput(conditions: {'High BP'}, medicines: ['Amlodipine 5 mg']))!;
      expect(note, contains('high bp'));
      expect(note, contains('Amlodipine 5 mg'));
      expect(vaidyaNote(const EngineInput(gender: 'Female', pregnancy: 'Breastfeeding')), contains('breastfeeding'));
    });

    test('the catalogue has no herbs, supplements or medicines', () {
      for (final it in dinacharyaCatalog) {
        final t = it.title.toLowerCase();
        for (final banned in ['herb', 'churna', 'tablet', 'capsule', 'supplement', 'ashwagandha', 'triphala', 'dose']) {
          expect(t.contains(banned), isFalse, reason: '${it.id} mentions $banned');
        }
      }
    });
  });

  group('Yoga ranking', () {
    test('sessions matching concerns and the focus dosha come first', () {
      final ranked = rankSessions(onlineSessions, const EngineInput(concerns: {'Can’t sleep'}));
      expect(ranked.first.session.title, 'Yoga Nidra for deep sleep');
      expect(ranked.first.reason, 'For your poor sleep');
    });

    test('Kapha focus ranks energising sessions up', () {
      final ranked = rankSessions(nearSessions, EngineInput(prakriti: prakriti(2)));
      expect(ranked.first.session.balances, contains('Kapha'));
      expect(ranked.first.caution, isFalse);
    });

    test('unsafe sessions go last and say ask your Vaidya', () {
      final ranked = rankSessions(nearSessions,
          EngineInput(prakriti: prakriti(2), concerns: const {'Weight gain'}, conditions: const {'High BP'}));
      final last = ranked.last;
      expect(last.session.title, 'Power vinyasa flow');
      expect(last.caution, isTrue);
      expect(last.reason, 'Ask your Vaidya first');
      expect(ranked.where((r) => r.caution).length, 1);
    });

    test('ranking note before and after the quiz', () {
      expect(rankingNote(const EngineInput()), contains('Take the Prakriti quiz'));
      expect(rankingNote(const EngineInput(concerns: {'Back pain'})), contains('your back pain'));
      final after = rankingNote(EngineInput(
          prakriti: prakriti(0), vikriti: vikriti([1, 1, 1, 1, 0, 2]), conditions: const {'High BP'}));
      expect(after, contains('your raised Pitta'));
      expect(after, contains('high bp'));
    });
  });
}
