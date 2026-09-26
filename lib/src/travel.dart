/// The maths both modes read a background's travel with.
///
/// Container mode measures its travel down the page and item mode measures it
/// across the viewport, but once either has a progress the effects are the
/// same, so they are worked out in one place.
library;

/// Step the blur sigma is rounded to, so the filter is rebuilt only when it
/// changes visibly.
const double blurStep = 0.25;

/// [progress] shaped by an effect that reaches its far end at [reach] and
/// either holds there or comes [back].
///
/// A `null` [reach] leaves the progress alone, so the effect runs once from one
/// end of the travel to the other. Anything else packs it into the stretch
/// before that point: `0.5` has it finished by the middle, and what follows is
/// either the far end held, or the same range run backwards.
double shaped(double progress, double? reach, bool back) {
  if (reach == null || reach >= 1) return progress;
  if (reach <= 0) return back ? 1 - progress : 1;
  if (progress <= reach) return progress / reach;
  return back ? (1 - progress) / (1 - reach) : 1;
}

/// The scale a background of [zoom] is drawn at, [progress] of the way along
/// its travel.
///
/// A negative zoom reads the same range from the other end, so the scale stays
/// at or above `1` whichever way it is given.
double scaleFor(double progress, double zoom) {
  if (zoom == 0) return 1;
  return 1 + zoom.abs() * (zoom > 0 ? progress : 1 - progress);
}

/// The sigma a background of [blur] is filtered with, [progress] of the way
/// along its travel, rounded to [blurStep].
///
/// A negative blur reads the same range from the other end, so the background
/// arrives soft and clears rather than the other way round.
double sigmaFor(double progress, double blur) {
  if (blur == 0) return 0;
  final double sigma = blur.abs() * (blur > 0 ? progress : 1 - progress);
  return (sigma / blurStep).roundToDouble() * blurStep;
}
