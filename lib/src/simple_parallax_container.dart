import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'smooth_scroll.dart';
import 'travel.dart';

/// A scrolling area whose background image drifts slower than its content.
///
/// The background is drawn at [overscan] times the viewport extent along
/// [scrollDirection] and translated against the content as it scrolls, which is
/// what produces the depth. Only the background repaints while scrolling:
/// [child] is built once and reused across frames.
///
/// The content is a [CustomScrollView]. The default constructor puts [child] in
/// a single box sliver, which builds it whole; [SimpleParallaxContainer.slivers]
/// takes the slivers themselves, so a long list builds lazily and a
/// `SliverAppBar` or a `SliverGrid` can sit in front of the background.
///
/// The background is either an [image] or a [background] widget, never both. The
/// widget form is what you want for a gradient, a video, a shader, a blurred or
/// tinted image, a cached network image, or for the [Image] parameters this
/// widget does not forward, `loadingBuilder`, `errorBuilder` and `cacheHeight`
/// among them. Either way the layer is built once and reused: scrolling only
/// moves it.
///
/// ---
///
/// ### Parameters:
/// - [image]: any [ImageProvider], so an asset, a network image, a file or
///   raw bytes all work.
/// - [background]: the background layer as a widget, in place of [image].
/// - [child]: the scrolling content, laid out as a single box sliver.
/// - [slivers]: the scrolling content as slivers, which build lazily.
/// - [scrollDirection]: the axis the content scrolls along, and therefore the
///   axis the background drifts along.
/// - [speed]: how far the background moves per pixel scrolled. `0` pins it,
///   `1` makes it follow the content exactly. Ignored when [autoSpeed] is set.
/// - [autoSpeed]: derives the speed from the real scroll extent, so the
///   background uses exactly the travel [overscan] gives it and no more.
/// - [overscan]: how much larger than the viewport the background is drawn
///   along [scrollDirection]. Must be at least `1`; at exactly `1` there is no
///   travel, so no drift, though a [zoom] still works there. It raises the
///   extent `BoxFit.cover` fits to, so it changes the framing only where that
///   extent is what `cover` is scaling by.
/// - [height]: forces the viewport height instead of taking it from the
///   incoming constraints.
/// - [width]: forces the viewport width instead of taking it from the incoming
///   constraints.
/// - [fit]: how the background fills its layer. Applies to [image] only.
/// - [alignment]: how the background is aligned inside its layer. Applies to
///   [image] only: a [background] widget is laid out to fill the layer as it
///   stands.
/// - [zoom]: scale the background gains across its travel, `0` for none.
/// - [blur]: gaussian blur in logical pixels the background gains across its
///   travel, `0` for none.
/// - [reach]: where along the travel [zoom] and [blur] are done, `null` to
///   spread them over the whole of it.
/// - [back]: whether they come back from there rather than holding.
/// - [smooth]: whether the mouse wheel is eased in rather than landed in one
///   step.
///
/// ### Example:
/// ```dart
/// SimpleParallaxContainer(
///   image: const AssetImage('assets/images/background.webp'),
///   autoSpeed: true,
///   child: Column(children: items),
/// );
/// ```
///
/// The same container scrolling sideways:
/// ```dart
/// SimpleParallaxContainer(
///   image: const AssetImage('assets/images/background.webp'),
///   scrollDirection: Axis.horizontal,
///   autoSpeed: true,
///   child: Row(children: items),
/// );
/// ```
///
/// The same container over a list that builds as it scrolls:
/// ```dart
/// SimpleParallaxContainer.slivers(
///   image: const AssetImage('assets/images/background.webp'),
///   autoSpeed: true,
///   slivers: <Widget>[
///     SliverList.builder(
///       itemCount: 500,
///       itemBuilder: (BuildContext context, int index) =>
///           ListTile(title: Text('Chapter $index')),
///     ),
///   ],
/// );
/// ```
///
/// The same container over a gradient instead of an image:
/// ```dart
/// SimpleParallaxContainer(
///   background: const DecoratedBox(
///     decoration: BoxDecoration(
///       gradient: LinearGradient(
///         begin: Alignment.topCenter,
///         end: Alignment.bottomCenter,
///         colors: <Color>[Color(0xFF1A237E), Color(0xFF80DEEA)],
///       ),
///     ),
///   ),
///   autoSpeed: true,
///   child: Column(children: items),
/// );
/// ```
class SimpleParallaxContainer extends StatefulWidget {
  /// Creates a parallax container over a single box [child], given either an
  /// [image] or a [background].
  const SimpleParallaxContainer({
    required Widget this.child,
    this.image,
    this.background,
    this.scrollDirection = Axis.vertical,
    this.speed = 0.3,
    this.autoSpeed = false,
    this.overscan = 1.5,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.zoom = 0,
    this.blur = 0,
    this.reach,
    this.back = false,
    this.smooth = false,
    super.key,
  })  : slivers = null,
        assert(overscan >= 1, 'overscan must be at least 1'),
        assert(
          reach == null || (reach >= 0 && reach <= 1),
          'reach is a fraction of the travel, so between 0 and 1',
        ),
        assert(!back || reach != null, 'back needs a reach to come back from'),
        assert(
          (image == null) != (background == null),
          'pass exactly one of image and background',
        );

