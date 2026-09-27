/// Parallax widgets for Flutter, in pure Dart and with no dependencies.
///
/// Two modes are available:
///   * [SimpleParallaxContainer] wraps a scrolling area and drifts a single
///     background behind it.
///   * [SimpleParallaxItem] is a block whose background slides as the block
///     crosses the viewport. It works inside any scrollable, and
///     [SimpleParallaxWidget] is a convenience scroll view for a list of them.
///
/// Both take an [ImageProvider], so assets, network images, files and raw
/// bytes are all supported, and both take a `background` widget instead when the
/// layer is not a plain image, for a gradient, a video or an image the caller
/// configured themselves. Both work vertically or horizontally: the
/// container takes a `scrollDirection`, and the item reads the axis of the
/// scrollable it sits in.
///
/// Each effect is configured on an object of its own: [ParallaxProperties] for
/// the drift, [ZoomProperties] for the scale it gains, [BlurProperties] for how
/// soft it goes and [OverlayProperties] for a fixed tint over it. The zoom and
/// the blur each carry their own `reach` and `back`, so one can run the whole
/// travel while the other stops at the middle.
///
/// Both scroll views take a `smooth` flag, which eases the mouse wheel in and
/// brings it to an axis a [Scrollable] otherwise leaves untouched.
///
/// Both scroll views are built on slivers.
/// [SimpleParallaxContainer.slivers] takes its content as slivers, and
/// [SimpleParallaxWidget] builds its blocks as they come into view, so a long
/// list costs no more than a `ListView` would.
///
/// ### Example:
/// ```dart
/// SimpleParallaxContainer(
///   image: const AssetImage('assets/images/background.webp'),
///   parallax: const ParallaxProperties(speed: 0.5),
///   child: Column(children: items),
/// );
/// ```
library;

import 'package:flutter/widgets.dart';
import 'src/properties.dart';
import 'src/simple_parallax_container.dart';
import 'src/simple_parallax_item.dart';
import 'src/simple_parallax_widget.dart';

export 'src/properties.dart';
export 'src/simple_parallax_container.dart';
export 'src/simple_parallax_item.dart';
export 'src/simple_parallax_widget.dart';
