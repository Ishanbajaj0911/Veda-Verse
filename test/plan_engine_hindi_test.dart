// The Veda engine speaks Hindi when the app is in Hindi: every catalogue
// string and every generated sentence, with English mode unchanged.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:veda_verse/engine/plan_engine.dart';
import 'package:veda_verse/l10n/lang.dart';
import 'package:veda_verse/ml/dosha_predictor.dart';
import 'package:veda_verse/ml/vikriti.dart';

final _devanagari = RegExp('[ऀ-ॿ]');

/// Proper nouns and user-typed text that may stay in Latin letters.
const _allowed = {'VedaVerse', 'Ayu', 'Buddy', 'Metformin', 'Amlodipine'};

List<String> _english(String s) =>
    [for (final m in RegExp('[A-Za-z]{3,}').allMatches(s)) if (!_allowed.contains(m[0])) m[0]!];

void main() {
  late DoshaPredictor model;
  late List<List<String>> vLabels;

  setUpAll(() {
    model = DoshaPredictor.fromJson(
        jsonDecode(File('assets/ml/dosha_model.json').readAsStringSync()) as Map<String, dynamic>);
    vLabels = [for (final q in model.vikritiQuestions) q.options];
  });

  tearDown(() => Lang.notifier.value = Lang.en);

  DoshaPrediction prakriti(int option) => model.predict(List.filled(model.nQuestions, option));
  VikritiResult vikriti(List<int> a, [Set<String> concerns = const {}]) =>
      VikritiResult.fromAnswers(a, vLabels, intakeConcerns: concerns);

  void hindi(String what, String hi, String en) {
    expect(hi, isNot(en), reason: '$what has no Hindi: $en');
    expect(hi, contains(_devanagari), reason: '$what: $hi');
  }

  /// A spread of users: every dosha focus, raised or not, concerns,
  /// conditions, pregnancy, medicines, allergies and every season.
  List<EngineInput> inputs() {
    const concerns = [
      <String>{},
      {'Can’t sleep'},
      {'Acidity', 'Back pain'},
      {'Weight gain', 'Low energy', 'Skin issues'},
      {'Always stressed', 'Irregular periods'},
    ];
    const conditions = [
      <String>{},
      {'High BP'},
      {'Diabetes', 'Asthma'},
      {'None of these'},
      {'Heart condition', 'Thyroid'},
    ];
    final seasons = [null, ...ritus.keys];
    final out = <EngineInput>[];
    var k = 0;
    for (final p in [null, 0, 1, 2]) {
      for (final v in [null, [1, 1, 1, 1, 0, 2], [0, 0, 0, 0, 1, 2], [2, 2, 2, 2, 0, 1]]) {
        for (final c in concerns) {
          k++;
          out.add(EngineInput(
            prakriti: p == null ? null : prakriti(p),
            vikriti: v == null ? null : vikriti(v, c),
            concerns: c,
            conditions: conditions[k % conditions.length],
            gender: k.isEven ? 'Female' : 'Male',
            pregnancy: const ['No', 'Pregnant', 'Breastfeeding'][k % 3],
            medicines: k % 4 == 0 ? const ['Metformin'] : const [],
            allergies: k % 5 == 0 ? const ['Milk'] : const [],
            ritu: seasons[k % seasons.length],
          ));
        }
      }
    }
    return out;
  }

  /// Every display string the engine produces for [i].
  List<String> texts(EngineInput i) => [
        for (final p in dailyPlan(i, count: dinacharyaCatalog.length)) ...[p.item.title, p.item.why, p.reason],
        if (vaidyaNote(i) != null) vaidyaNote(i)!,
        rankingNote(i),
        for (final r in [...rankSessions(nearSessions, i), ...rankSessions(onlineSessions, i)])
          ...[r.reason, r.session.title, r.session.where, r.session.time, r.session.price, r.session.cta],
      ];

  group('Hindi catalogue', () {
    setUp(() => Lang.notifier.value = Lang.hiCode);

    test('every Dinacharya item', () {
      for (final it in dinacharyaCatalog) {
        hindi('${it.id} title', it.title, it.titleEn);
        hindi('${it.id} why', it.why, it.whyEn);
      }
    });

    test('every yoga session', () {
      for (final s in [...nearSessions, ...onlineSessions]) {
        hindi('title', s.title, s.titleEn);
        hindi('where', s.where, s.whereEn);
        hindi('time', s.time, s.timeEn);
        hindi('cta', s.cta, s.ctaEn);
        if (s.priceEn.contains(RegExp('[A-Za-z]'))) {
          hindi('price', s.price, s.priceEn);
        } else {
          expect(s.price, s.priceEn); // "₹499" reads the same
        }
      }
    });

    test('free sessions stay free in Hindi', () {
      expect(onlineSessions.where((s) => s.free).length, 3);
      expect(onlineSessions.first.price, 'मुफ़्त');
    });

    test('every Ritu label', () {
      for (final r in ritus.keys) {
        hindi(r, rituLabel(r), rituLabelEn(r));
        expect(rituLabel(r), contains('ऋतु'));
      }
      expect(rituLabel('Vasanta'), 'वसंत ऋतु (बसंत)');
    });

    test('every concern phrase', () {
      for (final c in VikritiResult.concerns.keys) {
        hindi(c, concernPhrase(c), concernPhraseEn(c));
      }
    });
  });

  group('Hindi sentences', () {
    setUp(() => Lang.notifier.value = Lang.hiCode);

    test('no English left in plans, notes and rankings', () {
      final bad = <String>{};
      for (final i in inputs()) {
        for (final t in texts(i)) {
          if (_english(t).isNotEmpty) bad.add(t);
        }
      }
      expect(bad, isEmpty);
    });

    test('pregnancy and conditions read naturally', () {
      final i = EngineInput(
          prakriti: prakriti(2),
          concerns: const {'Weight gain'},
          conditions: const {'High BP'},
          gender: 'Female',
          pregnancy: 'Pregnant',
          medicines: const ['Amlodipine 5 mg']);
      expect(vaidyaNote(i),
          'आपने बताया है: हाई बीपी, गर्भावस्था; आपकी दवाएँ: Amlodipine 5 mg। इसलिए खान-पान या दिनचर्या में कोई भी बदलाव पहले अपने वैद्य से पूछकर करें।');
      expect(rankingNote(i), contains('(हाई बीपी, गर्भावस्था)'));
      expect(rankSessions(nearSessions, i).last.reason, 'पहले अपने वैद्य से पूछें');
    });

    test('reasons', () {
      expect(rankSessions(onlineSessions, const EngineInput(concerns: {'Can’t sleep'})).first.reason,
          'नींद की परेशानी के लिए');
      final plan = dailyPlan(EngineInput(prakriti: prakriti(0), ritu: 'Hemanta'));
      expect(plan.map((p) => p.reason), contains('हेमंत ऋतु (शुरुआती सर्दी) के अनुकूल'));
      expect(rankingNote(EngineInput(prakriti: prakriti(0), vikriti: vikriti([1, 1, 1, 1, 0, 2]))),
          'आपके बढ़े हुए पित्त के हिसाब से क्रम दिया गया।');
    });
  });

  group('English is unchanged', () {
    test('catalogue and sentences', () {
      Lang.notifier.value = Lang.en;
      expect(dinacharyaCatalog.first.title, 'Warm water on waking');
      expect(onlineSessions.first.time, 'Daily · 9:30 pm');
      expect(rituLabel('Hemanta'), 'Hemanta (early winter)');
      expect(concernPhrase('Can’t sleep'), 'poor sleep');
      expect(vaidyaNote(const EngineInput(conditions: {'High BP'}, medicines: ['Amlodipine 5 mg'])),
          'Because you noted high bp and you take Amlodipine 5 mg, check any diet or routine change with your Vaidya first.');
      expect(vaidyaNote(const EngineInput(medicines: ['Metformin'])),
          'Because you take Metformin, check any diet or routine change with your Vaidya first.');
      expect(rankingNote(const EngineInput()),
          'Take the Prakriti quiz on the Dosha tab and we will rank these for your body type.');
      expect(rankingNote(const EngineInput(concerns: {'Back pain'})),
          'Ranked for your back pain. Take the Prakriti quiz to rank for your body type too.');
      expect(rankingNote(EngineInput(prakriti: prakriti(2), concerns: const {'Acidity'}, conditions: const {'High BP'})),
          'Ranked for Kapha and your acidity. Sessions not safe with high bp are moved to the end.');
    });

    test('switching back from Hindi gives the same English', () {
      final before = [for (final i in inputs()) ...texts(i)];
      Lang.notifier.value = Lang.hiCode;
      final hi = [for (final i in inputs()) ...texts(i)];
      Lang.notifier.value = Lang.en;
      final after = [for (final i in inputs()) ...texts(i)];
      expect(after, before);
      expect(hi, isNot(before));
    });
  });
}
