import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'display_size_image.dart';
import 'live_blur.dart';
import 'overlay_layer.dart';
import 'properties.dart';
import 'smooth_scroll.dart';
import 'travel.dart';

/// A scrolling area whose background image drifts slower than its content.
///
/// The background is drawn at [ParallaxProperties.overscan] times the viewport
/// extent along [scrollDirection] and translated against the content as it
/// scrolls, which is what produces the depth. Only the background repaints
/// while scrolling: no widget is rebuilt, [child] included. When the platform
/// asks for reduced motion the background holds still, unless
/// [respectReducedMotion] is turned off.
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
/// - [decodeAtDisplaySize]: whether [image] is decoded at the size it is
///   drawn rather than at full resolution.
/// - [restorationId], [keyboardDismissBehavior] and [clipBehavior]: handed to
///   the scroll view.
/// - [controller]: an optional [ScrollController] for the scroll view. A
///   [SmoothScrollController] keeps [smooth] on.
/// - [physics]: scroll physics to hand to the scroll view.
/// - [smooth]: whether the mouse wheel is eased in rather than landed in one
///   step. On desktop and the web unless a [controller] other than a
///   [SmoothScrollController] was given; off on iOS and Android unless asked
///   for.
/// - [respectReducedMotion]: whether the background holds still when the
///   platform asks for reduced motion.
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
    this.decodeAtDisplaySize = true,
    this.controller,
    this.physics,
    bool? smooth,
    this.restorationId,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.clipBehavior = Clip.hardEdge,
    this.respectReducedMotion = true,
    super.key,
  })  : slivers = null,
        smooth = smooth ??
            (controller == null || controller is SmoothScrollController),
        _smoothAsked = smooth,
        assert(
          (image == null) != (background == null),
          'pass exactly one of image and background',
        ),
        assert(
          smooth != true ||
              controller == null ||
              controller is SmoothScrollController,
          'smooth needs no controller, or a SmoothScrollController',
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
    this.decodeAtDisplaySize = true,
    this.controller,
    this.physics,
    bool? smooth,
    this.restorationId,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.clipBehavior = Clip.hardEdge,
    this.respectReducedMotion = true,
    super.key,
  })  : child = null,
        smooth = smooth ??
            (controller == null || controller is SmoothScrollController),
        _smoothAsked = smooth,
        assert(
          (image == null) != (background == null),
          'pass exactly one of image and background',
        ),
        assert(
          smooth != true ||
              controller == null ||
              controller is SmoothScrollController,
          'smooth needs no controller, or a SmoothScrollController',
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
  /// On unless a [controller] other than a [SmoothScrollController] was given,
  /// since the easing lives in the position that controller creates; a stepping
  /// background is what a parallax is there to avoid. Passing both `true` and
  /// such a controller is an error rather than a silent no-op. Dragging,
  /// flinging and touch are untouched either way, so this is a mouse and
  /// trackpad setting.
  ///
  /// When the background holds still for reduced motion, a notch lands in one
  /// step too, and only the wheel brought to a horizontal view is left of this.
  ///
  /// Left unset, it is on on desktop and the web, where a mouse wheel is
  /// expected, and off on iOS and Android, where there is none: the easing
  /// needs a controller of the view's own, and a view with a controller is not
  /// the primary one, so a tap on the iOS status bar would no longer scroll it
  /// back to the top. Set it to `true` to ease the wheel there as well. The
  /// value read here is the one asked for, or derived from [controller].
  final bool smooth;

  /// What was passed as [smooth], `null` for the platform to decide.
  final bool? _smoothAsked;

  /// Whether [image] is decoded at the size it is drawn rather than at full
  /// resolution.
  ///
  /// A photo of 4000 by 3000 pixels is otherwise decoded, and held in memory,
  /// at full size whatever the size of the page. The size is worked out from
  /// the viewport, the overscan, the zoom and the pixel density of the screen,
  /// so nothing is lost. Turn it off when the same image is shown elsewhere at
  /// full size and one decoded copy should serve both, and when the image is
  /// warmed up with `precacheImage`: that decodes it at full size, a copy the
  /// page would not use, so it would be decoded again when it first shows. A
  /// [background] widget is
  /// never touched: an [Image] there takes its own `cacheWidth` and
  /// `cacheHeight`.
  final bool decodeAtDisplaySize;

  /// Restoration id handed to the scroll view, so the scroll offset survives
  /// the app being killed and restored.
  final String? restorationId;

  /// Whether a drag dismisses the keyboard, handed to the scroll view. Worth
  /// setting to [ScrollViewKeyboardDismissBehavior.onDrag] over a form.
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  /// How the scroll view clips its content, handed to it.
  final Clip clipBehavior;

  /// Optional controller for the scroll view, for instance to jump back to the
  /// top or to listen to the offset.
  ///
  /// A [SmoothScrollController] keeps the wheel eased; any other controller
  /// turns [smooth] off unless it is asked for, which is then an error.
  final ScrollController? controller;

  /// Scroll physics handed to the scroll view.
  final ScrollPhysics? physics;

  /// Whether the background holds still when the platform asks for reduced
  /// motion, through [MediaQueryData.disableAnimations].
  ///
  /// A background moving against the content is a known trigger for people
  /// with vestibular disorders, which is why the setting exists and why it is
  /// followed by default. The background then stays where it stands at the top
  /// of the page, [zoom] and [blur] included, whatever the scroll.
  final bool respectReducedMotion;

  @override
  State<SimpleParallaxContainer> createState() =>
      _SimpleParallaxContainerState();
}

