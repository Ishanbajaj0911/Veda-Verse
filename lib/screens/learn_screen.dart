import 'package:flutter/material.dart';
import 'package:veda_verse/content/articles.dart';
import 'package:veda_verse/l10n/lang.dart';
import 'package:veda_verse/screens/article_screen.dart';
import 'package:veda_verse/screens/profile_menu_screen.dart';
import 'package:veda_verse/state/app_state.dart';
import 'package:veda_verse/theme/vv.dart';

/// Learn / Awareness tab: short bilingual articles, practice videos and
/// guides (lib/content/articles.dart), saved articles, and the newsletter.
class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  static const _chips = ['For you', 'Journals', 'Videos', 'Guides', 'Saved', 'Newsletter'];
  static const _catOf = {'Journals': 'Journal', 'Videos': 'Video', 'Guides': 'Guide'};
  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[A-Za-z]{2,}$');

  String _cat = 'For you';
  final _email = TextEditingController();
  String? _emailError;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _open(Article a) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => ArticleScreen(article: a)));

  void _subscribe() {
    final v = _email.text.trim();
    if (!_emailRe.hasMatch(v)) {
      setState(() => _emailError = tr('Please enter a valid email address'));
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _emailError = null;
      _email.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Subscribed to the Veda letter'))));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: AppState.instance, builder: (context, _) => _build(context));
  }

  Widget _build(BuildContext context) {
    final s = AppState.instance;
    final hero = articleById(heroArticleId)!;
    final showHero = _cat == 'For you';
    final List<Article> list = switch (_cat) {
      'For you' => [for (final a in articles) if (a.id != hero.id) a],
      'Saved' => [for (final a in articles) if (s.savedArticles.contains(a.id)) a],
      'Newsletter' => const [],
      _ => [for (final a in articles) if (a.category == _catOf[_cat]) a],
    };
    final heading = _cat == 'For you' ? tr('Picked for you') : tr(_cat);

    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).padding.top),
        VvTabHeader(
          hello: trf('Hello, {name}', {'name': s.firstName}),
          title: Text(tr('Awareness'), style: Vv.serif(25, letterSpacing: -0.2)),
          initial: s.initial,
          onProfile: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileMenuScreen())),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            children: [
              SizedBox(
                height: 42,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final l in _chips) ...[
                        if (l != _chips.first) const SizedBox(width: 8),
                        VvChip(
                          key: ValueKey('learn-chip-$l'),
                          label: tr(l),
                          on: _cat == l,
                          onTap: () => setState(() => _cat = l),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (showHero) ...[
                _Hero(article: hero, onOpen: () => _open(hero)),
                const SizedBox(height: 18),
              ],
              if (_cat != 'Newsletter') ...[
                Text(heading, style: Vv.serif(17, weight: FontWeight.w700)),
                const SizedBox(height: 14),
                if (list.isEmpty && _cat == 'Saved') ...[
                  const _SavedEmpty(),
                  const SizedBox(height: 14),
                ],
                for (final a in list) ...[
                  _ArticleCard(
                    article: a,
                    saved: s.savedArticles.contains(a.id),
                    onOpen: () => _open(a),
                    onToggle: () => toggleSavedArticle(a.id),
                  ),
                  const SizedBox(height: 14),
                ],
              ],
              _newsletter(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _newsletter() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Vv.goldPale, borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('Weekly Veda letter'), style: Vv.serif(16, weight: FontWeight.w700, color: Vv.brownDeep)),
            const SizedBox(height: 10),
            Text(tr('One seasonal tip, one recipe, one practice — every Sunday.'),
                style: Vv.sans(13, color: Vv.brownDark, height: 1.45)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: Vv.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _emailError != null ? Vv.red : const Color(0xFFE9C18A), width: 1.5),
                    ),
                    child: TextField(
                      key: const ValueKey('newsletter-email'),
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _subscribe(),
                      onChanged: (_) {
                        if (_emailError != null) setState(() => _emailError = null);
                      },
                      style: Vv.sans(14),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: tr('you@example.com'),
                        hintStyle: Vv.sans(14, color: Vv.disabled),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                VvTap(
                  key: const ValueKey('newsletter-subscribe'),
                  onTap: _subscribe,
                  child: Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: Vv.deep, borderRadius: BorderRadius.circular(12)),
                    child: Text(tr('Subscribe'), style: Vv.sans(14, weight: FontWeight.w700, color: Vv.surface)),
                  ),
                ),
              ],
            ),
            if (_emailError != null) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 16, color: Vv.red),
                  const SizedBox(width: 6),
                  Expanded(child: Text(_emailError!, style: Vv.sans(12, weight: FontWeight.w600, color: Vv.red))),
                ],
              ),
            ],
          ],
        ),
      );
}

