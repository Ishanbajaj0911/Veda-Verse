import 'package:flutter/material.dart';
import 'package:veda_verse/l10n/hi.dart';
import 'package:veda_verse/l10n/lang.dart';
import 'package:veda_verse/screens/health_summary_screen.dart';
import 'package:veda_verse/screens/booking_screen.dart';
import 'package:veda_verse/screens/profile_menu_screen.dart';
import 'package:veda_verse/state/app_state.dart';
import 'package:veda_verse/theme/vv.dart';
import 'package:veda_verse/widgets/art.dart';

/// Ways to consult, as stored in [Booking.mode] (English; shown with tr()).
const consultModes = ['Video', 'Phone', 'In clinic'];

/// Extra words people type for each concern tag (English and Hindi), used
/// only by the search box.
const _concernWords = <String, List<String>>{
  'Digestion': ['digestion', 'gas', 'bloating', 'constipation', 'indigestion', 'stomach', 'पाचन', 'गैस', 'कब्ज', 'अपच', 'पेट'],
  'Acidity': ['acidity', 'acid', 'heartburn', 'reflux', 'एसिडिटी', 'जलन', 'खट्टी डकार'],
  'Sleep': ['sleep', 'insomnia', 'नींद', 'अनिद्रा'],
  'Stress': ['stress', 'anxiety', 'tension', 'तनाव', 'चिंता', 'टेंशन'],
  'Women’s health': ['women', 'woman', 'periods', 'menstrual', 'महिला', 'माहवारी', 'पीरियड'],
  'PCOS': ['pcos', 'pcod', 'पीसीओएस', 'पीसीओडी'],
  'Joints': ['joint', 'arthritis', 'knee', 'जोड़', 'घुटन', 'गठिया'],
  'Back pain': ['back', 'spine', 'neck', 'कमर', 'रीढ़', 'पीठ'],
  'Skin': ['skin', 'acne', 'pimple', 'eczema', 'त्वचा', 'मुंहासे', 'मुँहासे', 'दाने'],
};

/// A Vaidya in the demo directory. These are sample profiles drawn in code,
/// not real people.
class Vaidya {
  final String init, name, meta, slot, fee;
  final Color tint;

  /// Drawn portrait ([VaidyaPortrait]).
  final Color skin, hair;
  final Hair hairStyle;
  final bool beard;

  /// Subset of [consultModes] this Vaidya offers.
  final List<String> modes;
  final bool availableNow;

  /// Concern tags (English keys, shown with tr()).
  final List<String> concerns;

  /// Clinic address line (English key), empty without a clinic.
  final String clinic;

  /// Registration number shown on the card (demo values).
  final String reg;

  /// Start times of the consult slots, in minutes after midnight.
  final List<int> slotMinutes;

  const Vaidya(
    this.init,
    this.name,
    this.meta,
    this.slot,
    this.fee,
    this.tint, {
    this.skin = const Color(0xFFC68B63),
    this.hair = const Color(0xFF2B211C),
    this.hairStyle = Hair.short,
    this.beard = false,
    this.modes = const ['Video'],
    this.availableNow = false,
    this.concerns = const [],
    this.clinic = '',
    this.reg = 'RJ/A-2301',
    this.slotMinutes = const [630, 720, 780, 1020, 1110, 1200],
  });

  bool offers(String mode) => modes.contains(mode);
  bool get isFree => fee == 'Free';

  /// [meta], [slot] and [fee] as shown, in the current language. The name
  /// stays in Latin letters.
  String get metaText => meta.split(' · ').map(tr).join(' · ');
  String get slotText {
    if (availableNow) return tr(slot);
    final next = nextSlot(DateTime.now());
    if (next == null) return tr(slot);
    return trf('Next: {when}', {'when': '${dayLabel(next)} ${fmtTime(next)}'});
  }

  String get feeText => tr(fee);
  String get regText => trf('Reg. No. {reg} · NCISM-verified', {'reg': reg});
  String get modesText => modes.map(tr).join(' · ');

