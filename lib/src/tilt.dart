import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// An offset from `-1` to `1` on each axis, eased towards where it is aimed.
///
/// It is what a `TiltProperties` follows. Aim it with [aim] from anything
/// reporting where the viewer stands, the pointer or the tilt of the phone,
/// and it follows at the pace of [response], which smooths a pointer that
/// jumps and a sensor that shakes. Aim it at [Offset.zero] to let it settle.
///
/// Created with a [TickerProvider] like an [AnimationController], and disposed
/// the same way.
///
/// ---
///
/// ### Example:
/// ```dart
/// class _PageState extends State<Page> with SingleTickerProviderStateMixin {
///   late final TiltController _tilt = TiltController(vsync: this);
///
///   @override
///   void dispose() {
///     _tilt.dispose();
///     super.dispose();
///   }
///
///   @override
///   Widget build(BuildContext context) => PointerTilt(
///         controller: _tilt,
///         child: SimpleParallaxContainer(
///           image: const AssetImage('assets/images/background.webp'),
///           tilt: TiltProperties(_tilt),
///           child: Column(children: items),
///         ),
///       );
/// }
/// ```
class TiltController extends ChangeNotifier implements ValueListenable<Offset> {
  /// Creates a controller at rest, ticking through [vsync].
  TiltController({
    required TickerProvider vsync,
    this.response = const Duration(milliseconds: 200),
  }) {
    _ticker = vsync.createTicker(_tick);
  }

  /// How quickly the offset follows its aim: after this long it has covered
  /// about two thirds of the way. [Duration.zero] follows at once.
  final Duration response;

  late final Ticker _ticker;
  Offset _value = Offset.zero;
  Offset _aim = Offset.zero;
  Duration _last = Duration.zero;

  /// The offset as it stands, eased towards [target].
  @override
  Offset get value => _value;

  /// Where the offset is headed.
  Offset get target => _aim;

  /// Heads for [target], clamped to `-1` to `1` on each axis.
  void aim(Offset target) {
    _aim = Offset(target.dx.clamp(-1.0, 1.0), target.dy.clamp(-1.0, 1.0));
    if (response == Duration.zero) {
      _ticker.stop();
      _set(_aim);
    } else if (!_ticker.isActive && _aim != _value) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    final double seconds = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    final double k = 1 - math.exp(-seconds * 1e6 / response.inMicroseconds);
    Offset next = _value + (_aim - _value) * k;
    // Close enough that no pixel moves: land and stop ticking.
    if ((_aim - next).distanceSquared < 1e-6) {
      next = _aim;
      _ticker.stop();
    }
    _set(next);
  }

  void _set(Offset value) {
    if (value == _value) return;
    _value = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}

/// Aims a [TiltController] at the mouse over [child].
///
/// The pointer at the middle of [child] is `0`, at its edges `-1` and `1`, and
/// the controller settles back to `0` when the pointer leaves. Only a mouse
/// hovers, so touch leaves it alone.
class PointerTilt extends StatelessWidget {
  /// Aims [controller] at the mouse over [child].
  const PointerTilt({
    required this.controller,
    required this.child,
    super.key,
  });

  /// The controller to aim.
  final TiltController controller;

  /// The area the pointer is followed over.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      opaque: false,
      onHover: (PointerHoverEvent event) {
        final Size? size = context.size;
        if (size == null || size.isEmpty) return;
        controller.aim(
          Offset(
            event.localPosition.dx / size.width * 2 - 1,
            event.localPosition.dy / size.height * 2 - 1,
          ),
        );
      },
      onExit: (PointerExitEvent _) => controller.aim(Offset.zero),
      child: child,
    );
  }
}
