import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:veda_verse/theme/vv.dart';

/// Photos bundled with the app (assets/images). Offline, no network.
class VvImages {
  VvImages._();
  static const tulsi = 'assets/images/tulsi.jpg';
  static const neem = 'assets/images/neem.jpg';
  static const turmeric = 'assets/images/turmeric.jpg';
  static const ashwagandha = 'assets/images/ashwagandha.jpg';

  /// Line illustration of a woman in tree pose on white.
  static const yogaTree = 'assets/images/yoga_tree.jpg';

  /// Tall pale-blue picture: moon phases at the top, a seated meditation
  /// silhouette at the bottom. Use [Alignment.bottomCenter] for the figure,
  /// [Alignment.topCenter] for the moons.
  static const meditation = 'assets/images/meditation.jpg';
}

/// A bundled photo that fills its box (cover). Falls back to a tinted box
/// if the asset can't be loaded, so a layout never breaks.
class VvPhoto extends StatelessWidget {
  final String asset;
  final Alignment alignment;
  final BoxFit fit;
  final Color fallback;
  final String? semanticLabel;
  const VvPhoto(this.asset,
      {super.key, this.alignment = Alignment.center, this.fit = BoxFit.cover, this.fallback = Vv.mint, this.semanticLabel});

  @override
  Widget build(BuildContext context) => Image.asset(
        asset,
        fit: fit,
        alignment: alignment,
        width: double.infinity,
        height: double.infinity,
        semanticLabel: semanticLabel,
        excludeFromSemantics: semanticLabel == null,
        errorBuilder: (_, _, _) => ColoredBox(color: fallback),
      );
}

/// Subjects for drawn cover illustrations ([VvArt]).
enum ArtMotif {
  sunrise, // morning routine, Dinacharya
  moon, // sleep, night
  breath, // pranayama, breathing
  leaf, // food, herbs, nature
  flame, // Agni, digestion
  lotus, // calm, meditation, women's health
  water, // hydration, seasons, monsoon
  bowl, // meals, recipes, khichdi
  surya, // Surya Namaskar, energy
  meditate, // seated figure
  stretch, // standing figure, arms up
  spine, // back care
}

/// A flat illustration drawn in code in the app's palette: a soft
/// background, rings, and one subject. Fills its box; works offline.
class VvArt extends StatelessWidget {
  final ArtMotif motif;
  final Color bg;
  final Color ink;
  final Color accent;
  const VvArt(this.motif, {super.key, this.bg = Vv.mint, this.ink = Vv.green, this.accent = Vv.gold});

  /// A matching set of colours for each mood, so callers can pick by name.
  factory VvArt.themed(ArtMotif motif, {Key? key}) {
    final (bg, ink, accent) = switch (motif) {
      ArtMotif.sunrise || ArtMotif.surya => (Vv.goldPale, Vv.brown, Vv.gold),
      ArtMotif.moon || ArtMotif.meditate => (Vv.bluePale2, Vv.blueInk, Vv.goldLight),
      ArtMotif.breath || ArtMotif.water => (Vv.bluePale, Vv.blue, Vv.vataBar),
      ArtMotif.leaf || ArtMotif.bowl => (Vv.mint, Vv.green, Vv.kaphaBar),
      ArtMotif.flame => (Vv.rustPale, Vv.rust, Vv.gold),
      ArtMotif.lotus => (Vv.plumPale, Vv.plum, Vv.plumBar),
      ArtMotif.stretch || ArtMotif.spine => (Vv.rustPale, Vv.rust, Vv.goldSoft),
    };
    return VvArt(motif, key: key, bg: bg, ink: ink, accent: accent);
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: CustomPaint(painter: _ArtPainter(motif, bg, ink, accent), child: const SizedBox.expand()),
      );
}

class _ArtPainter extends CustomPainter {
  final ArtMotif motif;
  final Color bg, ink, accent;
  _ArtPainter(this.motif, this.bg, this.ink, this.accent);

