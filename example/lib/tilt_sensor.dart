/// Where the tilt demo reads how the phone is held: the accelerometer through
/// `sensors_plus` in an app, the browser's device orientation on the web.
library;

export 'tilt_sensor_io.dart'
    if (dart.library.js_interop) 'tilt_sensor_web.dart';
