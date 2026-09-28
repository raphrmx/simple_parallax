import 'package:flutter/widgets.dart';

import 'display_size_image.dart';
import 'live_blur.dart';
import 'overlay_layer.dart';
import 'properties.dart';
import 'travel.dart';

/// A fixed-extent block whose background image slides as the block crosses the
/// viewport.
///
/// The item finds the enclosing [Scrollable] on its own, so it works inside a
/// [ListView], a [CustomScrollView], a `SimpleParallaxWidget` or any other
/// scrollable. It also takes its axis from that scrollable, so the background
/// slides sideways in a horizontal list and downwards in a vertical one with
/// nothing to pass. Inside a scrollable nested in another, [scrollAxis] picks
/// which one to follow. Painting is driven straight off the scroll position, so
/// scrolling repaints the background without rebuilding a single widget, [child]
/// included.
///
/// Outside a scrollable the background is simply drawn still, which is what you
/// want for a preview or a test. It is drawn still too when the platform asks
/// for reduced motion, unless [respectReducedMotion] is turned off.
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
/// - [parallax]: how the background drifts, its speed and its overscan.
/// - [zoom]: how it scales as it crosses, `null` for not at all.
/// - [blur]: how it is blurred as it crosses, `null` for not at all.
/// - [overlay]: a fixed tint over the background and under [child], `null` for
///   none.
/// - [height]: item height. Defaults to the screen height in a vertical
///   scrollable, and to the incoming constraints in a horizontal one.
/// - [width]: item width. Defaults to the incoming constraints in a vertical
///   scrollable, and to the screen width in a horizontal one.
/// - [fit]: how the background fills its layer. Applies to [image] only: a
///   [background] widget is laid out to fill the layer as it stands.
/// - [alignment]: how the background sits inside its layer. Applies to [image]
///   only.
/// - [borderRadius]: rounds the corners of the block, `null` for square ones.
/// - [decodeAtDisplaySize]: whether [image] is decoded at the size it is drawn
///   rather than at full resolution.
/// - [scrollAxis]: the axis of the scrollable to follow, `null` for the
///   nearest one.
/// - [respectReducedMotion]: whether the background holds still when the
///   platform asks for reduced motion.
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
/// A block in a horizontal carousel that follows the vertical page around it
/// rather than the carousel:
/// ```dart
/// SimpleParallaxItem(
///   image: NetworkImage('https://example.com/a.jpg'),
///   width: 300,
///   scrollAxis: Axis.vertical,
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
class SimpleParallaxItem extends StatelessWidget {
  /// Creates a parallax item, given either an [image] or a [background].
  const SimpleParallaxItem({
    this.image,
    this.background,
    this.child,
    this.parallax = const ParallaxProperties(),
    this.zoom,
    this.blur,
    this.overlay,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.borderRadius,
    this.decodeAtDisplaySize = true,
    this.scrollAxis,
    this.respectReducedMotion = true,
    super.key,
  }) : assert(
          (image == null) != (background == null),
          'pass exactly one of image and background',
        );

  /// Background image, or `null` when a [background] was given instead.
  final ImageProvider? image;

  /// Background layer, or `null` when an [image] was given instead.
  ///
  /// The layer is given the item extent on the cross axis and the overscan
  /// times it on the scrolled axis, with both axes tight, so anything that
  /// fills the box it is handed works: a `DecoratedBox` holding a gradient, an
  /// [Image] the caller configured, a `Stack` of several layers, a video.
  final Widget? background;

  /// Content drawn over the background.
  final Widget? child;

  /// How the background drifts as the block crosses the viewport.
  final ParallaxProperties parallax;

  /// How the background scales as the block crosses, `null` for not at all.
  final ZoomProperties? zoom;

  /// How the background is blurred as the block crosses, `null` for not at all.
  ///
  /// The layer is blurred before [zoom] scales it, so a zoom carries the blur
  /// along with everything else.
  final BlurProperties? blur;

  /// A fixed tint over the background, `null` for none.
  ///
  /// It is drawn over the background and under [child], and it does not move
  /// with the background.
  final OverlayProperties? overlay;

  /// Item height, or `null` for the screen height in a vertical scrollable and
  /// the incoming constraints in a horizontal one. The scrollable meant is the
  /// nearest, the one laying the item out, whatever [scrollAxis] follows.
  final double? height;

