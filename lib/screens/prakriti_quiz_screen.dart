import 'package:flutter/material.dart';
import 'package:veda_verse/ml/dosha_predictor.dart';
import 'package:veda_verse/screens/prakriti_result_screen.dart';
import 'package:veda_verse/state/app_state.dart';
import 'package:veda_verse/theme/vv.dart';

/// Prakriti quiz in the design's "3 questions per page" layout, driven by the
/// on-device dosha model (30 base questions + optional 6-question tie-breaker).
class PrakritiQuizScreen extends StatefulWidget {
  const PrakritiQuizScreen({super.key});

  @override
  State<PrakritiQuizScreen> createState() => _PrakritiQuizScreenState();
}

class _PrakritiQuizScreenState extends State<PrakritiQuizScreen> {
  DoshaPredictor? _model;
  List<_Q> _qs = const [];
  int _page = 0;
  final Map<int, int> _ans = {};
  bool _warn = false;
  int? _last;
  bool _busy = false;

  // Tie-breaker round
  TieBreakerBank? _bank;
  final Map<int, int> _tbAns = {};

  static const _perPage = 3;

  static const _stories = [
    ('Your body', 'The shape of ', 'you', 'Think about most of your life, not just this week.'),
    ('Your body', 'Small ', 'details', 'The little things that stay the same over years.'),
    ('Your body', 'Finer ', 'features', 'Nails, teeth, complexion — as they usually are.'),
    ('Mind & energy', 'How you ', 'think', 'Pace, memory and how you take things in.'),
    ('Mind & energy', 'Night and ', 'day', 'Your natural rhythm of rest and energy.'),
    ('Digestion', 'When you’re ', 'hungry', 'Agni, your digestive fire, on a normal day.'),
    ('Digestion', 'Your ', 'gut', 'No wrong answers. Pick what feels most like you.'),
    ('Mind & energy', 'How you ', 'react', 'Under pressure, and in different weather.'),
    ('Your nature', 'Almost ', 'there', 'How you move, speak and spend.'),
    ('Your nature', 'Last ', 'three', 'Still about most of your life, not this week.'),
  ];

  @override
  void initState() {
    super.initState();
    DoshaPredictor.load().then((m) {
      final raw = m.questions;
      setState(() {
        _model = m;
        _qs = [for (final q in raw) _Q(q.title, q.options)];
      });
    });
  }

  int get _pages => (_qs.length / _perPage).ceil();
  bool get _inTb => _bank != null;

  Map<String, int> get _pct {
    final c = {'V': 0, 'P': 0, 'K': 0};
    for (final a in _ans.values) {
      c[['V', 'P', 'K'][a]] = c[['V', 'P', 'K'][a]]! + 1;
    }
    final t = _ans.length;
    if (t == 0) return {'v': 0, 'p': 0, 'k': 0};
    final v = (c['V']! * 100 / t).round();
    final p = (c['P']! * 100 / t).round();
    return {'v': v, 'p': p, 'k': 100 - v - p};
  }

  bool _pageDone(int page) {
    final base = page * _perPage;
    for (var i = base; i < base + _perPage && i < _qs.length; i++) {
      if (!_ans.containsKey(i)) return false;
    }
    return true;
  }

