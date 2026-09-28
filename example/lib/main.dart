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

/// Stands in for the platform's reduced motion setting, so every demo can be
/// seen the way someone who turned it on sees it.
final ValueNotifier<bool> _reduceMotion = ValueNotifier<bool>(false);

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
      // The switch on the menu reaches the demos the way the platform would,
      // through MediaQuery.
      builder: (BuildContext context, Widget? child) =>
          ValueListenableBuilder<bool>(
        valueListenable: _reduceMotion,
        builder: (BuildContext context, bool reduce, Widget? _) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations:
                reduce || MediaQuery.disableAnimationsOf(context),
          ),
          child: child!,
        ),
      ),
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
            const SizedBox(height: 20),
            const _ReduceMotionSwitch(),
            const _Section('Container mode'),
            _entry(
              context,
              'One background behind the page',
              'A scrolling column over a single drifting image',
              const ContainerVerticalDemo(),
            ),
            _entry(
              context,
              'Sideways',
              'The same, drifting on the horizontal axis',
              const ContainerHorizontalDemo(),
            ),
            _entry(
              context,
              'Slivers and a controller',
              'A SliverAppBar over the background, and a way back up',
              const ContainerSliversDemo(),
            ),
            _entry(
              context,
              'A gradient behind the page',
              'No image anywhere, just a widget',
              const ContainerCustomDemo(),
            ),
            const _Section('Item mode'),
            _entry(
              context,
              'Blocks that slide their own background',
              'Each block drifts as it crosses the screen',
              const ItemVerticalDemo(),
            ),
            _entry(
              context,
              'A carousel in a page',
              'Following the row, the page around it, or both',
              const ItemCarouselDemo(),
            ),
            _entry(
              context,
              'Five hundred blocks',
              'Built one at a time as they scroll in',
              const ItemBuilderDemo(),
            ),
            _entry(
              context,
              'Widgets as the background',
              'A gradient, a tinted image and a video',
              const ItemCustomDemo(),
            ),
            const _Section('Effects'),
            _entry(
              context,
              'Zooming and blurring',
              'Each one run forwards, then backwards',
              const ItemZoomBlurDemo(),
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

/// A heading over a group of menu entries.
class _Section extends StatelessWidget {
  const _Section(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 2.4,
          color: Color(0x99FFFFFF),
        ),
      ),
    );
  }
}

/// Turns [_reduceMotion] on and off.
class _ReduceMotionSwitch extends StatelessWidget {
  const _ReduceMotionSwitch();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x14FFFFFF),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: ValueListenableBuilder<bool>(
        valueListenable: _reduceMotion,
        builder: (BuildContext context, bool reduce, Widget? _) =>
            SwitchListTile(
          value: reduce,
          onChanged: (bool value) => _reduceMotion.value = value,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18),
          title: const Text(
            'Reduce motion',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          subtitle: const Text(
            'What the demos look like with the system setting on: the '
            'backgrounds hold still and the wheel lands in one step.',
            style: TextStyle(fontSize: 13, color: Color(0x99FFFFFF)),
          ),
        ),
      ),
    );
  }
}

/// A demo filling the window, with a way back over it.
class _Screen extends StatelessWidget {
  const _Screen({required this.child, this.color});

  final Widget child;

  /// The page under the demo, or `null` for the app's dark one.
  ///
  /// The item screens stack blocks of prose on [_panel] between the parallax
  /// blocks, and give the page that colour too. The smooth wheel stops the view
  /// on fractions of a pixel, where the edge of a block is blended with what is
  /// under it: on the dark page that shows as a grey line along every seam.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color,
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

/// Container mode over slivers, so the content builds as it scrolls, with a
/// controller of the page's own.
///
/// `SimpleParallaxContainer.slivers` takes the content as slivers instead of a
/// single child, which lets a `SliverAppBar` ride over the background and a
/// list build only the rows the viewport needs. The `controller` is what the
/// button in the bar uses to go back to the top. It is a
/// `SmoothScrollController`, which keeps the wheel eased: a plain
/// `ScrollController` would hand the wheel back to the platform.
class ContainerSliversDemo extends StatefulWidget {
  /// Creates the sliver container demo.
  const ContainerSliversDemo({super.key});

