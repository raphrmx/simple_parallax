import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:simple_parallax/simple_parallax.dart';
import 'package:video_player/video_player.dart';

void main() => runApp(const ExampleApp());

const AssetImage _background = AssetImage('assets/images/background.webp');

const Color _ink = Color(0xFF14110F);
const Color _card = Color(0xF7FCFAF8);
const Color _dusk = Color(0xFF241C18);
const Color _panel = Color(0xFFF7F4F1);
const Color _muted = Color(0xFF6B635C);

/// One entry of the scrolling content, the same copy the README previews use.
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

/// The note a row at [index] shows, cycling through [_notes].
_Note _noteAt(int index) => _notes[index % _notes.length];

/// Every combination the package offers, behind a menu.
class ExampleApp extends StatelessWidget {
  /// Creates the example app.
  const ExampleApp({super.key});

  /// The theme the example is drawn in, shared with the screenshot recorder so
  /// the two cannot drift apart.
  static ThemeData get theme => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE07A3F),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: _dusk,
        useMaterial3: true,
      );

  /// The scroll behaviour the example installs, which adds the mouse to the
  /// devices allowed to drag a list.
  static const ScrollBehavior scrollBehavior = _DragScrollBehavior();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Parallax v2',
      debugShowCheckedModeBanner: false,
      scrollBehavior: scrollBehavior,
      theme: theme,
      home: const _Menu(),
    );
  }
}

