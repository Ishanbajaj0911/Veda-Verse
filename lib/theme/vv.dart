import 'package:flutter/material.dart';

/// VedaVerse design tokens, ported from the "VedaVerse App UI" design file.
class Vv {
  Vv._();

  // Surfaces
  static const bg = Color(0xFFF6F2EA);
  static const surface = Color(0xFFFFFDF8);
  static const paleBg = Color(0xFFEAE4D8);
  static const divider = Color(0xFFF1ECE1);
  static const border = Color(0xFFE8E2D4);
  static const border2 = Color(0xFFE2DCCD);
  static const border3 = Color(0xFFD9D1BF);
  static const shade = Color(0xFFECE6D9);

  // Ink
  static const ink = Color(0xFF17251C);
  static const ink2 = Color(0xFF3F4F44);
  static const muted = Color(0xFF5E675F);
  static const disabled = Color(0xFFB7B0A2);

  // Greens
  static const deep = Color(0xFF163A2E);
  static const deeper = Color(0xFF143D2E);
  static const green = Color(0xFF1E5A44);
  static const mint = Color(0xFFE5EBDC);
  static const mintBorder = Color(0xFFBFD0B7);
  static const sage = Color(0xFFA9B8AD);
  static const sage2 = Color(0xFFA9B3A9);
  static const leaf = Color(0xFFA9C98F);
  static const onDeepMuted = Color(0xFFB9CBBE);
  static const onDeepMuted2 = Color(0xFFCBD8CE);
  static const onDeepMuted3 = Color(0xFFC9D6CC);
  static const live = Color(0xFF3C9A5F);

  // Golds
  static const gold = Color(0xFFE2A23B);
  static const goldLight = Color(0xFFF0C46C);
  static const goldSoft = Color(0xFFF2B866);
  static const goldPale = Color(0xFFF7EAD0);
  static const goldRing = Color(0xFFE8C77A);
  static const goldBorder = Color(0xFFF2C98F);
  static const cream = Color(0xFFFFF6E9);
  static const brown = Color(0xFF8A4B06);
  static const brownDark = Color(0xFF5A3204);
  static const brownDeep = Color(0xFF3A2003);
  static const amberBg = Color(0xFFFBF0D6);
  static const amberInk = Color(0xFF6B4600);

  // Plum (Learn / PCOS)
  static const plum = Color(0xFF7A3560);
  static const plumPale = Color(0xFFF3E3EC);
  static const plumInk = Color(0xFF5A2547);
  static const plumSoft = Color(0xFFF3C6DE);
  static const plumSofter = Color(0xFFF7DDEB);
  static const plumBg = Color(0xFFFFF7FB);
  static const plumBorder = Color(0xFFE7C9D9);
  static const plumBar = Color(0xFFC98BAE);

  // Blue (Buddy)
  static const blue = Color(0xFF3A4F8C);
  static const blueInk = Color(0xFF2C3E73);
  static const blueDark = Color(0xFF20456D);
  static const bluePale = Color(0xFFE3E8F4);
  static const bluePale2 = Color(0xFFE1EAF4);
  static const blueMuted = Color(0xFFD3D9EA);
  static const blueTint = Color(0xFFF3F5FB);

  // Rust (Yoga)
  static const rust = Color(0xFF8E3B22);
  static const rustPale = Color(0xFFF6E1D8);

  // Red
  static const red = Color(0xFFB3261E);
  static const redPale = Color(0xFFFBE9E8);
  static const redInk = Color(0xFF8C1D18);
  static const redBorder = Color(0xFFE6B7B3);

  // Dosha bar colours
  static const vataBar = Color(0xFF8FB4DD);
  static const vataBar2 = Color(0xFF9DB7E0);
  static const pittaBar = Color(0xFFF2B866);
  static const kaphaBar = Color(0xFF9CC48A);

  static const double frame = 390;

