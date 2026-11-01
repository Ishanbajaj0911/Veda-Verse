import 'package:flutter/material.dart';
import 'package:veda_verse/l10n/lang.dart';
import 'package:veda_verse/screens/help_screen.dart';
import 'package:veda_verse/screens/intake_screen.dart';
import 'package:veda_verse/screens/plans_screen.dart';
import 'package:veda_verse/screens/scan_screen.dart';
import 'package:veda_verse/screens/settings_screen.dart';
import 'package:veda_verse/screens/welcome_screen.dart';
import 'package:veda_verse/state/accounts.dart';
import 'package:veda_verse/state/app_state.dart';
import 'package:veda_verse/theme/vv.dart';

/// Account / profile menu.
class ProfileMenuScreen extends StatelessWidget {
  const ProfileMenuScreen({super.key});

  Future<void> _logOut(BuildContext context) async {
    final nav = Navigator.of(context);
    await Accounts.logOut();
    nav.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const WelcomeScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    final menu = [
      (tr('My Profile'), tr('Personal details & health intake'), Icons.person_outline_rounded, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const IntakeScreen(editing: true)))),
      (tr('My Plans'), tr('Subscription & billing'), Icons.credit_card_outlined, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PlansScreen()))),
      (tr('Health records'), tr('Lab reports, prescriptions, consult notes'), Icons.description_outlined, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScanScreen()))),
      (tr('Language & voice'), 'English · हिंदी', Icons.translate_rounded, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()))),
      (tr('Settings'), tr('Notifications, privacy, data'), Icons.settings_outlined, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()))),
      (tr('Help & safety'), tr('Emergency numbers, support'), Icons.health_and_safety_outlined, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpScreen()))),
    ];
    return Scaffold(
      body: VvFrame(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: s,
            builder: (context, _) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Row(
                    children: [
                      const VvBackButton(),
                      const SizedBox(width: 12),
                      Text(tr('Account'), style: Vv.serif(20, weight: FontWeight.w700)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      VvCard(
                        padding: const EdgeInsets.all(18),
                        radius: 22,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                VvAvatar(initial: s.initial, size: 64, fontSize: 24),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(s.name, style: Vv.serif(19, weight: FontWeight.w700)),
                                      const SizedBox(height: 4),
                                      Text(
                                        [
                                          if (s.age > 0) trf('{age} yrs', {'age': s.age}),
                                          if (s.gender.isNotEmpty) tr(s.gender),
                                          if (s.email.isNotEmpty) s.email,
                                        ].join(' · '),
                                        style: Vv.sans(13, color: Vv.muted),
                                      ),
                                      if (s.accountId.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(trf('Account ID: {id}', {'id': s.accountId}),
                                            style: Vv.sans(12, weight: FontWeight.w700, color: Vv.ink2)),
                                      ],
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(color: Vv.bluePale2, borderRadius: BorderRadius.circular(999)),
                                        child: Text(s.hasPrakriti ? s.prakritiLabel : tr('Prakriti not checked yet'),
                                            style: Vv.sans(12, weight: FontWeight.w800, color: Vv.blueDark)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                _stat('${s.streak}', tr('day streak')),
                                const SizedBox(width: 8),
                                _stat('${s.labReport == null ? 0 : 1}', tr('reports')),
                                const SizedBox(width: 8),
                                _stat('${s.buddyFlags.length}', tr('for Vaidya')),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Vv.deep, borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(tr('CURRENT PLAN · FREE'),
                                      style: Vv.sans(12, weight: FontWeight.w700, color: Vv.onDeepMuted, letterSpacing: Lang.hi ? 0.2 : 1)),
                                  const SizedBox(height: 4),
                                  Text(tr('Unlock unlimited report scans & priority Vaidya slots'),
                                      style: Vv.sans(15, weight: FontWeight.w700, color: Vv.bg, height: 1.35)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            VvTap(
                              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PlansScreen())),
                              child: Container(
                                height: 44,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(color: Vv.gold, borderRadius: BorderRadius.circular(12)),
                                child: Text(tr('Upgrade'), style: Vv.sans(14, weight: FontWeight.w800, color: Vv.deep)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          decoration: BoxDecoration(color: Vv.surface, border: Border.all(color: Vv.border), borderRadius: BorderRadius.circular(20)),
                          child: Column(
                            children: [
                              for (final m in menu)
                                VvTap(
                                  onTap: m.$4,
                                  child: Container(
                                    constraints: const BoxConstraints(minHeight: 60),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Vv.divider))),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(color: Vv.mint, borderRadius: BorderRadius.circular(12)),
                                          child: Icon(m.$3, size: 20, color: Vv.green),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(m.$1, style: Vv.sans(15, weight: FontWeight.w700)),
                                              const SizedBox(height: 2),
                                              Text(m.$2, style: Vv.sans(12, color: Vv.muted)),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.chevron_right_rounded, size: 20, color: Vv.muted),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      VvButton(
                        label: tr('Log out'),
                        height: 52,
                        fontSize: 15,
                        bg: Vv.surface,
                        fg: Vv.red,
                        borderColor: Vv.redBorder,
                        leading: Icons.logout_rounded,
                        onTap: () => _logOut(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(String v, String l) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Vv.bg, borderRadius: BorderRadius.circular(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(v, style: Vv.serif(18, weight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(l, style: Vv.sans(11, weight: FontWeight.w600, color: Vv.muted)),
            ],
          ),
        ),
      );
}
