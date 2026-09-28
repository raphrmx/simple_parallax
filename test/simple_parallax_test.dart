import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_parallax/simple_parallax.dart';
import 'package:simple_parallax/src/display_size_image.dart';
// Not exported: the overlay is an implementation detail the
// tests reach for to find what the widgets drew.
import 'package:simple_parallax/src/overlay_layer.dart';

/// A 1x1 transparent PNG, so the tests never touch the asset bundle or the
/// network.
final Uint8List _pixel = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

ImageProvider get _image => MemoryImage(_pixel);

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

/// Sends one wheel notch of [delta] over the middle of the view.
Future<void> _wheel(WidgetTester tester, Offset delta) async {
  final TestPointer pointer = TestPointer(1, PointerDeviceKind.mouse);
  final Offset middle = tester.getCenter(find.byType(Scrollable));
  await tester.sendEventToBinding(pointer.hover(middle));
  await tester.sendEventToBinding(pointer.scroll(delta));
}

/// The position of the one scroll view under test.
ScrollPosition _position(WidgetTester tester) =>
    (tester.state(find.byType(Scrollable)) as ScrollableState).position;

/// A list tall enough to scroll in a 600 pixel test viewport.
List<Widget> _tall() => List<Widget>.generate(
      20,
      (int i) => SizedBox(height: 100, child: Text('Item $i')),
    );

/// A list wide enough to scroll in an 800 pixel test viewport.
List<Widget> _wide() => List<Widget>.generate(
      20,
      (int i) => SizedBox(width: 300, child: Text('Item $i')),
    );

/// Marks the background widget, so a test can find the layer when there is no
/// [Image] to look for.
const Key _layerKey = Key('layer');

/// The layer itself. A [ColoredBox] with no child fills the box it is given,
/// which is what the parallax hands it.
const Widget _layer = ColoredBox(key: _layerKey, color: Color(0xFF1A237E));

/// A desktop, where the wheel is eased unless told otherwise. Tests run as
/// Android by default, where it is not.
final TargetPlatformVariant _desktop =
    TargetPlatformVariant.only(TargetPlatform.windows);

/// [child] on a platform that asks for reduced motion.
Widget _reducedMotion(Widget child) => Builder(
      builder: (BuildContext context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child,
      ),
    );

/// The blur over the one background under test, or `null` when the background
/// is not blurred at all.
ui.ImageFilter? _blur(WidgetTester tester) {
  final Iterable<ImageFilterLayer> filters =
      tester.layers.whereType<ImageFilterLayer>();
  return filters.isEmpty ? null : filters.single.imageFilter;
}

/// A gaussian blur of [sigma], as the widgets build it.
ui.ImageFilter _blurOf(double sigma) => ui.ImageFilter.blur(
      sigmaX: sigma,
      sigmaY: sigma,
      tileMode: TileMode.clamp,
    );

