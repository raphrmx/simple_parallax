import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../common/scroll_notifier.dart';
import './parallax_layer.dart';

/// SimpleParallax widget
class SimpleParallaxContainer extends StatefulWidget {
  /// Simple parallax constructor
  const SimpleParallaxContainer({
    super.key,
    required this.imagePath,
    required this.child,
    this.speed = 0.3,
    this.decal = 1.0,
    this.height,
    this.autoSpeed = false,
  });

  /// Background image path
  final String imagePath;

  /// Parallax content
  final Widget child;

  /// Parallax speed setting
  final double speed;

  /// Perfect speed auto calculated
  final bool autoSpeed;

  /// Image base position
  final double decal;

  /// Widget Height
  final double? height;

  @override
  State<SimpleParallaxContainer> createState() =>
      _SimpleParallaxContainerState();
}

class _SimpleParallaxContainerState extends State<SimpleParallaxContainer> {
  double _speed = 0.3;
  void _calculateSpeed() {
    final RenderBox? renderBox = (widget.child.key as GlobalKey?)
        ?.currentContext
        ?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      setState(() {
        _speed = (widget.height ?? MediaQuery.of(context).size.height) /
            renderBox.size.height;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _speed = widget.speed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.autoSpeed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _calculateSpeed();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double parentHeight = constraints.maxHeight;
        final double parentWidth = constraints.maxWidth;

        return ChangeNotifierProvider<ScrollNotifier>(
          create: (BuildContext context) => ScrollNotifier(),
          child: Consumer<ScrollNotifier>(
            builder: (BuildContext context, ScrollNotifier notifier, _) {
              return NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollNotification) {
                  if (scrollNotification is ScrollUpdateNotification) {
                    final double scrollPixels =
                        scrollNotification.metrics.pixels;
                    final double offset = scrollPixels * _speed;
                    Provider.of<ScrollNotifier>(context, listen: false)
                        .setScrollOffset(offset);
                  }
                  return true;
                },
                child: Stack(
                  children: <Widget>[
                    ParallaxLayer(
                      imagePath: widget.imagePath,
                      speed: _speed,
                      decal: widget.decal,
                      width: parentWidth,
                      height: parentHeight,
                    ),
                    SingleChildScrollView(child: widget.child),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
