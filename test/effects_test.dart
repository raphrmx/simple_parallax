import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_parallax/simple_parallax.dart';
// Not exported: the overlay is an implementation detail the
// tests reach for to find what the widgets drew.
import 'package:simple_parallax/src/overlay_layer.dart';

import 'helpers.dart';

void main() {
  group('the zoom', () {
    testWidgets('leaves the background at rest untouched', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        app(
          SimpleParallaxContainer(
            background: testLayer,
            zoom: const ZoomProperties(0.5),
            parallax: const ParallaxProperties(speed: 0.3, overscan: 2),
            child: Column(children: tallList()),
          ),
        ),
      );

      // Painted and laid out agree only while the scale is 1.
      expect(
        tester.getRect(find.byKey(layerKey)).height,
        tester.getSize(find.byKey(layerKey)).height,
      );
    });

    testWidgets('grows the background across the scroll in container mode', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        app(
          SimpleParallaxContainer(
            background: testLayer,
            zoom: const ZoomProperties(0.5),
            parallax: const ParallaxProperties(speed: 0.3, overscan: 2),
            child: Column(children: tallList()),
          ),
        ),
      );

      final double atRest = tester.getRect(find.byKey(layerKey)).height;
      final ScrollPosition position = scrollPosition(tester);
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();

      expect(
        tester.getRect(find.byKey(layerKey)).height / atRest,
        moreOrLessEquals(1.5, epsilon: 0.01),
      );
    });

    testWidgets('leaves the background alone when it is off', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        app(
          SimpleParallaxContainer(
            background: testLayer,
            parallax: const ParallaxProperties(speed: 0.3, overscan: 2),
            child: Column(children: tallList()),
          ),
        ),
      );

      final double atRest = tester.getRect(find.byKey(layerKey)).height;
      final ScrollPosition position = scrollPosition(tester);
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();

      expect(tester.getRect(find.byKey(layerKey)).height, atRest);
    });

    testWidgets('scales the painting and not the layout', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        app(
          SimpleParallaxContainer(
            background: testLayer,
            zoom: const ZoomProperties(0.5),
            parallax: const ParallaxProperties(speed: 0.3, overscan: 2),
            child: Column(children: tallList()),
          ),
        ),
      );

      final double laidOut = tester.getSize(find.byKey(layerKey)).height;
      final ScrollPosition position = scrollPosition(tester);
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();

      expect(tester.getSize(find.byKey(layerKey)).height, laidOut);
      expect(
        tester.getRect(find.byKey(layerKey)).height,
        greaterThan(laidOut),
      );
    });

    testWidgets('grows a block background as the block crosses', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        app(
          ListView(
            children: const <Widget>[
              SizedBox(height: 700),
              SimpleParallaxItem(
                background: testLayer,
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
      final double entering = tester.getRect(find.byKey(layerKey)).height;

      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pump();
      final double leaving = tester.getRect(find.byKey(layerKey)).height;

      expect(leaving, greaterThan(entering));
    });

    testWidgets('read backwards, a negative zoom starts enlarged', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        app(
          SimpleParallaxContainer(
            background: testLayer,
            zoom: const ZoomProperties(-0.5),
            parallax: const ParallaxProperties(speed: 0.3, overscan: 2),
            child: Column(children: tallList()),
          ),
        ),
      );

      final double laidOut = tester.getSize(find.byKey(layerKey)).height;
      expect(
        tester.getRect(find.byKey(layerKey)).height / laidOut,
        moreOrLessEquals(1.5, epsilon: 0.01),
      );

      final ScrollPosition position = scrollPosition(tester);
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();

      expect(
        tester.getRect(find.byKey(layerKey)).height,
        moreOrLessEquals(laidOut, epsilon: 0.01),
      );
    });

    testWidgets('never scales the background below 1', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        app(
          SimpleParallaxContainer(
            background: testLayer,
            zoom: const ZoomProperties(-0.5),
            parallax: const ParallaxProperties(speed: 0.3, overscan: 2),
            child: Column(children: tallList()),
          ),
        ),
      );

      final double laidOut = tester.getSize(find.byKey(layerKey)).height;
      final ScrollPosition position = scrollPosition(tester);

      for (final double at in <double>[0, 0.25, 0.5, 0.75, 1]) {
        position.jumpTo(position.maxScrollExtent * at);
        await tester.pump();
        expect(
          tester.getRect(find.byKey(layerKey)).height,
          greaterThanOrEqualTo(laidOut - 0.01),
        );
      }
    });
  });

  group('a block that is on its way in', () {
    /// How far the background sits inside the block, which is what the drift
    /// and the zoom both move.
    double inside(WidgetTester tester) =>
        tester.getRect(find.byKey(layerKey)).top -
        tester.getRect(find.byType(SimpleParallaxItem)).top;

    Future<void> pumpBlock(WidgetTester tester) async {
      await tester.pumpWidget(
        app(
          ListView(
            children: const <Widget>[
              SizedBox(height: 600),
              SimpleParallaxItem(
                background: testLayer,
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
      final ScrollPosition position = scrollPosition(tester);

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
      final ScrollPosition position = scrollPosition(tester);

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
        app(
          SimpleParallaxContainer(
            background: testLayer,
            child: Column(children: tallList()),
          ),
        ),
      );

      expect(blurFilter(tester), isNull);
    });

    testWidgets('sharpens into a blur down the page', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        app(
          SimpleParallaxContainer(
            background: testLayer,
            blur: const BlurProperties(12),
            child: Column(children: tallList()),
          ),
        ),
      );

      expect(blurFilter(tester), isNull);

      // 2000 of content in a 600 viewport, so the end of the travel.
      scrollPosition(tester).jumpTo(1400);
      await tester.pump();

      expect(blurFilter(tester), blurOf(12));
    });

    testWidgets('read backwards, a negative blur starts blurred', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        app(
          SimpleParallaxContainer(
            background: testLayer,
            blur: const BlurProperties(-12),
            child: Column(children: tallList()),
          ),
        ),
      );

      expect(blurFilter(tester), blurOf(12));

      scrollPosition(tester).jumpTo(1400);
      await tester.pump();

      expect(blurFilter(tester), isNull);
    });

    testWidgets('holds the filter through a change no one can see', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        app(
          SimpleParallaxContainer(
            background: testLayer,
            blur: const BlurProperties(12),
            child: Column(children: tallList()),
          ),
        ),
      );

      scrollPosition(tester).jumpTo(700);
      await tester.pump();

      // A single pixel is under a hundredth of a sigma here.
      scrollPosition(tester).jumpTo(701);
      await tester.pump();

      expect(blurFilter(tester), blurOf(6));
    });

    /// A block of 400 below a screenful, so it crosses a 600 viewport over
    /// 1000 of scrolling.
    Future<void> pumpBlock(WidgetTester tester, double blur) async {
      await tester.pumpWidget(
        app(
          ListView(
            children: <Widget>[
              const SizedBox(height: 600),
              SimpleParallaxItem(
                background: testLayer,
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
      scrollPosition(tester).jumpTo(250);
      await tester.pump();

      expect(blurFilter(tester), blurOf(5));

      scrollPosition(tester).jumpTo(750);
      await tester.pump();

      expect(blurFilter(tester), blurOf(15));
    });

    testWidgets('read backwards, a block clears as it crosses', (
      WidgetTester tester,
    ) async {
      await pumpBlock(tester, -20);

      scrollPosition(tester).jumpTo(250);
      await tester.pump();

      expect(blurFilter(tester), blurOf(15));

      scrollPosition(tester).jumpTo(750);
      await tester.pump();

      expect(blurFilter(tester), blurOf(5));
    });

    testWidgets('reads a block on the frame it is drawn', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        app(
          ListView(
            children: const <Widget>[
              SimpleParallaxItem(
                background: testLayer,
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
      expect(blurFilter(tester), blurOf(6));
    });
  });

  group('an effect that stops part way', () {
    testWidgets('holds the zoom from halfway down the page', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        app(
          SimpleParallaxContainer(
            background: testLayer,
            zoom: const ZoomProperties(0.5, reach: 0.5),
            parallax: const ParallaxProperties(overscan: 2),
            child: Column(children: tallList()),
          ),
        ),
      );

      double height(WidgetTester tester) =>
          tester.getRect(find.byKey(layerKey)).height;

      final double atRest = height(tester);

      // 2000 of content in a 600 viewport, so halfway and the end.
      scrollPosition(tester).jumpTo(700);
      await tester.pump();

      expect(height(tester) / atRest, moreOrLessEquals(1.5, epsilon: 0.01));

      scrollPosition(tester).jumpTo(1400);
      await tester.pump();

      expect(height(tester) / atRest, moreOrLessEquals(1.5, epsilon: 0.01));
    });

    testWidgets('holds a block blur once it is reached', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        app(
          ListView(
            children: const <Widget>[
              SizedBox(height: 600),
              SimpleParallaxItem(
                background: testLayer,
                height: 400,
                blur: BlurProperties(20, reach: 0.5),
              ),
              SizedBox(height: 1400),
            ],
          ),
        ),
      );

      // A quarter, a half and three quarters of a 600 + 400 crossing.
      scrollPosition(tester).jumpTo(250);
      await tester.pump();

      expect(blurFilter(tester), blurOf(10));

      scrollPosition(tester).jumpTo(500);
      await tester.pump();

      expect(blurFilter(tester), blurOf(20));

      scrollPosition(tester).jumpTo(750);
      await tester.pump();

      expect(blurFilter(tester), blurOf(20));
    });

    testWidgets('takes the zoom out and back down the page', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        app(
          SimpleParallaxContainer(
            background: testLayer,
            zoom: const ZoomProperties(0.5, reach: 0.5, back: true),
            parallax: const ParallaxProperties(overscan: 2),
            child: Column(children: tallList()),
          ),
        ),
      );

      double height(WidgetTester tester) =>
          tester.getRect(find.byKey(layerKey)).height;

      final double atRest = height(tester);

      // 2000 of content in a 600 viewport, so halfway and the end.
      scrollPosition(tester).jumpTo(700);
      await tester.pump();

      expect(height(tester) / atRest, moreOrLessEquals(1.5, epsilon: 0.01));

      scrollPosition(tester).jumpTo(1400);
      await tester.pump();

      expect(height(tester) / atRest, moreOrLessEquals(1, epsilon: 0.01));
    });

    testWidgets('clears the blur halfway and lets it back', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        app(
          SimpleParallaxContainer(
            background: testLayer,
            blur: const BlurProperties(-16, reach: 0.5, back: true),
            child: Column(children: tallList()),
          ),
        ),
      );

      expect(blurFilter(tester), blurOf(16));

      scrollPosition(tester).jumpTo(700);
      await tester.pump();

      expect(blurFilter(tester), isNull);

      scrollPosition(tester).jumpTo(1400);
      await tester.pump();

      expect(blurFilter(tester), blurOf(16));
    });

    testWidgets('reads the same either side of a block', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        app(
          ListView(
            children: const <Widget>[
              SizedBox(height: 600),
              SimpleParallaxItem(
                background: testLayer,
                height: 400,
                blur: BlurProperties(20, reach: 0.5, back: true),
              ),
              SizedBox(height: 1400),
            ],
          ),
        ),
      );

      // A quarter, a half and three quarters of a 600 + 400 crossing.
      scrollPosition(tester).jumpTo(250);
      await tester.pump();

      expect(blurFilter(tester), blurOf(10));

      scrollPosition(tester).jumpTo(500);
      await tester.pump();

      expect(blurFilter(tester), blurOf(20));

      scrollPosition(tester).jumpTo(750);
      await tester.pump();

      expect(blurFilter(tester), blurOf(10));
    });

    testWidgets('takes a block zoom out and back', (WidgetTester tester) async {
      await tester.pumpWidget(
        app(
          ListView(
            children: const <Widget>[
              SizedBox(height: 600),
              SimpleParallaxItem(
                background: testLayer,
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
          tester.getRect(find.byKey(layerKey)).height;

      scrollPosition(tester).jumpTo(250);
      await tester.pump();
      final double quarter = height(tester);

      scrollPosition(tester).jumpTo(500);
      await tester.pump();

      expect(height(tester), greaterThan(quarter));

      scrollPosition(tester).jumpTo(750);
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
        from - tester.getTopLeft(find.byKey(layerKey)).dy;

    Future<void> pumpPage(WidgetTester tester, double speed) async {
      await tester.pumpWidget(
        app(
          SimpleParallaxContainer(
            background: testLayer,
            parallax: ParallaxProperties(speed: speed, overscan: 2),
            child: Column(children: tallList()),
          ),
        ),
      );
    }

    testWidgets('spends exactly its travel over the whole scroll', (
      WidgetTester tester,
    ) async {
      await pumpPage(tester, 1);
      final double atRest = tester.getTopLeft(find.byKey(layerKey)).dy;

      final ScrollPosition position = scrollPosition(tester);
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();

      // An overscan of 2 over a 600 viewport is 600 of travel.
      expect(moved(tester, atRest), moreOrLessEquals(600, epsilon: 0.01));
    });

    testWidgets('spends the fraction it is given and no more', (
      WidgetTester tester,
    ) async {
      await pumpPage(tester, 0.5);
      final double atRest = tester.getTopLeft(find.byKey(layerKey)).dy;

      final ScrollPosition position = scrollPosition(tester);
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();

      expect(moved(tester, atRest), moreOrLessEquals(300, epsilon: 0.01));
    });

    testWidgets('pins the background at zero', (WidgetTester tester) async {
      await pumpPage(tester, 0);
      final double atRest = tester.getTopLeft(find.byKey(layerKey)).dy;

      final ScrollPosition position = scrollPosition(tester);
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
        app(
          SimpleParallaxContainer(
            background: testLayer,
            child: Column(children: tallList()),
          ),
        ),
      );

      expect(find.byType(OverlayLayer), findsNothing);
    });

    testWidgets('darkens the page at the opacity it is given', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        app(
          SimpleParallaxContainer(
            background: testLayer,
            overlay: const OverlayProperties.darken(0.4),
            child: Column(children: tallList()),
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
        app(
          SimpleParallaxContainer(
            background: testLayer,
            overlay: const OverlayProperties.lighten(0.2),
            child: Column(children: tallList()),
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
        app(
          ListView(
            children: const <Widget>[
              SimpleParallaxItem(
                background: testLayer,
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
        app(
          ListView(
            children: const <Widget>[
              SimpleParallaxItem(
                background: testLayer,
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
        app(
          SimpleParallaxContainer(
            background: testLayer,
            overlay: const OverlayProperties.darken(0.3),
            child: Column(children: tallList()),
          ),
        ),
      );

      final Rect before = tester.getRect(find.byType(OverlayLayer));
      final double layerBefore = tester.getTopLeft(find.byKey(layerKey)).dy;

      final ScrollPosition position = scrollPosition(tester);
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();

      expect(
        tester.getTopLeft(find.byKey(layerKey)).dy,
        lessThan(layerBefore),
      );
      expect(tester.getRect(find.byType(OverlayLayer)), before);
    });
  });
}
