// Renders the README previews frame by frame.
//
// Run it from the example directory:
//   flutter test tool/record_previews.dart
//
// It writes PNG frames under build/previews/<name>/, which
// tool/assemble_previews.py turns into the animated WebP files in doc/.
//
// The frames are rendered rather than captured, so the motion is exactly
// regular: each frame is a scroll offset this file computes, not a moment a
// recorder happened to catch.

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_parallax/simple_parallax.dart';

/// Logical size of a preview, and the size the WebP ends up at.
const Size _size = Size(520, 260);

/// Rendered at twice the logical size, then halved when assembled, so the text
/// and the image edges survive the shrink.
const double _scale = 2;

/// Frames in one loop, and the frame rate they are played back at.
const int _frames = 60;

/// Font the previews are typeset in, taken from the host rather than bundled.
const String _fontFamily = 'Preview';
const List<String> _fontCandidates = <String>[
  r'C:\Windows\Fonts\segoeui.ttf',
  '/System/Library/Fonts/Helvetica.ttc',
  '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
];

const AssetImage _photo = AssetImage('assets/images/background.webp');
const Key _shot = Key('shot');

const Color _ink = Color(0xFF14110F);
const Color _muted = Color(0xFF6B635C);
const Color _panel = Color(0xFFF7F4F1);
const Color _card = Color(0xFFFCFAF8);

/// One entry of the scrolling content, a coloured dot and two lines.
class _Note {
  const _Note(this.dot, this.title, this.detail);

  final Color dot;
  final String title;
  final String detail;
}

const List<_Note> _notes = <_Note>[
  _Note(
    Color(0xFF2F6FED),
    'Coastal ridge',
    'Eleven kilometres, four hours, no shade after the pass.',
  ),
  _Note(
    Color(0xFFE0446B),
    'Trail notes',
    'Water at the refuge only. The upper section stays icy.',
  ),
  _Note(
    Color(0xFF2FA36B),
    'Gear list',
    'Poles, two litres, a shell. Leave the rope behind.',
  ),
  _Note(
    Color(0xFFEBB53C),
    'Weather',
    'Clear until the afternoon, then wind from the south.',
  ),
  _Note(
    Color(0xFF7A5AF0),
    'Getting there',
    'Bus at 6.40 from the village, last one back at 19.10.',
  ),
  _Note(
    Color(0xFFE8734A),
    'Permits',
    'None needed below the col. The reserve asks for one.',
  ),
  _Note(
    Color(0xFF3FB6C4),
    'Signal',
    'Patchy along the ridge, nothing at all in the valley.',
  ),
];

TextStyle _style(
  double size,
  FontWeight weight,
  Color color, {
  double? height,
}) {
  return TextStyle(
    fontFamily: _fontFamily,
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: weight == FontWeight.w600 ? -0.2 : 0,
  );
}

/// A note as a row of the vertical content.
Widget _rowCard(_Note note) {
  return Container(
    height: 62,
    margin: const EdgeInsets.fromLTRB(84, 9, 84, 9),
    padding: const EdgeInsets.symmetric(horizontal: 18),
    decoration: BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(12),
      boxShadow: const <BoxShadow>[
        BoxShadow(
          color: Color(0x2B000000),
          blurRadius: 14,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Row(
      children: <Widget>[
        Container(
          width: 13,
          height: 13,
          decoration: BoxDecoration(color: note.dot, shape: BoxShape.circle),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(note.title, style: _style(13, FontWeight.w600, _ink)),
              const SizedBox(height: 3),
              Text(note.detail, style: _style(10, FontWeight.w400, _muted)),
            ],
          ),
        ),
      ],
    ),
  );
}

/// A note as a card of the sideways content.
Widget _sideCard(_Note note) {
  return Center(
    child: Container(
      width: 186,
      height: 168,
      margin: const EdgeInsets.symmetric(horizontal: 9),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x2B000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(color: note.dot, shape: BoxShape.circle),
          ),
          const Spacer(),
          Text(note.title, style: _style(14, FontWeight.w600, _ink)),
          const SizedBox(height: 5),
          Text(
            note.detail,
            style: _style(10, FontWeight.w400, _muted, height: 1.45),
          ),
        ],
      ),
    ),
  );
}

/// A block of prose between two parallax items.
Widget _prose(String heading, String body, {double? height, double? width}) {
  return Container(
    height: height,
    width: width,
    color: _panel,
    padding: const EdgeInsets.fromLTRB(84, 26, 84, 26),
    alignment: Alignment.centerLeft,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(heading, style: _style(15, FontWeight.w600, _ink)),
        const SizedBox(height: 7),
        Text(body, style: _style(10, FontWeight.w400, _muted, height: 1.6)),
      ],
    ),
  );
}

/// The overline and title drawn over a parallax item.
Widget _caption(String overline, String title) {
  return DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.center,
        end: Alignment.bottomCenter,
        colors: <Color>[Color(0x00000000), Color(0xA6000000)],
      ),
    ),
    child: Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              overline,
              style: TextStyle(
                fontFamily: _fontFamily,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.4,
                color: const Color(0xFFFFFFFF).withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: _style(19, FontWeight.w600, const Color(0xFFFFFFFF)),
            ),
          ],
        ),
      ),
    ),
  );
}

/// The gradient standing in for an image in the widget background preview.
const Widget _gradient = DecoratedBox(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[Color(0xFF1B1464), Color(0xFFB4436C), Color(0xFFFFB25B)],
    ),
  ),
);

/// One preview: a name, the widget to render, and how far it scrolls.
class _Preview {
  const _Preview(this.name, this.build);

  final String name;
  final Widget Function(ScrollController controller) build;
}

