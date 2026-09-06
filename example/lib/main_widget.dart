import 'package:flutter/material.dart';
import 'package:simple_parallax/simple_parallax.dart';

void main() => runApp(const ItemDemo());

/// Item mode: each block slides its own background as it crosses the viewport.
class ItemDemo extends StatelessWidget {
  /// Creates the item demo.
  const ItemDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SimpleParallaxWidget(
          children: <Widget>[
            Container(height: 400, color: Colors.red),
            const SimpleParallaxItem(
              image: AssetImage('assets/images/background.webp'),
              height: 300,
              child: Center(child: Text('TEST 1')),
            ),
            Container(height: 250, color: Colors.greenAccent),
            const SimpleParallaxItem(
              image: AssetImage('assets/images/background.webp'),
              height: 300,
              speed: 0.5,
              child: Center(child: Text('TEST 2')),
            ),
            Container(height: 500, color: Colors.blueGrey),
          ],
        ),
      ),
    );
  }
}