  /// Romie (serif) – headings.
  static TextStyle serif(
    double size, {
    FontWeight weight = FontWeight.w500,
    bool italic = false,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: 'Romie',
      fontSize: size,
      fontWeight: weight,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Manrope (sans) – body and UI. Bundled as a variable font, so the weight
  /// is applied through the `wght` axis (works offline, no runtime fetch).
  static TextStyle sans(
    double size, {
    FontWeight weight = FontWeight.w500,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: 'Manrope',
      fontSize: size,
      fontWeight: weight,
      fontVariations: [FontVariation('wght', weight.value.toDouble())],
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle kicker(Color color, {double size = 12, double spacing = 1}) =>
      sans(size, weight: FontWeight.w800, color: color, letterSpacing: spacing);

  static ThemeData theme() {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: green,
        primary: green,
        surface: surface,
      ),
      splashFactory: InkSparkle.splashFactory,
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: 'Manrope',
        bodyColor: ink,
        displayColor: ink,
      ),
      inputDecorationTheme: const InputDecorationTheme(border: InputBorder.none),
    );
  }
}

/// Current Ritu (Ayurvedic season) label for a date, simplified.
String rituFor(DateTime d) {
  const map = {
    1: 'Shishira Ritu (late winter)',
    2: 'Shishira Ritu (late winter)',
    3: 'Vasanta Ritu (spring)',
    4: 'Vasanta Ritu (spring)',
    5: 'Grishma Ritu (summer)',
    6: 'Grishma Ritu (summer)',
    7: 'Varsha Ritu (monsoon)',
    8: 'Varsha Ritu (monsoon)',
    9: 'Sharad Ritu (autumn)',
    10: 'Sharad Ritu (autumn)',
    11: 'Hemanta Ritu (early winter)',
    12: 'Hemanta Ritu (early winter)',
  };
  return map[d.month]!;
}

String weekdayName(DateTime d) => const [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ][d.weekday - 1];

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

/// Constrains a screen to the 390px design frame on wide screens.
class VvFrame extends StatelessWidget {
  final Widget child;
  final Color color;
  const VvFrame({super.key, required this.child, this.color = Vv.bg});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: child,
        ),
      ),
    );
  }
}

/// The VedaVerse leaf logo from the design (120x120 viewBox).
class VvLogo extends StatelessWidget {
  final double size;
  final Color leaf;
  final Color sides;
  final Color sun;
  const VvLogo({
    super.key,
    this.size = 28,
    this.leaf = Vv.leaf,
    this.sides = Vv.bg,
    this.sun = Vv.gold,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _LogoPainter(leaf, sides, sun),
    );
  }
}

class _LogoPainter extends CustomPainter {
  final Color leaf, sides, sun;
  _LogoPainter(this.leaf, this.sides, this.sun);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 120;
    canvas.scale(s);
    final p1 = Path()
      ..moveTo(60, 22)
      ..cubicTo(80, 44, 80, 76, 60, 100)
      ..cubicTo(40, 76, 40, 44, 60, 22)
      ..close();
    final p2 = Path()
      ..moveTo(55, 102)
      ..cubicTo(32, 96, 15, 76, 13, 50)
      ..cubicTo(33, 56, 48, 74, 55, 102)
      ..close();
    final p3 = Path()
      ..moveTo(65, 102)
      ..cubicTo(88, 96, 105, 76, 107, 50)
      ..cubicTo(87, 56, 72, 74, 65, 102)
      ..close();
    canvas.drawPath(p1, Paint()..color = leaf);
    canvas.drawPath(p2, Paint()..color = sides);
    canvas.drawPath(p3, Paint()..color = sides);
    canvas.drawCircle(const Offset(60, 10), 8, Paint()..color = sun);
  }

  @override
  bool shouldRepaint(_LogoPainter old) =>
      old.leaf != leaf || old.sides != sides || old.sun != sun;
}

