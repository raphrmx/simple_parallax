import 'package:flutter/widgets.dart';

import 'smooth_scroll.dart';

/// A scroll view meant to hold `SimpleParallaxItem` blocks.
///
/// This is a convenience around a [CustomScrollView] holding one [SliverList],
/// so the blocks build as they come into view however long the list is. The
/// default constructor takes the blocks as a list, which creates every widget
/// up front; [SimpleParallaxWidget.builder] creates each one as it is needed,
/// which is the form to use for a long or open-ended list. Items
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
/// - [itemBuilder] and [itemCount]: the blocks, created on demand, for
///   [SimpleParallaxWidget.builder].
/// - [scrollDirection]: the axis the blocks are laid out and scrolled along.
/// - [controller]: an optional [ScrollController], for instance to drive the
///   position from outside. A [SmoothScrollController] keeps [smooth] on.
/// - [padding]: padding around the list of blocks.
/// - [physics]: scroll physics to hand to the scroll view.
/// - [restorationId], [keyboardDismissBehavior] and [clipBehavior]: handed to
///   the scroll view.
/// - [smooth]: whether the mouse wheel is eased in. The view builds its own
///   controller to do it, so this is on unless a [controller] was given.
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
/// Five hundred blocks, each created as it scrolls into view:
/// ```dart
/// SimpleParallaxWidget.builder(
///   itemCount: 500,
///   itemBuilder: (BuildContext context, int index) => SimpleParallaxItem(
///     image: NetworkImage('https://example.com/$index.jpg'),
///     height: 300,
///   ),
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
    bool? smooth,
    this.restorationId,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.clipBehavior = Clip.hardEdge,
    super.key,
  })  : _smooth = smooth,
        itemBuilder = null,
        itemCount = null,
        assert(
          smooth != true ||
              controller == null ||
              controller is SmoothScrollController,
          'smooth needs no controller, or a SmoothScrollController',
        );

  /// Creates a scroll view whose blocks are created by [itemBuilder] as they
  /// come into view, [itemCount] of them, or as many as it returns non-null for
  /// when [itemCount] is `null`.
  const SimpleParallaxWidget.builder({
    required NullableIndexedWidgetBuilder this.itemBuilder,
    this.itemCount,
    this.scrollDirection = Axis.vertical,
    this.controller,
    this.padding,
    this.physics,
    bool? smooth,
    this.restorationId,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.clipBehavior = Clip.hardEdge,
    super.key,
  })  : _smooth = smooth,
        children = const <Widget>[],
        assert(
          smooth != true ||
              controller == null ||
              controller is SmoothScrollController,
          'smooth needs no controller, or a SmoothScrollController',
        );

  /// The blocks to stack along [scrollDirection]. Empty for
  /// [SimpleParallaxWidget.builder], which has an [itemBuilder] instead.
  final List<Widget> children;

  /// Creates the block at an index, or `null` for the default constructor,
  /// which takes [children] instead.
  final NullableIndexedWidgetBuilder? itemBuilder;

  /// How many blocks [itemBuilder] creates, `null` for as many as it returns
  /// non-null for.
  final int? itemCount;

  /// Axis the blocks are laid out and scrolled along.
  final Axis scrollDirection;

  /// Optional controller for the underlying scroll view.
  ///
  /// A [SmoothScrollController] keeps the wheel eased; any other controller
  /// turns [smooth] off unless it is asked for, which is then an error.
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
  /// On unless a [controller] other than a [SmoothScrollController] was given,
  /// since the easing lives in the position that controller creates. Passing
  /// both `true` and such a controller is an error rather than a silent no-op.
  /// Dragging, flinging and touch are untouched either way, so this is a mouse
  /// and trackpad setting.
  ///
  /// When the platform asks for reduced motion a notch lands in one step, and
  /// only the wheel brought to a horizontal view is left of this.
  ///
  /// Left unset, it is on on desktop and the web, where a mouse wheel is
  /// expected, and off on iOS and Android, where there is none: the easing
  /// needs a controller of the view's own, and a view with a controller is not
  /// the primary one, so a tap on the iOS status bar would no longer scroll it
  /// back to the top. Set it to `true` to ease the wheel there as well. The
  /// value read here is the one asked for, or derived from [controller].
  bool get smooth =>
      _smooth ?? (controller == null || controller is SmoothScrollController);

  /// What was passed as [smooth], `null` for the platform to decide.
  final bool? _smooth;

  /// Restoration id handed to the scroll view, so the scroll offset survives
  /// the app being killed and restored.
  final String? restorationId;

  /// Whether a drag dismisses the keyboard, handed to the scroll view.
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  /// How the scroll view clips its content, handed to it.
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final bool eased = easesWheel(_smooth, controller);
    // Always there, active or not, so a change of [smooth] keeps the view and
    // its offset.
    return SmoothScroll(
      axis: scrollDirection,
      active: eased,
      controller: controller,
      // Easing the wheel is motion too.
      eased: eased && !MediaQuery.disableAnimationsOf(context),
      builder: (BuildContext context, ScrollController? controller) =>
          _view(controller),
    );
  }

  /// The scroll view itself, on whichever controller it was handed.
  Widget _view(ScrollController? scrollController) {
    final NullableIndexedWidgetBuilder? builder = itemBuilder;
    final Widget list = builder == null
        ? SliverList.list(children: children)
        : SliverList.builder(itemBuilder: builder, itemCount: itemCount);
    final EdgeInsetsGeometry? insets = padding;

    return CustomScrollView(
      scrollDirection: scrollDirection,
      controller: scrollController,
      physics: physics,
      restorationId: restorationId,
      keyboardDismissBehavior: keyboardDismissBehavior,
      clipBehavior: clipBehavior,
      slivers: <Widget>[
        if (insets == null)
          list
        else
          SliverPadding(padding: insets, sliver: list),
      ],
    );
  }
}
