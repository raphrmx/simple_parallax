import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'travel.dart';

/// A fixed-extent block whose background image slides as the block crosses the
/// viewport.
///
/// The item finds the enclosing [Scrollable] on its own, so it works inside a
/// [ListView], a [CustomScrollView], a `SimpleParallaxWidget` or any other
/// scrollable. It also takes its axis from that scrollable, so the background
/// slides sideways in a horizontal list and downwards in a vertical one with
/// nothing to pass. Painting is driven straight off the scroll position, so
/// scrolling repaints the background without rebuilding a single widget, [child]
/// included.
///
/// Outside a scrollable the background is simply drawn still, which is what you
/// want for a preview or a test.
///
/// The background is either an [image] or a [background] widget, never both. The
/// widget form is what you want for a gradient, a video, a shader, a blurred or
/// tinted image, a cached network image, or for the [Image] parameters this
/// widget does not forward, `loadingBuilder`, `errorBuilder` and `cacheHeight`
/// among them.
///
/// ---
///
/// ### Parameters:
/// - [image]: any [ImageProvider], so an asset, a network image, a file or
///   raw bytes all work.
/// - [background]: the background layer as a widget, in place of [image].
/// - [child]: content drawn over the background, for instance a caption.
/// - [speed]: fraction of the available travel the background uses, from `0`
///   (pinned) to `1` (the whole [overscan]).
/// - [overscan]: how much larger than the item the background is drawn along
///   the scroll axis. Must be at least `1`; at exactly `1` there is no travel,
///   so no drift, though a [zoom] still works there. It raises the height
///   `BoxFit.cover` fits to, so it changes the framing only where that height
///   is what `cover` is scaling by.
/// - [height]: item height. Defaults to the screen height in a vertical
///   scrollable, and to the incoming constraints in a horizontal one.
/// - [width]: item width. Defaults to the incoming constraints in a vertical
///   scrollable, and to the screen width in a horizontal one.
/// - [zoom]: scale the background gains as the block crosses the viewport, `0`
///   for none.
/// - [blur]: gaussian blur in logical pixels the background gains as the block
///   crosses the viewport, `0` for none.
/// - [reach]: where along the crossing [zoom] and [blur] are done, `null` to
///   spread them over the whole of it.
/// - [back]: whether they come back from there rather than holding.
/// - [fit]: how the background fills its layer. Applies to [image] only: a
///   [background] widget is laid out to fill the layer as it stands.
///
/// ### Example:
/// ```dart
/// ListView(
///   children: const <Widget>[
///     SimpleParallaxItem(
///       image: NetworkImage('https://example.com/a.jpg'),
///       height: 300,
///       child: Center(child: Text('Chapter one')),
///     ),
///   ],
/// );
/// ```
///
/// The same item in a horizontal list, where it slides sideways:
/// ```dart
/// ListView(
///   scrollDirection: Axis.horizontal,
///   children: const <Widget>[
///     SimpleParallaxItem(
///       image: NetworkImage('https://example.com/a.jpg'),
///       width: 300,
///       child: Center(child: Text('Chapter one')),
///     ),
///   ],
/// );
/// ```
///
/// A gradient behind the block instead of an image:
/// ```dart
/// SimpleParallaxItem(
///   height: 300,
///   background: const DecoratedBox(
///     decoration: BoxDecoration(
///       gradient: LinearGradient(
///         begin: Alignment.topCenter,
///         end: Alignment.bottomCenter,
///         colors: <Color>[Color(0xFF1A237E), Color(0xFF80DEEA)],
///       ),
///     ),
///   ),
/// );
/// ```
class SimpleParallaxItem extends StatefulWidget {
  /// Creates a parallax item, given either an [image] or a [background].
  const SimpleParallaxItem({
    this.image,
    this.background,
    this.child,
    this.speed = 1.0,
    this.overscan = 1.5,
    this.height,
    this.width,
    this.zoom = 0,
    this.blur = 0,
    this.reach,
    this.back = false,
    this.fit = BoxFit.cover,
    super.key,
  })  : assert(overscan >= 1, 'overscan must be at least 1'),
        assert(
          reach == null || (reach >= 0 && reach <= 1),
          'reach is a fraction of the crossing, so between 0 and 1',
        ),
        assert(!back || reach != null, 'back needs a reach to come back from'),
        assert(speed >= 0 && speed <= 1, 'speed must be between 0 and 1'),
        assert(
          (image == null) != (background == null),
          'pass exactly one of image and background',
        );

