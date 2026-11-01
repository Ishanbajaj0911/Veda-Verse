import 'package:flutter/material.dart';
import 'package:veda_verse/content/sessions.dart';
import 'package:veda_verse/engine/plan_engine.dart';
import 'package:veda_verse/l10n/lang.dart';
import 'package:veda_verse/screens/practice_screen.dart';
import 'package:veda_verse/state/app_state.dart';
import 'package:veda_verse/theme/vv.dart';
import 'package:veda_verse/widgets/art.dart';

// ---------------------------------------------------------------------------
// Pictures
// ---------------------------------------------------------------------------

/// Drawn illustration for a session, by `titleEn`.
ArtMotif sessionMotif(String titleEn) => switch (titleEn) {
      'Sunrise Hatha by the lake' => ArtMotif.sunrise,
      'Gentle spine & back therapy' => ArtMotif.spine,
      'Shirodhara session' => ArtMotif.water,
      'Power vinyasa flow' => ArtMotif.stretch,
      'Yoga Nidra for deep sleep' => ArtMotif.moon,
      'Pranayama for acidity' => ArtMotif.breath,
      'Desk-break stretches' => ArtMotif.stretch,
      'Surya Namaskar · 12 rounds' => ArtMotif.surya,
      _ => ArtMotif.lotus,
    };

/// The picture for a session card or detail header. Fills its box.
class SessionPicture extends StatelessWidget {
  final String titleEn;
  const SessionPicture(this.titleEn, {super.key});

  @override
  Widget build(BuildContext context) => switch (titleEn) {
        // Line drawing on white: show it whole rather than crop the figure.
        'Sunrise Hatha by the lake' => const ColoredBox(
            color: Colors.white,
            child: VvPhoto(VvImages.yogaTree, fit: BoxFit.contain, fallback: Colors.white),
          ),
        'Yoga Nidra for deep sleep' => const _NidraPhoto(),
        _ => VvArt.themed(sessionMotif(titleEn)),
      };
}

/// The bottom of the tall meditation photo (the seated figure in its halo),
/// scaled to the box height and blended into the photo's own pale blue.
class _NidraPhoto extends StatelessWidget {
  const _NidraPhoto();
  static const _paper = Color(0xFFDBEFF8);

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final h = box.maxHeight / 0.42; // show the lowest 42% of the photo
        final w = h * 800 / 1422;
        return ColoredBox(
          color: _paper,
          child: ClipRect(
            child: OverflowBox(
              minWidth: w,
              maxWidth: w,
              minHeight: h,
              maxHeight: h,
              alignment: Alignment.bottomCenter,
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (r) => const LinearGradient(
                  colors: [Color(0x00000000), Color(0xFF000000), Color(0xFF000000), Color(0x00000000)],
                  stops: [0, 0.18, 0.82, 1],
                ).createShader(r),
                child: SizedBox(
                  width: w,
                  height: h,
                  child: const VvPhoto(VvImages.meditation, alignment: Alignment.bottomCenter, fallback: _paper),
                ),
              ),
            ),
          ),
        );
      });
}

// ---------------------------------------------------------------------------
// State helpers and actions (shared by the Yoga tab cards and the detail)
// ---------------------------------------------------------------------------

bool isJoined(YogaSession s) => AppState.instance.joinedSessions.contains(s.titleEn);

/// Recorded sessions are started in the app; live ones are joined or booked.
bool isRecorded(YogaSession s) => s.ctaEn == 'Start';

bool isOnline(YogaSession s) => onlineSessions.contains(s);

/// "Joined ✓", "Booked ✓" or (recorded) "Done ✓".
String joinedLabel(YogaSession s) => switch (s.ctaEn) {
      'Join' => tr('Joined ✓'),
      'Book' => tr('Booked ✓'),
      _ => tr('Done ✓'),
    };

/// The user's health flags that make this session one to check first.
List<String> cautionFlags(YogaSession s) {
  final flags = AppState.instance.engineInput.flags;
  return [for (final f in s.avoidIf) if (flags.contains(f)) tr(f)];
}

String _cautionWhy(YogaSession s) {
  final flags = cautionFlags(s);
  return flags.isEmpty
      ? tr('This session may not suit everyone. Please check with your Vaidya before you take part.')
      : trf('You noted: {flags}. This session can be hard on the body then, so please check with your Vaidya before you take part.',
          {'flags': flags.join(', ')});
}

