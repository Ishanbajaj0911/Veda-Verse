import 'package:flutter/material.dart';
import 'package:veda_verse/l10n/lang.dart';
import 'package:veda_verse/theme/vv.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  int _tab = 0;

  static const _free = ['Prakriti quiz & daily Dinacharya', 'Ayu Buddy chat (guardrailed)', '2 lab-report scans a month', 'Free community yoga sessions'];
  static const _premium = ['Unlimited lab-report scans', 'Ayu Buddy voice in Hindi & English', 'Priority Vaidya slots', 'Monthly progress review', 'Premium yoga & therapy content'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: VvFrame(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Row(
                  children: [
                    const VvBackButton(),
                    const SizedBox(width: 12),
                    SerifTitle(tr('My '), tr('plans'), size: 25),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  children: [
                    VvSegments(labels: [tr('Monthly'), tr('Yearly · save 2 months')], index: _tab, onChanged: (i) => setState(() => _tab = i)),
                    const SizedBox(height: 14),
                    VvCard(
                      padding: const EdgeInsets.all(18),
                      radius: 22,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(tr('Free'), style: Vv.serif(26)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: Vv.mint, borderRadius: BorderRadius.circular(999)),
                                child: Text(tr('Current plan'), style: Vv.sans(12, weight: FontWeight.w800, color: Vv.green)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          for (final f in _free) _line(f, Vv.green),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        color: Vv.deep,
                        padding: const EdgeInsets.all(20),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const VvRings(size: 220),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: Vv.goldLight, borderRadius: BorderRadius.circular(999)),
                                  child: Text(tr('MOST LOVED'), style: Vv.kicker(Vv.deep)),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Flexible(child: Text(tr('Premium'), style: Vv.serif(30, color: Vv.bg), overflow: TextOverflow.ellipsis)),
                                    Text(_tab == 1 ? tr('₹4,990/yr') : tr('₹499/mo'), style: Vv.serif(26, color: Vv.goldLight)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                for (final f in _premium) _line(f, Vv.leaf, color: Vv.bg),
                                const SizedBox(height: 6),
                                VvButton(
                                  label: tr('Upgrade with UPI / Google Pay'),
                                  height: 52,
                                  fontSize: 15,
                                  weight: FontWeight.w800,
                                  bg: Vv.gold,
                                  fg: Vv.deep,
                                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Google Pay checkout coming soon')))),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(tr('Cancel anytime. Vaidya consult fees are paid separately per booking.'),
                        textAlign: TextAlign.center, style: Vv.sans(12, color: Vv.muted, height: 1.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _line(String t, Color check, {Color color = Vv.ink}) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.only(top: 1), child: Icon(Icons.check_rounded, size: 18, color: check)),
            const SizedBox(width: 10),
            Expanded(child: Text(tr(t), style: Vv.sans(14, color: color, height: 1.4))),
          ],
        ),
      );
}
