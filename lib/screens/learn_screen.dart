import 'package:flutter/material.dart';
import 'package:veda_verse/screens/profile_menu_screen.dart';
import 'package:veda_verse/state/app_state.dart';
import 'package:veda_verse/theme/vv.dart';

/// Learn / Awareness tab.
class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  String _cat = 'For you';
  final _email = TextEditingController();

  static const _all = [
    ('Journal', 'Gut, sleep and stress: what Ayurveda calls Agni', 'Research summary · 5 min read', Vv.mint),
    ('Video', 'Anulom Vilom, step by step', 'Guided practice · 8 min', Vv.bluePale2),
    ('News', 'AYUSH wellness centres expand across Rajasthan', 'Health news · 3 min read', Vv.goldPale),
    ('Journal', 'Why one diet doesn’t fit every Prakriti', 'Explainer · 4 min read', Vv.mint),
    ('Video', 'Myths about herbs you should stop believing', 'Vaidya talk · 7 min', Vv.bluePale2),
  ];

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    const map = {'Journals': 'Journal', 'News': 'News', 'Videos': 'Video'};
    final list = map[_cat] == null ? _all : _all.where((x) => x.$1 == map[_cat]).toList();
    final heading = (_cat == 'For you' || _cat == 'Newsletter') ? 'Picked for you' : _cat;

    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).padding.top),
        VvTabHeader(
          hello: 'Hello, ${s.firstName}',
          title: Text('Awareness', style: Vv.serif(25, letterSpacing: -0.2)),
          initial: s.initial,
          onProfile: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileMenuScreen())),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            children: [
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 5,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final l = ['For you', 'Journals', 'News', 'Videos', 'Newsletter'][i];
                    return VvChip(label: l, on: _cat == l, onTap: () => setState(() => _cat = l));
                  },
                ),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 200),
                  color: Vv.deep,
                  padding: const EdgeInsets.all(18),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const VvRings(right: -50, top: 60, opacity: 0.18),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: Vv.gold, borderRadius: BorderRadius.circular(999)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.play_arrow_rounded, size: 14, color: Vv.deep),
                                const SizedBox(width: 4),
                                Text('Video · 6 min', style: Vv.sans(12, weight: FontWeight.w800, color: Vv.deep)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text('Ritucharya: how to eat as Rajasthan moves into winter',
                              style: Vv.serif(25, color: Vv.bg, height: 1.2, letterSpacing: -0.2)),
                          const SizedBox(height: 12),
                          Text('Seasonal routine explained by a Vaidya, in Hindi with English captions.',
                              style: Vv.sans(13, color: Vv.onDeepMuted3, height: 1.45)),
                          const SizedBox(height: 16),
                          VvTap(
                            onTap: () {},
                            child: Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(horizontal: 18),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: Vv.bg, borderRadius: BorderRadius.circular(12)),
                              child: Text('Watch now', style: Vv.sans(14, weight: FontWeight.w700, color: Vv.deep)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(heading, style: Vv.serif(17, weight: FontWeight.w700)),
              const SizedBox(height: 14),
              for (final it in list) ...[
                VvCard(
                  padding: const EdgeInsets.all(12),
                  radius: 18,
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(color: it.$4, borderRadius: BorderRadius.circular(14)),
                        child: Icon(it.$1 == 'Video' ? Icons.play_arrow_rounded : Icons.description_outlined, color: Vv.deep, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(it.$1.toUpperCase(), style: Vv.kicker(Vv.brown, size: 11, spacing: 0.8)),
                            const SizedBox(height: 4),
                            Text(it.$2, style: Vv.sans(14, weight: FontWeight.w700, height: 1.35)),
                            const SizedBox(height: 4),
                            Text(it.$3, style: Vv.sans(12, color: Vv.muted)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.bookmark_border_rounded, size: 18, color: Vv.muted),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Vv.goldPale, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Weekly Veda letter', style: Vv.serif(16, weight: FontWeight.w700, color: Vv.brownDeep)),
                    const SizedBox(height: 10),
                    Text('One seasonal tip, one recipe, one practice — every Sunday.', style: Vv.sans(13, color: Vv.brownDark, height: 1.45)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 46,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              color: Vv.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE9C18A), width: 1.5),
                            ),
                            child: TextField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              style: Vv.sans(14),
                              decoration: InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: 'you@example.com',
                                hintStyle: Vv.sans(14, color: Vv.disabled),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        VvTap(
                          onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subscribed to the Veda letter'))),
                          child: Container(
                            height: 46,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: Vv.deep, borderRadius: BorderRadius.circular(12)),
                            child: Text('Subscribe', style: Vv.sans(14, weight: FontWeight.w700, color: Vv.surface)),
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
      ],
    );
  }
}