  /// Background image, or `null` when a [background] was given instead.
  final ImageProvider? image;

  /// Background layer, or `null` when an [image] was given instead.
  ///
  /// The layer is given the item extent on the cross axis and [overscan] times
  /// it on the scrolled axis, with both axes tight, so anything that fills the
  /// box it is handed works: a `DecoratedBox` holding a gradient, an [Image] the
  /// caller configured, a `Stack` of several layers, a video.
  final Widget? background;

  /// Content drawn over the background.
  final Widget? child;

  /// Fraction of the available travel the background uses.
  final double speed;

  /// How much larger than the item the background is drawn along the scroll
  /// axis.
  final double overscan;

  /// Item height, or `null` for the screen height in a vertical scrollable and
  /// the incoming constraints in a horizontal one.
  final double? height;

  /// Item width, or `null` for the incoming constraints in a vertical
  /// scrollable and the screen width in a horizontal one.
  final double? width;

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
  /// range backwards: `-8` starts at eight and clears as the block leaves.
  ///
  /// The layer is blurred before [zoom] scales it, so a zoom carries the blur
  /// along with everything else.
  ///
  /// This one is a filter rather than a transform, so it costs more than the
  /// drift and the zoom: the layer is blurred again on each frame it moves. The
  /// sigma is rounded to a quarter of a pixel, so the filter is left alone for
  /// changes no one can see.
  final double blur;

  /// Where along the crossing [zoom] and [blur] are done, `null` to spread them
  /// over the whole of it.
  ///
  /// `0.5` is the middle of the viewport, so the effect is finished as the
  /// block passes the eye. It then holds at its far end for the rest of the
  /// crossing, or comes back the way it went when [back] is set.
  ///
  /// The drift is not shaped by this. It follows the scroll whatever is set
  /// here, since a background that walked back up the block would read as the
  /// list scrolling the other way.
  final double? reach;

  /// Whether [zoom] and [blur] come back from [reach] rather than holding
  /// there.
  ///
  /// A zoom then pushes in and backs out again over one crossing, and a
  /// negative blur arrives soft, clears as the block passes the eye and goes
  /// soft again.
  final bool back;

  /// How the background fills its layer. Applies to [image] only: a [background]
  /// widget fills the layer as it stands.
  final BoxFit fit;

  @override
  State<SimpleParallaxItem> createState() => _SimpleParallaxItemState();
}

class _SimpleParallaxItemState extends State<SimpleParallaxItem> {
  final GlobalKey _backgroundKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final ScrollableState? scrollable = Scrollable.maybeOf(context);
    final Axis axis = scrollable?.position.axis ?? Axis.vertical;
    final bool horizontal = axis == Axis.horizontal;
    final Size screen = MediaQuery.sizeOf(context);

    // The scrolled axis has to be known to size the overscan; the cross axis is
    // happy to come from the constraints.
    final double? height = widget.height ?? (horizontal ? null : screen.height);
    final double? width = widget.width ?? (horizontal ? screen.width : null);

    final Widget layer =
        widget.background ?? Image(image: widget.image!, fit: widget.fit);

    Widget background = SizedBox(
      key: _backgroundKey,
      height: horizontal ? null : height! * widget.overscan,
      width: horizontal ? width! * widget.overscan : null,
      child: layer,
    );

    if (widget.blur != 0 && scrollable != null) {
      background = _ScrollBlur(
        scrollable: scrollable,
        itemContext: context,
        axis: axis,
        blur: widget.blur,
        reach: widget.reach,
        back: widget.back,
        child: background,
      );
    }