  /// Creates a parallax container over [slivers], which build lazily, given
  /// either an [image] or a [background].
  const SimpleParallaxContainer.slivers({
    required List<Widget> this.slivers,
    this.image,
    this.background,
    this.scrollDirection = Axis.vertical,
    this.speed = 0.3,
    this.autoSpeed = false,
    this.overscan = 1.5,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.zoom = 0,
    this.blur = 0,
    this.reach,
    this.back = false,
    this.smooth = false,
    super.key,
  })  : child = null,
        assert(overscan >= 1, 'overscan must be at least 1'),
        assert(
          reach == null || (reach >= 0 && reach <= 1),
          'reach is a fraction of the travel, so between 0 and 1',
        ),
        assert(!back || reach != null, 'back needs a reach to come back from'),
        assert(
          (image == null) != (background == null),
          'pass exactly one of image and background',
        );

  /// Background image, or `null` when a [background] was given instead.
  final ImageProvider? image;

  /// Background layer, or `null` when an [image] was given instead.
  ///
  /// The layer is given the viewport extent on the cross axis and [overscan]
  /// times it on the scrolled axis, with both axes tight, so anything that fills
  /// the box it is handed works: a `DecoratedBox` holding a gradient, an [Image]
  /// the caller configured, a `Stack` of several layers, a video.
  final Widget? background;

  /// Scrolling content, or `null` when the container was given [slivers].
  final Widget? child;

  /// Scrolling content as slivers, or `null` when the container was given a
  /// [child].
  final List<Widget>? slivers;

  /// Axis the content scrolls along, and the background drifts along.
  final Axis scrollDirection;

  /// Background travel per pixel scrolled. Ignored when [autoSpeed] is set.
  final double speed;

  /// Whether the speed is derived from the actual scroll extent.
  final bool autoSpeed;

  /// How much larger than the viewport the background is drawn along
  /// [scrollDirection].
  final double overscan;

  /// Forced viewport height, or `null` to use the incoming constraints.
  final double? height;

  /// Forced viewport width, or `null` to use the incoming constraints.
  final double? width;

  /// How the background fills its layer. Applies to [image] only: a [background]
  /// widget fills the layer as it stands.
  final BoxFit fit;

  /// How the background is aligned inside its layer. Applies to [image] only.
  final Alignment alignment;

  /// Scale the background gains across its travel, on top of the drift.
  ///
  /// `0` leaves it alone. A positive figure pushes the background in, `0.3`
  /// ending thirty percent larger than it started. A negative one runs the same
  /// range backwards: `-0.3` starts thirty percent larger and settles back, so
  /// the background comes to rest instead of growing.
  ///
  /// Either way the scale never goes below `1`, which it cannot: [overscan]
  /// pads the scrolled axis alone, so the layer is exactly as wide as the
  /// viewport across it and anything smaller would show the page behind.
  ///
  /// Scaling a bitmap up softens it, and [overscan] has already scaled it once,
  /// so a large figure on a small asset will show.
  final double zoom;

