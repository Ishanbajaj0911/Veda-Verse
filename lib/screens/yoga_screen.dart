import 'package:flutter/material.dart';
import 'package:veda_verse/engine/plan_engine.dart';
import 'package:veda_verse/screens/profile_menu_screen.dart';
import 'package:veda_verse/state/app_state.dart';
import 'package:veda_verse/theme/vv.dart';

/// Yoga & Therapy tab. Sessions are ordered by the rule engine from the
/// quiz result and the intake answers (see plan_engine.dart).
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

  Widget _build(BuildContext context, AppState s) {
    final input = s.engineInput;
    var list = rankSessions(_mode == 0 ? nearSessions : onlineSessions, input);
    if (_price == 'Free') list = list.where((r) => r.session.free).toList();
    if (_price == 'Paid') list = list.where((r) => !r.session.free).toList();

    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).padding.top),
        VvTabHeader(
          hello: 'Hello, ${s.firstName}',
          title: Text('Yoga & Therapy', style: Vv.serif(25, letterSpacing: -0.2)),
          initial: s.initial,
          onProfile: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileMenuScreen())),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            children: [
              VvSegments(
                labels: const ['Near you', 'Online'],
                icons: const [Icons.location_on_outlined, Icons.tv_outlined],
                height: 44,
                index: _mode,
                onChanged: (i) => setState(() => _mode = i),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (final p in ['All', 'Free', 'Paid']) ...[
                    VvChip(label: p, on: _price == p, hPad: 16, onTap: () => setState(() => _price = p)),
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
              for (final r in list) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(color: Vv.surface, border: Border.all(color: Vv.border), borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          height: 112,
                          color: Color(r.session.bg),
                          child: Stack(
                            children: [
                              const Center(child: Opacity(opacity: 0.55, child: Icon(Icons.self_improvement_rounded, size: 64, color: Vv.deep))),
                              Positioned(
                                right: 12,
                                top: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(color: r.session.free ? Vv.green : Vv.deep, borderRadius: BorderRadius.circular(999)),
                                  child: Text(r.session.price, style: Vv.sans(12, weight: FontWeight.w800, color: r.session.free ? Vv.surface : Vv.goldSoft)),
                                ),
                              ),
                              Positioned(
                                left: 12,
                                bottom: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                      color: r.caution ? Vv.redPale : const Color(0xEBFFFFFF), borderRadius: BorderRadius.circular(999)),
                                  child: Text(r.reason,
                                      style: Vv.sans(12, weight: FontWeight.w700, color: r.caution ? Vv.redInk : Vv.ink)),
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
                              Text(r.session.title, style: Vv.sans(16, weight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(r.session.where, style: Vv.sans(13, color: Vv.muted)),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.schedule_rounded, size: 16, color: Vv.ink2),
                                      const SizedBox(width: 6),
                                      Text(r.session.time, style: Vv.sans(13, weight: FontWeight.w700, color: Vv.ink2)),
                                    ],
                                  ),
                                  VvTap(
                                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                        content: Text(r.caution
                                            ? 'Please check with your Vaidya before joining ${r.session.title}.'
                                            : '${r.session.cta}: ${r.session.title}'))),
                                    child: Container(
                                      height: 44,
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                          color: r.caution ? Vv.surface : Vv.green,
                                          borderRadius: BorderRadius.circular(12),
                                          border: r.caution ? Border.all(color: Vv.border3, width: 1.5) : null),
                                      child: Text(r.session.cta, style: Vv.sans(14, weight: FontWeight.w700, color: r.caution ? Vv.ink : Vv.surface)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
