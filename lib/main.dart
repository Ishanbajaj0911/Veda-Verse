import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:veda_verse/screens/welcome_screen.dart';
import 'package:veda_verse/theme/vv.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));
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
