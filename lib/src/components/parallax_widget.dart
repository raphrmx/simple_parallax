import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_parallax/src/common/scroll_notifier.dart';
import 'package:simple_parallax/src/components/parallax_layer.dart';

/// SimpleParallax widget
class ParallaxWidget extends StatelessWidget {
  /// Background image path
  final String imagePath;

  /// Parallax content
  final Widget child;

  /// Parallax speed setting
  final double speed;

  /// Image base position
  final double decal;

  /// Simple parallax constructor
  const ParallaxWidget({
    super.key,
    required this.imagePath,
    required this.child,
    this.speed = 0.3,
    this.decal = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final parentHeight = constraints.maxHeight;
      final parentWidth = constraints.maxWidth;

      return ChangeNotifierProvider(
        create: (context) => ScrollNotifier(),
        child: Consumer<ScrollNotifier>(builder: (context, notifier, _) {
          return NotificationListener<ScrollNotification>(
            onNotification: (scrollNotification) {
              if (scrollNotification is ScrollUpdateNotification) {
                final scrollPixels = scrollNotification.metrics.pixels;
                final offset = scrollPixels * speed;
                Provider.of<ScrollNotifier>(context, listen: false)
                    .setScrollOffset(offset);
              }
              return true;
            },
            child: Stack(
              children: [
                ParallaxLayer(
                  imagePath: imagePath,
                  speed: speed,
                  decal: decal,
                  width: parentWidth,
                  height: parentHeight,
                ),
                SingleChildScrollView(child: child),
              ],
            ),
          );
        }),
      );
    });
  }
}