class _SimpleParallaxContainerState extends State<SimpleParallaxContainer> {
  /// The metrics of the content as last reported, `null` until the view has
  /// laid out. The background paints off them, so this is what repaints it.
  final ValueNotifier<ScrollMetrics?> _metrics =
      ValueNotifier<ScrollMetrics?>(null);

  /// Where the background stands, as the flow last worked it out.
  final TravelProgress _progress = TravelProgress();

  bool get _horizontal => widget.scrollDirection == Axis.horizontal;

  /// The background layer: the caller's widget, or their image wrapped in one.
  ///
  /// Kept out of the semantics tree, whatever it is made of: it is decoration,
  /// and an image left to announce itself would mark the page as one. The
  /// boundary keeps it from being painted again on every scroll: only the
  /// transform over it changes.
  ///
  /// [size] is the layer in logical pixels, which the image is decoded for.
  Widget _layer(Size size, double devicePixelRatio) {
    ImageProvider<Object>? image = widget.image;
    final ZoomProperties? zoom = widget.zoom;
    if (image != null && widget.decodeAtDisplaySize) {
      image = decodedFor(
        image,
        layer: size,
        devicePixelRatio: devicePixelRatio,
        fit: widget.fit,
        zoom: zoom == null ? 1 : 1 + zoom.amount.abs(),
      );
    }
    return RepaintBoundary(
      child: ExcludeSemantics(
        child: widget.background ??
            Image(image: image!, fit: widget.fit, alignment: widget.alignment),
      ),
    );
  }

  @override
  void dispose() {
    _metrics.dispose();
    super.dispose();
  }

  /// Follows the content on a scroll, and on a change of its metrics: a resize,
  /// content that grows or shrinks, or an offset restored on the first layout,
  /// none of which scrolls.
  bool _onNotification(Notification notification) {
    final ScrollMetrics? metrics = switch (notification) {
      ScrollUpdateNotification(:final ScrollMetrics metrics) => metrics,
      ScrollMetricsNotification(:final ScrollMetrics metrics) => metrics,
      _ => null,
    };
    // Only our own view counts. One nested inside the content, whichever way it
    // runs, says nothing about our travel and must not move the background.
    if (metrics != null &&
        (notification as ViewportNotificationMixin).depth == 0 &&
        metrics.axis == widget.scrollDirection) {
      _metrics.value = metrics;
    }
    // Let the notification keep bubbling: an ancestor may be listening too.
    return false;
  }

  /// The scrolling content: the slivers the caller gave us, or the single box
  /// sliver holding [SimpleParallaxContainer.child].
  Widget _buildContent(bool still) {
    final ScrollController? given = widget.controller;
    final bool eased =
        widget.smooth && (widget._smoothAsked ?? easesWheelByDefault);
    // A SmoothScrollController goes through here even when the wheel is not
    // eased, which is what turns its easing off.
    if (eased || given is SmoothScrollController) {
      return SmoothScroll(
        axis: widget.scrollDirection,
        controller: given is SmoothScrollController ? given : null,
        eased: eased && !still,
        builder: (BuildContext context, ScrollController controller) =>
            _scrollView(controller),
      );
    }
    return _scrollView(widget.controller);
  }

  /// The scroll view itself, on whichever controller it was handed.
  Widget _scrollView(ScrollController? controller) => CustomScrollView(
        scrollDirection: widget.scrollDirection,
        controller: controller,
        physics: widget.physics,
        restorationId: widget.restorationId,
        keyboardDismissBehavior: widget.keyboardDismissBehavior,
        clipBehavior: widget.clipBehavior,
        slivers:
            widget.slivers ?? <Widget>[SliverToBoxAdapter(child: widget.child)],
      );

