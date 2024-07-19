import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../common/parallax_notifier.dart';

/// SimpleParallaxItem item
class SimpleParallaxItem extends StatefulWidget {
  /// SimpleParallaxItem constructor
  const SimpleParallaxItem({
    super.key,
    required this.imagePath,
    this.child,
    this.speed = 0.3,
    this.decal = 1.5,
    this.width,
    this.height,
  });

  /// Background image path
  final String imagePath;

  /// Parallax content
  final Widget? child;

  /// Parallax speed setting
  final double speed;

  /// Image decal zooming
  final double decal;

  /// Height of item
  final double? height;

  /// Width of item
  final double? width;

  @override
  State<SimpleParallaxItem> createState() => _SimpleParallaxItemState();
}

class _SimpleParallaxItemState extends State<SimpleParallaxItem> {
  late ParallaxNotifier _parallaxRowNotifier;
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    _parallaxRowNotifier = ParallaxNotifier();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculatePosition();
    });
  }

  void _calculatePosition() {
    final RenderBox renderBox =
        _key.currentContext!.findRenderObject()! as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    EdgeInsets padding = EdgeInsets.zero; // Default if no padding is used

    // Calculating the offset including padding
    final Padding? container =
        _key.currentContext!.findAncestorWidgetOfExactType<Padding>();
    if (container != null) {
      final Padding paddingWidget = container;
      final EdgeInsetsGeometry paddingEdge = paddingWidget.padding;
      if (paddingEdge is EdgeInsets) {
        padding = paddingEdge;
      }
    }

    final double offsetY = offset.dy - padding.top;
    final double scrollOffset =
        Provider.of<ParallaxNotifier>(context, listen: false).scrollOffset;
    _parallaxRowNotifier.updatePosition(offsetY - scrollOffset);
  }

  double _getTranslateValue(BuildContext context) {
    final double scrollOffset =
        Provider.of<ParallaxNotifier>(context).scrollOffset;
    final double widgetPosition = _parallaxRowNotifier.widgetPosition;
    return (scrollOffset - widgetPosition) * widget.speed;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ParallaxNotifier>(
      builder: (BuildContext context, ParallaxNotifier notifier, _) {
        final double translateValue = _getTranslateValue(context);

        return SizedBox(
          key: _key,
          height: widget.height ?? MediaQuery.of(context).size.height,
          width: widget.width ?? MediaQuery.of(context).size.width,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Positioned(
                top: translateValue,
                left: 0,
                right: 0,
                child: Image.asset(
                  widget.imagePath,
                  fit: BoxFit.cover,
                  height:
                      (widget.height ?? MediaQuery.of(context).size.height) *
                          widget.decal,
                ),
              ),
              if (widget.child != null) widget.child!,
            ],
          ),
        );
      },
    );
  }
}
