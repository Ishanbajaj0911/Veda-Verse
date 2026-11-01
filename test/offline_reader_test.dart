import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter_test/flutter_test.dart';
import 'package:veda_verse/ai/gemini_client.dart';
import 'package:veda_verse/ai/health_ai.dart';
import 'package:veda_verse/ai/offline_reader.dart';

/// Stands in for ML Kit: returns fixed rows, as if read from a photo.
class _FakePhone extends OfflineReader {
  final List<String> fixed;
  const _FakePhone(this.fixed);
  @override
  bool get supported => true;
  @override
  Future<List<String>> rows(Attachment file) async => fixed;
}

void main() {
  group('rebuilding table rows from OCR boxes', () {
    test('columns read separately are joined back into rows', () {
      // ML Kit often returns each table column as its own block.
      const pieces = [
        OcrPiece('Haemoglobin', 10, 100, 120, 118),
        OcrPiece('HbA1c', 10, 140, 70, 158),
        OcrPiece('14.1', 200, 101, 240, 119),
        OcrPiece('6.1', 200, 141, 230, 159),
        OcrPiece('g/dL', 260, 99, 300, 117),
        OcrPiece('%', 260, 139, 275, 157),
        OcrPiece('13.0 - 17.0', 330, 100, 420, 118),
        OcrPiece('4.0 - 5.6', 330, 140, 410, 158),
      ];
      expect(groupRows(pieces), ['Haemoglobin  14.1  g/dL  13.0 - 17.0', 'HbA1c  6.1  %  4.0 - 5.6']);
    });

    test('empty input gives no rows', () => expect(groupRows(const []), isEmpty));
  });

  group('lab report rows', () {
    final rows = [
      'CITY DIAGNOSTICS LAB',
      'Patient Name: Aarav Mehta   Age: 27',
      'TEST  RESULT  UNIT  REFERENCE RANGE',
      'Haemoglobin  14.1  g/dL  13.0 - 17.0',
      'HbA1c  6.1  H  %  4.0 – 5.6',
      'Vitamin D, 25-Hydroxy  18  ng/mL  30-100',
      'TSH  2.3  µIU/mL  0.4 - 4.0',
      'Total Cholesterol  178  mg/dL  < 200',
      'Vitamin B12  412  pg/mL  200 to 900',
      'Note: values to be correlated clinically',
    ];

    test('reads names, values, units and ranges; skips headers and notes', () {
      final tests = parseLabRows(rows);
      expect([for (final t in tests) t.name],
          ['Haemoglobin', 'HbA1c', 'Vitamin D, 25-Hydroxy', 'TSH', 'Total Cholesterol', 'Vitamin B12']);
      expect([for (final t in tests) t.value], ['14.1', '6.1', '18', '2.3', '178', '412']);
      expect(tests[0].unit, 'g/dL');
      expect(tests[1].unit, '%', reason: 'the H flag printed by the lab is not a unit');
      expect(tests[3].unit, 'µIU/mL');
      expect(tests[4].range, '< 200');
    });

    test('High / Low come from the printed range', () {
      final flags = {for (final t in parseLabRows(rows)) t.name: t.flag};
      expect(flags['HbA1c'], 'High');
      expect(flags['Vitamin D, 25-Hydroxy'], 'Low');
      expect(flags['Haemoglobin'], 'OK');
      expect(flags['Total Cholesterol'], 'OK');
    });

    test('names with digits stay whole', () {
      final t = parseLabRows(['Vitamin B12  150  pg/mL  200 - 900']).single;
      expect(t.name, 'Vitamin B12');
      expect(t.flag, 'Low');
    });
  });

  group('prescription rows', () {
    test('reads name and strength, drops directions', () {
      expect(
        parsePrescriptionRows([
          'Dr. R. Kapoor  BAMS',
          'Rx',
          '1. Tab. Amlodipine 5mg  1-0-0  x 30 days',
          'Cap. Omega 3 Fatty Acids 1000 mg  after food',
          'Metformin 500 mg  BD after meals',
          'Syp. Cough relief  10 ml  TDS',
          'Review after 2 weeks',
        ]),
        ['Amlodipine 5 mg', 'Omega Fatty Acids 1000 mg', 'Metformin 500 mg', 'Cough Relief 10 ml'],
      );
    });

    test('no medicines in a page of plain text', () {
      expect(parsePrescriptionRows(['Patient advised rest', 'Drink warm water']), isEmpty);
    });
  });

  group('without a Gemini key the phone reads the document', () {
    final photo = Attachment('report.jpg', 'image/jpeg', Uint8List.fromList([1]));

    test('lab report', () async {
      final ai = HealthAi(
        GeminiClient(apiKey: ''),
        const _FakePhone(['Haemoglobin  14.1  g/dL  13 - 17', 'HbA1c  6.1  %  4.0 - 5.6']),
      );
      expect(ai.configured, isFalse);
      expect(ai.canRead, isTrue);
      final r = await ai.readLabReport(photo);
      expect(r.source, LabSource.phone);
      expect(r.flagged.single.name, 'HbA1c');
    });

    test('a photo with no values is refused politely', () async {
      final ai = HealthAi(GeminiClient(apiKey: ''), const _FakePhone(['Thank you for visiting']));
      expect(() => ai.readLabReport(photo), throwsA(isA<NotThatDocument>()));
    });

    test('prescription', () async {
      final ai = HealthAi(GeminiClient(apiKey: ''), const _FakePhone(['Tab. Telmisartan 40mg 0-0-1']));
      expect(await ai.readPrescription(photo), ['Telmisartan 40 mg']);
    });

    test('on web (no ML Kit) and without a key nothing can read', () {
      expect(HealthAi(GeminiClient(apiKey: '')).canRead, isFalse, reason: 'tests run on the desktop host');
    });
  });
}
