import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Step, in physical pixels, a layer size is rounded up to before it is used
/// to decode, so a window resized by a few pixels reuses the image already
/// decoded instead of decoding it again.
const double _sizeStep = 64;

/// [image] as it should be decoded for a layer of [layer] logical pixels, drawn
/// under [fit] on a screen of [devicePixelRatio], and scaled up to [zoom] times
/// on top of that.
///
/// Returns [image] itself when the layer has no usable size yet.
ImageProvider<Object> decodedFor(
  ImageProvider<Object> image, {
  required Size layer,
  required double devicePixelRatio,
  required BoxFit fit,
  double zoom = 1,
}) {
  final double scale = devicePixelRatio * math.max(zoom, 1);
  final double width = layer.width * scale;
  final double height = layer.height * scale;
  if (!width.isFinite || !height.isFinite || width <= 0 || height <= 0) {
    return image;
  }
  return DisplaySizeImage(
    image,
    size: Size(
      (width / _sizeStep).ceil() * _sizeStep,
      (height / _sizeStep).ceil() * _sizeStep,
    ),
    fit: fit,
  );
}

/// The size an image of [intrinsic] pixels needs to be decoded at to be drawn
/// into a box of [box] physical pixels under [fit] without losing detail, or
/// `null` when that is its own size or more.
///
/// The scale is the one the image is drawn at: cover crops and keeps the larger
/// of the two ratios, contain keeps the smaller, fill stretches and needs the
/// larger. The image is never scaled up, which would cost memory for nothing.
@visibleForTesting
Size? decodeSizeFor(Size intrinsic, Size box, BoxFit fit) {
  if (intrinsic.isEmpty || box.isEmpty) return null;
  final FittedSizes fitted = applyBoxFit(fit, intrinsic, box);
  if (fitted.source.isEmpty) return null;
  final double scale = math.max(
    fitted.destination.width / fitted.source.width,
    fitted.destination.height / fitted.source.height,
  );
  if (scale >= 1) return null;
  return Size(
    (intrinsic.width * scale).ceilToDouble(),
    (intrinsic.height * scale).ceilToDouble(),
  );
}

/// Decodes [image] no larger than it is drawn: into a box of [size] physical
/// pixels, under [fit].
///
/// This is what `cacheWidth` and `cacheHeight` do on an `Image`, without having
/// to know the size of the picture in advance: it is read from the file, and
/// the decode size follows from it. A photo of 4000 by 3000 pixels shown in a
/// block of 300 is otherwise decoded, and held in memory, at full size.
@immutable
class DisplaySizeImage extends ImageProvider<DisplaySizeImageKey> {
  /// Creates a provider decoding [image] for a box of [size] under [fit].
  const DisplaySizeImage(this.image, {required this.size, required this.fit});

  /// The image to decode.
  final ImageProvider<Object> image;

  /// The box it is drawn into, in physical pixels.
  final Size size;

  /// How it is fitted into that box.
  final BoxFit fit;

  @override
  Future<DisplaySizeImageKey> obtainKey(ImageConfiguration configuration) {
    // Kept synchronous when the image's own key is, as ResizeImage does, so an
    // image already in the cache is drawn on the first frame rather than the
    // second.
    Completer<DisplaySizeImageKey>? completer;
    SynchronousFuture<DisplaySizeImageKey>? result;
    image.obtainKey(configuration).then((Object key) {
      final DisplaySizeImageKey wrapped = DisplaySizeImageKey(key, size, fit);
      if (completer == null) {
        result = SynchronousFuture<DisplaySizeImageKey>(wrapped);
      } else {
        completer.complete(wrapped);
      }
    });
    if (result != null) return result!;
    completer = Completer<DisplaySizeImageKey>();
    return completer.future;
  }

  @override
  ImageStreamCompleter loadImage(
    DisplaySizeImageKey key,
    ImageDecoderCallback decode,
  ) {
    Future<ui.Codec> decodeAtSize(
      ui.ImmutableBuffer buffer, {
      ui.TargetImageSizeCallback? getTargetSize,
    }) {
      // A provider further in, a ResizeImage for one, already picks a size:
      // that choice was made on purpose, so it stands.
      if (getTargetSize != null) {
        return decode(buffer, getTargetSize: getTargetSize);
      }
      return decode(
        buffer,
        getTargetSize: (int width, int height) {
          final Size? target = decodeSizeFor(
            Size(width.toDouble(), height.toDouble()),
            size,
            fit,
          );
          return target == null
              ? ui.TargetImageSize(width: width, height: height)
              : ui.TargetImageSize(
                  width: target.width.toInt(),
                  height: target.height.toInt(),
                );
        },
      );
    }

    return image.loadImage(key.image, decodeAtSize);
  }

  @override
  bool operator ==(Object other) =>
      other is DisplaySizeImage &&
      other.image == image &&
      other.size == size &&
      other.fit == fit;

  @override
  int get hashCode => Object.hash(image, size, fit);

  @override
  String toString() =>
      '${objectRuntimeType(this, 'DisplaySizeImage')}($image, $size, $fit)';
}

/// The cache key of a [DisplaySizeImage]: the image's own key, and the size
/// and fit it is decoded for.
@immutable
class DisplaySizeImageKey {
  /// Creates the key of [image] decoded for [size] under [fit].
  const DisplaySizeImageKey(this.image, this.size, this.fit);

  /// The key of the image being decoded.
  final Object image;

  /// The box it is decoded for, in physical pixels.
  final Size size;

  /// How it is fitted into that box.
  final BoxFit fit;

  @override
  bool operator ==(Object other) =>
      other is DisplaySizeImageKey &&
      other.image == image &&
      other.size == size &&
      other.fit == fit;

  @override
  int get hashCode => Object.hash(image, size, fit);
}
