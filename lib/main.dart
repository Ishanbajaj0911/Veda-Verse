import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:veda_verse/ai/ai_key.dart';
import 'package:veda_verse/app_shell.dart';
import 'package:veda_verse/l10n/lang.dart';
import 'package:veda_verse/screens/welcome_screen.dart';
import 'package:veda_verse/state/accounts.dart';
import 'package:veda_verse/state/app_state.dart';
import 'package:veda_verse/theme/vv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));
  // English or Hindi, as chosen last time.
  await Lang.load();
  // Reopen the account that was logged in last time, with its own data, and
  // keep saving it. Without one the app starts on Welcome.
  final home = await Accounts.restoreSession();
  Accounts.attach(AppState.instance);
  // The user's own Gemini key, if they saved one in Settings.
  await AiKey.load();
  runApp(VedaVerseApp(loggedIn: home));
}

class VedaVerseApp extends StatefulWidget {
  /// True when a logged-in account that finished onboarding was restored.
  final bool loggedIn;
  const VedaVerseApp({super.key, this.loggedIn = false});

  @override
  State<VedaVerseApp> createState() => _VedaVerseAppState();
}

class _VedaVerseAppState extends State<VedaVerseApp> {
  @override
  void initState() {
    super.initState();
    Lang.notifier.addListener(_redraw);
  }

  @override
  void dispose() {
    Lang.notifier.removeListener(_redraw);
    super.dispose();
  }

  /// Rebuilds every screen, including ones further back in the navigation
  /// stack, so a language switch shows everywhere at once and nothing the
  /// user typed or picked is lost.
  void _redraw() {
    void mark(Element e) {
      e.markNeedsBuild();
      e.visitChildren(mark);
    }

    if (mounted) (context as Element).visitChildren(mark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VedaVerse',
      debugShowCheckedModeBanner: false,
      theme: Vv.theme(),
      home: widget.loggedIn ? const AppShell() : const WelcomeScreen(),
    );
  }
}
