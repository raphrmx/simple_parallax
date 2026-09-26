import 'package:flutter/painting.dart';

/// How the background drifts behind the content.
///
/// The drift is the parallax itself: the background moves with the scroll, but
/// less than the content does, and the difference is what reads as depth.
///
/// ---
///
/// ### Parameters:
/// - [speed]: fraction of the available travel the background uses, from `0`
///   (pinned) to `1` (all of it).
/// - [overscan]: how much larger than the viewport, or than the item, the
///   background is drawn along the scrolled axis. It is what creates the travel
///   [speed] then spends. Must be at least `1`; at exactly `1` there is no
///   travel, so no drift, though a zoom or a blur still works.
///
/// ### Example:
/// ```dart
/// SimpleParallaxItem(
///   image: const AssetImage('assets/images/background.webp'),
///   height: 300,
///   parallax: const ParallaxProperties(speed: 0.5, overscan: 1.6),
/// );
/// ```
class ParallaxProperties {
  /// Creates the drift settings.
  const ParallaxProperties({this.speed = 1, this.overscan = 1.5})
      : assert(speed >= 0 && speed <= 1, 'speed must be between 0 and 1'),
        assert(overscan >= 1, 'overscan must be at least 1');

  /// Fraction of the available travel the background uses.
  ///
  /// `1` spreads the whole travel over the whole scroll, so the background
  /// arrives at the far end of its overscan exactly as the content ends. `0`
  /// pins it. Anything between uses that much of the travel and no more.
  ///
  /// On a very long scroll the same travel is spread thinner, so the drift
  /// becomes hard to see. Raise [overscan] to give it more room, or reach for
  /// item mode, where each block has a crossing of its own.
  final double speed;

  /// How much larger than the viewport, or than the item, the background is
  /// drawn along the scrolled axis.
  ///
  /// It raises the extent `BoxFit.cover` fits the image to, so it changes the
  /// framing only where that extent is what `cover` is scaling by.
  final double overscan;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParallaxProperties &&
          other.speed == speed &&
          other.overscan == overscan;

  @override
  int get hashCode => Object.hash(speed, overscan);

  @override
  String toString() => 'ParallaxProperties(speed: $speed, overscan: $overscan)';
}

/// How the background scales as it travels.
///
/// The scale turns about the middle of the viewport rather than the middle of
/// the layer, which sits off screen and moves as the background drifts. That is
/// what keeps the zoom and the drift independent: turning one up does not make
/// the other faster.
///
/// ---
///
/// ### Parameters:
/// - [amount]: the scale gained across the travel. `0.3` ends thirty percent
///   larger than it started. A negative figure runs the same range backwards,
///   so the background starts enlarged and settles.
/// - [reach]: where along the travel the zoom is done, `null` to spread it over
///   the whole of it. `0.5` has it finished at the middle of the screen, held
///   there for the rest.
/// - [back]: whether the zoom comes back from [reach] rather than holding, so
///   it pushes in and backs out again over one travel.
///
/// ### Example:
/// ```dart
/// SimpleParallaxItem(
///   image: const AssetImage('assets/images/background.webp'),
///   height: 300,
///   zoom: const ZoomProperties(0.6, reach: 0.5, back: true),
/// );
/// ```
class ZoomProperties {
  /// Creates the zoom settings, given the scale gained across the travel.
  const ZoomProperties(this.amount, {this.reach, this.back = false})
      : assert(
          reach == null || (reach >= 0 && reach <= 1),
          'reach is a fraction of the travel, so between 0 and 1',
        ),
        assert(!back || reach != null, 'back needs a reach to come back from');

  /// Scale the background gains across its travel.
  ///
  /// Either way the scale never goes below `1`, which it cannot: the overscan
  /// pads the scrolled axis alone, so the layer is exactly as wide as the
  /// viewport across it and anything smaller would show the page behind.
  ///
  /// Scaling a bitmap up softens it, and the overscan has already scaled it
  /// once, so a large figure on a small asset will show.
  final double amount;

  /// Where along the travel the zoom is done, `null` to spread it over the
  /// whole of it.
  final double? reach;

  /// Whether the zoom comes back from [reach] rather than holding there.
  final bool back;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ZoomProperties &&
          other.amount == amount &&
          other.reach == reach &&
          other.back == back;

  @override
  int get hashCode => Object.hash(amount, reach, back);

  @override
  String toString() => 'ZoomProperties($amount, reach: $reach, back: $back)';
}

