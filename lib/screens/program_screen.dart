import 'package:flutter/material.dart';
import 'package:veda_verse/app_shell.dart';
import 'package:veda_verse/theme/vv.dart';

/// 12-week PCOS / PCOD lifestyle program.
class ProgramScreen extends StatefulWidget {
  const ProgramScreen({super.key});

  @override
  State<ProgramScreen> createState() => _ProgramScreenState();
}

class _ProgramScreenState extends State<ProgramScreen> {
  final Set<int> _done = {0, 1};
  final Set<int> _signs = {0, 3, 4};
  bool _logged = false;

  static const _habits = [
    ('Breakfast by 9 am', 'Steady meals keep Agni even'),
    ('Dinner before 8 pm, light', 'Gives digestion time before sleep'),
    ('20-minute walk after lunch', 'Gentle movement helps Kapha'),
    ('Asleep by 10:30 pm', 'Same time every night'),
    ('5 minutes of Anulom Vilom', 'Calms stress, any time of day'),
  ];
  static const _signList = [
    'Cycles longer than 35 days',
    'Fewer than 8 periods a year',
    'Extra facial or body hair',
    'Acne after age 20',
    'Weight gain around the waist',
    'Thinning scalp hair',
    'Dark patches on neck',
  ];
  static const _cycles = [('May', 44), ('Jun', 41), ('Jul', 45), ('Aug', 39), ('Sep', 37), ('Oct', 36)];

