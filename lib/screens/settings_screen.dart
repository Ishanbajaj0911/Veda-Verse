import 'package:flutter/material.dart';
import 'package:veda_verse/l10n/lang.dart';
import 'package:veda_verse/screens/my_data_screen.dart';
import 'package:veda_verse/screens/welcome_screen.dart';
import 'package:veda_verse/state/accounts.dart';
import 'package:veda_verse/state/app_state.dart';
import 'package:veda_verse/theme/vv.dart';
import 'package:veda_verse/widgets/ai_key_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final s = AppState.instance;

  /// Language codes in the order of the segment labels below.
  static const _codes = [Lang.en, Lang.hiCode];

  @override
  Widget build(BuildContext context) {
    final toggles = [
      (tr('Share summary with booked Vaidya'), tr('Only for the consult you book'), s.consentVaidya, (bool v) => s.update((st) => st.consentVaidya = v)),
      (tr('Help improve the AI'), tr('Anonymised, optional'), s.consentAi, (bool v) => s.update((st) => st.consentAi = v)),
      (tr('Routine reminders'), tr('Dinacharya and session alerts'), s.consentNotify, (bool v) => s.update((st) => st.consentNotify = v)),
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
                    Text(tr('Settings'), style: Vv.serif(25)),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  children: [
                    Text(tr('LANGUAGE & VOICE'), style: Vv.kicker(Vv.ink2)),
                    const SizedBox(height: 8),
                    // Switches every screen of the app at once.
                    VvSegments(
                      labels: const ['English', 'हिंदी'],
                      index: _codes.indexOf(Lang.code),
                      onChanged: (i) => Lang.set(_codes[i]),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(tr('The whole app, Ayu Buddy and voice use this language.'), style: Vv.sans(12, color: Vv.muted)),
                    ),
                    const SizedBox(height: 18),
                    Text(tr('AI ASSISTANT'), style: Vv.kicker(Vv.ink2)),
                    const SizedBox(height: 8),
                    const AiKeyCard(),
                    const SizedBox(height: 18),
                    Text(tr('PRIVACY & CONSENT'), style: Vv.kicker(Vv.ink2)),
                    const SizedBox(height: 8),
                    VvCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Column(
                        children: [
                          for (final t in toggles)
                            Container(
                              constraints: const BoxConstraints(minHeight: 64),
                              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Vv.divider))),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(t.$1, style: Vv.sans(14, weight: FontWeight.w700)),
                                        const SizedBox(height: 2),
                                        Text(t.$2, style: Vv.sans(12, color: Vv.muted)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  VvSwitch(width: 48, height: 30, on: t.$3, onTap: () => setState(() => t.$4(!t.$3))),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(tr('Withdrawing consent takes effect immediately.'), style: Vv.sans(12, color: Vv.muted)),
                    ),
                    const SizedBox(height: 18),
                    Text(tr('YOUR DATA'), style: Vv.kicker(Vv.ink2)),
                    const SizedBox(height: 8),
                    VvCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Column(
                        children: [
                          _row(tr('Download my data'), true, () => const MyDataScreen()),
                          _row(tr('AI answer history (audit log)'), false, () => const AiHistoryScreen()),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    VvButton(
                      label: tr('Delete all my data'),
                      height: 52,
                      fontSize: 15,
                      bg: Vv.surface,
                      fg: Vv.red,
                      borderColor: Vv.redBorder,
                      leading: Icons.delete_outline_rounded,
                      onTap: _confirmDelete,
                    ),
                    const SizedBox(height: 8),
                    Text(tr('Your right to erasure under India’s DPDP Act.'), textAlign: TextAlign.center, style: Vv.sans(12, color: Vv.muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Right to erasure: removes this account and all its data from the phone.
  Future<void> _confirmDelete() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(tr('Delete all my data?')),
        content: Text(tr('Your account, profile, quiz result, bookings and saved items will be removed from this phone. This can’t be undone.')),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(false), child: Text(tr('Keep my data'))),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: Text(tr('Delete'), style: Vv.sans(14, weight: FontWeight.w800, color: Vv.red)),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    final nav = Navigator.of(context);
    await Accounts.deleteCurrent();
    nav.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const WelcomeScreen()), (_) => false);
  }

  Widget _row(String t, bool border, Widget Function() page) => VvTap(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page())),
        child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        decoration: BoxDecoration(border: border ? const Border(bottom: BorderSide(color: Vv.divider)) : null),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text(t, style: Vv.sans(14, weight: FontWeight.w700))),
            const Icon(Icons.chevron_right_rounded, size: 20, color: Vv.muted),
          ],
        ),
        ),
      );
}