  /// First free slot in the next 3 days (skips ones the user already booked).
  DateTime? nextSlot(DateTime now) {
    final mine = {for (final b in AppState.instance.bookings) if (b.vaidya == name) b.when};
    for (var i = 0; i < 3; i++) {
      for (final t in slotsFor(this, DateTime(now.year, now.month, now.day + i), now)) {
        if (!mine.contains(t)) return t;
      }
    }
    return null;
  }

  /// True if every word of [query] matches the name, speciality, concern
  /// tags or their Hindi words.
  bool matches(String query) {
    final words = query.trim().toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) return true;
    final hay = [
      name,
      meta,
      for (final p in meta.split(' · ')) hiStrings[p] ?? '',
      for (final c in concerns) ...[c, hiStrings[c] ?? '', ...?_concernWords[c]],
    ].map((s) => s.toLowerCase()).toList();
    return words.every((w) => hay.any((h) => h.contains(w)));
  }

  /// The drawn portrait in a rounded square.
  Widget portrait({double size = 60, double radius = 16}) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox(
          width: size,
          height: size,
          child: VaidyaPortrait(skin: skin, hair: hair, style: hairStyle, beard: beard, bg: tint),
        ),
      );
}

const vaidyas = [
  Vaidya('RK', 'Dr. Rohan Kapoor', 'BAMS, MD (Kayachikitsa) · Hindi, English', 'Available now', '₹399', Vv.mint,
      skin: Color(0xFFC68B63),
      hair: Color(0xFF2B211C),
      hairStyle: Hair.short,
      beard: true,
      modes: ['Video', 'Phone'],
      availableNow: true,
      concerns: ['Digestion', 'Acidity', 'Stress'],
      reg: 'DL/A-4127'),
  Vaidya('AN', 'Dr. Anjali Nair', 'BAMS · Women’s health · English, Malayalam', 'By appointment', '₹499', Vv.goldPale,
      skin: Color(0xFF9C6644),
      hair: Color(0xFF1C1412),
      hairStyle: Hair.long,
      modes: ['Video', 'In clinic'],
      concerns: ['Women’s health', 'PCOS', 'Skin'],
      clinic: 'Panampilly Nagar, Kochi',
      reg: 'KL/A-1187',
      slotMinutes: [600, 690, 840, 990, 1080, 1170]),
  Vaidya('SP', 'Dr. Suresh Paliwal', 'BAMS · Joints & spine · Hindi, Mewari', 'By appointment', 'Free', Vv.bluePale2,
      skin: Color(0xFFB57A55),
      hair: Color(0xFF8E8A86),
      hairStyle: Hair.bald,
      beard: true,
      modes: ['In clinic', 'Phone'],
      concerns: ['Joints', 'Back pain'],
      clinic: 'Fatehpura, Udaipur',
      reg: 'RJ/A-2301',
      slotMinutes: [540, 630, 720, 960, 1050, 1140]),
  Vaidya('MS', 'Dr. Meera Sharma', 'BAMS · Sleep & stress · Hindi, English', 'Available now', '₹299', Vv.plumPale,
      skin: Color(0xFFD9A07A),
      hair: Color(0xFF3B2A22),
      hairStyle: Hair.bun,
      modes: ['Video', 'Phone', 'In clinic'],
      availableNow: true,
      concerns: ['Sleep', 'Stress', 'Digestion'],
      clinic: 'Vaishali Nagar, Jaipur',
      reg: 'RJ/A-3315'),
];

/// The listed Vaidya with this name, if any.
Vaidya? vaidyaNamed(String name) {
  for (final v in vaidyas) {
    if (v.name == name) return v;
  }
  return null;
}

/// "6:30 pm".
String fmtTime(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return '$h:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'am' : 'pm'}';
}

/// "Today", "Tomorrow", a weekday within the week, else "4/11".
String dayLabel(DateTime when, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final days = DateTime.utc(when.year, when.month, when.day).difference(DateTime.utc(n.year, n.month, n.day)).inDays;
  if (days == 0) return tr('Today');
  if (days == 1) return tr('Tomorrow');
  if (days > 1 && days < 7) return weekdayName(when);
  return '${when.day}/${when.month}';
}