  @override
  Widget build(BuildContext context) {
    final n = _signs.length;
    final many = n >= 2;
    return Scaffold(
      body: VvFrame(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                child: Row(
                  children: [
                    const VvBackButton(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('LIFESTYLE PROGRAM', style: Vv.kicker(Vv.plum)),
                          const SizedBox(height: 1),
                          const SerifTitle('PCOS / PCOD ', 'care', size: 26),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        color: Vv.plum,
                        padding: const EdgeInsets.all(20),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const VvRings(right: -60, top: -60, color: Vv.plumSoft, opacity: 0.18),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('WEEK 3 OF 12 · RESET', style: Vv.kicker(Vv.plumSoft)),
                                const SizedBox(height: 14),
                                SerifTitle('This week: ', 'eat on time', size: 30, color: Vv.plumBg, height: 1.1),
                                const SizedBox(height: 14),
                                Text('Fixed meal times and an early, light dinner help Agni (digestion) settle. One small change a day.',
                                    style: Vv.sans(14, color: Vv.plumSofter, height: 1.5)),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    _phase(2, 1.0),
                                    const SizedBox(width: 4),
                                    _phase(4, 0.25),
                                    const SizedBox(width: 4),
                                    _phase(4, 0),
                                    const SizedBox(width: 4),
                                    _phase(2, 0),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    for (final l in [(2, 'Understand'), (4, 'Reset'), (4, 'Build'), (2, 'Review')])
                                      Expanded(
                                        flex: l.$1,
                                        child: Text(
                                          l.$2,
                                          softWrap: false,
                                          overflow: TextOverflow.visible,
                                          style: Vv.sans(10.5, weight: FontWeight.w700, color: Vv.plumSoft),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    VvCard(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              const Flexible(child: SerifTitle('This week’s ', 'habits', size: 20)),
                              Text('${_done.length}/5 today', style: Vv.sans(13, weight: FontWeight.w800, color: Vv.plum)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          for (var i = 0; i < _habits.length; i++)
                            VvTap(
                              onTap: () => setState(() => _done.contains(i) ? _done.remove(i) : _done.add(i)),
                              child: Container(
                                constraints: const BoxConstraints(minHeight: 54),
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                decoration: const BoxDecoration(border: Border(top: BorderSide(color: Vv.divider))),
                                child: Row(
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 160),
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        color: _done.contains(i) ? Vv.plum : Vv.surface,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: _done.contains(i) ? Vv.plum : Vv.border3, width: 2),
                                      ),
                                      child: _done.contains(i) ? const Icon(Icons.check_rounded, size: 16, color: Vv.surface) : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(_habits[i].$1, style: Vv.sans(14, weight: FontWeight.w700)),
                                          const SizedBox(height: 2),
                                          Text(_habits[i].$2, style: Vv.sans(12, color: Vv.muted)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    VvCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              const Flexible(child: SerifTitle('Your cycle ', 'log', size: 20)),
                              Text('Days between periods', style: Vv.sans(12, weight: FontWeight.w700, color: Vv.muted)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _chart(),
                          const SizedBox(height: 10),
                          Text('Your last cycles are getting shorter. Keep logging; your Vaidya sees this in week 10.',
                              style: Vv.sans(13, color: Vv.ink2, height: 1.5)),
                          const SizedBox(height: 10),
                          VvTap(
                            onTap: () => setState(() => _logged = true),
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 46),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Vv.plumPale,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Vv.plumBorder, width: 1.5),
                              ),
                              child: Text(_logged ? 'Logged ✓ · day 1 of a new cycle' : 'Log period started today',
                                  style: Vv.sans(14, weight: FontWeight.w800, color: Vv.plum)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 171 / 104,
                      children: [
                        _stat('Waist', '84 cm', '−1 cm since week 1'),
                        _stat('Sleep, 7-day average', '6.8 h', '+0.6 h since week 1'),
                        _stat('Energy today', '3 / 5', 'Logged at 2 pm'),
                        _stat('Habit streak', '9 days', 'Best so far'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    VvCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(TextSpan(children: [
                            TextSpan(text: 'Sign ', style: Vv.serif(20)),
                            TextSpan(text: 'check', style: Vv.serif(20, italic: true)),
                            TextSpan(text: ' · tap what applies', style: Vv.sans(12, weight: FontWeight.w600, color: Vv.muted)),
                          ])),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (var i = 0; i < _signList.length; i++)
                                VvChip(
                                  label: _signList[i],
                                  on: _signs.contains(i),
                                  onColor: Vv.plum,
                                  radius: 12,
                                  hPad: 12,
                                  onTap: () => setState(() => _signs.contains(i) ? _signs.remove(i) : _signs.add(i)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: many ? Vv.amberBg : Vv.mint, borderRadius: BorderRadius.circular(14)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  many ? '$n signs are worth checking' : (n == 1 ? '1 sign noted' : 'No signs selected'),
                                  style: Vv.sans(14, weight: FontWeight.w800, color: many ? Vv.amberInk : Vv.green),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  many
                                      ? 'Ask a gynaecologist about an ultrasound and hormone tests. Only a doctor can diagnose PCOS, usually when 2 of 3 criteria are met.'
                                      : 'Keep following your weekly habits. We will ask again in 4 weeks.',
                                  style: Vv.sans(13, color: many ? Vv.amberInk : Vv.green, height: 1.5),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          VvButton(
                            label: 'Talk to a Vaidya or doctor',
                            height: 48,
                            fontSize: 14,
                            weight: FontWeight.w800,
                            onTap: () {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (_) => const AppShell(initialIndex: Tabs.vaidya)),
                                (_) => false,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const VvNote(text: 'This program helps you manage and improve daily habits. It does not diagnose or cure PCOS. Only a doctor can diagnose it, with tests.'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _phase(int flex, double fill) => Expanded(
        flex: flex,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 8,
            color: const Color(0x40FFFFFF),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(widthFactor: fill, child: Container(color: Vv.plumBg)),
          ),
        ),
      );

  Widget _stat(String label, String value, String note) => VvCard(
        padding: const EdgeInsets.all(14),
        radius: 18,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Vv.sans(12, weight: FontWeight.w700, color: Vv.muted)),
            const SizedBox(height: 4),
            Text(value, style: Vv.serif(26)),
            const SizedBox(height: 4),
            Text(note, style: Vv.sans(12, weight: FontWeight.w700, color: Vv.green)),
          ],
        ),
      );

  Widget _chart() {
    // 130px column: 21 days = 14px, 50 days = 120px; band 21–35 spans 14–65px.
    double h(int v) => 14 + (v - 21) * (106 / 29);
    return Padding(
      padding: const EdgeInsets.only(left: 26),
      child: SizedBox(
        height: 150,
        child: Stack(
          children: [
            Positioned(left: 0, right: 0, top: 65, child: Container(height: 51, decoration: BoxDecoration(color: Vv.mint, borderRadius: BorderRadius.circular(6)))),
            Positioned(right: 6, top: 69, child: Text('typical 21–35 days', style: Vv.sans(10, weight: FontWeight.w800, color: Vv.green))),
            Positioned(left: -26, top: 59, child: Text('35', style: Vv.sans(10, color: Vv.muted))),
            Positioned(left: -26, top: 110, child: Text('21', style: Vv.sans(10, color: Vv.muted))),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 131,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Vv.border3))),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < _cycles.length; i++) ...[
                      if (i > 0) const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${_cycles[i].$2}', style: Vv.sans(11, weight: FontWeight.w800)),
                            const SizedBox(height: 3),
                            Container(
                              height: h(_cycles[i].$2),
                              decoration: BoxDecoration(
                                color: _cycles[i].$2 > 35 ? Vv.plumBar : Vv.plum,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(6), bottom: Radius.circular(2)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 134,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  children: [
                    for (var i = 0; i < _cycles.length; i++) ...[
                      if (i > 0) const SizedBox(width: 14),
                      Expanded(child: Text(_cycles[i].$1, textAlign: TextAlign.center, style: Vv.sans(10, color: Vv.muted))),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
