import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Gravity across the screen, in g: x to the right, y towards the top, as the
/// accelerometer of a phone held in portrait gives it. Nothing where there is
/// no such sensor, on a desktop.
Stream<Offset> gravityAcrossScreen() {
  if (defaultTargetPlatform != TargetPlatform.android &&
      defaultTargetPlatform != TargetPlatform.iOS) {
    return const Stream<Offset>.empty();
  }
  return accelerometerEventStream(
    samplingPeriod: SensorInterval.gameInterval,
  ).map((AccelerometerEvent event) => Offset(event.x, event.y) / 9.81);
}

/// Whether there is a way to ask for the tilt. An app has none to ask: it is
/// allowed from the start.
bool get tiltNeedsPermission => false;

/// Asks to read the tilt. An app needs nothing.
Future<bool> askForTilt() async => true;
