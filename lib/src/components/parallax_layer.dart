import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_parallax/src/common/scroll_notifier.dart';

/// Parallax layer for background image
class ParallaxLayer extends StatelessWidget {
  /// Background image path
  final String imagePath;

  /// Parallax speed setting
  final double speed;

  /// Image base position
  final double decal;

  /// Background layer width
  final double? width;

  /// Background layer height
  final double? height;

  /// Layer constructor
  const ParallaxLayer({
    super.key,
    required this.imagePath,
    this.speed = 0.3,
    this.decal = 1.0,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ScrollNotifier>(
      builder: (context, notifier, _) {
        final blocHeight = height ?? MediaQuery.of(context).size.height;
        final blocWidth = width ?? MediaQuery.of(context).size.width;
        final imageHeight = blocHeight * (speed + decal);

        double offset = notifier.scrollOffset;

        if (offset.isNaN || offset.isInfinite) {
          offset = 0;
        }

        final imageActualHeight = imageHeight + offset;

        return Positioned(
          top: -offset,
          left: 0,
          width: blocWidth,
          height: imageActualHeight,
          child: Image.asset(imagePath, fit: BoxFit.cover),
        );
      },
    );
  }
}