/// What paying looks like. No payment is taken in the app.
String payNote(YogaSession s) {
  if (s.free) return tr('Free to join. Nothing to pay.');
  return isOnline(s)
      ? tr('Pay the teacher at your first session. Nothing is charged in the app.')
      : tr('Pay at the studio when you arrive. Nothing is charged in the app.');
}

Future<T?> _sheet<T>(BuildContext context, List<Widget> children) => showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Vv.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (c) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: Vv.border3, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              ...children,
            ],
          ),
        ),
      ),
    );

Widget _sheetHead(YogaSession s, String kicker, {Color kickerColor = Vv.brown}) => Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(width: 64, height: 64, child: SessionPicture(s.titleEn)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(kicker, style: Vv.kicker(kickerColor, size: 11)),
              const SizedBox(height: 4),
              Text(s.title, style: Vv.serif(20, height: 1.15)),
            ],
          ),
        ),
      ],
    );

Widget _infoRow(IconData icon, String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Vv.green),
          const SizedBox(width: 10),
          SizedBox(width: 72, child: Text(label, style: Vv.sans(13, weight: FontWeight.w600, color: Vv.muted))),
          Expanded(child: Text(value, style: Vv.sans(14, weight: FontWeight.w700, color: Vv.ink))),
        ],
      ),
    );

Widget _textButton(String label, VoidCallback onTap, {Key? key}) => VvTap(
      key: key,
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        child: Text(label, style: Vv.sans(15, weight: FontWeight.w700, color: Vv.ink2)),
      ),
    );

/// Confirm step for a live session, then saves it to the account.
Future<void> confirmBooking(BuildContext context, YogaSession s) async {
  final join = s.ctaEn == 'Join';
  final ok = await _sheet<bool>(context, [
    Builder(builder: (c) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sheetHead(s, join ? tr('JOIN THIS SESSION') : tr('BOOK THIS SESSION')),
          const SizedBox(height: 18),
          _infoRow(Icons.schedule_rounded, tr('When'), s.time),
          _infoRow(isOnline(s) ? Icons.tv_outlined : Icons.location_on_outlined, tr('Where'), s.where),
          _infoRow(Icons.payments_outlined, tr('Price'), s.price),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: s.free ? Vv.mint : Vv.goldPale, borderRadius: BorderRadius.circular(12)),
            child: VvNote(
              text: payNote(s),
              icon: s.free ? Icons.check_circle_outline_rounded : Icons.storefront_outlined,
              color: s.free ? Vv.green : Vv.brownDark,
            ),
          ),
          const SizedBox(height: 18),
          VvButton(
            key: const ValueKey('session-confirm'),
            label: join ? tr('Confirm and join') : tr('Confirm booking'),
            leading: Icons.check_rounded,
            onTap: () => Navigator.of(c).pop(true),
          ),
          const SizedBox(height: 4),
          _textButton(tr('Not now'), () => Navigator.of(c).pop(false)),
        ],
      );
    }),
  ]);
  if (ok != true) return;
  // The card and the detail switch to "Booked ✓" / "Joined ✓" right away.
  AppState.instance.update((st) => st.joinedSessions.add(s.titleEn));
}

/// Asks before removing a booked or joined session.
Future<void> confirmCancel(BuildContext context, YogaSession s) async {
  final join = s.ctaEn == 'Join';
  final ok = await _sheet<bool>(context, [
    Builder(builder: (c) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sheetHead(s, join ? tr('LEAVE THIS SESSION?') : tr('CANCEL THIS BOOKING?'), kickerColor: Vv.redInk),
          const SizedBox(height: 14),
          Text(s.time, style: Vv.sans(14, weight: FontWeight.w700, color: Vv.ink2)),
          const SizedBox(height: 4),
          Text(s.where, style: Vv.sans(13, color: Vv.muted)),
          const SizedBox(height: 18),
          VvButton(
            key: const ValueKey('session-cancel-confirm'),
            label: join ? tr('Yes, leave') : tr('Yes, cancel'),
            bg: Vv.redPale,
            fg: Vv.redInk,
            borderColor: Vv.redBorder,
            onTap: () => Navigator.of(c).pop(true),
          ),
          const SizedBox(height: 4),
          _textButton(tr('Keep it'), () => Navigator.of(c).pop(false)),
        ],
      );
    }),
  ]);
  if (ok != true) return;
  AppState.instance.update((st) => st.joinedSessions.remove(s.titleEn));
}

