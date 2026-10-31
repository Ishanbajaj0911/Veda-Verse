import 'package:flutter/material.dart';
import 'package:veda_verse/app_shell.dart';
import 'package:veda_verse/screens/profile_menu_screen.dart';
import 'package:veda_verse/state/app_state.dart';
import 'package:veda_verse/theme/vv.dart';

enum _Kind { user, answer, vaidya, emergency }

class _Msg {
  final _Kind kind;
  final String text;
  final String? source;
  const _Msg(this.kind, this.text, {this.source});
}

/// Ayu Buddy – chat and voice. The guardrail (red flag → 112, herb/medicine →
/// "Needs a Vaidya") runs locally here; Gemini wiring plugs into [_reply].
class BuddyScreen extends StatefulWidget {
  const BuddyScreen({super.key});

  @override
  State<BuddyScreen> createState() => _BuddyScreenState();
}

class _BuddyScreenState extends State<BuddyScreen> {
  int _mode = 0;
  final _input = TextEditingController();
  final _scroll = ScrollController();

  final List<_Msg> _msgs = [
    const _Msg(_Kind.user, 'Why do I feel so bloated after dinner?'),
    const _Msg(
      _Kind.answer,
      'In Ayurveda, digestive fire (Agni) is weaker at night, and with your Vata–Pitta pattern, heavy or late meals often sit longer. Eating your largest meal at lunch and a lighter, warm dinner before 8 pm is the classical guidance.',
      source: 'Charaka Samhita · Sutrasthana',
    ),
    const _Msg(_Kind.user, 'Can I take Triphala with my BP tablet?'),
    const _Msg(_Kind.vaidya, 'Amlodipine'),
  ];

  static const _redFlags = ['chest pain', 'breathless', 'can\'t breathe', 'cannot breathe', 'faint', 'suicid', 'self-harm', 'self harm', 'seene', 'saans'];
  static const _herbWords = ['tablet', 'pill', 'medicine', 'dose', 'herb', 'triphala', 'ashwagandha', 'giloy', 'churna', 'bp', 'dawai', 'goli'];

  void _send([String? preset]) {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty) return;
    _input.clear();
    setState(() {
      _msgs.add(_Msg(_Kind.user, text));
      _msgs.add(_reply(text));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  _Msg _reply(String text) {
    final t = text.toLowerCase();
    if (_redFlags.any(t.contains)) return const _Msg(_Kind.emergency, '');
    final meds = AppState.instance.medicines;
    if (_herbWords.any(t.contains)) return _Msg(_Kind.vaidya, meds.isEmpty ? '' : meds.first);
    if (t.contains('sleep') || t.contains('neend')) {
      return const _Msg(
        _Kind.answer,
        'For a restless Vata mind, Ayurveda suggests a fixed bedtime, warm milk or water, oil massage on the feet (Padabhyanga) and screens off an hour before sleep. Try 10 minutes of Anulom Vilom before bed.',
        source: 'Ashtanga Hridaya · Sutrasthana',
      );
    }
    if (t.contains('food') || t.contains('diet') || t.contains('eat') || t.contains('khana')) {
      return const _Msg(
        _Kind.answer,
        'With Vata leading, favour warm, cooked, lightly spiced food: khichdi, soups, ghee, stewed fruit. Keep meals at regular times and avoid cold, dry or raw food in the evening.',
        source: 'Charaka Samhita · Sutrasthana',
      );
    }
    return const _Msg(
      _Kind.answer,
      'Ayurveda looks at routine first: regular meals, sleep by 10:30 pm, gentle movement and breath work. Tell me what you feel most days and I’ll suggest one small change you can start today.',
      source: 'Charaka Samhita · Sutrasthana',
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).padding.top),
        VvTabHeader(
          hello: 'Hello, ${s.firstName}',
          title: Row(
            children: [
              Flexible(child: Text('Ayu Buddy', style: Vv.serif(25, letterSpacing: -0.2), overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Vv.live, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text('24/7', style: Vv.sans(12, weight: FontWeight.w600, color: Vv.green)),
            ],
          ),
          initial: s.initial,
          onLogo: () => AppShell.of(context)?.go(Tabs.home),
          onProfile: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileMenuScreen())),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Column(
            children: [
              VvSegments(labels: const ['Chat', 'Voice'], index: _mode, onChanged: (i) => setState(() => _mode = i)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: Vv.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Vv.border)),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_outlined, size: 18, color: Vv.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(TextSpan(
                        style: Vv.sans(12, color: Vv.ink2, height: 1.4),
                        children: [
                          TextSpan(text: 'Vaidya-reviewed guardrails. ', style: Vv.sans(12, weight: FontWeight.w800, color: Vv.ink2)),
                          const TextSpan(text: 'Ayu Buddy explains and guides — it never prescribes or doses.'),
                        ],
                      )),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: Vv.redPale, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Chest pain, breathlessness, fainting? Don’t chat — get help.',
                          style: Vv.sans(12, weight: FontWeight.w700, color: Vv.redInk)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Vv.red, borderRadius: BorderRadius.circular(8)),
                      child: Text('Call 112', style: Vv.sans(12, weight: FontWeight.w700, color: Vv.surface)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _mode == 0 ? _chat() : _voice()),
      ],
    );
  }

