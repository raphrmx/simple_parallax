import 'package:flutter/material.dart';
import 'package:simple_parallax/simple_parallax.dart';

void main() => runApp(const MyApp());

/// App demo
class MyApp extends StatelessWidget {
  /// App demo constructor
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            //height: 300,
            //width: 600,
            child: SimpleParallaxContainer(
              //height: 300,
              imagePath: 'assets/images/background.jpg',
              speed: 0.3,
              autoSpeed: true,
              decal: 1.0,
              child: Column(
                children: List<Widget>.generate(
                  20,
                  (int index) => Container(
                    height: 100,
                    margin: const EdgeInsets.symmetric(vertical: 10),
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
