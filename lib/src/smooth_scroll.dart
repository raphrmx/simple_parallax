import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
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

/// Whether a view eases the wheel, given the `smooth` it was handed: as asked,
/// or else where the platform expects a wheel and [controller], if any, is a
/// [SmoothScrollController].
bool easesWheel(bool? smooth, ScrollController? controller) =>
    smooth ??
    (easesWheelByDefault &&
        (controller == null || controller is SmoothScrollController));

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
    // Which way the user scrolls, as a notch landed at once tells it: a
    // floating app bar reads it to come back on the way up. The animation
    // says nothing of it, and settles back to idle once done.
    if (activity is DrivenScrollActivity) {
      updateUserScrollDirection(
        delta < 0 ? ScrollDirection.forward : ScrollDirection.reverse,
      );
    }
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
///
/// It stays in the tree whether it is [active] or not, so turning the easing
/// on or off hands the view another controller rather than building another
/// view: the new position takes over the offset of the old one, and the page
/// does not jump back to the top. Except on iOS and Android, where a view with
/// no controller becomes the primary one, which Flutter builds with a widget
/// more: going from no controller to one of this widget's own there still
/// builds the view anew. The easing is off by default on those platforms,
/// having no wheel to ease, so that is a change nobody makes in practice.
class SmoothScroll extends StatefulWidget {
  /// Creates a smoothly wheeled scroll view through [builder].
  const SmoothScroll({
    required this.axis,
    required this.builder,
    this.active = true,
    this.controller,
    this.eased = true,
    super.key,
  });

  /// The axis the built view scrolls along.
  final Axis axis;

  /// Whether this widget takes the wheel. Off, the view is built on
  /// [controller] as it stands, or on none, and the wheel is the platform's;
  /// a [SmoothScrollController] handed in is still honoured, with [eased].
  final bool active;

  /// The caller's controller, or `null` for one of this widget's own when it
  /// is [active] and none at all when it is not. The caller's is never
  /// disposed here.
  final ScrollController? controller;

  /// Whether a wheel notch is animated. Off, it lands in one step, while the
  /// wheel is still brought to the axis of a horizontal view.
  final bool eased;

  /// Builds the scroll view, which has to take the controller it is given,
  /// `null` included.
  final Widget Function(BuildContext context, ScrollController? controller)
      builder;

  @override
  State<SmoothScroll> createState() => _SmoothScrollState();
}

class _SmoothScrollState extends State<SmoothScroll> {
  /// The controller this widget made, when it was active and not handed one.
  /// Kept until the widget goes, even once it is no longer used: the view may
  /// still be attached to it until it rebuilds.
  SmoothScrollController? _own;

  /// The controller the view is built on: the caller's, this widget's own when
  /// it is active and was handed none, or none.
  ScrollController? get _controller {
    final ScrollController? given = widget.controller;
    if (given != null) return given;
    return widget.active ? (_own ??= SmoothScrollController()) : null;
  }

  void _syncEasing() {
    final ScrollController? controller = _controller;
    if (controller is SmoothScrollController) controller.eased = widget.eased;
  }

  @override
  void initState() {
    super.initState();
    _syncEasing();
  }

  @override
  void didUpdateWidget(SmoothScroll oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncEasing();
  }

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  void _onPointerSignal(PointerSignalEvent event) {
    final ScrollController? controller = _controller;
    if (event is! PointerScrollEvent ||
        controller is! SmoothScrollController ||
        !controller.hasClients) {
      return;
    }
    final ScrollPosition position = controller.position;
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
