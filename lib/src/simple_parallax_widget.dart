import 'package:flutter/widgets.dart';

import 'smooth_scroll.dart';

/// A scroll view meant to hold `SimpleParallaxItem` blocks.
///
/// This is a convenience around a [CustomScrollView] holding one [SliverList],
/// so the blocks build as they come into view however long the list is. Items
/// find the enclosing [Scrollable] themselves and read its axis, so any scroll
/// view works just as well; reach for a [CustomScrollView] directly once the
/// page needs other slivers alongside the blocks.
///
/// Each block is laid out across the full cross axis, the way a [ListView] lays
/// its children out.
///
/// ---
///
/// ### Parameters:
/// - [children]: the blocks to stack along [scrollDirection].
/// - [scrollDirection]: the axis the blocks are laid out and scrolled along.
/// - [controller]: an optional [ScrollController], for instance to drive the
///   position from outside.
/// - [padding]: padding around the list of blocks.
/// - [physics]: scroll physics to hand to the scroll view.
/// - [smooth]: whether the mouse wheel is eased in. The view then builds its
///   own controller, so [controller] has to be left out.
///
/// ### Example:
/// ```dart
/// SimpleParallaxWidget(
///   children: <Widget>[
///     const SimpleParallaxItem(
///       image: AssetImage('assets/images/background.webp'),
///       height: 300,
///     ),
///     Container(height: 400, color: const Color(0xFF90A4AE)),
///   ],
/// );
/// ```
///
/// The same blocks scrolling sideways, laid out along the horizontal axis:
/// ```dart
/// SimpleParallaxWidget(
///   scrollDirection: Axis.horizontal,
///   children: <Widget>[
///     const SimpleParallaxItem(
///       image: AssetImage('assets/images/background.webp'),
///       width: 300,
///     ),
///     Container(width: 400, color: const Color(0xFF90A4AE)),
///   ],
/// );
/// ```
class SimpleParallaxWidget extends StatelessWidget {
  /// Creates a scroll view for parallax items.
  const SimpleParallaxWidget({
    required this.children,
    this.scrollDirection = Axis.vertical,
    this.controller,
    this.padding,
    this.physics,
    this.smooth = false,
    super.key,
  }) : assert(
          !smooth || controller == null,
          'smooth builds its own controller, so none can be given',
        );

  /// The blocks to stack along [scrollDirection].
  final List<Widget> children;

  /// Axis the blocks are laid out and scrolled along.
  final Axis scrollDirection;

  /// Optional controller for the underlying scroll view.
  final ScrollController? controller;

  /// Padding around the list of blocks.
  final EdgeInsetsGeometry? padding;

  /// Scroll physics handed to the underlying scroll view.
  final ScrollPhysics? physics;

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
  Widget build(BuildContext context) {
    if (smooth) {
      return SmoothScroll(
        axis: scrollDirection,
        builder: (BuildContext context, ScrollController controller) =>
            _view(controller),
      );
    }
    return _view(controller);
  }

  /// The scroll view itself, on whichever controller it was handed.
  Widget _view(ScrollController? scrollController) {
    final Widget list = SliverList.list(children: children);
    final EdgeInsetsGeometry? insets = padding;

    return CustomScrollView(
      scrollDirection: scrollDirection,
      controller: scrollController,
      physics: physics,
      slivers: <Widget>[
        if (insets == null)
          list
        else
          SliverPadding(padding: insets, sliver: list),
      ],
    );
  }
}