  /// Item width, or `null` for the incoming constraints in a vertical
  /// scrollable and the screen width in a horizontal one.
  final double? width;

  /// How the background fills its layer. Applies to [image] only: a [background]
  /// widget fills the layer as it stands.
  final BoxFit fit;

  /// How the background sits inside its layer, for instance
  /// `Alignment.topCenter` to keep the top of a portrait in the frame. Applies
  /// to [image] only.
  final Alignment alignment;

  /// Rounds the corners of the block, `null` for square ones.
  ///
  /// Everything is clipped to it, the background, the overlay and [child]
  /// alike, which is what a card wants.
  final BorderRadiusGeometry? borderRadius;

  /// Whether [image] is decoded at the size it is drawn rather than at full
  /// resolution.
  ///
  /// A photo of 4000 by 3000 pixels in a block of 300 is otherwise decoded, and
  /// held in memory, at full size, which in a list of photos costs far more
  /// than the parallax does. The size is worked out from the block, the
  /// overscan, the zoom and the pixel density of the screen, so nothing is
  /// lost. Turn it off when the same image is shown elsewhere at full size and
  /// one decoded copy should serve both, and when the image is warmed up with
  /// `precacheImage`: that decodes it at full size, a copy the block would not
  /// use, so it would be decoded again when it first shows. A [background]
  /// widget is never
  /// touched: an [Image] there takes its own `cacheWidth` and `cacheHeight`.
  final bool decodeAtDisplaySize;

  /// The axis of the scrollable the background follows, or `null` for the
  /// nearest scrollable, whichever way it runs.
  ///
  /// Only needed when scrollables are nested. A block in a horizontal carousel
  /// inside a vertical page follows the carousel by default and slides
  /// sideways; `Axis.vertical` has it follow the page instead, and slide
  /// downwards as the page scrolls. With no scrollable on that axis above it,
  /// the background is drawn still.
  final Axis? scrollAxis;

  /// Whether the background holds still when the platform asks for reduced
  /// motion, through [MediaQueryData.disableAnimations].
  ///
  /// A background moving against the content is a known trigger for people
  /// with vestibular disorders, which is why the setting exists and why it is
  /// followed by default. The block is then drawn as it looks in the middle of
  /// the viewport: background centred, [zoom] and [blur] at their mid-crossing
  /// values, none of it changing with the scroll.
  final bool respectReducedMotion;

