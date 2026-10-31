import 'package:flutter/material.dart';
import 'package:veda_verse/app_shell.dart';
import 'package:veda_verse/screens/profile_menu_screen.dart';
import 'package:veda_verse/state/app_state.dart';
import 'package:veda_verse/theme/vv.dart';

/// Home tab (design page "Home").
class AppHomeScreen extends StatefulWidget {
  final ValueChanged<int> onGo;
  const AppHomeScreen({super.key, required this.onGo});

  @override
  State<AppHomeScreen> createState() => _AppHomeScreenState();
}

class _AppHomeScreenState extends State<AppHomeScreen> {
  int _story = 0;

  static const _stories = [
    ('Ritucharya', 'Oct 28, 2026', 'Sharad Ritu: why autumn is Pitta season — and what to eat now', Vv.goldPale, Vv.brown),
    ('Video · 6 min', 'Oct 24, 2026', 'Anulom Vilom, explained step by step by a Vaidya', Vv.bluePale, Vv.blueInk),
    ('Newsletter', 'Oct 20, 2026', 'Veda Letter #12: sleep, screens and a restless Vata mind', Vv.plumPale, Vv.plum),
    ('Journal', 'Oct 14, 2026', 'Agni, simply: the digestive fire behind your energy', Vv.mint, Vv.green),
  ];

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    final now = DateTime.now();
    final ritu = rituFor(now).split(' (').first;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        final done = s.dinacharyaDone.length;
        return Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, 18 + MediaQuery.of(context).padding.top, 16, 8),
              child: Row(
                children: [
                  const VvLogoTile(),
                  const SizedBox(width: 10),
                  Expanded(child: SerifTitle('Veda', 'Verse', size: 23)),
                  VvAvatar(
                    initial: s.initial,
                    fontSize: 18,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileMenuScreen())),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(0, 10, 0, 100),
                children: _padded([
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${weekdayName(now)} · $ritu', style: Vv.sans(13, weight: FontWeight.w700, color: Vv.muted)),
                        const SizedBox(height: 2),
                        SerifTitle('Namaste, ', s.firstName, size: 36, height: 1.05),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Streak card
                  VvTap(
                    onTap: () => widget.onGo(Tabs.dosha),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        color: Vv.deep,
                        padding: const EdgeInsets.all(18),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const VvRings(),
                            Row(
                              children: [
                                _Ring(fraction: done / 4, label: '$done/4'),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${s.streak}-DAY STREAK', style: Vv.kicker(Vv.goldLight)),
                                      const SizedBox(height: 4),
                                      SerifTitle('Next: ', 'Anulom Vilom', size: 21, color: Vv.bg, height: 1.15),
                                      const SizedBox(height: 4),
                                      Text('10 min · steadies Vata', style: Vv.sans(12, color: Vv.onDeepMuted2)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Plan from Vaidya
                  VvTap(
                    onTap: () => widget.onGo(Tabs.vaidya),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Vv.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Vv.mintBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: Vv.mint, borderRadius: BorderRadius.circular(12)),
                            child: Text('RK', style: Vv.serif(16, color: Vv.green)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Plan from Dr. Rohan', style: Vv.sans(14, weight: FontWeight.w800)),
                                const SizedBox(height: 2),
                                Text('3 do’s · 2 avoid · follow-up in 14 days', style: Vv.sans(12, color: Vv.muted)),
                              ],
                            ),
                          ),
                          Text('View', style: Vv.sans(12, weight: FontWeight.w800, color: Vv.green)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Your path
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SerifTitle('Your ', 'path', size: 24),
                        Text('Step 3 of 5', style: Vv.sans(12, weight: FontWeight.w700, color: Vv.muted)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Path(onGo: widget.onGo),
                  const SizedBox(height: 20),
                  // Tiles
                  // Rows size to their content so narrow phones and large fonts don't overflow.
                  Column(
                    children: [
                      _tileRow(
                        _tile('01', 'Learn', 'Why Ayurveda, in 2 minutes', Vv.plum, Vv.plumPale, Tabs.learn),
                        _tile('02', 'Dosha', 'Your body type + lab scan', Vv.brown, Vv.goldPale, Tabs.dosha),
                      ),
                      const SizedBox(height: 12),
                      _tileRow(
                        _tile('04', 'Yoga', 'Sessions near you or online', Vv.rust, Vv.rustPale, Tabs.yoga),
                        _tile('05', 'Vaidya', 'Registered experts, 1 tap', Vv.green, Vv.mint, Tabs.vaidya),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Buddy banner
                  VvTap(
                    onTap: () => widget.onGo(Tabs.buddy),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Vv.blue, borderRadius: BorderRadius.circular(22)),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SerifTitle('Stuck? Ask ', 'Ayu Buddy', size: 21, color: Vv.surface),
                                const SizedBox(height: 2),
                                Text('Hindi or English · voice or chat · 24/7', style: Vv.sans(12, color: Vv.blueMuted)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(color: Vv.surface, borderRadius: BorderRadius.circular(16)),
                            child: const Icon(Icons.mic_none_rounded, color: Vv.blue, size: 22),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  // Journal
                  _journal(),
                  const SizedBox(height: 26),
                  // Shloka
                  VvCard(
                    radius: 24,
                    padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
                    child: Column(
                      children: [
                        Text('SHLOKA OF THE DAY', style: Vv.kicker(Vv.brown, spacing: 1.4)),
                        const SizedBox(height: 10),
                        Text(
                          'स्वस्थस्य स्वास्थ्य रक्षणम्',
                          textAlign: TextAlign.center,
                          style: Vv.serif(21, color: Vv.deep, height: 1.35),
                        ),
                        const SizedBox(height: 10),
                        Container(width: 40, height: 2, decoration: BoxDecoration(color: Vv.gold, borderRadius: BorderRadius.circular(2))),
                        const SizedBox(height: 10),
                        Text(
                          '“First, protect the health of the healthy.”',
                          textAlign: TextAlign.center,
                          style: Vv.serif(18, italic: true, color: Vv.ink2, height: 1.4),
                        ),
                        const SizedBox(height: 10),
                        Text.rich(
                          TextSpan(
                            style: Vv.sans(12, weight: FontWeight.w700, color: Vv.muted),
                            children: [
                              const TextSpan(text: 'Charaka Samhita · AI guides, '),
                              TextSpan(text: 'Vaidya decides', style: Vv.sans(12, weight: FontWeight.w700, color: Vv.muted).copyWith(fontStyle: FontStyle.italic)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        VvTap(
                          onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shared with family'))),
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 40),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: Vv.border3, width: 1.5),
                            ),
                            child: Text('Share with family', style: Vv.sans(13, weight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }

  static const _bleed = ValueKey('bleed');

  List<Widget> _padded(List<Widget> ws) => [
        for (final w in ws)
          w.key == _bleed ? w : Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: w),
      ];

  // Both tiles share the taller one's height, never shorter than the design's 132.
  Widget _tileRow(Widget a, Widget b) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 132),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [Expanded(child: a), const SizedBox(width: 12), Expanded(child: b)],
          ),
        ),
      );

  Widget _tile(String n, String name, String line, Color fg, Color tint, int tab) => VvTap(
        onTap: () => widget.onGo(tab),
        child: VvCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(8)),
                child: Text(n, style: Vv.sans(12, weight: FontWeight.w800, color: fg)),
              ),
              const SizedBox(height: 6),
              Text(name, style: Vv.serif(20, height: 1.15)),
              const SizedBox(height: 6),
              Text(line, style: Vv.sans(12, color: Vv.ink2, height: 1.4)),
            ],
          ),
        ),
      );

  Widget _journal() {
    final canPrev = _story > 0;
    final canNext = _story < _stories.length - 2;
    return Container(
      key: _bleed,
      padding: const EdgeInsets.fromLTRB(0, 22, 0, 6),
      decoration: const BoxDecoration(
        color: Vv.surface,
        border: Border.symmetric(horizontal: BorderSide(color: Vv.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('JOURNAL', style: Vv.kicker(Vv.muted, spacing: 1.4)),
                const SizedBox(height: 6),
                const SerifTitle('Veda ', 'Notes', size: 44, height: 1, letterSpacing: -0.6),
                const SizedBox(height: 4),
                Text('Seasonal wisdom, Vaidya explainers and our weekly letter — short reads for a calmer day.',
                    style: Vv.sans(13, color: Vv.ink2, height: 1.55)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    VvTap(
                      onTap: () => widget.onGo(Tabs.learn),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(0, 12, 0, 2),
                        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Vv.ink, width: 1.5))),
                        child: Text('EXPLORE ALL', style: Vv.kicker(Vv.ink, spacing: 0.8)),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: canPrev ? () => setState(() => _story--) : null,
                          icon: const Icon(Icons.arrow_back_rounded),
                          color: Vv.ink,
                          disabledColor: Vv.disabled,
                        ),
                        IconButton(
                          onPressed: canNext ? () => setState(() => _story++) : null,
                          icon: const Icon(Icons.arrow_forward_rounded),
                          color: Vv.ink,
                          disabledColor: Vv.disabled,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 300,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 2,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, i) {
                final st = _stories[_story + i];
                return SizedBox(
                  width: 250,
                  child: VvTap(
                    onTap: () => widget.onGo(Tabs.learn),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 220,
                          decoration: BoxDecoration(color: st.$4, borderRadius: BorderRadius.circular(4)),
                          child: Stack(
                            children: [
                              Center(child: Opacity(opacity: 0.55, child: VvLogo(size: 120, leaf: st.$5.withValues(alpha: 0.35), sides: st.$5.withValues(alpha: 0.2), sun: st.$5))),
                              Positioned(
                                left: 12,
                                top: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(color: Vv.surface, borderRadius: BorderRadius.circular(999)),
                                  child: Text(st.$1, style: Vv.sans(12, weight: FontWeight.w800, color: st.$5)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(st.$2, style: Vv.sans(12, weight: FontWeight.w600, color: Vv.muted)),
                        const SizedBox(height: 10),
                        Text(st.$3, maxLines: 2, overflow: TextOverflow.ellipsis, style: Vv.sans(16, height: 1.35)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  final double fraction;
  final String label;
  const _Ring({required this.fraction, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: const [Vv.goldLight, Vv.goldLight, Color(0x24FFFFFF), Color(0x24FFFFFF)],
          stops: [0, fraction, fraction, 1],
        ),
      ),
      child: Center(
        child: Container(
          width: 66,
          height: 66,
          decoration: const BoxDecoration(color: Vv.deep, shape: BoxShape.circle),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: Vv.serif(22, color: Vv.bg, height: 1)),
              Text('today', style: Vv.sans(12, weight: FontWeight.w700, color: Vv.onDeepMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Path extends StatelessWidget {
  final ValueChanged<int> onGo;
  const _Path({required this.onGo});

  @override
  Widget build(BuildContext context) {
    const steps = [
      ('Learn', Tabs.learn, 'done'),
      ('Dosha', Tabs.dosha, 'done'),
      ('Buddy', Tabs.buddy, 'now'),
      ('Yoga', Tabs.yoga, 'next'),
      ('Vaidya', Tabs.vaidya, 'next'),
    ];
    return LayoutBuilder(builder: (context, c) {
      final col = c.maxWidth / 5;
      return Stack(
        children: [
          Positioned(left: col / 2, right: col / 2, top: 23, child: Container(height: 2, color: Vv.border2)),
          Positioned(left: col / 2, width: col * 2, top: 23, child: Container(height: 2, color: Vv.green)),
          Row(
            children: [
              for (var i = 0; i < steps.length; i++)
                Expanded(
                  child: VvTap(
                    onTap: () => onGo(steps[i].$2),
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: steps[i].$3 == 'done'
                                ? Vv.green
                                : steps[i].$3 == 'now'
                                    ? Vv.blue
                                    : Vv.surface,
                            border: steps[i].$3 == 'next' ? Border.all(color: Vv.border2, width: 1.5) : null,
                            boxShadow: steps[i].$3 == 'now' ? const [BoxShadow(color: Vv.blueMuted, spreadRadius: 4)] : null,
                          ),
                          child: steps[i].$3 == 'done'
                              ? const Icon(Icons.check_rounded, size: 20, color: Vv.surface)
                              : Text('${i + 1}', style: Vv.serif(18, color: steps[i].$3 == 'now' ? Vv.surface : Vv.muted)),
                        ),
                        const SizedBox(height: 6),
                        Text(steps[i].$1,
                            style: Vv.sans(12, weight: FontWeight.w800, color: steps[i].$3 == 'next' ? Vv.muted : Vv.ink)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      );
    });
  }
}
