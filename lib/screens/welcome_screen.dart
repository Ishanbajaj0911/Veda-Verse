import 'package:flutter/material.dart';
import 'package:veda_verse/l10n/lang.dart';
import 'package:veda_verse/screens/login_screen.dart';
import 'package:veda_verse/state/app_state.dart';
import 'package:veda_verse/theme/vv.dart';

class _Tile {
  final String label;
  final double x, y, w;
  final Color ink, tint;
  const _Tile(this.label, this.x, this.y, this.w, this.ink, this.tint);
}

const _tiles = [
  _Tile('Can’t sleep', 20, 40, 108, Vv.blue, Vv.bluePale),
  _Tile('Always stressed', 140, 62, 118, Vv.plum, Vv.plumPale),
  _Tile('Acidity after meals', 282, 70, 92, Vv.brown, Vv.goldPale),
  _Tile('Desk-job back pain', 40, 150, 112, Vv.rust, Vv.rustPale),
  _Tile('Low energy by 4 pm', 172, 144, 104, Vv.brown, Vv.goldPale),
  _Tile('Weight creeping up', 290, 188, 84, Vv.green, Vv.mint),
  _Tile('Don’t know my body type', 22, 520, 118, Vv.brown, Vv.goldPale),
  _Tile('Same diet advice for all', 160, 558, 98, Vv.plum, Vv.plumPale),
  _Tile('Herbs with my BP pills?', 274, 508, 98, Vv.red, Vv.redPale),
  _Tile('No Vaidya nearby', 36, 636, 104, Vv.green, Vv.mint),
  _Tile('Advice not in Hindi', 156, 664, 100, Vv.blue, Vv.bluePale),
  _Tile('Habits never stick', 272, 626, 98, Vv.rust, Vv.rustPale),
];

/// "Who it's for" – the first screen.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final Set<int> _on = {0, 1};

  String get _hint {
    final n = _on.length;
    if (n == 0) return tr('Tap what sounds like you');
    if (n == 1) return tr('1 sounds like you — let’s fix that');
    return trf('{n} sound like you — let’s fix that', {'n': n});
  }

  void _go() {
    AppState.instance.update((s) {
      s.welcomeTiles = _on.map((i) => _tiles[i].label).toSet();
      s.issues = {
        for (final i in _on)
          if (_tiles[i].label == 'Can’t sleep') 'Can’t sleep',
        for (final i in _on)
          if (_tiles[i].label == 'Always stressed') 'Always stressed',
        for (final i in _on)
          if (_tiles[i].label == 'Acidity after meals') 'Acidity',
        for (final i in _on)
          if (_tiles[i].label == 'Desk-job back pain') 'Back pain',
        for (final i in _on)
          if (_tiles[i].label == 'Low energy by 4 pm') 'Low energy',
        for (final i in _on)
          if (_tiles[i].label == 'Weight creeping up') 'Weight gain',
      };
    });
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Vv.paleBg,
      body: VvFrame(
        color: Vv.paleBg,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, c) {
              final scale = c.maxWidth / Vv.frame;
              final yScale = (c.maxHeight / 844).clamp(0.78, 1.0);
              return Stack(
                children: [
                  for (var i = 0; i < _tiles.length; i++)
                    Positioned(
                      left: _tiles[i].x * scale,
                      top: _tiles[i].y * yScale,
                      width: _tiles[i].w * scale,
                      child: _TileButton(
                        tile: _tiles[i],
                        on: _on.contains(i),
                        onTap: () => setState(() => _on.contains(i) ? _on.remove(i) : _on.add(i)),
                      ),
                    ),
                  Positioned(
                    right: 16,
                    top: 14,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Vv.surface,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: const [
                          BoxShadow(color: Color(0x1417251C), blurRadius: 12, offset: Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _langButton('EN', Lang.en, 13),
                          _langButton('हिंदी', Lang.hiCode, 14),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    top: 296 * yScale,
                    child: IgnorePointer(
                      child: Column(
                        children: [
                          Text(tr('VEDAVERSE IS FOR'),
                              style: Vv.sans(12, weight: FontWeight.w800, color: Vv.muted, letterSpacing: Lang.hi ? 0.4 : 1.6)),
                          const SizedBox(height: 12),
                          Text.rich(
                            TextSpan(
                              style: Vv.serif(Lang.hi ? 34 : 44, weight: FontWeight.w500, height: Lang.hi ? 1.3 : 0.98, letterSpacing: -0.5),
                              children: [
                                TextSpan(text: tr('EVERY BODY\nOUT OF ')),
                                TextSpan(
                                  text: tr('rhythm'),
                                  style: Vv.serif(Lang.hi ? 34 : 44, weight: FontWeight.w500, italic: true, color: Vv.green, height: Lang.hi ? 1.3 : 0.98),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            tr('The stressed, the sleepless and the curious —\nwherever they live, in their own language.'),
                            textAlign: TextAlign.center,
                            style: Vv.serif(16, weight: FontWeight.w500, italic: true, color: Vv.ink2, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 22,
                    child: Column(
                      children: [
                        Text(_hint, style: Vv.sans(12, weight: FontWeight.w700, color: Vv.ink2)),
                        const SizedBox(height: 8),
                        VvButton(
                          label: tr('Find my rhythm'),
                          bg: Vv.deep,
                          fg: Vv.bg,
                          trailing: Icons.arrow_forward_rounded,
                          onTap: _go,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _langButton(String l, String code, double size) {
    final on = Lang.code == code;
    return VvTap(
      // Switches the whole app, this screen included, at once.
      onTap: () => Lang.set(code),
      child: Container(
        constraints: const BoxConstraints(minHeight: 36),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? Vv.deep : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(l, style: Vv.sans(size, weight: FontWeight.w700, color: on ? Vv.bg : Vv.ink)),
      ),
    );
  }
}

class _TileButton extends StatelessWidget {
  final _Tile tile;
  final bool on;
  final VoidCallback onTap;
  const _TileButton({required this.tile, required this.on, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return VvTap(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: on ? tile.ink : tile.tint,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: on ? tile.ink : Colors.transparent, width: 1.5),
          boxShadow: const [BoxShadow(color: Color(0x1417251C), blurRadius: 14, offset: Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: on ? Vv.goldLight : tile.ink, shape: BoxShape.circle),
            ),
            const SizedBox(height: 6),
            Text(
              tr(tile.label),
              style: Vv.sans(12.5, weight: FontWeight.w700, color: on ? Vv.surface : tile.ink, height: 1.25),
            ),
          ],
        ),
      ),
    );
  }
}
