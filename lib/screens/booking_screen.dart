import 'package:flutter/material.dart';
import 'package:veda_verse/l10n/lang.dart';
import 'package:veda_verse/screens/health_summary_screen.dart';
import 'package:veda_verse/screens/vaidya_screen.dart';
import 'package:veda_verse/state/app_state.dart';
import 'package:veda_verse/theme/vv.dart';

/// Book a consult with [vaidya]: mode, day and time, and whether to share the
/// health summary. Saves a [Booking] and pops with `true`.
class BookingScreen extends StatefulWidget {
  final Vaidya vaidya;

  /// Mode to preselect ('Video', 'Phone' or 'In clinic'), if offered.
  final String? mode;

  /// The current time. Tests pass a fixed one; defaults to the clock.
  final DateTime? now;

  const BookingScreen({super.key, required this.vaidya, this.mode, this.now});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  late String _mode = _firstMode();
  int _day = 0;
  DateTime? _slot;
  late bool _share = AppState.instance.consentVaidya;

  DateTime get _now => widget.now ?? DateTime.now();

  String _firstMode() {
    final v = widget.vaidya;
    if (widget.mode != null && v.offers(widget.mode!)) return widget.mode!;
    return consultModes.firstWhere(v.offers, orElse: () => v.modes.isEmpty ? 'Video' : v.modes.first);
  }

  DateTime _date(int i) {
    final n = _now;
    return DateTime(n.year, n.month, n.day + i);
  }

  List<DateTime> _slotsOn(int i) => slotsFor(widget.vaidya, _date(i), _now);

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < 3; i++) {
      final s = _slotsOn(i);
      if (s.isNotEmpty) {
        _day = i;
        _slot = s.first;
        break;
      }
    }
  }

  void _pickDay(int i) {
    setState(() {
      _day = i;
      final s = _slotsOn(i);
      if (_slot == null || !s.contains(_slot)) {
        // Keep the same time of day if that day has it.
        final same = _slot == null ? null : s.where((t) => t.hour == _slot!.hour && t.minute == _slot!.minute).firstOrNull;
        _slot = same ?? s.firstOrNull;
      }
    });
  }

  List<(String, String)> get _days {
    const wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    String big(DateTime d) => '${tr(wd[d.weekday - 1])} ${d.day}';
    return [
      (tr('Today'), big(_date(0))),
      (tr('Tomorrow'), big(_date(1))),
      (weekdayName(_date(2)), big(_date(2))),
    ];
  }

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  void _confirm() {
    final v = widget.vaidya;
    final when = _slot;
    if (when == null) return;
    if (!when.isAfter(_now)) {
      _toast(tr('This time has passed. Please pick another.'));
      setState(() => _slot = _slotsOn(_day).firstOrNull);
      return;
    }
    final s = AppState.instance;
    for (final b in s.bookings) {
      if (b.when != when) continue;
      _toast(b.vaidya == v.name
          ? trf('You already booked {name} at this time.', {'name': v.name})
          : trf('You already have a consult with {name} at this time.', {'name': b.vaidya}));
      return;
    }
    s.update((s) => s.bookings.add(Booking(vaidya: v.name, when: when, mode: _mode, shareSummary: _share)));
    _toast(trf('Booked: {name}, {when} ({mode})', {'name': v.name, 'when': '${dayLabel(when, now: _now)} ${fmtTime(when)}', 'mode': tr(_mode)}));
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vaidya;
    final days = _days;
    final slots = _slotsOn(_day);
    final (noteIcon, note) = switch (_mode) {
      'Phone' => (Icons.phone_outlined, tr('The Vaidya calls you at the chosen time.')),
      'In clinic' => (Icons.place_outlined, v.clinic.isEmpty ? tr('In clinic') : trf('Clinic: {address}', {'address': tr(v.clinic)})),
      _ => (Icons.videocam_outlined, tr('The video link becomes active 10 minutes before the start.')),
    };
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
                    Flexible(child: SerifTitle(tr('Book a '), tr('consult'), size: 25)),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              v.portrait(size: 80, radius: 20),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(v.name, style: Vv.sans(16, weight: FontWeight.w800, color: Vv.bg)),
                                    const SizedBox(height: 3),
                                    Text(v.metaText, style: Vv.sans(12, color: Vv.onDeepMuted2)),
                                    const SizedBox(height: 3),
                                    Text(v.regText, style: Vv.sans(12, weight: FontWeight.w700, color: Vv.goldLight)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (v.concerns.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final c in v.concerns)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                    decoration: BoxDecoration(color: const Color(0xFF24503F), borderRadius: BorderRadius.circular(999)),
                                    child: Text(tr(c), style: Vv.sans(11.5, weight: FontWeight.w700, color: Vv.onDeepMuted2)),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(tr('HOW'), style: Vv.kicker(Vv.ink2)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (final m in consultModes) ...[
                          Expanded(
                            child: Semantics(
                              enabled: v.offers(m),
                              selected: _mode == m,
                              child: _chip(tr(m), _mode == m, v.offers(m) ? () => setState(() => _mode = m) : null),
                            ),
                          ),
                          if (m != consultModes.last) const SizedBox(width: 8),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    VvNote(text: note, icon: noteIcon),
                    const SizedBox(height: 16),
                    Text(tr('WHEN'), style: Vv.kicker(Vv.ink2)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (var i = 0; i < 3; i++) ...[
                          Expanded(
                            child: VvTap(
                              onTap: () => _pickDay(i),
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
                    if (slots.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: VvNote(text: tr('No times left on this day. Please pick another day.'), icon: Icons.schedule_rounded),
                      )
                    else
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 110 / 44,
                        children: [for (final sl in slots) _chip(fmtTime(sl), _slot == sl, () => setState(() => _slot = sl))],
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
                                Text(tr('Share my health summary'), style: Vv.sans(14, weight: FontWeight.w800)),
                                const SizedBox(height: 3),
                                Text(tr('Intake, Prakriti and lab values — with this Vaidya only.'), style: Vv.sans(12, color: Vv.muted, height: 1.45)),
                                const SizedBox(height: 4),
                                VvTap(
                                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HealthSummaryScreen())),
                                  child: Text(tr('Preview summary'), style: Vv.sans(12.5, weight: FontWeight.w800, color: Vv.green)),
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
                          Text(
                            _slot == null ? tr('Pick a time') : '${tr(_mode)} · ${days[_day].$1} ${fmtTime(_slot!)}',
                            style: Vv.sans(12, color: Vv.muted),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(v.feeText, style: Vv.serif(24)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 2,
                      child: VvButton(
                        label: tr('Confirm booking'),
                        bg: _slot == null ? Vv.sage : Vv.green,
                        onTap: _slot == null ? null : _confirm,
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

  Widget _chip(String l, bool on, VoidCallback? onTap) => VvTap(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: const BoxConstraints(minHeight: 44),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: on ? Vv.green : (onTap == null ? Vv.shade : Vv.surface),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: on ? Vv.green : Vv.border2, width: 1.5),
          ),
          child: Text(l,
              textAlign: TextAlign.center,
              style: Vv.sans(13,
                  weight: FontWeight.w700,
                  color: on ? Vv.surface : (onTap == null ? Vv.disabled : Vv.ink))
                  .copyWith(decoration: onTap == null ? TextDecoration.lineThrough : null)),
        ),
      );
}
