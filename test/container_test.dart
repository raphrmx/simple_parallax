import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_parallax/simple_parallax.dart';

import 'helpers.dart';

void main() {
  group('SimpleParallaxContainer', () {
    testWidgets('renders its child and a background',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        app(
          SimpleParallaxContainer(
            image: testImage,
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
        app(
          SimpleParallaxContainer.slivers(
            image: testImage,
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
        app(
          SimpleParallaxContainer.slivers(
            image: testImage,
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
        app(
          SimpleParallaxContainer.slivers(
            image: testImage,
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
        app(
          SimpleParallaxContainer(
            image: testImage,
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
        app(
          SimpleParallaxContainer(
            image: testImage,
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
        app(
          SimpleParallaxContainer(
            image: testImage,
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
        app(
          SimpleParallaxContainer(
            background: testLayer,
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

      final Offset before = tester.getTopLeft(find.byKey(layerKey));
      await tester.drag(find.text('Nested 0'), const Offset(0, -150));
      await tester.pump();

      expect(tester.getTopLeft(find.byKey(layerKey)), before);
    });

    testWidgets('follows content that grows without being scrolled', (
      WidgetTester tester,
    ) async {
      Widget page(int count) => app(
            SimpleParallaxContainer(
              background: testLayer,
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
      final ScrollPosition position = scrollPosition(tester);
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();
      final double atEnd = tester.getTopLeft(find.byKey(layerKey)).dy;

      // Twice the content with the view where it was: no longer at the end, so
      // the background has to come back part of the way.
      await tester.pumpWidget(page(40));
      await tester.pump();

      expect(tester.getTopLeft(find.byKey(layerKey)).dy, greaterThan(atEnd));
    });

    testWidgets('takes a new speed without waiting for a scroll', (
      WidgetTester tester,
    ) async {
      Widget page(double speed) => app(
            SimpleParallaxContainer(
              background: testLayer,
              parallax: ParallaxProperties(speed: speed, overscan: 2),
              child: Column(children: tallList()),
            ),
          );

      await tester.pumpWidget(page(1));
      final double atRest = tester.getTopLeft(find.byKey(layerKey)).dy;
      final ScrollPosition position = scrollPosition(tester);
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();

      await tester.pumpWidget(page(0.5));

      // Half of the 600 of travel an overscan of 2 gives a 600 viewport.
      expect(
        atRest - tester.getTopLeft(find.byKey(layerKey)).dy,
        moreOrLessEquals(300, epsilon: 0.01),
      );
    });

    testWidgets('follows a controller it is given', (
      WidgetTester tester,
    ) async {
      final ScrollController controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        app(
          SimpleParallaxContainer(
            background: testLayer,
            controller: controller,
            parallax: const ParallaxProperties(overscan: 2),
            child: Column(children: tallList()),
          ),
        ),
      );

      final double atRest = tester.getTopLeft(find.byKey(layerKey)).dy;
      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pump();

      expect(
        atRest - tester.getTopLeft(find.byKey(layerKey)).dy,
        moreOrLessEquals(600, epsilon: 0.01),
      );
    });

    test('stands the smooth wheel down for a controller', () {
      final SimpleParallaxContainer container = SimpleParallaxContainer(
        background: testLayer,
        controller: ScrollController(),
        child: const SizedBox(),
      );

      expect(container.smooth, isFalse);
      expect(
        () => SimpleParallaxContainer(
          background: testLayer,
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
        app(
          SimpleParallaxContainer(
            background: testLayer,
            physics: const NeverScrollableScrollPhysics(),
            child: Column(children: tallList()),
          ),
        ),
      );

      await tester.drag(find.text('Item 0'), const Offset(0, -300));
      await tester.pump();

      expect(scrollPosition(tester).pixels, 0);
    });

    testWidgets('lets a scroll notification keep bubbling', (
      WidgetTester tester,
    ) async {
      int seenByAncestor = 0;

      await tester.pumpWidget(
        app(
          NotificationListener<ScrollUpdateNotification>(
            onNotification: (_) {
              seenByAncestor++;
              return false;
            },
            child: SimpleParallaxContainer(
              image: testImage,
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
        app(
          SimpleParallaxContainer(
            image: testImage,
            child: const SizedBox(height: 2000),
          ),
        ),
      );
      await tester.pumpWidget(app(const SizedBox()));

      expect(tester.takeException(), isNull);
    });
  });
}