/// Concentric decorative rings, as used on the dark hero cards.
class VvRings extends StatelessWidget {
  final double size;
  final double right;
  final double top;
  final double? bottom;
  final Color color;
  final double opacity;
  final bool cross;
  const VvRings({
    super.key,
    this.size = 200,
    this.right = -70,
    this.top = -70,
    this.bottom,
    this.color = Vv.goldRing,
    this.opacity = 0.16,
    this.cross = false,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: right,
      top: bottom == null ? top : null,
      bottom: bottom,
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity,
          child: CustomPaint(
            size: Size.square(size),
            painter: _RingsPainter(color, cross),
          ),
        ),
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  final Color color;
  final bool cross;
  _RingsPainter(this.color, this.cross);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final radii = cross
        ? [r * 40 / 150, r * 70 / 150, r * 100 / 150, r * 130 / 150]
        : [r * 30 / 110, r * 60 / 110, r * 90 / 110];
    for (final rr in radii) {
      canvas.drawCircle(c, rr, paint);
    }
    if (cross) {
      canvas.drawLine(Offset(c.dx, 0), Offset(c.dx, size.height), paint);
      canvas.drawLine(Offset(0, c.dy), Offset(size.width, c.dy), paint);
      final d = r * 92 / 150;
      canvas.drawLine(Offset(c.dx - d, c.dy - d), Offset(c.dx + d, c.dy + d), paint);
      canvas.drawLine(Offset(c.dx + d, c.dy - d), Offset(c.dx - d, c.dy + d), paint);
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) => old.color != color || old.cross != cross;
}

/// Rounded tap target with the design's scale-down press feedback.
class VvTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const VvTap({super.key, required this.child, this.onTap});

  @override
  State<VvTap> createState() => _VvTapState();
}

class _VvTapState extends State<VvTap> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.96 : 1,
        duration: const Duration(milliseconds: 120),
        child: widget.child,
      ),
    );
  }
}

/// Square icon button with a border, used for "Back".
class VvSquareButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color bg;
  final Color fg;
  final Color? borderColor;
  const VvSquareButton({
    super.key,
    required this.icon,
    this.onTap,
    this.bg = Vv.surface,
    this.fg = Vv.ink,
    this.borderColor = Vv.border2,
  });

  @override
  Widget build(BuildContext context) {
    return VvTap(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: borderColor == null ? null : Border.all(color: borderColor!),
        ),
        child: Icon(icon, size: 22, color: fg),
      ),
    );
  }
}

class VvBackButton extends StatelessWidget {
  final VoidCallback? onTap;
  const VvBackButton({super.key, this.onTap});
  @override
  Widget build(BuildContext context) => VvSquareButton(
        icon: Icons.chevron_left_rounded,
        onTap: onTap ?? () => Navigator.of(context).maybePop(),
      );
}

/// Dark-green logo tile used at the top-left of tab screens.
class VvLogoTile extends StatelessWidget {
  final VoidCallback? onTap;
  const VvLogoTile({super.key, this.onTap});
  @override
  Widget build(BuildContext context) => VvTap(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Vv.deep,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Center(child: VvLogo(size: 28)),
        ),
      );
}

/// Round avatar initial used as the profile entry point.
class VvAvatar extends StatelessWidget {
  final String initial;
  final double size;
  final double fontSize;
  final VoidCallback? onTap;
  const VvAvatar({
    super.key,
    required this.initial,
    this.size = 44,
    this.fontSize = 15,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => VvTap(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(color: Vv.green, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: Vv.serif(fontSize, weight: FontWeight.w700, color: Vv.surface),
          ),
        ),
      );
}

/// Primary filled button (height 54/56).
class VvButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color bg;
  final Color fg;
  final double height;
  final IconData? trailing;
  final IconData? leading;
  final FontWeight weight;
  final double fontSize;
  final Color? borderColor;
  const VvButton({
    super.key,
    required this.label,
    this.onTap,
    this.bg = Vv.green,
    this.fg = Vv.surface,
    this.height = 54,
    this.trailing,
    this.leading,
    this.weight = FontWeight.w700,
    this.fontSize = 16,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return VvTap(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: borderColor == null ? null : Border.all(color: borderColor!, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leading != null) ...[
              Icon(leading, size: 18, color: fg),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Vv.sans(fontSize, weight: weight, color: fg),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              Icon(trailing, size: 18, color: fg),
            ],
          ],
        ),
      ),
    );
  }
}

