import 'package:flutter/material.dart';
import 'package:veda_verse/screens/booking_screen.dart';
import 'package:veda_verse/screens/profile_menu_screen.dart';
import 'package:veda_verse/state/app_state.dart';
import 'package:veda_verse/theme/vv.dart';

class Vaidya {
  final String init, name, meta, slot, fee;
  final Color tint;
  const Vaidya(this.init, this.name, this.meta, this.slot, this.fee, this.tint);
}

const vaidyas = [
  Vaidya('RK', 'Dr. Rohan Kapoor', 'BAMS, MD (Kayachikitsa) · Hindi, English', 'Available now', '₹399', Vv.mint),
  Vaidya('AN', 'Dr. Anjali Nair', 'BAMS · Women’s health · English, Malayalam', 'Next: Today 8:00 pm', '₹499', Vv.goldPale),
  Vaidya('SP', 'Dr. Suresh Paliwal', 'BAMS · Joints & spine · Hindi, Mewari', 'Next: Tomorrow 10:30 am', 'Free', Vv.bluePale2),
];

/// Connect with Vaidya tab.
class VaidyaScreen extends StatefulWidget {
  const VaidyaScreen({super.key});

  @override
  State<VaidyaScreen> createState() => _VaidyaScreenState();
}

class _VaidyaScreenState extends State<VaidyaScreen> {
  String _f = 'All';

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).padding.top),
        VvTabHeader(
          hello: 'Hello, ${s.firstName}',
          title: Text('Connect with Vaidya', style: Vv.serif(25, letterSpacing: -0.2)),
          initial: s.initial,
          onProfile: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileMenuScreen())),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            children: [
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: Vv.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: Vv.border2, width: 1.5)),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, size: 18, color: Vv.muted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        style: Vv.sans(14),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'Search by concern, e.g. acidity, sleep',
                          hintStyle: Vv.sans(14, color: Vv.disabled),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 5,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final l = ['All', 'Available now', 'Video', 'In clinic', 'Free'][i];
                    return VvChip(label: l, on: _f == l, onTap: () => setState(() => _f = l));
                  },
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Vv.deep, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('UPCOMING', style: Vv.sans(12, weight: FontWeight.w700, color: Vv.onDeepMuted, letterSpacing: 1)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: Vv.gold, borderRadius: BorderRadius.circular(999)),
                          child: Text('Today · 6:30 pm', style: Vv.sans(12, weight: FontWeight.w700, color: Vv.deep)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: const Color(0xFF3C6E4C), borderRadius: BorderRadius.circular(14)),
                          child: Text('MS', style: Vv.serif(16, weight: FontWeight.w700, color: Vv.bg)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Dr. Meera Sharma', style: Vv.sans(15, weight: FontWeight.w700, color: Vv.bg)),
                              const SizedBox(height: 2),
                              Text('Video consult · Digestion & sleep', style: Vv.sans(13, color: Vv.onDeepMuted3)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.check_rounded, size: 16, color: Vv.kaphaBar),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Your AI health summary is shared before the call — no repeating your history.',
                              style: Vv.sans(12, color: Vv.onDeepMuted3, height: 1.4)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    VvButton(
                      label: 'Join on Google Meet',
                      height: 48,
                      fontSize: 15,
                      weight: FontWeight.w800,
                      bg: Vv.gold,
                      fg: Vv.deep,
                      leading: Icons.videocam_outlined,
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Google Meet link opens at 6:30 pm'))),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text('Verified Vaidyas', style: Vv.serif(17, weight: FontWeight.w700)),
              const SizedBox(height: 14),
              for (final d in vaidyas) ...[
                VvCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: d.tint, borderRadius: BorderRadius.circular(16)),
                            child: Text(d.init, style: Vv.serif(17, weight: FontWeight.w700, color: Vv.deep)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(d.name, style: Vv.sans(15, weight: FontWeight.w700)),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.verified_rounded, size: 16, color: Vv.green),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(d.meta, style: Vv.sans(12, color: Vv.muted)),
                                const SizedBox(height: 3),
                                Text('Reg. No. RJ/A-2301 · NCISM-verified', style: Vv.sans(12, weight: FontWeight.w700, color: Vv.ink2)),
                                const SizedBox(height: 3),
                                Text(d.slot, style: Vv.sans(12, weight: FontWeight.w700, color: Vv.green)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _ico(Icons.chat_bubble_outline_rounded),
                          const SizedBox(width: 8),
                          _ico(Icons.phone_outlined),
                          const SizedBox(width: 8),
                          _ico(Icons.videocam_outlined),
                          const SizedBox(width: 8),
                          Expanded(
                            child: VvButton(
                              label: 'Book · ${d.fee}',
                              height: 44,
                              fontSize: 14,
                              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => BookingScreen(vaidya: d))),
                            ),
                          ),
                        ],
                      ),
                    ],
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

  Widget _ico(IconData i) => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: Vv.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Vv.border2, width: 1.5)),
        child: Icon(i, size: 18, color: Vv.ink),
      );
}