  /// Gaussian blur the background gains across its travel, in logical pixels.
  ///
  /// `0` leaves it alone. A positive figure starts sharp and ends at that
  /// sigma, `8` finishing at a sigma of eight. A negative one runs the same
  /// range backwards: `-8` starts at eight and clears as the page is scrolled.
  ///
  /// The layer is blurred before [zoom] scales it, so a zoom carries the blur
  /// along with everything else.
  ///
  /// This one is a filter rather than a transform, so it costs more than the
  /// drift and the zoom: the layer is blurred again on each frame it moves. The
  /// sigma is rounded to a quarter of a pixel, so the filter is left alone for
  /// changes no one can see.
  final double blur;

  /// Where along the travel [zoom] and [blur] are done, `null` to spread them
  /// over the whole of it.
  ///
  /// `0.5` is halfway down the page, so the effect is finished there. It then
  /// holds at its far end for the rest of the travel, or comes back the way it
  /// went when [back] is set.
  ///
  /// The drift is not shaped by this. It follows the scroll whatever is set
  /// here, since a background that walked back up the page would read as the
  /// content scrolling the other way.
  final double? reach;

  /// Whether [zoom] and [blur] come back from [reach] rather than holding
  /// there.
  ///
  /// A zoom then pushes in and backs out again over one page, and a negative
  /// blur arrives soft, clears halfway and goes soft again.
  final bool back;

  /// Whether the mouse wheel is eased in rather than landed in one step.
  ///
  /// A wheel notch normally arrives on a single frame, which shows on anything
  /// driven off the scroll position, a parallax background first of all. On a
  /// horizontal view it also brings the wheel to an axis a [Scrollable] leaves
  /// untouched, since a plain wheel only carries a vertical delta.
  ///
  /// Dragging and flinging are untouched.
  final bool smooth;

  @override
  State<SimpleParallaxContainer> createState() =>
      _SimpleParallaxContainerState();
}

/// Where the background sits, how far it is scaled and how far it is blurred,
/// at one scroll position.
typedef _Drift = ({double offset, double scale, double sigma});

class _SimpleParallaxContainerState extends State<SimpleParallaxContainer> {
  /// Late so the first value can already carry the scale and the sigma the
  /// background starts at, which a negative zoom or blur puts above nothing.
  late final ValueNotifier<_Drift> _drift =
      ValueNotifier<_Drift>(_driftAt(0, 0));

  bool get _horizontal => widget.scrollDirection == Axis.horizontal;