/// The bookable start times of [v] on [day] that are still ahead of [now].
/// A Vaidya marked available now also has a slot in the next 10–25 minutes
/// today (until 10 pm).
List<DateTime> slotsFor(Vaidya v, DateTime day, DateTime now) {
  final out = [for (final m in v.slotMinutes) DateTime(day.year, day.month, day.day, m ~/ 60, m % 60)];
  final today = day.year == now.year && day.month == now.month && day.day == now.day;
  if (today && v.availableNow) {
    final soon = now.add(const Duration(minutes: 10));
    final up = (soon.minute + 14) ~/ 15 * 15;
    final s = DateTime(soon.year, soon.month, soon.day, soon.hour, up);
    if (s.day == now.day && s.hour < 22 && !out.contains(s)) out.add(s);
  }
  return out.where((t) => t.isAfter(now)).toList()..sort();
}

/// Short line for a booked consult's mode.
String modeLine(String mode) => switch (mode) {
      'Phone' => tr('Phone consult'),
      'In clinic' => tr('Clinic visit'),
      _ => tr('Video consult'),
    };

/// Connect with Vaidya tab.
class VaidyaScreen extends StatefulWidget {
  const VaidyaScreen({super.key});

  @override
  State<VaidyaScreen> createState() => _VaidyaScreenState();
}

class _VaidyaScreenState extends State<VaidyaScreen> {
  static const _filters = ['All', 'Available now', 'Video', 'In clinic', 'Free'];

  String _f = 'All';
  final _q = TextEditingController();
  final _scroll = ScrollController();
  final _listKey = GlobalKey();

  @override
  void dispose() {
    _q.dispose();
    _scroll.dispose();
    super.dispose();
  }

  bool _passes(Vaidya d) {
    final chip = switch (_f) {
      'Available now' => d.availableNow,
      'Video' => d.offers('Video'),
      'In clinic' => d.offers('In clinic'),
      'Free' => d.isFree,
      _ => true,
    };
    return chip && d.matches(_q.text);
  }

