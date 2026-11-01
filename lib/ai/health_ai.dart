import 'package:veda_verse/ai/gemini_client.dart';
import 'package:veda_verse/ai/offline_reader.dart';
import 'package:veda_verse/ai/safety.dart';
import 'package:veda_verse/engine/plan_engine.dart' show concernPhrase;
import 'package:veda_verse/l10n/lang.dart';
import 'package:veda_verse/ml/dosha_predictor.dart';
import 'package:veda_verse/ml/vikriti.dart';
import 'package:veda_verse/state/app_state.dart';

/// Gemini-powered helpers outside the chat: reading lab reports, reading
/// prescriptions and writing the Vaidya's case-sheet overview.
///
/// Gemini only transcribes or summarises. Decisions stay on the phone:
/// High/Low flags are computed from the printed range, the case sheet is
/// built from the user's own data, and every free-text output passes
/// [Safety.checkAnswer].

// ---------------------------------------------------------------------------
// Lab reports
// ---------------------------------------------------------------------------

class LabTest {
  final String name;
  final String value; // as printed, e.g. "6.1"
  final String unit;
  final String range; // as printed, e.g. "4.0-5.6"
  final String flag; // High / Low / OK / Unknown
  const LabTest(this.name, this.value, this.unit, this.range, this.flag);

  String get valueWithUnit => unit.isEmpty ? value : '$value $unit';
  bool get outOfRange => flag == 'High' || flag == 'Low';

  /// The flag as shown on a pill: High / Low / OK, or "–" when unknown
  /// (Hindi: ज़्यादा / कम / सामान्य). [flag] itself stays English.
  String get flagLabel => switch (flag) {
        'High' => tr('High'),
        'Low' => tr('Low'),
        'OK' => Lang.hi ? tr('Normal') : 'OK',
        _ => '–',
      };

  /// The flag inside a sentence: "high" / "low" (Hindi: ज़्यादा / कम).
  String get flagWord => Lang.hi ? tr(flag) : flag.toLowerCase();
}

/// "a, b and c" in the current language.
String _andList(List<String> xs) => xs.length == 1
    ? xs.first
    : trf('{a} and {b}', {'a': xs.sublist(0, xs.length - 1).join(', '), 'b': xs.last});

/// Who read a lab report.
enum LabSource { gemini, phone, sample }

class LabReport {
  final String lab;
  final String date;
  final List<LabTest> tests;
  final DateTime readAt;

  /// True for the built-in example shown when Gemini is not set up.
  /// Who read it: Gemini (online), the phone's ML Kit (offline), or the
  /// built-in example.
  final LabSource source;
  bool get sample => source == LabSource.sample;
  const LabReport(
      {required this.lab, required this.date, required this.tests, required this.readAt, this.source = LabSource.gemini});

  List<LabTest> get flagged => tests.where((t) => t.outOfRange).toList();

  /// A test's name as shown. Real reports keep the printed name; the
  /// built-in example's names are translated.
  String nameOf(LabTest t) => sample ? tr(t.name) : t.name;

  /// Plain-words line computed from the flags, never from the AI.
  String get summary {
    if (tests.isEmpty) return tr('No test values could be read from this file.');
    final f = flagged;
    if (f.isEmpty) return trf('All {n} values are inside the printed range.', {'n': tests.length});
    final list = _andList(f.map((t) => '${nameOf(t)} (${t.flagWord})').toList());
    return f.length == 1
        ? trf('1 value is outside the printed range: {list}. Your Vaidya will see this before your consult.', {'list': list})
        : trf('{n} values are outside the printed range: {list}. Your Vaidya will see this before your consult.',
            {'n': f.length, 'list': list});
  }

  static double? _num(String s) {
    final m = RegExp(r'-?\d+(?:\.\d+)?').firstMatch(s.replaceAll(',', ''));
    return m == null ? null : double.tryParse(m.group(0)!);
  }

