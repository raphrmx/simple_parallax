import 'package:flutter/widgets.dart';

/// A scrolling area whose background image drifts slower than its content.
///
/// The background is drawn at [overscan] times the viewport height and
/// translated up as the content scrolls, which is what produces the depth.
/// Only the background repaints while scrolling: [child] is built once and
/// reused across frames.
///
/// ---
///
/// ### Parameters:
/// - [image]: any [ImageProvider], so an asset, a network image, a file or
///   raw bytes all work.
/// - [child]: the scrolling content, laid out in a [SingleChildScrollView].
/// - [speed]: how far the background moves per pixel scrolled. `0` pins it,
///   `1` makes it follow the content exactly. Ignored when [autoSpeed] is set.
/// - [autoSpeed]: derives the speed from the real scroll extent, so the
///   background uses exactly the travel [overscan] gives it and no more.
/// - [overscan]: how much taller than the viewport the background is drawn.
///   Must be at least `1`; at exactly `1` there is no travel, so no effect.
/// - [height]: forces the viewport height instead of taking it from the
///   incoming constraints.
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
class SimpleParallaxContainer extends StatefulWidget {
  /// Creates a parallax container.
  const SimpleParallaxContainer({
    required this.image,
    required this.child,
    this.speed = 0.3,
    this.autoSpeed = false,
    this.overscan = 1.5,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    super.key,
  }) : assert(overscan >= 1, 'overscan must be at least 1');

  /// Background image.
  final ImageProvider image;

  /// Scrolling content.
  final Widget child;

  /// Background travel per pixel scrolled. Ignored when [autoSpeed] is set.
  final double speed;

  /// Whether the speed is derived from the actual scroll extent.
  final bool autoSpeed;

  /// How much taller than the viewport the background is drawn.
  final double overscan;

  /// Forced viewport height, or `null` to use the incoming constraints.
  final double? height;

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

  @override
  void dispose() {
    _offset.dispose();
    super.dispose();
  }

  /// Travel the background has available before its bottom edge would show.
  double _travelFor(double viewportHeight) =>
      viewportHeight * (widget.overscan - 1);

  double _speedFor(ScrollMetrics metrics) {
    if (!widget.autoSpeed) return widget.speed;
    if (metrics.maxScrollExtent <= 0) return 0;
    return _travelFor(metrics.viewportDimension) / metrics.maxScrollExtent;
  }

  bool _onScroll(ScrollUpdateNotification notification, double viewportHeight) {
    final double travel = _travelFor(viewportHeight);
    final double value =
        notification.metrics.pixels * _speedFor(notification.metrics);
    if (value.isFinite) {
      // Clamped so the background never travels past the overscan it was drawn
      // with, which would uncover its bottom edge.
      _offset.value = value.clamp(0, travel <= 0 ? 0 : travel);
    }
    // Let the notification keep bubbling: an ancestor may be listening too.
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double viewportHeight = widget.height ??
            (constraints.hasBoundedHeight
                ? constraints.maxHeight
                : MediaQuery.sizeOf(context).height);

        return SizedBox(
          height: viewportHeight,
          child: NotificationListener<ScrollUpdateNotification>(
            onNotification: (ScrollUpdateNotification notification) =>
                _onScroll(notification, viewportHeight),
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
                        alignment: Alignment.topCenter,
                        minHeight: 0,
                        maxHeight: double.infinity,
                        child: Transform.translate(
                          offset: Offset(0, -offset),
                          child: background,
                        ),
                      ),
                      child: SizedBox(
                        height: viewportHeight * widget.overscan,
                        child: Image(
                          image: widget.image,
                          fit: widget.fit,
                          alignment: widget.alignment,
                        ),
                      ),
                    ),
                  ),
                ),
                SingleChildScrollView(child: widget.child),
              ],
            ),
          ),
        );
      },
    );
  }
}