  /// The background layer: the caller's widget, or their image wrapped in one.
  Widget get _layer {
    final Widget? background = widget.background;
    return background ??
        Image(
          image: widget.image!,
          fit: widget.fit,
          alignment: widget.alignment,
        );
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  /// Travel the background has available before its trailing edge would show.
  double _travelFor(double viewportExtent) =>
      viewportExtent * (widget.overscan - 1);

  /// Where the background stands at [metrics], from `0` at the top of the page
  /// to `1` at the bottom.
  double _progressFor(ScrollMetrics metrics) {
    if (metrics.maxScrollExtent <= 0) return 0;
    return (metrics.pixels / metrics.maxScrollExtent).clamp(0.0, 1.0);
  }

  /// The background sitting at [offset], [progress] of the way along its
  /// travel.
  _Drift _driftAt(double offset, double progress) {
    final double at = shaped(progress, widget.reach, widget.back);
    return (
      offset: offset,
      scale: scaleFor(at, widget.zoom),
      sigma: sigmaFor(at, widget.blur),
    );
  }

  /// The layer under a blur of [sigma], or the layer itself when there is no
  /// blur to apply.
  Widget _blurred(Widget layer, double sigma) {
    if (widget.blur == 0) return layer;
    return ImageFiltered(
      enabled: sigma > 0,
      // Clamped rather than left to fade out, which would show the page down
      // the sides of the layer.
      imageFilter: ui.ImageFilter.blur(
        sigmaX: sigma,
        sigmaY: sigma,
        tileMode: TileMode.clamp,
      ),
      child: layer,
    );
  }

  /// The point the scale turns about, given as an [Alignment] of the layer.
  ///
  /// The middle of the viewport, which is where the eye is, rather than the
  /// middle of the layer, which sits off screen and moves as the background
  /// drifts.
  Alignment _anchor(double offset, double viewportExtent) {
    final double extent = viewportExtent * widget.overscan;
    if (extent <= 0) return Alignment.center;
    final double at = 2 * (offset + viewportExtent / 2) / extent - 1;
    return _horizontal ? Alignment(at, 0) : Alignment(0, at);
  }

  double _speedFor(ScrollMetrics metrics) {
    if (!widget.autoSpeed) return widget.speed;
    if (metrics.maxScrollExtent <= 0) return 0;
    return _travelFor(metrics.viewportDimension) / metrics.maxScrollExtent;
  }

  bool _onScroll(ScrollUpdateNotification notification, double viewportExtent) {
    // A scrollable nested the other way round says nothing about our own
    // travel, so it must not move the background.
    if (notification.metrics.axis != widget.scrollDirection) return false;

    final ScrollMetrics metrics = notification.metrics;
    final double travel = _travelFor(viewportExtent);
    final double value = metrics.pixels * _speedFor(metrics);
    if (value.isFinite) {
      // Clamped so the background never travels past the overscan it was drawn
      // with, which would uncover its trailing edge.
      final double offset = value.clamp(0, travel <= 0 ? 0 : travel);
      _drift.value = _driftAt(offset, _progressFor(metrics));
    }
    // Let the notification keep bubbling: an ancestor may be listening too.
    return false;
  }

  /// The scrolling content: the slivers the caller gave us, or the single box
  /// sliver holding [SimpleParallaxContainer.child].
  Widget _buildContent() {
    if (widget.smooth) {
      return SmoothScroll(
        axis: widget.scrollDirection,
        builder: (BuildContext context, ScrollController controller) =>
            _scrollView(controller),
      );
    }
    return _scrollView(null);
  }

  /// The scroll view itself, on whichever controller it was handed.
  Widget _scrollView(ScrollController? controller) => CustomScrollView(
        scrollDirection: widget.scrollDirection,
        controller: controller,
        slivers:
            widget.slivers ?? <Widget>[SliverToBoxAdapter(child: widget.child)],
      );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size screen = MediaQuery.sizeOf(context);
        final double viewportHeight = widget.height ??
            (constraints.hasBoundedHeight
                ? constraints.maxHeight
                : screen.height);
        final double viewportWidth = widget.width ??
            (constraints.hasBoundedWidth ? constraints.maxWidth : screen.width);
        final double viewportExtent =
            _horizontal ? viewportWidth : viewportHeight;

        return SizedBox(
          // Only the scrolled axis is pinned; the cross axis keeps whatever the
          // caller gave us.
          height: _horizontal ? widget.height : viewportHeight,
          width: _horizontal ? viewportWidth : widget.width,
          child: NotificationListener<ScrollUpdateNotification>(
            onNotification: (ScrollUpdateNotification notification) =>
                _onScroll(notification, viewportExtent),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                RepaintBoundary(
                  child: ClipRect(
                    child: ValueListenableBuilder<_Drift>(
                      valueListenable: _drift,
                      builder: (
                        BuildContext context,
                        _Drift drift,
                        Widget? background,
                      ) =>
                          OverflowBox(
                        alignment: _horizontal
                            ? Alignment.centerLeft
                            : Alignment.topCenter,
                        minWidth: _horizontal ? 0 : null,
                        maxWidth: _horizontal ? double.infinity : null,
                        minHeight: _horizontal ? null : 0,
                        maxHeight: _horizontal ? null : double.infinity,
                        child: Transform.translate(
                          offset: _horizontal
                              ? Offset(-drift.offset, 0)
                              : Offset(0, -drift.offset),
                          // Scaled inside the drift, so the two do not multiply
                          // and the zoom leaves the speed alone.
                          child: Transform.scale(
                            scale: drift.scale,
                            alignment: _anchor(drift.offset, viewportExtent),
                            child: _blurred(background!, drift.sigma),
                          ),
                        ),
                      ),
                      child: SizedBox(
                        height: _horizontal
                            ? null
                            : viewportHeight * widget.overscan,
                        width: _horizontal
                            ? viewportWidth * widget.overscan
                            : null,
                        child: _layer,
                      ),
                    ),
                  ),
                ),
                _buildContent(),
              ],
            ),
          ),
        );
      },
    );
  }
}
