import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_parallax/src/common/scroll_notifier.dart';

class ParallaxLayer extends StatelessWidget {
  final String imagePath;
  final double speed;
  final double decal;
  final double? width;
  final double? height;

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