  @override
  Widget build(BuildContext context) {
    // The nearest scrollable lays the block out, so it settles the defaults;
    // the one followed may be further up.
    final ScrollableState? nearest = Scrollable.maybeOf(context);
    final ScrollableState? followed = scrollAxis == null
        ? nearest
        : Scrollable.maybeOf(context, axis: scrollAxis);
    final bool laidOutSideways = nearest?.position.axis == Axis.horizontal;
    final Size screen = MediaQuery.sizeOf(context);
    final bool still =
        respectReducedMotion && MediaQuery.disableAnimationsOf(context);

    // The scrolled axis cannot come from the constraints, which are unbounded
    // along it; the cross axis is happy to.
    final double? height =
        this.height ?? (laidOutSideways ? null : screen.height);
    final double? width = this.width ?? (laidOutSideways ? screen.width : null);

    final ZoomProperties? zoom = this.zoom;
    final double devicePixelRatio = MediaQuery.devicePixelRatioOf(context);

    // The layer, sized along the axis followed.
    Widget layerIn(Size block) {
      ImageProvider<Object>? image = this.image;
      if (image != null && decodeAtDisplaySize) {
        final bool drift = followed != null;
        final bool sideways = followed?.position.axis == Axis.horizontal;
        image = decodedFor(
          image,
          layer: Size(
            block.width * (drift && sideways ? parallax.overscan : 1),
            block.height * (drift && !sideways ? parallax.overscan : 1),
          ),
          devicePixelRatio: devicePixelRatio,
          fit: fit,
          zoom: zoom == null ? 1 : 1 + zoom.amount.abs(),
        );
      }

      // Decoration, whatever it is made of: left to announce itself, an image
      // would mark the block and everything in [child] as one. The boundary
      // keeps it from being painted again on every scroll: only the transform
      // over it changes.
      return RepaintBoundary(
        child: ExcludeSemantics(
          child: background ??
              Image(image: image!, fit: fit, alignment: alignment),
        ),
      );
    }

    // Laid out rather than built, so the decode size can follow the block.
    final Widget painted = LayoutBuilder(
      builder: (BuildContext _, BoxConstraints constraints) {
        final Widget layer = layerIn(constraints.biggest);
        if (followed == null) return layer;

        final TravelProgress progress = TravelProgress();
        final BlurProperties? blur = this.blur;
        return Flow.unwrapped(
          delegate: _ParallaxFlowDelegate(
            scrollable: followed,
            itemContext: context,
            progress: progress,
            parallax: parallax,
            zoom: zoom,
            still: still,
          ),
          children: <Widget>[
            if (blur == null)
              layer
            else
              LiveBlur(
                sigma: () => sigmaOf(blur, progress.value),
                child: layer,
              ),
          ],
        );
      },
    );

    final Widget block = Stack(
      fit: StackFit.expand,
      children: <Widget>[
        RepaintBoundary(child: ClipRect(child: painted)),
        if (overlay != null) OverlayLayer(overlay!),
        if (child != null) child!,
      ],
    );

    final BorderRadiusGeometry? borderRadius = this.borderRadius;
    return SizedBox(
      height: height,
      width: width,
      child: borderRadius == null
          ? block
          : ClipRRect(borderRadius: borderRadius, child: block),
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
/// The ends are those of the scroll, not of the screen: a right-to-left list or
/// a reversed one brings the block in from the left or from the top.
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
  final double along = horizontal ? itemOffset.dx : itemOffset.dy;
  final double travelled = axisDirectionIsReversed(scrollable.axisDirection)
      ? viewport - along
      : along;
  return ((viewport + extent / 2 - travelled) / span).clamp(0.0, 1.0);
}

/// The progress a block is drawn at when it holds still: the middle of its
/// crossing, which is how it looks once it is in view.
const double _still = 0.5;

/// Places the background inside the item according to how far the item has
/// travelled across the viewport.
///
/// Repainting is bound to the scroll position rather than to a rebuild, so a
/// scroll costs one paint and no widget work at all. The progress is measured
/// once here and left in [progress] for a blur painted inside the flow.
class _ParallaxFlowDelegate extends FlowDelegate {
  _ParallaxFlowDelegate({
    required this.scrollable,
    required this.itemContext,
    required this.progress,
    required this.parallax,
    required this.zoom,
    required this.still,
  }) : super(repaint: still ? null : scrollable.position);

  final ScrollableState scrollable;
  final BuildContext itemContext;
  final TravelProgress progress;
  final ParallaxProperties parallax;
  final ZoomProperties? zoom;

  /// Whether the block is drawn at [_still] whatever the scroll.
  final bool still;

  Axis get _axis => scrollable.position.axis;

  bool get _horizontal => _axis == Axis.horizontal;

  /// The layer is the block on the cross axis and the overscan times it along
  /// the axis followed, both tight.
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
    final Size? backgroundSize = context.getChildSize(0);
    final double? at =
        still ? _still : _progressOf(scrollable, itemContext, _axis);
    progress.value = at ?? 0;

    if (at == null || backgroundSize == null) {
      // Nothing to measure against yet; draw the background where it stands so
      // the first frame is not blank.
      context.paintChild(0);
      return;
    }

    // Towards the end the block comes in from, so the background lags behind
    // it whichever way the scroll runs.
    final double towards =
        axisDirectionIsReversed(scrollable.axisDirection) ? -1 : 1;
    final double shift = (1 - 2 * at) * parallax.speed * towards;
    final Alignment alignment =
        _horizontal ? Alignment(shift, 0) : Alignment(0, shift);
    // The flow fills the block, so its size is the block's.
    final Rect childRect = alignment.inscribe(
      backgroundSize,
      Offset.zero & context.size,
    );

    context.paintChild(
      0,
      transform: placed(
        _horizontal ? Offset(childRect.left, 0) : Offset(0, childRect.top),
        scaleOf(zoom, at),
        context.size.center(Offset.zero),
      ),
    );
  }

  @override
  bool shouldRepaint(_ParallaxFlowDelegate oldDelegate) =>
      scrollable != oldDelegate.scrollable ||
      itemContext != oldDelegate.itemContext ||
      parallax != oldDelegate.parallax ||
      zoom != oldDelegate.zoom ||
      still != oldDelegate.still;
}
