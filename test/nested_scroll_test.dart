import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_parallax/simple_parallax.dart';
import 'package:simple_parallax/src/display_size_image.dart';

import 'helpers.dart';

void main() {
  group('a scroll running the other way', () {
    testWidgets('drifts a right-to-left container with its content', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        app(
          Directionality(
            textDirection: TextDirection.rtl,
            child: SimpleParallaxContainer(
              background: testLayer,
              scrollDirection: Axis.horizontal,
              parallax: const ParallaxProperties(overscan: 2),
              child: Row(children: wideList()),
            ),
          ),
        ),
      );

      final double content = tester.getTopLeft(find.text('Item 0')).dx;
      final Rect atRest = tester.getRect(find.byKey(layerKey));
      // Starts against the right edge, the end the content comes from.
      expect(atRest.right, 800);

      scrollPosition(tester).jumpTo(400);
      await tester.pump();

      final double contentMoved =
          tester.getTopLeft(find.text('Item 0')).dx - content;
      final double backgroundMoved =
          tester.getTopLeft(find.byKey(layerKey)).dx - atRest.left;
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
          app(
            Directionality(
              textDirection: direction,
              child: ListView(
                scrollDirection: axis,
                reverse: reverse,
                children: const <Widget>[
                  SizedBox(width: 800, height: 600),
                  SimpleParallaxItem(
                    background: testLayer,
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
      scrollPosition(tester).jumpTo(scrolled);
      await tester.pump();
      return (
        tester.getRect(find.byType(SimpleParallaxItem)),
        tester.getRect(find.byKey(layerKey)),
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
                        image: image,
                        background: image == null ? testLayer : null,
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
        tester.getRect(find.byKey(layerKey)).shift(
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
        app(
          ListView(
            scrollDirection: Axis.horizontal,
            children: const <Widget>[
              SimpleParallaxItem(
                background: testLayer,
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
      expect(tester.getSize(find.byKey(layerKey)), const Size(600, 600));
    });

    testWidgets('holds still on both axes under reduced motion', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        app(
          reducedMotion(
            ListView(
              children: <Widget>[
                const SizedBox(height: 600),
                SizedBox(
                  height: 300,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: const <Widget>[
                      SimpleParallaxItem(
                        background: testLayer,
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
      await pumpCross(tester, image: testImage);
      page(tester).jumpTo(300);
      await tester.pump();

      // 600 by 450 on a screen of 3, rounded up to 64.
      final DisplaySizeImage image =
          tester.widget<Image>(find.byType(Image)).image as DisplaySizeImage;
      expect(image.size, const Size(1856, 1408));
    });
  });
}
