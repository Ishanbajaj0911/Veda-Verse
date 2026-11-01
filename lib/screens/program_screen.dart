import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veda_verse/app_shell.dart';
import 'package:veda_verse/l10n/lang.dart';
import 'package:veda_verse/state/app_state.dart';
import 'package:veda_verse/theme/vv.dart';
import 'package:veda_verse/widgets/art.dart';

/// Short month names, shown with tr().
const monthShort = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// "3 Nov" in the current language.
String shortDate(DateTime d) => '${d.day} ${tr(monthShort[d.month - 1])}';

/// The user's own progress in the 12-week program: start day, habit ticks per
/// day, period start days and the sign check. Saved on the device per account
/// ("vv.u.ID.program"); nothing is made up. Before the user starts, it is
/// week 1 day 1 with nothing logged.
class ProgramProgress extends ChangeNotifier {
  ProgramProgress._();
  static final ProgramProgress instance = ProgramProgress._();

  static const weeks = 12;
  static const days = weeks * 7;

  /// The phases, (name, weeks).
  static const phases = [('Understand', 2), ('Reset', 4), ('Build', 4), ('Review', 2)];

  String? _loadedFor;

  /// The day the user started, or null before they start.
  DateTime? start;

  /// Habit ticks per day: yyyy-mm-dd -> habit indexes.
  Map<String, Set<int>> ticks = {};

  /// Days a period started, oldest first.
  List<DateTime> periods = [];

  /// Sign-check answers (indexes into the sign list).
  Set<int> signs = {};

  String get _account => AppState.instance.accountId;
  String get _key => _account.isEmpty ? 'vv.program' : 'vv.u.$_account.program';

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime get _today => _day(DateTime.now());

  /// Loads the logged-in account's progress (again after an account switch).
  /// Never throws; without storage the program simply starts blank.
  Future<void> ensureLoaded() async {
    final acc = _account;
    if (_loadedFor == acc) return;
    _loadedFor = acc;
    _clear();
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw != null && _loadedFor == acc) _read(jsonDecode(raw));
    } catch (e) {
      debugPrint('ProgramProgress load failed');
    }
    notifyListeners();
  }

  @visibleForTesting
  void debugReset() {
    _loadedFor = null;
    _clear();
  }

  void _clear() {
    start = null;
    ticks = {};
    periods = [];
    signs = {};
  }

  void _read(Object? j) {
    if (j is! Map) return;
    start = DateTime.tryParse('${j['start']}');
    final t = j['ticks'];
    if (t is Map) {
      ticks = {
        for (final e in t.entries)
          if (e.value is List) '${e.key}': {for (final x in e.value as List) if (x is int) x},
      };
    }
    final p = j['periods'];
    if (p is List) periods = [for (final x in p) ?DateTime.tryParse('$x')]..sort();
    final s = j['signs'];
    if (s is List) signs = {for (final x in s) if (x is int) x};
  }

  Future<void> _save() async {
    notifyListeners();
    // Keep about the last 100 days of ticks.
    final cutoff = AppState.dayKey(_today.subtract(const Duration(days: 100)));
    ticks.removeWhere((k, _) => k.compareTo(cutoff) < 0);
    try {
      await (await SharedPreferences.getInstance()).setString(
        _key,
        jsonEncode({
          'start': start == null ? null : AppState.dayKey(start!),
          'ticks': {for (final e in ticks.entries) e.key: e.value.toList()},
          'periods': [for (final d in periods) AppState.dayKey(d)],
          'signs': signs.toList(),
        }),
      );
    } catch (e) {
      debugPrint('ProgramProgress save failed');
    }
  }

  bool get started => start != null;

  /// Days since the start, 0 on the first day. 0 before the user starts.
  int get dayIndex => start == null ? 0 : _today.difference(_day(start!)).inDays.clamp(0, 1 << 20);

  bool get finished => started && dayIndex >= days;

  /// 1-12 and 1-7.
  int get week => (dayIndex.clamp(0, days - 1) ~/ 7) + 1;
  int get dayOfWeek => (dayIndex.clamp(0, days - 1) % 7) + 1;

  /// Index into [phases] for the current week.
  int get phase {
    var w = 0;
    for (var i = 0; i < phases.length; i++) {
      w += phases[i].$2;
      if (week <= w) return i;
    }
    return phases.length - 1;
  }

  /// How much of each phase is behind the user, 0..1.
  List<double> get phaseFill {
    if (!started) return List.filled(phases.length, 0);
    final done = (dayIndex + 1).clamp(0, days);
    final out = <double>[];
    var from = 0;
    for (final p in phases) {
      final len = p.$2 * 7;
      out.add(((done - from) / len).clamp(0.0, 1.0));
      from += len;
    }
    return out;
  }

  void begin() {
    start = _today;
    _save();
  }

  Set<int> get doneToday => ticks[AppState.dayKey(_today)] ?? const {};

  void toggleHabit(int i) {
    start ??= _today;
    final k = AppState.dayKey(_today);
    final set = {...?ticks[k]};
    set.contains(i) ? set.remove(i) : set.add(i);
    ticks[k] = set;
    _save();
  }

  /// Consecutive days with 3 or more habits ticked, up to today. Today only
  /// counts once it has 3; it never breaks the streak while it is still going.
  int get habitStreak {
    var d = _today;
    if ((ticks[AppState.dayKey(d)]?.length ?? 0) < 3) d = d.subtract(const Duration(days: 1));
    var n = 0;
    while ((ticks[AppState.dayKey(d)]?.length ?? 0) >= 3) {
      n++;
      d = d.subtract(const Duration(days: 1));
    }
    return n;
  }

  bool get loggedToday => periods.any((p) => _day(p) == _today);

  /// Logs (or, if already logged, un-logs) a period starting today.
  void togglePeriodToday() {
    start ??= _today;
    if (loggedToday) {
      periods.removeWhere((p) => _day(p) == _today);
    } else {
      periods = [...periods, _today]..sort();
    }
    _save();
  }

  /// (start of cycle, length in days) between logged periods, oldest first.
  List<(DateTime, int)> get cycles => [
        for (var i = 1; i < periods.length; i++) (periods[i - 1], _day(periods[i]).difference(_day(periods[i - 1])).inDays),
      ];

  int? get averageCycle {
    final c = cycles;
    if (c.isEmpty) return null;
    return (c.fold<int>(0, (a, x) => a + x.$2) / c.length).round();
  }

  void toggleSign(int i) {
    signs.contains(i) ? signs.remove(i) : signs.add(i);
    signs = {...signs};
    _save();
  }
}

