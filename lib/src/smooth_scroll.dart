import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// How long one wheel notch is animated over.
const Duration _wheelDuration = Duration(milliseconds: 220);

/// Curve a wheel notch is animated on.
const Curve _wheelCurve = Curves.easeOutCubic;

/// Whether a view left to decide eases the mouse wheel on this platform.
///
/// On desktop and the web, where a mouse is expected. Not on iOS or Android,
/// where there is none: the easing needs a controller of the view's own, and a
/// view with a controller is not the primary one, which is what a tap on the
/// iOS status bar scrolls back to the top.
bool get easesWheelByDefault => switch (defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.android => false,
      _ => true,
    };

/// A [ScrollController] whose position eases the mouse wheel in.
///
/// A [Scrollable] applies a wheel notch with [ScrollPosition.jumpTo], which
/// lands the whole notch on one frame. Anything driven off the scroll position,
/// a parallax background included, then moves in steps.
///
/// Hand one to `SimpleParallaxContainer` or `SimpleParallaxWidget` as their
/// `controller` to drive the view from outside, to jump back to the top or to
/// read the offset, and keep the wheel eased: a plain [ScrollController] turns
/// `smooth` off, since the easing lives in the position this one creates. It is
/// used like any other controller otherwise, and disposed by whoever created it.
///
/// Those views set [eased] themselves, off when the platform asks for reduced
/// motion. In a scroll view of your own it eases the wheel along the view's
/// axis, and leaves [eased] to you.
///
/// ---
///
/// ### Example:
/// ```dart
/// final SmoothScrollController controller = SmoothScrollController();
///
/// SimpleParallaxContainer(
///   image: const AssetImage('assets/images/background.webp'),
///   controller: controller,
///   child: Column(children: items),
/// );
///
/// // Later, from a button:
/// controller.animateTo(
///   0,
///   duration: const Duration(milliseconds: 600),
///   curve: Curves.easeInOutCubic,
/// );
/// ```
class SmoothScrollController extends ScrollController {
  /// Creates a controller for a smoothly wheeled scroll view.
  SmoothScrollController({
    super.initialScrollOffset,
    super.keepScrollOffset,
    super.debugLabel,
  });

  /// Whether a wheel notch is animated rather than landed in one step. Read on
  /// every notch, so it can change while the view is up.
  bool eased = true;

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
      eased: () => eased,
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
    bool Function()? eased,
  }) : _eased = eased ?? _always;

  static bool _always() => true;

  /// Whether a notch is animated, asked on every one.
  final bool Function() _eased;

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
    if (!_eased()) {
      _target = null;
      super.pointerScroll(delta);
      return;
    }
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

  /// Whether a notch of [delta] would move the view at all, counted from where
  /// the notch being animated is headed.
  bool canWheelBy(double delta) {
    final double from = _target ?? pixels;
    return delta < 0 ? from > minScrollExtent : from < maxScrollExtent;
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
/// leaves the other axis to this widget. At either end that wheel is let
/// through, so a horizontal view inside a vertical page does not stop the page
/// from scrolling.
class SmoothScroll extends StatefulWidget {
  /// Creates a smoothly wheeled scroll view through [builder].
  const SmoothScroll({
    required this.axis,
    required this.builder,
    this.controller,
    this.eased = true,
    super.key,
  });

  /// The axis the built view scrolls along.
  final Axis axis;

  /// The caller's controller, or `null` for one of this widget's own. The
  /// caller's is never disposed here.
  final SmoothScrollController? controller;

  /// Whether a wheel notch is animated. Off, it lands in one step, while the
  /// wheel is still brought to the axis of a horizontal view.
  final bool eased;

  /// Builds the scroll view, which has to take the controller it is given.
  final Widget Function(BuildContext context, ScrollController controller)
      builder;

  @override
  State<SmoothScroll> createState() => _SmoothScrollState();
}

class _SmoothScrollState extends State<SmoothScroll> {
  /// The controller this widget made, when it was not handed one. Kept until
  /// the widget goes, even if a controller is handed in meanwhile: the view may
  /// still be attached to it until it rebuilds.
  SmoothScrollController? _own;

  SmoothScrollController get _controller =>
      widget.controller ?? (_own ??= SmoothScrollController());

  @override
  void initState() {
    super.initState();
    _controller.eased = widget.eased;
  }

  @override
  void didUpdateWidget(SmoothScroll oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.eased = widget.eased;
  }

  @override
  void dispose() {
    _own?.dispose();
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
    // At the end the wheel is heading for, the view has nothing to do with it,
    // so it is left to an enclosing scroll view rather than swallowed here.
    if (delta == 0 || !position.canWheelBy(delta)) {
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
