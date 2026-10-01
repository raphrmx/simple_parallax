import 'package:flutter/material.dart';
import 'package:simple_parallax/simple_parallax.dart';

const AssetImage _village = AssetImage('assets/images/village.webp');
const AssetImage _hill = AssetImage('assets/images/coline-herbe.webp');
const AssetImage _mountain = AssetImage('assets/images/montagne.webp');
const AssetImage _lake = AssetImage('assets/images/lac.webp');
const AssetImage _cabin = AssetImage('assets/images/cabane.webp');
const AssetImage _pines = AssetImage('assets/images/pins.webp');

const Color _paper = Color(0xFFF6F1EA);
const Color _sand = Color(0xFFEDE4D8);
const Color _white = Color(0xFFFFFDFB);
const Color _ink = Color(0xFF1D1712);
const Color _muted = Color(0xFF6F665E);
const Color _accent = Color(0xFFD9692E);

/// The width from which sections sit side by side rather than stacked.
const double _wide = 760;

/// The soft shadow under every card.
const List<BoxShadow> _shadow = <BoxShadow>[
  BoxShadow(color: Color(0x293B2A1A), blurRadius: 28, offset: Offset(0, 12)),
];

/// A page of a travel site, every picture on it a [SimpleParallaxItem]: the
/// cover drifting and settling, photos coming into focus or easing in beside
/// the text, a row of cards following the row and the page, a band of colour
/// drifting like the photos do.
class ShowcaseDemo extends StatelessWidget {
  /// Creates the demo.
  const ShowcaseDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paper,
      body: Stack(
        children: <Widget>[
          const SimpleParallaxWidget(
            children: <Widget>[
              _Cover(),
              _Intro(),
              _Quote(),
              _Day(
                index: 0,
                overline: 'DAY ONE',
                title: 'Out of the village',
                text:
                    'The path leaves the last houses by the chapel and climbs '
                    'through the woods to the open slopes. Fill your bottles at '
                    'the fountain: there is no water before the ridge.',
                look: _Look(
                  _village,
                  alignment: Alignment(0.6, 0.2),
                  closer: 1.4,
                ),
                parallax: ParallaxProperties(overscan: 1.8),
              ),
              _Day(
                index: 1,
                overline: 'DAY TWO',
                title: 'Over the pass',
                text:
                    'A steady climb to the col, then the refuge a little below '
                    'it. There is water there only, so fill up before the last '
                    'stretch, and book ahead in August.',
                look: _Look(
                  _mountain,
                  alignment: Alignment(0.2, -0.3),
                  closer: 1.5,
                ),
                parallax: ParallaxProperties(speed: 0.6, overscan: 1.8),
                blur: BlurProperties(-10, reach: 0.5),
              ),
              _Day(
                index: 2,
                overline: 'DAY THREE',
                title: 'Down to the lake',
                text:
                    'The descent follows the stream through the pastures to the '
                    'shore. The last bus leaves at ten past seven, from the stop '
                    'by the dam.',
                look: _Look(_lake, alignment: Alignment(0.2, 0.3), closer: 1.3),
                parallax: ParallaxProperties(speed: 0.8, overscan: 1.8),
                zoom: ZoomProperties(-0.5),
              ),
              _Refuges(),
              _Season(),
              _Closing(),
              _Footer(),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Material(
                color: const Color(0x59000000),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Whether the page is wide enough to set sections side by side.
bool _isWide(BuildContext context) => MediaQuery.sizeOf(context).width >= _wide;

/// How a picture shows a photo: which part of it, how close and which way
/// round. It is a widget wrapped around the image, so it goes in as a
/// `background` rather than an `image`.
class _Look {
  const _Look(
    this.photo, {
    this.alignment = Alignment.center,
    this.closer = 1,
    this.mirrored = false,
  });

  final AssetImage photo;
  final Alignment alignment;

  /// How much closer than the whole photo the crop is, about [alignment].
  final double closer;

  final bool mirrored;

  Widget build() {
    Widget image = Image(
      image: photo,
      fit: BoxFit.cover,
      alignment: alignment,
      width: double.infinity,
      height: double.infinity,
      gaplessPlayback: true,
    );
    if (closer != 1) {
      image =
          Transform.scale(scale: closer, alignment: alignment, child: image);
    }
    if (mirrored) image = Transform.flip(flipX: true, child: image);
    return ClipRect(child: image);
  }
}

/// Content kept to a readable width, centred, with room on either side.
class _Band extends StatelessWidget {
  const _Band({
    required this.child,
    this.top = 96,
    this.bottom = 96,
  });

  final Widget child;
  final double top;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    final double side = _isWide(context) ? 56 : 24;
    return ColoredBox(
      color: _paper,
      child: Padding(
        padding: EdgeInsets.fromLTRB(side, top, side, bottom),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A small line in capitals over a title.
class _Overline extends StatelessWidget {
  const _Overline(this.text, {this.color = _accent});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 3,
        color: color,
      ),
    );
  }
}

/// The cover: the photo drifting at full speed and growing a little as the
/// page leaves it, darkened at the foot under the title.
class _Cover extends StatelessWidget {
  const _Cover();

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final bool wide = size.width >= _wide;
    return SimpleParallaxItem(
      image: _mountain,
      height: (size.height * 0.92).clamp(460.0, 860.0),
      alignment: const Alignment(0, -0.3),
      parallax: const ParallaxProperties(overscan: 1.7),
      zoom: const ZoomProperties(0.35),
      overlay: const OverlayProperties.gradient(
        LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: <double>[0, 0.4, 1],
          colors: <Color>[
            Color(0x4D000000),
            Color(0x00000000),
            Color(0xCC000000),
          ],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          wide ? 72 : 24,
          0,
          wide ? 72 : 24,
          wide ? 72 : 40,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const _Overline(
              'THE HIGH ROUTE · FOUR DAYS',
              color: Color(0xFFFFC79E),
            ),
            const SizedBox(height: 14),
            Text(
              'Four days\nabove the valley',
              style: TextStyle(
                fontSize: wide ? 76 : 46,
                height: 1.02,
                fontWeight: FontWeight.w800,
                letterSpacing: wide ? -2.6 : -1.6,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 18),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Text(
                'Up from the village, along the ridge, over the pass and down '
                'to the lake, from refuge to refuge.',
                style: TextStyle(
                  fontSize: wide ? 19 : 16,
                  height: 1.5,
                  color: const Color(0xE6FFFFFF),
                ),
              ),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 18,
                ),
              ),
              child: const Text(
                'Plan the walk',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// What the walk is, and four figures.
class _Intro extends StatelessWidget {
  const _Intro();

  static const List<(String, String)> _figures = <(String, String)>[
    ('42 km', 'from the village to the lake'),
    ('4 days', 'three nights in refuges'),
    ('1,380 m', 'climbed over the whole walk'),
    ('June', 'when the meadows flower'),
  ];

  @override
  Widget build(BuildContext context) {
    final bool wide = _isWide(context);
    return _Band(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _Overline('THE WALK'),
          const SizedBox(height: 14),
          Text(
            'Green slopes, one pass,\nand a lake at the end of it.',
            style: TextStyle(
              fontSize: wide ? 44 : 30,
              height: 1.12,
              fontWeight: FontWeight.w700,
              letterSpacing: wide ? -1.4 : -0.8,
              color: _ink,
            ),
          ),
          const SizedBox(height: 18),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: const Text(
              'A walk for anyone used to a day on their feet. The climbs are '
              'steady rather than steep, the refuges cook, and the bus brings '
              'you back to where you started.',
              style: TextStyle(fontSize: 17, height: 1.6, color: _muted),
            ),
          ),
          const SizedBox(height: 48),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) => Wrap(
              spacing: 14,
              runSpacing: 14,
              children: <Widget>[
                for (final (String figure, String detail) in _figures)
                  Container(
                    // Four abreast on a wide page, two on a narrow one.
                    width: wide ? 228 : (constraints.maxWidth - 14) / 2,
                    padding: EdgeInsets.all(wide ? 22 : 18),
                    decoration: BoxDecoration(
                      color: _white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: _shadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          figure,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                            color: _accent,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          detail,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: _muted,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A band across the page, the photo drifting and growing under a quote.
class _Quote extends StatelessWidget {
  const _Quote();

  @override
  Widget build(BuildContext context) {
    final bool wide = _isWide(context);
    return SimpleParallaxItem(
      background: const _Look(_hill, alignment: Alignment(0.4, -0.2)).build(),
      height: wide ? 520 : 440,
      parallax: const ParallaxProperties(overscan: 1.9),
      zoom: const ZoomProperties(0.3),
      overlay: const OverlayProperties.darken(0.4),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Text(
              '“By June the grass on the ridge comes up to the knee, and the '
              'clouds sit just above it.”',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: wide ? 38 : 26,
                height: 1.3,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.6,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A day of the walk: its photo beside its text, on alternate sides on a wide
/// page, each photo with an effect of its own.
class _Day extends StatelessWidget {
  const _Day({
    required this.index,
    required this.overline,
    required this.title,
    required this.text,
    required this.look,
    required this.parallax,
    this.zoom,
    this.blur,
  });

  final int index;
  final String overline;
  final String title;
  final String text;
  final _Look look;
  final ParallaxProperties parallax;
  final ZoomProperties? zoom;
  final BlurProperties? blur;

  @override
  Widget build(BuildContext context) {
    final bool wide = _isWide(context);
    final Widget photo = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: _shadow,
      ),
      child: SimpleParallaxItem(
        background: look.build(),
        height: wide ? 440 : 300,
        borderRadius: BorderRadius.circular(24),
        parallax: parallax,
        zoom: zoom,
        blur: blur,
      ),
    );
    final Widget words = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _Overline(overline),
        const SizedBox(height: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: wide ? 38 : 28,
            height: 1.1,
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
            color: _ink,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          text,
          style: const TextStyle(fontSize: 17, height: 1.65, color: _muted),
        ),
      ],
    );
    if (!wide) {
      return _Band(
        top: index == 0 ? 72 : 36,
        bottom: 36,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[photo, const SizedBox(height: 26), words],
        ),
      );
    }
    final List<Widget> pair = <Widget>[
      Expanded(flex: 6, child: photo),
      const SizedBox(width: 64),
      Expanded(flex: 5, child: words),
    ];
    return _Band(
      top: index == 0 ? 112 : 48,
      bottom: 48,
      child: Row(
        children: index.isOdd ? pair.reversed.toList() : pair,
      ),
    );
  }
}

/// A row of refuges, each card drifting with the row and with the page.
class _Refuges extends StatelessWidget {
  const _Refuges();

  static const List<(String, String, _Look)> _refuges =
      <(String, String, _Look)>[
    (
      'NIGHT ONE',
      'Huts in the firs',
      _Look(_cabin, alignment: Alignment(-0.4, 0)),
    ),
    (
      'NIGHT TWO',
      'Refuge of the col',
      _Look(_mountain, alignment: Alignment(0.6, -0.4), closer: 1.6),
    ),
    (
      'NIGHT THREE',
      'The woodcutters’ camp',
      _Look(_pines, alignment: Alignment(0, 0.2)),
    ),
    (
      'THE LAST DAY',
      'Lunch by the lake',
      _Look(_lake, alignment: Alignment(-0.6, 0.2), closer: 1.6),
    ),
    (
      'IF IT RAINS',
      'The village inn',
      _Look(_village, alignment: Alignment(0.8, 0.1), closer: 2),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bool wide = _isWide(context);
    final double side = wide ? 56 : 24;
    return ColoredBox(
      color: _sand,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 88),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: side),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const _Overline('WHERE TO SLEEP'),
                  const SizedBox(height: 12),
                  Text(
                    'Three refuges, and a bed if it rains',
                    style: TextStyle(
                      fontSize: wide ? 38 : 28,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                      color: _ink,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),
            SizedBox(
              height: wide ? 420 : 360,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: side),
                itemCount: _refuges.length,
                separatorBuilder: (BuildContext context, int index) =>
                    const SizedBox(width: 18),
                itemBuilder: (BuildContext context, int index) {
                  final (String overline, String title, _Look look) =
                      _refuges[index];
                  return SimpleParallaxItem(
                    background: look.build(),
                    width: wide ? 320 : 260,
                    borderRadius: BorderRadius.circular(22),
                    parallax: const ParallaxProperties(overscan: 1.8),
                    crossParallax: const ParallaxProperties(speed: 0.5),
                    overlay: const OverlayProperties.gradient(
                      LinearGradient(
                        begin: Alignment.center,
                        end: Alignment.bottomCenter,
                        colors: <Color>[Color(0x00000000), Color(0xB3000000)],
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            _Overline(overline, color: const Color(0xD9FFFFFF)),
                            const SizedBox(height: 6),
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.6,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// When to go, over a band of sky that drifts the way a photo
/// would: the background is a widget.
class _Season extends StatelessWidget {
  const _Season();

  static const List<(String, bool)> _months = <(String, bool)>[
    ('Apr', false),
    ('May', true),
    ('Jun', true),
    ('Jul', true),
    ('Aug', false),
    ('Sep', true),
    ('Oct', false),
  ];

  @override
  Widget build(BuildContext context) {
    final bool wide = _isWide(context);
    return SimpleParallaxItem(
      height: wide ? 440 : 480,
      parallax: const ParallaxProperties(overscan: 2.2),
      background: const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFF173F7A),
              Color(0xFF2F78B8),
              Color(0xFF7DB8E0),
              Color(0xFFD8ECF7),
            ],
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: wide ? 72 : 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const _Overline('WHEN TO GO', color: Color(0xFFBFE1F7)),
            const SizedBox(height: 12),
            Text(
              'Late spring, or early autumn',
              style: TextStyle(
                fontSize: wide ? 42 : 30,
                height: 1.1,
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                for (final (String month, bool good) in _months)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: good ? Colors.white : const Color(0x33FFFFFF),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Text(
                      month,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: good ? _ink : Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The last photo, soft as it comes in and in focus by the middle of the
/// screen, under a way to book.
class _Closing extends StatelessWidget {
  const _Closing();

  @override
  Widget build(BuildContext context) {
    final bool wide = _isWide(context);
    return SimpleParallaxItem(
      background: const _Look(
        _hill,
        mirrored: true,
        alignment: Alignment(-0.2, 0.4),
        closer: 1.3,
      ).build(),
      height: wide ? 600 : 520,
      parallax: const ParallaxProperties(overscan: 1.8),
      zoom: const ZoomProperties(-0.4, reach: 0.5),
      blur: const BlurProperties(-14, reach: 0.5),
      overlay: const OverlayProperties.darken(0.35),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Ready when the meadows are.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: wide ? 56 : 36,
                  height: 1.05,
                  fontWeight: FontWeight.w800,
                  letterSpacing: wide ? -2 : -1.2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'The refuges open on the first of May.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Color(0xE6FFFFFF)),
              ),
              const SizedBox(height: 30),
              FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _ink,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 18,
                  ),
                ),
                child: const Text(
                  'Book the refuges',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The foot of the page.
class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: _sand,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Center(
          child: Text(
            'Every picture on this page is a SimpleParallaxItem.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: _muted),
          ),
        ),
      ),
    );
  }
}
