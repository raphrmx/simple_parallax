import 'package:flutter/widgets.dart';

/// A scroll view meant to hold `SimpleParallaxItem` blocks.
///
/// This is a convenience around a [SingleChildScrollView] and a [Column], or a
/// [Row] when [scrollDirection] is horizontal: items find the enclosing
/// [Scrollable] themselves and read its axis, so any scroll view works just as
/// well. Reach for a [ListView] instead when the list is long enough to need
/// lazy building.
///
/// ---
///
/// ### Parameters:
/// - [children]: the blocks to stack along [scrollDirection].
/// - [scrollDirection]: the axis the blocks are laid out and scrolled along.
/// - [controller]: an optional [ScrollController], for instance to drive the
///   position from outside.
/// - [padding]: padding around the column or row.
/// - [physics]: scroll physics to hand to the scroll view.
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
/// The same blocks scrolling sideways:
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
    super.key,
  });

  /// The blocks to stack along [scrollDirection].
  final List<Widget> children;

  /// Axis the blocks are laid out and scrolled along.
  final Axis scrollDirection;

  /// Optional controller for the underlying scroll view.
  final ScrollController? controller;

  /// Padding around the column or row.
  final EdgeInsetsGeometry? padding;

  /// Scroll physics handed to the underlying scroll view.
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: scrollDirection,
      controller: controller,
      padding: padding,
      physics: physics,
      child: scrollDirection == Axis.horizontal
          ? Row(children: children)
          : Column(children: children),
    );
  }
}
