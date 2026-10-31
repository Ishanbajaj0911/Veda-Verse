import 'package:flutter/material.dart';
import 'package:veda_verse/screens/consent_screen.dart';
import 'package:veda_verse/theme/vv.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  int _role = 0; // 0 patient, 1 partner, 2 admin
  int _lang = 0;

  static const _roles = [
    ('Patient', 'Care for me'),
    ('Partner', 'Vaidya · yoga'),
    ('Admin', 'Team'),
  ];

  void _continue() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ConsentScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final ph = ['you@example.com', 'Email from your invite', 'name@vedaverse.app'][_role];
    return Scaffold(
      backgroundColor: Vv.deep,
      resizeToAvoidBottomInset: true,
      body: VvFrame(
        color: Vv.deep,
        child: Column(
          children: [
            // Hero
            ClipRect(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const VvRings(size: 300, right: -90, top: -60, opacity: 0.18, cross: true),
                  Padding(
                    padding: EdgeInsets.fromLTRB(28, 28 + MediaQuery.of(context).padding.top, 28, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(color: Vv.bg, borderRadius: BorderRadius.circular(15)),
                              child: const Center(
                                child: VvLogo(size: 32, leaf: Vv.green, sides: Color(0xFF7FA88F)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SerifTitle('Veda', 'Verse', size: 26, color: Vv.bg, letterSpacing: -0.2),
                                const SizedBox(height: 2),
                                Text('Your Ayurvedic AI Buddy',
                                    style: Vv.sans(12, weight: FontWeight.w700, color: Vv.goldSoft, letterSpacing: 0.6)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        Text.rich(
                          TextSpan(
                            style: Vv.serif(36, weight: FontWeight.w500, color: Vv.bg, height: 1.08, letterSpacing: -0.4),
                            children: [
                              const TextSpan(text: 'Your body has a rhythm.\n'),
                              TextSpan(
                                text: 'Let’s learn it.',
                                style: Vv.serif(36, weight: FontWeight.w500, italic: true, color: Vv.goldLight, height: 1.08),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Ayurveda-guided wellness, personalised by AI and checked by real Vaidyas.',
                          style: Vv.sans(15, color: Vv.onDeepMuted3, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Sheet
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Vv.bg,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Flexible(child: SerifTitle('Welcome ', 'back', size: 26)),
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(color: Vv.mint, borderRadius: BorderRadius.circular(999)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _langBtn('EN', 0),
                                _langBtn('हिंदी', 1),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: Vv.shade, borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          children: [
                            for (var i = 0; i < 3; i++) ...[
                              if (i > 0) const SizedBox(width: 6),
                              Expanded(child: _roleBtn(i)),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _field(_role == 0 ? 'Email' : 'Work email', ph, false),
                      const SizedBox(height: 14),
                      _field('Password', '••••••••', true),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text('Forgot password?', style: Vv.sans(13, weight: FontWeight.w600, color: Vv.green)),
                      ),
                      const SizedBox(height: 14),
                      if (_role == 0) ...[
                        VvButton(label: 'Log in', trailing: Icons.arrow_forward_rounded, onTap: _continue),
                        const SizedBox(height: 14),
                        VvButton(
                          label: 'Continue with Google',
                          bg: Vv.surface,
                          fg: Vv.ink,
                          height: 52,
                          fontSize: 15,
                          weight: FontWeight.w600,
                          leading: Icons.g_mobiledata_rounded,
                          borderColor: Vv.border3,
                          onTap: _continue,
                        ),
                        const SizedBox(height: 22),
                        Center(
                          child: Text.rich(
                            TextSpan(
                              style: Vv.sans(14, color: Vv.ink2),
                              children: [
                                const TextSpan(text: 'New here? '),
                                TextSpan(
                                  text: 'Create an account',
                                  style: Vv.sans(14, weight: FontWeight.w700, color: Vv.green),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else if (_role == 1) ...[
                        VvButton(label: 'Log in to Partner app', trailing: Icons.arrow_forward_rounded, onTap: () {}),
                        const SizedBox(height: 14),
                        _infoBox(
                          Vv.mint,
                          Vv.green,
                          Icons.verified_user_outlined,
                          'For Vaidyas, Ayurvedic dietitians, yoga studios and NGO partners. Your login is created by VedaVerse after we verify your registration.',
                        ),
                        const SizedBox(height: 22),
                        Center(
                          child: Text.rich(
                            TextSpan(
                              style: Vv.sans(14, color: Vv.ink2),
                              children: [
                                const TextSpan(text: 'Want to join? '),
                                TextSpan(text: 'Apply as a partner', style: Vv.sans(14, weight: FontWeight.w700, color: Vv.green)),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        VvButton(label: 'Log in to Admin console', bg: Vv.deep, trailing: Icons.arrow_forward_rounded, onTap: () {}),
                        const SizedBox(height: 14),
                        _infoBox(
                          Vv.goldPale,
                          Vv.brown,
                          Icons.lock_outline_rounded,
                          'VedaVerse team only. A 6-digit code is sent to your phone after your password. Every admin action is logged.',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoBox(Color bg, Color iconColor, IconData icon, String text) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.only(top: 1), child: Icon(icon, size: 18, color: iconColor)),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: Vv.sans(13, color: Vv.ink2, height: 1.5))),
          ],
        ),
      );

  Widget _langBtn(String l, int i) {
    final on = _lang == i;
    return VvTap(
      onTap: () => setState(() => _lang = i),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: on ? Vv.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(l, style: Vv.sans(13, weight: FontWeight.w600, color: on ? Vv.ink : Vv.ink2)),
      ),
    );
  }

  Widget _roleBtn(int i) {
    final on = _role == i;
    return VvTap(
      onTap: () => setState(() => _role = i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: const BoxConstraints(minHeight: 52),
        decoration: BoxDecoration(
          color: on ? Vv.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: on ? const [BoxShadow(color: Color(0x1F17251C), blurRadius: 8, offset: Offset(0, 2))] : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_roles[i].$1, style: Vv.sans(14, weight: FontWeight.w800, color: on ? Vv.deep : Vv.muted)),
            const SizedBox(height: 1),
            Opacity(
              opacity: 0.8,
              child: Text(_roles[i].$2, style: Vv.sans(11, weight: FontWeight.w600, color: on ? Vv.deep : Vv.muted)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, String hint, bool obscure) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Vv.sans(13, weight: FontWeight.w600, color: Vv.ink2)),
          const SizedBox(height: 6),
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Vv.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Vv.border3, width: 1.5),
            ),
            alignment: Alignment.centerLeft,
            child: TextField(
              obscureText: obscure,
              keyboardType: obscure ? TextInputType.text : TextInputType.emailAddress,
              style: Vv.sans(15, color: Vv.ink),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: Vv.sans(15, color: Vv.disabled),
              ),
            ),
          ),
        ],
      );
}
