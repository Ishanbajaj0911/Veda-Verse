import 'package:flutter/material.dart';
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
  String _lang = 'हिंदी + English';

  @override
  Widget build(BuildContext context) {
    final toggles = [
      ('Share summary with booked Vaidya', 'Only for the consult you book', s.consentVaidya, (bool v) => s.consentVaidya = v),
      ('Help improve the AI', 'Anonymised, optional', s.consentAi, (bool v) => s.consentAi = v),
      ('Routine reminders', 'Dinacharya and session alerts', s.consentNotify, (bool v) => s.consentNotify = v),
    ];
    final langs = ['English', 'हिंदी', 'हिंदी + English'];
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
                    Text('Settings', style: Vv.serif(25)),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  children: [
                    Text('AI ASSISTANT', style: Vv.kicker(Vv.ink2)),
                    const SizedBox(height: 8),
                    const AiKeyCard(),
                    const SizedBox(height: 18),
                    Text('PRIVACY & CONSENT', style: Vv.kicker(Vv.ink2)),
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
                      child: Text('Withdrawing consent takes effect immediately.', style: Vv.sans(12, color: Vv.muted)),
                    ),
                    const SizedBox(height: 18),
                    Text('LANGUAGE & VOICE', style: Vv.kicker(Vv.ink2)),
                    const SizedBox(height: 8),
                    VvSegments(labels: langs, index: langs.indexOf(_lang), onChanged: (i) => setState(() => _lang = langs[i])),
                    const SizedBox(height: 18),
                    Text('YOUR DATA', style: Vv.kicker(Vv.ink2)),
                    const SizedBox(height: 8),
                    VvCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Column(
                        children: [
                          _row('Download my data', true),
                          _row('AI answer history (audit log)', false),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    VvButton(
                      label: 'Delete all my data',
                      height: 52,
                      fontSize: 15,
                      bg: Vv.surface,
                      fg: Vv.red,
                      borderColor: Vv.redBorder,
                      leading: Icons.delete_outline_rounded,
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('One-tap erasure will be wired to Firestore'))),
                    ),
                    const SizedBox(height: 8),
                    Text('Your right to erasure under India’s DPDP Act.', textAlign: TextAlign.center, style: Vv.sans(12, color: Vv.muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String t, bool border) => Container(
        constraints: const BoxConstraints(minHeight: 56),
        decoration: BoxDecoration(border: border ? const Border(bottom: BorderSide(color: Vv.divider)) : null),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(t, style: Vv.sans(14, weight: FontWeight.w700)),
            const Icon(Icons.chevron_right_rounded, size: 20, color: Vv.muted),
          ],
        ),
      );
}
