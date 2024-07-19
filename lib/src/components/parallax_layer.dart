import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../common/scroll_notifier.dart';

/// Parallax layer for background image
class ParallaxLayer extends StatelessWidget {
  /// Layer constructor
  const ParallaxLayer({
    super.key,
    required this.imagePath,
    this.speed = 0.3,
    this.decal = 1.0,
    this.width,
    this.height,
  });

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

  @override
  Widget build(BuildContext context) {
    return Consumer<ScrollNotifier>(
      builder: (BuildContext context, ScrollNotifier notifier, _) {
        final double blocHeight = height ?? MediaQuery.of(context).size.height;
        final double blocWidth = width ?? MediaQuery.of(context).size.width;
        final double imageHeight = blocHeight * (speed + decal);

        double offset = notifier.scrollOffset;

        if (offset.isNaN || offset.isInfinite) {
          offset = 0;
        }

        final double imageActualHeight = imageHeight + offset;

        return Positioned(
          top: -offset,
          left: 0,
          width: blocWidth,
          height: imageActualHeight,
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }
}
