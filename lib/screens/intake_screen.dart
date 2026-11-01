import 'package:flutter/material.dart';
import 'package:veda_verse/ai/health_ai.dart';
import 'package:veda_verse/app_shell.dart';
import 'package:veda_verse/l10n/lang.dart';
import 'package:veda_verse/state/accounts.dart';
import 'package:veda_verse/state/app_state.dart';
import 'package:veda_verse/theme/vv.dart';
import 'package:veda_verse/widgets/doc_picker.dart';

/// "Safety basics" – 4-step intake. Every question must be answered before
/// Continue works. When [editing] is true it is opened from the profile
/// ("My Profile") and pops instead of entering the app.
class IntakeScreen extends StatefulWidget {
  final bool editing;
  const IntakeScreen({super.key, this.editing = false, this.ai});

  /// Gemini helper for the prescription scan; tests pass a fake.
  final HealthAi? ai;

  @override
  State<IntakeScreen> createState() => _IntakeScreenState();
}

class _IntakeScreenState extends State<IntakeScreen> {
  final s = AppState.instance;
  int _page = 0;

  /// True after Continue was tapped on this page with something missing:
  /// then each missing answer shows its own message.
  bool _tried = false;
  bool _readingRx = false;

  void _toast(String m) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  /// Reads medicine names from a prescription photo or PDF with Gemini and
  /// adds the new ones to the list. The user can remove any that are wrong.
  Future<void> _scanPrescription() async {
    final ai = widget.ai ?? HealthAi();
    final file = await pickDocument(context, what: 'prescription');
    if (file == null || !mounted) return;
    if (!ai.canRead) {
      _toast(tr('Reading prescriptions works in the Android and iPhone app. Please type the names here.'));
      return;
    }
    setState(() => _readingRx = true);
    try {
      final found = await ai.readPrescription(file);
      final have = _meds.map((m) => m.toLowerCase()).toSet();
      final added = [for (final m in found) if (!have.contains(m.toLowerCase())) m];
      setState(() {
        _meds.addAll(added);
        if (added.isNotEmpty) _noMeds = false;
      });
      _toast(added.isEmpty
          ? (found.isEmpty ? tr('No medicine names could be read. Please type them.') : tr('These medicines are already on your list.'))
          : trf('Added {names}. Please check the names are right.', {'names': added.join(', ')}));
    } on NotThatDocument catch (e) {
      _toast(e.message);
    } catch (e) {
      debugPrint('Prescription scan: $e');
      _toast(tr('Couldn’t read the prescription. Check your internet or type the names.'));
    } finally {
      if (mounted) setState(() => _readingRx = false);
    }
  }

  late final TextEditingController _name = TextEditingController(text: s.name);
  late final TextEditingController _age = TextEditingController(text: s.age > 0 ? '${s.age}' : '');
  final _allergy = TextEditingController();
  final _med = TextEditingController();

  late String _gender = s.gender;
  late final Set<String> _issues = {...s.issues};
  late String _since = s.since;
  late Set<String> _conds = {...s.conditions};
  late String _preg = s.pregnancy;
  late final List<String> _allergies = [...s.allergies];
  late final List<String> _meds = [...s.medicines];

