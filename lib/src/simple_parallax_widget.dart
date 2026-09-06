import 'package:flutter/widgets.dart';

/// A vertical scroll view meant to hold `SimpleParallaxItem` blocks.
///
/// This is a convenience around a [SingleChildScrollView] and a [Column]:
/// items find the enclosing [Scrollable] themselves, so any scroll view works
/// just as well. Reach for a [ListView] instead when the list is long enough to
/// need lazy building.
///
/// ---
///
/// ### Parameters:
/// - [children]: the blocks to stack vertically.
/// - [controller]: an optional [ScrollController], for instance to drive the
///   position from outside.
/// - [padding]: padding around the column.
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
class SimpleParallaxWidget extends StatelessWidget {
  /// Creates a scroll view for parallax items.
  const SimpleParallaxWidget({
    required this.children,
    this.controller,
    this.padding,
    this.physics,
    super.key,
  });

  /// The blocks to stack vertically.
  final List<Widget> children;

  /// Optional controller for the underlying scroll view.
  final ScrollController? controller;

  /// Padding around the column.
  final EdgeInsetsGeometry? padding;

  /// Scroll physics handed to the underlying scroll view.
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: controller,
      padding: padding,
      physics: physics,
      child: Column(children: children),
    );
  }
}
