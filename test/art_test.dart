// Draws every illustration, portrait and bundled photo. Fails on any error.
// Set VV_SHOTS=<dir> to save art.png for a visual check.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veda_verse/widgets/art.dart';

void main() {
  testWidgets('every illustration, portrait and photo draws', (t) async {
    final v = t.platformDispatcher.views.first;
    v.physicalSize = const Size(600, 760);
    v.devicePixelRatio = 1;
    addTearDown(v.reset);
    const photos = [VvImages.tulsi, VvImages.neem, VvImages.turmeric, VvImages.ashwagandha, VvImages.yogaTree, VvImages.meditation];
    final tiles = <Widget>[
      for (final m in ArtMotif.values) VvArt.themed(m),
      const VaidyaPortrait(),
      const VaidyaPortrait(style: Hair.long, skin: Color(0xFFD9A07A)),
      const VaidyaPortrait(style: Hair.bun, skin: Color(0xFFB57A55), bg: Color(0xFFF7EAD0)),
      const VaidyaPortrait(style: Hair.short, beard: true, hair: Color(0xFF6B6B6B)),
      for (final p in photos) VvPhoto(p, alignment: p == VvImages.meditation ? Alignment.bottomCenter : Alignment.center),
    ];
    await t.pumpWidget(MaterialApp(
      home: RepaintBoundary(
        key: const ValueKey('shot'),
        child: Material(
          child: GridView.count(
            crossAxisCount: 4,
            padding: const EdgeInsets.all(8),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.2,
            children: [for (final w in tiles) ClipRRect(borderRadius: BorderRadius.circular(12), child: w)],
          ),
        ),
      ),
    ));
    await t.runAsync(() async {
      for (final p in photos) {
        await precacheImage(AssetImage(p), t.element(find.byType(GridView)));
      }
    });
    await t.pump();
    expect(t.takeException(), isNull);
    final dir = Platform.environment['VV_SHOTS'];
    if (dir != null) {
      final b = t.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('shot')));
      await t.runAsync(() async {
        final img = await b.toImage(pixelRatio: 1);
        final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
        File('$dir/art.png').writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    }
  });
}