  /// High / Low / OK from the printed value and range; Gemini's own flag is
  /// used only when the range can't be parsed.
  static String flagFor(String value, String range, [String? aiFlag]) {
    final v = _num(value);
    final r = range.toLowerCase().replaceAll(RegExp('[–—]'), '-').replaceAll(',', '');
    if (v != null) {
      final between = RegExp(r'(-?\d+(?:\.\d+)?)\s*(?:-|to)\s*(-?\d+(?:\.\d+)?)').firstMatch(r);
      if (between != null) {
        final lo = double.parse(between.group(1)!), hi = double.parse(between.group(2)!);
        if (lo <= hi) return v < lo ? 'Low' : (v > hi ? 'High' : 'OK');
      }
      final upper = RegExp(r'(?:<=?|≤|less than|below|up ?to)\s*(\d+(?:\.\d+)?)').firstMatch(r);
      if (upper != null) return v > double.parse(upper.group(1)!) ? 'High' : 'OK';
      final lower = RegExp(r'(?:>=?|≥|more than|above|at least)\s*(\d+(?:\.\d+)?)').firstMatch(r);
      if (lower != null) return v < double.parse(lower.group(1)!) ? 'Low' : 'OK';
    }
    return switch ((aiFlag ?? '').toUpperCase()) {
      'HIGH' => 'High',
      'LOW' => 'Low',
      'NORMAL' || 'OK' => 'OK',
      _ => 'Unknown',
    };
  }

  /// Example shown, clearly labelled, when Gemini is not set up.
  static LabReport sampleReport() => LabReport(
        lab: 'Sample report',
        date: 'example',
        readAt: DateTime.now(),
        source: LabSource.sample,
        tests: [
          for (final (n, v, u, r) in const [
            ('Haemoglobin', '14.1', 'g/dL', '13-17'),
            ('HbA1c', '6.1', '%', '4.0-5.6'),
            ('Vitamin D', '18', 'ng/mL', '30-100'),
            ('TSH', '2.3', 'µIU/mL', '0.4-4.0'),
            ('Total cholesterol', '178', 'mg/dL', '< 200'),
            ('Vitamin B12', '412', 'pg/mL', '200-900'),
          ])
            LabTest(n, v, u, r, flagFor(v, r)),
        ],
      );
}

class NotThatDocument implements Exception {
  final String message;
  const NotThatDocument(this.message);
  @override
  String toString() => message;
}

class HealthAi {
  HealthAi([GeminiClient? client, OfflineReader? offline])
      : _ai = client ?? GeminiClient(),
        _offline = offline ?? const OfflineReader();
  final GeminiClient _ai;

  final OfflineReader _offline;

  /// Gemini is set up (online, best quality, reads PDFs too).
  bool get configured => _ai.configured;

  /// Reports and prescriptions can be read: by Gemini, or offline on the
  /// phone with ML Kit when there is no key.
  bool get canRead => configured || _offline.supported;

  static const _str = {'type': 'STRING'};

  static const _labSchema = <String, Object>{
    'type': 'OBJECT',
    'properties': {
      'is_lab_report': {'type': 'BOOLEAN'},
      'lab_name': _str,
      'report_date': _str,
      'tests': {
        'type': 'ARRAY',
        'items': {
          'type': 'OBJECT',
          'properties': {
            'name': _str,
            'value': _str,
            'unit': _str,
            'reference_range': _str,
            'flag': {
              'type': 'STRING',
              'enum': ['HIGH', 'LOW', 'NORMAL', 'UNKNOWN'],
            },
          },
          'required': ['name', 'value'],
        },
      },
    },
    'required': ['is_lab_report', 'tests'],
  };

