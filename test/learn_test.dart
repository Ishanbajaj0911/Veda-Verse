// Learn tab: articles open from the list and the big card, bookmarks and the
// Saved filter, newsletter email check, and every article screen in English
// and Hindi at phone size (390x844) without overflow or leftover English.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veda_verse/content/articles.dart';
import 'package:veda_verse/l10n/lang.dart';
import 'package:veda_verse/screens/article_screen.dart';
import 'package:veda_verse/screens/learn_screen.dart';
import 'package:veda_verse/state/app_state.dart';
import 'package:veda_verse/theme/vv.dart';

/// Same list as test/screens_hindi_test.dart: words that may stay in Latin
/// letters in Hindi (brand names, people's names, units).
const allowedLatin = [
  'you@example.com', 'Google Pay', 'VedaVerse', 'Veda', 'Verse', 'Ayu Buddy', 'Gemini', 'Google', 'Tele-MANAS', 'MANAS',
  'Aarav', 'Mehta', 'Amlodipine', 'Peanuts', 'example.com', 'vedaverse.app',
  'Dr.', 'Rohan', 'Kapoor', 'Suresh', 'Paliwal', 'Meera', 'Sharma', 'Anjali', 'Nair', 'BAMS', 'PCOS', 'UPI', 'DPDP',
  'English',
  'mg/dL', 'mIU/L', 'g/dL', 'mmol/L', 'pg/mL', 'ng/mL', 'HbA1c', 'TSH', 'Hemoglobin', 'Haemoglobin',
];

/// Visible text that still has English words in it.
List<String> englishLeft(WidgetTester t) {
  final out = <String>{};
  for (final r in t.widgetList<RichText>(find.byType(RichText))) {
    var s = r.text.toPlainText();
    for (final a in allowedLatin) {
      s = s.replaceAll(a, ' ');
    }
    if (RegExp('[A-Za-z]{3,}').hasMatch(s)) out.add(r.text.toPlainText().replaceAll('\n', ' '));
  }
  return out.toList();
}

Future<void> _loadFonts() async {
  final romie = FontLoader('Romie');
  for (final f in ['Romie-300', 'Romie-300Italic', 'Romie-500', 'Romie-500Italic', 'Romie-700']) {
    romie.addFont(rootBundle.load('assets/fonts/$f.otf'));
  }
  await romie.load();
  final manrope = FontLoader('Manrope')..addFont(rootBundle.load('assets/fonts/Manrope-Variable.ttf'));
  await manrope.load();
}

Future<void> _pump(WidgetTester t, Widget home) async {
  await t.pumpWidget(MaterialApp(debugShowCheckedModeBanner: false, theme: Vv.theme(), home: home));
  await t.pump(const Duration(milliseconds: 400));
}

Future<void> _pumpLearn(WidgetTester t) => _pump(t, const Scaffold(body: LearnScreen()));

/// Taps [f], scrolling the Learn list up or down first if it isn't built yet.
Future<void> _tap(WidgetTester t, Finder f) async {
  final list = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down);
  for (final delta in [-300.0, 300.0]) {
    if (f.evaluate().isNotEmpty || list.evaluate().isEmpty) break;
    try {
      await t.scrollUntilVisible(f, delta, scrollable: list.first, maxScrolls: 12);
    } on StateError {
      // Not that way; try the other direction.
    }
  }
  await t.ensureVisible(f);
  await t.pump();
  await t.tap(f);
  await t.pump();
  await t.pump(const Duration(milliseconds: 500));
}

