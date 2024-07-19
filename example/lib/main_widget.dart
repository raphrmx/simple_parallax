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
        body: SimpleParallaxWidget(
          children: <Widget>[
            Container(
              color: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 200, horizontal: 0),
              child: const SizedBox(
                height: 50,
              ),
            ),
            const SimpleParallaxItem(
              imagePath: 'assets/images/background.webp',
              height: 300,
              child: Center(
                child: Text('TEST 1'),
              ),
            ),
            Container(
              color: Colors.greenAccent,
              child: const SizedBox(
                height: 250,
              ),
            ),
            const SimpleParallaxItem(
              imagePath: 'assets/images/background.webp',
              height: 300,
              child: Center(
                child: Text('TEST 2'),
              ),
            ),
            Container(height: 500, color: Colors.blueGrey),
          ],
        ),
      ),
    );
  }
}
