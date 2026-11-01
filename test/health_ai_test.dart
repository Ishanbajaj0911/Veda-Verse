import 'dart:convert';

import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:veda_verse/ai/gemini_client.dart';
import 'package:veda_verse/ai/health_ai.dart';
import 'package:veda_verse/ai/safety.dart';
import 'package:veda_verse/state/app_state.dart';

String _wrap(String text) => jsonEncode({
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': text},
            ],
          },
        },
      ],
    });

void main() {
  final file = Attachment('report.pdf', 'application/pdf', Uint8List.fromList([1, 2, 3]));
  late List<Map<String, dynamic>> sent;

  HealthAi fake(Object reply) => HealthAi(GeminiClient(
        apiKey: 'k',
        client: MockClient((req) async {
          sent.add(jsonDecode(req.body) as Map<String, dynamic>);
          return http.Response(_wrap(reply is String ? reply : jsonEncode(reply)), 200);
        }),
      ));

  setUp(() => sent = []);

  group('High / Low comes from the printed range, not the AI', () {
    test('ranges with a dash, en dash or "to"', () {
      expect(LabReport.flagFor('6.1', '4.0-5.6'), 'High');
      expect(LabReport.flagFor('18', '30–100'), 'Low');
      expect(LabReport.flagFor('14.1 g/dL', '13 to 17'), 'OK');
      expect(LabReport.flagFor('1,250', '150-450'), 'High');
    });
    test('upper and lower limits', () {
      expect(LabReport.flagFor('178', '< 200'), 'OK');
      expect(LabReport.flagFor('250', '<200'), 'High');
      expect(LabReport.flagFor('35', '> 40'), 'Low');
      expect(LabReport.flagFor('45', 'more than 40'), 'OK');
    });
    test('falls back to the AI flag only when the range is unreadable', () {
      expect(LabReport.flagFor('Positive', '', 'HIGH'), 'High');
      expect(LabReport.flagFor('12', 'see note', 'NORMAL'), 'OK');
      expect(LabReport.flagFor('12', ''), 'Unknown');
      // A wrong AI flag never overrides a readable range.
      expect(LabReport.flagFor('6.1', '4.0-5.6', 'NORMAL'), 'High');
    });
  });

  test('reads a lab report with a JSON schema and the file inline', () async {
    final ai = fake({
      'is_lab_report': true,
      'lab_name': 'City Diagnostics',
      'report_date': '28 Oct 2026',
      'tests': [
        {'name': 'HbA1c', 'value': '6.1', 'unit': '%', 'reference_range': '4.0-5.6', 'flag': 'NORMAL'},
        {'name': 'Vitamin D', 'value': '18', 'unit': 'ng/mL', 'reference_range': '30-100', 'flag': 'LOW'},
        {'name': 'Haemoglobin', 'value': '14.1', 'unit': 'g/dL', 'reference_range': '13-17'},
        {'name': '', 'value': '1'},
      ],
    });
    final r = await ai.readLabReport(file);
    final req = sent.single;
    expect(req['generationConfig']['responseMimeType'], 'application/json');
    expect(req['generationConfig']['responseSchema']['required'], contains('tests'));
    expect(req['contents'][0]['parts'][0]['inlineData']['mimeType'], 'application/pdf');
    expect(r.lab, 'City Diagnostics');
    expect(r.tests.length, 3, reason: 'rows without a name are dropped');
    expect([for (final t in r.tests) t.flag], ['High', 'Low', 'OK']);
    expect(r.summary, startsWith('2 values are outside the printed range: HbA1c (high) and Vitamin D (low)'));
  });

  test('a file that is not a lab report is rejected', () async {
    final ai = fake({'is_lab_report': false, 'tests': []});
    expect(() => ai.readLabReport(file), throwsA(isA<NotThatDocument>()));
  });

  test('reads medicine names from a prescription, without duplicates', () async {
    final ai = fake({
      'is_prescription': true,
      'medicines': [
        {'name': 'Amlodipine', 'strength': '5 mg'},
        {'name': 'amlodipine', 'strength': '5 mg'},
        {'name': 'Metformin', 'strength': '500 mg'},
        {'name': 'X'},
      ],
    });
    expect(await ai.readPrescription(file), ['Amlodipine 5 mg', 'Metformin 500 mg']);
    expect(() => fake({'is_prescription': false, 'medicines': []}).readPrescription(file), throwsA(isA<NotThatDocument>()));
  });

  group('Vaidya case sheet', () {
    late AppState s;
    setUp(() {
      s = AppState.instance
        ..issues = {'Acidity', 'Can’t sleep'}
        ..since = '3+ mo'
        ..conditions = {'High BP'}
        ..medicines = ['Amlodipine 5 mg']
        ..allergies = ['Peanuts']
        ..prediction = null
        ..labReport = LabReport.sampleReport()
        ..buddyFlags.clear();
      s.buddyFlags.add(BuddyFlag(DateTime(2026, 11, 1), SafetyLevel.vaidya, 'Can I take ashwagandha with my BP tablet?'));
    });
    tearDown(() => s
      ..labReport = null
      ..buddyFlags.clear());

    test('is built from the user\'s own data', () {
      final c = CaseSheet.from(s);
      expect(c.concerns, containsAll(['Acidity', 'Can’t sleep']));
      expect(c.medicines, ['Amlodipine 5 mg']);
      expect(c.prakriti, 'Not checked yet');
      final facts = c.asFacts();
      expect(facts, contains('Amlodipine 5 mg'));
      expect(facts, contains('Can I take ashwagandha with my BP tablet?'));
      expect(facts, isNot(contains('HbA1c')), reason: 'the sample report is never passed off as real');
    });

    test('without a key, the overview is the plain template', () async {
      final c = CaseSheet.from(s);
      expect(await HealthAi(GeminiClient(apiKey: '')).vaidyaOverview(c), c.plainOverview);
      expect(c.plainOverview, contains('acidity'));
      expect(c.plainOverview, contains('takes Amlodipine 5 mg'));
    });

    test('a Gemini overview that gives a dose falls back to the template', () async {
      final c = CaseSheet.from(s);
      expect(await fake('Start 500 mg ashwagandha twice daily.').vaidyaOverview(c), c.plainOverview);
      expect(await fake('Aarav, 27, reports acidity and poor sleep for over three months.').vaidyaOverview(c),
          'Aarav, 27, reports acidity and poor sleep for over three months.');
      expect(sent.last['contents'][0]['parts'].last['text'], contains('Main concerns'));
    });
  });
}
