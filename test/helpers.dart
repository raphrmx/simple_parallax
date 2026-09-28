/// What the tests share: a tiny image, the app around a widget, and ways to
/// scroll and read back what was drawn.
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// A 1x1 transparent PNG, so the tests never touch the asset bundle or the
/// network.
final Uint8List testPixel = Uint8List.fromList(<int>[
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

ImageProvider get testImage => MemoryImage(testPixel);

Widget app(Widget child) => MaterialApp(home: Scaffold(body: child));

/// Sends one wheel notch of [delta] over the middle of the view.
Future<void> sendWheel(WidgetTester tester, Offset delta) async {
  final TestPointer pointer = TestPointer(1, PointerDeviceKind.mouse);
  final Offset middle = tester.getCenter(find.byType(Scrollable));
  await tester.sendEventToBinding(pointer.hover(middle));
  await tester.sendEventToBinding(pointer.scroll(delta));
}

/// The position of the one scroll view under test.
ScrollPosition scrollPosition(WidgetTester tester) =>
    (tester.state(find.byType(Scrollable)) as ScrollableState).position;

/// A list tall enough to scroll in a 600 pixel test viewport.
List<Widget> tallList() => List<Widget>.generate(
      20,
      (int i) => SizedBox(height: 100, child: Text('Item $i')),
    );

/// A list wide enough to scroll in an 800 pixel test viewport.
List<Widget> wideList() => List<Widget>.generate(
      20,
      (int i) => SizedBox(width: 300, child: Text('Item $i')),
    );

/// Marks the background widget, so a test can find the layer when there is no
/// [Image] to look for.
const Key layerKey = Key('layer');

/// The layer itself. A [ColoredBox] with no child fills the box it is given,
/// which is what the parallax hands it.
const Widget testLayer = ColoredBox(key: layerKey, color: Color(0xFF1A237E));

/// A desktop, where the wheel is eased unless told otherwise. Tests run as
/// Android by default, where it is not.
final TargetPlatformVariant onDesktop =
    TargetPlatformVariant.only(TargetPlatform.windows);

/// [child] on a platform that asks for reduced motion.
Widget reducedMotion(Widget child) => Builder(
      builder: (BuildContext context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child,
      ),
    );

/// The blur over the one background under test, or `null` when the background
/// is not blurred at all.
ui.ImageFilter? blurFilter(WidgetTester tester) {
  final Iterable<ImageFilterLayer> filters =
      tester.layers.whereType<ImageFilterLayer>();
  return filters.isEmpty ? null : filters.single.imageFilter;
}

/// A gaussian blur of [sigma], as the widgets build it.
ui.ImageFilter blurOf(double sigma) => ui.ImageFilter.blur(
      sigmaX: sigma,
      sigmaY: sigma,
      tileMode: TileMode.clamp,
    );
