import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../common/parallax_notifier.dart';

/// SimpleParallaxWidget
class SimpleParallaxWidget extends StatefulWidget {
  /// SimpleParallaxWidget constructor
  const SimpleParallaxWidget({
    super.key,
    required this.children,
  });

  /// Parallax content
  final List<Widget> children;

  @override
  State<SimpleParallaxWidget> createState() => _SimpleParallaxWidgetState();
}

class _SimpleParallaxWidgetState extends State<SimpleParallaxWidget> {
  final ScrollController _scrollController = ScrollController();
  final ParallaxNotifier _parallaxNotifier = ParallaxNotifier();

  void _scrollListener() {
    _parallaxNotifier.updateScrollOffset(_scrollController.offset);
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ParallaxNotifier>.value(
      value: _parallaxNotifier,
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: widget.children,
        ),
      ),
    );
  }
}