    return SizedBox(
      height: height,
      width: width,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          RepaintBoundary(
            child: ClipRect(
              child: scrollable == null
                  ? background
                  : Flow(
                      delegate: _ParallaxFlowDelegate(
                        scrollable: scrollable,
                        itemContext: context,
                        backgroundKey: _backgroundKey,
                        speed: widget.speed,
                        zoom: widget.zoom,
                        reach: widget.reach,
                        back: widget.back,
                        axis: axis,
                      ),
                      children: <Widget>[background],
                    ),
            ),
          ),
          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }
}

/// How far the block has come, from `0` the moment its leading edge appears at
/// one end of the viewport to `1` the moment its trailing edge leaves at the
/// other.
///
/// That is `viewport + extent` of scrolling. Measuring the middle of the block
/// against the viewport alone would leave the effect standing still for half of
/// it, once on the way in and once on the way out.
///
/// `null` while there is no geometry to measure against.
double? _progressOf(
  ScrollableState scrollable,
  BuildContext itemContext,
  Axis axis,
) {
  final RenderObject? scrollBox = scrollable.context.findRenderObject();
  final RenderObject? itemBox = itemContext.findRenderObject();
  if (scrollBox is! RenderBox ||
      itemBox is! RenderBox ||
      !scrollBox.hasSize ||
      !itemBox.hasSize) {
    return null;
  }

  final double viewport = scrollable.position.viewportDimension;
  final bool horizontal = axis == Axis.horizontal;
  final double extent = horizontal ? itemBox.size.width : itemBox.size.height;
  final double span = viewport + extent;
  if (viewport <= 0 || span <= 0) return null;

  final Offset itemOffset = itemBox.localToGlobal(
    horizontal
        ? itemBox.size.topCenter(Offset.zero)
        : itemBox.size.centerLeft(Offset.zero),
    ancestor: scrollBox,
  );
  final double travelled = horizontal ? itemOffset.dx : itemOffset.dy;
  return ((viewport + extent / 2 - travelled) / span).clamp(0.0, 1.0);
}

/// Blurs its child by an amount that follows the block across the viewport.
///
/// A filter is a layer, so it cannot be handed to the [Flow] that places the
/// background. This pushes its own from inside that flow, which repaints it on
/// every scroll, and reads the geometry there rather than from a listener,
/// where it would still be the geometry of the frame before.
class _ScrollBlur extends SingleChildRenderObjectWidget {
  const _ScrollBlur({
    required this.scrollable,
    required this.itemContext,
    required this.axis,
    required this.blur,
    required this.reach,
    required this.back,
    required Widget super.child,
  });

  final ScrollableState scrollable;
  final BuildContext itemContext;
  final Axis axis;
  final double blur;
  final double? reach;
  final bool back;

  @override
  _RenderScrollBlur createRenderObject(BuildContext context) =>
      _RenderScrollBlur(
        scrollable: scrollable,
        itemContext: itemContext,
        axis: axis,
        blur: blur,
        reach: reach,
        back: back,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderScrollBlur renderObject,
  ) {
    renderObject
      ..scrollable = scrollable
      ..itemContext = itemContext
      ..axis = axis
      ..blur = blur
      ..reach = reach
      ..back = back;
  }
}

class _RenderScrollBlur extends RenderProxyBox {
  _RenderScrollBlur({
    required ScrollableState scrollable,
    required BuildContext itemContext,
    required Axis axis,
    required double blur,
    required double? reach,
    required bool back,
  })  : _scrollable = scrollable,
        _itemContext = itemContext,
        _axis = axis,
        _blur = blur,
        _reach = reach,
        _back = back;

  ScrollableState _scrollable;

