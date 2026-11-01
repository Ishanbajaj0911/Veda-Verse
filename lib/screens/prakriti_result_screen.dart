import 'package:flutter/material.dart';
import 'package:veda_verse/app_shell.dart';
import 'package:veda_verse/l10n/lang.dart';
import 'package:veda_verse/ml/dosha_predictor.dart';
import 'package:veda_verse/state/app_state.dart';
import 'package:veda_verse/theme/vv.dart';

/// Prakriti result – shows the dosha model's probabilities.
class PrakritiResultScreen extends StatelessWidget {
  final DoshaPrediction prediction;

  /// One sentence naming the answers that drove the result, from
  /// [DoshaPredictor.explain]. Hidden when null.
  final String? why;
  const PrakritiResultScreen({super.key, required this.prediction, this.why});

  static const _blurb = {
    'Vata': 'Air + space: quick, creative and light. You thrive on warmth, routine and enough rest.',
    'Pitta': 'Fire + water: sharp, driven and warm. You thrive on cooling food, calm routines and moderation.',
    'Kapha': 'Earth + water: steady, strong and nurturing. You thrive on light, warm food and regular movement.',
    'Tridoshic': 'All three doshas are fairly even. The aim is to keep that balance by adjusting diet and routine with the seasons.',
  };

  @override
  Widget build(BuildContext context) {
    final p = prediction;
    final v = (p['Vata'] * 100).round();
    final pi = (p['Pitta'] * 100).round();
    final rows = [
      ('Vata', 'air + space', v, Vv.vataBar2),
      ('Pitta', 'fire + water', pi, Vv.goldLight),
      ('Kapha', 'earth + water', 100 - v - pi, Vv.leaf),
    ];
    final second = p.ranked[1];
    final vikriti = AppState.instance.vikriti;
    final String a, b;
    if (p.type == 'Tridoshic') {
      a = '${tr('Tridoshic')}\n';
      b = tr('balanced');
    } else if (p.type.contains('-')) {
      a = '${tr(p.ranked[0].key)}–\n';
      b = tr(p.ranked[1].key);
    } else {
      a = '${tr(p.dominant)}\n';
      b = tr('dominant');
    }

    return Scaffold(
      backgroundColor: Vv.deep,
      body: VvFrame(
        color: Vv.deep,
        child: Stack(
          children: [
            const VvRings(size: 360, right: -110, top: -80, cross: true),
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
                      children: [
                        Text(tr('YOUR PRAKRITI · NATURAL BODY TYPE'), style: Vv.kicker(Vv.onDeepMuted, spacing: 1.4)),
                        const SizedBox(height: 14),
                        SerifTitle(a, b, size: 46, color: Vv.bg, bColor: Vv.goldLight, height: 1.02, letterSpacing: -0.5),
                        const SizedBox(height: 14),
                        Text(tr(_blurb[p.type == 'Tridoshic' ? 'Tridoshic' : p.dominant]!), style: Vv.sans(15, color: Vv.onDeepMuted2, height: 1.55)),
                        if (why != null && why!.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0x14FFFFFF),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 1),
                                  child: Icon(Icons.lightbulb_outline_rounded, size: 18, color: Vv.goldLight),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text.rich(TextSpan(
                                    style: Vv.sans(14, color: Vv.bg, height: 1.45),
                                    children: [
                                      TextSpan(text: tr('Why: '), style: Vv.sans(14, weight: FontWeight.w800, color: Vv.goldLight)),
                                      TextSpan(text: why),
                                    ],
                                  )),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 28),
                        for (final r in rows) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text.rich(TextSpan(children: [
                                TextSpan(text: tr(r.$1), style: Vv.sans(15, weight: FontWeight.w700, color: Vv.bg)),
                                TextSpan(text: ' · ${tr(r.$2)}', style: Vv.sans(15, color: Vv.onDeepMuted)),
                              ])),
                              Text('${r.$3}%', style: Vv.serif(22, color: Vv.bg)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              height: 14,
                              color: const Color(0x1FFFFFFF),
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: (r.$3 / 100).clamp(0, 1),
                                child: Container(decoration: BoxDecoration(color: r.$4, borderRadius: BorderRadius.circular(14))),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0x29F0C46C),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0x66F0C46C)),
                          ),
                          child: Row(
                            children: [
                              Text(tr('RIGHT NOW'), style: Vv.kicker(Vv.goldLight)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: vikriti != null
                                    ? Text.rich(TextSpan(
                                        style: Vv.sans(14, color: Vv.bg, height: 1.4),
                                        children: vikriti.raised == null
                                            ? [
                                                TextSpan(text: tr('No single dosha stands out'), style: Vv.sans(14, weight: FontWeight.w800, color: Vv.bg)),
                                                TextSpan(text: tr(' in the last two weeks. Keep your routine steady.')),
                                              ]
                                            : [
                                                TextSpan(text: trf('{dosha} is raised', {'dosha': tr(vikriti.raised!)}), style: Vv.sans(14, weight: FontWeight.w800, color: Vv.bg)),
                                                TextSpan(text: trf(' (your Vikriti) — matches your {signs}. Your plan starts here.', {'signs': vikriti.shownSigns()})),
                                              ],
                                      ))
                                    : Text.rich(TextSpan(
                                        style: Vv.sans(14, color: Vv.bg, height: 1.4),
                                        children: [
                                          TextSpan(text: trf('{dosha} is your close second', {'dosha': tr(second.key)}), style: Vv.sans(14, weight: FontWeight.w800, color: Vv.bg)),
                                          TextSpan(text: tr(' — your daily plan balances both.')),
                                        ],
                                      )),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(tr('Self-assessment, not a diagnosis. A Vaidya confirms it with Nadi Pariksha (pulse reading).'),
                            style: Vv.sans(12, color: Vv.onDeepMuted, height: 1.5)),
                        const SizedBox(height: 12),
                        VvButton(
                          label: tr('See my daily plan'),
                          height: 56,
                          weight: FontWeight.w800,
                          bg: Vv.gold,
                          fg: Vv.deep,
                          onTap: () => Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const AppShell(initialIndex: Tabs.dosha)),
                            (_) => false,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Opens the Vaidya list so the user picks who to see.
                        VvButton(
                          key: const ValueKey('result-vaidya'),
                          label: tr('Confirm with a Vaidya'),
                          height: 48,
                          fontSize: 14,
                          bg: Colors.transparent,
                          fg: Vv.bg,
                          borderColor: const Color(0x66F0C46C),
                          onTap: () => Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const AppShell(initialIndex: Tabs.vaidya)),
                            (_) => false,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
