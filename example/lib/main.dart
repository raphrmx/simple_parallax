import 'package:flutter/material.dart';
import 'package:simple_parallax/simple_parallax.dart';

void main() => runApp(const ContainerDemo());

/// Container mode: one background drifting behind a scrolling column.
class ContainerDemo extends StatelessWidget {
  /// Creates the container demo.
  const ContainerDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SimpleParallaxContainer(
          image: const AssetImage('assets/images/background.webp'),
          autoSpeed: true,
          overscan: 1.5,
          child: Column(
            children: List<Widget>.generate(
              20,
              (int index) => Container(
                height: 100,
                margin: const EdgeInsets.symmetric(vertical: 10),
                color: const Color(0xCCFFFFFF),
                child: Center(child: Text('Item $index')),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