  /// Reads a lab report photo or PDF into structured values.
  /// Throws [NotThatDocument] if the file is not a lab report.
  Future<LabReport> readLabReport(Attachment file) async {
    if (!configured) return _offline.readLabReport(file); // free, on the phone
    final out = await _ai.generate(
      system: 'You transcribe medical laboratory reports. Copy test names, values, units and reference ranges exactly '
          'as printed. Never guess a value that is not printed, never interpret results and never diagnose. If the '
          'document is not a lab report, set is_lab_report to false and return no tests.',
      prompt: 'Extract every test result from this report.',
      files: [file],
      schema: _labSchema,
    ) as Map<String, dynamic>;
    if (out['is_lab_report'] != true) {
      throw NotThatDocument(tr('This doesn’t look like a lab report. Please share a photo or PDF of your blood or urine test report.'));
    }
    String s(Object? v) => (v ?? '').toString().trim();
    final tests = <LabTest>[
      for (final t in ((out['tests'] as List?) ?? const []).take(60))
        if (t is Map && s(t['name']).isNotEmpty && s(t['value']).isNotEmpty)
          LabTest(s(t['name']), s(t['value']), s(t['unit']), s(t['reference_range']),
              LabReport.flagFor(s(t['value']), s(t['reference_range']), s(t['flag']))),
    ];
    return LabReport(lab: s(out['lab_name']), date: s(out['report_date']), tests: tests, readAt: DateTime.now());
  }

  static const _rxSchema = <String, Object>{
    'type': 'OBJECT',
    'properties': {
      'is_prescription': {'type': 'BOOLEAN'},
      'medicines': {
        'type': 'ARRAY',
        'items': {
          'type': 'OBJECT',
          'properties': {'name': _str, 'strength': _str},
          'required': ['name'],
        },
      },
    },
    'required': ['is_prescription', 'medicines'],
  };

  /// Reads medicine names (and strengths) from a prescription photo or PDF.
  /// Throws [NotThatDocument] if the file is not a prescription.
  Future<List<String>> readPrescription(Attachment file) async {
    if (!configured) return _offline.readPrescription(file); // free, on the phone
    final out = await _ai.generate(
      system: 'You transcribe medicine names from prescriptions. List each medicine name and its strength exactly as '
          'written (for example "Amlodipine" and "5 mg"). Do not add medicines that are not written, do not explain '
          'them and do not give any advice. If the document is not a prescription, set is_prescription to false.',
      prompt: 'List the medicines on this prescription.',
      files: [file],
      schema: _rxSchema,
    ) as Map<String, dynamic>;
    if (out['is_prescription'] != true) {
      throw NotThatDocument(tr('This doesn’t look like a prescription. Please share a clear photo or PDF of it.'));
    }
    final seen = <String>{};
    final names = <String>[];
    for (final m in ((out['medicines'] as List?) ?? const []).take(20)) {
      if (m is! Map) continue;
      final name = (m['name'] ?? '').toString().trim();
      final strength = (m['strength'] ?? '').toString().trim();
      if (name.length < 2 || name.length > 60) continue;
      final label = strength.isEmpty ? name : '$name $strength';
      if (seen.add(label.toLowerCase())) names.add(label);
    }
    return names;
  }

  /// A short handover paragraph for the Vaidya, written from [sheet] only.
  /// Falls back to [CaseSheet.plainOverview] without a key, on errors, or if
  /// the text fails the safety check.
  Future<String> vaidyaOverview(CaseSheet sheet) async {
    if (!configured) return sheet.plainOverview;
    try {
      final text = await _ai.generate(
        system: 'You write a three-sentence handover note for an Ayurvedic Vaidya before a consultation. Use ONLY the '
            'facts given; add nothing. Do not diagnose, do not suggest treatment, herbs, medicines or doses. Plain '
            'text, third person, under 80 words.'
            '${Lang.hi ? ' Write it in simple everyday Hindi in Devanagari script. Keep names, medicine names, lab test '
                'names and units exactly as given.' : ''}',
        prompt: sheet.asFacts(),
      ) as String;
      final clean = text.replaceAll(RegExp(r'\*\*|__|^#+\s*', multiLine: true), '').trim();
      if (clean.isEmpty || Safety.checkAnswer(clean).blocked) return sheet.plainOverview;
      return clean;
    } catch (_) {
      return sheet.plainOverview;
    }
  }
}

// ---------------------------------------------------------------------------
// Vaidya case sheet
// ---------------------------------------------------------------------------

