import 'package:flutter/material.dart';
import 'package:veda_verse/app_shell.dart';
import 'package:veda_verse/l10n/lang.dart';
import 'package:veda_verse/screens/consent_screen.dart';
import 'package:veda_verse/state/accounts.dart';
import 'package:veda_verse/state/app_state.dart';
import 'package:veda_verse/theme/vv.dart';

/// Log in or create an account. Email and password are required; each
/// account gets its own id and its own saved data on this phone.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  int _role = 0; // 0 patient, 1 partner, 2 admin
  bool _signUp = false;
  bool _hidden = true;
  bool _busy = false;
  String? _error;
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  static const _roles = [
    ('Patient', 'Care for me'),
    ('Partner', 'Vaidya · yoga'),
    ('Admin', 'Team'),
  ];

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _submit() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = _signUp
        ? await Accounts.signUp(_email.text, _password.text, confirm: _confirm.text)
        : await Accounts.logIn(_email.text, _password.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = err;
    });
    if (err != null) return;
    final nav = Navigator.of(context);
    if (AppState.instance.onboarded) {
      nav.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const AppShell()), (_) => false);
    } else {
      nav.push(MaterialPageRoute(builder: (_) => const ConsentScreen()));
    }
  }

  void _switchMode() => setState(() {
        _signUp = !_signUp;
        _error = null;
        _confirm.clear();
      });

  @override
  Widget build(BuildContext context) {
    final ph = ['you@example.com', tr('Email from your invite'), 'name@vedaverse.app'][_role];
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
                            Flexible(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SerifTitle('Veda', 'Verse', size: 26, color: Vv.bg, letterSpacing: -0.2),
                                const SizedBox(height: 2),
                                Text(tr('Your Ayurvedic AI Buddy'),
                                    style: Vv.sans(12, weight: FontWeight.w700, color: Vv.goldSoft, letterSpacing: 0.6)),
                              ],
                            )),
                          ],
                        ),
                        const SizedBox(height: 28),
                        Text.rich(
                          TextSpan(
                            style: Vv.serif(Lang.hi ? 30 : 36, weight: FontWeight.w500, color: Vv.bg, height: Lang.hi ? 1.3 : 1.08, letterSpacing: -0.4),
                            children: [
                              TextSpan(text: tr('Your body has a rhythm.\n')),
                              TextSpan(
                                text: tr('Let’s learn it.'),
                                style: Vv.serif(Lang.hi ? 30 : 36, weight: FontWeight.w500, italic: true, color: Vv.goldLight, height: Lang.hi ? 1.3 : 1.08),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          tr('Ayurveda-guided wellness, personalised by AI and checked by real Vaidyas.'),
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
                          Flexible(
                            child: _signUp && _role == 0
                                ? SerifTitle(tr('Create your '), tr('account'), size: 26)
                                : SerifTitle(tr('Welcome '), tr('back'), size: 26),
                          ),
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(color: Vv.mint, borderRadius: BorderRadius.circular(999)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _langBtn('EN', Lang.en),
                                _langBtn('हिंदी', Lang.hiCode),
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
                      _field(_role == 0 ? tr('Email') : tr('Work email'), ph, _email, email: true),
                      const SizedBox(height: 14),
                      _field(tr('Password'), _signUp ? tr('At least 6 characters') : '••••••••', _password),
                      if (_signUp && _role == 0) ...[
                        const SizedBox(height: 14),
                        _field(tr('Confirm password'), tr('Type it again'), _confirm),
                      ],
                      if (!_signUp) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: VvTap(
                            onTap: () => _toast(tr('Your password is saved only on this phone. If you forgot it, create a new account.')),
                            child: Text(tr('Forgot password?'), style: Vv.sans(13, weight: FontWeight.w600, color: Vv.green)),
                          ),
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(color: Vv.redPale, borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, size: 18, color: Vv.redInk),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(tr(_error!), style: Vv.sans(13, weight: FontWeight.w700, color: Vv.redInk, height: 1.4)),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      if (_role == 0) ...[
                        VvButton(
                          label: _busy ? tr('Please wait…') : (_signUp ? tr('Create account') : tr('Log in')),
                          trailing: Icons.arrow_forward_rounded,
                          onTap: _busy ? null : _submit,
                        ),
                        const SizedBox(height: 14),
                        VvButton(
                          label: tr('Continue with Google'),
                          bg: Vv.surface,
                          fg: Vv.ink,
                          height: 52,
                          fontSize: 15,
                          weight: FontWeight.w600,
                          leading: Icons.g_mobiledata_rounded,
                          borderColor: Vv.border3,
                          onTap: () => _toast(tr('Google sign-in is coming soon. Please use email and password.')),
                        ),
                        const SizedBox(height: 22),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(_signUp ? tr('Already have an account? ') : tr('New here? '), style: Vv.sans(14, color: Vv.ink2)),
                            VvTap(
                              onTap: _switchMode,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Text(
                                  _signUp ? tr('Log in') : tr('Create an account'),
                                  style: Vv.sans(14, weight: FontWeight.w700, color: Vv.green),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else if (_role == 1) ...[
                        VvButton(
                          label: tr('Log in to Partner app'),
                          trailing: Icons.arrow_forward_rounded,
                          onTap: () => _toast(tr('The Partner app is not part of this demo yet.')),
                        ),
                        const SizedBox(height: 14),
                        _infoBox(
                          Vv.mint,
                          Vv.green,
                          Icons.verified_user_outlined,
                          tr('For Vaidyas, Ayurvedic dietitians, yoga studios and NGO partners. Your login is created by VedaVerse after we verify your registration.'),
                        ),
                        const SizedBox(height: 22),
                        Center(
                          child: Text.rich(
                            TextSpan(
                              style: Vv.sans(14, color: Vv.ink2),
                              children: [
                                TextSpan(text: tr('Want to join? ')),
                                TextSpan(text: tr('Apply as a partner'), style: Vv.sans(14, weight: FontWeight.w700, color: Vv.green)),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        VvButton(
                          label: tr('Log in to Admin console'),
                          bg: Vv.deep,
                          trailing: Icons.arrow_forward_rounded,
                          onTap: () => _toast(tr('The Admin console is not part of this demo yet.')),
                        ),
                        const SizedBox(height: 14),
                        _infoBox(
                          Vv.goldPale,
                          Vv.brown,
                          Icons.lock_outline_rounded,
                          tr('VedaVerse team only. A 6-digit code is sent to your phone after your password. Every admin action is logged.'),
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

  Widget _langBtn(String l, String code) {
    final on = Lang.code == code;
    return VvTap(
      onTap: () => Lang.set(code),
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
      onTap: () => setState(() {
        _role = i;
        _error = null;
      }),
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
            Text(tr(_roles[i].$1), style: Vv.sans(14, weight: FontWeight.w800, color: on ? Vv.deep : Vv.muted)),
            const SizedBox(height: 1),
            Opacity(
              opacity: 0.8,
              child: Text(tr(_roles[i].$2), style: Vv.sans(11, weight: FontWeight.w600, color: on ? Vv.deep : Vv.muted)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, String hint, TextEditingController c, {bool email = false}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(TextSpan(children: [
            TextSpan(text: label, style: Vv.sans(13, weight: FontWeight.w600, color: Vv.ink2)),
            TextSpan(text: ' *', style: Vv.sans(13, weight: FontWeight.w800, color: Vv.red)),
          ])),
          const SizedBox(height: 6),
          Container(
            height: 52,
            padding: EdgeInsets.only(left: 16, right: email ? 16 : 4),
            decoration: BoxDecoration(
              color: Vv.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Vv.border3, width: 1.5),
            ),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: c,
                    obscureText: !email && _hidden,
                    autocorrect: false,
                    enableSuggestions: email,
                    keyboardType: email ? TextInputType.emailAddress : TextInputType.visiblePassword,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                    onSubmitted: (_) => _role == 0 && !email && (c == _confirm || !_signUp) ? _submit() : null,
                    style: Vv.sans(15, color: Vv.ink),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: hint,
                      hintStyle: Vv.sans(15, color: Vv.disabled),
                    ),
                  ),
                ),
                if (!email)
                  IconButton(
                    tooltip: _hidden ? tr('Show password') : tr('Hide password'),
                    onPressed: () => setState(() => _hidden = !_hidden),
                    icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20, color: Vv.muted),
                  ),
              ],
            ),
          ),
        ],
      );
}
