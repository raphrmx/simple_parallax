import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_parallax/simple_parallax.dart';
import 'package:simple_parallax/src/display_size_image.dart';

import 'helpers.dart';

/// A page that owns a [TiltController] and hands it to [builder].
class _Host extends StatefulWidget {
  const _Host(this.builder, {this.response});

  final Widget Function(TiltController tilt) builder;
  final Duration? response;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> with SingleTickerProviderStateMixin {
  late final TiltController tilt = widget.response == null
      ? TiltController(vsync: this)
      : TiltController(vsync: this, response: widget.response!);

  @override
  void dispose() {
    tilt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(tilt);
}

/// The controller of the one [_Host] under test.
TiltController _controller(WidgetTester tester) =>
    tester.state<_HostState>(find.byType(_Host)).tilt;

void main() {
  group('the tilt controller', () {
    testWidgets('eases towards its aim and lands on it', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_Host((_) => const SizedBox()));
      final TiltController tilt = _controller(tester);

      tilt.aim(const Offset(1, -1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final Offset partway = tilt.value;
      expect(partway.dx, greaterThan(0));
      expect(partway.dx, lessThan(1));
      expect(partway.dy, -partway.dx);

      await tester.pumpAndSettle();
      expect(tilt.value, const Offset(1, -1));
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('clamps its aim to -1 and 1', (WidgetTester tester) async {
      await tester.pumpWidget(_Host((_) => const SizedBox()));
      final TiltController tilt = _controller(tester);

      tilt.aim(const Offset(3, -0.5));
      expect(tilt.target, const Offset(1, -0.5));
    });

    testWidgets('follows at once with no response time', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _Host((_) => const SizedBox(), response: Duration.zero),
      );
      final TiltController tilt = _controller(tester);

      tilt.aim(const Offset(0.5, 0.25));
      expect(tilt.value, const Offset(0.5, 0.25));
      expect(tester.binding.transientCallbackCount, 0);
    });
  });

  group('the pointer tilt', () {
    testWidgets('aims at the mouse and settles when it leaves', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _Host(
          (TiltController tilt) => Align(
            alignment: Alignment.topLeft,
            child: PointerTilt(
              controller: tilt,
              child: const SizedBox(width: 400, height: 200),
            ),
          ),
          response: Duration.zero,
        ),
      );
      final TiltController tilt = _controller(tester);

      final TestGesture mouse =
          await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: const Offset(200, 100));
      await tester.pump();
      expect(tilt.value, Offset.zero);

      await mouse.moveTo(const Offset(399, 150));
      await tester.pump();
      expect(tilt.value.dx, closeTo(1, 0.01));
      expect(tilt.value.dy, closeTo(0.5, 0.01));

      await mouse.moveTo(const Offset(600, 500));
      await tester.pump();
      expect(tilt.value, Offset.zero);
    });

    testWidgets('leaves touch alone', (WidgetTester tester) async {
      await tester.pumpWidget(
        _Host(
          (TiltController tilt) => PointerTilt(
            controller: tilt,
            child: const SizedBox.expand(),
          ),
          response: Duration.zero,
        ),
      );

      await tester.tapAt(const Offset(780, 580));
      await tester.pump();
      expect(_controller(tester).value, Offset.zero);
    });
  });

  group('a tilted item', () {
    /// A block of 200 at the middle of a list, leaning with [source].
    Future<void> pumpBlock(
      WidgetTester tester,
      ValueNotifier<Offset> source, {
      double distance = 20,
    }) =>
        tester.pumpWidget(
          app(
            ListView(
              children: <Widget>[
                const SizedBox(height: 200),
                SimpleParallaxItem(
                  background: testLayer,
                  height: 200,
                  tilt: TiltProperties(source, distance: distance),
                ),
                const SizedBox(height: 1200),
              ],
            ),
          ),
        );

    testWidgets('draws its layer larger on every side', (
      WidgetTester tester,
    ) async {
      final ValueNotifier<Offset> source = ValueNotifier<Offset>(Offset.zero);
      await pumpBlock(tester, source);

      final Rect block = tester.getRect(find.byType(SimpleParallaxItem));
      final Rect layer = tester.getRect(find.byKey(layerKey));
      expect(layer.width, block.width + 40);
      expect(layer.height, block.height * 1.5 + 40);
      // At rest the margin is shared evenly across the block.
      expect(layer.left, block.left - 20);
    });

    testWidgets('leans away from its source, up to the distance', (
      WidgetTester tester,
    ) async {
      final ValueNotifier<Offset> source = ValueNotifier<Offset>(Offset.zero);
      await pumpBlock(tester, source);
      final Rect atRest = tester.getRect(find.byKey(layerKey));

      source.value = const Offset(1, -1);
      await tester.pump();
      final Rect leaning = tester.getRect(find.byKey(layerKey));
      expect(leaning.left - atRest.left, -20);
      expect(leaning.top - atRest.top, 20);

      // Past the range is held at the distance.
      source.value = const Offset(-4, 0);
      await tester.pump();
      expect(tester.getRect(find.byKey(layerKey)).left - atRest.left, 20);
    });

    testWidgets('adds the lean to the drift', (WidgetTester tester) async {
      final ValueNotifier<Offset> source = ValueNotifier<Offset>(Offset.zero);
      await pumpBlock(tester, source);

      scrollPosition(tester).jumpTo(100);
      await tester.pump();
      final Rect drifted = tester.getRect(find.byKey(layerKey));

      source.value = const Offset(0, 1);
      await tester.pump();
      expect(tester.getRect(find.byKey(layerKey)).top - drifted.top, -20);
    });

    testWidgets('never shows past its layer at a full tilt', (
      WidgetTester tester,
    ) async {
      final ValueNotifier<Offset> source = ValueNotifier<Offset>(Offset.zero);
      await pumpBlock(tester, source);

      for (final double scrolled in <double>[0, 150, 300]) {
        scrollPosition(tester).jumpTo(scrolled);
        for (final Offset at in const <Offset>[
          Offset(1, 1),
          Offset(-1, -1),
          Offset(1, -1),
          Offset(-1, 1),
        ]) {
          source.value = at;
          await tester.pump();
          final Rect block = tester.getRect(find.byType(SimpleParallaxItem));
          final Rect layer = tester.getRect(find.byKey(layerKey));
          expect(layer.left, lessThanOrEqualTo(block.left));
          expect(layer.right, greaterThanOrEqualTo(block.right));
          expect(layer.top, lessThanOrEqualTo(block.top));
          expect(layer.bottom, greaterThanOrEqualTo(block.bottom));
        }
      }
    });

    testWidgets('lays its layer out again for a new distance', (
      WidgetTester tester,
    ) async {
      final ValueNotifier<Offset> source = ValueNotifier<Offset>(Offset.zero);
      await pumpBlock(tester, source);
      await pumpBlock(tester, source, distance: 40);

      expect(tester.getSize(find.byKey(layerKey)).width, 880);
    });

    testWidgets('leans outside a scrollable too', (WidgetTester tester) async {
      final ValueNotifier<Offset> source = ValueNotifier<Offset>(Offset.zero);
      await tester.pumpWidget(
        app(
          Center(
            child: SimpleParallaxItem(
              background: testLayer,
              width: 300,
              height: 200,
              zoom: const ZoomProperties(0.5),
              tilt: TiltProperties(source),
            ),
          ),
        ),
      );
      final Rect block = tester.getRect(find.byType(SimpleParallaxItem));
      final Rect atRest = tester.getRect(find.byKey(layerKey));
      // No overscan and no zoom out here: only the margin.
      expect(atRest, block.inflate(16));

      source.value = const Offset(1, 0);
      await tester.pump();
      expect(tester.getRect(find.byKey(layerKey)).left, atRest.left - 16);
    });

    testWidgets('holds still under reduced motion', (
      WidgetTester tester,
    ) async {
      final ValueNotifier<Offset> source = ValueNotifier<Offset>(Offset.zero);
      await tester.pumpWidget(
        app(
          reducedMotion(
            ListView(
              children: <Widget>[
                SimpleParallaxItem(
                  background: testLayer,
                  height: 200,
                  tilt: TiltProperties(source),
                ),
              ],
            ),
          ),
        ),
      );
      final Rect atRest = tester.getRect(find.byKey(layerKey));

      source.value = const Offset(1, 1);
      await tester.pump();
      expect(tester.getRect(find.byKey(layerKey)), atRest);
    });

    testWidgets('decodes its image with the margin', (
      WidgetTester tester,
    ) async {
      final ValueNotifier<Offset> source = ValueNotifier<Offset>(Offset.zero);
      await tester.pumpWidget(
        app(
          ListView(
            children: <Widget>[
              SimpleParallaxItem(
                image: testImage,
                height: 200,
                tilt: TiltProperties(source),
              ),
            ],
          ),
        ),
      );

      // 832 by 332 on a screen of 3, rounded up to 64.
      final DisplaySizeImage image =
          tester.widget<Image>(find.byType(Image)).image as DisplaySizeImage;
      expect(image.size, const Size(2496, 1024));
    });
  });

  group('a tilted container', () {
    Future<void> pumpPage(
      WidgetTester tester,
      ValueNotifier<Offset> source, {
      Axis axis = Axis.vertical,
      TextDirection direction = TextDirection.ltr,
    }) =>
        tester.pumpWidget(
          app(
            Directionality(
              textDirection: direction,
              child: SimpleParallaxContainer(
                background: testLayer,
                scrollDirection: axis,
                parallax: const ParallaxProperties(overscan: 2),
                tilt: TiltProperties(source, distance: 24),
                child: axis == Axis.vertical
                    ? Column(children: tallList())
                    : Row(children: wideList()),
              ),
            ),
          ),
        );

    testWidgets('draws its layer larger on every side and leans', (
      WidgetTester tester,
    ) async {
      final ValueNotifier<Offset> source = ValueNotifier<Offset>(Offset.zero);
      await pumpPage(tester, source);

      final Rect atRest = tester.getRect(find.byKey(layerKey));
      expect(atRest, const Rect.fromLTWH(-24, -24, 848, 1248));

      source.value = const Offset(-1, 1);
      await tester.pump();
      final Rect leaning = tester.getRect(find.byKey(layerKey));
      expect(leaning.topLeft - atRest.topLeft, const Offset(24, -24));
    });

    testWidgets('keeps its layer over the viewport, whichever way it runs', (
      WidgetTester tester,
    ) async {
      final ValueNotifier<Offset> source = ValueNotifier<Offset>(Offset.zero);
      for (final (Axis, TextDirection) way in const <(Axis, TextDirection)>[
        (Axis.vertical, TextDirection.ltr),
        (Axis.horizontal, TextDirection.ltr),
        (Axis.horizontal, TextDirection.rtl),
      ]) {
        await pumpPage(tester, source, axis: way.$1, direction: way.$2);
        final ScrollPosition position = scrollPosition(tester);
        for (final double at in <double>[0, 1]) {
          position.jumpTo(position.maxScrollExtent * at);
          for (final Offset lean in const <Offset>[
            Offset(1, 1),
            Offset(-1, -1),
          ]) {
            source.value = lean;
            await tester.pump();
            final Rect layer = tester.getRect(find.byKey(layerKey));
            expect(layer.left, lessThanOrEqualTo(0), reason: '$way $at');
            expect(layer.top, lessThanOrEqualTo(0), reason: '$way $at');
            expect(layer.right, greaterThanOrEqualTo(800), reason: '$way $at');
            expect(
              layer.bottom,
              greaterThanOrEqualTo(600),
              reason: '$way $at',
            );
          }
        }
      }
    });
  });

  test('rejects a negative distance', () {
    expect(
      () => TiltProperties(ValueNotifier<Offset>(Offset.zero), distance: -1),
      throwsAssertionError,
    );
  });
}