/// What Ayu Buddy flagged during chats, for the Vaidya.
class BuddyFlag {
  final DateTime at;
  final SafetyLevel level;
  final String question;
  const BuddyFlag(this.at, this.level, this.question);
}

/// The case sheet a Vaidya sees before a consult (design doc: complaint,
/// duration, Agni/Mala/Nidra, labs, escalated questions). Built only from
/// the user's own data.
class CaseSheet {
  final String name;
  final int age;
  final String gender;
  final List<String> concerns;
  final String since;
  final List<String> conditions;
  final String pregnancy;
  final List<String> medicines;
  final List<String> allergies;
  final String prakriti;
  final String vikriti;
  final List<(String, String)> agniMalaNidra; // (label, answer)
  final LabReport? labs;
  final List<BuddyFlag> flags;

  const CaseSheet({
    required this.name,
    required this.age,
    required this.gender,
    required this.concerns,
    required this.since,
    required this.conditions,
    required this.pregnancy,
    required this.medicines,
    required this.allergies,
    required this.prakriti,
    required this.vikriti,
    required this.agniMalaNidra,
    required this.labs,
    required this.flags,
  });

  static String _answer(DoshaPredictor? m, List<int>? answers, List<QuizQuestion> qs, String title) {
    if (m == null || answers == null) return '';
    final i = qs.indexWhere((q) => q.title == title);
    if (i < 0 || i >= answers.length) return '';
    final hi = Lang.hi ? qs[i].optionsHi : null;
    return hi != null && answers[i] < hi.length ? hi[answers[i]] : qs[i].options[answers[i]];
  }

  /// A Vikriti sign (an English quiz option or concern phrase) as shown.
  static String _sign(String s, List<QuizQuestion> qs) {
    if (!Lang.hi) return s;
    for (final q in qs) {
      final i = q.options.indexOf(s);
      final hi = q.optionsHi;
      if (i >= 0 && hi != null && i < hi.length) return hi[i];
    }
    for (final e in VikritiResult.concerns.entries) {
      if (e.value.$2 == s) return tr(e.key);
    }
    return tr(s);
  }

  factory CaseSheet.from(AppState s, [DoshaPredictor? model]) {
    final v = s.vikriti;
    final mix = s.mix;
    final p = model?.questions ?? const <QuizQuestion>[];
    final vq = model?.vikritiQuestions ?? const <QuizQuestion>[];
    // Quiz answers only count once the quiz result exists.
    final pa = s.hasPrakriti ? s.prakritiAnswers : null;
    final va = s.hasPrakriti ? s.vikritiAnswers : null;
    final rows = <(String, String)>[
      (tr('Agni (hunger)'), _answer(model, pa, p, 'How is your hunger?')),
      (tr('Agni lately'), _answer(model, va, vq, 'How has your stomach been lately?')),
      (tr('Mala (bowel)'), _answer(model, pa, p, 'How are your bowel movements usually?')),
      (tr('Nidra (sleep)'), _answer(model, pa, p, 'How do you usually sleep?')),
      (tr('Nidra lately'), _answer(model, va, vq, 'How has your sleep been lately?')),
    ].where((r) => r.$2.isNotEmpty).toList();
    return CaseSheet(
      name: s.name,
      age: s.age,
      gender: s.gender,
      concerns: s.issues.toList(),
      since: s.since,
      conditions: s.conditions.where((c) => c != 'None of these').toList(),
      pregnancy: s.gender == 'Female' ? s.pregnancy : '',
      medicines: List.of(s.medicines),
      allergies: List.of(s.allergies),
      prakriti: s.hasPrakriti
          ? trf('{label} (Vata {v}%, Pitta {p}%, Kapha {k}%)',
              {'label': s.prakritiLabel, 'v': mix['Vata'], 'p': mix['Pitta'], 'k': mix['Kapha']})
          : tr('Not checked yet'),
      vikriti: v == null
          ? tr('Not checked yet')
          : (v.raised == null
              ? tr('No single dosha stands out')
              : trf('{dosha} raised: {signs}',
                  {'dosha': tr(v.raised!), 'signs': v.signs.take(3).map((x) => _sign(x, vq)).join(', ')})),
      agniMalaNidra: rows,
      labs: s.labReport,
      flags: List.of(s.buddyFlags),
    );
  }

