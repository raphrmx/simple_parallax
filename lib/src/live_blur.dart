import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Blurs its child by a sigma read at paint.
///
/// A filter is a layer, so it cannot be handed to the [Flow] that places the
/// background. This pushes its own from inside that flow instead, which has to
/// be a [Flow.unwrapped]: a plain [Flow] puts a [RepaintBoundary] over each
/// child, and a scroll would then move the layer without painting this again,
/// so the sigma would never be read. Unwrapped, it is painted by the flow on
/// every scroll, straight after the flow has worked out where the background
/// stands, which is what [sigma] reads. Keep a [RepaintBoundary] under it, over
/// the layer itself, so the layer is not painted again along with it.
class LiveBlur extends SingleChildRenderObjectWidget {
  /// Creates a blur of [sigma].
  const LiveBlur({
    required this.sigma,
    required Widget super.child,
    super.key,
  });

  /// The sigma to blur with, read at paint. `0` or less draws the child as it
  /// stands.
  final double Function() sigma;

  @override
  RenderLiveBlur createRenderObject(BuildContext context) =>
      RenderLiveBlur(sigma: sigma);

  @override
  void updateRenderObject(BuildContext context, RenderLiveBlur renderObject) {
    renderObject.sigma = sigma;
  }
}

/// The render object behind [LiveBlur].
class RenderLiveBlur extends RenderProxyBox {
  /// Creates a blur of [sigma].
  RenderLiveBlur({required double Function() sigma}) : _sigma = sigma;

  double Function() _sigma;

  /// The sigma to blur with, read at paint.
  set sigma(double Function() value) {
    if (value == _sigma) return;
    _sigma = value;
    markNeedsPaint();
  }

  final LayerHandle<ImageFilterLayer> _filter = LayerHandle<ImageFilterLayer>();

  @override
  bool get alwaysNeedsCompositing => child != null;

  @override
  void dispose() {
    _filter.layer = null;
    super.dispose();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final double sigma = _sigma();
    if (sigma <= 0) {
      _filter.layer = null;
      super.paint(context, offset);
      return;
    }

    final ImageFilterLayer filter = _filter.layer ??= ImageFilterLayer();
    // Clamped rather than left to fade out, which would show the page down the
    // sides of the layer.
    filter.imageFilter = ui.ImageFilter.blur(
      sigmaX: sigma,
      sigmaY: sigma,
      tileMode: TileMode.clamp,
    );
    context.pushLayer(filter, super.paint, offset);
  }
}
