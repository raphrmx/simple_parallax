import 'package:flutter/material.dart';
import 'package:simple_parallax/simple_parallax.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const itemHeight = 100.0;
  static const itemMargin = 10.0;
  static const numberItems = 20;
  static const widgetHeight = 300.0;
  static const widgetWidth = 600.0;
  final _columnKey = GlobalKey();

  double _columnHeight = 1;

  void _calculateHeight() {
    final RenderBox renderBox =
        _columnKey.currentContext!.findRenderObject() as RenderBox;
    setState(() {
      _columnHeight = renderBox.size.height;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _calculateHeight());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            height: widgetHeight,
            width: widgetWidth,
            child: SimpleParallax(
              imagePath: 'assets/images/background.jpg',
              speed: widgetHeight / _columnHeight,
              decal: 1.0,
              child: Column(
                key: _columnKey,
                children: List.generate(
                  numberItems,
                  (index) => Container(
                    height: itemHeight,
                    margin: const EdgeInsets.symmetric(vertical: itemMargin),
                    color: Colors.white.withOpacity(0.8),
                    child: Center(child: Text('Item $index')),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