  @override
  State<ContainerSliversDemo> createState() => _ContainerSliversDemoState();
}

class _ContainerSliversDemoState extends State<ContainerSliversDemo> {
  final SmoothScrollController _controller = SmoothScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _backToTop() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpTo(0);
      return;
    }
    _controller.animateTo(
      0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _Screen(
      child: SimpleParallaxContainer.slivers(
        image: _background,
        controller: _controller,
        parallax: const ParallaxProperties(overscan: 2),
        slivers: <Widget>[
          SliverAppBar(
            title: const Text('Slivers'),
            backgroundColor: const Color(0x66000000),
            foregroundColor: const Color(0xFFFFFFFF),
            floating: true,
            automaticallyImplyLeading: false,
            actions: <Widget>[
              IconButton(
                tooltip: 'Back to the top',
                icon: const Icon(Icons.arrow_upward),
                onPressed: _backToTop,
              ),
            ],
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
      color: _panel,
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

/// Items in a horizontal row inside a vertical page, three times.
///
/// In the first row the blocks read their axis from the row, as in any
/// horizontal list, and slide sideways as it is dragged. The second row is the
/// same with `scrollAxis: Axis.vertical`: the blocks look past the row to the
/// page and slide downwards as the page scrolls, like the blocks of a vertical
/// list. The third follows both, sideways with the row through `parallax` and
/// downwards with the page through `crossParallax`, at a gentler speed. Every
/// way they are laid out by the row, so they take a `width`.
class ItemCarouselDemo extends StatelessWidget {
  /// Creates the carousel demo.
  const ItemCarouselDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const _Screen(
      color: _panel,
      child: SimpleParallaxWidget(
        children: <Widget>[
          SizedBox(
            height: 260,
            child: _Prose(
              'Sideways, with the row',
              'Each block below reads its axis from the row it sits in, so it '
                  'slides sideways as the row moves. Drag it.',
            ),
          ),
          _Carousel(),
          SizedBox(
            height: 260,
            child: _Prose(
              'Or down, with the page',
              'The same row, told to follow the page. Dragging the row leaves '
                  'the images alone; scrolling the page slides them.',
            ),
          ),
          _Carousel(scrollAxis: Axis.vertical),
          SizedBox(
            height: 260,
            child: _Prose(
              'Or both at once',
              'Sideways with the row, and downwards with the page at a '
                  'gentler speed. Scroll the page, then drag the row.',
            ),
          ),
          _Carousel(crossParallax: ParallaxProperties(speed: 0.5)),
          SizedBox(
            height: 420,
            child: _Prose(
              'Which one to follow',
              'Left alone, a block follows the nearest scrollable. scrollAxis '
                  'names the one it should follow when they are nested, and '
                  'crossParallax adds the other.',
            ),
          ),
        ],
      ),
    );
  }
}

/// A row of blocks following the scrollable on [scrollAxis], and the one
/// running across it too when there is a [crossParallax].
class _Carousel extends StatelessWidget {
  const _Carousel({this.scrollAxis, this.crossParallax});

  final Axis? scrollAxis;
  final ParallaxProperties? crossParallax;

  static const List<(String, String)> _days = <(String, String)>[
    ('DAY ONE', 'The southern pass'),
    ('DAY TWO', 'Down to the lake'),
    ('DAY THREE', 'The long ridge'),
    ('DAY FOUR', 'Back to the village'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 380,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _days.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(width: 14),
        itemBuilder: (BuildContext context, int index) => SimpleParallaxItem(
          image: _background,
          width: 300,
          borderRadius: BorderRadius.circular(18),
          parallax: const ParallaxProperties(overscan: 1.8),
          scrollAxis: scrollAxis,
          crossParallax: crossParallax,
          child: _Caption(_days[index].$1, _days[index].$2),
        ),
      ),
    );
  }
}

/// Five hundred blocks, each created as it scrolls into view.
///
/// `SimpleParallaxWidget.builder` takes an `itemBuilder` instead of a list, so
/// only the blocks near the screen exist at any time, however long the list.
class ItemBuilderDemo extends StatelessWidget {
  /// Creates the builder demo.
  const ItemBuilderDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return _Screen(
      color: _panel,
      child: SimpleParallaxWidget.builder(
        itemCount: 500,
        itemBuilder: (BuildContext context, int index) {
          final _Note note = _noteAt(index ~/ 2);
          if (index.isOdd) {
            return SizedBox(
              height: 150,
              child: _Prose(note.title, note.detail),
            );
          }
          return SimpleParallaxItem(
            image: _background,
            height: 320,
            parallax: ParallaxProperties(
              speed: index % 4 == 0 ? 1 : 0.5,
              overscan: 1.8,
            ),
            child: _Caption('No. ${index + 1} OF 500', note.title),
          );
        },
      ),
    );
  }
}

/// The two directions of `zoom`, then the two directions of `blur`.
///
/// All four blocks are given the same `overscan`, so what differs between them
/// is the effect and its sign. A positive zoom pushes in as the block crosses,
/// a negative one starts enlarged and comes to rest; a positive blur softens,
/// a negative one sharpens. The captions stay sharp throughout, since only the
/// background is filtered.
///
/// A screenful of prose sits in front of each, so the block enters from below
/// and its whole range is seen. A block already on screen when the page opens
/// has spent part of that range before the first scroll.
class ItemZoomBlurDemo extends StatelessWidget {
  /// Creates the zoom and blur demo.
  const ItemZoomBlurDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const _Screen(
      color: _panel,
      child: SimpleParallaxWidget(
        children: <Widget>[
          _Screenful(
            child: _Prose(
              'The zoom, both ways',
              'The first block holds its drift still, so what you see is the '
                  'zoom and nothing else. It pushes in as the block crosses. '
                  'Scroll on.',
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
                  'as large and settles at its own size as the block leaves. '
                  'Neither goes below its own size.',
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
              'The blur, both ways',
              'A blur reads in logical pixels rather than as a fraction, so '
                  'the figure is a sigma. This one starts at nothing and ends '
                  'at sixteen.',
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
              'It arrives soft and comes into focus as the block crosses.',
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
      color: _panel,
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
      color: _panel,
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

/// Item mode with three layers an `ImageProvider` could not express.
///
/// The first block drifts a gradient, the second the asset tinted through a
/// `ColorFiltered`, the third a looping video. Anything wrapping the image is
/// the caller's business, `loadingBuilder` and `errorBuilder` included. The
/// video carries an aspect ratio of its own, so it goes through a `FittedBox` to
/// cover the layer: that is the work `fit: BoxFit.cover` does for an image. The
/// same layers work behind a whole page, in container mode.
class ItemCustomDemo extends StatelessWidget {
  /// Creates the custom background item demo.
  const ItemCustomDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const _Screen(
      color: _panel,
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
            child: _Caption('A GRADIENT', 'The southern pass'),
          ),
          SizedBox(
            height: 230,
            child: _Prose(
              'The asset, tinted',
              'Wrapping the image is the caller business, which is how a '
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
            child: _Caption('A TINTED IMAGE', 'Down to the lake'),
          ),
          SizedBox(
            height: 230,
            child: _Prose(
              'A video',
              'The block below owns its player, so the video lives only while '
                  'the block does, and slides the way an image would.',
            ),
          ),
          SimpleParallaxItem(
            height: 470,
            parallax: ParallaxProperties(overscan: 2),
            background: _VideoBackground(),
            child: _Caption('A VIDEO', 'At the refuge'),
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