  @override
  Widget build(BuildContext context) {
    final bool still =
        widget.respectReducedMotion && MediaQuery.disableAnimationsOf(context);

    final BlurProperties? blur = widget.blur;
    final double devicePixelRatio = MediaQuery.devicePixelRatioOf(context);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size screen = MediaQuery.sizeOf(context);
        final double viewportHeight = widget.height ??
            (constraints.hasBoundedHeight
                ? constraints.maxHeight
                : screen.height);
        final double viewportWidth = widget.width ??
            (constraints.hasBoundedWidth ? constraints.maxWidth : screen.width);

        final Widget background = _layer(
          _horizontal
              ? Size(viewportWidth * widget.parallax.overscan, viewportHeight)
              : Size(viewportWidth, viewportHeight * widget.parallax.overscan),
          devicePixelRatio,
        );
        final Widget layer = blur == null
            ? background
            : LiveBlur(
                sigma: () => sigmaOf(blur, _progress.value),
                child: background,
              );

        return SizedBox(
          // Only the scrolled axis is pinned; the cross axis keeps whatever the
          // caller gave us.
          height: _horizontal ? widget.height : viewportHeight,
          width: _horizontal ? viewportWidth : widget.width,
          child: NotificationListener<Notification>(
            onNotification: _onNotification,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                RepaintBoundary(
                  child: Flow.unwrapped(
                    delegate: _DriftDelegate(
                      metrics: _metrics,
                      progress: _progress,
                      axis: widget.scrollDirection,
                      parallax: widget.parallax,
                      zoom: widget.zoom,
                      still: still,
                      // A right-to-left page scrolls its content rightwards.
                      reversed: axisDirectionIsReversed(
                        getAxisDirectionFromAxisReverseAndDirectionality(
                          context,
                          widget.scrollDirection,
                          false,
                        ),
                      ),
                    ),
                    children: <Widget>[layer],
                  ),
                ),
                if (widget.overlay != null) OverlayLayer(widget.overlay!),
                _buildContent(still),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Places the background behind the viewport according to how far down the page
/// the content has scrolled.
///
/// Repainting is bound to the metrics of the content rather than to a rebuild,
/// so a scroll costs one paint of the background and no widget work at all.
/// The progress is worked out once here and left in [progress] for a blur
/// painted inside the flow.
class _DriftDelegate extends FlowDelegate {
  _DriftDelegate({
    required this.metrics,
    required this.progress,
    required this.axis,
    required this.parallax,
    required this.zoom,
    required this.still,
    required this.reversed,
  }) : super(repaint: still ? null : metrics);

  final ValueListenable<ScrollMetrics?> metrics;
  final TravelProgress progress;
  final Axis axis;
  final ParallaxProperties parallax;
  final ZoomProperties? zoom;

  /// Whether the background is held at the top of its travel.
  final bool still;

  /// Whether the content moves right or down as it scrolls, as on a
  /// right-to-left page, rather than left or up.
  final bool reversed;

  bool get _horizontal => axis == Axis.horizontal;

  /// The layer is the viewport on the cross axis and the overscan times it on
  /// the scrolled axis, both tight.
  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) =>
      _horizontal
          ? BoxConstraints.tightFor(
              width: constraints.maxWidth * parallax.overscan,
              height: constraints.maxHeight,
            )
          : BoxConstraints.tightFor(
              width: constraints.maxWidth,
              height: constraints.maxHeight * parallax.overscan,
            );

  @override
  void paintChildren(FlowPaintingContext context) {
    // From `0` at the top of the page to `1` at the bottom.
    final ScrollMetrics? scrolled = metrics.value;
    final double at = still || scrolled == null || scrolled.maxScrollExtent <= 0
        ? 0
        : (scrolled.pixels / scrolled.maxScrollExtent).clamp(0.0, 1.0);
    progress.value = at;

    final Size viewport = context.size;
    final double extent = _horizontal ? viewport.width : viewport.height;
    // A fraction of the travel spread over the whole scroll, so the background
    // never runs past the overscan it was drawn with.
    final double offset =
        at * extent * (parallax.overscan - 1) * parallax.speed;
    if (!offset.isFinite) {
      context.paintChild(0);
      return;
    }

    // The background follows the content: it starts against the end the
    // content comes from and moves the way the content does.
    final Size layer = context.getChildSize(0) ?? viewport;
    final double move = reversed
        ? (_horizontal
                ? viewport.width - layer.width
                : viewport.height - layer.height) +
            offset
        : -offset;

    context.paintChild(
      0,
      transform: placed(
        _horizontal ? Offset(move, 0) : Offset(0, move),
        scaleOf(zoom, at),
        viewport.center(Offset.zero),
      ),
    );
  }

  @override
  bool shouldRepaint(_DriftDelegate oldDelegate) =>
      metrics != oldDelegate.metrics ||
      axis != oldDelegate.axis ||
      parallax != oldDelegate.parallax ||
      zoom != oldDelegate.zoom ||
      still != oldDelegate.still ||
      reversed != oldDelegate.reversed;
}
