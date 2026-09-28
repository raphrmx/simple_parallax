import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_parallax/simple_parallax.dart';
import 'package:simple_parallax/src/display_size_image.dart';

import 'helpers.dart';

void main() {
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
        testImage,
        layer: const Size(400, 300),
        devicePixelRatio: 2,
        fit: BoxFit.cover,
      );
      final ImageProvider<Object> b = decodedFor(
        testImage,
        layer: const Size(401, 301),
        devicePixelRatio: 2,
        fit: BoxFit.cover,
      );

      expect(a, b);
      expect((a as DisplaySizeImage).size, const Size(832, 640));
    });

    test('leaves room for the zoom', () {
      final DisplaySizeImage image = decodedFor(
        testImage,
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
        app(
          ListView(
            children: <Widget>[
              SimpleParallaxItem(image: testImage, height: 200),
            ],
          ),
        ),
      );

      // 800 by 200 at an overscan of 1.5, on a screen of 3, rounded up.
      final DisplaySizeImage image = drawn(tester) as DisplaySizeImage;
      expect(image.size, const Size(2432, 960));
      expect(image.image, testImage);
    });

    testWidgets('decodes a container for its layer', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        app(
          SimpleParallaxContainer(
            image: testImage,
            parallax: const ParallaxProperties(overscan: 2),
            child: Column(children: tallList()),
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
        app(
          ListView(
            children: <Widget>[
              SimpleParallaxItem(
                image: testImage,
                height: 200,
                decodeAtDisplaySize: false,
              ),
            ],
          ),
        ),
      );

      expect(drawn(tester), testImage);
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
          app(
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

  group('an image on its way', () {
    const Color placeholder = Color(0xFFB00020);

    /// A picture the cache has never seen, so it loads rather than being drawn
    /// at once.
    ImageProvider fresh() => MemoryImage(Uint8List.fromList(testPixel));

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
      return tester.pumpWidget(app(reduced ? reducedMotion(list) : list));
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
        app(
          SimpleParallaxContainer(
            image: fresh(),
            placeholderColor: placeholder,
            child: Column(children: tallList()),
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
      Widget page(double overscan) => app(
            SimpleParallaxContainer(
              background: testLayer,
              parallax: ParallaxProperties(overscan: overscan),
              child: Column(children: tallList()),
            ),
          );

      await tester.pumpWidget(page(1.5));
      expect(tester.getSize(find.byKey(layerKey)), const Size(800, 900));

      await tester.pumpWidget(page(2));
      expect(tester.getSize(find.byKey(layerKey)), const Size(800, 1200));
    });

    testWidgets('follows a container turned sideways', (
      WidgetTester tester,
    ) async {
      Widget page(Axis axis) => app(
            SimpleParallaxContainer(
              background: testLayer,
              scrollDirection: axis,
              parallax: const ParallaxProperties(overscan: 1.5),
              child: Flex(direction: axis, children: tallList()),
            ),
          );

      await tester.pumpWidget(page(Axis.vertical));
      expect(tester.getSize(find.byKey(layerKey)), const Size(800, 900));

      await tester.pumpWidget(page(Axis.horizontal));
      expect(tester.getSize(find.byKey(layerKey)), const Size(1200, 600));
    });

    testWidgets('follows an item to a new overscan', (
      WidgetTester tester,
    ) async {
      Widget page(double overscan) => app(
            ListView(
              children: <Widget>[
                SimpleParallaxItem(
                  background: testLayer,
                  height: 200,
                  parallax: ParallaxProperties(overscan: overscan),
                ),
              ],
            ),
          );

      await tester.pumpWidget(page(1.5));
      expect(tester.getSize(find.byKey(layerKey)), const Size(800, 300));

      await tester.pumpWidget(page(2));
      expect(tester.getSize(find.byKey(layerKey)), const Size(800, 400));
    });

    testWidgets('follows an item given a drift across', (
      WidgetTester tester,
    ) async {
      Widget page(ParallaxProperties? cross) => app(
            ListView(
              children: <Widget>[
                SizedBox(
                  height: 300,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: <Widget>[
                      SimpleParallaxItem(
                        background: testLayer,
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
      expect(tester.getSize(find.byKey(layerKey)), const Size(600, 300));

      await tester.pumpWidget(page(const ParallaxProperties()));
      expect(tester.getSize(find.byKey(layerKey)), const Size(600, 450));
    });
  });
}
