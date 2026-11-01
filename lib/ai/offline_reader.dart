import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:veda_verse/ai/gemini_client.dart';
import 'package:veda_verse/ai/health_ai.dart';

/// Free, offline document reading on the phone: Google ML Kit text
/// recognition turns a photo into text, and simple rules pull out lab values
/// or medicine names. No internet, no key, no cost. Android and iPhone only
/// (ML Kit has no web version), and photos only (not PDFs).
class OfflineReader {
  const OfflineReader();

  bool get supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Recognises the text in [file] and returns it as table rows, top to
  /// bottom, each row's pieces joined left to right.
  Future<List<String>> rows(Attachment file) async {
    if (!supported) {
      throw const NotThatDocument('Reading without internet works in the Android and iPhone app.');
    }
    if (!file.isImage) {
      throw const NotThatDocument('Without internet I can read photos, not PDFs. Please take a clear photo of the page.');
    }
    final dir = await getTemporaryDirectory();
    final dot = file.name.lastIndexOf('.');
    final ext = dot < 0 ? 'jpg' : file.name.substring(dot + 1);
    final tmp = File('${dir.path}/vv_scan_${DateTime.now().microsecondsSinceEpoch}.$ext');
    await tmp.writeAsBytes(file.bytes, flush: true);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final text = await recognizer.processImage(InputImage.fromFilePath(tmp.path));
      return groupRows([
        for (final b in text.blocks)
          for (final l in b.lines)
            OcrPiece(l.text, l.boundingBox.left, l.boundingBox.top, l.boundingBox.right, l.boundingBox.bottom),
      ]);
    } finally {
      await recognizer.close();
      try {
        await tmp.delete();
      } catch (_) {}
    }
  }

  Future<LabReport> readLabReport(Attachment file) async {
    final tests = parseLabRows(await rows(file));
    if (tests.length < 2) {
      throw const NotThatDocument(
          'I couldn’t find test values in this photo. Take a clear, straight photo of the results table in good light.');
    }
    return LabReport(lab: '', date: '', tests: tests, readAt: DateTime.now(), source: LabSource.phone);
  }

  Future<List<String>> readPrescription(Attachment file) async {
    final meds = parsePrescriptionRows(await rows(file));
    if (meds.isEmpty) {
      throw const NotThatDocument('I couldn’t find medicine names in this photo. Please type them, or take a clearer photo.');
    }
    return meds;
  }
}

/// One recognised line of text and its box on the page.
class OcrPiece {
  final String text;
  final double left, top, right, bottom;
  const OcrPiece(this.text, this.left, this.top, this.right, this.bottom);
  double get cy => (top + bottom) / 2;
  double get height => bottom - top;
}

/// Rebuilds table rows: pieces whose vertical centres are close belong to the
/// same row, and each row is read left to right. ML Kit often returns table
/// columns as separate blocks, so this step matters for lab reports.
List<String> groupRows(List<OcrPiece> pieces) {
  final ps = pieces.where((p) => p.text.trim().isNotEmpty).toList()..sort((a, b) => a.cy.compareTo(b.cy));
  if (ps.isEmpty) return const [];
  final heights = ps.map((p) => p.height).toList()..sort();
  final tol = (heights[heights.length ~/ 2] * 0.6).clamp(4.0, 60.0);
  final rows = <List<OcrPiece>>[];
  for (final p in ps) {
    if (rows.isNotEmpty) {
      final row = rows.last;
      final cy = row.map((r) => r.cy).reduce((a, b) => a + b) / row.length;
      if ((p.cy - cy).abs() <= tol) {
        row.add(p);
        continue;
      }
    }
    rows.add([p]);
  }
  return [
    for (final r in rows) (r..sort((a, b) => a.left.compareTo(b.left))).map((p) => p.text.trim()).join('  '),
  ];
}

// ---------------------------------------------------------------------------
// Lab reports
// ---------------------------------------------------------------------------

const _headerWords = {
  'test', 'tests', 'investigation', 'result', 'results', 'unit', 'units', 'reference', 'range', 'interval', 'method',
  'patient', 'name', 'age', 'sex', 'gender', 'date', 'ref', 'sample', 'collected', 'reported', 'page', 'dr', 'doctor',
  'lab', 'laboratory', 'remarks', 'note', 'normal', 'value', 'values', 'specimen', 'id', 'mobile', 'phone',
};