/// "Ask your Vaidya first": true if the user chose to go ahead anyway.
Future<bool> askVaidyaFirst(BuildContext context, YogaSession s, {VoidCallback? findVaidya}) async {
  final r = await _sheet<String>(context, [
    Builder(builder: (c) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: Vv.redPale, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.health_and_safety_outlined, color: Vv.redInk),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(tr('Ask your Vaidya first'), style: Vv.serif(22, height: 1.15))),
            ],
          ),
          const SizedBox(height: 14),
          Text(_cautionWhy(s), style: Vv.sans(14, color: Vv.ink2, height: 1.5)),
          const SizedBox(height: 18),
          if (findVaidya != null) ...[
            VvButton(
              label: tr('Talk to a Vaidya'),
              leading: Icons.medical_services_outlined,
              onTap: () => Navigator.of(c).pop('vaidya'),
            ),
            const SizedBox(height: 10),
          ],
          VvButton(
            key: const ValueKey('session-caution-continue'),
            label: tr('I’ve checked, continue'),
            bg: Vv.surface,
            fg: Vv.ink,
            borderColor: Vv.border3,
            onTap: () => Navigator.of(c).pop('go'),
          ),
          const SizedBox(height: 4),
          _textButton(tr('Not now'), () => Navigator.of(c).pop()),
        ],
      );
    }),
  ]);
  if (r == 'vaidya') findVaidya?.call();
  return r == 'go';
}

/// Opens the guided practice for [titleEn].
Future<void> openPractice(BuildContext context, String titleEn) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => PracticeScreen(titleEn: titleEn)));

/// The main button of a session: start, join or book (asking first when the
/// session may not suit this user).
Future<void> sessionMainAction(BuildContext context, RankedSession r, {VoidCallback? findVaidya}) async {
  final s = r.session;
  if (r.caution && !await askVaidyaFirst(context, s, findVaidya: findVaidya)) return;
  if (!context.mounted) return;
  if (isRecorded(s)) {
    await openPractice(context, s.titleEn);
  } else {
    await confirmBooking(context, s);
  }
}

// ---------------------------------------------------------------------------
// Detail screen
// ---------------------------------------------------------------------------

class SessionScreen extends StatelessWidget {
  final RankedSession ranked;