final List<_Preview> _previews = <_Preview>[
  _Preview(
    'container_mode',
    (ScrollController c) => SimpleParallaxContainer(
      image: _photo,
      parallax: const ParallaxProperties(speed: 0.8, overscan: 1.6),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 10),
          for (final _Note n in _notes) _rowCard(n),
          const SizedBox(height: 10),
        ],
      ),
    ),
  ),
  _Preview(
    'container_mode_horizontal',
    (ScrollController c) => SimpleParallaxContainer(
      image: _photo,
      scrollDirection: Axis.horizontal,
      parallax: const ParallaxProperties(speed: 0.8, overscan: 1.6),
      child: Row(
        children: <Widget>[
          const SizedBox(width: 8),
          for (final _Note n in _notes) _sideCard(n),
          const SizedBox(width: 8),
        ],
      ),
    ),
  ),
  _Preview(
    'item_mode',
    (ScrollController c) => SimpleParallaxWidget(
      controller: c,
      children: <Widget>[
        _prose(
          'Two days on the ridge',
          'The path leaves the road just past the bridge and climbs steadily '
              'for the first hour.',
          height: 132,
        ),
        SimpleParallaxItem(
          image: _photo,
          height: 210,
          parallax: ParallaxProperties(overscan: 2),
          child: _caption('DAY ONE', 'The southern pass'),
        ),
        _prose(
          'Where to stop',
          'The refuge sits a little below the col. It fills up quickly in '
              'August, so book ahead.',
          height: 132,
        ),
        SimpleParallaxItem(
          image: _photo,
          height: 210,
          parallax: ParallaxProperties(speed: 0.45, overscan: 2),
          child: _caption('DAY TWO', 'Down to the lake'),
        ),
        _prose(
          'Getting back',
          'The last bus leaves at ten past seven, from the same stop.',
          height: 132,
        ),
      ],
    ),
  ),
  _Preview(
    'item_mode_horizontal',
    (ScrollController c) => SimpleParallaxWidget(
      controller: c,
      scrollDirection: Axis.horizontal,
      children: <Widget>[
        _prose(
          'Two days on the ridge',
          'The path leaves the road just past the bridge and climbs '
              'steadily.',
          width: 260,
        ),
        SimpleParallaxItem(
          image: _photo,
          width: 300,
          parallax: ParallaxProperties(overscan: 2),
          child: _caption('DAY ONE', 'The southern pass'),
        ),
        _prose(
          'Where to stop',
          'The refuge sits below the col and fills up quickly in August.',
          width: 260,
        ),
        SimpleParallaxItem(
          image: _photo,
          width: 300,
          parallax: ParallaxProperties(speed: 0.45, overscan: 2),
          child: _caption('DAY TWO', 'Down to the lake'),
        ),
        _prose(
          'Getting back',
          'The last bus leaves at ten past seven.',
          width: 260,
        ),
      ],
    ),
  ),
  _Preview(
    'widget_background',
    (ScrollController c) => SimpleParallaxContainer(
      background: _gradient,
      parallax: const ParallaxProperties(speed: 0.8, overscan: 1.6),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 10),
          for (final _Note n in _notes) _rowCard(n),
          const SizedBox(height: 10),
        ],
      ),
    ),
  ),
];

Future<void> _loadFont() async {
  for (final String path in _fontCandidates) {
    final File file = File(path);
    if (!file.existsSync()) {
      continue;
    }
    final FontLoader loader = FontLoader(_fontFamily);
    loader.addFont(
      Future<ByteData>.value(
        ByteData.view(Uint8List.fromList(file.readAsBytesSync()).buffer),
      ),
    );
    await loader.load();
    return;
  }
  throw StateError('no font found among $_fontCandidates');
}

void main() {
  testWidgets(
    'render the previews',
    (WidgetTester tester) async {
      await _loadFont();
      await tester.binding.setSurfaceSize(_size);
      tester.view.devicePixelRatio = _scale;
      tester.view.physicalSize = _size * _scale;

      for (final _Preview preview in _previews) {
        final ScrollController controller = ScrollController();
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Material(
              child:
                  RepaintBoundary(key: _shot, child: preview.build(controller)),
            ),
          ),
        );

        await tester.runAsync(() async {
          await precacheImage(_photo, tester.element(find.byKey(_shot)));
        });
        await tester.pumpAndSettle();

        final ScrollableState scrollable =
            tester.state(find.byType(Scrollable).first);
        final double extent = scrollable.position.maxScrollExtent;

        final Directory out = Directory('build/previews/${preview.name}')
          ..createSync(recursive: true);
        for (final FileSystemEntity old in out.listSync()) {
          old.deleteSync();
        }

        for (int frame = 0; frame < _frames; frame++) {
          // There and back on a cosine, so the loop closes with no jolt at
          // either end.
          final double t = frame / _frames;
          final double eased = (1 - math.cos(2 * math.pi * t)) / 2;
          // Read afresh: jumpTo does not clamp, and a frame captured past the
          // end shows the viewport background instead of the content.
          final double max = scrollable.position.maxScrollExtent;
          scrollable.position.jumpTo((max * eased).clamp(0.0, max));
          await tester.pump();

          final RenderRepaintBoundary boundary =
              tester.renderObject(find.byKey(_shot)) as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final ui.Image image = await boundary.toImage(pixelRatio: _scale);
            final ByteData? png =
                await image.toByteData(format: ui.ImageByteFormat.png);
            image.dispose();
            File('${out.path}/${frame.toString().padLeft(3, '0')}.png')
                .writeAsBytesSync(png!.buffer.asUint8List());
          });
        }

        controller.dispose();
        // ignore: avoid_print
        print('${preview.name}: $_frames frames, extent '
            '${extent.toStringAsFixed(0)}');
      }
    },
    timeout: const Timeout(
      Duration(minutes: 10),
    ),
  );
}
