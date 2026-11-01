import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:veda_verse/l10n/lang.dart';
import 'package:veda_verse/theme/vv.dart';

/// Help & safety: India emergency numbers (tap to call), what VedaVerse is
/// and isn't, and how to reach the team.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const supportEmail = 'vedaverse.support@gmail.com';

  Future<void> _open(BuildContext context, Uri uri, String fallback) async {
    var ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(fallback)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final numbers = [
      ('108', tr('Ambulance'), tr('Chest pain, trouble breathing, fainting, heavy bleeding, stroke signs.'), Vv.red, Vv.redPale),
      ('112', tr('All emergencies'), tr('Police, fire and ambulance, from any phone.'), Vv.red, Vv.redPale),
      ('14416', tr('Tele-MANAS'), tr('Free, 24x7 mental health support. Talk to someone if you feel low or think of hurting yourself.'),
          Vv.blue, Vv.bluePale),
    ];
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
                    Expanded(child: Text(tr('Help & safety'), style: Vv.serif(25))),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    Text(tr('EMERGENCY NUMBERS · INDIA'), style: Vv.kicker(Vv.ink2, spacing: Lang.hi ? 0.4 : 1.2)),
                    const SizedBox(height: 8),
                    for (final n in numbers) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: n.$5, borderRadius: BorderRadius.circular(18)),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${n.$1} · ${n.$2}', style: Vv.sans(16, weight: FontWeight.w800, color: n.$4)),
                                  const SizedBox(height: 4),
                                  Text(n.$3, style: Vv.sans(13, color: Vv.ink2, height: 1.45)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Semantics(
                              button: true,
                              label: trf('Call {number}', {'number': n.$1}),
                              child: VvTap(
                                onTap: () => _open(context, Uri(scheme: 'tel', path: n.$1),
                                    trf('Please dial {number} from your phone.', {'number': n.$1})),
                                child: Container(
                                  height: 48,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(color: n.$4, borderRadius: BorderRadius.circular(14)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.call_rounded, size: 18, color: Vv.surface),
                                      const SizedBox(width: 6),
                                      Text(tr('Call'), style: Vv.sans(15, weight: FontWeight.w800, color: Vv.surface)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 8),
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
                          Text(tr('What VedaVerse is — and isn’t'), style: Vv.sans(14, weight: FontWeight.w800, color: Vv.brown)),
                          const SizedBox(height: 8),
                          Text(
                            tr('A wellness guide based on Ayurveda. It does not diagnose, treat or cure disease, and AI never prescribes. Medicines and herbs are advised only by registered Vaidyas. Don’t stop any current treatment without your doctor.'),
                            style: Vv.sans(13, color: Vv.brownDark, height: 1.55),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(tr('HOW AYU BUDDY KEEPS YOU SAFE'), style: Vv.kicker(Vv.ink2, spacing: Lang.hi ? 0.4 : 1.2)),
                    const SizedBox(height: 8),
                    VvCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final line in [
                            tr('Every question is checked on your phone before it reaches the AI.'),
                            tr('Questions about medicines, herbs, doses or supplements go to a Vaidya, not the AI.'),
                            tr('Emergency words show the 108 / Tele-MANAS card at once.'),
                            tr('Every AI answer is checked again before you see it.'),
                          ]) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(Icons.check_circle_outline_rounded, size: 18, color: Vv.green),
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Text(line, style: Vv.sans(13.5, color: Vv.ink2, height: 1.45))),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(tr('CONTACT US'), style: Vv.kicker(Vv.ink2, spacing: Lang.hi ? 0.4 : 1.2)),
                    const SizedBox(height: 8),
                    VvButton(
                      label: tr('Email the VedaVerse team'),
                      height: 52,
                      fontSize: 15,
                      bg: Vv.surface,
                      fg: Vv.green,
                      borderColor: Vv.green,
                      leading: Icons.mail_outline_rounded,
                      onTap: () => _open(
                        context,
                        Uri(scheme: 'mailto', path: supportEmail, query: 'subject=VedaVerse%20help'),
                        trf('Write to us at {email}', {'email': supportEmail}),
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
}