  Widget _chat() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            children: [
              for (final m in _msgs) ...[
                _bubble(m),
                const SizedBox(height: 12),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final q in ['Foods for my dosha?', 'Better sleep routine'])
                    VvTap(
                      onTap: () => _send(q),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 38),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Vv.surface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Vv.border3, width: 1.5),
                        ),
                        child: Text(q, style: Vv.sans(13, weight: FontWeight.w600)),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: Vv.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Vv.border2, width: 1.5),
                  ),
                  child: TextField(
                    controller: _input,
                    style: Vv.sans(14),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Ask in Hindi or English…',
                      hintStyle: Vv.sans(14, color: Vv.disabled),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              VvTap(
                onTap: () => _input.text.trim().isEmpty ? setState(() => _mode = 1) : _send(),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(color: Vv.gold, borderRadius: BorderRadius.circular(16)),
                  child: Icon(_input.text.trim().isEmpty ? Icons.mic_none_rounded : Icons.send_rounded, color: Vv.deep, size: 22),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bubble(_Msg m) {
    switch (m.kind) {
      case _Kind.user:
        return Align(
          alignment: Alignment.centerRight,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 300),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: Vv.green,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomLeft: Radius.circular(18), bottomRight: Radius.circular(4)),
            ),
            child: Text(m.text, style: Vv.sans(14, color: Vv.surface, height: 1.5)),
          ),
        );
      case _Kind.answer:
        return Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Vv.surface,
                    border: Border.all(color: Vv.border),
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomRight: Radius.circular(18), bottomLeft: Radius.circular(4)),
                  ),
                  child: Text(m.text, style: Vv.sans(14, height: 1.55)),
                ),
                if (m.source != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.menu_book_outlined, size: 14, color: Vv.ink2),
                      const SizedBox(width: 6),
                      Text('Source: ${m.source}', style: Vv.sans(12, weight: FontWeight.w700, color: Vv.ink2)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      case _Kind.vaidya:
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 330),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Vv.cream,
              border: Border.all(color: Vv.goldBorder, width: 1.5),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomRight: Radius.circular(18), bottomLeft: Radius.circular(4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shield_outlined, size: 16, color: Vv.brown),
                    const SizedBox(width: 6),
                    Text('NEEDS A VAIDYA', style: Vv.kicker(Vv.brown, spacing: 0.6)),
                  ],
                ),
                const SizedBox(height: 10),
                Text.rich(TextSpan(
                  style: Vv.sans(14, height: 1.55),
                  children: [
                    if (m.text.isNotEmpty) ...[
                      const TextSpan(text: 'Your profile shows you take '),
                      TextSpan(text: m.text, style: Vv.sans(14, weight: FontWeight.w800)),
                      const TextSpan(text: '. '),
                    ],
                    const TextSpan(text: 'Herb–medicine combinations need a qualified check, so I won’t advise on this. A Vaidya can review it with your history.'),
                  ],
                )),
                const SizedBox(height: 10),
                VvButton(label: 'Ask a Vaidya now', height: 44, fontSize: 14, onTap: () => AppShell.of(context)?.go(Tabs.vaidya)),
              ],
            ),
          ),
        );
      case _Kind.emergency:
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 330),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Vv.redPale,
              border: Border.all(color: Vv.red, width: 1.5),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('THIS NEEDS A DOCTOR NOW', style: Vv.kicker(Vv.redInk, spacing: 0.6)),
                const SizedBox(height: 8),
                Text('This can be an emergency. Please call 112 or 108 right away, or go to the nearest hospital. For mental-health support call Tele-MANAS 14416.',
                    style: Vv.sans(14, color: Vv.redInk, height: 1.5)),
                const SizedBox(height: 10),
                VvButton(label: 'Call 112', height: 44, fontSize: 14, bg: Vv.red, onTap: () {}),
              ],
            ),
          ),
        );
    }
  }

  Widget _voice() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 240,
                  height: 240,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(width: 240, height: 240, decoration: const BoxDecoration(color: Vv.mint, shape: BoxShape.circle)),
                      Container(width: 184, height: 184, decoration: const BoxDecoration(color: Color(0xFFCFDDC6), shape: BoxShape.circle)),
                      Container(
                        width: 132,
                        height: 132,
                        decoration: const BoxDecoration(color: Vv.green, shape: BoxShape.circle),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (final h in [22.0, 44.0, 62.0, 38.0, 18.0]) ...[
                              Container(width: 6, height: h, decoration: BoxDecoration(color: h == 62 ? Vv.bg : Vv.goldSoft, borderRadius: BorderRadius.circular(6))),
                              if (h != 18) const SizedBox(width: 6),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Text('Listening · हिंदी', style: Vv.sans(13, weight: FontWeight.w700, color: Vv.green)),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text('“Raat ko neend kyun nahi aati?”', textAlign: TextAlign.center, style: Vv.serif(24, italic: true, height: 1.3)),
                ),
                const SizedBox(height: 8),
                Text('Powered by Gemini Live · answers in your language', style: Vv.sans(13, color: Vv.muted)),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _round(Icons.mic_off_outlined, Vv.surface, Vv.ink, border: true, onTap: () {}),
              const SizedBox(width: 20),
              _round(Icons.close_rounded, Vv.red, Vv.surface, onTap: () => setState(() => _mode = 0)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _round(IconData icon, Color bg, Color fg, {bool border = false, VoidCallback? onTap}) => VvTap(
        onTap: onTap,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle, border: border ? Border.all(color: Vv.border3, width: 1.5) : null),
          child: Icon(icon, color: fg, size: 22),
        ),
      );
}
