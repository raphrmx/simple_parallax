import 'package:flutter/widgets.dart';

/// A scrolling area whose background image drifts slower than its content.
///
/// The background is drawn at [overscan] times the viewport extent along
/// [scrollDirection] and translated against the content as it scrolls, which is
/// what produces the depth. Only the background repaints while scrolling:
/// [child] is built once and reused across frames.
///
/// ---
///
/// ### Parameters:
/// - [image]: any [ImageProvider], so an asset, a network image, a file or
///   raw bytes all work.
/// - [child]: the scrolling content, laid out in a [SingleChildScrollView].
/// - [scrollDirection]: the axis the content scrolls along, and therefore the
///   axis the background drifts along.
/// - [speed]: how far the background moves per pixel scrolled. `0` pins it,
///   `1` makes it follow the content exactly. Ignored when [autoSpeed] is set.
/// - [autoSpeed]: derives the speed from the real scroll extent, so the
///   background uses exactly the travel [overscan] gives it and no more.
/// - [overscan]: how much larger than the viewport the background is drawn
///   along [scrollDirection]. Must be at least `1`; at exactly `1` there is no
///   travel, so no effect.
/// - [height]: forces the viewport height instead of taking it from the
///   incoming constraints.
/// - [width]: forces the viewport width instead of taking it from the incoming
///   constraints.
/// - [fit]: how the background fills its layer.
/// - [alignment]: how the background is aligned inside its layer.
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
class SimpleParallaxContainer extends StatefulWidget {
  /// Creates a parallax container.
  const SimpleParallaxContainer({
    required this.image,
    required this.child,
    this.scrollDirection = Axis.vertical,
    this.speed = 0.3,
    this.autoSpeed = false,
    this.overscan = 1.5,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    super.key,
  }) : assert(overscan >= 1, 'overscan must be at least 1');

  /// Background image.
  final ImageProvider image;

  /// Scrolling content.
  final Widget child;

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

  /// How the background fills its layer.
  final BoxFit fit;

  /// How the background is aligned inside its layer.
  final Alignment alignment;

  @override
  State<SimpleParallaxContainer> createState() =>
      _SimpleParallaxContainerState();
}

class _SimpleParallaxContainerState extends State<SimpleParallaxContainer> {
  final ValueNotifier<double> _offset = ValueNotifier<double>(0);

  bool get _horizontal => widget.scrollDirection == Axis.horizontal;

  @override
  void dispose() {
    _offset.dispose();
    super.dispose();
  }

  /// Travel the background has available before its trailing edge would show.
  double _travelFor(double viewportExtent) =>
      viewportExtent * (widget.overscan - 1);

  double _speedFor(ScrollMetrics metrics) {
    if (!widget.autoSpeed) return widget.speed;
    if (metrics.maxScrollExtent <= 0) return 0;
    return _travelFor(metrics.viewportDimension) / metrics.maxScrollExtent;
  }

  bool _onScroll(ScrollUpdateNotification notification, double viewportExtent) {
    // A scrollable nested the other way round says nothing about our own
    // travel, so it must not move the background.
    if (notification.metrics.axis != widget.scrollDirection) return false;

    final double travel = _travelFor(viewportExtent);
    final double value =
        notification.metrics.pixels * _speedFor(notification.metrics);
    if (value.isFinite) {
      // Clamped so the background never travels past the overscan it was drawn
      // with, which would uncover its trailing edge.
      _offset.value = value.clamp(0, travel <= 0 ? 0 : travel);
    }
    // Let the notification keep bubbling: an ancestor may be listening too.
    return false;
  }

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
                    child: ValueListenableBuilder<double>(
                      valueListenable: _offset,
                      builder: (
                        BuildContext context,
                        double offset,
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
                              ? Offset(-offset, 0)
                              : Offset(0, -offset),
                          child: background,
                        ),
                      ),
                      child: SizedBox(
                        height: _horizontal
                            ? null
                            : viewportHeight * widget.overscan,
                        width: _horizontal
                            ? viewportWidth * widget.overscan
                            : null,
                        child: Image(
                          image: widget.image,
                          fit: widget.fit,
                          alignment: widget.alignment,
                        ),
                      ),
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: widget.scrollDirection,
                  child: widget.child,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
