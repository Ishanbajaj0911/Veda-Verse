import 'package:flutter/material.dart';
import 'package:veda_verse/screens/profile_menu_screen.dart';
import 'package:veda_verse/state/app_state.dart';
import 'package:veda_verse/theme/vv.dart';

class _Session {
  final String title, where, time, price, match, cta;
  final Color bg;
  const _Session(this.title, this.where, this.time, this.price, this.match, this.bg, this.cta);
  bool get free => price == 'Free';
}

/// Yoga & Therapy tab.
class YogaScreen extends StatefulWidget {
  const YogaScreen({super.key});

  @override
  State<YogaScreen> createState() => _YogaScreenState();
}

class _YogaScreenState extends State<YogaScreen> {
  int _mode = 0;
  String _price = 'All';

  static const _near = [
    _Session('Sunrise Hatha by the lake', 'Fateh Sagar Pal · 1.2 km', 'Sun · 6:00 am', 'Free', 'Great for Vata', Vv.mint, 'Join'),
    _Session('Gentle spine & back therapy', 'Shanti Wellness, Hiran Magri · 3.4 km', 'Tue, Thu · 7:30 am', '₹499', 'For back pain', Vv.goldPale, 'Book'),
    _Session('Shirodhara session', 'Ayur Kendra, Sector 4 · 4.1 km', 'By appointment', '₹1,200', 'Calms Pitta', Vv.bluePale2, 'Book'),
  ];
  static const _online = [
    _Session('Yoga Nidra for deep sleep', 'Live on VedaVerse · Hindi', 'Daily · 9:30 pm', 'Free', 'For poor sleep', Vv.bluePale2, 'Join'),
    _Session('Pranayama for acidity', 'Live on VedaVerse · English', 'Mon–Fri · 7:00 am', '₹299/mo', 'Cools Pitta', Vv.goldPale, 'Book'),
    _Session('Desk-break stretches', 'Recorded · 12 min', 'Anytime', 'Free', 'Great for Vata', Vv.mint, 'Start'),
  ];

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    var list = _mode == 0 ? _near : _online;
    if (_price == 'Free') list = list.where((x) => x.free).toList();
    if (_price == 'Paid') list = list.where((x) => !x.free).toList();

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
                      child: Text.rich(TextSpan(
                        style: Vv.sans(13, color: Vv.brownDark, height: 1.45),
                        children: [
                          const TextSpan(text: 'Ranked for '),
                          TextSpan(text: s.prakritiLabel.replaceAll(' dominant', ''), style: Vv.sans(13, weight: FontWeight.w800, color: Vv.brownDark)),
                          const TextSpan(text: ' and your back pain — grounding, cooling, gentle on the spine.'),
                        ],
                      )),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              for (final x in list) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(color: Vv.surface, border: Border.all(color: Vv.border), borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          height: 112,
                          color: x.bg,
                          child: Stack(
                            children: [
                              const Center(child: Opacity(opacity: 0.55, child: Icon(Icons.self_improvement_rounded, size: 64, color: Vv.deep))),
                              Positioned(
                                right: 12,
                                top: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(color: x.free ? Vv.green : Vv.deep, borderRadius: BorderRadius.circular(999)),
                                  child: Text(x.price, style: Vv.sans(12, weight: FontWeight.w800, color: x.free ? Vv.surface : Vv.goldSoft)),
                                ),
                              ),
                              Positioned(
                                left: 12,
                                bottom: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(color: const Color(0xEBFFFFFF), borderRadius: BorderRadius.circular(999)),
                                  child: Text(x.match, style: Vv.sans(12, weight: FontWeight.w700)),
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
                              Text(x.title, style: Vv.sans(16, weight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(x.where, style: Vv.sans(13, color: Vv.muted)),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.schedule_rounded, size: 16, color: Vv.ink2),
                                      const SizedBox(width: 6),
                                      Text(x.time, style: Vv.sans(13, weight: FontWeight.w700, color: Vv.ink2)),
                                    ],
                                  ),
                                  VvTap(
                                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${x.cta}: ${x.title}'))),
                                    child: Container(
                                      height: 44,
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(color: Vv.green, borderRadius: BorderRadius.circular(12)),
                                      child: Text(x.cta, style: Vv.sans(14, weight: FontWeight.w700, color: Vv.surface)),
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
