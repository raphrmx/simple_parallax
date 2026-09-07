import 'package:flutter/widgets.dart';

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
/// ---
///
/// ### Parameters:
/// - [image]: any [ImageProvider], so an asset, a network image, a file or
///   raw bytes all work.
/// - [child]: content drawn over the background, for instance a caption.
/// - [speed]: fraction of the available travel the background uses, from `0`
///   (pinned) to `1` (the whole [overscan]).
/// - [overscan]: how much larger than the item the background is drawn along
///   the scroll axis. Must be at least `1`; at exactly `1` there is no travel,
///   so no effect.
/// - [height]: item height. Defaults to the screen height in a vertical
///   scrollable, and to the incoming constraints in a horizontal one.
/// - [width]: item width. Defaults to the incoming constraints in a vertical
///   scrollable, and to the screen width in a horizontal one.
/// - [fit]: how the background fills its layer.
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
class SimpleParallaxItem extends StatefulWidget {
  /// Creates a parallax item.
  const SimpleParallaxItem({
    required this.image,
    this.child,
    this.speed = 1.0,
    this.overscan = 1.5,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    super.key,
  })  : assert(overscan >= 1, 'overscan must be at least 1'),
        assert(speed >= 0 && speed <= 1, 'speed must be between 0 and 1');

  /// Background image.
  final ImageProvider image;

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

  /// How the background fills its layer.
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

    final Widget background = SizedBox(
      key: _backgroundKey,
      height: horizontal ? null : height! * widget.overscan,
      width: horizontal ? width! * widget.overscan : null,
      child: Image(image: widget.image, fit: widget.fit),
    );

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
    required this.axis,
  }) : super(repaint: scrollable.position);

  final ScrollableState scrollable;
  final BuildContext itemContext;
  final GlobalKey backgroundKey;
  final double speed;
  final Axis axis;

  bool get _horizontal => axis == Axis.horizontal;

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) =>
      _horizontal
          ? BoxConstraints.tightFor(height: constraints.maxHeight)
          : BoxConstraints.tightFor(width: constraints.maxWidth);

  @override
  void paintChildren(FlowPaintingContext context) {
    final RenderObject? scrollBox = scrollable.context.findRenderObject();
    final RenderObject? itemBox = itemContext.findRenderObject();
    final RenderObject? backgroundBox =
        backgroundKey.currentContext?.findRenderObject();

    if (scrollBox is! RenderBox ||
        itemBox is! RenderBox ||
        backgroundBox is! RenderBox ||
        !scrollBox.hasSize ||
        !itemBox.hasSize ||
        !backgroundBox.hasSize) {
      // Nothing to measure against yet; draw the background where it stands so
      // the first frame is not blank.
      context.paintChild(0);
      return;
    }

    final double viewport = scrollable.position.viewportDimension;
    if (viewport <= 0) {
      context.paintChild(0);
      return;
    }

    final Offset itemOffset = itemBox.localToGlobal(
      _horizontal
          ? itemBox.size.topCenter(Offset.zero)
          : itemBox.size.centerLeft(Offset.zero),
      ancestor: scrollBox,
    );
    final double travelled = _horizontal ? itemOffset.dx : itemOffset.dy;
    final double fraction = (travelled / viewport).clamp(0.0, 1.0);
    final double shift = (fraction * 2 - 1) * speed;
    final Alignment alignment =
        _horizontal ? Alignment(shift, 0) : Alignment(0, shift);
    final Rect childRect = alignment.inscribe(
      backgroundBox.size,
      Offset.zero & itemBox.size,
    );

    context.paintChild(
      0,
      transform: _horizontal
          ? Matrix4.translationValues(childRect.left, 0, 0)
          : Matrix4.translationValues(0, childRect.top, 0),
    );
  }

  @override
  bool shouldRepaint(_ParallaxFlowDelegate oldDelegate) =>
      scrollable != oldDelegate.scrollable ||
      itemContext != oldDelegate.itemContext ||
      backgroundKey != oldDelegate.backgroundKey ||
      speed != oldDelegate.speed ||
      axis != oldDelegate.axis;
}