  set scrollable(ScrollableState value) {
    if (value == _scrollable) return;
    if (attached) _scrollable.position.removeListener(markNeedsPaint);
    _scrollable = value;
    if (attached) _scrollable.position.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  BuildContext _itemContext;

  set itemContext(BuildContext value) {
    if (value == _itemContext) return;
    _itemContext = value;
    markNeedsPaint();
  }

  Axis _axis;

  set axis(Axis value) {
    if (value == _axis) return;
    _axis = value;
    markNeedsPaint();
  }

  double _blur;

  set blur(double value) {
    if (value == _blur) return;
    _blur = value;
    markNeedsPaint();
  }

  double? _reach;

  set reach(double? value) {
    if (value == _reach) return;
    _reach = value;
    markNeedsPaint();
  }

  bool _back;

  set back(bool value) {
    if (value == _back) return;
    _back = value;
    markNeedsPaint();
  }

  final LayerHandle<ImageFilterLayer> _filter = LayerHandle<ImageFilterLayer>();

  @override
  bool get alwaysNeedsCompositing => child != null;

  /// [Flow] wraps each of its children in a [RepaintBoundary], so a scroll
  /// moves the layer under it without painting it again. The sigma is read at
  /// paint, so that paint has to be asked for.
  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _scrollable.position.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _scrollable.position.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void dispose() {
    _filter.layer = null;
    super.dispose();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final double? progress = _progressOf(_scrollable, _itemContext, _axis);
    final double sigma = sigmaFor(shaped(progress ?? 0, _reach, _back), _blur);
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

/// Places the background inside the item according to how far the item has
/// travelled across the viewport.
///
/// Repainting is bound to the scroll position rather than to a rebuild, so a
/// scroll costs one paint and no widget work at all.
class _ParallaxFlowDelegate extends FlowDelegate {
  _ParallaxFlowDelegate({
    required this.scrollable,
    required this.itemContext,
    required this.backgroundKey,
    required this.speed,
    required this.zoom,
    required this.reach,
    required this.back,
    required this.axis,
  }) : super(repaint: scrollable.position);

  final ScrollableState scrollable;
  final BuildContext itemContext;
  final GlobalKey backgroundKey;
  final double speed;
  final double zoom;
  final double? reach;
  final bool back;
  final Axis axis;

  bool get _horizontal => axis == Axis.horizontal;

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) =>
      _horizontal
          ? BoxConstraints.tightFor(height: constraints.maxHeight)
          : BoxConstraints.tightFor(width: constraints.maxWidth);

  @override
  void paintChildren(FlowPaintingContext context) {
    final RenderObject? itemBox = itemContext.findRenderObject();
    final RenderObject? backgroundBox =
        backgroundKey.currentContext?.findRenderObject();
    final double? progress = _progressOf(scrollable, itemContext, axis);

    if (progress == null ||
        itemBox is! RenderBox ||
        backgroundBox is! RenderBox ||
        !backgroundBox.hasSize) {
      // Nothing to measure against yet; draw the background where it stands so
      // the first frame is not blank.
      context.paintChild(0);
      return;
    }

    final double shift = (1 - 2 * progress) * speed;
    final Alignment alignment =
        _horizontal ? Alignment(shift, 0) : Alignment(0, shift);
    final Rect childRect = alignment.inscribe(
      backgroundBox.size,
      Offset.zero & itemBox.size,
    );

    final Offset placement =
        _horizontal ? Offset(childRect.left, 0) : Offset(0, childRect.top);
    final Matrix4 transform = Matrix4.translationValues(
      placement.dx,
      placement.dy,
      0,
    );

    if (zoom != 0) {
      // Turned about the middle of the block, which is where the eye is, and
      // applied after the placement so the drift is not scaled with it.
      final Offset about = itemBox.size.center(Offset.zero) - placement;
      final double scale = scaleFor(shaped(progress, reach, back), zoom);
      transform
        ..translateByDouble(about.dx, about.dy, 0, 1)
        ..scaleByDouble(scale, scale, 1, 1)
        ..translateByDouble(-about.dx, -about.dy, 0, 1);
    }

    context.paintChild(0, transform: transform);
  }

  @override
  bool shouldRepaint(_ParallaxFlowDelegate oldDelegate) =>
      scrollable != oldDelegate.scrollable ||
      itemContext != oldDelegate.itemContext ||
      backgroundKey != oldDelegate.backgroundKey ||
      speed != oldDelegate.speed ||
      zoom != oldDelegate.zoom ||
      reach != oldDelegate.reach ||
      back != oldDelegate.back ||
      axis != oldDelegate.axis;
}
