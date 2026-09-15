import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_parallax/simple_parallax.dart';

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
      expect(
        () => SimpleParallaxContainer(
          image: _image,
          overscan: 0.5,
          child: const SizedBox(),
        ),
        throwsAssertionError,
      );
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
            speed: 0.5,
            overscan: 2,
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
            speed: 0.5,
            overscan: 2,
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
            speed: 0.5,
            overscan: 2,
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
            speed: 0.5,
            overscan: 2,
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
                overscan: 2,
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
      expect(
        () => SimpleParallaxItem(image: _image, speed: 2),
        throwsAssertionError,
      );
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
}