  /// Switches the app to the Vaidya tab (from the Yoga tab), if given.
  final VoidCallback? findVaidya;
  const SessionScreen({super.key, required this.ranked, this.findVaidya});

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: AppState.instance, builder: (context, _) => _build(context));

  Widget _kicker(String t) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 10),
        child: Text(t, style: Vv.kicker(Vv.muted, size: 11)),
      );

  Widget _line(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: Vv.green),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: Vv.sans(14, weight: FontWeight.w600, color: Vv.ink2, height: 1.35))),
          ],
        ),
      );

  Widget _bullet(IconData icon, Color color, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.only(top: 1), child: Icon(icon, size: 18, color: color)),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: Vv.sans(14, color: Vv.ink, height: 1.45))),
          ],
        ),
      );

  Widget _build(BuildContext context) {
    final r = ranked;
    final s = r.session;
    final info = sessionInfo[s.titleEn];
    final joined = isJoined(s);
    final recorded = isRecorded(s);
    final pad = MediaQuery.of(context).padding;
    void toVaidya() {
      Navigator.of(context).pop();
      findVaidya?.call();
    }

    return Scaffold(
      body: VvFrame(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  SizedBox(
                    height: 260 + pad.top,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        SessionPicture(s.titleEn),
                        Positioned(top: pad.top + 12, left: 16, child: const VvBackButton()),
                        Positioned(right: 16, bottom: 16, child: PriceBadge(s)),
                        if (joined) Positioned(left: 16, bottom: 16, child: JoinedBadge(s)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(s.title, style: Vv.serif(27, height: 1.12, letterSpacing: -0.2)),
                        const SizedBox(height: 4),
                        _line(isOnline(s) ? Icons.tv_outlined : Icons.location_on_outlined, s.where),
                        _line(Icons.schedule_rounded, s.time),
                        _line(Icons.payments_outlined, payNote(s)),
                        const SizedBox(height: 18),
                        if (r.caution)
                          Container(
                            key: const ValueKey('session-caution-box'),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Vv.redPale,
                              border: Border.all(color: Vv.redBorder),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.health_and_safety_outlined, size: 22, color: Vv.redInk),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(tr('Ask your Vaidya first'), style: Vv.sans(15, weight: FontWeight.w800, color: Vv.redInk)),
                                      const SizedBox(height: 4),
                                      Text(_cautionWhy(s), style: Vv.sans(13, color: Vv.redInk, height: 1.45)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: Vv.goldPale, borderRadius: BorderRadius.circular(16)),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.auto_awesome_outlined, size: 20, color: Vv.brownDark),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(tr('WHY WE PICKED THIS'), style: Vv.kicker(Vv.brown, size: 11)),
                                      const SizedBox(height: 4),
                                      Text(r.reason, style: Vv.sans(14, weight: FontWeight.w700, color: Vv.brownDark, height: 1.4)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (info != null) ...[
                          _kicker(tr('ABOUT')),
                          Text(bi(info.about), style: Vv.sans(14.5, color: Vv.ink, height: 1.55)),
                          _kicker(tr('HOW IT MAY HELP')),
                          for (final b in info.benefits) _bullet(Icons.check_circle_outline_rounded, Vv.green, bi(b)),
                          _kicker(tr('WHAT TO BRING AND WEAR')),
                          for (final b in info.bring) _bullet(Icons.backpack_outlined, Vv.brown, bi(b)),
                        ],
                        const SizedBox(height: 14),
                        VvNote(text: practiceSafety()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + pad.bottom),
              decoration: const BoxDecoration(color: Vv.surface, border: Border(top: BorderSide(color: Vv.border))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!recorded && practices.containsKey(s.titleEn)) ...[
                    VvButton(
                      key: const ValueKey('session-try'),
                      label: tr('Try a short version now'),
                      leading: Icons.play_arrow_rounded,
                      bg: Vv.surface,
                      fg: Vv.ink,
                      borderColor: Vv.border3,
                      height: 50,
                      onTap: () async {
                        if (r.caution && !await askVaidyaFirst(context, s, findVaidya: findVaidya == null ? null : toVaidya)) return;
                        if (context.mounted) await openPractice(context, s.titleEn);
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (joined && !recorded)
                    Row(
                      children: [
                        Expanded(
                          child: VvButton(
                            label: joinedLabel(s),
                            leading: Icons.event_available_outlined,
                            bg: Vv.mint,
                            fg: Vv.green,
                            borderColor: Vv.mintBorder,
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 128,
                          child: VvButton(
                            key: const ValueKey('session-cancel'),
                            label: s.ctaEn == 'Join' ? tr('Leave') : tr('Cancel'),
                            bg: Vv.surface,
                            fg: Vv.redInk,
                            borderColor: Vv.redBorder,
                            onTap: () => confirmCancel(context, s),
                          ),
                        ),
                      ],
                    )
                  else
                    VvButton(
                      key: const ValueKey('session-main'),
                      label: r.caution ? tr('Ask your Vaidya first') : (recorded ? tr('Start practice') : s.cta),
                      leading: r.caution
                          ? Icons.health_and_safety_outlined
                          : (recorded ? Icons.play_arrow_rounded : Icons.event_outlined),
                      bg: r.caution ? Vv.surface : Vv.green,
                      fg: r.caution ? Vv.redInk : Vv.surface,
                      borderColor: r.caution ? Vv.redBorder : null,
                      onTap: () => sessionMainAction(context, r, findVaidya: findVaidya == null ? null : toVaidya),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Price pill for a session picture.
class PriceBadge extends StatelessWidget {
  final YogaSession s;
  const PriceBadge(this.s, {super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: s.free ? Vv.green : Vv.deep,
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Text(s.price, style: Vv.sans(12, weight: FontWeight.w800, color: s.free ? Vv.surface : Vv.goldSoft)),
      );
}

/// "Booked ✓" / "Joined ✓" / "Done ✓" pill for a session picture.
class JoinedBadge extends StatelessWidget {
  final YogaSession s;
  const JoinedBadge(this.s, {super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Vv.deep,
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Text(joinedLabel(s), style: Vv.sans(12, weight: FontWeight.w800, color: Vv.surface)),
      );
}
