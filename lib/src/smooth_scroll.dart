import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// How long one wheel notch is animated over.
const Duration _wheelDuration = Duration(milliseconds: 220);

/// Curve a wheel notch is animated on.
const Curve _wheelCurve = Curves.easeOutCubic;

/// A [ScrollController] whose position eases the mouse wheel in.
///
/// A [Scrollable] applies a wheel notch with [ScrollPosition.jumpTo], which
/// lands the whole notch on one frame. Anything driven off the scroll position,
/// a parallax background included, then moves in steps.
///
/// ---
///
/// ### Example:
/// ```dart
/// CustomScrollView(
///   controller: SmoothScrollController(),
///   slivers: slivers,
/// );
/// ```
class SmoothScrollController extends ScrollController {
  /// Creates a controller for a smoothly wheeled scroll view.
  SmoothScrollController({
    super.initialScrollOffset,
    super.keepScrollOffset,
    super.debugLabel,
  });

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return SmoothScrollPosition(
      physics: physics,
      context: context,
      oldPosition: oldPosition,
      initialPixels: initialScrollOffset,
      keepScrollOffset: keepScrollOffset,
      debugLabel: debugLabel,
    );
  }
}

/// The position a [SmoothScrollController] creates.
///
/// Dragging, flinging and [jumpTo] behave as they do on any scroll view; only
/// the mouse wheel is animated.
class SmoothScrollPosition extends ScrollPositionWithSingleContext {
  /// Creates a position that animates the wheel.
  SmoothScrollPosition({
    required super.physics,
    required super.context,
    super.oldPosition,
    super.initialPixels,
    super.keepScrollOffset,
    super.debugLabel,
  });

  /// Where the notch being animated is headed, or `null` when none is running.
  double? _target;

  @override
  void pointerScroll(double delta) {
    if (delta == 0) {
      goBallistic(pixels);
      return;
    }
    wheelBy(delta);
  }

  /// Eases [delta] pixels in.
  ///
  /// A notch arriving while another is still running carries on from where that
  /// one was headed, so turning the wheel quickly adds the notches up instead of
  /// restarting each time from where the view happens to be.
  void wheelBy(double delta) {
    final double from = _target ?? pixels;
    final double to =
        (from + delta).clamp(minScrollExtent, maxScrollExtent).toDouble();
    if (to == pixels) {
      _target = null;
      return;
    }
    _target = to;
    animateTo(to, duration: _wheelDuration, curve: _wheelCurve)
        .whenComplete(() {
      if (_target == to) {
        _target = null;
      }
    });
  }

  @override
  void jumpTo(double value) {
    _target = null;
    super.jumpTo(value);
  }

  @override
  void applyUserOffset(double delta) {
    _target = null;
    super.applyUserOffset(delta);
  }
}

/// Builds a scroll view on a [SmoothScrollController] and hands it the wheel
/// notches the view itself turns down.
///
/// A [Scrollable] reads a wheel along its own axis alone, so a horizontal view
/// never moves under a plain wheel, which only carries a vertical delta. The
/// view claims the pointer signal only when it has a delta of its own, which
/// leaves the other axis to this widget.
class SmoothScroll extends StatefulWidget {
  /// Creates a smoothly wheeled scroll view through [builder].
  const SmoothScroll({
    required this.axis,
    required this.builder,
    super.key,
  });

  /// The axis the built view scrolls along.
  final Axis axis;

  /// Builds the scroll view, which has to take the controller it is given.
  final Widget Function(BuildContext context, ScrollController controller)
      builder;

  @override
  State<SmoothScroll> createState() => _SmoothScrollState();
}

class _SmoothScrollState extends State<SmoothScroll> {
  final SmoothScrollController _controller = SmoothScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !_controller.hasClients) {
      return;
    }
    final ScrollPosition position = _controller.position;
    if (position is! SmoothScrollPosition) {
      return;
    }

    final bool horizontal = widget.axis == Axis.horizontal;
    final Offset scrolled = event.scrollDelta;
    if ((horizontal ? scrolled.dx : scrolled.dy) != 0) {
      return;
    }
    final double delta = horizontal ? scrolled.dy : scrolled.dx;
    if (delta == 0) {
      return;
    }

    GestureBinding.instance.pointerSignalResolver.register(
      event,
      (PointerSignalEvent _) => position.wheelBy(delta),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: _onPointerSignal,
      child: widget.builder(context, _controller),
    );
  }
}
