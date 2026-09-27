import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_parallax/simple_parallax.dart';
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
}
