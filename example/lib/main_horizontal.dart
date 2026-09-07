import 'package:flutter/material.dart';
import 'package:simple_parallax/simple_parallax.dart';

void main() => runApp(const HorizontalDemo());

/// Both modes scrolling sideways: a container on top, items below.
class HorizontalDemo extends StatelessWidget {
  /// Creates the horizontal demo.
  const HorizontalDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: <Widget>[
            // Container mode: one background drifting behind a scrolling row.
            Expanded(
              child: SimpleParallaxContainer(
                image: const AssetImage('assets/images/background.webp'),
                scrollDirection: Axis.horizontal,
                autoSpeed: true,
                overscan: 1.5,
                child: Row(
                  children: List<Widget>.generate(
                    20,
                    (int index) => Container(
                      width: 150,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      color: const Color(0xCCFFFFFF),
                      child: Center(child: Text('Item $index')),
                    ),
                  ),
                ),
              ),
            ),
            // Item mode: the items read the axis of the scrollable themselves.
            Expanded(
              child: SimpleParallaxWidget(
                scrollDirection: Axis.horizontal,
                children: <Widget>[
                  Container(width: 400, color: Colors.red),
                  const SimpleParallaxItem(
                    image: AssetImage('assets/images/background.webp'),
                    width: 300,
                    child: Center(child: Text('TEST 1')),
                  ),
                  Container(width: 250, color: Colors.greenAccent),
                  const SimpleParallaxItem(
                    image: AssetImage('assets/images/background.webp'),
                    width: 300,
                    speed: 0.5,
                    child: Center(child: Text('TEST 2')),
                  ),
                  Container(width: 500, color: Colors.blueGrey),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
