import 'package:flutter/widgets.dart';

import 'properties.dart';

/// The fixed tint a parallax draws over its background.
///
/// It sits in the same [Stack] as the background and the content, above the
/// first and below the second, so it covers the image without touching what is
/// written on top of it.
class OverlayLayer extends StatelessWidget {
  /// Creates the tint described by [overlay].
  const OverlayLayer(this.overlay, {super.key});

  /// The colour or the gradient to draw, and what to draw it at.
  final OverlayProperties overlay;

  @override
  Widget build(BuildContext context) => Opacity(
        // At 1 this pushes no layer, so the common case costs nothing.
        opacity: overlay.opacity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: overlay.color,
            gradient: overlay.gradient,
          ),
        ),
      );
}
