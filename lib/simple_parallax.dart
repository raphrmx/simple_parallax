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
/// The background can also gain scale as it travels, through `zoom`, and go
/// soft, through `blur`. Either spreads over the whole travel, or is done by
/// `reach` and then held, or comes `back` from there.
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
