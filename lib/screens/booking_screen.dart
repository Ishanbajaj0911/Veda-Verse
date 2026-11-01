import 'package:flutter/material.dart';
import 'package:veda_verse/screens/health_summary_screen.dart';
import 'package:veda_verse/screens/vaidya_screen.dart';
import 'package:veda_verse/state/app_state.dart';
import 'package:veda_verse/theme/vv.dart';

class BookingScreen extends StatefulWidget {
  final Vaidya vaidya;
  const BookingScreen({super.key, required this.vaidya});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  String _mode = 'Video';
  int _day = 0;
  String _slot = '6:30 pm';
  late bool _share = AppState.instance.consentVaidya;

  static const _slots = ['10:30 am', '12:00 pm', '1:00 pm', '5:00 pm', '6:30 pm', '8:00 pm'];

  List<(String, String)> get _days {
    final now = DateTime.now();
    const wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    String big(DateTime d) => '${wd[d.weekday - 1]} ${d.day}';
    final d2 = now.add(const Duration(days: 2));
    return [
      ('Today', big(now)),
      ('Tomorrow', big(now.add(const Duration(days: 1)))),
      (weekdayName(d2), big(d2)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vaidya;
    final days = _days;
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
                    const SerifTitle('Book a ', 'consult', size: 25),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Vv.deep, borderRadius: BorderRadius.circular(22)),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: Vv.mint, borderRadius: BorderRadius.circular(16)),
                            child: Text(v.init, style: Vv.serif(22, color: Vv.deep)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(v.name, style: Vv.sans(16, weight: FontWeight.w800, color: Vv.bg)),
                                const SizedBox(height: 3),
                                Text(v.meta, style: Vv.sans(12, color: Vv.onDeepMuted2)),
                                const SizedBox(height: 3),
                                Text('Reg. No. RJ/A-2301 · NCISM-verified', style: Vv.sans(12, weight: FontWeight.w700, color: Vv.goldLight)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('HOW', style: Vv.kicker(Vv.ink2)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (final m in ['Chat', 'Call', 'Video', 'Clinic']) ...[
                          Expanded(child: _chip(m, _mode == m, () => setState(() => _mode = m))),
                          if (m != 'Clinic') const SizedBox(width: 8),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('WHEN', style: Vv.kicker(Vv.ink2)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (var i = 0; i < 3; i++) ...[
                          Expanded(
                            child: VvTap(
                              onTap: () => setState(() => _day = i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                constraints: const BoxConstraints(minHeight: 64),
                                decoration: BoxDecoration(
                                  color: _day == i ? Vv.deep : Vv.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: _day == i ? Vv.deep : Vv.border2, width: 1.5),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Opacity(opacity: 0.8, child: Text(days[i].$1, style: Vv.sans(12, weight: FontWeight.w700, color: _day == i ? Vv.bg : Vv.ink))),
                                    const SizedBox(height: 2),
                                    Text(days[i].$2, style: Vv.serif(20, color: _day == i ? Vv.bg : Vv.ink)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (i < 2) const SizedBox(width: 8),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 110 / 44,
                      children: [for (final sl in _slots) _chip(sl, _slot == sl, () => setState(() => _slot = sl))],
                    ),
                    const SizedBox(height: 16),
                    VvCard(
                      padding: const EdgeInsets.all(14),
                      radius: 18,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Share my health summary', style: Vv.sans(14, weight: FontWeight.w800)),
                                const SizedBox(height: 3),
                                Text('Intake, Prakriti and lab values — with this Vaidya only.', style: Vv.sans(12, color: Vv.muted, height: 1.45)),
                                const SizedBox(height: 4),
                                VvTap(
                                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HealthSummaryScreen())),
                                  child: Text('Preview summary', style: Vv.sans(12.5, weight: FontWeight.w800, color: Vv.green)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          VvSwitch(on: _share, onTap: () => setState(() => _share = !_share)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: Vv.border))),
                child: Row(
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$_mode · ${days[_day].$1} $_slot', style: Vv.sans(12, color: Vv.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(v.fee, style: Vv.serif(24)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 2,
                      child: VvButton(
                        label: 'Confirm booking',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booked: ${v.name}, ${days[_day].$1} $_slot ($_mode)')));
                          Navigator.of(context).pop();
                        },
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

  Widget _chip(String l, bool on, VoidCallback onTap) => VvTap(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: const BoxConstraints(minHeight: 44),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? Vv.green : Vv.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: on ? Vv.green : Vv.border2, width: 1.5),
          ),
          child: Text(l, style: Vv.sans(13, weight: FontWeight.w700, color: on ? Vv.surface : Vv.ink)),
        ),
      );
}
