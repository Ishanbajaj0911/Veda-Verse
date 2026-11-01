import 'package:flutter/material.dart';
import 'package:veda_verse/engine/plan_engine.dart';
import 'package:veda_verse/screens/prakriti_quiz_screen.dart';
import 'package:veda_verse/screens/profile_menu_screen.dart';
import 'package:veda_verse/screens/program_screen.dart';
import 'package:veda_verse/screens/scan_screen.dart';
import 'package:veda_verse/state/app_state.dart';
import 'package:veda_verse/theme/vv.dart';

/// Dosha analysis tab.
class DoshaScreen extends StatelessWidget {
  const DoshaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    final now = DateTime.now();
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        final mix = s.mix;
        final rows = [
          ('Vata', 'air + space', mix['Vata']!, Vv.vataBar),
          ('Pitta', 'fire + water', mix['Pitta']!, Vv.pittaBar),
          ('Kapha', 'earth + water', mix['Kapha']!, Vv.kaphaBar),
        ];
        final label = s.prakritiLabel;
        final parts = label.split(' ');
        final input = s.engineInput;
        final plan = dailyPlan(input);
        final note = vaidyaNote(input);
        return Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top),
            VvTabHeader(
              hello: '${weekdayName(now)} · ${rituFor(now)}',
              title: SerifTitle('Hello, ', s.firstName, size: 27, letterSpacing: -0.2),
              initial: s.initial,
              extra: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: Vv.goldPale, borderRadius: BorderRadius.circular(999)),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department_outlined, size: 16, color: Vv.brown),
                    const SizedBox(width: 5),
                    Text('${s.streak} days', style: Vv.sans(13, weight: FontWeight.w800, color: Vv.brown)),
                  ],
                ),
              ),
              onProfile: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileMenuScreen())),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      color: Vv.deep,
                      padding: const EdgeInsets.all(20),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const VvRings(size: 220),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('YOUR PRAKRITI · NATURAL BODY TYPE',
                                            style: Vv.sans(12, weight: FontWeight.w700, color: Vv.onDeepMuted, letterSpacing: 1)),
                                        const SizedBox(height: 4),
                                        !s.hasPrakriti
                                            ? SerifTitle('Not ', 'checked yet', size: 32, color: Vv.bg, letterSpacing: -0.3)
                                            : parts.length > 1
                                            ? SerifTitle('${parts.first} ', parts.sublist(1).join(' '), size: 32, color: Vv.bg, letterSpacing: -0.3)
                                            : Text(label, style: Vv.serif(32, color: Vv.bg, letterSpacing: -0.3)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(color: const Color(0x1FFFFFFF), borderRadius: BorderRadius.circular(999)),
                                    child: Text(s.prediction == null ? 'Take the quiz' : 'Updated today',
                                        style: Vv.sans(12, weight: FontWeight.w700, color: Vv.bg)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              for (final r in rows) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text.rich(TextSpan(children: [
                                      TextSpan(text: r.$1, style: Vv.sans(14, weight: FontWeight.w700, color: Vv.bg)),
                                      TextSpan(text: ' · ${r.$2}', style: Vv.sans(14, color: Vv.onDeepMuted)),
                                    ])),
                                    Text('${r.$3}%', style: Vv.sans(14, weight: FontWeight.w700, color: Vv.bg)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                _bar(r.$3 / 100, r.$4, 10),
                                const SizedBox(height: 12),
                              ],
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: const Color(0x2EE08A1E), borderRadius: BorderRadius.circular(14)),
                                child: Row(
                                  children: [
                                    Icon(s.hasPrakriti ? Icons.arrow_upward_rounded : Icons.quiz_outlined, size: 20, color: Vv.goldSoft),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: s.hasPrakriti
                                          ? Text.rich(
                                              TextSpan(
                                                style: Vv.sans(13, color: Vv.bg, height: 1.45),
                                                children: [
                                                  TextSpan(text: 'Right now (Vikriti): ', style: Vv.sans(13, weight: FontWeight.w800, color: Vv.bg)),
                                                  TextSpan(
                                                      text: s.vikriti?.summary ??
                                                          'retake the quiz to see how you feel right now.'),
                                                ],
                                              ),
                                            )
                                          : Text(
                                              'Take the Prakriti quiz to see your Vata, Pitta and Kapha mix. It takes about 4 minutes.',
                                              style: Vv.sans(13, color: Vv.bg, height: 1.45),
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _action(
                          context,
                          Icons.document_scanner_outlined,
                          'Scan lab report',
                          'Gemini reads it for you',
                          () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScanScreen())),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _action(
                          context,
                          Icons.refresh_rounded,
                          s.prediction == null ? 'Take Prakriti quiz' : 'Retake Prakriti quiz',
                          '24 questions · 4 min',
                          () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrakritiQuizScreen())),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  VvTap(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProgramScreen())),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Vv.plumPale, borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(color: Vv.plum, borderRadius: BorderRadius.circular(14)),
                            child: const Icon(Icons.schedule_rounded, color: Vv.surface, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('LIFESTYLE PROGRAM', style: Vv.kicker(Vv.plumInk, spacing: 0.8)),
                                const SizedBox(height: 2),
                                const SerifTitle('PCOS / PCOD · ', 'Week 3 of 12', size: 19),
                                const SizedBox(height: 2),
                                Text('Sign check, cycle log and this week’s habits', style: Vv.sans(12, color: Vv.muted)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: Vv.plumInk),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  VvCard(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text.rich(TextSpan(children: [
                              TextSpan(text: 'Today’s Dinacharya', style: Vv.serif(17, weight: FontWeight.w700)),
                              TextSpan(text: ' · daily routine', style: Vv.sans(13, weight: FontWeight.w600, color: Vv.muted)),
                            ])),
                            Text('${plan.where((p) => s.doneToday.contains(p.item.id)).length}/${plan.length} done',
                                style: Vv.sans(13, weight: FontWeight.w700, color: Vv.green)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          input.focus == null
                              ? 'Picked for your concerns and ${rituLabel(input.ritu!)}. Take the quiz to fit it to your body type.'
                              : 'Picked for ${input.focus == input.vikriti?.raised ? 'your raised ${input.focus}' : 'your ${input.focus}'}, your concerns and ${rituLabel(input.ritu!)}.',
                          style: Vv.sans(12, color: Vv.muted),
                        ),
                        const SizedBox(height: 8),
                        for (final p in plan) _task(s, p),
                        if (note != null) ...[
                          const SizedBox(height: 4),
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Vv.cream, borderRadius: BorderRadius.circular(12)),
                            child: VvNote(
                              text: note,
                              color: Vv.brownDark,
                              style: Vv.sans(12, color: Vv.brownDark, height: 1.45),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const VvNote(
                    text: 'Wellness guidance from classical texts and your intake — not a diagnosis. Herbs and medicines are only discussed with a Vaidya.',
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _task(AppState s, PlannedItem p) {
    final id = p.item.id;
    final done = s.doneToday.contains(id);
    final t = (p.item.title, p.reason, p.item.time);
    return VvTap(
      onTap: () => s.toggleDone(id),
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: Vv.divider))),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: done ? Vv.green : Vv.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: done ? Vv.green : Vv.sage, width: 2),
              ),
              child: done ? const Icon(Icons.check_rounded, size: 16, color: Vv.surface) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.$1, style: Vv.sans(14, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(t.$2, style: Vv.sans(12, color: Vv.muted)),
                ],
              ),
            ),
            Text(t.$3, style: Vv.sans(12, weight: FontWeight.w700, color: Vv.muted)),
          ],
        ),
      ),
    );
  }

  static Widget _bar(double f, Color c, double h) => ClipRRect(
        borderRadius: BorderRadius.circular(h),
        child: Container(
          height: h,
          color: const Color(0x1FFFFFFF),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: f.clamp(0, 1),
            child: Container(decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(h))),
          ),
        ),
      );

  Widget _action(BuildContext context, IconData icon, String title, String sub, VoidCallback onTap) => VvTap(
        onTap: onTap,
        child: VvCard(
          padding: const EdgeInsets.all(14),
          radius: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 22, color: Vv.green),
              const SizedBox(height: 8),
              Text(title, style: Vv.sans(14, weight: FontWeight.w700, height: 1.3)),
              Text(sub, style: Vv.sans(12, color: Vv.muted, height: 1.3)),
            ],
          ),
        ),
      );
}