/// Lets a mouse drag a scroll view.
///
/// Flutter hands dragging to touch, stylus and trackpad, never to a mouse, so a
/// sideways list has nothing to drag with on a desktop.
class _DragScrollBehavior extends MaterialScrollBehavior {
  const _DragScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => <PointerDeviceKind>{
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

class _Menu extends StatelessWidget {
  const _Menu();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
          children: <Widget>[
            const Text(
              'Simple Parallax v2',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Two modes, either axis, any image or any widget as the '
              'background. The drift, the zoom, the blur and the overlay are '
              'each set on their own.',
              style: TextStyle(fontSize: 15, color: Color(0x99FFFFFF)),
            ),
            const SizedBox(height: 28),
            _entry(
              context,
              'Container mode',
              'One background behind a scrolling column',
              const ContainerVerticalDemo(),
            ),
            _entry(
              context,
              'Container mode, sideways',
              'The same, drifting on the horizontal axis',
              const ContainerHorizontalDemo(),
            ),
            _entry(
              context,
              'Container mode, slivers',
              'A SliverAppBar riding over the background',
              const ContainerSliversDemo(),
            ),
            _entry(
              context,
              'Item mode',
              'Each block slides its own background',
              const ItemVerticalDemo(),
            ),
            _entry(
              context,
              'Item mode, sideways',
              'The blocks read the axis from the list',
              const ItemHorizontalDemo(),
            ),
            _entry(
              context,
              'Zooming in and out',
              'Two blocks, the same drift, opposite zooms',
              const ItemZoomDemo(),
            ),
            _entry(
              context,
              'Blurring in and out',
              'The same two blocks, softened instead of scaled',
              const ItemBlurDemo(),
            ),
            _entry(
              context,
              'Stopping at the middle',
              'An effect that is done halfway, held or sent back',
              const ItemReachDemo(),
            ),
            _entry(
              context,
              'A tint over the image',
              'A fixed overlay, darkened, tinted or faded',
              const ItemOverlayDemo(),
            ),
            _entry(
              context,
              'A gradient as the background',
              'No image anywhere, just a widget',
              const ContainerCustomDemo(),
            ),
            _entry(
              context,
              'A tinted image as the background',
              'Anything wrapping the image is yours',
              const ItemCustomDemo(),
            ),
            _entry(
              context,
              'A video behind the page',
              'Container mode over a looping video',
              const ContainerVideoDemo(),
            ),
            _entry(
              context,
              'A video inside a block',
              'Item mode over the same video',
              const ItemVideoDemo(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _entry(
    BuildContext context,
    String label,
    String detail,
    Widget demo,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (BuildContext context) => demo),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        detail,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0x99FFFFFF),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0x66FFFFFF)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A demo filling the window, with a way back over it.
class _Screen extends StatelessWidget {
  const _Screen({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Positioned.fill(child: child),
          Positioned(
            left: 12,
            top: MediaQuery.paddingOf(context).top + 12,
            child: Material(
              color: const Color(0x66000000),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.of(context).pop(),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    Icons.arrow_back,
                    size: 22,
                    color: Color(0xFFFFFFFF),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A block as tall as the window, so whatever follows it enters from below.
///
/// An item already on screen when a page opens is partway through its crossing,
/// so it has already spent part of its drift and its zoom. A screenful in front
/// of it is what lets the whole range be seen.
class _Screenful extends StatelessWidget {
  const _Screenful({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: MediaQuery.sizeOf(context).height, child: child);
}

/// A note as a row, inset so the background shows around it.
class _Row extends StatelessWidget {
  const _Row(this.note);

  final _Note note;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 7),
          padding: const EdgeInsets.fromLTRB(22, 17, 22, 17),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: note.dot,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      note.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      note.detail,
                      style: const TextStyle(fontSize: 13, color: _muted),
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

/// A note as a card of the sideways content.
class _Card extends StatelessWidget {
  const _Card(this.note);

  final _Note note;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 210,
        height: 280,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: note.dot,
                shape: BoxShape.circle,
              ),
            ),
            const Spacer(),
            Text(
              note.title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
                color: _ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              note.detail,
              style: const TextStyle(fontSize: 13, height: 1.45, color: _muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// An overline and a title over a parallax block, on a scrim so they stay
/// readable whatever the background is.
class _Caption extends StatelessWidget {
  const _Caption(this.overline, this.title);

  final String overline;
  final String title;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.center,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0x00000000), Color(0xB3000000)],
        ),
      ),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                overline,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 3,
                  color: Color(0xB8FFFFFF),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.8,
                  color: Color(0xFFFFFFFF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A block of prose between two parallax blocks.
class _Prose extends StatelessWidget {
  const _Prose(this.heading, this.body);

  final String heading;
  final String body;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _panel,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  heading,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: _muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Container mode: one background drifting behind a scrolling column.
///
/// A speed of `1` spends the whole travel over the whole page, so the background
/// uses exactly the travel `overscan` gives it and never runs out of image.
class ContainerVerticalDemo extends StatelessWidget {
  /// Creates the vertical container demo.
  const ContainerVerticalDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return _Screen(
      child: SimpleParallaxContainer(
        image: _background,
        parallax: const ParallaxProperties(speed: 0.8, overscan: 1.6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: Column(
            children: List<Widget>.generate(
              20,
              (int index) => _Row(_noteAt(index)),
            ),
          ),
        ),
      ),
    );
  }
}

/// The same container, scrolling sideways.
///
/// Only `scrollDirection` changes: the background then drifts on the horizontal
/// axis, and `overscan` widens it instead of heightening it.
class ContainerHorizontalDemo extends StatelessWidget {
  /// Creates the horizontal container demo.
  const ContainerHorizontalDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return _Screen(
      child: SimpleParallaxContainer(
        image: _background,
        scrollDirection: Axis.horizontal,
        parallax: const ParallaxProperties(overscan: 2),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: List<Widget>.generate(
              16,
              (int index) => _Card(_noteAt(index)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Container mode over slivers, so the content builds as it scrolls.
///
/// `SimpleParallaxContainer.slivers` takes the content as slivers instead of a
/// single child, which lets a `SliverAppBar` ride over the background and a
/// list build only the rows the viewport needs.
class ContainerSliversDemo extends StatelessWidget {
  /// Creates the sliver container demo.
  const ContainerSliversDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return _Screen(
      child: SimpleParallaxContainer.slivers(
        image: _background,
        parallax: const ParallaxProperties(overscan: 2),
        slivers: <Widget>[
          const SliverAppBar(
            title: Text('Slivers'),
            backgroundColor: Color(0x66000000),
            foregroundColor: Color(0xFFFFFFFF),
            floating: true,
            automaticallyImplyLeading: false,
          ),
          SliverList.builder(
            itemCount: 40,
            itemBuilder: (BuildContext context, int index) =>
                _Row(_noteAt(index)),
          ),
        ],
      ),
    );
  }
}

/// Item mode: each block slides its own background as it crosses the viewport.
///
/// `SimpleParallaxWidget` is a convenience scroll view built on a `SliverList`,
/// so its blocks build as they come into view; a `ListView` works just as well.
class ItemVerticalDemo extends StatelessWidget {
  /// Creates the vertical item demo.
  const ItemVerticalDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const _Screen(
      child: SimpleParallaxWidget(
        children: <Widget>[
          SizedBox(
            height: 230,
            child: _Prose(
              'Two days on the ridge',
              'The path leaves the road just past the bridge and climbs steadily '
                  'for the first hour.',
            ),
          ),
          SimpleParallaxItem(
            image: _background,
            height: 430,
            parallax: ParallaxProperties(overscan: 2),
            child: _Caption('DAY ONE', 'The southern pass'),
          ),
          SizedBox(
            height: 230,
            child: _Prose(
              'Where to stop',
              'The refuge sits a little below the col. It fills up quickly in '
                  'August, so book ahead.',
            ),
          ),
          SimpleParallaxItem(
            image: _background,
            height: 430,
            parallax: ParallaxProperties(speed: 0.4, overscan: 2),
            child: _Caption('DAY TWO', 'Down to the lake'),
          ),
          SizedBox(
            height: 300,
            child: _Prose(
              'Getting back',
              'The last bus leaves at ten past seven, from the same stop.',
            ),
          ),
        ],
      ),
    );
  }
}

/// The same items in a horizontal list.
///
/// Nothing is passed to the items about the axis: each one reads it from the
/// scrollable it sits in. Give them a `width` here, the way you give them a
/// `height` in a vertical list.
class ItemHorizontalDemo extends StatelessWidget {
  /// Creates the horizontal item demo.
  const ItemHorizontalDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const _Screen(
      child: SimpleParallaxWidget(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          SizedBox(
            width: 340,
            child: _Prose(
              'Two days on the ridge',
              'The path leaves the road just past the bridge and climbs steadily '
                  'for the first hour.',
            ),
          ),
          SimpleParallaxItem(
            image: _background,
            width: 380,
            parallax: ParallaxProperties(overscan: 2),
            child: _Caption('DAY ONE', 'The southern pass'),
          ),
          SizedBox(
            width: 340,
            child: _Prose(
              'Where to stop',
              'The refuge sits a little below the col. It fills up quickly in '
                  'August, so book ahead.',
            ),
          ),
          SimpleParallaxItem(
            image: _background,
            width: 380,
            parallax: ParallaxProperties(speed: 0.4, overscan: 2),
            child: _Caption('DAY TWO', 'Down to the lake'),
          ),
          SizedBox(
            width: 340,
            child: _Prose(
              'Getting back',
              'The last bus leaves at ten past seven, from the same stop.',
            ),
          ),
        ],
      ),
    );
  }
}

/// The two directions of `zoom`, one under the other.
///
/// Both blocks are given the same `speed` and the same `overscan`, so the only
/// thing between them is the sign of `zoom`. The first pushes in as it crosses,
/// the second starts enlarged and comes to rest.
///
/// A screenful of prose sits in front of each, so the block enters from below
/// and its whole range is seen. A block already on screen when the page opens
/// has spent part of that range before the first scroll.
class ItemZoomDemo extends StatelessWidget {
  /// Creates the zoom demo.
  const ItemZoomDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const _Screen(
      child: SimpleParallaxWidget(
        children: <Widget>[
          _Screenful(
            child: _Prose(
              'Two blocks, one difference',
              'Both drift at the same speed. Only the sign of their zoom is '
                  'not the same, so what you see between them is the zoom and '
                  'nothing else. Scroll on.',
            ),
          ),
          SimpleParallaxItem(
            image: _background,
            height: 620,
            parallax: ParallaxProperties(speed: 0, overscan: 1.6),
            zoom: ZoomProperties(0.9),
            child: _Caption('ZOOM 0.9', 'It pushes in'),
          ),
          _Screenful(
            child: _Prose(
              'And the other way',
              'The same range read from the other end. It starts half again '
                  'as large and settles at its own size as the block leaves.',
            ),
          ),
          SimpleParallaxItem(
            image: _background,
            height: 620,
            parallax: ParallaxProperties(speed: 0, overscan: 1.6),
            zoom: ZoomProperties(-0.9),
            child: _Caption('ZOOM -0.9', 'It comes to rest'),
          ),
          _Screenful(
            child: _Prose(
              'Neither goes below its own size',
              'A background smaller than the block would show the page down '
                  'both sides, so the scale stops at one whichever way it runs.',
            ),
          ),
        ],
      ),
    );
  }
}

/// The two directions of `blur`, one under the other.
///
/// Laid out like the zoom demo, and read the same way: the first block is sharp
/// as it arrives and soft as it goes, the second the other way round. The
/// caption stays sharp either way, since only the background is filtered.
class ItemBlurDemo extends StatelessWidget {
  /// Creates the blur demo.
  const ItemBlurDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const _Screen(
      child: SimpleParallaxWidget(
        children: <Widget>[
          _Screenful(
            child: _Prose(
              'Sharp, then soft',
              'A blur reads in logical pixels rather than as a fraction, so '
                  'the figure is a sigma. This one starts at nothing and ends '
                  'at sixteen. Scroll on.',
            ),
          ),
          SimpleParallaxItem(
            image: _background,
            height: 620,
            parallax: ParallaxProperties(speed: 0.5, overscan: 1.6),
            blur: BlurProperties(16),
            child: _Caption('BLUR 16', 'It softens'),
          ),
          _Screenful(
            child: _Prose(
              'And the other way',
              'The same range read from the other end. It arrives soft and '
                  'comes into focus as the block crosses.',
            ),
          ),
          SimpleParallaxItem(
            image: _background,
            height: 620,
            parallax: ParallaxProperties(speed: 0.5, overscan: 1.6),
            blur: BlurProperties(-16),
            child: _Caption('BLUR -16', 'It sharpens'),
          ),
          _Screenful(
            child: _Prose(
              'Only the background moves through it',
              'The filter sits under the block content, so a caption, a button '
                  'or a form over a blurred background stays readable.',
            ),
          ),
        ],
      ),
    );
  }
}

/// An effect packed into the first half of the crossing.
///
/// `reach: 0.5` has it finished as the block passes the eye. What happens after
/// that is `back`: held at its far end, or run backwards. The three blocks are
/// the same zoom held, the same zoom sent back, and a negative blur sent back,
/// which arrives soft, clears in passing and goes soft again.
class ItemReachDemo extends StatelessWidget {
  /// Creates the reach demo.
  const ItemReachDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const _Screen(
      child: SimpleParallaxWidget(
        children: <Widget>[
          _Screenful(
            child: _Prose(
              'Done by the middle',
              'Left alone an effect is spread over the whole crossing. This '
                  'one is finished as the block passes the eye, and holds '
                  'there on its way out. Scroll on.',
            ),
          ),
          SimpleParallaxItem(
            image: _background,
            height: 620,
            parallax: ParallaxProperties(speed: 0.5, overscan: 1.6),
            zoom: ZoomProperties(0.6, reach: 0.5),
            child: _Caption('ZOOM 0.6, REACH 0.5', 'In, then held'),
          ),
          _Screenful(
            child: _Prose(
              'Or sent back',
              'The same block and the same figures, with one word more. It '
                  'runs the range backwards instead of holding it.',
            ),
          ),
          SimpleParallaxItem(
            image: _background,
            height: 620,
            parallax: ParallaxProperties(speed: 0.5, overscan: 1.6),
            zoom: ZoomProperties(0.6, reach: 0.5, back: true),
            child: _Caption('BACK', 'In, then out'),
          ),
          _Screenful(
            child: _Prose(
              'The same on a blur',
              'A negative blur arrives soft. Sent back, it clears as the block '
                  'passes the eye and goes soft again on its way out.',
            ),
          ),
          SimpleParallaxItem(
            image: _background,
            height: 620,
            parallax: ParallaxProperties(speed: 0.5, overscan: 1.6),
            blur: BlurProperties(-16, reach: 0.5, back: true),
            child: _Caption('BLUR -16, BACK', 'Sharp in passing'),
          ),
          _Screenful(
            child: _Prose(
              'The drift is left alone',
              'Only the zoom and the blur are shaped. A background that walked '
                  'back up the block would read as the list scrolling the '
                  'other way.',
            ),
          ),
        ],
      ),
    );
  }
}

/// The three forms of `overlay`, one under the other.
///
/// The overlay is fixed: it stays where it is while the background drifts under
/// it, and it is drawn under the block content, so the captions here sit at full
/// strength over a photo that has been knocked back.
class ItemOverlayDemo extends StatelessWidget {
  /// Creates the overlay demo.
  const ItemOverlayDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const _Screen(
      child: SimpleParallaxWidget(
        children: <Widget>[
          _Screenful(
            child: _Prose(
              'Knocking the image back',
              'A photo is rarely the right contrast for text on its own. An '
                  'overlay is a fixed layer of colour over it, under whatever '
                  'the block draws. Scroll on.',
            ),
          ),
          SimpleParallaxItem(
            image: _background,
            height: 520,
            parallax: ParallaxProperties(speed: 0.5, overscan: 1.6),
            overlay: OverlayProperties.darken(0.45),
            child: _Caption('DARKEN 0.45', 'Black at nearly a half'),
          ),
          _Screenful(
            child: _Prose(
              'Or only where it is needed',
              'A gradient dulls the image where the text goes and leaves the '
                  'rest alone. This one darkens the top; the caption brings '
                  'its own scrim at the bottom.',
            ),
          ),
          SimpleParallaxItem(
            image: _background,
            height: 520,
            parallax: ParallaxProperties(speed: 0.5, overscan: 1.6),
            overlay: OverlayProperties.gradient(
              LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.center,
                colors: <Color>[Color(0xCC000000), Color(0x00000000)],
              ),
            ),
            child: _Caption('GRADIENT', 'Dark at the top only'),
          ),
          _Screenful(
            child: _Prose(
              'Or a colour of your own',
              'Any colour works, and the opacity is a parameter of its own, so '
                  'a brand colour can be laid over the photo without working '
                  'out an alpha channel by hand.',
            ),
          ),
          SimpleParallaxItem(
            image: _background,
            height: 520,
            parallax: ParallaxProperties(speed: 0.5, overscan: 1.6),
            overlay: OverlayProperties(Color(0xFF1A237E), opacity: 0.5),
            child: _Caption('COLOUR', 'Indigo at a half'),
          ),
          _Screenful(
            child: _Prose(
              'It does not move',
              'The background drifts under the overlay while the overlay stays '
                  'where it is. That is what makes it read as a treatment of '
                  'the page rather than as part of the photo.',
            ),
          ),
        ],
      ),
    );
  }
}

/// A gradient in place of the image.
///
/// `background` takes the layer as a widget, so it can be anything that fills
/// the box it is handed. `fit` and `alignment` apply to the image only: a widget
/// is laid out to fill the layer as it stands.
class ContainerCustomDemo extends StatelessWidget {
  /// Creates the gradient background demo.
  const ContainerCustomDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return _Screen(
      child: SimpleParallaxContainer(
        background: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Color(0xFF1B1464),
                Color(0xFFB4436C),
                Color(0xFFFFB25B),
              ],
            ),
          ),
        ),
        parallax: const ParallaxProperties(speed: 0.8, overscan: 1.6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: Column(
            children: List<Widget>.generate(
              20,
              (int index) => _Row(_noteAt(index)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Item mode with two layers an `ImageProvider` could not express.
///
/// The first block drifts a gradient, the second the asset tinted through a
/// `ColorFiltered`. Anything wrapping the image is the caller's business now,
/// `loadingBuilder` and `errorBuilder` included.
class ItemCustomDemo extends StatelessWidget {
  /// Creates the custom background item demo.
  const ItemCustomDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const _Screen(
      child: SimpleParallaxWidget(
        children: <Widget>[
          SizedBox(
            height: 230,
            child: _Prose(
              'No image anywhere',
              'The block below drifts a gradient. The background is a widget, '
                  'so it can be anything that fills the box it is handed.',
            ),
          ),
          SimpleParallaxItem(
            height: 430,
            parallax: ParallaxProperties(overscan: 2),
            background: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[Color(0xFF311B92), Color(0xFF26C6DA)],
                ),
              ),
            ),
            child: _Caption('DAY ONE', 'The southern pass'),
          ),
          SizedBox(
            height: 230,
            child: _Prose(
              'And the asset, tinted',
              'Wrapping the image is the caller business now, which is how a '
                  'ColorFiltered gets in front of it.',
            ),
          ),
          SimpleParallaxItem(
            height: 430,
            parallax: ParallaxProperties(overscan: 2),
            background: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Color(0x99311B92),
                BlendMode.srcATop,
              ),
              child: Image(image: _background, fit: BoxFit.cover),
            ),
            child: _Caption('DAY TWO', 'Down to the lake'),
          ),
          SizedBox(
            height: 300,
            child: _Prose(
              'Getting back',
              'The last bus leaves at ten past seven, from the same stop.',
            ),
          ),
        ],
      ),
    );
  }
}

/// Container mode over a looping video.
///
/// The layer is a `VideoPlayer`, which carries an aspect ratio of its own, so it
/// goes through a `FittedBox` to cover the layer: that is the work
/// `fit: BoxFit.cover` does for an image.
class ContainerVideoDemo extends StatelessWidget {
  /// Creates the video background demo.
  const ContainerVideoDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return _Screen(
      child: SimpleParallaxContainer(
        background: const _VideoBackground(),
        parallax: const ParallaxProperties(speed: 0.8, overscan: 1.6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: Column(
            children: List<Widget>.generate(
              20,
              (int index) => _Row(_noteAt(index)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Item mode over the same video.
///
/// The block owns its player, so the video exists only while the block is in
/// the tree, and it slides inside the block the way an image would.
class ItemVideoDemo extends StatelessWidget {
  /// Creates the video item demo.
  const ItemVideoDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const _Screen(
      child: SimpleParallaxWidget(
        children: <Widget>[
          SizedBox(
            height: 230,
            child: _Prose(
              'Two days on the ridge',
              'The block below drifts a video rather than an image. It owns '
                  'its player, so the video lives only while the block does.',
            ),
          ),
          SimpleParallaxItem(
            height: 470,
            parallax: ParallaxProperties(overscan: 2),
            background: _VideoBackground(),
            child: _Caption('DAY ONE', 'The southern pass'),
          ),
          SizedBox(
            height: 230,
            child: _Prose(
              'Where to stop',
              'The one below is the asset again, in the same block at the '
                  'same drift.',
            ),
          ),
          SimpleParallaxItem(
            image: _background,
            height: 430,
            parallax: ParallaxProperties(overscan: 2),
            child: _Caption('DAY TWO', 'Down to the lake'),
          ),
          SizedBox(
            height: 300,
            child: _Prose(
              'Getting back',
              'The last bus leaves at ten past seven, from the same stop.',
            ),
          ),
        ],
      ),
    );
  }
}

/// A looping video sized to cover the layer it is handed.
///
/// It owns its player, so it can be dropped into any background slot. Where
/// `video_player` has no implementation, Windows and Linux at the time of
/// writing, it falls back to a gradient and says so.
class _VideoBackground extends StatefulWidget {
  const _VideoBackground();

  @override
  State<_VideoBackground> createState() => _VideoBackgroundState();
}

class _VideoBackgroundState extends State<_VideoBackground> {
  static final Uri _source = Uri.parse(
    'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
  );

  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(_source);
    _start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    try {
      await _controller.initialize();
      await _controller.setLooping(true);
      // Muted, otherwise a browser refuses to start it without a tap.
      await _controller.setVolume(0);
      await _controller.play();
      if (mounted) {
        setState(() => _ready = true);
      }
    } on Object {
      if (mounted) {
        setState(() => _failed = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) {
      final Size size = _controller.value.size;
      return FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: VideoPlayer(_controller),
        ),
      );
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF1B1464), Color(0xFF241C18)],
        ),
      ),
      child: _failed
          ? const Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 90, 24, 0),
                child: Text(
                  'No video player on this platform.',
                  style: TextStyle(fontSize: 13, color: Color(0x99FFFFFF)),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
