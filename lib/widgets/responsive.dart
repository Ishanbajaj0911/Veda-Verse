import 'dart:ui';

import 'package:flutter/material.dart';

/// Width at or above which the app switches to a desktop layout.
const double kDesktopBreakpoint = 900;

/// Maximum width of page content on large screens.
const double kContentMaxWidth = 1100;

bool isWideScreen(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= kDesktopBreakpoint;

/// Centers [child] horizontally and caps its width so content does not
/// stretch edge to edge on desktop windows.
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = kContentMaxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Lets carousels and horizontal lists be dragged with a mouse or trackpad,
/// which Flutter disables by default on desktop and web.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}
