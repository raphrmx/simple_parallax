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
/// bytes are all supported, and both work vertically or horizontally: the
/// container takes a `scrollDirection`, and the item reads the axis of the
/// scrollable it sits in.
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
///   autoSpeed: true,
///   child: Column(children: items),
/// );
/// ```
library;

import 'package:flutter/widgets.dart';
import 'src/simple_parallax_container.dart';
import 'src/simple_parallax_item.dart';
import 'src/simple_parallax_widget.dart';

export 'src/simple_parallax_container.dart';
export 'src/simple_parallax_item.dart';
export 'src/simple_parallax_widget.dart';