void main() {
  group('SimpleParallaxContainer', () {
    testWidgets('renders its child and a background',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          SimpleParallaxContainer(
            image: _image,
            child: Column(
              children: List<Widget>.generate(
                10,
                (int i) => SizedBox(height: 100, child: Text('Item $i')),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Item 0'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    test('rejects an overscan below 1', () {
      expect(() => ParallaxProperties(overscan: 0.5), throwsAssertionError);
    });

    testWidgets('renders the slivers it is given', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SimpleParallaxContainer.slivers(
            image: _image,
            slivers: <Widget>[
              SliverList.builder(
                itemCount: 10,
                itemBuilder: (BuildContext context, int index) =>
                    SizedBox(height: 100, child: Text('Item $index')),
              ),
            ],
          ),
        ),
      );

      expect(find.text('Item 0'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('builds a sliver list no further than the viewport', (
      WidgetTester tester,
    ) async {
      int built = 0;

      await tester.pumpWidget(
        _app(
          SimpleParallaxContainer.slivers(
            image: _image,
            slivers: <Widget>[
              SliverList.builder(
                itemCount: 1000,
                itemBuilder: (BuildContext context, int index) {
                  built++;
                  return SizedBox(height: 100, child: Text('Item $index'));
                },
              ),
            ],
          ),
        ),
      );

      expect(built, lessThan(50));
      expect(find.text('Item 999'), findsNothing);
    });

    testWidgets('moves its background under scrolling slivers', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SimpleParallaxContainer.slivers(
            image: _image,
            parallax: const ParallaxProperties(speed: 0.5, overscan: 2),
            slivers: <Widget>[
              SliverList.builder(
                itemCount: 20,
                itemBuilder: (BuildContext context, int index) =>
                    SizedBox(height: 100, child: Text('Item $index')),
              ),
            ],
          ),
        ),
      );

      final Offset before = tester.getTopLeft(find.byType(Image).first);
      await tester.drag(find.text('Item 0'), const Offset(0, -300));
      await tester.pump();

      expect(
        tester.getTopLeft(find.byType(Image).first).dy,
        lessThan(before.dy),
      );
    });

    testWidgets('moves its background as the content scrolls', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SimpleParallaxContainer(
            image: _image,
            parallax: const ParallaxProperties(speed: 0.5, overscan: 2),
            child: Column(
              children: List<Widget>.generate(
                20,
                (int i) => SizedBox(height: 100, child: Text('Item $i')),
              ),
            ),
          ),
        ),
      );

      Offset backgroundTopLeft() => tester.getTopLeft(find.byType(Image).first);

      final Offset before = backgroundTopLeft();
      await tester.drag(find.text('Item 0'), const Offset(0, -300));
      await tester.pump();

      expect(backgroundTopLeft().dy, lessThan(before.dy));
    });

    testWidgets('moves its background sideways when scrolled horizontally', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SimpleParallaxContainer(
            image: _image,
            scrollDirection: Axis.horizontal,
            parallax: const ParallaxProperties(speed: 0.5, overscan: 2),
            child: Row(
              children: List<Widget>.generate(
                20,
                (int i) => SizedBox(width: 100, child: Text('Item $i')),
              ),
            ),
          ),
        ),
      );

      Offset backgroundTopLeft() => tester.getTopLeft(find.byType(Image).first);

      final Offset before = backgroundTopLeft();
      await tester.drag(find.text('Item 0'), const Offset(-300, 0));
      await tester.pump();

      final Offset after = backgroundTopLeft();
      expect(after.dx, lessThan(before.dx));
      expect(after.dy, before.dy);
    });

    testWidgets('ignores a scrollable running the other way', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SimpleParallaxContainer(
            image: _image,
            parallax: const ParallaxProperties(speed: 0.5, overscan: 2),
            child: Column(
              children: <Widget>[
                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: List<Widget>.generate(
                      20,
                      (int i) => SizedBox(width: 100, child: Text('Nested $i')),
                    ),
                  ),
                ),
                const SizedBox(height: 2000),
              ],
            ),
          ),
        ),
      );

      final Offset before = tester.getTopLeft(find.byType(Image).first);
      await tester.drag(find.text('Nested 0'), const Offset(-300, 0));
      await tester.pump();

      expect(tester.getTopLeft(find.byType(Image).first), before);
    });

    testWidgets('ignores a scrollable nested the same way', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SimpleParallaxContainer(
            background: _layer,
            parallax: const ParallaxProperties(speed: 0.5, overscan: 2),
            child: Column(
              children: <Widget>[
                SizedBox(
                  height: 200,
                  child: ListView(
                    children: List<Widget>.generate(
                      20,
                      (int i) =>
                          SizedBox(height: 100, child: Text('Nested $i')),
                    ),
                  ),
                ),
                const SizedBox(height: 2000),
              ],
            ),
          ),
        ),
      );

      final Offset before = tester.getTopLeft(find.byKey(_layerKey));
      await tester.drag(find.text('Nested 0'), const Offset(0, -150));
      await tester.pump();

      expect(tester.getTopLeft(find.byKey(_layerKey)), before);
    });

    testWidgets('follows content that grows without being scrolled', (
      WidgetTester tester,
    ) async {
      Widget page(int count) => _app(
            SimpleParallaxContainer(
              background: _layer,
              parallax: const ParallaxProperties(overscan: 2),
              child: Column(
                children: List<Widget>.generate(
                  count,
                  (int i) => SizedBox(height: 100, child: Text('Item $i')),
                ),
              ),
            ),
          );

      await tester.pumpWidget(page(20));
      final ScrollPosition position = _position(tester);
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();
      final double atEnd = tester.getTopLeft(find.byKey(_layerKey)).dy;

      // Twice the content with the view where it was: no longer at the end, so
      // the background has to come back part of the way.
      await tester.pumpWidget(page(40));
      await tester.pump();

      expect(tester.getTopLeft(find.byKey(_layerKey)).dy, greaterThan(atEnd));
    });

    testWidgets('takes a new speed without waiting for a scroll', (
      WidgetTester tester,
    ) async {
      Widget page(double speed) => _app(
            SimpleParallaxContainer(
              background: _layer,
              parallax: ParallaxProperties(speed: speed, overscan: 2),
              child: Column(children: _tall()),
            ),
          );

      await tester.pumpWidget(page(1));
      final double atRest = tester.getTopLeft(find.byKey(_layerKey)).dy;
      final ScrollPosition position = _position(tester);
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();

      await tester.pumpWidget(page(0.5));

      // Half of the 600 of travel an overscan of 2 gives a 600 viewport.
      expect(
        atRest - tester.getTopLeft(find.byKey(_layerKey)).dy,
        moreOrLessEquals(300, epsilon: 0.01),
      );
    });

    testWidgets('follows a controller it is given', (
      WidgetTester tester,
    ) async {
      final ScrollController controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _app(
          SimpleParallaxContainer(
            background: _layer,
            controller: controller,
            parallax: const ParallaxProperties(overscan: 2),
            child: Column(children: _tall()),
          ),
        ),
      );

      final double atRest = tester.getTopLeft(find.byKey(_layerKey)).dy;
      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pump();

      expect(
        atRest - tester.getTopLeft(find.byKey(_layerKey)).dy,
        moreOrLessEquals(600, epsilon: 0.01),
      );
    });

    test('stands the smooth wheel down for a controller', () {
      final SimpleParallaxContainer container = SimpleParallaxContainer(
        background: _layer,
        controller: ScrollController(),
        child: const SizedBox(),
      );

      expect(container.smooth, isFalse);
      expect(
        () => SimpleParallaxContainer(
          background: _layer,
          controller: ScrollController(),
          smooth: true,
          child: const SizedBox(),
        ),
        throwsAssertionError,
      );
    });

    testWidgets('hands its physics to the scroll view', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SimpleParallaxContainer(
            background: _layer,
            physics: const NeverScrollableScrollPhysics(),
            child: Column(children: _tall()),
          ),
        ),
      );

      await tester.drag(find.text('Item 0'), const Offset(0, -300));
      await tester.pump();

      expect(_position(tester).pixels, 0);
    });

    testWidgets('lets a scroll notification keep bubbling', (
      WidgetTester tester,
    ) async {
      int seenByAncestor = 0;

      await tester.pumpWidget(
        _app(
          NotificationListener<ScrollUpdateNotification>(
            onNotification: (_) {
              seenByAncestor++;
              return false;
            },
            child: SimpleParallaxContainer(
              image: _image,
              child: Column(
                children: List<Widget>.generate(
                  20,
                  (int i) => SizedBox(height: 100, child: Text('Item $i')),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.drag(find.text('Item 0'), const Offset(0, -200));
      await tester.pump();

      expect(seenByAncestor, greaterThan(0));
    });

    testWidgets('disposes without leaving a listener behind', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SimpleParallaxContainer(
            image: _image,
            child: const SizedBox(height: 2000),
          ),
        ),
      );
      await tester.pumpWidget(_app(const SizedBox()));

      expect(tester.takeException(), isNull);
    });
  });

  group('SimpleParallaxItem', () {
    testWidgets('renders inside any scrollable', (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          ListView(
            children: <Widget>[
              SimpleParallaxItem(
                image: _image,
                height: 200,
                child: const Text('Caption'),
              ),
              const SizedBox(height: 1000),
            ],
          ),
        ),
      );

      expect(find.text('Caption'), findsOneWidget);
      expect(find.byType(Flow), findsOneWidget);
    });

    testWidgets('falls back to a still background outside a scrollable', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(SimpleParallaxItem(image: _image, height: 200)),
      );

      expect(find.byType(Flow), findsNothing);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('slides sideways inside a horizontal scrollable', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          ListView(
            scrollDirection: Axis.horizontal,
            children: <Widget>[
              const SizedBox(width: 600),
              SimpleParallaxItem(
                image: _image,
                width: 200,
                parallax: ParallaxProperties(overscan: 2),
                child: const Text('Caption'),
              ),
              const SizedBox(width: 1000),
            ],
          ),
        ),
      );

      expect(find.text('Caption'), findsOneWidget);
      expect(find.byType(Flow), findsOneWidget);

      Offset backgroundTopLeft() => tester.getTopLeft(find.byType(Image).first);

      final Offset before = backgroundTopLeft();
      await tester.drag(find.byType(ListView), const Offset(-300, 0));
      await tester.pump();

      final Offset after = backgroundTopLeft();
      expect(after.dx, isNot(before.dx));
      expect(after.dy, before.dy);
    });

    testWidgets('survives being scrolled out of the tree', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          ListView(
            children: <Widget>[
              SimpleParallaxItem(image: _image, height: 200),
              const SizedBox(height: 2000),
            ],
          ),
        ),
      );

      await tester.drag(find.byType(ListView), const Offset(0, -1500));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    /// A carousel of one block, a screenful down a vertical page, the block
    /// following the scrollable on [scrollAxis].
    Future<void> pumpCarousel(WidgetTester tester, Axis? scrollAxis) =>
        tester.pumpWidget(
          _app(
            ListView(
              children: <Widget>[
                const SizedBox(height: 600),
                SizedBox(
                  height: 300,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: <Widget>[
                      SimpleParallaxItem(
                        background: _layer,
                        width: 400,
                        scrollAxis: scrollAxis,
                      ),
                      const SizedBox(width: 2000),
                    ],
                  ),
                ),
                const SizedBox(height: 1400),
              ],
            ),
          ),
        );

    ScrollPosition page(WidgetTester tester) =>
        (tester.state(find.byType(Scrollable).first) as ScrollableState)
            .position;
    ScrollPosition carousel(WidgetTester tester) =>
        (tester.state(find.byType(Scrollable).at(1)) as ScrollableState)
            .position;

    /// Where the layer stands inside the block.
    Offset layerInBlock(WidgetTester tester) =>
        tester.getTopLeft(find.byKey(_layerKey)) -
        tester.getTopLeft(find.byType(SimpleParallaxItem));

    testWidgets('follows the nearest scrollable by default', (
      WidgetTester tester,
    ) async {
      await pumpCarousel(tester, null);
      page(tester).jumpTo(300);
      await tester.pump();
      final Offset before = layerInBlock(tester);

      page(tester).jumpTo(500);
      await tester.pump();
      expect(layerInBlock(tester), before);

      carousel(tester).jumpTo(100);
      await tester.pump();
      expect(layerInBlock(tester).dx, isNot(before.dx));
      expect(layerInBlock(tester).dy, before.dy);
    });

    testWidgets('follows the page around a carousel on the axis it is given', (
      WidgetTester tester,
    ) async {
      await pumpCarousel(tester, Axis.vertical);
      page(tester).jumpTo(300);
      await tester.pump();
      final Offset before = layerInBlock(tester);

      // Laid out by the carousel, drawn over the height of the block.
      expect(tester.getSize(find.byKey(_layerKey)), const Size(400, 450));

      carousel(tester).jumpTo(100);
      await tester.pump();
      expect(layerInBlock(tester), before);

      page(tester).jumpTo(500);
      await tester.pump();
      expect(layerInBlock(tester).dx, before.dx);
      expect(layerInBlock(tester).dy, isNot(before.dy));
    });

    testWidgets('holds still with no scrollable on that axis', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          ListView(
            scrollDirection: Axis.horizontal,
            children: const <Widget>[
              SimpleParallaxItem(
                background: _layer,
                width: 400,
                scrollAxis: Axis.vertical,
              ),
              SizedBox(width: 2000),
            ],
          ),
        ),
      );
      final Offset before = layerInBlock(tester);

      _position(tester).jumpTo(100);
      await tester.pump();

      expect(layerInBlock(tester), before);
    });

    test('rejects a speed outside 0..1', () {
      expect(() => ParallaxProperties(speed: 2), throwsAssertionError);
    });
  });

  group('SimpleParallaxWidget', () {
    testWidgets('scrolls the blocks it is given', (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          SimpleParallaxWidget(
            children: <Widget>[
              const SizedBox(height: 400, child: Text('First')),
              SimpleParallaxItem(image: _image, height: 300),
              const SizedBox(height: 800, child: Text('Last')),
            ],
          ),
        ),
      );

      expect(find.text('First'), findsOneWidget);
      await tester.drag(find.text('First'), const Offset(0, -900));
      await tester.pumpAndSettle();

      expect(find.text('Last'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('builds its blocks only as they come into view', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SimpleParallaxWidget(
            children: <Widget>[
              const SizedBox(height: 400, child: Text('First')),
              SimpleParallaxItem(image: _image, height: 800),
              const SizedBox(height: 800, child: Text('Last')),
            ],
          ),
        ),
      );

      expect(find.text('Last'), findsNothing);

      await tester.drag(find.text('First'), const Offset(0, -900));
      await tester.pumpAndSettle();

      expect(find.text('Last'), findsOneWidget);
    });

    testWidgets('creates its blocks only as they come into view', (
      WidgetTester tester,
    ) async {
      final Set<int> created = <int>{};

      await tester.pumpWidget(
        _app(
          SimpleParallaxWidget.builder(
            itemCount: 100,
            itemBuilder: (BuildContext context, int index) {
              created.add(index);
              return SimpleParallaxItem(
                background: _layer,
                height: 300,
                child: Text('Block $index'),
              );
            },
          ),
        ),
      );

      expect(created.length, lessThan(10));

      final ScrollPosition position = _position(tester);
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();

      expect(find.text('Block 99'), findsOneWidget);
      expect(created, isNot(contains(100)));
    });

    testWidgets('pads the list it is given', (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          SimpleParallaxWidget(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              const SizedBox(height: 400, child: Text('First')),
              SimpleParallaxItem(image: _image, height: 300),
            ],
          ),
        ),
      );

      expect(tester.getTopLeft(find.text('First')).dy, 20);
      expect(find.byType(SliverPadding), findsOneWidget);
    });

    testWidgets('lays its blocks out along the horizontal axis', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SimpleParallaxWidget(
            scrollDirection: Axis.horizontal,
            children: <Widget>[
              const SizedBox(width: 400, child: Text('First')),
              SimpleParallaxItem(image: _image, width: 300),
              const SizedBox(width: 800, child: Text('Last')),
            ],
          ),
        ),
      );

      expect(
        tester.widget<Scrollable>(find.byType(Scrollable)).axisDirection,
        AxisDirection.right,
      );
      expect(find.text('First'), findsOneWidget);
      await tester.drag(find.text('First'), const Offset(-900, 0));
      await tester.pumpAndSettle();

      expect(find.text('Last'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('a widget background', () {
    testWidgets('replaces the image in container mode', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SimpleParallaxContainer(
            background: _layer,
            child: Column(
              children: List<Widget>.generate(
                10,
                (int i) => SizedBox(height: 100, child: Text('Item $i')),
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(_layerKey), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      expect(find.text('Item 0'), findsOneWidget);
    });

    testWidgets('moves as the content scrolls in container mode', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SimpleParallaxContainer(
            background: _layer,
            parallax: const ParallaxProperties(speed: 0.5, overscan: 2),
            child: Column(
              children: List<Widget>.generate(
                20,
                (int i) => SizedBox(height: 100, child: Text('Item $i')),
              ),
            ),
          ),
        ),
      );

      Offset layerTopLeft() => tester.getTopLeft(find.byKey(_layerKey));

      final Offset before = layerTopLeft();
      await tester.drag(find.text('Item 0'), const Offset(0, -300));
      await tester.pump();

      expect(layerTopLeft().dy, lessThan(before.dy));
    });

    testWidgets('is drawn over slivers that still build lazily', (
      WidgetTester tester,
    ) async {
      int built = 0;

      await tester.pumpWidget(
        _app(
          SimpleParallaxContainer.slivers(
            background: _layer,
            slivers: <Widget>[
              SliverList.builder(
                itemCount: 1000,
                itemBuilder: (BuildContext context, int index) {
                  built++;
                  return SizedBox(height: 100, child: Text('Item $index'));
                },
              ),
            ],
          ),
        ),
      );

      expect(find.byKey(_layerKey), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      expect(built, lessThan(50));
    });

    testWidgets('slides sideways in item mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          ListView(
            scrollDirection: Axis.horizontal,
            children: const <Widget>[
              SizedBox(width: 600),
              SimpleParallaxItem(
                background: _layer,
                width: 200,
                parallax: ParallaxProperties(overscan: 2),
                child: Text('Caption'),
              ),
              SizedBox(width: 1000),
            ],
          ),
        ),
      );

      expect(find.text('Caption'), findsOneWidget);
      expect(find.byType(Flow), findsOneWidget);
      expect(find.byType(Image), findsNothing);

      Offset layerTopLeft() => tester.getTopLeft(find.byKey(_layerKey));

      final Offset before = layerTopLeft();
      await tester.drag(find.byType(ListView), const Offset(-300, 0));
      await tester.pump();

      final Offset after = layerTopLeft();
      expect(after.dx, isNot(before.dx));
      expect(after.dy, before.dy);
    });

    testWidgets('is drawn still outside a scrollable in item mode', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(const SimpleParallaxItem(background: _layer, height: 200)),
      );

      expect(find.byType(Flow), findsNothing);
      expect(find.byKey(_layerKey), findsOneWidget);
    });

    test('rejects an item given neither an image nor a background', () {
      expect(() => SimpleParallaxItem(height: 200), throwsAssertionError);
    });

    test('rejects an item given both', () {
      expect(
        () => SimpleParallaxItem(image: _image, background: _layer),
        throwsAssertionError,
      );
    });

    test('rejects a container given both', () {
      expect(
        () => SimpleParallaxContainer(
          image: _image,
          background: _layer,
          child: const SizedBox(),
        ),
        throwsAssertionError,
      );
    });
  });

  group('the smooth wheel', () {
    testWidgets('eases a notch in instead of landing it at once', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(SimpleParallaxWidget(smooth: true, children: _tall())),
      );

      await _wheel(tester, const Offset(0, 120));
      await tester.pump();
      expect(_position(tester).pixels, lessThan(120));

      await tester.pumpAndSettle();
      expect(_position(tester).pixels, 120);
    });

    testWidgets('lands the notch on one frame without it', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(SimpleParallaxWidget(smooth: false, children: _tall())),
      );

      await _wheel(tester, const Offset(0, 120));
      await tester.pump();

      expect(_position(tester).pixels, 120);
    });

    testWidgets('adds up the notches of a wheel turned quickly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(SimpleParallaxWidget(smooth: true, children: _tall())),
      );

      await _wheel(tester, const Offset(0, 120));
      await tester.pump(const Duration(milliseconds: 40));
      await _wheel(tester, const Offset(0, 120));
      await tester.pumpAndSettle();

      expect(_position(tester).pixels, 240);
    });

    testWidgets('brings a vertical wheel to a horizontal view', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SimpleParallaxWidget(
            scrollDirection: Axis.horizontal,
            smooth: true,
            children: _wide(),
          ),
        ),
      );

      await _wheel(tester, const Offset(0, 120));
      await tester.pumpAndSettle();

      expect(_position(tester).pixels, 120);
    });

    testWidgets('a horizontal view ignores that wheel without it', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SimpleParallaxWidget(
            smooth: false,
            scrollDirection: Axis.horizontal,
            children: _wide(),
          ),
        ),
      );

      await _wheel(tester, const Offset(0, 120));
      await tester.pumpAndSettle();

      expect(_position(tester).pixels, 0);
    });

    testWidgets('lands a notch at once under reduced motion', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          _reducedMotion(SimpleParallaxWidget(smooth: true, children: _tall())),
        ),
      );

      await _wheel(tester, const Offset(0, 120));
      await tester.pump();

      expect(_position(tester).pixels, 120);
    });

    testWidgets('still brings the wheel sideways under reduced motion', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          _reducedMotion(
            SimpleParallaxWidget(
              scrollDirection: Axis.horizontal,
              smooth: true,
              children: _wide(),
            ),
          ),
        ),
      );

      await _wheel(tester, const Offset(0, 120));
      await tester.pump();

      expect(_position(tester).pixels, 120);
    });

    testWidgets(
      'eases a container wheel told to ignore reduced motion',
      (
        WidgetTester tester,
      ) async {
        Widget page({required bool respect}) => _app(
              _reducedMotion(
                SimpleParallaxContainer(
                  background: _layer,
                  respectReducedMotion: respect,
                  child: Column(children: _tall()),
                ),
              ),
            );

        await tester.pumpWidget(page(respect: true));
        await _wheel(tester, const Offset(0, 120));
        await tester.pump();
        expect(_position(tester).pixels, 120);

        await tester.pumpWidget(page(respect: false));
        await _wheel(tester, const Offset(0, 120));
        await tester.pump();
        expect(_position(tester).pixels, lessThan(240));

        await tester.pumpAndSettle();
        expect(_position(tester).pixels, 240);
      },
      variant: _desktop,
    );

    testWidgets('hands the wheel to the page once a horizontal view is done', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          ListView(
            children: <Widget>[
              SizedBox(
                height: 200,
                child: SimpleParallaxWidget(
                  scrollDirection: Axis.horizontal,
                  smooth: true,
                  children: _wide(),
                ),
              ),
              ..._tall(),
            ],
          ),
        ),
      );

      final ScrollPosition page =
          (tester.state(find.byType(Scrollable).first) as ScrollableState)
              .position;
      final ScrollPosition row = (tester.state(
        find.descendant(
          of: find.byType(SimpleParallaxWidget),
          matching: find.byType(Scrollable),
        ),
      ) as ScrollableState)
          .position;

      Future<void> wheel() async {
        final TestPointer pointer = TestPointer(1, PointerDeviceKind.mouse);
        final Offset over = tester.getCenter(find.byType(SimpleParallaxWidget));
        await tester.sendEventToBinding(pointer.hover(over));
        await tester.sendEventToBinding(pointer.scroll(const Offset(0, 120)));
        await tester.pumpAndSettle();
      }

      await wheel();
      expect(row.pixels, 120);
      expect(page.pixels, 0);

      row.jumpTo(row.maxScrollExtent);
      await tester.pump();
      await wheel();
      expect(page.pixels, 120);
    });

    testWidgets('drives the background of a container', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SimpleParallaxContainer(
            background: _layer,
            smooth: true,
            parallax: const ParallaxProperties(speed: 0.5, overscan: 2),
            child: Column(children: _tall()),
          ),
        ),
      );

      final Offset before = tester.getTopLeft(find.byKey(_layerKey));
      await _wheel(tester, const Offset(0, 300));
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(find.byKey(_layerKey)).dy, lessThan(before.dy));
    });

    testWidgets(
      'keeps easing a container on a SmoothScrollController',
      (
        WidgetTester tester,
      ) async {
        final SmoothScrollController controller = SmoothScrollController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          _app(
            SimpleParallaxContainer(
              background: _layer,
              controller: controller,
              parallax: const ParallaxProperties(overscan: 2),
              child: Column(children: _tall()),
            ),
          ),
        );

        await _wheel(tester, const Offset(0, 120));
        await tester.pump();
        expect(controller.offset, lessThan(120));
        await tester.pumpAndSettle();
        expect(controller.offset, 120);

        // Driven from outside as well, background included.
        final double before = tester.getTopLeft(find.byKey(_layerKey)).dy;
        controller.jumpTo(controller.position.maxScrollExtent);
        await tester.pump();
        expect(tester.getTopLeft(find.byKey(_layerKey)).dy, lessThan(before));
      },
      variant: _desktop,
    );

    testWidgets('brings the wheel sideways on a SmoothScrollController', (
      WidgetTester tester,
    ) async {
      final SmoothScrollController controller = SmoothScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _app(
          SimpleParallaxWidget(
            scrollDirection: Axis.horizontal,
            controller: controller,
            children: _wide(),
          ),
        ),
      );

      await _wheel(tester, const Offset(0, 120));
      await tester.pumpAndSettle();

      expect(controller.offset, 120);
    });

    testWidgets('leaves a SmoothScrollController it was given undisposed', (
      WidgetTester tester,
    ) async {
      final SmoothScrollController controller = SmoothScrollController();

      await tester.pumpWidget(
        _app(
          SimpleParallaxContainer(
            background: _layer,
            controller: controller,
            child: Column(children: _tall()),
          ),
        ),
      );
      await tester.pumpWidget(_app(const SizedBox()));

      // Disposing twice would throw in debug.
      controller.dispose();
      expect(tester.takeException(), isNull);
    });

    test('stays on for a SmoothScrollController', () {
      final SmoothScrollController controller = SmoothScrollController();
      addTearDown(controller.dispose);

      expect(
        SimpleParallaxWidget(controller: controller, children: const <Widget>[])
            .smooth,
        isTrue,
      );
      expect(
        SimpleParallaxContainer(
          background: _layer,
          controller: controller,
          smooth: true,
          child: const SizedBox(),
        ).smooth,
        isTrue,
      );
    });

    testWidgets(
      'stays off on a phone, leaving the view primary',
      (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          _app(
            SimpleParallaxContainer(
              background: _layer,
              child: Column(children: _tall()),
            ),
          ),
        );

        // No controller of its own, so a tap on the iOS status bar reaches it.
        expect(
          tester
              .widget<CustomScrollView>(find.byType(CustomScrollView))
              .controller,
          isNull,
        );
        await _wheel(tester, const Offset(0, 120));
        await tester.pump();
        expect(_position(tester).pixels, 120);
      },
      variant: TargetPlatformVariant(
        <TargetPlatform>{TargetPlatform.android, TargetPlatform.iOS},
      ),
    );

    testWidgets(
      'eases on a phone when asked to',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _app(
            SimpleParallaxWidget(smooth: true, children: _tall()),
          ),
        );

        await _wheel(tester, const Offset(0, 120));
        await tester.pump();
        expect(_position(tester).pixels, lessThan(120));
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );

    testWidgets(
      'eases on a desktop by default',
      (WidgetTester tester) async {
        await tester.pumpWidget(_app(SimpleParallaxWidget(children: _tall())));

        await _wheel(tester, const Offset(0, 120));
        await tester.pump();
        expect(_position(tester).pixels, lessThan(120));
      },
      variant: _desktop,
    );

    test('is on when nothing stands in its way', () {
      expect(const SimpleParallaxWidget(children: <Widget>[]).smooth, isTrue);
    });

    test('stands down for a controller rather than fight it', () {
      final SimpleParallaxWidget view = SimpleParallaxWidget(
        controller: ScrollController(),
        children: const <Widget>[],
      );

      expect(view.smooth, isFalse);
    });

    test('refuses a controller it cannot make smooth', () {
      expect(
        () => SimpleParallaxWidget(
          smooth: true,
          controller: ScrollController(),
          children: const <Widget>[],
        ),
        throwsAssertionError,
      );
    });
  });

  group('the zoom', () {
    testWidgets('leaves the background at rest untouched', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SimpleParallaxContainer(
            background: _layer,
            zoom: const ZoomProperties(0.5),
            parallax: const ParallaxProperties(speed: 0.3, overscan: 2),
            child: Column(children: _tall()),
          ),
        ),
      );

      // Painted and laid out agree only while the scale is 1.
      expect(
        tester.getRect(find.byKey(_layerKey)).height,
        tester.getSize(find.byKey(_layerKey)).height,
      );
    });

    testWidgets('grows the background across the scroll in container mode', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SimpleParallaxContainer(
            background: _layer,
            zoom: const ZoomProperties(0.5),
            parallax: const ParallaxProperties(speed: 0.3, overscan: 2),
            child: Column(children: _tall()),
          ),
        ),
      );

      final double atRest = tester.getRect(find.byKey(_layerKey)).height;
      final ScrollPosition position = _position(tester);
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();

      expect(
        tester.getRect(find.byKey(_layerKey)).height / atRest,
        moreOrLessEquals(1.5, epsilon: 0.01),
      );
    });

    testWidgets('leaves the background alone when it is off', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SimpleParallaxContainer(
            background: _layer,
            parallax: const ParallaxProperties(speed: 0.3, overscan: 2),
            child: Column(children: _tall()),
          ),
        ),
      );

      final double atRest = tester.getRect(find.byKey(_layerKey)).height;
      final ScrollPosition position = _position(tester);
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();

      expect(tester.getRect(find.byKey(_layerKey)).height, atRest);
    });

    testWidgets('scales the painting and not the layout', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SimpleParallaxContainer(
            background: _layer,
            zoom: const ZoomProperties(0.5),
            parallax: const ParallaxProperties(speed: 0.3, overscan: 2),
            child: Column(children: _tall()),
          ),
        ),
      );

      final double laidOut = tester.getSize(find.byKey(_layerKey)).height;
      final ScrollPosition position = _position(tester);
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();

      expect(tester.getSize(find.byKey(_layerKey)).height, laidOut);
      expect(
        tester.getRect(find.byKey(_layerKey)).height,
        greaterThan(laidOut),
      );
    });

    testWidgets('grows a block background as the block crosses', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          ListView(
            children: const <Widget>[
              SizedBox(height: 700),
              SimpleParallaxItem(
                background: _layer,
                height: 200,
                parallax: ParallaxProperties(overscan: 2),
                zoom: ZoomProperties(0.5),
              ),
              SizedBox(height: 1200),
            ],
          ),
        ),
      );

      await tester.drag(find.byType(ListView), const Offset(0, -260));
      await tester.pump();
      final double entering = tester.getRect(find.byKey(_layerKey)).height;

      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pump();
      final double leaving = tester.getRect(find.byKey(_layerKey)).height;

      expect(leaving, greaterThan(entering));
    });

    testWidgets('read backwards, a negative zoom starts enlarged', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SimpleParallaxContainer(
            background: _layer,
            zoom: const ZoomProperties(-0.5),
            parallax: const ParallaxProperties(speed: 0.3, overscan: 2),
            child: Column(children: _tall()),
          ),
        ),
      );

      final double laidOut = tester.getSize(find.byKey(_layerKey)).height;
      expect(
        tester.getRect(find.byKey(_layerKey)).height / laidOut,
        moreOrLessEquals(1.5, epsilon: 0.01),
      );

      final ScrollPosition position = _position(tester);
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();

      expect(
        tester.getRect(find.byKey(_layerKey)).height,
        moreOrLessEquals(laidOut, epsilon: 0.01),
      );
    });

    testWidgets('never scales the background below 1', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SimpleParallaxContainer(
            background: _layer,
            zoom: const ZoomProperties(-0.5),
            parallax: const ParallaxProperties(speed: 0.3, overscan: 2),
            child: Column(children: _tall()),
          ),
        ),
      );

      final double laidOut = tester.getSize(find.byKey(_layerKey)).height;
      final ScrollPosition position = _position(tester);

      for (final double at in <double>[0, 0.25, 0.5, 0.75, 1]) {
        position.jumpTo(position.maxScrollExtent * at);
        await tester.pump();
        expect(
          tester.getRect(find.byKey(_layerKey)).height,
          greaterThanOrEqualTo(laidOut - 0.01),
        );
      }
    });
  });

  group('a block that is on its way in', () {
    /// How far the background sits inside the block, which is what the drift
    /// and the zoom both move.
    double inside(WidgetTester tester) =>
        tester.getRect(find.byKey(_layerKey)).top -
        tester.getRect(find.byType(SimpleParallaxItem)).top;

    Future<void> pumpBlock(WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          ListView(
            children: const <Widget>[
              SizedBox(height: 600),
              SimpleParallaxItem(
                background: _layer,
                height: 400,
                parallax: ParallaxProperties(overscan: 2),
              ),
              SizedBox(height: 1400),
            ],
          ),
        ),
      );
    }

    testWidgets('moves from the moment it appears', (
      WidgetTester tester,
    ) async {
      await pumpBlock(tester);
      final ScrollPosition position = _position(tester);

      // The block's middle only reaches the viewport at 200, so both of these
      // sit in the stretch where the effect used to stand still.
      position.jumpTo(50);
      await tester.pump();
      final double onArrival = inside(tester);

      position.jumpTo(150);
      await tester.pump();

      expect(inside(tester), isNot(onArrival));
    });

    testWidgets('is still moving as it leaves', (WidgetTester tester) async {
      await pumpBlock(tester);
      final ScrollPosition position = _position(tester);

      // The block's middle has reached the top of the screen.
      position.jumpTo(800);
      await tester.pump();
      final double nearlyGone = inside(tester);

      // Half the block is still on screen here.
      position.jumpTo(900);
      await tester.pump();

      expect(inside(tester), isNot(nearlyGone));
    });
  });

  group('the blur', () {
    testWidgets('leaves the layer unfiltered when it is off', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SimpleParallaxContainer(
            background: _layer,
            child: Column(children: _tall()),
          ),
        ),
      );

      expect(_blur(tester), isNull);
    });

    testWidgets('sharpens into a blur down the page', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SimpleParallaxContainer(
            background: _layer,
            blur: const BlurProperties(12),
            child: Column(children: _tall()),
          ),
        ),
      );

      expect(_blur(tester), isNull);

      // 2000 of content in a 600 viewport, so the end of the travel.
      _position(tester).jumpTo(1400);
      await tester.pump();

      expect(_blur(tester), _blurOf(12));
    });

    testWidgets('read backwards, a negative blur starts blurred', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SimpleParallaxContainer(
            background: _layer,
            blur: const BlurProperties(-12),
            child: Column(children: _tall()),
          ),
        ),
      );

      expect(_blur(tester), _blurOf(12));

      _position(tester).jumpTo(1400);
      await tester.pump();

      expect(_blur(tester), isNull);
    });

    testWidgets('holds the filter through a change no one can see', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SimpleParallaxContainer(
            background: _layer,
            blur: const BlurProperties(12),
            child: Column(children: _tall()),
          ),
        ),
      );

      _position(tester).jumpTo(700);
      await tester.pump();

      // A single pixel is under a hundredth of a sigma here.
      _position(tester).jumpTo(701);
      await tester.pump();

      expect(_blur(tester), _blurOf(6));
    });

    /// A block of 400 below a screenful, so it crosses a 600 viewport over
    /// 1000 of scrolling.
    Future<void> pumpBlock(WidgetTester tester, double blur) async {
      await tester.pumpWidget(
        _app(
          ListView(
            children: <Widget>[
              const SizedBox(height: 600),
              SimpleParallaxItem(
                background: _layer,
                height: 400,
                blur: BlurProperties(blur),
              ),
              const SizedBox(height: 1400),
            ],
          ),
        ),
      );
    }

    testWidgets('blurs a block as it crosses', (WidgetTester tester) async {
      await pumpBlock(tester, 20);

      // A quarter of the way across, and three quarters.
      _position(tester).jumpTo(250);
      await tester.pump();

      expect(_blur(tester), _blurOf(5));

      _position(tester).jumpTo(750);
      await tester.pump();

      expect(_blur(tester), _blurOf(15));
    });

    testWidgets('read backwards, a block clears as it crosses', (
      WidgetTester tester,
    ) async {
      await pumpBlock(tester, -20);

      _position(tester).jumpTo(250);
      await tester.pump();

      expect(_blur(tester), _blurOf(15));

      _position(tester).jumpTo(750);
      await tester.pump();

      expect(_blur(tester), _blurOf(5));
    });

    testWidgets('reads a block on the frame it is drawn', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          ListView(
            children: const <Widget>[
              SimpleParallaxItem(
                background: _layer,
                height: 400,
                blur: BlurProperties(10),
              ),
              SizedBox(height: 1400),
            ],
          ),
        ),
      );

      // The block opens the page, so it is already three fifths of the way
      // across its 600 + 400 crossing, with no scroll to announce it.
      expect(_blur(tester), _blurOf(6));
    });
  });

  group('an effect that stops part way', () {
    testWidgets('holds the zoom from halfway down the page', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SimpleParallaxContainer(
            background: _layer,
            zoom: const ZoomProperties(0.5, reach: 0.5),
            parallax: const ParallaxProperties(overscan: 2),
            child: Column(children: _tall()),
          ),
        ),
      );

      double height(WidgetTester tester) =>
          tester.getRect(find.byKey(_layerKey)).height;

      final double atRest = height(tester);

      // 2000 of content in a 600 viewport, so halfway and the end.
      _position(tester).jumpTo(700);
      await tester.pump();

      expect(height(tester) / atRest, moreOrLessEquals(1.5, epsilon: 0.01));

      _position(tester).jumpTo(1400);
      await tester.pump();

      expect(height(tester) / atRest, moreOrLessEquals(1.5, epsilon: 0.01));
    });

    testWidgets('holds a block blur once it is reached', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          ListView(
            children: const <Widget>[
              SizedBox(height: 600),
              SimpleParallaxItem(
                background: _layer,
                height: 400,
                blur: BlurProperties(20, reach: 0.5),
              ),
              SizedBox(height: 1400),
            ],
          ),
        ),
      );

      // A quarter, a half and three quarters of a 600 + 400 crossing.
      _position(tester).jumpTo(250);
      await tester.pump();

      expect(_blur(tester), _blurOf(10));

      _position(tester).jumpTo(500);
      await tester.pump();

      expect(_blur(tester), _blurOf(20));

      _position(tester).jumpTo(750);
      await tester.pump();

      expect(_blur(tester), _blurOf(20));
    });

    testWidgets('takes the zoom out and back down the page', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SimpleParallaxContainer(
            background: _layer,
            zoom: const ZoomProperties(0.5, reach: 0.5, back: true),
            parallax: const ParallaxProperties(overscan: 2),
            child: Column(children: _tall()),
          ),
        ),
      );

      double height(WidgetTester tester) =>
          tester.getRect(find.byKey(_layerKey)).height;

      final double atRest = height(tester);

      // 2000 of content in a 600 viewport, so halfway and the end.
      _position(tester).jumpTo(700);
      await tester.pump();

      expect(height(tester) / atRest, moreOrLessEquals(1.5, epsilon: 0.01));

      _position(tester).jumpTo(1400);
      await tester.pump();

      expect(height(tester) / atRest, moreOrLessEquals(1, epsilon: 0.01));
    });

    testWidgets('clears the blur halfway and lets it back', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SimpleParallaxContainer(
            background: _layer,
            blur: const BlurProperties(-16, reach: 0.5, back: true),
            child: Column(children: _tall()),
          ),
        ),
      );

      expect(_blur(tester), _blurOf(16));

      _position(tester).jumpTo(700);
      await tester.pump();

      expect(_blur(tester), isNull);

      _position(tester).jumpTo(1400);
      await tester.pump();

      expect(_blur(tester), _blurOf(16));
    });

    testWidgets('reads the same either side of a block', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          ListView(
            children: const <Widget>[
              SizedBox(height: 600),
              SimpleParallaxItem(
                background: _layer,
                height: 400,
                blur: BlurProperties(20, reach: 0.5, back: true),
              ),
              SizedBox(height: 1400),
            ],
          ),
        ),
      );

      // A quarter, a half and three quarters of a 600 + 400 crossing.
      _position(tester).jumpTo(250);
      await tester.pump();

      expect(_blur(tester), _blurOf(10));

      _position(tester).jumpTo(500);
      await tester.pump();

      expect(_blur(tester), _blurOf(20));

      _position(tester).jumpTo(750);
      await tester.pump();

      expect(_blur(tester), _blurOf(10));
    });

    testWidgets('takes a block zoom out and back', (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          ListView(
            children: const <Widget>[
              SizedBox(height: 600),
              SimpleParallaxItem(
                background: _layer,
                height: 400,
                parallax: ParallaxProperties(speed: 0),
                zoom: ZoomProperties(0.5, reach: 0.5, back: true),
              ),
              SizedBox(height: 1400),
            ],
          ),
        ),
      );

      double height(WidgetTester tester) =>
          tester.getRect(find.byKey(_layerKey)).height;

      _position(tester).jumpTo(250);
      await tester.pump();
      final double quarter = height(tester);

      _position(tester).jumpTo(500);
      await tester.pump();

      expect(height(tester), greaterThan(quarter));

      _position(tester).jumpTo(750);
      await tester.pump();

      expect(height(tester), moreOrLessEquals(quarter, epsilon: 0.01));
    });

    test('refuses a reach outside the travel', () {
      expect(() => ZoomProperties(0.5, reach: 1.5), throwsAssertionError);
      expect(() => BlurProperties(8, reach: -1), throwsAssertionError);
    });

    test('refuses a way back from nowhere', () {
      expect(() => ZoomProperties(0.5, back: true), throwsAssertionError);
      expect(() => BlurProperties(8, back: true), throwsAssertionError);
    });
  });

  group('the drift', () {
    /// How far the background has moved from where it started.
    double moved(WidgetTester tester, double from) =>
        from - tester.getTopLeft(find.byKey(_layerKey)).dy;

    Future<void> pumpPage(WidgetTester tester, double speed) async {
      await tester.pumpWidget(
        _app(
          SimpleParallaxContainer(
            background: _layer,
            parallax: ParallaxProperties(speed: speed, overscan: 2),
            child: Column(children: _tall()),
          ),
        ),
      );
    }

    testWidgets('spends exactly its travel over the whole scroll', (
      WidgetTester tester,
    ) async {
      await pumpPage(tester, 1);
      final double atRest = tester.getTopLeft(find.byKey(_layerKey)).dy;

      final ScrollPosition position = _position(tester);
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();

      // An overscan of 2 over a 600 viewport is 600 of travel.
      expect(moved(tester, atRest), moreOrLessEquals(600, epsilon: 0.01));
    });

    testWidgets('spends the fraction it is given and no more', (
      WidgetTester tester,
    ) async {
      await pumpPage(tester, 0.5);
      final double atRest = tester.getTopLeft(find.byKey(_layerKey)).dy;

      final ScrollPosition position = _position(tester);
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();

      expect(moved(tester, atRest), moreOrLessEquals(300, epsilon: 0.01));
    });

    testWidgets('pins the background at zero', (WidgetTester tester) async {
      await pumpPage(tester, 0);
      final double atRest = tester.getTopLeft(find.byKey(_layerKey)).dy;

      final ScrollPosition position = _position(tester);
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();

      expect(moved(tester, atRest), 0);
    });
  });

  group('the overlay', () {
    /// The decoration the overlay draws, whichever mode built it.
    BoxDecoration decoration(WidgetTester tester) => tester
        .widget<DecoratedBox>(
          find.descendant(
            of: find.byType(OverlayLayer),
            matching: find.byType(DecoratedBox),
          ),
        )
        .decoration as BoxDecoration;

    testWidgets('draws nothing when there is none', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SimpleParallaxContainer(
            background: _layer,
            child: Column(children: _tall()),
          ),
        ),
      );

      expect(find.byType(OverlayLayer), findsNothing);
    });

    testWidgets('darkens the page at the opacity it is given', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SimpleParallaxContainer(
            background: _layer,
            overlay: const OverlayProperties.darken(0.4),
            child: Column(children: _tall()),
          ),
        ),
      );

      expect(decoration(tester).color, const Color(0xFF000000));
      expect(
        tester
            .widget<Opacity>(
              find.descendant(
                of: find.byType(OverlayLayer),
                matching: find.byType(Opacity),
              ),
            )
            .opacity,
        0.4,
      );
    });

    testWidgets('lightens it the other way', (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          SimpleParallaxContainer(
            background: _layer,
            overlay: const OverlayProperties.lighten(0.2),
            child: Column(children: _tall()),
          ),
        ),
      );

      expect(decoration(tester).color, const Color(0xFFFFFFFF));
    });

    testWidgets('takes a gradient for a scrim', (WidgetTester tester) async {
      const LinearGradient scrim = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: <Color>[Color(0xCC000000), Color(0x00000000)],
      );

      await tester.pumpWidget(
        _app(
          ListView(
            children: const <Widget>[
              SimpleParallaxItem(
                background: _layer,
                height: 400,
                overlay: OverlayProperties.gradient(scrim),
              ),
              SizedBox(height: 1400),
            ],
          ),
        ),
      );

      expect(decoration(tester).gradient, scrim);
      expect(decoration(tester).color, isNull);
    });

    testWidgets('sits over the background and under the content', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          ListView(
            children: const <Widget>[
              SimpleParallaxItem(
                background: _layer,
                height: 400,
                overlay: OverlayProperties.darken(0.3),
                child: Center(child: Text('Chapter one')),
              ),
              SizedBox(height: 1400),
            ],
          ),
        ),
      );

      final Stack stack = tester.widget<Stack>(
        find
            .descendant(
              of: find.byType(SimpleParallaxItem),
              matching: find.byType(Stack),
            )
            .first,
      );

      expect(stack.children.length, 3);
      expect(stack.children[1], isA<OverlayLayer>());
      expect(stack.children.last, isA<Center>());
    });

    testWidgets('stays put while the background moves under it', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SimpleParallaxContainer(
            background: _layer,
            overlay: const OverlayProperties.darken(0.3),
            child: Column(children: _tall()),
          ),
        ),
      );

      final Rect before = tester.getRect(find.byType(OverlayLayer));
      final double layerBefore = tester.getTopLeft(find.byKey(_layerKey)).dy;

      final ScrollPosition position = _position(tester);
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();

      expect(
        tester.getTopLeft(find.byKey(_layerKey)).dy,
        lessThan(layerBefore),
      );
      expect(tester.getRect(find.byType(OverlayLayer)), before);
    });
  });

  group('semantics', () {
    /// Whether anything on screen is announced as an image.
    bool anImageIn(WidgetTester tester) {
      bool found = false;
      bool visit(SemanticsNode node) {
        found = found || node.getSemanticsData().flagsCollection.isImage;
        node.visitChildren(visit);
        return true;
      }

      visit(tester.getSemantics(find.byType(MaterialApp)));
      return found;
    }

    testWidgets('leaves an item background out', (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          ListView(
            children: <Widget>[
              SimpleParallaxItem(
                image: _image,
                height: 300,
                child: const Center(child: Text('Chapter one')),
              ),
            ],
          ),
        ),
      );

      expect(anImageIn(tester), isFalse);
      semantics.dispose();
    });

    testWidgets('leaves a container background out', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          SimpleParallaxContainer(
            image: _image,
            child: const Center(child: Text('Page')),
          ),
        ),
      );

      expect(anImageIn(tester), isFalse);
      semantics.dispose();
    });
  });

  group('reduced motion', () {
    Future<void> pumpPage(WidgetTester tester, {required bool respect}) =>
        tester.pumpWidget(
          _app(
            _reducedMotion(
              SimpleParallaxContainer(
                background: _layer,
                parallax: const ParallaxProperties(overscan: 2),
                zoom: const ZoomProperties(0.5),
                respectReducedMotion: respect,
                child: Column(children: _tall()),
              ),
            ),
          ),
        );

    testWidgets('holds a container background still', (
      WidgetTester tester,
    ) async {
      await pumpPage(tester, respect: true);
      final Rect atRest = tester.getRect(find.byKey(_layerKey));

      final ScrollPosition position = _position(tester);
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();

      expect(tester.getRect(find.byKey(_layerKey)), atRest);
    });

    testWidgets('moves it anyway when told to', (WidgetTester tester) async {
      await pumpPage(tester, respect: false);
      final Rect atRest = tester.getRect(find.byKey(_layerKey));

      final ScrollPosition position = _position(tester);
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();

      expect(tester.getRect(find.byKey(_layerKey)), isNot(atRest));
    });

    /// A block of 400 below a screenful, with a background of 600 at the
    /// default overscan, so a centred one stands 100 above the block.
    Future<void> pumpBlock(WidgetTester tester) => tester.pumpWidget(
          _app(
            _reducedMotion(
              ListView(
                children: const <Widget>[
                  SizedBox(height: 600),
                  SimpleParallaxItem(
                    background: _layer,
                    height: 400,
                    blur: BlurProperties(12),
                  ),
                  SizedBox(height: 1400),
                ],
              ),
            ),
          ),
        );

    double layerInBlock(WidgetTester tester) =>
        tester.getTopLeft(find.byKey(_layerKey)).dy -
        tester.getTopLeft(find.byType(SimpleParallaxItem)).dy;

    testWidgets('holds a block background centred', (
      WidgetTester tester,
    ) async {
      await pumpBlock(tester);
      // Just in, where a moving background would still sit near one end.
      _position(tester).jumpTo(100);
      await tester.pump();
      expect(layerInBlock(tester), -100);

      _position(tester).jumpTo(900);
      await tester.pump();

      expect(layerInBlock(tester), -100);
    });

    testWidgets('holds a block blur at its mid-crossing value', (
      WidgetTester tester,
    ) async {
      await pumpBlock(tester);
      _position(tester).jumpTo(100);
      await tester.pump();
      expect(_blur(tester), _blurOf(6));

      _position(tester).jumpTo(900);
      await tester.pump();

      expect(_blur(tester), _blurOf(6));
    });
  });

  group('a scroll running the other way', () {
    testWidgets('drifts a right-to-left container with its content', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          Directionality(
            textDirection: TextDirection.rtl,
            child: SimpleParallaxContainer(
              background: _layer,
              scrollDirection: Axis.horizontal,
              parallax: const ParallaxProperties(overscan: 2),
              child: Row(children: _wide()),
            ),
          ),
        ),
      );

      final double content = tester.getTopLeft(find.text('Item 0')).dx;
      final Rect atRest = tester.getRect(find.byKey(_layerKey));
      // Starts against the right edge, the end the content comes from.
      expect(atRest.right, 800);

      _position(tester).jumpTo(400);
      await tester.pump();

      final double contentMoved =
          tester.getTopLeft(find.text('Item 0')).dx - content;
      final double backgroundMoved =
          tester.getTopLeft(find.byKey(_layerKey)).dx - atRest.left;
      expect(contentMoved, 400);
      expect(backgroundMoved, greaterThan(0));
      expect(backgroundMoved, lessThan(contentMoved));
    });

    /// A block of 400 in a list of [direction], a screenful from its start.
    Future<void> pumpBlock(
      WidgetTester tester, {
      TextDirection direction = TextDirection.ltr,
      Axis axis = Axis.horizontal,
      bool reverse = false,
    }) =>
        tester.pumpWidget(
          _app(
            Directionality(
              textDirection: direction,
              child: ListView(
                scrollDirection: axis,
                reverse: reverse,
                children: const <Widget>[
                  SizedBox(width: 800, height: 600),
                  SimpleParallaxItem(
                    background: _layer,
                    width: 400,
                    height: 400,
                    zoom: ZoomProperties(0.5),
                  ),
                  SizedBox(width: 1200, height: 1400),
                ],
              ),
            ),
          ),
        );

    /// The block and its layer at [scrolled], as the block crosses.
    Future<(Rect, Rect)> at(WidgetTester tester, double scrolled) async {
      _position(tester).jumpTo(scrolled);
      await tester.pump();
      return (
        tester.getRect(find.byType(SimpleParallaxItem)),
        tester.getRect(find.byKey(_layerKey)),
      );
    }

    testWidgets('zooms a right-to-left block in as it crosses', (
      WidgetTester tester,
    ) async {
      await pumpBlock(tester, direction: TextDirection.rtl);

      final (Rect _, Rect entering) = await at(tester, 200);
      final (Rect _, Rect leaving) = await at(tester, 1000);

      expect(leaving.width, greaterThan(entering.width));
    });

    testWidgets('lets a right-to-left background lag behind its block', (
      WidgetTester tester,
    ) async {
      await pumpBlock(tester, direction: TextDirection.rtl);

      final (Rect block1, Rect layer1) = await at(tester, 500);
      final (Rect block2, Rect layer2) = await at(tester, 700);

      final double blockMoved = block2.left - block1.left;
      final double layerMoved = layer2.left - layer1.left;
      expect(blockMoved, 200);
      expect(layerMoved, greaterThan(0));
      expect(layerMoved, lessThan(blockMoved));
    });

    testWidgets('zooms a block in a reversed list in as it crosses', (
      WidgetTester tester,
    ) async {
      await pumpBlock(tester, axis: Axis.vertical, reverse: true);

      final (Rect _, Rect entering) = await at(tester, 200);
      final (Rect _, Rect leaving) = await at(tester, 800);

      expect(leaving.height, greaterThan(entering.height));
    });
  });

  group('decoding at the size drawn', () {
    test('keeps the larger ratio for a cover', () {
      expect(
        decodeSizeFor(
          const Size(4000, 2000),
          const Size(1000, 1000),
          BoxFit.cover,
        ),
        const Size(2000, 1000),
      );
    });

    test('keeps the smaller ratio for a contain', () {
      expect(
        decodeSizeFor(
          const Size(4000, 2000),
          const Size(1000, 1000),
          BoxFit.contain,
        ),
        const Size(1000, 500),
      );
    });

    test('never scales an image up', () {
      expect(
        decodeSizeFor(
          const Size(800, 600),
          const Size(2000, 2000),
          BoxFit.cover,
        ),
        isNull,
      );
    });

    test('rounds the box up, so a small resize reuses the decode', () {
      final ImageProvider<Object> a = decodedFor(
        _image,
        layer: const Size(400, 300),
        devicePixelRatio: 2,
        fit: BoxFit.cover,
      );
      final ImageProvider<Object> b = decodedFor(
        _image,
        layer: const Size(401, 301),
        devicePixelRatio: 2,
        fit: BoxFit.cover,
      );

      expect(a, b);
      expect((a as DisplaySizeImage).size, const Size(832, 640));
    });

    test('leaves room for the zoom', () {
      final DisplaySizeImage image = decodedFor(
        _image,
        layer: const Size(640, 640),
        devicePixelRatio: 1,
        fit: BoxFit.cover,
        zoom: 1.5,
      ) as DisplaySizeImage;

      expect(image.size, const Size(960, 960));
    });

    /// The provider the one [Image] under test draws.
    ImageProvider<Object> drawn(WidgetTester tester) =>
        tester.widget<Image>(find.byType(Image)).image;

    testWidgets('decodes an item for its layer', (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          ListView(
            children: <Widget>[
              SimpleParallaxItem(image: _image, height: 200),
            ],
          ),
        ),
      );

      // 800 by 200 at an overscan of 1.5, on a screen of 3, rounded up.
      final DisplaySizeImage image = drawn(tester) as DisplaySizeImage;
      expect(image.size, const Size(2432, 960));
      expect(image.image, _image);
    });

    testWidgets('decodes a container for its layer', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SimpleParallaxContainer(
            image: _image,
            parallax: const ParallaxProperties(overscan: 2),
            child: Column(children: _tall()),
          ),
        ),
      );

      // 800 by 600 at an overscan of 2, on a screen of 3.
      expect((drawn(tester) as DisplaySizeImage).size, const Size(2432, 3648));
    });

    testWidgets('hands the image over untouched when told to', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          ListView(
            children: <Widget>[
              SimpleParallaxItem(
                image: _image,
                height: 200,
                decodeAtDisplaySize: false,
              ),
            ],
          ),
        ),
      );

      expect(drawn(tester), _image);
    });

    testWidgets('decodes a large picture no larger than it is drawn', (
      WidgetTester tester,
    ) async {
      final Uint8List? bytes = await tester.runAsync(() async {
        final ui.PictureRecorder recorder = ui.PictureRecorder();
        Canvas(recorder).drawRect(
          const Rect.fromLTWH(0, 0, 4000, 2000),
          Paint()..color = const Color(0xFF3060A0),
        );
        final ui.Image picture =
            await recorder.endRecording().toImage(4000, 2000);
        final ByteData? png =
            await picture.toByteData(format: ui.ImageByteFormat.png);
        return png!.buffer.asUint8List();
      });
      final MemoryImage large = MemoryImage(bytes!);

      Future<int> decodedWidth({required bool atDisplaySize}) async {
        await tester.pumpWidget(
          _app(
            ListView(
              children: <Widget>[
                SimpleParallaxItem(
                  image: large,
                  height: 200,
                  decodeAtDisplaySize: atDisplaySize,
                ),
              ],
            ),
          ),
        );
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)),
        );
        await tester.pump();
        return tester.widget<RawImage>(find.byType(RawImage)).image!.width;
      }

      // The layer is 2432 by 960 physical pixels: a 2 to 1 picture covers it
      // at 2432 by 1216.
      expect(await decodedWidth(atDisplaySize: true), 2432);
      imageCache.clear();
      expect(await decodedWidth(atDisplaySize: false), 4000);
    });
  });

  group('the item frame', () {
    testWidgets('aligns its image as it is told', (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          ListView(
            children: <Widget>[
              SimpleParallaxItem(
                image: _image,
                height: 200,
                alignment: Alignment.topCenter,
              ),
            ],
          ),
        ),
      );

      expect(
        tester.widget<Image>(find.byType(Image)).alignment,
        Alignment.topCenter,
      );
    });

    testWidgets('rounds its corners, content included', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          ListView(
            children: <Widget>[
              SimpleParallaxItem(
                background: _layer,
                height: 200,
                borderRadius: BorderRadius.circular(18),
                child: const Text('Caption'),
              ),
            ],
          ),
        ),
      );

      final Finder clip = find.byType(ClipRRect);
      expect(
        tester.widget<ClipRRect>(clip).borderRadius,
        BorderRadius.circular(18),
      );
      expect(
        find.descendant(of: clip, matching: find.text('Caption')),
        findsOneWidget,
      );
    });

    testWidgets('stays square by default', (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          ListView(
            children: const <Widget>[
              SimpleParallaxItem(background: _layer, height: 200),
            ],
          ),
        ),
      );

      expect(find.byType(ClipRRect), findsNothing);
    });
  });

  group('the scroll view', () {
    testWidgets('takes what a container hands it', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SimpleParallaxContainer(
            background: _layer,
            restorationId: 'page',
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            clipBehavior: Clip.none,
            child: Column(children: _tall()),
          ),
        ),
      );

      final CustomScrollView view =
          tester.widget<CustomScrollView>(find.byType(CustomScrollView));
      expect(view.restorationId, 'page');
      expect(
        view.keyboardDismissBehavior,
        ScrollViewKeyboardDismissBehavior.onDrag,
      );
      expect(view.clipBehavior, Clip.none);
    });

    testWidgets('takes what a widget hands it', (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          SimpleParallaxWidget(
            restorationId: 'list',
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            clipBehavior: Clip.none,
            children: _tall(),
          ),
        ),
      );

      final CustomScrollView view =
          tester.widget<CustomScrollView>(find.byType(CustomScrollView));
      expect(view.restorationId, 'list');
      expect(
        view.keyboardDismissBehavior,
        ScrollViewKeyboardDismissBehavior.onDrag,
      );
      expect(view.clipBehavior, Clip.none);
    });
  });

  group('the drift across', () {
    /// A carousel of one 400 by 300 block, a screenful down a vertical page,
    /// drifting with the carousel and, through [crossParallax], with the page.
    Future<void> pumpCross(
      WidgetTester tester, {
      ParallaxProperties? crossParallax = const ParallaxProperties(),
      ZoomProperties? zoom,
      ImageProvider? image,
    }) =>
        tester.pumpWidget(
          _app(
            ListView(
              children: <Widget>[
                const SizedBox(height: 600),
                SizedBox(
                  height: 300,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: <Widget>[
                      SimpleParallaxItem(
                        image: image,
                        background: image == null ? _layer : null,
                        width: 400,
                        zoom: zoom,
                        crossParallax: crossParallax,
                      ),
                      const SizedBox(width: 2000),
                    ],
                  ),
                ),
                const SizedBox(height: 1400),
              ],
            ),
          ),
        );

    ScrollPosition page(WidgetTester tester) =>
        (tester.state(find.byType(Scrollable).first) as ScrollableState)
            .position;
    ScrollPosition carousel(WidgetTester tester) =>
        (tester.state(find.byType(Scrollable).at(1)) as ScrollableState)
            .position;

    Rect layerInBlock(WidgetTester tester) =>
        tester.getRect(find.byKey(_layerKey)).shift(
              -tester.getTopLeft(find.byType(SimpleParallaxItem)),
            );

    testWidgets('drifts with the carousel and with the page', (
      WidgetTester tester,
    ) async {
      await pumpCross(tester);
      page(tester).jumpTo(300);
      await tester.pump();
      final Rect before = layerInBlock(tester);

      // Drawn larger on both axes.
      expect(before.size, const Size(600, 450));

      page(tester).jumpTo(500);
      await tester.pump();
      final Rect paged = layerInBlock(tester);
      expect(paged.left, before.left);
      expect(paged.top, isNot(before.top));

      carousel(tester).jumpTo(100);
      await tester.pump();
      final Rect swiped = layerInBlock(tester);
      expect(swiped.left, isNot(paged.left));
      expect(swiped.top, paged.top);
    });

    testWidgets('leaves the zoom to the scrollable followed', (
      WidgetTester tester,
    ) async {
      await pumpCross(tester, zoom: const ZoomProperties(0.5));
      page(tester).jumpTo(300);
      await tester.pump();
      final double before = layerInBlock(tester).width;

      page(tester).jumpTo(500);
      await tester.pump();
      expect(layerInBlock(tester).width, before);

      carousel(tester).jumpTo(100);
      await tester.pump();
      expect(layerInBlock(tester).width, isNot(before));
    });

    testWidgets('stays one axis without it', (WidgetTester tester) async {
      await pumpCross(tester, crossParallax: null);
      page(tester).jumpTo(300);
      await tester.pump();
      final Rect before = layerInBlock(tester);

      expect(before.size, const Size(600, 300));
      page(tester).jumpTo(500);
      await tester.pump();
      expect(layerInBlock(tester), before);
    });

    testWidgets('does nothing with no scrollable the other way', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          ListView(
            scrollDirection: Axis.horizontal,
            children: const <Widget>[
              SimpleParallaxItem(
                background: _layer,
                width: 400,
                crossParallax: ParallaxProperties(),
              ),
              SizedBox(width: 2000),
            ],
          ),
        ),
      );

      // The page itself does not scroll, so only the list's axis is drawn
      // larger.
      expect(tester.getSize(find.byKey(_layerKey)), const Size(600, 600));
    });

    testWidgets('holds still on both axes under reduced motion', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          _reducedMotion(
            ListView(
              children: <Widget>[
                const SizedBox(height: 600),
                SizedBox(
                  height: 300,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: const <Widget>[
                      SimpleParallaxItem(
                        background: _layer,
                        width: 400,
                        crossParallax: ParallaxProperties(),
                      ),
                      SizedBox(width: 2000),
                    ],
                  ),
                ),
                const SizedBox(height: 1400),
              ],
            ),
          ),
        ),
      );
      page(tester).jumpTo(300);
      await tester.pump();
      final Rect before = layerInBlock(tester);

      // Centred on both axes.
      expect(before, const Rect.fromLTWH(-100, -75, 600, 450));

      page(tester).jumpTo(500);
      carousel(tester).jumpTo(100);
      await tester.pump();
      expect(layerInBlock(tester), before);
    });

    testWidgets('decodes the image for both overscans', (
      WidgetTester tester,
    ) async {
      await pumpCross(tester, image: _image);
      page(tester).jumpTo(300);
      await tester.pump();

      // 600 by 450 on a screen of 3, rounded up to 64.
      final DisplaySizeImage image =
          tester.widget<Image>(find.byType(Image)).image as DisplaySizeImage;
      expect(image.size, const Size(1856, 1408));
    });
  });

  group('an image on its way', () {
    const Color placeholder = Color(0xFFB00020);

    /// A picture the cache has never seen, so it loads rather than being drawn
    /// at once.
    ImageProvider fresh() => MemoryImage(Uint8List.fromList(_pixel));

    final Finder placeholderBox = find.byWidgetPredicate(
      (Widget widget) => widget is ColoredBox && widget.color == placeholder,
    );

    Future<void> pumpBlock(
      WidgetTester tester,
      ImageProvider image, {
      Duration fadeIn = Duration.zero,
      ImageErrorWidgetBuilder? errorBuilder,
      bool reduced = false,
      Key? key,
    }) {
      final Widget list = ListView(
        children: <Widget>[
          SimpleParallaxItem(
            key: key,
            image: image,
            height: 300,
            placeholderColor: placeholder,
            fadeIn: fadeIn,
            errorBuilder: errorBuilder,
          ),
        ],
      );
      return tester.pumpWidget(_app(reduced ? _reducedMotion(list) : list));
    }

    /// Lets the decode that started finish.
    Future<void> decode(WidgetTester tester) async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
    }

    testWidgets('shows the placeholder until the picture is ready', (
      WidgetTester tester,
    ) async {
      await pumpBlock(tester, fresh());
      expect(placeholderBox, findsOneWidget);

      await decode(tester);
      expect(placeholderBox, findsNothing);
    });

    testWidgets('fades the picture in over the placeholder', (
      WidgetTester tester,
    ) async {
      await pumpBlock(
        tester,
        fresh(),
        fadeIn: const Duration(milliseconds: 300),
      );
      expect(
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        0,
      );

      await decode(tester);
      expect(
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        1,
      );
      expect(placeholderBox, findsOneWidget);

      // Once in, nothing is left of the fade or of the placeholder.
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      expect(find.byType(AnimatedOpacity), findsNothing);
      expect(placeholderBox, findsNothing);
    });

    testWidgets('skips the fade under reduced motion', (
      WidgetTester tester,
    ) async {
      await pumpBlock(
        tester,
        fresh(),
        fadeIn: const Duration(milliseconds: 300),
        reduced: true,
      );
      expect(find.byType(AnimatedOpacity), findsNothing);
      expect(placeholderBox, findsOneWidget);

      await decode(tester);
      expect(placeholderBox, findsNothing);
    });

    testWidgets('draws a picture the cache holds at once', (
      WidgetTester tester,
    ) async {
      final ImageProvider image = fresh();
      await pumpBlock(tester, image, key: const ValueKey<int>(1));
      await decode(tester);

      await pumpBlock(
        tester,
        image,
        fadeIn: const Duration(milliseconds: 300),
        key: const ValueKey<int>(2),
      );
      expect(placeholderBox, findsNothing);
      expect(find.byType(AnimatedOpacity), findsNothing);
    });

    testWidgets('puts what errorBuilder gives in place of a broken picture', (
      WidgetTester tester,
    ) async {
      await pumpBlock(
        tester,
        MemoryImage(Uint8List.fromList(<int>[0, 1, 2, 3])),
        errorBuilder: (BuildContext context, Object error, StackTrace? stack) =>
            const Text('Broken'),
      );

      await decode(tester);
      expect(find.text('Broken'), findsOneWidget);
    });

    testWidgets('does the same for a container', (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          SimpleParallaxContainer(
            image: fresh(),
            placeholderColor: placeholder,
            child: Column(children: _tall()),
          ),
        ),
      );
      expect(placeholderBox, findsOneWidget);

      await decode(tester);
      expect(placeholderBox, findsNothing);
    });
  });

  group('a layer resized in place', () {
    testWidgets('follows a container to a new overscan', (
      WidgetTester tester,
    ) async {
      Widget page(double overscan) => _app(
            SimpleParallaxContainer(
              background: _layer,
              parallax: ParallaxProperties(overscan: overscan),
              child: Column(children: _tall()),
            ),
          );

      await tester.pumpWidget(page(1.5));
      expect(tester.getSize(find.byKey(_layerKey)), const Size(800, 900));

      await tester.pumpWidget(page(2));
      expect(tester.getSize(find.byKey(_layerKey)), const Size(800, 1200));
    });

    testWidgets('follows a container turned sideways', (
      WidgetTester tester,
    ) async {
      Widget page(Axis axis) => _app(
            SimpleParallaxContainer(
              background: _layer,
              scrollDirection: axis,
              parallax: const ParallaxProperties(overscan: 1.5),
              child: Flex(direction: axis, children: _tall()),
            ),
          );

      await tester.pumpWidget(page(Axis.vertical));
      expect(tester.getSize(find.byKey(_layerKey)), const Size(800, 900));

      await tester.pumpWidget(page(Axis.horizontal));
      expect(tester.getSize(find.byKey(_layerKey)), const Size(1200, 600));
    });

    testWidgets('follows an item to a new overscan', (
      WidgetTester tester,
    ) async {
      Widget page(double overscan) => _app(
            ListView(
              children: <Widget>[
                SimpleParallaxItem(
                  background: _layer,
                  height: 200,
                  parallax: ParallaxProperties(overscan: overscan),
                ),
              ],
            ),
          );

      await tester.pumpWidget(page(1.5));
      expect(tester.getSize(find.byKey(_layerKey)), const Size(800, 300));

      await tester.pumpWidget(page(2));
      expect(tester.getSize(find.byKey(_layerKey)), const Size(800, 400));
    });

    testWidgets('follows an item given a drift across', (
      WidgetTester tester,
    ) async {
      Widget page(ParallaxProperties? cross) => _app(
            ListView(
              children: <Widget>[
                SizedBox(
                  height: 300,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: <Widget>[
                      SimpleParallaxItem(
                        background: _layer,
                        width: 400,
                        crossParallax: cross,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );

      await tester.pumpWidget(page(null));
      expect(tester.getSize(find.byKey(_layerKey)), const Size(600, 300));

      await tester.pumpWidget(page(const ParallaxProperties()));
      expect(tester.getSize(find.byKey(_layerKey)), const Size(600, 450));
    });
  });
}
