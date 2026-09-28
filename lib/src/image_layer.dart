import 'package:flutter/widgets.dart';

/// The background [image], with what shows while it loads and if it fails.
///
/// [placeholderColor] fills the layer until the first frame is decoded, and
/// [fadeIn] brings the picture in over it. An image the cache already holds is
/// drawn at once, with neither. [errorBuilder] takes the place of an image that
/// could not be loaded; without one, Flutter draws its error box in a debug
/// build and the placeholder stays in a release one.
class ImageLayer extends StatelessWidget {
  /// Creates the layer for [image].
  const ImageLayer({
    required this.image,
    required this.fit,
    required this.alignment,
    this.placeholderColor,
    this.fadeIn = Duration.zero,
    this.errorBuilder,
    super.key,
  });

  /// The picture.
  final ImageProvider<Object> image;

  /// How it fills the layer.
  final BoxFit fit;

  /// How it sits inside the layer.
  final Alignment alignment;

  /// What fills the layer until the picture is ready, `null` for nothing.
  final Color? placeholderColor;

  /// How long the picture takes to come in once it is ready. [Duration.zero]
  /// draws it at once.
  final Duration fadeIn;

  /// What is drawn in place of a picture that could not be loaded, `null` for
  /// nothing.
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    final bool arrives = placeholderColor != null || fadeIn > Duration.zero;
    return Image(
      image: image,
      fit: fit,
      alignment: alignment,
      errorBuilder: errorBuilder,
      frameBuilder: arrives
          ? (
              BuildContext context,
              Widget child,
              int? frame,
              bool wasSynchronouslyLoaded,
            ) =>
              wasSynchronouslyLoaded
                  ? child
                  : _Arrival(
                      ready: frame != null,
                      color: placeholderColor,
                      fadeIn: fadeIn,
                      child: child,
                    )
          : null,
    );
  }
}

/// [child] brought in over [color] once it is [ready].
///
/// The colour stays under the picture while it fades in, so the page does not
/// show through, and is dropped once the fade is over, so it never shows
/// through a picture with transparent parts.
class _Arrival extends StatefulWidget {
  const _Arrival({
    required this.ready,
    required this.color,
    required this.fadeIn,
    required this.child,
  });

  final bool ready;
  final Color? color;
  final Duration fadeIn;
  final Widget child;

  @override
  State<_Arrival> createState() => _ArrivalState();
}

class _ArrivalState extends State<_Arrival> {
  /// Whether the picture has come in completely.
  bool _arrived = false;

  @override
  Widget build(BuildContext context) {
    if (_arrived || (widget.ready && widget.fadeIn == Duration.zero)) {
      return widget.child;
    }

    final Color? color = widget.color;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        if (color != null) ColoredBox(color: color),
        if (widget.fadeIn == Duration.zero)
          widget.child
        else
          AnimatedOpacity(
            opacity: widget.ready ? 1 : 0,
            duration: widget.fadeIn,
            onEnd: () {
              if (widget.ready) setState(() => _arrived = true);
            },
            child: widget.child,
          ),
      ],
    );
  }
}