/// Pill chip (filters, multi-select).
class VvChip extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback? onTap;
  final Color onColor;
  final double minHeight;
  final double fontSize;
  final double hPad;
  final double radius;
  const VvChip({
    super.key,
    required this.label,
    required this.on,
    this.onTap,
    this.onColor = Vv.green,
    this.minHeight = 40,
    this.fontSize = 13,
    this.hPad = 14,
    this.radius = 999,
  });

  @override
  Widget build(BuildContext context) {
    return VvTap(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: minHeight),
        padding: EdgeInsets.symmetric(horizontal: hPad),
        decoration: BoxDecoration(
          color: on ? onColor : Vv.surface,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: on ? onColor : Vv.border3, width: 1.5),
        ),
        child: Center(
          widthFactor: 1,
          child: Text(
            label,
            style: Vv.sans(fontSize, weight: FontWeight.w700, color: on ? Vv.surface : Vv.ink),
          ),
        ),
      ),
    );
  }
}

/// Segmented control on a mint track.
class VvSegments extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  final double height;
  final List<IconData>? icons;
  const VvSegments({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
    this.height = 40,
    this.icons,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Vv.mint, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: VvTap(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: height,
                  decoration: BoxDecoration(
                    color: i == index ? Vv.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icons != null) ...[
                        Icon(icons![i], size: 16, color: i == index ? Vv.ink : Vv.ink2),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        labels[i],
                        style: Vv.sans(13, weight: FontWeight.w700, color: i == index ? Vv.ink : Vv.ink2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Toggle switch matching the design (52x32, green when on).
class VvSwitch extends StatelessWidget {
  final bool on;
  final VoidCallback? onTap;
  final double width;
  final double height;
  const VvSwitch({super.key, required this.on, this.onTap, this.width = 52, this.height = 32});

  @override
  Widget build(BuildContext context) {
    final knob = height - 6;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: width,
        height: height,
        padding: const EdgeInsets.all(3),
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(
          color: on ? Vv.green : Vv.sage,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Container(
          width: knob,
          height: knob,
          decoration: const BoxDecoration(color: Vv.surface, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

/// White card with the standard 1px border.
class VvCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;
  final Color? borderColor;
  const VvCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
    this.color = Vv.surface,
    this.borderColor = Vv.border,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
          border: borderColor == null ? null : Border.all(color: borderColor!),
        ),
        child: child,
      );
}

/// "Hello, Name / Title" header used on tab screens.
class VvTabHeader extends StatelessWidget {
  final String hello;
  final Widget title;
  final String initial;
  final VoidCallback? onLogo;
  final VoidCallback? onProfile;
  final Widget? extra;
  const VvTabHeader({
    super.key,
    required this.hello,
    required this.title,
    required this.initial,
    this.onLogo,
    this.onProfile,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      child: Row(
        children: [
          VvLogoTile(onTap: onLogo),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hello, style: Vv.sans(13, weight: FontWeight.w600, color: Vv.muted)),
                const SizedBox(height: 2),
                title,
              ],
            ),
          ),
          if (extra != null) ...[extra!, const SizedBox(width: 10)],
          VvAvatar(initial: initial, onTap: onProfile),
        ],
      ),
    );
  }
}

/// Small shield + text note.
class VvNote extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;
  final TextStyle? style;
  const VvNote({super.key, required this.text, this.color = Vv.muted, this.icon = Icons.shield_outlined, this.style});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: style ?? Vv.sans(12, color: color, height: 1.5))),
        ],
      );
}

/// Rich serif heading with an italic (optionally coloured) second part.
class SerifTitle extends StatelessWidget {
  final String a;
  final String b;
  final double size;
  final Color color;
  final Color? bColor;
  final FontWeight weight;
  final double height;
  final TextAlign align;
  final double? letterSpacing;
  const SerifTitle(
    this.a,
    this.b, {
    super.key,
    this.size = 28,
    this.color = Vv.ink,
    this.bColor,
    this.weight = FontWeight.w500,
    this.height = 1.1,
    this.align = TextAlign.start,
    this.letterSpacing,
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: Vv.serif(size, weight: weight, color: color, height: height, letterSpacing: letterSpacing),
        children: [
          TextSpan(text: a),
          TextSpan(text: b, style: Vv.serif(size, weight: weight, italic: true, color: bColor ?? color, height: height)),
        ],
      ),
      textAlign: align,
    );
  }
}
