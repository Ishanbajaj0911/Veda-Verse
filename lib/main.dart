import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:veda_verse/ai/ai_key.dart';
import 'package:veda_verse/screens/welcome_screen.dart';
import 'package:veda_verse/state/app_state.dart';
import 'package:veda_verse/state/quiz_store.dart';
import 'package:veda_verse/theme/vv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));
  // Bring back the saved quiz result and today's ticks, then keep saving.
  await QuizStore.attach(AppState.instance);
  // The user's own Gemini key, if they saved one in Settings.
  await AiKey.load();
  runApp(const VedaVerseApp());
}

class VedaVerseApp extends StatelessWidget {
  const VedaVerseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VedaVerse',
      debugShowCheckedModeBanner: false,
      theme: Vv.theme(),
      home: const WelcomeScreen(),
    );
  }
}