final _num = RegExp(r'^[<>]?\d+(?:[.,]\d+)?$');
final _rangeBetween = RegExp(r'(\d+(?:\.\d+)?)\s*(?:-|to)\s*(\d+(?:\.\d+)?)');
final _rangeLimit = RegExp(r'(?:<=?|>=?|≤|≥|less than|more than|up ?to|upto)\s*\d+(?:\.\d+)?', caseSensitive: false);
final _unit = RegExp(r'^(?=.*[a-zA-Zµμ%])[a-zA-Zµμ%/^0-9.*³]{1,14}$');

/// Turns OCR rows like "Haemoglobin  14.1  g/dL  13.0 - 17.0" into tests.
/// Rows without a readable value and range are skipped, so headers, patient
/// details and notes drop out.
List<LabTest> parseLabRows(List<String> rows) {
  final out = <LabTest>[];
  final seen = <String>{};
  for (final raw in rows) {
    final row = raw.replaceAll(RegExp('[–—]'), '-').replaceAll(RegExp(r'\s+'), ' ').trim();
    // Range: the last "a - b" or "< b" in the row.
    final between = _rangeBetween.allMatches(row).toList();
    final limit = _rangeLimit.allMatches(row).toList();
    final RegExpMatch? range = between.isNotEmpty ? between.last : (limit.isNotEmpty ? limit.last : null);
    if (range == null) continue;
    final before = row.substring(0, range.start).trim();
    final tokens = before.split(' ');
    // Name: leading tokens up to the first stand-alone number (the value).
    final vi = tokens.indexWhere((t) => _num.hasMatch(t));
    if (vi <= 0) continue;
    final name = tokens.sublist(0, vi).join(' ').replaceAll(RegExp(r'[:\-]+$'), '').trim();
    final letters = RegExp(r'[a-zA-Z]').allMatches(name).length;
    if (letters < 2 || name.length > 40) continue;
    if (name.toLowerCase().split(RegExp(r'[^a-z]+')).where((w) => w.isNotEmpty).every(_headerWords.contains)) continue;
    final value = tokens[vi].replaceAll(',', '.');
    final unitTokens = [for (final t in tokens.sublist(vi + 1)) if (_unit.hasMatch(t) && !RegExp(r'^[HL]$').hasMatch(t)) t];
    final unit = unitTokens.isEmpty ? '' : unitTokens.first;
    final rangeText = row.substring(range.start, range.end).trim();
    if (!seen.add(name.toLowerCase())) continue;
    out.add(LabTest(name, value, unit, rangeText, LabReport.flagFor(value, rangeText)));
  }
  return out;
}

// ---------------------------------------------------------------------------
// Prescriptions
// ---------------------------------------------------------------------------

final _rxPrefix = RegExp(r'^(?:\d+[.)]\s*)?(tab|tabs|tablet|cap|caps|capsule|syp|syr|syrup|inj|injection|t|c|oint|drops?)\.?\s+',
    caseSensitive: false);
final _strength = RegExp(r'(\d+(?:\.\d+)?\s?(?:mg|mcg|µg|g|gm|ml|iu|%))\b', caseSensitive: false);
const _notNames = {
  'after', 'before', 'food', 'meal', 'meals', 'daily', 'once', 'twice', 'days', 'day', 'weeks', 'week', 'morning',
  'night', 'bedtime', 'od', 'bd', 'tds', 'qid', 'sos', 'hs', 'x', 'for', 'and', 'with', 'take', 'rx', 'dr', 'tab',
  'cap', 'syp', 'inj',
};

/// Pulls "Name strength" from rows like "Tab. Amlodipine 5mg 1-0-0 x 30 days"
/// or "Metformin 500 mg after food". Schedules and directions are dropped.
List<String> parsePrescriptionRows(List<String> rows) {
  final out = <String>[];
  final seen = <String>{};
  for (final raw in rows) {
    var row = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    final prefixed = _rxPrefix.hasMatch(row);
    final strength = _strength.firstMatch(row);
    if (!prefixed && strength == null) continue;
    row = row.replaceFirst(_rxPrefix, '');
    final cut = strength == null ? row : row.substring(0, row.indexOf(strength.group(0)!.trim()));
    final words = [
      for (final w in cut.split(' '))
        if (RegExp(r'^[A-Za-z][A-Za-z\-]{2,}$').hasMatch(w) && !_notNames.contains(w.toLowerCase())) w,
    ];
    if (words.isEmpty || words.first.length < 4) continue;
    final name = words.take(3).map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase()).join(' ');
    final s = strength?.group(1)?.replaceAll(RegExp(r'\s'), ' ').trim();
    final label = s == null ? name : '$name ${s.replaceAllMapped(RegExp(r'(\d)([a-zA-Z%])'), (m) => '${m[1]} ${m[2]}')}';
    if (seen.add(label.toLowerCase())) out.add(label);
  }
  return out;
}
