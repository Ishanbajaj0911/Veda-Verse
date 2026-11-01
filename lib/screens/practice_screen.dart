import 'dart:async';

import 'package:flutter/material.dart';
import 'package:veda_verse/content/sessions.dart';
import 'package:veda_verse/engine/plan_engine.dart';
import 'package:veda_verse/l10n/lang.dart';
import 'package:veda_verse/state/app_state.dart';
import 'package:veda_verse/theme/vv.dart';
import 'package:veda_verse/widgets/art.dart';

/// The safety line shown with every practice.
String practiceSafety() => tr(
    'Stop if you feel pain or dizziness. If you are pregnant or have a heart or BP condition, ask a Vaidya or doctor first.');

/// A guided practice: one step at a time with a countdown. Steps come from
/// lib/content/sessions.dart ([practices]).
class PracticeScreen extends StatefulWidget {
  final String titleEn;
  const PracticeScreen({super.key, required this.titleEn});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  late final List<PracticeStep> _steps = practices[widget.titleEn] ?? const [];
  int _i = 0;
  late int _left = _steps.isEmpty ? 0 : _steps.first.seconds;
  Timer? _timer;
  bool _finished = false;
  bool _marked = false;

  bool get _running => _timer != null;
  String get _title => tr(widget.titleEn);

  /// Recorded sessions from the Yoga tab can be marked complete; the done
  /// mark is saved with the account.
  bool get _canMark => [...nearSessions, ...onlineSessions].any((s) => s.titleEn == widget.titleEn && s.ctaEn == 'Start');

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _play() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    setState(() {});
  }

  void _pause() {
    _timer?.cancel();
    _timer = null;
    setState(() {});
  }

  void _tick() {
    if (!mounted) return;
    setState(() {
      _left--;
      if (_left > 0) return;
      if (_i < _steps.length - 1) {
        _i++;
        _left = _steps[_i].seconds;
      } else {
        _left = 0;
        _finishNow();
      }
    });
  }

  void _go(int i) => setState(() {
        _i = i;
        _left = _steps[i].seconds;
      });

  void _finishNow() {
    _timer?.cancel();
    _timer = null;
    _finished = true;
  }

  void _finish() => setState(_finishNow);

  void _restart() => setState(() {
        _finished = false;
        _marked = false;
        _i = 0;
        _left = _steps.first.seconds;
      });

  void _mark() {
    AppState.instance.update((s) => s.joinedSessions.add(widget.titleEn));
    setState(() => _marked = true);
  }

  static String _clock(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: VvFrame(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    const VvBackButton(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(_title, maxLines: 2, overflow: TextOverflow.ellipsis, style: Vv.serif(21, height: 1.15)),
                    ),
                  ],
                ),
              ),
              Expanded(child: _steps.isEmpty ? const SizedBox.shrink() : (_finished ? _done() : _step())),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                child: VvNote(
                  text: practiceSafety(),
                  icon: Icons.health_and_safety_outlined,
                  color: Vv.redInk,
                  style: Vv.sans(12, color: Vv.redInk, height: 1.45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _step() {
    final st = _steps[_i];
    final last = _i == _steps.length - 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(trf('Step {n} of {total}', {'n': _i + 1, 'total': _steps.length}),
                  style: Vv.kicker(Vv.brown, size: 12)),
              const Spacer(),
              Text(trf('{n} sec', {'n': st.seconds}), style: Vv.sans(12, weight: FontWeight.w700, color: Vv.muted)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var k = 0; k < _steps.length; k++) ...[
                if (k > 0) const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: k <= _i ? Vv.green : Vv.border2,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: VvArt.themed(st.art, key: ValueKey('art-$_i')),
            ),
          ),
          const SizedBox(height: 14),
          Text(bi(st.name),
              key: const ValueKey('practice-name'),
              textAlign: TextAlign.center,
              maxLines: 2,
              style: Vv.serif(25, height: 1.15)),
          const SizedBox(height: 6),
          Text(bi(st.how), textAlign: TextAlign.center, maxLines: 3, style: Vv.sans(14.5, color: Vv.ink2, height: 1.45)),
          const SizedBox(height: 10),
          Text(_clock(_left),
              key: const ValueKey('practice-clock'),
              textAlign: TextAlign.center,
              style: Vv.serif(46, weight: FontWeight.w500, color: Vv.green, height: 1.1)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Semantics(
                button: true,
                label: tr('Previous step'),
                child: VvSquareButton(
                  key: const ValueKey('practice-prev'),
                  icon: Icons.skip_previous_rounded,
                  fg: _i == 0 ? Vv.disabled : Vv.ink,
                  onTap: _i == 0 ? null : () => _go(_i - 1),
                ),
              ),
              const SizedBox(width: 22),
              Semantics(
                button: true,
                label: _running ? tr('Pause') : tr('Play'),
                child: VvTap(
                  key: const ValueKey('practice-play'),
                  onTap: _running ? _pause : _play,
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: const BoxDecoration(color: Vv.green, shape: BoxShape.circle),
                    child: Icon(_running ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 36, color: Vv.surface),
                  ),
                ),
              ),
              const SizedBox(width: 22),
              Semantics(
                button: true,
                label: last ? tr('Finish') : tr('Next step'),
                child: VvSquareButton(
                  key: const ValueKey('practice-next'),
                  icon: last ? Icons.check_rounded : Icons.skip_next_rounded,
                  onTap: last ? _finish : () => _go(_i + 1),
                ),
              ),
            ],
          ),
          VvTap(
            key: const ValueKey('practice-finish'),
            onTap: _finish,
            child: Container(
              height: 40,
              alignment: Alignment.center,
              child: Text(tr('Finish now'), style: Vv.sans(13, weight: FontWeight.w700, color: Vv.muted)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _done() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: VvArt.themed(ArtMotif.lotus),
            ),
          ),
          const SizedBox(height: 18),
          Text(tr('Well done'), textAlign: TextAlign.center, style: Vv.serif(32, height: 1.1)),
          const SizedBox(height: 6),
          Text(trf('You finished {title}. Take a few easy breaths before you get up.', {'title': _title}),
              textAlign: TextAlign.center, style: Vv.sans(14.5, color: Vv.ink2, height: 1.45)),
          const SizedBox(height: 18),
          if (_canMark)
            _marked || AppState.instance.joinedSessions.contains(widget.titleEn)
                ? VvButton(
                    key: const ValueKey('practice-marked'),
                    label: tr('Marked complete ✓'),
                    bg: Vv.mint,
                    fg: Vv.green,
                    borderColor: Vv.mintBorder,
                  )
                : VvButton(
                    key: const ValueKey('practice-mark'),
                    label: tr('Mark as complete'),
                    leading: Icons.check_rounded,
                    onTap: _mark,
                  ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: VvButton(
                  label: tr('Do it again'),
                  leading: Icons.replay_rounded,
                  bg: Vv.surface,
                  fg: Vv.ink,
                  borderColor: Vv.border3,
                  height: 50,
                  fontSize: 15,
                  onTap: _restart,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: VvButton(
                  key: const ValueKey('practice-close'),
                  label: tr('Close'),
                  bg: Vv.surface,
                  fg: Vv.ink,
                  borderColor: Vv.border3,
                  height: 50,
                  fontSize: 15,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
