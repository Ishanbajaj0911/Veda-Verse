import 'package:flutter/material.dart';
import 'package:veda_verse/ai/health_ai.dart';
import 'package:veda_verse/ai/safety.dart';
import 'package:veda_verse/l10n/lang.dart';
import 'package:veda_verse/ml/dosha_predictor.dart';
import 'package:veda_verse/screens/scan_screen.dart';
import 'package:veda_verse/state/app_state.dart';
import 'package:veda_verse/theme/vv.dart';

/// The health summary a Vaidya sees before a consult: a case sheet built
/// from the user's own intake, quiz, lab report and Ayu Buddy referrals,
/// with a short Gemini-written overview on top.
class HealthSummaryScreen extends StatefulWidget {
  /// Gemini helper; tests pass a fake. Defaults to the real one.
  final HealthAi? ai;
  const HealthSummaryScreen({super.key, this.ai});

  @override
  State<HealthSummaryScreen> createState() => _HealthSummaryScreenState();
}

class _HealthSummaryScreenState extends State<HealthSummaryScreen> {
  late final HealthAi _ai = widget.ai ?? HealthAi();
  CaseSheet? _sheet;
  String? _overview;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _build();
  }

  Future<void> _build() async {
    setState(() => _loading = true);
    DoshaPredictor? model;
    try {
      model = await DoshaPredictor.load();
    } catch (_) {}
    final sheet = CaseSheet.from(AppState.instance, model);
    if (!mounted) return;
    setState(() => _sheet = sheet);
    final overview = await _ai.vaidyaOverview(sheet);
    if (mounted) {
      setState(() {
        _overview = overview;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _sheet;
    return Scaffold(
      body: VvFrame(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Row(
                  children: [
                    const VvBackButton(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SerifTitle(tr('Health '), tr('summary'), size: 25),
                          Text(tr('What your Vaidya sees before the consult'), style: Vv.sans(12, color: Vv.muted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: c == null
                    ? const Center(child: CircularProgressIndicator(color: Vv.green))
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        children: [
                          _overviewCard(),
                          const SizedBox(height: 14),
                          _section(tr('Story'), [
                            (tr('Concerns'), c.concerns.isEmpty ? tr('None noted') : c.concerns.map(tr).join(', ')),
                            (tr('Since'), tr(c.since)),
                          ]),
                          _section(tr('Health and safety'), [
                            (tr('Conditions'), c.conditions.isEmpty ? tr('None noted') : c.conditions.map(tr).join(', ')),
                            if (c.pregnancy.isNotEmpty) (tr('Pregnancy'), tr(c.pregnancy)),
                            (tr('Medicines'), c.medicines.isEmpty ? tr('None') : c.medicines.join(', ')),
                            (tr('Allergies'), c.allergies.isEmpty ? tr('None') : c.allergies.join(', ')),
                          ]),
                          _section(tr('Ayurvedic profile'), [
                            (tr('Prakriti'), c.prakriti),
                            (tr('Vikriti'), c.vikriti),
                            for (final (l, a) in c.agniMalaNidra) (l, a),
                          ]),
                          _labsSection(c.labs),
                          if (c.flags.isNotEmpty) _flagsSection(c.flags),
                          const SizedBox(height: 4),
                          VvNote(
                            text: tr('Shared only with the Vaidya you book, for that consult. You can turn sharing off on the booking '
                                'screen. Self-reported and AI-assisted: not a diagnosis.'),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _overviewCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Vv.deep, borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome_outlined, size: 16, color: Vv.goldLight),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(_ai.configured ? tr('OVERVIEW · WRITTEN BY GEMINI FROM YOUR DATA') : tr('OVERVIEW'),
                      style: Vv.kicker(Vv.goldLight, spacing: 0.8, size: 11)),
                ),
                if (!_loading)
                  InkWell(
                    onTap: _build,
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.refresh_rounded, size: 18, color: Vv.onDeepMuted)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            _loading
                ? Row(children: [
                    const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Vv.goldLight)),
                    const SizedBox(width: 10),
                    Text(tr('Writing the overview…'), style: Vv.sans(14, color: Vv.onDeepMuted2)),
                  ])
                : Text(_overview ?? '', style: Vv.sans(14, color: Vv.bg, height: 1.55)),
          ],
        ),
      );

  Widget _section(String title, List<(String, String)> rows) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: VvCard(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title.toUpperCase(), style: Vv.kicker(Vv.ink2, spacing: 1)),
              const SizedBox(height: 6),
              for (final (k, v) in rows)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: Vv.divider))),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 108, child: Text(k, style: Vv.sans(13, weight: FontWeight.w700, color: Vv.muted))),
                      Expanded(child: Text(v, style: Vv.sans(13.5, height: 1.45))),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );

  Widget _labsSection(LabReport? r) {
    if (r == null || r.sample) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: VvCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(child: Text(tr('No lab report shared yet.'), style: Vv.sans(13.5, color: Vv.ink2))),
              TextButton(
                onPressed: () async {
                  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScanScreen()));
                  if (mounted) _build();
                },
                child: Text(tr('Scan a report'), style: Vv.sans(13, weight: FontWeight.w800, color: Vv.green)),
              ),
            ],
          ),
        ),
      );
    }
    return _section('${tr('Lab report')}${r.lab.isEmpty ? '' : ' · ${r.lab}'}', [
      (tr('Summary'), r.summary),
      for (final t in r.flagged)
        (r.nameOf(t), trf('{value} ({flag}; range {range})', {'value': t.valueWithUnit, 'flag': t.flagWord, 'range': t.range})),
    ]);
  }

  Widget _flagsSection(List<BuddyFlag> flags) {
    final vaidya = flags.where((f) => f.level == SafetyLevel.vaidya).toList();
    final alerts = flags.where((f) => f.level != SafetyLevel.vaidya).length;
    return _section(tr('From Ayu Buddy'), [
      for (final f in vaidya.reversed.take(5)) (tr('Asked'), '“${f.question}”'),
      if (alerts > 0)
        (
            tr('Safety'),
            alerts == 1
                ? tr('Emergency guidance was shown 1 time')
                : trf('Emergency guidance was shown {n} times', {'n': alerts})),
    ]);
  }
}