  Paint _fill(Color c, [double a = 1]) => Paint()..color = c.withValues(alpha: a);
  Paint _line(Color c, double w, [double a = 1]) => Paint()
    ..color = c.withValues(alpha: a)
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    canvas.drawRect(
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(bg, Colors.white, 0.35)!, bg],
        ).createShader(r),
    );
    // Soft rings, like the rest of the app.
    final ringC = Offset(size.width * 0.86, size.height * 0.18);
    for (var i = 1; i <= 3; i++) {
      canvas.drawCircle(ringC, size.shortestSide * 0.22 * i, _line(ink, 1, 0.08));
    }
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.95), size.shortestSide * 0.35, _fill(accent, 0.12));

    // Subject sits in a square in the middle.
    final s = size.shortestSide * 0.78;
    final box = Rect.fromCenter(center: r.center, width: s, height: s);
    canvas.save();
    canvas.translate(box.left, box.top);
    canvas.scale(s / 100);
    switch (motif) {
      case ArtMotif.sunrise:
        _sunrise(canvas);
      case ArtMotif.moon:
        _moon(canvas);
      case ArtMotif.breath:
        _breath(canvas);
      case ArtMotif.leaf:
        _leaf(canvas);
      case ArtMotif.flame:
        _flame(canvas);
      case ArtMotif.lotus:
        _lotus(canvas);
      case ArtMotif.water:
        _water(canvas);
      case ArtMotif.bowl:
        _bowl(canvas);
      case ArtMotif.surya:
        _surya(canvas);
      case ArtMotif.meditate:
        _meditate(canvas);
      case ArtMotif.stretch:
        _stretch(canvas);
      case ArtMotif.spine:
        _spine(canvas);
    }
    canvas.restore();
  }

  // All subjects are drawn on a 100 x 100 grid.

  void _sunrise(Canvas c) {
    c.drawCircle(const Offset(50, 62), 22, _fill(accent));
    for (var i = 0; i < 7; i++) {
      final a = math.pi + math.pi * i / 6;
      c.drawLine(Offset(50 + 28 * math.cos(a), 62 + 28 * math.sin(a)), Offset(50 + 38 * math.cos(a), 62 + 38 * math.sin(a)),
          _line(accent, 3));
    }
    final hill = Path()
      ..moveTo(0, 70)
      ..quadraticBezierTo(30, 55, 55, 68)
      ..quadraticBezierTo(80, 58, 100, 66)
      ..lineTo(100, 100)
      ..lineTo(0, 100)
      ..close();
    c.drawPath(hill, _fill(ink, 0.85));
    c.drawLine(const Offset(10, 82), const Offset(40, 82), _line(Vv.surface, 2, 0.5));
    c.drawLine(const Offset(55, 88), const Offset(90, 88), _line(Vv.surface, 2, 0.4));
  }

  void _moon(Canvas c) {
    final moon = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: const Offset(48, 50), radius: 28)),
      Path()..addOval(Rect.fromCircle(center: const Offset(62, 42), radius: 25)),
    );
    c.drawPath(moon, _fill(accent));
    for (final (x, y, rad) in [(74.0, 70.0, 2.5), (82.0, 22.0, 2.0), (22.0, 20.0, 1.8), (86.0, 48.0, 1.5), (30.0, 84.0, 1.6)]) {
      c.drawCircle(Offset(x, y), rad, _fill(ink, 0.7));
    }
    c.drawLine(const Offset(14, 92), const Offset(86, 92), _line(ink, 2, 0.25));
  }

  void _breath(Canvas c) {
    for (var k = 0; k < 3; k++) {
      final p = Path()..moveTo(8, 35.0 + k * 15);
      for (var x = 8.0; x <= 92; x += 2) {
        p.lineTo(x, 35 + k * 15 + 7 * math.sin((x / 84) * 2 * math.pi + k * 0.9));
      }
      c.drawPath(p, _line(k == 1 ? accent : ink, k == 1 ? 4 : 3, k == 1 ? 1 : 0.75));
    }
    c.drawCircle(const Offset(50, 20), 6, _fill(ink, 0.2));
  }

  Path _leafPath(double cx, double top, double bottom, double half) => Path()
    ..moveTo(cx, top)
    ..quadraticBezierTo(cx + half * 1.6, (top + bottom) / 2, cx, bottom)
    ..quadraticBezierTo(cx - half * 1.6, (top + bottom) / 2, cx, top)
    ..close();

  void _leaf(Canvas c) {
    c.save();
    c.translate(50, 52);
    c.rotate(-0.5);
    c.translate(-50, -52);
    c.drawPath(_leafPath(50, 12, 88, 22), _fill(ink, 0.9));
    c.drawLine(const Offset(50, 16), const Offset(50, 94), _line(Vv.surface, 2, 0.7));
    for (var i = 0; i < 4; i++) {
      final y = 30.0 + i * 13;
      c.drawLine(Offset(50, y + 6), Offset(36, y), _line(Vv.surface, 1.5, 0.5));
      c.drawLine(Offset(50, y + 6), Offset(64, y), _line(Vv.surface, 1.5, 0.5));
    }
    c.restore();
    c.save();
    c.translate(72, 74);
    c.rotate(0.9);
    c.translate(-72, -74);
    c.drawPath(_leafPath(72, 58, 90, 9), _fill(accent));
    c.restore();
  }

  void _flame(Canvas c) {
    Path drop(double w, double top, double bottom) => Path()
      ..moveTo(50, top)
      ..cubicTo(50 + w, top + (bottom - top) * 0.45, 50 + w, bottom, 50, bottom)
      ..cubicTo(50 - w, bottom, 50 - w, top + (bottom - top) * 0.45, 50, top)
      ..close();
    c.drawPath(drop(30, 8, 86), _fill(ink, 0.85));
    c.drawPath(drop(18, 34, 86), _fill(accent));
    c.drawPath(drop(8, 58, 86), _fill(Vv.surface, 0.85));
    c.drawLine(const Offset(24, 94), const Offset(76, 94), _line(ink, 3, 0.5));
  }

  void _lotus(Canvas c) {
    void petal(double angle, Color col, double len) {
      c.save();
      c.translate(50, 70);
      c.rotate(angle);
      c.drawPath(_leafPath(0, -len, 0, 9), _fill(col));
      c.restore();
    }

    petal(-1.1, accent, 34);
    petal(1.1, accent, 34);
    petal(-0.55, ink.withValues(alpha: 0.75), 42);
    petal(0.55, ink.withValues(alpha: 0.75), 42);
    petal(0, ink, 50);
    for (var i = 0; i < 3; i++) {
      c.drawArc(Rect.fromCenter(center: Offset(50, 82.0 + i * 6), width: 70.0 - i * 14, height: 8), 0, math.pi,
          false, _line(ink, 2, 0.35));
    }
  }

  void _water(Canvas c) {
    final d = Path()
      ..moveTo(50, 8)
      ..cubicTo(72, 36, 76, 52, 76, 60)
      ..arcToPoint(const Offset(24, 60), radius: const Radius.circular(26))
      ..cubicTo(24, 52, 28, 36, 50, 8)
      ..close();
    c.drawPath(d, _fill(ink, 0.85));
    c.drawArc(const Rect.fromLTWH(34, 44, 22, 26), 2.2, 1.3, false, _line(Vv.surface, 3, 0.7));
    for (var i = 0; i < 2; i++) {
      c.drawOval(Rect.fromCenter(center: const Offset(50, 92), width: 50.0 + i * 30, height: 8.0 + i * 4), _line(accent, 2, 0.8 - i * 0.3));
    }
  }

  void _bowl(Canvas c) {
    for (var i = 0; i < 3; i++) {
      final x = 34.0 + i * 16;
      final p = Path()
        ..moveTo(x, 40)
        ..cubicTo(x - 6, 32, x + 6, 26, x, 16);
      c.drawPath(p, _line(ink, 2.5, 0.45));
    }
    c.drawOval(const Rect.fromLTWH(14, 46, 72, 12), _fill(accent));
    final bowl = Path()
      ..moveTo(12, 52)
      ..arcToPoint(const Offset(88, 52), radius: const Radius.circular(38), clockwise: false)
      ..close();
    c.drawPath(bowl, _fill(ink, 0.9));
    c.drawLine(const Offset(36, 92), const Offset(64, 92), _line(ink, 4, 0.9));
  }

  void _surya(Canvas c) {
    for (var i = 0; i < 12; i++) {
      final a = 2 * math.pi * i / 12;
      c.drawLine(Offset(50 + 26 * math.cos(a), 50 + 26 * math.sin(a)), Offset(50 + (i.isEven ? 44 : 38) * math.cos(a), 50 + (i.isEven ? 44 : 38) * math.sin(a)),
          _line(i.isEven ? ink : accent, 3.5, 0.85));
    }
    c.drawCircle(const Offset(50, 50), 21, _fill(accent));
    c.drawCircle(const Offset(50, 50), 13, _fill(Vv.surface, 0.55));
  }

  void _meditate(Canvas c) {
    final body = _fill(ink, 0.9);
    c.drawCircle(const Offset(50, 22), 9, body);
    final torso = Path()
      ..moveTo(42, 33)
      ..quadraticBezierTo(50, 30, 58, 33)
      ..quadraticBezierTo(64, 50, 62, 66)
      ..lineTo(38, 66)
      ..quadraticBezierTo(36, 50, 42, 33)
      ..close();
    c.drawPath(torso, body);
    // Crossed legs.
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(18, 62, 64, 16), const Radius.circular(8)), body);
    // Arms resting on knees.
    c.drawPath(
        Path()
          ..moveTo(42, 38)
          ..quadraticBezierTo(30, 52, 24, 64),
        _line(ink, 6, 0.9));
    c.drawPath(
        Path()
          ..moveTo(58, 38)
          ..quadraticBezierTo(70, 52, 76, 64),
        _line(ink, 6, 0.9));
    c.drawCircle(const Offset(50, 22), 22, _line(accent, 2, 0.9));
    c.drawLine(const Offset(12, 88), const Offset(88, 88), _line(ink, 2, 0.3));
  }

  void _stretch(Canvas c) {
    final l = _line(ink, 6, 0.9);
    c.drawCircle(const Offset(50, 30), 7.5, _fill(ink, 0.9));
    c.drawLine(const Offset(50, 40), const Offset(50, 66), _line(ink, 9, 0.9));
    // Arms up, palms together.
    c.drawPath(
        Path()
          ..moveTo(47, 42)
          ..quadraticBezierTo(38, 26, 49, 8),
        l);
    c.drawPath(
        Path()
          ..moveTo(53, 42)
          ..quadraticBezierTo(62, 26, 51, 8),
        l);
    // Tree pose: one leg straight, one bent.
    c.drawLine(const Offset(49, 66), const Offset(47, 92), l);
    c.drawPath(
        Path()
          ..moveTo(52, 66)
          ..lineTo(66, 76)
          ..lineTo(50, 82),
        l);
    c.drawLine(const Offset(24, 94), const Offset(76, 94), _line(accent, 3, 0.9));
  }

  void _spine(Canvas c) {
    for (var i = 0; i < 7; i++) {
      final y = 12.0 + i * 11.5;
      final x = 50 + 9 * math.sin(i / 6 * math.pi * 1.2);
      c.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, y), width: 24.0 - i, height: 8), const Radius.circular(4)),
          _fill(i.isEven ? ink : accent, i.isEven ? 0.85 : 1));
    }
    c.drawArc(const Rect.fromLTWH(18, 20, 64, 70), -1.2, 2.4, false, _line(ink, 2, 0.25));
  }

  @override
  bool shouldRepaint(_ArtPainter old) => old.motif != motif || old.bg != bg || old.ink != ink || old.accent != accent;
}