/// 12-week PCOS / PCOD lifestyle program.
class ProgramScreen extends StatefulWidget {
  const ProgramScreen({super.key});

  @override
  State<ProgramScreen> createState() => _ProgramScreenState();
}

class _ProgramScreenState extends State<ProgramScreen> {
  final _p = ProgramProgress.instance;

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

  /// This week's focus for each phase: (title start, title end, text).
  static const _focus = [
    ('This week: ', 'notice your patterns', 'Tick the habits you already manage and log your period. No big changes yet, just notice.'),
    ('This week: ', 'eat on time', 'Fixed meal times and an early, light dinner help Agni (digestion) settle. One small change a day.'),
    ('This week: ', 'move every day', 'Keep meal times steady and add a daily walk or gentle yoga. Small steps, done daily.'),
    ('This week: ', 'look back', 'See what changed in your habits and cycle log, and share it with your Vaidya or doctor.'),
  ];

  @override
  void initState() {
    super.initState();
    _p.ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: VvFrame(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: _p,
            builder: (context, _) => Column(
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
                            Text(tr('LIFESTYLE PROGRAM'), style: Vv.kicker(Vv.plum)),
                            const SizedBox(height: 1),
                            SerifTitle(tr('PCOS / PCOD '), tr('care'), size: 26),
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
                      _hero(),
                      const SizedBox(height: 16),
                      _habitsCard(),
                      const SizedBox(height: 16),
                      _cycleCard(),
                      const SizedBox(height: 16),
                      _stats(),
                      const SizedBox(height: 16),
                      _signCard(),
                      const SizedBox(height: 16),
                      VvNote(text: tr('This program helps you manage and improve daily habits. It does not diagnose or cure PCOS. Only a doctor can diagnose it, with tests.')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hero() {
    final p = _p;
    final f = _focus[p.phase];
    final fill = p.phaseFill;
    return ClipRRect(
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.finished
                                ? tr('ALL 12 WEEKS DONE')
                                : trf('WEEK {w} OF 12 · DAY {d}', {'w': p.week, 'd': p.dayOfWeek}),
                            style: Vv.kicker(Vv.plumSoft),
                          ),
                          const SizedBox(height: 14),
                          !p.started
                              ? SerifTitle(tr('Ready to '), tr('begin?'), size: 30, color: Vv.plumBg, height: 1.1)
                              : SerifTitle(tr(f.$1), tr(f.$2), size: 30, color: Vv.plumBg, height: 1.1),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: SizedBox(width: 72, height: 72, child: VvArt.themed(ArtMotif.lotus)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  !p.started
                      ? tr('Twelve weeks of small daily habits. We count the weeks from the day you start.')
                      : tr(f.$3),
                  style: Vv.sans(14, color: Vv.plumSofter, height: 1.5),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    for (var i = 0; i < ProgramProgress.phases.length; i++) ...[
                      if (i > 0) const SizedBox(width: 4),
                      _phase(ProgramProgress.phases[i].$2, fill[i]),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    for (var i = 0; i < ProgramProgress.phases.length; i++)
                      Expanded(
                        flex: ProgramProgress.phases[i].$2,
                        child: Text(
                          tr(ProgramProgress.phases[i].$1),
                          softWrap: false,
                          overflow: TextOverflow.visible,
                          style: Vv.sans(10.5,
                              weight: i == p.phase && p.started ? FontWeight.w900 : FontWeight.w700,
                              color: i == p.phase && p.started ? Vv.plumBg : Vv.plumSoft),
                        ),
                      ),
                  ],
                ),
                if (!p.started || p.finished) ...[
                  const SizedBox(height: 16),
                  VvButton(
                    label: p.finished ? tr('Start again') : tr('Start the program'),
                    height: 48,
                    fontSize: 14,
                    weight: FontWeight.w800,
                    bg: Vv.plumBg,
                    fg: Vv.plum,
                    onTap: _p.begin,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _habitsCard() {
    final done = _p.doneToday;
    return VvCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(child: SerifTitle(tr('This week’s '), tr('habits'), size: 20)),
              Text(trf('{n}/5 today', {'n': done.length}), style: Vv.sans(13, weight: FontWeight.w800, color: Vv.plum)),
            ],
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < _habits.length; i++)
            VvTap(
              onTap: () => _p.toggleHabit(i),
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
                        color: done.contains(i) ? Vv.plum : Vv.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: done.contains(i) ? Vv.plum : Vv.border3, width: 2),
                      ),
                      child: done.contains(i) ? const Icon(Icons.check_rounded, size: 16, color: Vv.surface) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tr(_habits[i].$1), style: Vv.sans(14, weight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(tr(_habits[i].$2), style: Vv.sans(12, color: Vv.muted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _cycleCard() {
    final p = _p;
    final cycles = p.cycles;
    final avg = p.averageCycle;
    final String note;
    if (p.periods.isEmpty) {
      note = tr('Nothing logged yet. Tap the button below on the day your period starts.');
    } else if (cycles.isEmpty) {
      note = trf('Last period: {date}. Log the next one to see your cycle length.', {'date': shortDate(p.periods.last)});
    } else if (cycles.any((c) => c.$2 > 35)) {
      note = trf('Your average is {n} days, and some cycles were longer than 35 days. Worth showing to your Vaidya or doctor.', {'n': avg});
    } else {
      note = trf('Your average is {n} days. Keep logging; your Vaidya or doctor can review this with you.', {'n': avg});
    }
    return VvCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(child: SerifTitle(tr('Your cycle '), tr('log'), size: 20)),
              Text(tr('Days between periods'), style: Vv.sans(12, weight: FontWeight.w700, color: Vv.muted)),
            ],
          ),
          const SizedBox(height: 10),
          if (cycles.isEmpty)
            Container(
              height: 96,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: Vv.plumPale, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  const Icon(Icons.water_drop_outlined, color: Vv.plum, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(tr('Your chart appears after two logged periods.'),
                        style: Vv.sans(13, weight: FontWeight.w700, color: Vv.plumInk, height: 1.4)),
                  ),
                ],
              ),
            )
          else
            _chart(cycles.length > 6 ? cycles.sublist(cycles.length - 6) : cycles),
          const SizedBox(height: 10),
          Text(note, style: Vv.sans(13, color: Vv.ink2, height: 1.5)),
          const SizedBox(height: 10),
          VvTap(
            onTap: p.togglePeriodToday,
            child: Container(
              constraints: const BoxConstraints(minHeight: 46),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Vv.plumPale,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Vv.plumBorder, width: 1.5),
              ),
              child: Text(
                p.loggedToday ? tr('Logged today ✓ · tap to undo') : tr('Log period started today'),
                textAlign: TextAlign.center,
                style: Vv.sans(14, weight: FontWeight.w800, color: Vv.plum),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stats() {
    final p = _p;
    final avg = p.averageCycle;
    Widget row(Widget a, Widget b) => IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [Expanded(child: a), const SizedBox(width: 12), Expanded(child: b)],
          ),
        );
    return Column(
      children: [
        row(
          _stat(
            tr('Program day'),
            p.started ? '${(p.dayIndex + 1).clamp(1, ProgramProgress.days)} / ${ProgramProgress.days}' : '—',
            p.started ? trf('Week {w} of 12', {'w': p.week}) : tr('Not started yet'),
          ),
          _stat(
            tr('Habit streak'),
            trf('{n} days', {'n': p.habitStreak}),
            tr('Days with 3 or more habits'),
          ),
        ),
        const SizedBox(height: 12),
        row(
          _stat(
            tr('Periods logged'),
            '${p.periods.length}',
            p.periods.isEmpty ? tr('None yet') : trf('Last: {date}', {'date': shortDate(p.periods.last)}),
          ),
          _stat(
            tr('Average cycle'),
            avg == null ? '—' : trf('{n} days', {'n': avg}),
            avg == null ? tr('Needs two period logs') : tr('Typical: 21–35 days'),
          ),
        ),
      ],
    );
  }

  Widget _signCard() {
    final signs = _p.signs;
    final n = signs.length;
    final many = n >= 2;
    return VvCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(TextSpan(children: [
            TextSpan(text: tr('Sign '), style: Vv.serif(20)),
            TextSpan(text: tr('check'), style: Vv.serif(20, italic: true)),
            TextSpan(text: tr(' · tap what applies'), style: Vv.sans(12, weight: FontWeight.w600, color: Vv.muted)),
          ])),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _signList.length; i++)
                VvChip(
                  label: tr(_signList[i]),
                  on: signs.contains(i),
                  onColor: Vv.plum,
                  radius: 12,
                  hPad: 12,
                  onTap: () => _p.toggleSign(i),
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
                  many ? trf('{n} signs are worth checking', {'n': n}) : (n == 1 ? tr('1 sign noted') : tr('No signs selected')),
                  style: Vv.sans(14, weight: FontWeight.w800, color: many ? Vv.amberInk : Vv.green),
                ),
                const SizedBox(height: 4),
                Text(
                  many
                      ? tr('Ask a gynaecologist about an ultrasound and hormone tests. Only a doctor can diagnose PCOS, usually when 2 of 3 criteria are met.')
                      : n == 1
                          ? tr('Keep following your weekly habits. We will ask again in 4 weeks.')
                          : tr('Tap any sign above that applies to you. Your answers stay on this phone.'),
                  style: Vv.sans(13, color: many ? Vv.amberInk : Vv.green, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          VvButton(
            label: tr('Talk to a Vaidya or doctor'),
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

  Widget _chart(List<(DateTime, int)> cycles) {
    // 130px column: 21 days = 14px, 50 days = 120px; band 21–35 spans 14–65px.
    // Bars are capped so very short or long cycles still fit; the number is exact.
    double h(int v) => 14 + (v.clamp(18, 46) - 21) * (106 / 29);
    return Padding(
      padding: const EdgeInsets.only(left: 26),
      child: SizedBox(
        height: 150,
        child: Stack(
          children: [
            Positioned(left: 0, right: 0, top: 65, child: Container(height: 51, decoration: BoxDecoration(color: Vv.mint, borderRadius: BorderRadius.circular(6)))),
            Positioned(right: 6, top: 69, child: Text(tr('typical 21–35 days'), style: Vv.sans(10, weight: FontWeight.w800, color: Vv.green))),
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
                    for (var i = 0; i < 6; i++) ...[
                      if (i > 0) const SizedBox(width: 14),
                      Expanded(
                        child: i >= cycles.length
                            ? const SizedBox()
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('${cycles[i].$2}', style: Vv.sans(11, weight: FontWeight.w800)),
                                  const SizedBox(height: 3),
                                  Container(
                                    height: h(cycles[i].$2),
                                    decoration: BoxDecoration(
                                      color: cycles[i].$2 > 35 ? Vv.plumBar : Vv.plum,
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
                    for (var i = 0; i < 6; i++) ...[
                      if (i > 0) const SizedBox(width: 14),
                      Expanded(
                        child: Text(i >= cycles.length ? '' : tr(monthShort[cycles[i].$1.month - 1]),
                            textAlign: TextAlign.center, style: Vv.sans(10, color: Vv.muted)),
                      ),
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
