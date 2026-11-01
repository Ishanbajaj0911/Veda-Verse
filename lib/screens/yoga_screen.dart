import 'package:flutter/material.dart';
import 'package:veda_verse/app_shell.dart';
import 'package:veda_verse/engine/plan_engine.dart';
import 'package:veda_verse/l10n/lang.dart';
import 'package:veda_verse/screens/profile_menu_screen.dart';
import 'package:veda_verse/screens/session_screen.dart';
import 'package:veda_verse/state/app_state.dart';
import 'package:veda_verse/theme/vv.dart';

/// Yoga & Therapy tab. Sessions are ordered by the rule engine from the
/// quiz result and the intake answers (see plan_engine.dart). Tap a card for
/// its details; live sessions are booked or joined (saved per account),
/// recorded ones open a guided practice.
class YogaScreen extends StatefulWidget {
  const YogaScreen({super.key});

  @override
  State<YogaScreen> createState() => _YogaScreenState();
}

class _YogaScreenState extends State<YogaScreen> {
  int _mode = 0;
  String _price = 'All';

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    return ListenableBuilder(listenable: s, builder: (context, _) => _build(context, s));
  }

  /// Switches the app to the Vaidya tab, when the Yoga tab sits in the shell.
  VoidCallback? get _findVaidya {
    final shell = AppShell.of(context);
    return shell == null ? null : () => shell.go(Tabs.vaidya);
  }

  void _open(RankedSession r) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => SessionScreen(ranked: r, findVaidya: _findVaidya)));

  Widget _build(BuildContext context, AppState s) {
    final input = s.engineInput;
    var list = rankSessions(_mode == 0 ? nearSessions : onlineSessions, input);
    if (_price == 'Free') list = list.where((r) => r.session.free).toList();
    if (_price == 'Paid') list = list.where((r) => !r.session.free).toList();

    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).padding.top),
        VvTabHeader(
          hello: trf('Hello, {name}', {'name': s.firstName}),
          title: Text(tr('Yoga & Therapy'), style: Vv.serif(25, letterSpacing: -0.2)),
          initial: s.initial,
          onProfile: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileMenuScreen())),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            children: [
              VvSegments(
                labels: [tr('Near you'), tr('Online')],
                icons: const [Icons.location_on_outlined, Icons.tv_outlined],
                height: 44,
                index: _mode,
                onChanged: (i) => setState(() => _mode = i),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (final p in ['All', 'Free', 'Paid']) ...[
                    VvChip(label: tr(p), on: _price == p, hPad: 16, onTap: () => setState(() => _price = p)),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: Vv.goldPale, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome_outlined, size: 20, color: Vv.brownDark),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(rankingNote(input), style: Vv.sans(13, color: Vv.brownDark, height: 1.45)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (list.isEmpty) _empty(),
              for (final r in list) ...[
                _SessionCard(
                  key: ValueKey('session-${r.session.titleEn}'),
                  ranked: r,
                  onOpen: () => _open(r),
                  onAction: () => sessionMainAction(context, r, findVaidya: _findVaidya),
                  onCancel: () => confirmCancel(context, r.session),
                ),
                const SizedBox(height: 14),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _empty() => VvCard(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(color: Vv.mint, shape: BoxShape.circle),
              child: const Icon(Icons.self_improvement_rounded, size: 28, color: Vv.green),
            ),
            const SizedBox(height: 12),
            Text(tr('Nothing here yet'), style: Vv.serif(20)),
            const SizedBox(height: 6),
            Text(
              _price == 'Free' ? tr('No free sessions in this list right now.') : tr('No paid sessions in this list right now.'),
              textAlign: TextAlign.center,
              style: Vv.sans(13.5, color: Vv.muted, height: 1.45),
            ),
            const SizedBox(height: 14),
            VvChip(label: tr('Show all'), on: true, hPad: 18, onTap: () => setState(() => _price = 'All')),
          ],
        ),
      );
}

class _SessionCard extends StatelessWidget {
  final RankedSession ranked;
  final VoidCallback onOpen;
  final VoidCallback onAction;
  final VoidCallback onCancel;
  const _SessionCard({super.key, required this.ranked, required this.onOpen, required this.onAction, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final r = ranked;
    final s = r.session;
    final joined = isJoined(s);
    final recorded = isRecorded(s);
    return VvTap(
      onTap: onOpen,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(color: Vv.surface, border: Border.all(color: Vv.border), borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 140,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    SessionPicture(s.titleEn),
                    // Soft shade at the bottom so the badges stand off the picture.
                    const Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 56,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x00000000), Color(0x2E000000)],
                          ),
                        ),
                      ),
                    ),
                    Positioned(right: 12, top: 12, child: PriceBadge(s)),
                    if (joined) Positioned(left: 12, top: 12, child: JoinedBadge(s)),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: r.caution ? Vv.redPale : const Color(0xF5FFFDF8),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 6, offset: Offset(0, 2))],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(r.caution ? Icons.health_and_safety_outlined : Icons.auto_awesome_outlined,
                                  size: 14, color: r.caution ? Vv.redInk : Vv.brown),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(r.reason,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Vv.sans(12, weight: FontWeight.w700, color: r.caution ? Vv.redInk : Vv.ink)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.title, style: Vv.sans(16, weight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(s.where, style: Vv.sans(13, color: Vv.muted)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded, size: 16, color: Vv.ink2),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(s.time,
                              maxLines: 2, style: Vv.sans(13, weight: FontWeight.w700, color: Vv.ink2, height: 1.3)),
                        ),
                        const SizedBox(width: 10),
                        _cta(s, joined, recorded),
                      ],
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

  Widget _cta(YogaSession s, bool joined, bool recorded) {
    final r = ranked;
    final String label;
    final Color bg, fg;
    Color? border;
    IconData? icon;
    VoidCallback onTap = onAction;
    if (joined && !recorded) {
      label = joinedLabel(s);
      bg = Vv.mint;
      fg = Vv.green;
      border = Vv.mintBorder;
      onTap = onCancel;
    } else if (r.caution) {
      label = tr('Ask your Vaidya first');
      bg = Vv.surface;
      fg = Vv.redInk;
      border = Vv.redBorder;
      icon = Icons.health_and_safety_outlined;
    } else {
      label = s.cta;
      bg = Vv.green;
      fg = Vv.surface;
      icon = recorded ? Icons.play_arrow_rounded : null;
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 190),
      child: VvTap(
        key: ValueKey('session-cta-${s.titleEn}'),
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: border == null ? null : Border.all(color: border, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 17, color: fg), const SizedBox(width: 6)],
              Flexible(
                child: Text(label,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: Vv.sans(14, weight: FontWeight.w700, color: fg)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
