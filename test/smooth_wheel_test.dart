import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_parallax/simple_parallax.dart';

import 'helpers.dart';

void main() {
  group('the smooth wheel', () {
    testWidgets('eases a notch in instead of landing it at once', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        app(SimpleParallaxWidget(smooth: true, children: tallList())),
      );

      await sendWheel(tester, const Offset(0, 120));
      await tester.pump();
      expect(scrollPosition(tester).pixels, lessThan(120));

      await tester.pumpAndSettle();
      expect(scrollPosition(tester).pixels, 120);
    });

    testWidgets('lands the notch on one frame without it', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        app(SimpleParallaxWidget(smooth: false, children: tallList())),
      );

      await sendWheel(tester, const Offset(0, 120));
      await tester.pump();

      expect(scrollPosition(tester).pixels, 120);
    });

    testWidgets('adds up the notches of a wheel turned quickly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        app(SimpleParallaxWidget(smooth: true, children: tallList())),
      );

      await sendWheel(tester, const Offset(0, 120));
      await tester.pump(const Duration(milliseconds: 40));
      await sendWheel(tester, const Offset(0, 120));
      await tester.pumpAndSettle();

      expect(scrollPosition(tester).pixels, 240);
    });

    testWidgets('brings a vertical wheel to a horizontal view', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        app(
          SimpleParallaxWidget(
            scrollDirection: Axis.horizontal,
            smooth: true,
            children: wideList(),
          ),
        ),
      );

      await sendWheel(tester, const Offset(0, 120));
      await tester.pumpAndSettle();

      expect(scrollPosition(tester).pixels, 120);
    });

    testWidgets('a horizontal view ignores that wheel without it', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        app(
          SimpleParallaxWidget(
            smooth: false,
            scrollDirection: Axis.horizontal,
            children: wideList(),
          ),
        ),
      );

      await sendWheel(tester, const Offset(0, 120));
      await tester.pumpAndSettle();

      expect(scrollPosition(tester).pixels, 0);
    });

    testWidgets('lands a notch at once under reduced motion', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        app(
          reducedMotion(
            SimpleParallaxWidget(smooth: true, children: tallList()),
          ),
        ),
      );

      await sendWheel(tester, const Offset(0, 120));
      await tester.pump();

      expect(scrollPosition(tester).pixels, 120);
    });

    testWidgets('still brings the wheel sideways under reduced motion', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        app(
          reducedMotion(
            SimpleParallaxWidget(
              scrollDirection: Axis.horizontal,
              smooth: true,
              children: wideList(),
            ),
          ),
        ),
      );

      await sendWheel(tester, const Offset(0, 120));
      await tester.pump();

      expect(scrollPosition(tester).pixels, 120);
    });

    testWidgets(
      'eases a container wheel told to ignore reduced motion',
      (
        WidgetTester tester,
      ) async {
        Widget page({required bool respect}) => app(
              reducedMotion(
                SimpleParallaxContainer(
                  background: testLayer,
                  respectReducedMotion: respect,
                  child: Column(children: tallList()),
                ),
              ),
            );

        await tester.pumpWidget(page(respect: true));
        await sendWheel(tester, const Offset(0, 120));
        await tester.pump();
        expect(scrollPosition(tester).pixels, 120);

        await tester.pumpWidget(page(respect: false));
        await sendWheel(tester, const Offset(0, 120));
        await tester.pump();
        expect(scrollPosition(tester).pixels, lessThan(240));

        await tester.pumpAndSettle();
        expect(scrollPosition(tester).pixels, 240);
      },
      variant: onDesktop,
    );

    testWidgets('hands the wheel to the page once a horizontal view is done', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        app(
          ListView(
            children: <Widget>[
              SizedBox(
                height: 200,
                child: SimpleParallaxWidget(
                  scrollDirection: Axis.horizontal,
                  smooth: true,
                  children: wideList(),
                ),
              ),
              ...tallList(),
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
        app(
          SimpleParallaxContainer(
            background: testLayer,
            smooth: true,
            parallax: const ParallaxProperties(speed: 0.5, overscan: 2),
            child: Column(children: tallList()),
          ),
        ),
      );

      final Offset before = tester.getTopLeft(find.byKey(layerKey));
      await sendWheel(tester, const Offset(0, 300));
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(find.byKey(layerKey)).dy, lessThan(before.dy));
    });

    testWidgets(
      'keeps easing a container on a SmoothScrollController',
      (
        WidgetTester tester,
      ) async {
        final SmoothScrollController controller = SmoothScrollController();
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

        await sendWheel(tester, const Offset(0, 120));
        await tester.pump();
        expect(controller.offset, lessThan(120));
        await tester.pumpAndSettle();
        expect(controller.offset, 120);

        // Driven from outside as well, background included.
        final double before = tester.getTopLeft(find.byKey(layerKey)).dy;
        controller.jumpTo(controller.position.maxScrollExtent);
        await tester.pump();
        expect(tester.getTopLeft(find.byKey(layerKey)).dy, lessThan(before));
      },
      variant: onDesktop,
    );

    testWidgets('brings the wheel sideways on a SmoothScrollController', (
      WidgetTester tester,
    ) async {
      final SmoothScrollController controller = SmoothScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        app(
          SimpleParallaxWidget(
            scrollDirection: Axis.horizontal,
            controller: controller,
            children: wideList(),
          ),
        ),
      );

      await sendWheel(tester, const Offset(0, 120));
      await tester.pumpAndSettle();

      expect(controller.offset, 120);
    });

    testWidgets('leaves a SmoothScrollController it was given undisposed', (
      WidgetTester tester,
    ) async {
      final SmoothScrollController controller = SmoothScrollController();

      await tester.pumpWidget(
        app(
          SimpleParallaxContainer(
            background: testLayer,
            controller: controller,
            child: Column(children: tallList()),
          ),
        ),
      );
      await tester.pumpWidget(app(const SizedBox()));

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
          background: testLayer,
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
          app(
            SimpleParallaxContainer(
              background: testLayer,
              child: Column(children: tallList()),
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
        await sendWheel(tester, const Offset(0, 120));
        await tester.pump();
        expect(scrollPosition(tester).pixels, 120);
      },
      variant: TargetPlatformVariant(
        <TargetPlatform>{TargetPlatform.android, TargetPlatform.iOS},
      ),
    );

    testWidgets(
      'eases on a phone when asked to',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          app(
            SimpleParallaxWidget(smooth: true, children: tallList()),
          ),
        );

        await sendWheel(tester, const Offset(0, 120));
        await tester.pump();
        expect(scrollPosition(tester).pixels, lessThan(120));
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );

    testWidgets(
      'eases on a desktop by default',
      (WidgetTester tester) async {
        await tester
            .pumpWidget(app(SimpleParallaxWidget(children: tallList())));

        await sendWheel(tester, const Offset(0, 120));
        await tester.pump();
        expect(scrollPosition(tester).pixels, lessThan(120));
      },
      variant: onDesktop,
    );

    testWidgets(
      'keeps a container where it was as it is turned on and off',
      (
        WidgetTester tester,
      ) async {
        Widget page({required bool smooth}) => app(
              SimpleParallaxContainer(
                background: testLayer,
                smooth: smooth,
                child: Column(children: tallList()),
              ),
            );

        await tester.pumpWidget(page(smooth: true));
        scrollPosition(tester).jumpTo(300);
        await tester.pump();

        await tester.pumpWidget(page(smooth: false));
        expect(scrollPosition(tester).pixels, 300);

        await tester.pumpWidget(page(smooth: true));
        expect(scrollPosition(tester).pixels, 300);
      },
      variant: onDesktop,
    );

    testWidgets(
      'keeps a widget where it was as it is turned on and off',
      (
        WidgetTester tester,
      ) async {
        Widget page({required bool smooth}) =>
            app(SimpleParallaxWidget(smooth: smooth, children: tallList()));

        await tester.pumpWidget(page(smooth: true));
        scrollPosition(tester).jumpTo(300);
        await tester.pump();

        await tester.pumpWidget(page(smooth: false));
        expect(scrollPosition(tester).pixels, 300);

        await tester.pumpWidget(page(smooth: true));
        expect(scrollPosition(tester).pixels, 300);
      },
      variant: onDesktop,
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
}