  Future<void> _finish() async {
    final m = _model;
    if (m == null || _busy) return;
    setState(() => _busy = true);
    try {
      final answers = [for (var i = 0; i < _qs.length; i++) _ans[i]!];
      DoshaPrediction p;
      if (_inTb) {
        p = m.predict(
          answers,
          tieBreakerBank: _bank,
          tieBreakerAnswers: [for (var j = 0; j < DoshaPredictor.tieBreakerQuestionsPerBank; j++) _tbAns[j]!],
        );
      } else {
        p = m.predict(answers);
        if (m.needsTieBreaker(p)) {
          setState(() {
            _bank = m.tieBreakerBankFor(p);
            _tbAns.clear();
            _warn = false;
          });
          return;
        }
      }
      AppState.instance.update((s) => s.prediction = p);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => PrakritiResultScreen(prediction: p)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _next() {
    if (_inTb) {
      if (_tbAns.length < DoshaPredictor.tieBreakerQuestionsPerBank) {
        setState(() => _warn = true);
        return;
      }
      _finish();
      return;
    }
    if (!_pageDone(_page)) {
      setState(() => _warn = true);
      return;
    }
    if (_page == _pages - 1) {
      _finish();
    } else {
      setState(() {
        _page++;
        _warn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_model == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Vv.green)));
    }
    final pct = _pct;
    final lead = _ans.isEmpty
        ? 'Answer to see'
        : '${['Vata', 'Pitta', 'Kapha'][[pct['v']!, pct['p']!, pct['k']!].indexOf([pct['v']!, pct['p']!, pct['k']!].reduce((a, b) => a > b ? a : b))]} leading';
    final isLast = _inTb || _page == _pages - 1;
    final done = _inTb ? _tbAns.length == DoshaPredictor.tieBreakerQuestionsPerBank : _pageDone(_page);

    return Scaffold(
      body: VvFrame(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        VvSquareButton(icon: Icons.close_rounded, onTap: () => Navigator.of(context).maybePop()),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Row(
                            children: [
                              for (var i = 0; i < _pages; i++) ...[
                                if (i > 0) const SizedBox(width: 4),
                                Expanded(
                                  child: VvTap(
                                    onTap: _inTb ? null : () => setState(() {
                                      _page = i;
                                      _warn = false;
                                    }),
                                    child: Container(
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: (!_inTb && i == _page) ? Vv.gold : (_pageDone(i) ? Vv.green : Vv.border2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              if (_inTb) ...[
                                const SizedBox(width: 4),
                                Expanded(child: Container(height: 8, decoration: BoxDecoration(color: Vv.gold, borderRadius: BorderRadius.circular(8)))),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: Vv.mint, borderRadius: BorderRadius.circular(999)),
                          child: Text('${_ans.length}/${_qs.length}', style: Vv.sans(13, weight: FontWeight.w800, color: Vv.green)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(color: Vv.deep, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text('YOUR NATURE SO FAR', style: Vv.sans(11, weight: FontWeight.w800, color: Vv.onDeepMuted, letterSpacing: 1)),
                              Text(lead, style: Vv.serif(15, weight: FontWeight.w700, color: Vv.bg)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              height: 10,
                              child: Row(
                                children: [
                                  _seg(pct['v']!, Vv.vataBar),
                                  _seg(pct['p']!, Vv.pittaBar),
                                  _seg(pct['k']!, Vv.kaphaBar),
                                  _seg(100 - pct['v']! - pct['p']! - pct['k']!, const Color(0x1FFFFFFF)),
                                  if (_ans.isEmpty) _seg(100, const Color(0x1FFFFFFF)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              for (final e in [('Vata', pct['v']), ('Pitta', pct['p']), ('Kapha', pct['k'])])
                                Expanded(
                                  child: Text('${e.$1} ${e.$2}%', style: Vv.sans(11, weight: FontWeight.w700, color: Vv.bg)),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: _inTb ? _tbPage() : _basePage(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 26),
                child: Row(
                  children: [
                    if (!_inTb && _page > 0) ...[
                      VvTap(
                        onTap: () => setState(() {
                          _page--;
                          _warn = false;
                        }),
                        child: Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Vv.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Vv.border3, width: 1.5),
                          ),
                          child: Text('Back', style: Vv.sans(15, weight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: VvButton(
                        label: isLast
                            ? (_busy ? 'Reading your answers…' : 'See my Prakriti')
                            : (done ? 'Next' : (_warn ? 'Answer the marked one' : 'Next')),
                        height: 56,
                        fontSize: 15,
                        weight: FontWeight.w800,
                        bg: isLast
                            ? (done ? Vv.gold : (_warn ? Vv.redPale : Vv.sage))
                            : (done ? Vv.green : (_warn ? Vv.redPale : Vv.sage)),
                        fg: isLast && done ? Vv.deep : (_warn && !done ? Vv.redInk : Vv.surface),
                        onTap: _busy ? null : _next,
                      ),
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

  Widget _seg(int w, Color c) => w <= 0 ? const SizedBox.shrink() : Expanded(flex: w, child: Container(color: c));

  Widget _basePage() {
    final st = _stories[_page % _stories.length];
    final base = _page * _perPage;
    return ListView(
      key: ValueKey('p$_page'),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      children: [
        Text('${st.$1.toUpperCase()} · PAGE ${_page + 1} OF $_pages', style: Vv.kicker(Vv.brown, spacing: 1.2)),
        const SizedBox(height: 4),
        SerifTitle(st.$2, st.$3, size: 28, bColor: Vv.green, height: 1.1),
        const SizedBox(height: 4),
        Text(st.$4, style: Vv.sans(13, color: Vv.ink2, height: 1.45)),
        const SizedBox(height: 12),
        for (var i = base; i < base + _perPage && i < _qs.length; i++) ...[
          _card(
            n: i + 1,
            text: _qs[i].title,
            options: _qs[i].options,
            picked: _ans[i],
            missing: _warn && !_ans.containsKey(i),
            pop: _last == i,
            dots: const [Vv.vataBar, Vv.goldSoft, Vv.kaphaBar],
            onPick: (k) => setState(() {
              _ans[i] = k;
              _last = i;
              _warn = false;
            }),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _tbPage() {
    final b = _bank!;
    return ListView(
      key: const ValueKey('tb'),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      children: [
        Text('TIE-BREAKER · ${b.title.toUpperCase()}', style: Vv.kicker(Vv.blue, spacing: 1.2)),
        const SizedBox(height: 4),
        SerifTitle('Two are ', 'close', size: 28, bColor: Vv.green, height: 1.1),
        const SizedBox(height: 4),
        Text('Six quick either-or questions to separate ${b.pair[0]} from ${b.pair[1]}.', style: Vv.sans(13, color: Vv.ink2, height: 1.45)),
        const SizedBox(height: 12),
        for (var j = 0; j < b.questions.length; j++) ...[
          _card(
            n: j + 1,
            text: b.questions[j].title,
            options: b.questions[j].options,
            picked: _tbAns[j],
            missing: _warn && !_tbAns.containsKey(j),
            pop: false,
            dots: const [Vv.vataBar, Vv.goldSoft],
            onPick: (k) => setState(() {
              _tbAns[j] = k;
              _warn = false;
            }),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _card({
    required int n,
    required String text,
    required List<String> options,
    required int? picked,
    required bool missing,
    required bool pop,
    required List<Color> dots,
    required ValueChanged<int> onPick,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Vv.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: missing ? Vv.red : (picked != null ? const Color(0xFFB9D0BE) : Vv.border),
          width: missing ? 2 : (picked != null ? 1.5 : 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: picked != null ? Vv.green : Vv.divider,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text('$n', style: Vv.sans(12, weight: FontWeight.w800, color: picked != null ? Vv.surface : Vv.ink2)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(text, style: Vv.sans(15, weight: FontWeight.w800, height: 1.3))),
            ],
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var k = 0; k < options.length; k++) ...[
                if (k > 0) const SizedBox(width: 8),
                Expanded(
                  child: VvTap(
                    onTap: () => onPick(k),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      constraints: const BoxConstraints(minHeight: 68),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                      decoration: BoxDecoration(
                        color: picked == k ? Vv.green : const Color(0xFFFAF6EC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: picked == k ? Vv.green : Vv.border2, width: 1.5),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(color: picked == k ? dots[k] : Vv.border3, shape: BoxShape.circle),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            options[k],
                            textAlign: TextAlign.center,
                            style: Vv.sans(13, weight: FontWeight.w700, color: picked == k ? Vv.surface : Vv.ink, height: 1.25),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Q {
  final String title;
  final List<String> options;
  const _Q(this.title, this.options);
}
