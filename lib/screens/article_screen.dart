import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:veda_verse/content/articles.dart';
import 'package:veda_verse/l10n/lang.dart';
import 'package:veda_verse/state/app_state.dart';
import 'package:veda_verse/theme/vv.dart';

/// Saves or un-saves a Learn article for this account (persisted by Accounts).
void toggleSavedArticle(String id) {
  AppState.instance.update((s) {
    final next = {...s.savedArticles};
    if (!next.remove(id)) next.add(id);
    s.savedArticles = next;
  });
}

/// "Explainer · 4 min" for an article, in the current language.
String articleMeta(Article a) => '${a.kind.t} · ${trf('{n} min', {'n': a.minutes})}';

/// One Learn article, video or guide: picture, text, steps and, for videos,
/// a YouTube search for a guided version.
class ArticleScreen extends StatelessWidget {
  final Article article;
  const ArticleScreen({super.key, required this.article});

  Future<void> _watch(BuildContext context) async {
    final uri = article.youtubeUri;
    var ok = false;
    try {
      if (uri != null) ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Couldn’t open YouTube. Please try again.'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = article;
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      body: VvFrame(
        child: ListenableBuilder(
          listenable: AppState.instance,
          builder: (context, _) {
            final saved = AppState.instance.savedArticles.contains(a.id);
            return SingleChildScrollView(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 260 + top,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
                          child: a.image.build(),
                        ),
                        Positioned(
                          left: 16,
                          top: top + 14,
                          child: const VvBackButton(),
                        ),
                        Positioned(
                          right: 16,
                          top: top + 14,
                          child: Semantics(
                            button: true,
                            label: saved ? tr('Remove from saved') : tr('Save article'),
                            child: VvSquareButton(
                              key: const ValueKey('article-bookmark'),
                              icon: saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                              fg: saved ? Vv.green : Vv.ink,
                              onTap: () => toggleSavedArticle(a.id),
                            ),
                          ),
                        ),
                        if (a.isVideo)
                          Positioned(
                            right: 20,
                            bottom: 16,
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: Vv.surface.withValues(alpha: 0.92),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.play_arrow_rounded, color: Vv.deep, size: 30),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Vv.goldPale, borderRadius: BorderRadius.circular(999)),
                              child: Text(tr(a.category).toUpperCase(), style: Vv.kicker(Vv.brown, size: 11, spacing: 0.8)),
                            ),
                            Text(articleMeta(a), style: Vv.sans(12, weight: FontWeight.w600, color: Vv.muted)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(a.title.t, style: Vv.serif(27, height: 1.2, letterSpacing: -0.2)),
                        if (a.seasonal) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(color: Vv.mint, borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.wb_sunny_outlined, size: 16, color: Vv.green),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(trf('This season: {ritu}', {'ritu': rituFor(DateTime.now())}),
                                      style: Vv.sans(13, weight: FontWeight.w700, color: Vv.green)),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        for (final p in a.body) ...[
                          Text(p.t, style: Vv.sans(15, color: Vv.ink2, height: 1.6)),
                          const SizedBox(height: 12),
                        ],
                        if (a.steps.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(a.category == 'Guide' ? tr('Quick checklist') : tr('How to do it'),
                              style: Vv.serif(19, weight: FontWeight.w700)),
                          const SizedBox(height: 12),
                          if (a.caution != null) ...[
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Vv.amberBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Vv.goldBorder),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.health_and_safety_outlined, size: 18, color: Vv.amberInk),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(tr('Before you start'),
                                            style: Vv.sans(13, weight: FontWeight.w800, color: Vv.amberInk)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(a.caution!.t, style: Vv.sans(13, color: Vv.amberInk, height: 1.5)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          VvCard(
                            padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
                            radius: 18,
                            child: Column(
                              children: [
                                for (var i = 0; i < a.steps.length; i++)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 28,
                                          height: 28,
                                          alignment: Alignment.center,
                                          decoration: const BoxDecoration(color: Vv.mint, shape: BoxShape.circle),
                                          child: Text('${i + 1}',
                                              style: Vv.sans(13, weight: FontWeight.w800, color: Vv.green)),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text(a.steps[i].t, style: Vv.sans(14, color: Vv.ink, height: 1.5)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (a.isVideo && a.youtubeUri != null) ...[
                          VvButton(
                            key: const ValueKey('watch-youtube'),
                            label: tr('Watch on YouTube'),
                            leading: Icons.play_circle_outline_rounded,
                            bg: Vv.deep,
                            onTap: () => _watch(context),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            tr('There’s no video inside the app yet. Follow the steps above, or watch a guided version on YouTube.'),
                            style: Vv.sans(12, color: Vv.muted, height: 1.5),
                          ),
                          const SizedBox(height: 16),
                        ],
                        VvNote(
                          text: tr('Wellness information only, not a diagnosis or treatment. For any health concern, ask a Vaidya or doctor.'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