  /// "None" answers for the last step. An empty list only counts once the
  /// user said so, either here or in an earlier finished intake.
  late bool _noAllergies = s.onboarded && s.allergies.isEmpty;
  late bool _noMeds = s.onboarded && s.medicines.isEmpty;

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _allergy.dispose();
    _med.dispose();
    super.dispose();
  }

  static const _pages = [
    ('Step 1 · About you', 'First, let’s ', 'meet', 'Three quick details so advice fits your age and body.'),
    ('Step 2 · Your story', 'What brings ', 'you here?', 'We picked up your welcome choices. Change anything.'),
    ('Step 3 · Your health', 'Keep it ', 'safe', 'Some tips are not right with certain conditions. This keeps Ayu Buddy careful.'),
    ('Step 4 · Allergies & medicines', 'Last one, ', 'promise', 'So no tip ever clashes with what you already take.'),
  ];

  static const _genders = ['Female', 'Male', 'Other'];
  static const _issueList = ['Can’t sleep', 'Always stressed', 'Acidity', 'Back pain', 'Low energy', 'Weight gain', 'Skin issues', 'Irregular periods'];
  static const _sinceList = ['< 2 wks', '1–3 mo', '3+ mo', 'Years'];
  static const _condList = ['Diabetes', 'High BP', 'Thyroid', 'Heart condition', 'Asthma', 'None of these'];
  static const _pregList = ['No', 'Pregnant', 'Breastfeeding'];

  bool get _flagged =>
      _conds.any((c) => c != 'None of these') || (_gender == 'Female' && (_preg == 'Pregnant' || _preg == 'Breastfeeding'));

  int? get _ageValue {
    final a = int.tryParse(_age.text.trim());
    return a != null && a >= 1 && a <= 120 ? a : null;
  }

  /// Text typed in a tag box but not yet added with Enter counts too.
  void _takePending() {
    for (final (c, list) in [(_allergy, _allergies), (_med, _meds)]) {
      final v = c.text.trim();
      if (v.isNotEmpty && !list.contains(v)) list.add(v);
      c.clear();
    }
    if (_allergies.isNotEmpty) _noAllergies = false;
    if (_meds.isNotEmpty) _noMeds = false;
  }

  /// What is still missing on [page]: field -> English message key.
  Map<String, String> _missing(int page) => switch (page) {
        0 => {
            if (_name.text.trim().length < 2) 'name': 'Please enter your name',
            if (_ageValue == null) 'age': 'Enter your age in years (1–120)',
            if (!_genders.contains(_gender)) 'gender': 'Please choose one',
          },
        1 => {
            if (_issues.isEmpty) 'issues': 'Pick at least one',
            if (!_sinceList.contains(_since)) 'since': 'Please choose how long',
          },
        2 => {
            if (_conds.isEmpty) 'conds': 'Pick at least one, or None of these',
            if (_gender == 'Female' && !_pregList.contains(_preg)) 'preg': 'Please choose one',
          },
        _ => {
            if (_allergies.isEmpty && !_noAllergies) 'allergies': 'Add an allergy, or tap No allergies',
            if (_meds.isEmpty && !_noMeds) 'meds': 'Add a medicine, or tap No medicines',
          },
      };

  String? _err(String field) => _tried ? _missing(_page)[field] : null;

  /// One key per question's error line, to scroll to it.
  final _errorKeys = <String, GlobalKey>{};

  void _save() {
    s.update((st) {
      st.name = _name.text.trim();
      st.age = _ageValue ?? st.age;
      st.gender = _gender;
      st.issues = _issues;
      st.since = _since;
      st.conditions = _conds;
      st.pregnancy = _gender == 'Female' ? _preg : 'No';
      st.allergies = _allergies;
      st.medicines = _meds;
    });
  }

  void _next() {
    if (_page == 3) _takePending();
    final missing = _missing(_page);
    if (missing.isNotEmpty) {
      setState(() => _tried = true);
      // Bring the first unanswered question into view.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _errorKeys[missing.keys.first]?.currentContext;
        if (ctx != null && ctx.mounted) {
          Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 250), alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd);
        }
      });
      return;
    }
    if (_page < 3) {
      setState(() {
        _page++;
        _tried = false;
      });
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    _save();
    if (widget.editing) {
      Navigator.of(context).pop();
      return;
    }
    await Accounts.finishOnboarding();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AppShell()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = _pages[_page];
    final blocked = _tried && _missing(_page).isNotEmpty;
    return Scaffold(
      body: VvFrame(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  children: [
                    VvBackButton(
                      onTap: _page == 0
                          ? () => Navigator.of(context).maybePop()
                          : () => setState(() {
                                _page--;
                                _tried = false;
                              }),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: [
                          for (var i = 0; i < 4; i++) ...[
                            if (i > 0) const SizedBox(width: 6),
                            Expanded(
                              child: Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: i < _page ? Vv.green : (i == _page ? Vv.gold : Vv.border2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('${_page + 1}/4', style: Vv.sans(13, weight: FontWeight.w800, color: Vv.ink2)),
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  // Not a lazy ListView: every question and its error line
                  // must exist so Continue can scroll to the first missing one.
                  child: SingleChildScrollView(
                    key: ValueKey(_page),
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(tr(p.$1).toUpperCase(), style: Vv.kicker(Vv.brown, spacing: Lang.hi ? 0.4 : 1.2)),
                      const SizedBox(height: 12),
                      SerifTitle(tr(p.$2), tr(p.$3), size: Lang.hi ? 30 : 34, bColor: Vv.green, height: Lang.hi ? 1.3 : 1.08),
                      const SizedBox(height: 12),
                      Text(tr(p.$4), style: Vv.sans(15, color: Vv.ink2, height: 1.5)),
                      const SizedBox(height: 18),
                      ..._body(),
                    ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                child: Column(
                  children: [
                    VvButton(
                      label: blocked
                          ? tr('Answer the questions marked in red')
                          : _page < 3
                              ? tr('Continue')
                              : (widget.editing ? tr('Save') : tr('Save & go to my home')),
                      height: 56,
                      fontSize: blocked ? 15 : 16,
                      weight: FontWeight.w800,
                      bg: blocked ? Vv.redPale : (_page < 3 ? Vv.green : Vv.gold),
                      fg: blocked ? Vv.redInk : (_page < 3 ? Vv.surface : Vv.deep),
                      trailing: _page < 3 && !blocked ? Icons.arrow_forward_rounded : null,
                      onTap: _next,
                    ),
                    const SizedBox(height: 8),
                    Text(tr('A Vaidya sees this only if you book a consult.'), style: Vv.sans(12, color: Vv.muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _body() {
    switch (_page) {
      case 0:
        return [
          _label(tr('What should we call you?')),
          _input(_name, TextInputType.name, 'name', hint: tr('Your name')),
          _error('name'),
          const SizedBox(height: 14),
          _label(tr('Your age')),
          Align(alignment: Alignment.centerLeft, child: SizedBox(width: 160, child: _input(_age, TextInputType.number, 'age', hint: tr('Age in years')))),
          _error('age'),
          const SizedBox(height: 14),
          _label(tr('Gender')),
          Row(
            children: [
              for (final g in _genders) ...[
                Expanded(child: _seg(tr(g), _gender == g, () => setState(() => _gender = g), field: 'gender')),
                if (g != _genders.last) const SizedBox(width: 8),
              ],
            ],
          ),
          _error('gender'),
        ];
      case 1:
        return [
          Text.rich(TextSpan(children: [
            TextSpan(text: tr('What’s bothering you? '), style: Vv.sans(15, weight: FontWeight.w700)),
            TextSpan(text: tr('Pick any'), style: Vv.sans(15, weight: FontWeight.w600, color: Vv.muted)),
            TextSpan(text: ' *', style: Vv.sans(15, weight: FontWeight.w800, color: Vv.red)),
          ])),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final i in _issueList)
                VvChip(
                  label: tr(i),
                  on: _issues.contains(i),
                  minHeight: 46,
                  fontSize: 14,
                  hPad: 16,
                  onTap: () => setState(() => _issues.contains(i) ? _issues.remove(i) : _issues.add(i)),
                ),
            ],
          ),
          _error('issues'),
          const SizedBox(height: 14),
          _label(tr('Since when?')),
          Row(
            children: [
              for (final sc in _sinceList) ...[
                Expanded(child: _seg(tr(sc), _since == sc, () => setState(() => _since = sc), field: 'since', fontSize: Lang.hi ? 12.5 : 14)),
                if (sc != _sinceList.last) const SizedBox(width: 6),
              ],
            ],
          ),
          _error('since'),
          const SizedBox(height: 14),
          Container(
            constraints: const BoxConstraints(minHeight: 50),
            decoration: BoxDecoration(
              color: Vv.blueTint,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Vv.blue, width: 1.5, style: BorderStyle.solid),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.mic_none_rounded, size: 18, color: Vv.blueInk),
                const SizedBox(width: 8),
                Flexible(child: Text(Lang.hi ? tr('Or just say it — Hindi / English') : 'Or just say it — हिंदी / English',
                    style: Vv.sans(14, weight: FontWeight.w700, color: Vv.blueInk))),
              ],
            ),
          ),
        ];
      case 2:
        return [
          _label(tr('Do you have any of these?')),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in _condList)
                VvChip(
                  label: tr(c),
                  on: _conds.contains(c),
                  onColor: Vv.brown,
                  minHeight: 46,
                  fontSize: 14,
                  hPad: 16,
                  onTap: () => setState(() {
                    if (c == 'None of these') {
                      _conds = _conds.contains(c) ? {} : {c};
                    } else {
                      _conds.remove('None of these');
                      _conds.contains(c) ? _conds.remove(c) : _conds.add(c);
                    }
                  }),
                ),
            ],
          ),
          _error('conds'),
          if (_gender == 'Female') ...[
            const SizedBox(height: 14),
            _label(tr('Pregnant or breastfeeding?')),
            Row(
              children: [
                for (final pr in _pregList) ...[
                  Expanded(child: _seg(tr(pr), _preg == pr, () => setState(() => _preg = pr), field: 'preg', fontSize: 13)),
                  if (pr != _pregList.last) const SizedBox(width: 6),
                ],
              ],
            ),
            _error('preg'),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Vv.goldPale, borderRadius: BorderRadius.circular(999)),
              child: Text(tr('Used by the AI safety check'), style: Vv.sans(12, weight: FontWeight.w800, color: Vv.brown)),
            ),
          ),
        ];
      default:
        return [
          _label(tr('Any allergies?')),
          _tagBox(_allergies, _allergy, tr('Add…'), Vv.goldPale, Vv.brown, 'allergies', onAdd: () => _noAllergies = false),
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerLeft, child: VvChip(
            label: tr('No allergies'),
            on: _noAllergies && _allergies.isEmpty,
            onTap: () => setState(() {
              _noAllergies = !(_noAllergies && _allergies.isEmpty);
              if (_noAllergies) _allergies.clear();
            }),
          )),
          _error('allergies'),
          const SizedBox(height: 14),
          _label(tr('Medicines you take now')),
          _tagBox(_meds, _med, tr('Add one more'), Vv.mint, Vv.green, 'meds', onAdd: () => _noMeds = false),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              VvChip(
                label: tr('No medicines'),
                on: _noMeds && _meds.isEmpty,
                onTap: () => setState(() {
                  _noMeds = !(_noMeds && _meds.isEmpty);
                  if (_noMeds) _meds.clear();
                }),
              ),
              VvTap(
                onTap: _readingRx ? null : _scanPrescription,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 40),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Vv.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Vv.border3, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_readingRx)
                        const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Vv.green))
                      else
                        const Icon(Icons.document_scanner_outlined, size: 16, color: Vv.green),
                      const SizedBox(width: 8),
                      Flexible(child: Text(_readingRx ? tr('Reading prescription…') : tr('Scan prescription instead'),
                          style: Vv.sans(13, weight: FontWeight.w700, color: Vv.green))),
                    ],
                  ),
                ),
              ),
            ],
          ),
          _error('meds'),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Vv.cream, borderRadius: BorderRadius.circular(14)),
            child: VvNote(
              icon: Icons.shield_outlined,
              color: Vv.brownDark,
              style: Vv.sans(13, color: Vv.brownDark, height: 1.5),
              text: _flagged
                  ? tr('Noted. Ayu Buddy will involve a Vaidya before any diet, herb or routine change for you.')
                  : tr('Ayu Buddy checks these before every answer, and never suggests medicines.'),
            ),
          ),
        ];
    }
  }

  /// Question label with a red * (every question is required).
  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text.rich(TextSpan(children: [
          TextSpan(text: t, style: Vv.sans(15, weight: FontWeight.w700)),
          TextSpan(text: ' *', style: Vv.sans(15, weight: FontWeight.w800, color: Vv.red)),
        ])),
      );

  /// The message for a missing answer, shown after Continue was tapped.
  Widget _error(String field) {
    final e = _err(field);
    final key = _errorKeys.putIfAbsent(field, GlobalKey.new);
    if (e == null) return SizedBox.shrink(key: key);
    return Padding(
      key: key,
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 16, color: Vv.redInk),
          const SizedBox(width: 6),
          Expanded(child: Text(tr(e), style: Vv.sans(13, weight: FontWeight.w700, color: Vv.redInk))),
        ],
      ),
    );
  }

  Widget _input(TextEditingController c, TextInputType type, String field, {String? hint}) => Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: Vv.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _err(field) != null ? Vv.red : Vv.border3, width: 1.5),
        ),
        child: TextField(
          controller: c,
          keyboardType: type,
          onChanged: (_) {
            if (_tried) setState(() {});
          },
          style: Vv.sans(17, color: Vv.ink),
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            hintText: hint,
            hintStyle: Vv.sans(17, color: Vv.disabled),
          ),
        ),
      );

  Widget _seg(String label, bool on, VoidCallback onTap, {required String field, double fontSize = 14}) => VvTap(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 50),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: on ? Vv.green : Vv.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: on ? Vv.green : (_err(field) != null ? Vv.red : Vv.border3), width: 1.5),
          ),
          child: Text(label,
              textAlign: TextAlign.center, style: Vv.sans(fontSize, weight: FontWeight.w700, color: on ? Vv.surface : Vv.ink)),
        ),
      );

  Widget _tagBox(List<String> items, TextEditingController c, String hint, Color bg, Color fg, String field,
          {required VoidCallback onAdd}) =>
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Vv.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _err(field) != null ? Vv.red : Vv.border3, width: 1.5),
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final it in items)
              VvTap(
                onTap: () => setState(() => items.remove(it)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
                  child: Text('$it ×', style: Vv.sans(14, weight: FontWeight.w700, color: fg)),
                ),
              ),
            SizedBox(
              width: 160,
              child: TextField(
                controller: c,
                style: Vv.sans(15, color: Vv.ink),
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: hint,
                  hintStyle: Vv.sans(15, color: Vv.disabled),
                ),
                onSubmitted: (v) {
                  if (v.trim().isEmpty) return;
                  setState(() {
                    items.add(v.trim());
                    c.clear();
                    onAdd();
                  });
                },
              ),
            ),
          ],
        ),
      );
}
