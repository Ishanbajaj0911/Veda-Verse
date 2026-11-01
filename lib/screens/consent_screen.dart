import 'package:flutter/material.dart';
import 'package:veda_verse/l10n/lang.dart';
import 'package:veda_verse/screens/intake_screen.dart';
import 'package:veda_verse/state/app_state.dart';
import 'package:veda_verse/theme/vv.dart';

class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  final s = AppState.instance;

  /// Must be ticked by the user; never pre-ticked.
  bool _adult = false;
  bool _warn = false;
  final _adultKey = GlobalKey();

  void _continue() {
    if (!_adult) {
      setState(() => _warn = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _adultKey.currentContext;
        if (ctx != null && ctx.mounted) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 250), alignment: 0.5);
      });
      return;
    }
    s.update((_) {});
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const IntakeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        tr('Store my health profile'),
        tr('Encrypted, used only to personalise your guidance. Delete anytime.'),
        true,
        s.consentStore,
        (bool v) {}
      ),
      (
        tr('Share with a Vaidya when I book'),
        tr('Only the Vaidya you choose sees your summary, only for that consult.'),
        false,
        s.consentVaidya,
        (bool v) => s.consentVaidya = v
      ),
      (
        tr('Help improve the AI (anonymised)'),
        tr('Your name and contact are removed. Fully optional.'),
        false,
        s.consentAi,
        (bool v) => s.consentAi = v
      ),
      (
        tr('Daily routine reminders'),
        tr('Dinacharya nudges and session alerts.'),
        false,
        s.consentNotify,
        (bool v) => s.consentNotify = v
      ),
    ];

    return Scaffold(
      body: VvFrame(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(color: Vv.deep, borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.shield_outlined, color: Vv.goldSoft, size: 26),
                    ),
                    const SizedBox(height: 12),
                    SerifTitle(tr('Your health data, '), tr('your control'), size: Lang.hi ? 26 : 30, height: Lang.hi ? 1.3 : 1.15, letterSpacing: -0.3),
                    const SizedBox(height: 12),
                    Text(
                      tr('Before we start, choose what VedaVerse may do. You can change or withdraw any of these anytime in Settings.'),
                      style: Vv.sans(14, color: Vv.ink2, height: 1.5),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final it in items) ...[
                      VvCard(
                        padding: const EdgeInsets.all(14),
                        radius: 18,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 8,
                                    children: [
                                      Text(it.$1, style: Vv.sans(14, weight: FontWeight.w700)),
                                      if (it.$3)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(color: Vv.goldPale, borderRadius: BorderRadius.circular(999)),
                                          child: Text(tr('Required'), style: Vv.sans(11, weight: FontWeight.w800, color: Vv.brown)),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(it.$2, style: Vv.sans(12, color: Vv.muted, height: 1.45)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            VvSwitch(
                              on: it.$4,
                              onTap: it.$3 ? null : () => setState(() => it.$5(!it.$4)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Vv.cream,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Vv.goldBorder, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tr('What VedaVerse is — and isn’t'), style: Vv.sans(13, weight: FontWeight.w800, color: Vv.brown)),
                          const SizedBox(height: 8),
                          Text(
                            tr('A wellness guide based on Ayurveda. It does not diagnose, treat or cure disease, and AI never prescribes. Medicines and herbs are advised only by registered Vaidyas. Don’t stop any current treatment without your doctor.'),
                            style: Vv.sans(12, color: Vv.brownDark, height: 1.55),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(color: Vv.redPale, borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 18, color: Vv.redInk),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(tr('Medical emergency? Call 112 / 108 — not this app.'),
                                style: Vv.sans(13, weight: FontWeight.w700, color: Vv.redInk)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    VvTap(
                      key: _adultKey,
                      onTap: () => setState(() {
                        _adult = !_adult;
                        _warn = false;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        decoration: _warn
                            ? BoxDecoration(color: Vv.redPale, borderRadius: BorderRadius.circular(12), border: Border.all(color: Vv.redBorder))
                            : null,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: Checkbox(
                                value: _adult,
                                activeColor: Vv.green,
                                onChanged: (v) => setState(() {
                                  _adult = v ?? false;
                                  _warn = false;
                                }),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text.rich(
                                TextSpan(children: [
                                  TextSpan(text: tr('I am 18 or older. (Under 18? A parent or guardian must consent.)')),
                                  TextSpan(text: ' *', style: Vv.sans(13, weight: FontWeight.w800, color: Vv.red)),
                                ]),
                                style: Vv.sans(13, color: Vv.ink2, height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_warn)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
                        child: Text(tr('Please tick this box to continue.'),
                            style: Vv.sans(12.5, weight: FontWeight.w700, color: Vv.redInk)),
                      ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(Lang.hi ? tr('Read full privacy notice') : 'Read full privacy notice · हिंदी में पढ़ें',
                          style: Vv.sans(13, weight: FontWeight.w700, color: Vv.green)),
                    ),
                  ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: VvButton(
                  label: _warn ? tr('Tick the 18+ box first') : tr('I agree, continue'),
                  height: 56,
                  bg: _warn ? Vv.redPale : Vv.green,
                  fg: _warn ? Vv.redInk : Vv.surface,
                  trailing: Icons.arrow_forward_rounded,
                  onTap: _continue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