/// The big dark card at the top: picture, title, season and "Watch now".
class _Hero extends StatelessWidget {
  final Article article;
  final VoidCallback onOpen;
  const _Hero({required this.article, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final a = article;
    return VvTap(
      key: const ValueKey('learn-hero'),
      onTap: onOpen,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: ColoredBox(
          color: Vv.deep,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 150,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    a.image.build(),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x00163A2E), Color(0x00163A2E), Vv.deep],
                          stops: [0, 0.55, 1],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      top: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Vv.gold, borderRadius: BorderRadius.circular(999)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(a.isVideo ? Icons.play_arrow_rounded : Icons.menu_book_rounded, size: 14, color: Vv.deep),
                            const SizedBox(width: 4),
                            Text('${tr(a.category)} · ${trf('{n} min', {'n': a.minutes})}',
                                style: Vv.sans(12, weight: FontWeight.w800, color: Vv.deep)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.title.t, style: Vv.serif(24, color: Vv.bg, height: 1.2, letterSpacing: -0.2)),
                    const SizedBox(height: 10),
                    if (a.seasonal)
                      Text(trf('This season: {ritu}', {'ritu': rituFor(DateTime.now())}),
                          style: Vv.sans(13, weight: FontWeight.w700, color: Vv.goldLight)),
                    const SizedBox(height: 4),
                    Text(tr('What to eat, and how to live, as the weather turns.'),
                        style: Vv.sans(13, color: Vv.onDeepMuted3, height: 1.45)),
                    const SizedBox(height: 16),
                    Container(
                      key: const ValueKey('learn-hero-watch'),
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(color: Vv.bg, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(a.isVideo ? Icons.play_arrow_rounded : Icons.menu_book_rounded, size: 18, color: Vv.deep),
                          const SizedBox(width: 6),
                          Text(a.isVideo ? tr('Watch now') : tr('Read now'),
                              style: Vv.sans(14, weight: FontWeight.w700, color: Vv.deep)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A list card: picture, category, title, meta, and a bookmark toggle.
class _ArticleCard extends StatelessWidget {
  final Article article;
  final bool saved;
  final VoidCallback onOpen;
  final VoidCallback onToggle;
  const _ArticleCard({required this.article, required this.saved, required this.onOpen, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final a = article;
    return VvTap(
      key: ValueKey('learn-card-${a.id}'),
      onTap: onOpen,
      child: VvCard(
        padding: const EdgeInsets.all(12),
        radius: 18,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 76,
                height: 76,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    a.image.build(),
                    if (a.isVideo)
                      Center(
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(color: Vv.surface.withValues(alpha: 0.9), shape: BoxShape.circle),
                          child: const Icon(Icons.play_arrow_rounded, size: 20, color: Vv.deep),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr(a.category).toUpperCase(), style: Vv.kicker(Vv.brown, size: 11, spacing: 0.8)),
                  const SizedBox(height: 4),
                  Text(a.title.t, style: Vv.sans(14, weight: FontWeight.w700, height: 1.35)),
                  const SizedBox(height: 4),
                  Text(articleMeta(a), style: Vv.sans(12, color: Vv.muted)),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Semantics(
              button: true,
              label: saved ? tr('Remove from saved') : tr('Save article'),
              child: VvTap(
                key: ValueKey('learn-bookmark-${a.id}'),
                onTap: onToggle,
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(
                    saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    size: 20,
                    color: saved ? Vv.green : Vv.muted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedEmpty extends StatelessWidget {
  const _SavedEmpty();

  @override
  Widget build(BuildContext context) => VvCard(
        radius: 18,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: Vv.mint, borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.bookmark_border_rounded, color: Vv.green),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('Nothing saved yet'), style: Vv.sans(14, weight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(tr('Tap the bookmark on any article to keep it here.'),
                      style: Vv.sans(12, color: Vv.muted, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      );
}
