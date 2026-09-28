import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_parallax/simple_parallax.dart';

import 'helpers.dart';

void main() {
  group('SimpleParallaxItem', () {
    testWidgets('renders inside any scrollable', (WidgetTester tester) async {
      await tester.pumpWidget(
        app(
          ListView(
            children: <Widget>[
              SimpleParallaxItem(
                image: testImage,
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
        app(SimpleParallaxItem(image: testImage, height: 200)),
      );

      expect(find.byType(Flow), findsNothing);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('slides sideways inside a horizontal scrollable', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        app(
          ListView(
            scrollDirection: Axis.horizontal,
            children: <Widget>[
              const SizedBox(width: 600),
              SimpleParallaxItem(
                image: testImage,
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
        app(
          ListView(
            children: <Widget>[
              SimpleParallaxItem(image: testImage, height: 200),
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
          app(
            ListView(
              children: <Widget>[
                const SizedBox(height: 600),
                SizedBox(
                  height: 300,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: <Widget>[
                      SimpleParallaxItem(
                        background: testLayer,
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
        tester.getTopLeft(find.byKey(layerKey)) -
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
      expect(tester.getSize(find.byKey(layerKey)), const Size(400, 450));

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
        app(
          ListView(
            scrollDirection: Axis.horizontal,
            children: const <Widget>[
              SimpleParallaxItem(
                background: testLayer,
                width: 400,
                scrollAxis: Axis.vertical,
              ),
              SizedBox(width: 2000),
            ],
          ),
        ),
      );
      final Offset before = layerInBlock(tester);

      scrollPosition(tester).jumpTo(100);
      await tester.pump();

      expect(layerInBlock(tester), before);
    });

    test('rejects a speed outside 0..1', () {
      expect(() => ParallaxProperties(speed: 2), throwsAssertionError);
    });
  });

  group('the item frame', () {
    testWidgets('aligns its image as it is told', (WidgetTester tester) async {
      await tester.pumpWidget(
        app(
          ListView(
            children: <Widget>[
              SimpleParallaxItem(
                image: testImage,
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
        app(
          ListView(
            children: <Widget>[
              SimpleParallaxItem(
                background: testLayer,
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
        app(
          ListView(
            children: const <Widget>[
              SimpleParallaxItem(background: testLayer, height: 200),
            ],
          ),
        ),
      );

      expect(find.byType(ClipRRect), findsNothing);
    });
  });

  group('a widget background', () {
    testWidgets('replaces the image in container mode', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        app(
          SimpleParallaxContainer(
            background: testLayer,
            child: Column(
              children: List<Widget>.generate(
                10,
                (int i) => SizedBox(height: 100, child: Text('Item $i')),
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(layerKey), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      expect(find.text('Item 0'), findsOneWidget);
    });

    testWidgets('moves as the content scrolls in container mode', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        app(
          SimpleParallaxContainer(
            background: testLayer,
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

      Offset layerTopLeft() => tester.getTopLeft(find.byKey(layerKey));

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
        app(
          SimpleParallaxContainer.slivers(
            background: testLayer,
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

      expect(find.byKey(layerKey), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      expect(built, lessThan(50));
    });

    testWidgets('slides sideways in item mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        app(
          ListView(
            scrollDirection: Axis.horizontal,
            children: const <Widget>[
              SizedBox(width: 600),
              SimpleParallaxItem(
                background: testLayer,
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

      Offset layerTopLeft() => tester.getTopLeft(find.byKey(layerKey));

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
        app(const SimpleParallaxItem(background: testLayer, height: 200)),
      );

      expect(find.byType(Flow), findsNothing);
      expect(find.byKey(layerKey), findsOneWidget);
    });

    test('rejects an item given neither an image nor a background', () {
      expect(() => SimpleParallaxItem(height: 200), throwsAssertionError);
    });

    test('rejects an item given both', () {
      expect(
        () => SimpleParallaxItem(image: testImage, background: testLayer),
        throwsAssertionError,
      );
    });

    test('rejects a container given both', () {
      expect(
        () => SimpleParallaxContainer(
          image: testImage,
          background: testLayer,
          child: const SizedBox(),
        ),
        throwsAssertionError,
      );
    });
  });
}
