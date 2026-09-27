import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'overlay_layer.dart';
import 'properties.dart';
import 'smooth_scroll.dart';
import 'travel.dart';

/// A scrolling area whose background image drifts slower than its content.
///
/// The background is drawn at [ParallaxProperties.overscan] times the viewport
/// extent along [scrollDirection] and translated against the content as it
/// scrolls, which is what produces the depth. Only the background repaints
/// while scrolling: [child] is built once and reused across frames.
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
/// - [parallax]: how the background drifts, its speed and its overscan.
/// - [zoom]: how it scales down the page, `null` for not at all.
/// - [blur]: how it is blurred down the page, `null` for not at all.
/// - [overlay]: a fixed tint over the background and under the content, `null`
///   for none.
/// - [height]: forces the viewport height instead of taking it from the
///   incoming constraints.
/// - [width]: forces the viewport width instead of taking it from the incoming
///   constraints.
/// - [fit]: how the background fills its layer. Applies to [image] only.
/// - [alignment]: how the background is aligned inside its layer. Applies to
///   [image] only: a [background] widget is laid out to fill the layer as it
///   stands.
/// - [smooth]: whether the mouse wheel is eased in rather than landed in one
///   step.
///
/// ### Example:
/// ```dart
/// SimpleParallaxContainer(
///   image: const AssetImage('assets/images/background.webp'),
///   child: Column(children: items),
/// );
/// ```
///
/// The same container scrolling sideways:
/// ```dart
/// SimpleParallaxContainer(
///   image: const AssetImage('assets/images/background.webp'),
///   scrollDirection: Axis.horizontal,
///   child: Row(children: items),
/// );
/// ```
///
/// The same container over a list that builds as it scrolls:
/// ```dart
/// SimpleParallaxContainer.slivers(
///   image: const AssetImage('assets/images/background.webp'),
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
    this.parallax = const ParallaxProperties(),
    this.zoom,
    this.blur,
    this.overlay,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.smooth = true,
    super.key,
  })  : slivers = null,
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
    this.parallax = const ParallaxProperties(),
    this.zoom,
    this.blur,
    this.overlay,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.smooth = true,
    super.key,
  })  : child = null,
        assert(
          (image == null) != (background == null),
          'pass exactly one of image and background',
        );

  /// Background image, or `null` when a [background] was given instead.
  final ImageProvider? image;

  /// Background layer, or `null` when an [image] was given instead.
  ///
  /// The layer is given the viewport extent on the cross axis and the overscan
  /// times it on the scrolled axis, with both axes tight, so anything that
  /// fills the box it is handed works: a `DecoratedBox` holding a gradient, an
  /// [Image] the caller configured, a `Stack` of several layers, a video.
  final Widget? background;

  /// Scrolling content, or `null` when the container was given [slivers].
  final Widget? child;

  /// Scrolling content as slivers, or `null` when the container was given a
  /// [child].
  final List<Widget>? slivers;

  /// Axis the content scrolls along, and the background drifts along.
  final Axis scrollDirection;

  /// How the background drifts behind the content.
  final ParallaxProperties parallax;

  /// How the background scales down the page, `null` for not at all.
  final ZoomProperties? zoom;

  /// How the background is blurred down the page, `null` for not at all.
  ///
  /// The layer is blurred before [zoom] scales it, so a zoom carries the blur
  /// along with everything else.
  final BlurProperties? blur;

  /// A fixed tint over the background, `null` for none.
  ///
  /// It is drawn over the background and under the scrolling content, and it
  /// does not move with the background.
  final OverlayProperties? overlay;

  /// Forced viewport height, or `null` to use the incoming constraints.
  final double? height;

  /// Forced viewport width, or `null` to use the incoming constraints.
  final double? width;

  /// How the background fills its layer. Applies to [image] only: a [background]
  /// widget fills the layer as it stands.
  final BoxFit fit;

  /// How the background is aligned inside its layer. Applies to [image] only.
  final Alignment alignment;

  /// Whether the mouse wheel is eased in rather than landed in one step.
  ///
  /// A wheel notch normally arrives on a single frame, which shows on anything
  /// driven off the scroll position, a parallax background first of all. On a
  /// horizontal view it also brings the wheel to an axis a [Scrollable] leaves
  /// untouched, since a plain wheel only carries a vertical delta.
  ///
  /// On by default, since a stepping background is what a parallax is there to
  /// avoid. Dragging, flinging and touch are untouched either way, so this is a
  /// mouse and trackpad setting.
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

  /// The metrics and the viewport extent the drift was last worked out from,
  /// kept so a change of settings can be applied without waiting for a scroll.
  ScrollMetrics? _metrics;
  double _viewportExtent = 0;

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
  void didUpdateWidget(SimpleParallaxContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final ScrollMetrics? metrics = _metrics;
    if (metrics != null &&
        (widget.parallax != oldWidget.parallax ||
            widget.zoom != oldWidget.zoom ||
            widget.blur != oldWidget.blur)) {
      _follow(metrics, _viewportExtent);
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  /// Travel the background has available before its trailing edge would show.
  double _travelFor(double viewportExtent) =>
      viewportExtent * (widget.parallax.overscan - 1);

  /// Where the background stands at [metrics], from `0` at the top of the page
  /// to `1` at the bottom.
  double _progressFor(ScrollMetrics metrics) {
    if (metrics.maxScrollExtent <= 0) return 0;
    return (metrics.pixels / metrics.maxScrollExtent).clamp(0.0, 1.0);
  }

  /// The background sitting at [offset], [progress] of the way along its
  /// travel.
  _Drift _driftAt(double offset, double progress) => (
        offset: offset,
        scale: scaleOf(widget.zoom, progress),
        sigma: sigmaOf(widget.blur, progress),
      );

  /// The layer under a blur of [sigma], or the layer itself when there is no
  /// blur to apply.
  Widget _blurred(Widget layer, double sigma) {
    if (widget.blur == null) return layer;
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
    final double extent = viewportExtent * widget.parallax.overscan;
    if (extent <= 0) return Alignment.center;
    final double at = 2 * (offset + viewportExtent / 2) / extent - 1;
    return _horizontal ? Alignment(at, 0) : Alignment(0, at);
  }

  /// Follows the content on a scroll, and on a change of its metrics: a resize,
  /// content that grows or shrinks, or an offset restored on the first layout,
  /// none of which scrolls.
  bool _onNotification(Notification notification, double viewportExtent) {
    final ScrollMetrics? metrics = switch (notification) {
      ScrollUpdateNotification(:final ScrollMetrics metrics) => metrics,
      ScrollMetricsNotification(:final ScrollMetrics metrics) => metrics,
      _ => null,
    };
    // Only our own view counts. One nested inside the content, whichever way it
    // runs, says nothing about our travel and must not move the background.
    if (metrics == null ||
        (notification as ViewportNotificationMixin).depth != 0 ||
        metrics.axis != widget.scrollDirection) {
      return false;
    }

    _follow(metrics, viewportExtent);
    // Let the notification keep bubbling: an ancestor may be listening too.
    return false;
  }

  /// Puts the background where [metrics] have the content.
  void _follow(ScrollMetrics metrics, double viewportExtent) {
    _metrics = metrics;
    _viewportExtent = viewportExtent;

    final double progress = _progressFor(metrics);
    // A fraction of the travel spread over the whole scroll, so the background
    // never runs past the overscan it was drawn with.
    final double offset =
        progress * _travelFor(viewportExtent) * widget.parallax.speed;
    if (offset.isFinite) _drift.value = _driftAt(offset, progress);
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
          child: NotificationListener<Notification>(
            onNotification: (Notification notification) =>
                _onNotification(notification, viewportExtent),
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
                            : viewportHeight * widget.parallax.overscan,
                        width: _horizontal
                            ? viewportWidth * widget.parallax.overscan
                            : null,
                        child: _layer,
                      ),
                    ),
                  ),
                ),
                if (widget.overlay != null) OverlayLayer(widget.overlay!),
                _buildContent(),
              ],
            ),
          ),
        );
      },
    );
  }
}