  static String _list(List<String> xs) => xs.isEmpty ? 'none' : xs.join(', ');

  /// The facts handed to Gemini for the overview.
  String asFacts() {
    final lab = labs;
    return [
      'Patient: $name, $age, $gender${pregnancy.isNotEmpty && pregnancy != 'No' ? ', $pregnancy' : ''}.',
      'Main concerns: ${_list(concerns)}, for $since.',
      'Known conditions: ${_list(conditions)}. Medicines: ${_list(medicines)}. Allergies: ${_list(allergies)}.',
      'Prakriti (self-assessed quiz): $prakriti. Vikriti (last 2 weeks): $vikriti.',
      for (final (l, a) in agniMalaNidra) '$l: $a.',
      if (lab != null && !lab.sample) 'Lab report: ${lab.summary}',
      if (flags.isNotEmpty)
        'Questions Ayu Buddy referred to a Vaidya: ${flags.where((f) => f.level == SafetyLevel.vaidya).map((f) => '"${f.question}"').join('; ')}.',
      if (flags.any((f) => f.level != SafetyLevel.vaidya)) 'Ayu Buddy also showed emergency guidance during a chat.',
    ].join('\n');
  }

  /// Overview written from a template, used without Gemini.
  String get plainOverview {
    if (Lang.hi) return _plainOverviewHi;
    final lab = labs;
    final who = '$name, $age, ${gender.toLowerCase()}';
    final phrases = concerns.map(concernPhrase).toList();
    final concern = phrases.isEmpty
        ? 'no specific concern'
        : (phrases.length == 1 ? phrases.first : '${phrases.sublist(0, phrases.length - 1).join(', ')} and ${phrases.last}');
    final health = [
      if (conditions.isNotEmpty) 'has ${conditions.join(', ')}',
      if (medicines.isNotEmpty) 'takes ${medicines.join(', ')}',
      if (pregnancy.isNotEmpty && pregnancy != 'No') 'is ${pregnancy.toLowerCase()}',
    ];
    return [
      '$who, reports $concern for $since.',
      if (health.isNotEmpty) 'The patient ${health.join(' and ')}.',
      'Prakriti: $prakriti; Vikriti: $vikriti.',
      if (lab != null && !lab.sample && lab.flagged.isNotEmpty)
        'Lab values outside range: ${lab.flagged.map((t) => '${t.name} (${t.flag.toLowerCase()})').join(', ')}.',
    ].join(' ');
  }

  /// [plainOverview] in Hindi. Intake values go through [tr]; names,
  /// medicines and lab test names stay as entered or printed.
  String get _plainOverviewHi {
    final lab = labs;
    final concern = concerns.isEmpty ? tr('no specific concern') : _andList(concerns.map(tr).toList());
    final health = [
      if (conditions.isNotEmpty) trf('Conditions: {x}', {'x': conditions.map(tr).join(', ')}),
      if (medicines.isNotEmpty) trf('Medicines: {x}', {'x': medicines.join(', ')}),
      if (pregnancy.isNotEmpty && pregnancy != 'No') tr(pregnancy),
    ];
    return [
      trf('{name}, {age}, {gender}. Main concern: {concern}, for {since}.',
          {'name': name, 'age': age, 'gender': tr(gender), 'concern': concern, 'since': tr(since)}),
      if (health.isNotEmpty) '${health.join('; ')}।',
      trf('Prakriti: {p}; Vikriti: {v}.', {'p': prakriti, 'v': vikriti}),
      if (lab != null && !lab.sample && lab.flagged.isNotEmpty)
        trf('Lab values outside range: {list}.',
            {'list': lab.flagged.map((t) => '${t.name} (${t.flagWord})').join(', ')}),
    ].join(' ');
  }
}
