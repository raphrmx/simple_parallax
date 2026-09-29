import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// Gravity across the screen, in g: x to the right, y towards the top, as the
/// accelerometer of a phone held in portrait gives it.
///
/// Worked out from the browser's `deviceorientation` angles rather than read
/// from a sensor API: Safari has no `Accelerometer`, and its `devicemotion`
/// has not always given gravity the same sign as Chrome, while `beta` and
/// `gamma` mean the same everywhere. A desktop browser sends a single event
/// with no angles, and nothing comes.
Stream<Offset> gravityAcrossScreen() {
  final StreamController<Offset> controller = StreamController<Offset>();
  void onOrientation(web.DeviceOrientationEvent event) {
    final double? beta = event.beta;
    final double? gamma = event.gamma;
    if (beta == null || gamma == null) return;
    // beta tips the top edge towards the user, gamma the right edge down.
    final double pitch = beta * math.pi / 180;
    final double roll = gamma * math.pi / 180;
    controller.add(
      Offset(-math.cos(pitch) * math.sin(roll), math.sin(pitch)),
    );
  }

  final web.EventListener listener = onOrientation.toJS;
  controller
    ..onListen = () {
      web.window.addEventListener('deviceorientation', listener);
    }
    ..onCancel = () {
      web.window.removeEventListener('deviceorientation', listener);
      controller.close();
    };
  return controller.stream;
}

/// `DeviceOrientationEvent`, where the browser has it.
JSObject? get _orientationEvent =>
    globalContext.getProperty<JSObject?>('DeviceOrientationEvent'.toJS);

/// Whether the browser has a way to ask for the tilt. Safari on iOS sends
/// nothing until a tap has asked; Chrome has the same request but sends the
/// tilt without it.
bool get tiltNeedsPermission =>
    _orientationEvent?.has('requestPermission') ?? false;

/// Asks to read the tilt. To be called from a tap: Safari refuses otherwise.
Future<bool> askForTilt() async {
  final JSObject? event = _orientationEvent;
  if (event == null || !event.has('requestPermission')) return true;
  try {
    final JSString answer = await event
        .callMethod<JSPromise<JSString>>('requestPermission'.toJS)
        .toDart;
    return answer.toDart == 'granted';
  } on Object {
    return false;
  }
}
