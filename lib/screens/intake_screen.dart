import 'package:flutter/material.dart';
import 'package:veda_verse/ai/health_ai.dart';
import 'package:veda_verse/app_shell.dart';
import 'package:veda_verse/state/app_state.dart';
import 'package:veda_verse/theme/vv.dart';
import 'package:veda_verse/widgets/doc_picker.dart';

/// "Safety basics" – 4-step intake. When [editing] is true it is opened from
/// the profile ("My Profile") and pops instead of entering the app.
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
  bool _warn = false;
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
      _toast('Reading prescriptions works in the Android and iPhone app. Please type the names here.');
      return;
    }
    setState(() => _readingRx = true);
    try {
      final found = await ai.readPrescription(file);
      final have = _meds.map((m) => m.toLowerCase()).toSet();
      final added = [for (final m in found) if (!have.contains(m.toLowerCase())) m];
      setState(() => _meds.addAll(added));
      _toast(added.isEmpty
          ? (found.isEmpty ? 'No medicine names could be read. Please type them.' : 'These medicines are already on your list.')
          : 'Added ${added.join(', ')}. Please check the names are right.');
    } on NotThatDocument catch (e) {
      _toast(e.message);
    } catch (e) {
      debugPrint('Prescription scan: $e');
      _toast('Couldn’t read the prescription. Check your internet or type the names.');
    } finally {
      if (mounted) setState(() => _readingRx = false);
    }
  }

  late final TextEditingController _name = TextEditingController(text: s.name);
  late final TextEditingController _age = TextEditingController(text: '${s.age}');
  final _allergy = TextEditingController();
  final _med = TextEditingController();

  late String _gender = s.gender;
  late final Set<String> _issues = {...s.issues};
  late String _since = s.since;
  late Set<String> _conds = {...s.conditions};
  late String _preg = s.pregnancy;
  late final List<String> _allergies = [...s.allergies];
  late final List<String> _meds = [...s.medicines];

  static const _pages = [
    ('Step 1 · About you', 'First, let’s ', 'meet', 'Three quick details so advice fits your age and body.'),
    ('Step 2 · Your story', 'What brings ', 'you here?', 'We picked up your welcome choices. Change anything.'),
    ('Step 3 · Your health', 'Keep it ', 'safe', 'Some tips are not right with certain conditions. This keeps Ayu Buddy careful.'),
    ('Step 4 · Allergies & medicines', 'Last one, ', 'promise', 'So no tip ever clashes with what you already take.'),
  ];

  static const _issueList = ['Can’t sleep', 'Always stressed', 'Acidity', 'Back pain', 'Low energy', 'Weight gain', 'Skin issues', 'Irregular periods'];
  static const _sinceList = ['< 2 wks', '1–3 mo', '3+ mo', 'Years'];
  static const _condList = ['Diabetes', 'High BP', 'Thyroid', 'Heart condition', 'Asthma', 'None of these'];

  bool get _flagged =>
      _conds.any((c) => c != 'None of these') || (_gender == 'Female' && _preg != 'No');

  void _save() {
    s.update((st) {
      st.name = _name.text.trim().isEmpty ? st.name : _name.text.trim();
      st.age = int.tryParse(_age.text) ?? st.age;
      st.gender = _gender;
      st.issues = _issues;
      st.since = _since;
      st.conditions = _conds;
      st.pregnancy = _preg;
      st.allergies = _allergies;
      st.medicines = _meds;
    });
  }

  void _next() {
    final ok = _page != 1 || _issues.isNotEmpty;
    if (!ok) {
      setState(() => _warn = true);
      return;
    }
    setState(() {
      _page++;
      _warn = false;
    });
  }

  void _finish() {
    _save();
    if (widget.editing) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AppShell()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _pages[_page];
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
                                _warn = false;
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
                  child: ListView(
                    key: ValueKey(_page),
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                    children: [
                      Text(p.$1.toUpperCase(), style: Vv.kicker(Vv.brown, spacing: 1.2)),
                      const SizedBox(height: 12),
                      SerifTitle(p.$2, p.$3, size: 34, bColor: Vv.green, height: 1.08),
                      const SizedBox(height: 12),
                      Text(p.$4, style: Vv.sans(15, color: Vv.ink2, height: 1.5)),
                      const SizedBox(height: 18),
                      ..._body(),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                child: Column(
                  children: [
                    if (_page < 3)
                      VvButton(
                        label: _warn ? 'Pick at least one' : 'Continue',
                        height: 56,
                        weight: FontWeight.w800,
                        bg: _warn ? Vv.redPale : Vv.green,
                        fg: _warn ? Vv.redInk : Vv.surface,
                        trailing: Icons.arrow_forward_rounded,
                        onTap: _next,
                      )
                    else
                      VvButton(
                        label: widget.editing ? 'Save' : 'Save & go to my home',
                        height: 56,
                        weight: FontWeight.w800,
                        bg: Vv.gold,
                        fg: Vv.deep,
                        onTap: _finish,
                      ),
                    const SizedBox(height: 8),
                    Text('A Vaidya sees this only if you book a consult.', style: Vv.sans(12, color: Vv.muted)),
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
          _label('What should we call you?'),
          _input(_name, TextInputType.name),
          const SizedBox(height: 14),
          _label('Your age'),
          SizedBox(width: 140, child: _input(_age, TextInputType.number)),
          const SizedBox(height: 14),
          _label('Gender'),
          Row(
            children: [
              for (final g in ['Female', 'Male', 'Other']) ...[
                Expanded(child: _seg(g, _gender == g, () => setState(() => _gender = g))),
                if (g != 'Other') const SizedBox(width: 8),
              ],
            ],
          ),
        ];
      case 1:
        return [
          Text.rich(TextSpan(children: [
            TextSpan(text: 'What’s bothering you? ', style: Vv.sans(15, weight: FontWeight.w700)),
            TextSpan(text: 'Pick any', style: Vv.sans(15, weight: FontWeight.w600, color: Vv.muted)),
          ])),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final i in _issueList)
                VvChip(
                  label: i,
                  on: _issues.contains(i),
                  minHeight: 46,
                  fontSize: 14,
                  hPad: 16,
                  onTap: () => setState(() {
                    _issues.contains(i) ? _issues.remove(i) : _issues.add(i);
                    _warn = false;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _label('Since when?'),
          Row(
            children: [
              for (final sc in _sinceList) ...[
                Expanded(child: _seg(sc, _since == sc, () => setState(() => _since = sc))),
                if (sc != _sinceList.last) const SizedBox(width: 6),
              ],
            ],
          ),
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
                Text('Or just say it — हिंदी / English',
                    style: Vv.sans(14, weight: FontWeight.w700, color: Vv.blueInk)),
              ],
            ),
          ),
        ];
      case 2:
        return [
          _label('Do you have any of these?'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in _condList)
                VvChip(
                  label: c,
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
          if (_gender == 'Female') ...[
            const SizedBox(height: 14),
            _label('Pregnant or breastfeeding?'),
            Row(
              children: [
                for (final pr in ['No', 'Pregnant', 'Breastfeeding']) ...[
                  Expanded(child: _seg(pr, _preg == pr, () => setState(() => _preg = pr), fontSize: 13)),
                  if (pr != 'Breastfeeding') const SizedBox(width: 6),
                ],
              ],
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Vv.goldPale, borderRadius: BorderRadius.circular(999)),
              child: Text('Used by the AI safety check', style: Vv.sans(12, weight: FontWeight.w800, color: Vv.brown)),
            ),
          ),
        ];
      default:
        return [
          _label('Any allergies?'),
          _tagBox(_allergies, _allergy, 'Add…', Vv.goldPale, Vv.brown),
          const SizedBox(height: 14),
          _label('Medicines you take now'),
          _tagBox(_meds, _med, 'Add one more', Vv.mint, Vv.green),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: VvTap(
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
                    Text(_readingRx ? 'Reading prescription…' : 'Scan prescription instead',
                        style: Vv.sans(13, weight: FontWeight.w700, color: Vv.green)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Vv.cream, borderRadius: BorderRadius.circular(14)),
            child: VvNote(
              icon: Icons.shield_outlined,
              color: Vv.brownDark,
              style: Vv.sans(13, color: Vv.brownDark, height: 1.5),
              text: _flagged
                  ? 'Noted. Ayu Buddy will involve a Vaidya before any diet, herb or routine change for you.'
                  : 'Ayu Buddy checks these before every answer, and never suggests medicines.',
            ),
          ),
        ];
    }
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: Vv.sans(15, weight: FontWeight.w700)),
      );

  Widget _input(TextEditingController c, TextInputType type) => Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: Vv.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Vv.border3, width: 1.5),
        ),
        child: TextField(
          controller: c,
          keyboardType: type,
          style: Vv.sans(17, color: Vv.ink),
          decoration: const InputDecoration(isDense: true, border: InputBorder.none),
        ),
      );

  Widget _seg(String label, bool on, VoidCallback onTap, {double fontSize = 14}) => VvTap(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 50),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? Vv.green : Vv.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: on ? Vv.green : Vv.border3, width: 1.5),
          ),
          child: Text(label, style: Vv.sans(fontSize, weight: FontWeight.w700, color: on ? Vv.surface : Vv.ink)),
        ),
      );

  Widget _tagBox(List<String> items, TextEditingController c, String hint, Color bg, Color fg) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Vv.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Vv.border3, width: 1.5),
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
              width: 140,
              child: TextField(
                controller: c,
                style: Vv.sans(15, color: Vv.ink),
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
                  });
                },
              ),
            ),
          ],
        ),
      );
}
