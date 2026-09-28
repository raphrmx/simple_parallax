/// The maths both modes read a background's travel with.
///
/// Container mode measures its travel down the page and item mode measures it
/// across the viewport, but once either has a progress the effects are the
/// same, so they are worked out in one place.
library;

import 'package:flutter/rendering.dart';

import 'properties.dart';

/// The transform that draws a background moved by [offset], then scaled by
/// [scale] about [about], a point of the box it is drawn into.
///
/// Scaling after the move keeps the drift from being scaled with it, and about
/// the middle of what is on screen, which is where the eye is.
///
/// Built from `diagonal3Values` and `setTranslationRaw` rather than
/// `translateByDouble` and `scaleByDouble`, which the `vector_math` pinned by
/// the oldest Flutter this package supports does not have.
Matrix4 placed(Offset offset, double scale, Offset about) {
  final Matrix4 move = Matrix4.translationValues(offset.dx, offset.dy, 0);
  if (scale == 1) return move;
  return Matrix4.diagonal3Values(scale, scale, 1)
    ..setTranslationRaw(about.dx * (1 - scale), about.dy * (1 - scale), 0)
    ..multiply(move);
}

/// Where a background stands along its travel, from `0` to `1`.
///
/// Worked out once per paint by the flow that places the background, and read
/// by the blur painted inside that flow straight after, so the two agree on the
/// frame being drawn and the geometry is measured once.
class TravelProgress {
  /// The progress as of the last paint, `0` before the first.
  double value = 0;
}

/// Step the blur sigma is rounded to, so the filter is rebuilt only when it
/// changes visibly.
const double _blurStep = 0.25;

/// The scale [zoom] draws the background at, [progress] of the way along its
/// travel. `1` when there is no zoom.
double scaleOf(ZoomProperties? zoom, double progress) {
  if (zoom == null || zoom.amount == 0) return 1;
  final double at = _shaped(progress, zoom.reach, zoom.back);
  final double amount = zoom.amount;
  return 1 + amount.abs() * (amount > 0 ? at : 1 - at);
}

/// The sigma [blur] filters the background with, [progress] of the way along
/// its travel. `0` when there is no blur.
double sigmaOf(BlurProperties? blur, double progress) {
  if (blur == null || blur.sigma == 0) return 0;
  final double at = _shaped(progress, blur.reach, blur.back);
  final double amount = blur.sigma;
  final double sigma = amount.abs() * (amount > 0 ? at : 1 - at);
  return (sigma / _blurStep).roundToDouble() * _blurStep;
}

/// [progress] shaped by an effect that reaches its far end at [reach] and
/// either holds there or comes [back].
///
/// A `null` [reach] leaves the progress alone, so the effect runs once from one
/// end of the travel to the other. Anything else packs it into the stretch
/// before that point: `0.5` has it finished by the middle, and what follows is
/// either the far end held, or the same range run backwards.
double _shaped(double progress, double? reach, bool back) {
  if (reach == null || reach >= 1) return progress;
  if (reach <= 0) return back ? 1 - progress : 1;
  if (progress <= reach) return progress / reach;
  return back ? (1 - progress) / (1 - reach) : 1;
}