/// Hair styles for [VaidyaPortrait].
enum Hair { short, long, bun, bald }

/// A friendly drawn head-and-shoulders portrait in a white coat with a
/// stethoscope, for Vaidya cards. Not a photo of a real person.
class VaidyaPortrait extends StatelessWidget {
  final Color skin;
  final Color hair;
  final Hair style;
  final Color bg;
  final bool beard;
  const VaidyaPortrait({
    super.key,
    this.skin = const Color(0xFFC68B63),
    this.hair = const Color(0xFF2B211C),
    this.style = Hair.short,
    this.bg = Vv.mint,
    this.beard = false,
  });

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: CustomPaint(painter: _PortraitPainter(this), child: const SizedBox.expand()),
      );
}

class _PortraitPainter extends CustomPainter {
  final VaidyaPortrait p;
  _PortraitPainter(this.p);

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    canvas.drawRect(r, Paint()..color = p.bg);
    canvas.save();
    canvas.clipRect(r);
    final s = size.shortestSide / 100;
    canvas.translate((size.width - 100 * s) / 2, (size.height - 100 * s) / 2);
    canvas.scale(s);

    Paint f(Color c) => Paint()..color = c;
    final shade = Color.lerp(p.skin, Colors.black, 0.18)!;

    // Long hair falls behind the shoulders.
    if (p.style == Hair.long) {
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(29, 26, 42, 52), const Radius.circular(20)), f(p.hair));
    }
    // White coat and a coloured top under it.
    final coat = Path()
      ..moveTo(12, 100)
      ..quadraticBezierTo(14, 76, 34, 72)
      ..lineTo(66, 72)
      ..quadraticBezierTo(86, 76, 88, 100)
      ..close();
    canvas.drawPath(coat, f(const Color(0xFFFFFDF8)));
    canvas.drawPath(
        Path()
          ..moveTo(40, 72)
          ..lineTo(50, 90)
          ..lineTo(60, 72)
          ..close(),
        f(Vv.green));
    // Neck.
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(43, 58, 14, 16), const Radius.circular(4)), f(shade));
    // Head.
    canvas.drawOval(const Rect.fromLTWH(32, 22, 36, 42), f(p.skin));
    // Ears.
    canvas.drawCircle(const Offset(32, 44), 4, f(p.skin));
    canvas.drawCircle(const Offset(68, 44), 4, f(p.skin));
    // Hair on top.
    if (p.style != Hair.bald) {
      final top = Path()
        ..moveTo(31, 42)
        ..quadraticBezierTo(28, 16, 50, 17)
        ..quadraticBezierTo(72, 16, 69, 42)
        ..quadraticBezierTo(62, 28, 50, 29)
        ..quadraticBezierTo(38, 28, 31, 42)
        ..close();
      canvas.drawPath(top, f(p.hair));
    }
    if (p.style == Hair.bun) canvas.drawCircle(const Offset(50, 15), 8, f(p.hair));
    if (p.beard) {
      canvas.drawPath(
          Path()
            ..moveTo(34, 48)
            ..quadraticBezierTo(36, 66, 50, 66)
            ..quadraticBezierTo(64, 66, 66, 48)
            ..quadraticBezierTo(58, 58, 50, 58)
            ..quadraticBezierTo(42, 58, 34, 48)
            ..close(),
          f(p.hair));
    }
    // Eyes and smile.
    final ink = f(const Color(0xFF2B211C));
    canvas.drawCircle(const Offset(43, 44), 1.8, ink);
    canvas.drawCircle(const Offset(57, 44), 1.8, ink);
    canvas.drawArc(const Rect.fromLTWH(44, 48, 12, 8), 0.3, 2.5, false,
        Paint()
          ..color = const Color(0xFF7A3A2A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round);
    // Stethoscope.
    final steth = Paint()
      ..color = Vv.deep
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
        Path()
          ..moveTo(38, 72)
          ..quadraticBezierTo(36, 88, 46, 90)
          ..moveTo(62, 72)
          ..quadraticBezierTo(64, 86, 58, 92),
        steth);
    canvas.drawCircle(const Offset(58, 94), 3.2, f(Vv.deep));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PortraitPainter old) => old.p != p;
}
