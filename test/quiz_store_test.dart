import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veda_verse/ml/dosha_predictor.dart';
import 'package:veda_verse/state/app_state.dart';
import 'package:veda_verse/state/quiz_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DoshaPredictor model;

  setUpAll(() {
    model = DoshaPredictor.fromJson(
        jsonDecode(File('assets/ml/dosha_model.json').readAsStringSync()) as Map<String, dynamic>);
  });

  void reset(AppState s) {
    s
      ..prediction = null
      ..prakritiAnswers = null
      ..vikritiAnswers = null
      ..vikritiLabels = const []
      ..dinacharyaDone = {}
      ..doneDate = '';
  }

  final s = AppState.instance;
  setUp(() => reset(s));
  tearDown(() => reset(s));

  test('quiz result and today\'s ticks survive a restart', () async {
    SharedPreferences.setMockInitialValues({});
    final answers = List.filled(model.nQuestions, 2);
    s
      ..prakritiAnswers = answers
      ..prediction = model.predict(answers)
      ..vikritiAnswers = [1, 1, 1, 0, 2, 1]
      ..vikritiLabels = [for (final q in model.vikritiQuestions) q.options];
    s.toggleDone('warm_water');
    await QuizStore.save(s);

    reset(s); // "close the app"
    expect(s.prediction, isNull);
    await QuizStore.restore(s, model: model);

    expect(s.prakritiAnswers, answers);
    expect(s.prediction?.type, 'Kapha');
    expect(s.vikriti?.raised, 'Pitta');
    expect(s.doneToday, {'warm_water'});
  });

  test('yesterday\'s ticks are not restored', () async {
    SharedPreferences.setMockInitialValues({
      'vv.done_date': '2000-01-01',
      'vv.done_ids': ['warm_water'],
    });
    await QuizStore.restore(s, model: model);
    expect(s.doneToday, isEmpty);
  });

  test('answers saved for another model version are discarded', () async {
    SharedPreferences.setMockInitialValues({
      'vv.model_version': model.version - 1,
      'vv.prakriti_answers': List.filled(model.nQuestions, 0).join(','),
    });
    await QuizStore.restore(s, model: model);
    expect(s.prediction, isNull);
  });

  test('corrupt or wrong-length data is ignored, never thrown', () async {
    SharedPreferences.setMockInitialValues({
      'vv.model_version': model.version,
      'vv.prakriti_answers': '0,1,x',
      'vv.vikriti_answers': '9,9',
    });
    await QuizStore.restore(s, model: model);
    expect(s.prediction, isNull);
    SharedPreferences.setMockInitialValues({
      'vv.model_version': model.version,
      'vv.prakriti_answers': List.filled(30, 0).join(','),
    });
    await QuizStore.restore(s, model: model);
    expect(s.prediction, isNull);
  });
}