int _words(Iterable<L> ps) => ps.map((p) => p.en.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length).fold(0, (a, b) => a + b);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(_loadFonts);

  setUp(() {
    Lang.notifier.value = Lang.en;
    AppState.instance.savedArticles = {};
    final v = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    v.physicalSize = const Size(390, 844);
    v.devicePixelRatio = 1;
  });
  tearDown(() {
    Lang.notifier.value = Lang.en;
    AppState.instance.savedArticles = {};
  });

  group('content', () {
    test('about eight articles with unique ids and a hero', () {
      expect(articles.length, greaterThanOrEqualTo(8));
      expect(articles.map((a) => a.id).toSet().length, articles.length);
      expect(articleById(heroArticleId), isNotNull);
      for (final a in articles) {
        expect(['Journal', 'Video', 'Guide'], contains(a.category), reason: a.id);
      }
    });

    test('each body is 120 to 220 words and every text has Hindi', () {
      for (final a in articles) {
        final n = _words(a.body);
        expect(n, inInclusiveRange(120, 220), reason: '${a.id}: $n words');
        for (final l in [a.title, a.kind, ...a.body, ...a.steps, ?a.caution]) {
          expect(l.en.trim(), isNotEmpty, reason: a.id);
          expect(l.hi.trim(), isNotEmpty, reason: a.id);
          expect(RegExp('[A-Za-z]{3,}').hasMatch(l.hi.replaceAll('VedaVerse', '')), isFalse, reason: '${a.id}: ${l.hi}');
        }
      }
    });

    test('videos have steps and a YouTube search; practices carry a caution', () {
      for (final a in articles.where((a) => a.isVideo)) {
        expect(a.steps, isNotEmpty, reason: a.id);
        final u = a.youtubeUri!;
        expect(u.host, 'www.youtube.com');
        expect(u.path, '/results');
        expect(u.queryParameters['search_query'], isNotEmpty);
      }
      for (final id in ['anulom-vilom', 'desk-stretches', 'dinacharya']) {
        final c = articleById(id)!.caution!;
        expect(c.en.toLowerCase(), contains('stop'));
        expect(c.en, contains('pregnant'));
        expect(c.en, contains('Vaidya or doctor'));
      }
    });

    test('no doses and no fake news', () {
      final dose = RegExp(r'\b\d+(\.\d+)?\s*(mg|g|gm|grams?|ml|tsp|teaspoons?|tablespoons?|capsules?|tablets?)\b', caseSensitive: false);
      for (final a in articles) {
        for (final l in [...a.body, ...a.steps]) {
          expect(dose.hasMatch(l.en), isFalse, reason: '${a.id}: ${l.en}');
        }
      }
      expect(articles.where((a) => a.category == 'News'), isEmpty);
    });
  });

  testWidgets('a list card opens its article', (t) async {
    await _pumpLearn(t);
    final a = articleById('agni')!;
    await _tap(t, find.byKey(const ValueKey('learn-card-agni')));
    expect(find.byType(ArticleScreen), findsOneWidget);
    expect(find.text(a.title.en), findsOneWidget);
    expect(find.text(a.body.first.en), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('"Watch now" on the big card opens the hero article', (t) async {
    await _pumpLearn(t);
    await _tap(t, find.byKey(const ValueKey('learn-hero-watch')));
    expect(find.byType(ArticleScreen), findsOneWidget);
    final hero = articleById(heroArticleId)!;
    expect(find.text(hero.title.en), findsOneWidget);
    expect(find.byKey(const ValueKey('watch-youtube')), findsOneWidget);
    expect(find.text('How to do it'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('bookmark toggles and the Saved filter shows it', (t) async {
    await _pumpLearn(t);
    await _tap(t, find.byKey(const ValueKey('learn-chip-Saved')));
    expect(find.text('Nothing saved yet'), findsOneWidget);

    await _tap(t, find.byKey(const ValueKey('learn-chip-For you')));
    final bookmark = find.byKey(const ValueKey('learn-bookmark-sleep'));
    await _tap(t, bookmark);
    expect(AppState.instance.savedArticles, {'sleep'});
    expect(find.descendant(of: bookmark, matching: find.byIcon(Icons.bookmark_rounded)), findsOneWidget);
    expect(find.byType(ArticleScreen), findsNothing, reason: 'the bookmark does not open the article');

    await _tap(t, find.byKey(const ValueKey('learn-chip-Saved')));
    expect(find.byKey(const ValueKey('learn-card-sleep')), findsOneWidget);
    expect(find.byKey(const ValueKey('learn-card-agni')), findsNothing);
    expect(find.text('Nothing saved yet'), findsNothing);

    await _tap(t, find.byKey(const ValueKey('learn-bookmark-sleep')));
    expect(AppState.instance.savedArticles, isEmpty);
    expect(find.byKey(const ValueKey('learn-card-sleep')), findsNothing);
    expect(find.text('Nothing saved yet'), findsOneWidget);
  });

  testWidgets('category chips filter the list', (t) async {
    await _pumpLearn(t);
    for (final (chip, cat) in [('Journals', 'Journal'), ('Videos', 'Video'), ('Guides', 'Guide')]) {
      await _tap(t, find.byKey(ValueKey('learn-chip-$chip')));
      for (final a in articles) {
        expect(find.byKey(ValueKey('learn-card-${a.id}')), a.category == cat ? findsOneWidget : findsNothing,
            reason: '$chip: ${a.id}');
      }
      expect(find.byKey(const ValueKey('learn-hero')), findsNothing);
    }
    expect(t.takeException(), isNull);
  });

  testWidgets('the article header bookmark saves it', (t) async {
    await _pump(t, ArticleScreen(article: articleById('anulom-vilom')!));
    final b = find.byKey(const ValueKey('article-bookmark'));
    expect(find.descendant(of: b, matching: find.byIcon(Icons.bookmark_border_rounded)), findsOneWidget);
    await _tap(t, b);
    expect(AppState.instance.savedArticles, contains('anulom-vilom'));
    expect(find.descendant(of: b, matching: find.byIcon(Icons.bookmark_rounded)), findsOneWidget);
    await _tap(t, b);
    expect(AppState.instance.savedArticles, isEmpty);
  });

  testWidgets('newsletter: invalid email shows an error, valid one subscribes', (t) async {
    await _pumpLearn(t);
    await _tap(t, find.byKey(const ValueKey('learn-chip-Newsletter')));
    final field = find.byKey(const ValueKey('newsletter-email'));
    final go = find.byKey(const ValueKey('newsletter-subscribe'));

    await t.enterText(field, 'not-an-email');
    await _tap(t, go);
    expect(find.text('Please enter a valid email address'), findsOneWidget);
    expect(find.text('Subscribed to the Veda letter'), findsNothing);

    await t.enterText(field, 'asha@mail');
    await _tap(t, go);
    expect(find.text('Please enter a valid email address'), findsOneWidget);

    await t.enterText(field, 'asha.k@gmail.com');
    await _tap(t, go);
    expect(find.text('Please enter a valid email address'), findsNothing);
    expect(find.text('Subscribed to the Veda letter'), findsOneWidget);
    expect(t.widget<TextField>(field).controller!.text, isEmpty);
    expect(t.takeException(), isNull);
  });

  testWidgets('Learn tab in Hindi: every filter, empty Saved and email error', (t) async {
    Lang.notifier.value = Lang.hiCode;
    await _pumpLearn(t);
    expect(englishLeft(t), isEmpty);
    for (final chip in ['Journals', 'Videos', 'Guides', 'Saved', 'Newsletter']) {
      await _tap(t, find.byKey(ValueKey('learn-chip-$chip')));
      expect(t.takeException(), isNull, reason: chip);
      expect(englishLeft(t), isEmpty, reason: chip);
    }
    await t.enterText(find.byKey(const ValueKey('newsletter-email')), 'x');
    await _tap(t, find.byKey(const ValueKey('newsletter-subscribe')));
    expect(find.text(tr('Please enter a valid email address')), findsOneWidget);
    // The typed "x" is the user's own text, not app text.
    expect(englishLeft(t), isEmpty);
  });

  for (final lang in [Lang.en, Lang.hiCode]) {
    for (final a in articles) {
      testWidgets('article ${a.id} in $lang fits 390x844', (t) async {
        Lang.notifier.value = lang;
        AppState.instance.savedArticles = {a.id};
        await _pump(t, ArticleScreen(article: a));
        expect(t.takeException(), isNull, reason: 'overflow or error on ${a.id} ($lang)');
        expect(find.text(a.title.t), findsOneWidget);
        expect(find.text(a.body.last.t), findsOneWidget, reason: 'whole body is shown');
        if (a.steps.isNotEmpty) expect(find.text(a.steps.last.t), findsOneWidget);
        if (lang == Lang.hiCode) expect(englishLeft(t), isEmpty, reason: 'English text left on ${a.id}');
      });
    }
  }
}
