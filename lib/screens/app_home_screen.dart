import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:veda_verse/app_shell.dart';
import 'package:veda_verse/engine/plan_engine.dart';
import 'package:veda_verse/l10n/lang.dart';
import 'package:veda_verse/screens/prakriti_quiz_screen.dart';
import 'package:veda_verse/screens/profile_menu_screen.dart';
import 'package:veda_verse/screens/program_screen.dart' show shortDate;
import 'package:veda_verse/screens/vaidya_screen.dart';
import 'package:veda_verse/state/app_state.dart';
import 'package:veda_verse/theme/vv.dart';
import 'package:veda_verse/widgets/art.dart';

/// Home tab (design page "Home"). Everything personal on it comes from the
/// account: the streak, today's plan, the next step and the user's path.
class AppHomeScreen extends StatefulWidget {
  final ValueChanged<int> onGo;
  const AppHomeScreen({super.key, required this.onGo});

  @override
  State<AppHomeScreen> createState() => _AppHomeScreenState();
}

class _AppHomeScreenState extends State<AppHomeScreen> {
  int _story = 0;

  static const _shloka = 'स्वस्थस्य स्वास्थ्य रक्षणम्';

  void _openQuiz() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrakritiQuizScreen()));

  /// Journal cards: (kicker, length, title, picture). The first one follows
  /// the current Ritu.
  List<(String, String, String, ArtMotif)> _stories(DateTime now) => [
        (
          tr('Ritucharya'),
          tr('4 min read'),
          trf('{ritu}: how to eat and live this season', {'ritu': rituFor(now).split(' (').first}),
          ArtMotif.leaf,
        ),
        (tr('Video'), tr('6 min watch'), tr('Anulom Vilom, explained step by step by a Vaidya'), ArtMotif.breath),
        (tr('Newsletter'), tr('3 min read'), tr('Veda Letter #12: sleep, screens and a restless Vata mind'), ArtMotif.moon),
        (tr('Journal'), tr('5 min read'), tr('Agni, simply: the digestive fire behind your energy'), ArtMotif.flame),
      ];

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    final now = DateTime.now();
    final ritu = rituFor(now).split(' (').first;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        final plan = dailyPlan(s.engineInput);
        final done = plan.where((p) => s.doneToday.contains(p.item.id)).length;
        final next = plan.where((p) => !s.doneToday.contains(p.item.id)).firstOrNull;
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
                        SerifTitle(tr('Namaste, '), s.firstName.isEmpty ? tr('friend') : s.firstName, size: 36, height: 1.05),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Streak + today's plan: opens the Dosha tab, where the plan is ticked.
                  VvTap(
                    key: const ValueKey('home-today'),
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
                                _Ring(fraction: plan.isEmpty ? 0 : done / plan.length, label: '$done/${plan.length}'),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.streak > 0 ? trf('{n}-DAY STREAK', {'n': s.streak}) : tr('START YOUR STREAK TODAY'),
                                        style: Vv.kicker(Vv.goldLight),
                                      ),
                                      const SizedBox(height: 4),
                                      next == null
                                          ? SerifTitle(tr('All done '), tr('for today'), size: 21, color: Vv.bg, height: 1.15)
                                          : SerifTitle(tr('Next: '), next.item.title, size: 21, color: Vv.bg, height: 1.15),
                                      const SizedBox(height: 4),
                                      Text(next == null ? tr('Come back tomorrow for a fresh plan') : '${next.item.time} · ${next.reason}',
                                          style: Vv.sans(12, color: Vv.onDeepMuted2)),
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
                  _nextStep(s),
                  const SizedBox(height: 20),
                  // Your path: real progress through the app.
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(child: SerifTitle(tr('Your '), tr('path'), size: 24)),
                        Text(trf('{n} of 5 done', {'n': _pathSteps(s).where((x) => x.$2).length}),
                            style: Vv.sans(12, weight: FontWeight.w700, color: Vv.muted)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Path(steps: _pathSteps(s)),
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
                        _tile('03', 'Yoga', 'Sessions near you or online', Vv.rust, Vv.rustPale, Tabs.yoga),
                        _tile('04', 'Vaidya', 'Registered experts, 1 tap', Vv.green, Vv.mint, Tabs.vaidya),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Buddy banner
                  VvTap(
                    key: const ValueKey('home-buddy'),
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
                                SerifTitle(tr('Stuck? Ask '), 'Ayu Buddy', size: 21, color: Vv.surface),
                                const SizedBox(height: 2),
                                Text(tr('Hindi or English · voice or chat · 24/7'), style: Vv.sans(12, color: Vv.blueMuted)),
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
                  _journal(now),
                  const SizedBox(height: 26),
                  // Shloka
                  VvCard(
                    radius: 24,
                    padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
                    child: Column(
                      children: [
                        Text(tr('SHLOKA OF THE DAY'), style: Vv.kicker(Vv.brown, spacing: 1.4)),
                        const SizedBox(height: 10),
                        Text(
                          _shloka,
                          textAlign: TextAlign.center,
                          style: Vv.serif(21, color: Vv.deep, height: 1.35),
                        ),
                        const SizedBox(height: 10),
                        Container(width: 40, height: 2, decoration: BoxDecoration(color: Vv.gold, borderRadius: BorderRadius.circular(2))),
                        const SizedBox(height: 10),
                        Text(
                          tr('“First, protect the health of the healthy.”'),
                          textAlign: TextAlign.center,
                          style: Vv.serif(18, italic: true, color: Vv.ink2, height: 1.4),
                        ),
                        const SizedBox(height: 10),
                        Text.rich(
                          TextSpan(
                            style: Vv.sans(12, weight: FontWeight.w700, color: Vv.muted),
                            children: [
                              TextSpan(text: tr('Charaka Samhita · AI guides, ')),
                              TextSpan(text: tr('Vaidya decides'), style: Vv.sans(12, weight: FontWeight.w700, color: Vv.muted).copyWith(fontStyle: FontStyle.italic)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        VvTap(
                          key: const ValueKey('home-share'),
                          onTap: _shareShloka,
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 44),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: Vv.border3, width: 1.5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.copy_rounded, size: 16, color: Vv.ink),
                                const SizedBox(width: 8),
                                Flexible(child: Text(tr('Copy to share with family'), style: Vv.sans(13, weight: FontWeight.w700))),
                              ],
                            ),
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

  /// Copies the shloka and its meaning, ready to paste into WhatsApp or SMS.
  Future<void> _shareShloka() async {
    final text = '$_shloka\n${tr('“First, protect the health of the healthy.”')}\n— ${tr('Charaka Samhita')} · VedaVerse';
    final messenger = ScaffoldMessenger.of(context);
    try {
      await Clipboard.setData(ClipboardData(text: text));
      messenger.showSnackBar(SnackBar(content: Text(tr('Copied. Paste it in WhatsApp or a message to share with family.'))));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(tr('Could not copy on this device.'))));
    }
  }

  /// The five steps of the path: (label, done, open). Each is done only when
  /// the account really did it.
  List<(String, bool, VoidCallback)> _pathSteps(AppState s) => [
        ('Quiz', s.hasPrakriti, s.hasPrakriti ? () => widget.onGo(Tabs.dosha) : _openQuiz),
        ('Plan', s.doneToday.isNotEmpty, () => widget.onGo(Tabs.dosha)),
        ('Learn', s.savedArticles.isNotEmpty, () => widget.onGo(Tabs.learn)),
        ('Yoga', s.joinedSessions.isNotEmpty, () => widget.onGo(Tabs.yoga)),
        ('Vaidya', s.bookings.isNotEmpty, () => widget.onGo(Tabs.vaidya)),
      ];

  /// One card with the most useful next step: the upcoming consult, else the
  /// quiz, else a follow-up or a first consult.
  Widget _nextStep(AppState s) {
    final up = s.upcoming;
    final past = s.bookings.isEmpty ? null : s.bookings.last;
    final Widget badge;
    final String title, sub, cta;
    final VoidCallback onTap;
    if (up.isNotEmpty) {
      final b = up.first;
      badge = Text(_initials(b.vaidya), style: Vv.serif(16, color: Vv.green));
      title = trf('Consult with {name}', {'name': b.vaidya});
      sub = '${_when(b.when)} · ${_mode(b.mode)}';
      cta = tr('View');
      onTap = () => widget.onGo(Tabs.vaidya);
    } else if (!s.hasPrakriti) {
      badge = const Icon(Icons.quiz_outlined, color: Vv.green, size: 22);
      title = tr('Find your Prakriti');
      sub = tr('24 questions · 4 min · then a plan that fits you');
      cta = tr('Start');
      onTap = _openQuiz;
    } else if (past != null) {
      badge = Text(_initials(past.vaidya), style: Vv.serif(16, color: Vv.green));
      title = trf('Consult with {name}', {'name': past.vaidya});
      sub = trf('Done on {date} · book a follow-up', {'date': shortDate(past.when)});
      cta = tr('Book');
      onTap = () => widget.onGo(Tabs.vaidya);
    } else {
      badge = const Icon(Icons.medical_services_outlined, color: Vv.green, size: 22);
      title = tr('Talk to a Vaidya');
      sub = tr('A registered Vaidya can confirm your Prakriti and plan');
      cta = tr('Book');
      onTap = () => widget.onGo(Tabs.vaidya);
    }
    return VvTap(
      key: const ValueKey('home-next'),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
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
              child: badge,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Vv.sans(14, weight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(sub, style: Vv.sans(12, color: Vv.muted)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              constraints: const BoxConstraints(minHeight: 36),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Vv.mint, borderRadius: BorderRadius.circular(999)),
              child: Text(cta, style: Vv.sans(12, weight: FontWeight.w800, color: Vv.green)),
            ),
          ],
        ),
      ),
    );
  }

  static String _initials(String vaidya) {
    final known = vaidyas.where((v) => v.name == vaidya).firstOrNull;
    if (known != null) return known.init;
    final words = vaidya.split(' ').where((w) => w.isNotEmpty && w != 'Dr.').toList();
    return words.take(2).map((w) => w[0].toUpperCase()).join();
  }

  static String _mode(String mode) => switch (mode) {
        'Video' => tr('Video'),
        'In clinic' => tr('In clinic'),
        'Phone' => tr('Phone call'),
        _ => mode,
      };

  /// "Today, 8:00 pm" / "आज, शाम 8:00" / "3 Nov, 10:30 am".
  static String _when(DateTime d) {
    final now = DateTime.now();
    final days = DateTime(d.year, d.month, d.day).difference(DateTime(now.year, now.month, now.day)).inDays;
    final date = days == 0 ? tr('Today') : (days == 1 ? tr('Tomorrow') : shortDate(d));
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final t = '$h:${d.minute.toString().padLeft(2, '0')}';
    if (!Lang.hi) return '$date, $t ${d.hour < 12 ? 'am' : 'pm'}';
    final part = d.hour < 12 ? tr('morning') : (d.hour < 16 ? tr('afternoon') : (d.hour < 20 ? tr('evening') : tr('night')));
    return '$date, $part $t';
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
        key: ValueKey('home-tile-$name'),
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
              Text(tr(name), style: Vv.serif(20, height: 1.15)),
              const SizedBox(height: 6),
              Text(tr(line), style: Vv.sans(12, color: Vv.ink2, height: 1.4)),
            ],
          ),
        ),
      );

  Widget _journal(DateTime now) {
    final stories = _stories(now);
    final canPrev = _story > 0;
    final canNext = _story < stories.length - 2;
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
                Text(tr('JOURNAL'), style: Vv.kicker(Vv.muted, spacing: 1.4)),
                const SizedBox(height: 6),
                SerifTitle('Veda ', tr('Notes'), size: 44, height: 1, letterSpacing: -0.6),
                const SizedBox(height: 4),
                Text(tr('Seasonal wisdom, Vaidya explainers and our weekly letter — short reads for a calmer day.'),
                    style: Vv.sans(13, color: Vv.ink2, height: 1.55)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    VvTap(
                      key: const ValueKey('home-explore'),
                      onTap: () => widget.onGo(Tabs.learn),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 44),
                        alignment: Alignment.bottomLeft,
                        padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
                        child: Container(
                          padding: const EdgeInsets.only(bottom: 2),
                          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Vv.ink, width: 1.5))),
                          child: Text(tr('EXPLORE ALL'), style: Vv.kicker(Vv.ink, spacing: 0.8)),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          key: const ValueKey('home-story-prev'),
                          tooltip: tr('Previous'),
                          onPressed: canPrev ? () => setState(() => _story--) : null,
                          icon: const Icon(Icons.arrow_back_rounded),
                          color: Vv.ink,
                          disabledColor: Vv.disabled,
                        ),
                        IconButton(
                          key: const ValueKey('home-story-next'),
                          tooltip: tr('Next'),
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
            height: 315,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 2,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, i) {
                final st = stories[_story + i];
                return SizedBox(
                  width: 250,
                  child: VvTap(
                    key: ValueKey('home-story-$i'),
                    onTap: () => widget.onGo(Tabs.learn),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            height: 220,
                            child: Stack(
                              children: [
                                Positioned.fill(child: VvArt.themed(st.$4)),
                                Positioned(
                                  left: 12,
                                  top: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(color: Vv.surface, borderRadius: BorderRadius.circular(999)),
                                    child: Text(st.$1, style: Vv.sans(12, weight: FontWeight.w800, color: Vv.ink)),
                                  ),
                                ),
                              ],
                            ),
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
              Text(tr('today'), style: Vv.sans(12, weight: FontWeight.w700, color: Vv.onDeepMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Five steps: done ones are ticked, the first open one is "now".
class _Path extends StatelessWidget {
  final List<(String, bool, VoidCallback)> steps;
  const _Path({required this.steps});

  @override
  Widget build(BuildContext context) {
    final now = steps.indexWhere((x) => !x.$2);
    final reach = now < 0 ? steps.length - 1 : now;
    return LayoutBuilder(builder: (context, c) {
      final col = c.maxWidth / steps.length;
      return Stack(
        children: [
          Positioned(left: col / 2, right: col / 2, top: 23, child: Container(height: 2, color: Vv.border2)),
          Positioned(left: col / 2, width: col * reach, top: 23, child: Container(height: 2, color: Vv.green)),
          Row(
            children: [
              for (var i = 0; i < steps.length; i++)
                Expanded(
                  child: VvTap(
                    key: ValueKey('home-path-${steps[i].$1}'),
                    onTap: steps[i].$3,
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: steps[i].$2
                                ? Vv.green
                                : i == now
                                    ? Vv.blue
                                    : Vv.surface,
                            border: !steps[i].$2 && i != now ? Border.all(color: Vv.border2, width: 1.5) : null,
                            boxShadow: i == now ? const [BoxShadow(color: Vv.blueMuted, spreadRadius: 4)] : null,
                          ),
                          child: steps[i].$2
                              ? const Icon(Icons.check_rounded, size: 20, color: Vv.surface)
                              : Text('${i + 1}', style: Vv.serif(18, color: i == now ? Vv.surface : Vv.muted)),
                        ),
                        const SizedBox(height: 6),
                        Text(tr(steps[i].$1),
                            textAlign: TextAlign.center,
                            style: Vv.sans(12, weight: FontWeight.w800, color: !steps[i].$2 && i != now ? Vv.muted : Vv.ink)),
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
