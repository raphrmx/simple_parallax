import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_parallax/simple_parallax.dart';

import 'helpers.dart';

void main() {
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
        app(
          ListView(
            children: <Widget>[
              SimpleParallaxItem(
                image: testImage,
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
        app(
          SimpleParallaxContainer(
            image: testImage,
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
          app(
            reducedMotion(
              SimpleParallaxContainer(
                background: testLayer,
                parallax: const ParallaxProperties(overscan: 2),
                zoom: const ZoomProperties(0.5),
                respectReducedMotion: respect,
                child: Column(children: tallList()),
              ),
            ),
          ),
        );

    testWidgets('holds a container background still', (
      WidgetTester tester,
    ) async {
      await pumpPage(tester, respect: true);
      final Rect atRest = tester.getRect(find.byKey(layerKey));

      final ScrollPosition position = scrollPosition(tester);
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();

      expect(tester.getRect(find.byKey(layerKey)), atRest);
    });

    testWidgets('moves it anyway when told to', (WidgetTester tester) async {
      await pumpPage(tester, respect: false);
      final Rect atRest = tester.getRect(find.byKey(layerKey));

      final ScrollPosition position = scrollPosition(tester);
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();

      expect(tester.getRect(find.byKey(layerKey)), isNot(atRest));
    });

    /// A block of 400 below a screenful, with a background of 600 at the
    /// default overscan, so a centred one stands 100 above the block.
    Future<void> pumpBlock(WidgetTester tester) => tester.pumpWidget(
          app(
            reducedMotion(
              ListView(
                children: const <Widget>[
                  SizedBox(height: 600),
                  SimpleParallaxItem(
                    background: testLayer,
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
        tester.getTopLeft(find.byKey(layerKey)).dy -
        tester.getTopLeft(find.byType(SimpleParallaxItem)).dy;

    testWidgets('holds a block background centred', (
      WidgetTester tester,
    ) async {
      await pumpBlock(tester);
      // Just in, where a moving background would still sit near one end.
      scrollPosition(tester).jumpTo(100);
      await tester.pump();
      expect(layerInBlock(tester), -100);

      scrollPosition(tester).jumpTo(900);
      await tester.pump();

      expect(layerInBlock(tester), -100);
    });

    testWidgets('holds a block blur at its mid-crossing value', (
      WidgetTester tester,
    ) async {
      await pumpBlock(tester);
      scrollPosition(tester).jumpTo(100);
      await tester.pump();
      expect(blurFilter(tester), blurOf(6));

      scrollPosition(tester).jumpTo(900);
      await tester.pump();

      expect(blurFilter(tester), blurOf(6));
    });
  });
}
