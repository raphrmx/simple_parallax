// Renders the pub.dev screenshots from the example's own screens.
//
// Run it from the example directory:
//   flutter test tool/record_screenshots.dart
//   python tool/assemble_screenshots.py
//
// The screens come from lib/main.dart rather than being rebuilt here, so a
// screenshot can never show something the example does not.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_parallax_example/main.dart';

/// Logical size of a screenshot, and the size the WebP ends up at.
const Size _size = Size(1200, 750);

/// Rendered at twice that, then halved when assembled.
const double _scale = 2;

const String _fontFamily = 'Screenshot';
const List<String> _fontCandidates = <String>[
  r'C:\Windows\Fonts\segoeui.ttf',
  '/System/Library/Fonts/Helvetica.ttc',
  '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
];

const Key _shot = Key('shot');

/// One screenshot: a file name, the screen to draw, and how far into its
/// content to scroll before the shutter, as a fraction of the scrollable
/// extent. A screen at rest shows less of the effect than one under way.
class _Shot {
  const _Shot(this.name, this.screen, this.at);

  final String name;
  final Widget screen;
  final double at;
}

const List<_Shot> _shots = <_Shot>[
  _Shot('container_mode', ContainerVerticalDemo(), 0.38),
  _Shot('item_mode', ItemVerticalDemo(), 0.26),
  _Shot('widget_background', ContainerCustomDemo(), 0.38),
  _Shot('sideways', ContainerHorizontalDemo(), 0.34),
];

/// Registers the icon font, which a test does not get on its own: without it
/// every icon draws as an empty box.
Future<void> _loadIcons() async {
  final String? flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot == null) {
    throw StateError('FLUTTER_ROOT is not set, cannot find the icon font');
  }
  final File file = File(
    '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (!file.existsSync()) {
    throw StateError('no icon font at ${file.path}');
  }
  final FontLoader loader = FontLoader('MaterialIcons');
  loader.addFont(
    Future<ByteData>.value(ByteData.view(file.readAsBytesSync().buffer)),
  );
  await loader.load();
}

Future<void> _loadFont() async {
  for (final String path in _fontCandidates) {
    final File file = File(path);
    if (!file.existsSync()) {
      continue;
    }
    final FontLoader loader = FontLoader(_fontFamily);
    loader.addFont(
      Future<ByteData>.value(ByteData.view(file.readAsBytesSync().buffer)),
    );
    await loader.load();
    return;
  }
  throw StateError('no font found among $_fontCandidates');
}

/// Decodes every picture on screen with the provider its [Image] draws, then
/// settles.
///
/// Precaching the asset is not enough: the widgets decode it at the size they
/// draw it, which is a key of its own in the image cache, so a precached asset
/// would leave the backgrounds blank.
Future<void> _decodeOnScreen(WidgetTester tester) async {
  final List<Element> images = find.byType(Image).evaluate().toList();
  await tester.runAsync(() async {
    for (final Element element in images) {
      await precacheImage((element.widget as Image).image, element);
    }
  });
  await tester.pumpAndSettle();
}

/// Whether a picture on screen is still waiting for its decode.
bool _undecoded(WidgetTester tester) => find
    .byType(RawImage)
    .evaluate()
    .any((Element element) => (element.widget as RawImage).image == null);

void main() {
  testWidgets(
    'render the screenshots',
    (WidgetTester tester) async {
      await _loadFont();
      await _loadIcons();
      await tester.binding.setSurfaceSize(_size);
      tester.view.devicePixelRatio = _scale;
      tester.view.physicalSize = _size * _scale;

      final Directory out = Directory('build/screenshots')
        ..createSync(recursive: true);

      for (final _Shot shot in _shots) {
        await tester.pumpWidget(
          RepaintBoundary(
            key: _shot,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              scrollBehavior: ExampleApp.scrollBehavior,
              theme: ExampleApp.theme.copyWith(
                textTheme: ExampleApp.theme.textTheme.apply(
                  fontFamily: _fontFamily,
                ),
              ),
              home: shot.screen,
            ),
          ),
        );

        await _decodeOnScreen(tester);

        final ScrollableState scrollable = tester.state(
          find.byType(Scrollable).first,
        );
        final double max = scrollable.position.maxScrollExtent;
        scrollable.position.jumpTo((max * shot.at).clamp(0.0, max));
        await tester.pumpAndSettle();
        if (_undecoded(tester)) await _decodeOnScreen(tester);

        final RenderRepaintBoundary boundary =
            tester.renderObject(find.byKey(_shot)) as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final ui.Image image = await boundary.toImage(pixelRatio: _scale);
          final ByteData? png = await image.toByteData(
            format: ui.ImageByteFormat.png,
          );
          image.dispose();
          File('${out.path}/${shot.name}.png').writeAsBytesSync(
            png!.buffer.asUint8List(),
          );
        });
        // ignore: avoid_print
        print('${shot.name}: at ${(max * shot.at).toStringAsFixed(0)} of '
            '${max.toStringAsFixed(0)}');
      }
    },
    timeout: const Timeout(
      Duration(minutes: 5),
    ),
  );
}