  void _clearFilters() {
    _q.clear();
    FocusScope.of(context).unfocus();
    setState(() => _f = 'All');
  }

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _book(Vaidya d, {String? mode}) async {
    final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => BookingScreen(vaidya: d, mode: mode)));
    if (ok == true && mounted && _scroll.hasClients) {
      await _scroll.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  void _toList() {
    final c = _listKey.currentContext;
    if (c != null) Scrollable.ensureVisible(c, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final s = AppState.instance;
        final upcoming = s.upcoming;
        final shown = vaidyas.where(_passes).toList();
        return Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top),
            VvTabHeader(
              hello: trf('Hello, {name}', {'name': s.firstName}),
              title: Text(tr('Connect with Vaidya'), style: Vv.serif(25, letterSpacing: -0.2)),
              initial: s.initial,
              onProfile: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileMenuScreen())),
            ),
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                children: [
                  _search(),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filters.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final l = _filters[i];
                        return VvChip(label: tr(l), on: _f == l, onTap: () => setState(() => _f = l));
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (upcoming.isEmpty) _noUpcoming() else ...[
                    _upcomingCard(upcoming.first),
                    if (upcoming.length > 1) ...[
                      const SizedBox(height: 12),
                      Text(tr('Also booked'), style: Vv.kicker(Vv.ink2)),
                      const SizedBox(height: 8),
                      for (final b in upcoming.skip(1)) ...[_moreRow(b), const SizedBox(height: 8)],
                    ],
                  ],
                  const SizedBox(height: 18),
                  Row(
                    key: _listKey,
                    children: [
                      Expanded(child: Text(tr('Verified Vaidyas'), style: Vv.serif(17, weight: FontWeight.w700))),
                      if (shown.length != vaidyas.length)
                        Text(trf('{n} of {total}', {'n': shown.length, 'total': vaidyas.length}),
                            style: Vv.sans(12, weight: FontWeight.w700, color: Vv.muted)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  VvNote(text: tr('Demo profiles: names and registration numbers are examples.'), icon: Icons.info_outline_rounded),
                  const SizedBox(height: 12),
                  if (shown.isEmpty) _noMatch(),
                  for (final d in shown) ...[_card(d), const SizedBox(height: 14)],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _search() => Container(
        height: 50,
        padding: const EdgeInsets.only(left: 14, right: 4),
        decoration: BoxDecoration(color: Vv.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: Vv.border2, width: 1.5)),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, size: 18, color: Vv.muted),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _q,
                style: Vv.sans(14),
                textInputAction: TextInputAction.search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: tr('Search by concern, e.g. acidity, sleep'),
                  hintStyle: Vv.sans(14, color: Vv.disabled),
                ),
              ),
            ),
            if (_q.text.isNotEmpty)
              IconButton(
                tooltip: tr('Clear search'),
                icon: const Icon(Icons.close_rounded, size: 18, color: Vv.muted),
                onPressed: () {
                  _q.clear();
                  setState(() {});
                },
              ),
          ],
        ),
      );

  Widget _noUpcoming() => VvCard(
        color: Vv.mint,
        borderColor: Vv.mintBorder,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: Vv.surface, borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.event_available_outlined, size: 22, color: Vv.green),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(tr('No consults booked yet'), style: Vv.sans(15, weight: FontWeight.w800))),
              ],
            ),
            const SizedBox(height: 10),
            Text(tr('Pick a Vaidya below. Your health summary can go with the booking, so you don’t repeat your story.'),
                style: Vv.sans(12.5, color: Vv.ink2, height: 1.45)),
            const SizedBox(height: 12),
            VvButton(label: tr('Find a Vaidya'), height: 44, fontSize: 14, trailing: Icons.arrow_downward_rounded, onTap: _toList),
          ],
        ),
      );

  Widget _portraitFor(String name, double size, double radius) {
    final d = vaidyaNamed(name);
    if (d != null) return d.portrait(size: size, radius: radius);
    final init = name.replaceAll('Dr. ', '').split(' ').where((w) => w.isNotEmpty).map((w) => w[0]).take(2).join();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: const Color(0xFF3C6E4C), borderRadius: BorderRadius.circular(radius)),
      child: Text(init, style: Vv.serif(size * 0.32, weight: FontWeight.w700, color: Vv.bg)),
    );
  }

  Widget _upcomingCard(Booking b) {
    final day = dayLabel(b.when);
    final time = fmtTime(b.when);
    final (joinLabel, joinIcon) = switch (b.mode) {
      'Phone' => (tr('Call details'), Icons.phone_outlined),
      'In clinic' => (tr('Clinic address'), Icons.place_outlined),
      _ => (tr('How to join'), Icons.videocam_outlined),
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Vv.deep, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(tr('UPCOMING CONSULT'), style: Vv.sans(12, weight: FontWeight.w700, color: Vv.onDeepMuted, letterSpacing: 1)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Vv.gold, borderRadius: BorderRadius.circular(999)),
                child: Text('$day · $time', style: Vv.sans(12, weight: FontWeight.w700, color: Vv.deep)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _portraitFor(b.vaidya, 52, 14),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.vaidya, style: Vv.sans(15, weight: FontWeight.w700, color: Vv.bg), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(modeLine(b.mode), style: Vv.sans(13, color: Vv.onDeepMuted3)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(b.shareSummary ? Icons.check_rounded : Icons.lock_outline_rounded, size: 16, color: Vv.kaphaBar),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    b.shareSummary
                        ? tr('Your health summary is shared before the consult, so you don’t repeat your history.')
                        : tr('Your health summary is not shared for this consult.'),
                    style: Vv.sans(12, color: Vv.onDeepMuted3, height: 1.4)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Flexible(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HealthSummaryScreen())),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 0), minimumSize: const Size(0, 40)),
                  child: Text(tr('View my summary'), style: Vv.sans(12.5, weight: FontWeight.w800, color: Vv.goldLight)),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _cancel(b),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: const Size(0, 40)),
                child: Text(tr('Cancel'), style: Vv.sans(12.5, weight: FontWeight.w800, color: Vv.onDeepMuted2)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          VvButton(
            label: joinLabel,
            height: 48,
            fontSize: 15,
            weight: FontWeight.w800,
            bg: Vv.gold,
            fg: Vv.deep,
            leading: joinIcon,
            onTap: () => _joinSheet(b),
          ),
        ],
      ),
    );
  }

  Widget _moreRow(Booking b) => VvCard(
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        radius: 16,
        child: Row(
          children: [
            _portraitFor(b.vaidya, 40, 12),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b.vaidya, style: Vv.sans(13.5, weight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('${dayLabel(b.when)} · ${fmtTime(b.when)} · ${tr(b.mode)}', style: Vv.sans(12, color: Vv.muted)),
                ],
              ),
            ),
            IconButton(
              tooltip: tr('Cancel'),
              icon: const Icon(Icons.close_rounded, size: 20, color: Vv.muted),
              onPressed: () => _cancel(b),
            ),
          ],
        ),
      );

  Future<void> _cancel(Booking b) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Vv.surface,
        title: Text(tr('Cancel this consult?'), style: Vv.serif(20)),
        content: Text('${b.vaidya} · ${dayLabel(b.when)} · ${fmtTime(b.when)} · ${tr(b.mode)}', style: Vv.sans(14, color: Vv.ink2, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('Keep it'), style: Vv.sans(14, weight: FontWeight.w700, color: Vv.green)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('Cancel consult'), style: Vv.sans(14, weight: FontWeight.w800, color: Vv.red)),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    AppState.instance.update((s) => s.bookings.remove(b));
    _toast(tr('Consult cancelled'));
  }

  Future<void> _sheet({required IconData icon, required String title, String? chip, required List<String> lines, Widget? action}) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Vv.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: Vv.mint, borderRadius: BorderRadius.circular(14)),
                    child: Icon(icon, size: 22, color: Vv.green),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(title, style: Vv.serif(20, weight: FontWeight.w700))),
                ],
              ),
              if (chip != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Vv.goldPale, borderRadius: BorderRadius.circular(999)),
                  child: Text(chip, style: Vv.sans(12.5, weight: FontWeight.w700, color: Vv.brown)),
                ),
              ],
              const SizedBox(height: 12),
              for (final l in lines) ...[
                Text(l, style: Vv.sans(14, color: Vv.ink2, height: 1.45)),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 8),
              action ?? VvButton(label: tr('OK'), height: 48, fontSize: 15, onTap: () => Navigator.pop(ctx)),
            ],
          ),
        ),
      ),
    );
  }

  void _joinSheet(Booking b) {
    final d = vaidyaNamed(b.vaidya);
    final time = fmtTime(b.when);
    final chip = '${dayLabel(b.when)} · $time';
    switch (b.mode) {
      case 'Phone':
        _sheet(icon: Icons.phone_outlined, title: tr('Phone consult'), chip: chip, lines: [
          trf('The Vaidya will call you at {time}.', {'time': time}),
          tr('Keep your phone nearby with the ringer on.'),
        ]);
      case 'In clinic':
        _sheet(icon: Icons.place_outlined, title: tr('Clinic visit'), chip: chip, lines: [
          if (d != null && d.clinic.isNotEmpty) trf('Clinic: {address}', {'address': tr(d.clinic)}),
          trf('Please arrive 10 minutes before {time}.', {'time': time}),
        ]);
      default:
        final open = DateTime.now().isAfter(b.when.subtract(const Duration(minutes: 10)));
        _sheet(icon: Icons.videocam_outlined, title: tr('Video consult'), chip: chip, lines: [
          open
              ? trf('Your consult starts at {time}.', {'time': time})
              : trf('Your consult starts at {time}. The video link becomes active 10 minutes before the start.', {'time': time}),
          tr('Video calls aren’t live in this demo yet, so no link is shown.'),
        ]);
    }
  }

  void _chatSheet(Vaidya d) {
    final booked = AppState.instance.upcoming.where((b) => b.vaidya == d.name).firstOrNull;
    if (booked != null) {
      _sheet(icon: Icons.chat_bubble_outline_rounded, title: tr('Messages'), lines: [
        trf('You have a consult with {name}: {when}.', {'name': d.name, 'when': '${dayLabel(booked.when)} · ${fmtTime(booked.when)}'}),
        tr('Messages aren’t live in this demo yet. Note your questions for the consult.'),
      ]);
      return;
    }
    _sheet(
      icon: Icons.chat_bubble_outline_rounded,
      title: tr('Messages'),
      lines: [tr('Messages open after you book a consult.')],
      action: Builder(
        builder: (ctx) => VvButton(
          label: trf('Book · {fee}', {'fee': d.feeText}),
          height: 48,
          fontSize: 15,
          onTap: () {
            Navigator.pop(ctx);
            _book(d);
          },
        ),
      ),
    );
  }

  Widget _card(Vaidya d) {
    return VvCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              d.portrait(size: 62, radius: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text(d.name, style: Vv.sans(15, weight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified_rounded, size: 16, color: Vv.green),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(d.metaText, style: Vv.sans(12, color: Vv.muted)),
                    const SizedBox(height: 3),
                    Text(d.regText, style: Vv.sans(12, weight: FontWeight.w700, color: Vv.ink2)),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (d.availableNow) ...[
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Vv.live, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                        ],
                        Flexible(child: Text(d.slotText, style: Vv.sans(12, weight: FontWeight.w700, color: Vv.green))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final c in d.concerns) _tag(tr(c), d.tint),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.event_available_outlined, size: 15, color: Vv.muted),
              const SizedBox(width: 6),
              Expanded(child: Text(d.modesText, style: Vv.sans(12, weight: FontWeight.w600, color: Vv.muted))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _ico(Icons.chat_bubble_outline_rounded, tr('Message'), () => _chatSheet(d)),
              const SizedBox(width: 8),
              _ico(
                Icons.phone_outlined,
                d.offers('Phone') ? tr('Book a phone consult') : tr('Phone consult not offered'),
                () => d.offers('Phone') ? _book(d, mode: 'Phone') : _toast(trf('{name} doesn’t offer phone consults.', {'name': d.name})),
                enabled: d.offers('Phone'),
              ),
              const SizedBox(width: 8),
              _ico(
                Icons.videocam_outlined,
                d.offers('Video') ? tr('Book a video consult') : tr('Video consult not offered'),
                () => d.offers('Video') ? _book(d, mode: 'Video') : _toast(trf('{name} doesn’t offer video consults.', {'name': d.name})),
                enabled: d.offers('Video'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: VvButton(
                  label: trf('Book · {fee}', {'fee': d.feeText}),
                  height: 44,
                  fontSize: 14,
                  onTap: () => _book(d),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tag(String label, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Text(label, style: Vv.sans(11.5, weight: FontWeight.w700, color: Vv.ink2)),
      );

  Widget _noMatch() => VvCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const Icon(Icons.search_off_rounded, size: 28, color: Vv.muted),
            const SizedBox(height: 8),
            Text(tr('No Vaidya matches'), style: Vv.sans(15, weight: FontWeight.w800), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(tr('Try another word or filter.'), style: Vv.sans(12.5, color: Vv.muted), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            VvButton(label: tr('Clear filters'), height: 44, fontSize: 14, bg: Vv.surface, fg: Vv.green, borderColor: Vv.green, onTap: _clearFilters),
          ],
        ),
      );

  Widget _ico(IconData i, String tip, VoidCallback onTap, {bool enabled = true}) => Tooltip(
        message: tip,
        excludeFromSemantics: true,
        child: Semantics(
          button: true,
          enabled: enabled,
          label: tip,
          child: VvTap(
            onTap: onTap,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: enabled ? Vv.surface : Vv.shade,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Vv.border2, width: 1.5),
              ),
              child: Icon(i, size: 18, color: enabled ? Vv.ink : Vv.disabled),
            ),
          ),
        ),
      );
}