/// How the background is blurred as it travels.
///
/// Only the background is filtered. Content drawn over it stays sharp, which is
/// what makes a caption or a form readable over a background going soft.
///
/// This one is a filter rather than a transform, so it costs more than the
/// drift and the zoom: the layer is blurred again on each frame it moves. The
/// sigma is rounded to a quarter of a pixel, so the filter is left alone for
/// changes no one can see, and a sigma of zero pushes no layer at all.
///
/// ---
///
/// ### Parameters:
/// - [sigma]: the gaussian sigma gained across the travel, in logical pixels.
///   A negative figure runs the same range backwards, so the background arrives
///   soft and clears.
/// - [reach]: where along the travel the blur is done, `null` to spread it over
///   the whole of it. `0.5` has it finished at the middle of the screen, held
///   there for the rest.
/// - [back]: whether the blur comes back from [reach] rather than holding, so a
///   negative sigma arrives soft, clears in passing and goes soft again.
///
/// ### Example:
/// ```dart
/// SimpleParallaxItem(
///   image: const AssetImage('assets/images/background.webp'),
///   height: 300,
///   blur: const BlurProperties(-16, reach: 0.5, back: true),
/// );
/// ```
class BlurProperties {
  /// Creates the blur settings, given the sigma gained across the travel.
  const BlurProperties(this.sigma, {this.reach, this.back = false})
      : assert(
          reach == null || (reach >= 0 && reach <= 1),
          'reach is a fraction of the travel, so between 0 and 1',
        ),
        assert(!back || reach != null, 'back needs a reach to come back from');

  /// Gaussian sigma the background gains across its travel, in logical pixels.
  ///
  /// A sigma reads in pixels rather than as a fraction of the layer, so the
  /// same figure is a heavy blur on a phone and a moderate one on a desktop.
  final double sigma;

  /// Where along the travel the blur is done, `null` to spread it over the
  /// whole of it.
  final double? reach;

  /// Whether the blur comes back from [reach] rather than holding there.
  final bool back;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlurProperties &&
          other.sigma == sigma &&
          other.reach == reach &&
          other.back == back;

  @override
  int get hashCode => Object.hash(sigma, reach, back);

  @override
  String toString() => 'BlurProperties($sigma, reach: $reach, back: $back)';
}

/// A fixed layer of colour over the background.
///
/// It does not drift, scale or blur with the background: it stays put while the
/// background moves under it, which is what makes it read as a tint on the page
/// rather than as part of the image.
///
/// It is drawn over the background and under the content, so a caption, a
/// button or a form over a darkened image stays at full strength.
///
/// ---
///
/// ### Parameters:
/// - [color]: a flat colour, its own alpha included. `null` when the overlay
///   was given a [gradient] instead.
/// - [gradient]: a gradient, for a scrim that fades across the background.
///   `null` when the overlay was given a [color] instead.
/// - [opacity]: what the whole layer is drawn at, on top of any alpha the
///   colour or the gradient already carries.
///
/// ### Example:
/// ```dart
/// SimpleParallaxItem(
///   image: const AssetImage('assets/images/background.webp'),
///   height: 300,
///   overlay: const OverlayProperties.darken(0.4),
///   child: const Center(child: Text('Chapter one')),
/// );
/// ```
class OverlayProperties {
  /// A flat colour over the background.
  const OverlayProperties(Color this.color, {this.opacity = 1})
      : gradient = null,
        assert(opacity >= 0 && opacity <= 1, 'opacity must be between 0 and 1');

  /// Black over the background, at [opacity].
  const OverlayProperties.darken(this.opacity)
      : color = const Color(0xFF000000),
        gradient = null,
        assert(opacity >= 0 && opacity <= 1, 'opacity must be between 0 and 1');

  /// White over the background, at [opacity].
  const OverlayProperties.lighten(this.opacity)
      : color = const Color(0xFFFFFFFF),
        gradient = null,
        assert(opacity >= 0 && opacity <= 1, 'opacity must be between 0 and 1');

  /// A gradient over the background, for a scrim that fades across it.
  ///
  /// This is what a caption sitting at one edge wants: opaque enough to read
  /// against at that edge, and gone by the other, so the image is not dulled
  /// where nothing is drawn over it.
  const OverlayProperties.gradient(Gradient this.gradient, {this.opacity = 1})
      : color = null,
        assert(opacity >= 0 && opacity <= 1, 'opacity must be between 0 and 1');

  /// Flat colour, or `null` when a [gradient] was given instead.
  final Color? color;

  /// Gradient, or `null` when a [color] was given instead.
  final Gradient? gradient;

  /// What the layer is drawn at, on top of any alpha it already carries.
  final double opacity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OverlayProperties &&
          other.color == color &&
          other.gradient == gradient &&
          other.opacity == opacity;

  @override
  int get hashCode => Object.hash(color, gradient, opacity);

  @override
  String toString() => 'OverlayProperties(color: $color, gradient: $gradient, '
      'opacity: $opacity)';
}
