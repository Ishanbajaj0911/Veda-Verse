import 'package:veda_verse/l10n/hi_ai.dart';
import 'package:veda_verse/l10n/hi_care.dart';
import 'package:veda_verse/l10n/hi_core.dart';
import 'package:veda_verse/l10n/hi_engine.dart';
import 'package:veda_verse/l10n/hi_home.dart';
import 'package:veda_verse/l10n/hi_quiz.dart';

/// English text -> Hindi, merged from one file per area of the app so each
/// area can be translated on its own.
final Map<String, String> hiStrings = {
  ...hiCore,
  ...hiHome,
  ...hiQuiz,
  ...hiAi,
  ...hiCare,
  ...hiEngine,
};
