# SimpleParallax Plugin for Flutter
<a alt="ComApps Logo" href="https://www.comapps.be" target="_blank" rel="noreferrer"><img src="https://www.comapps.be/public/images/CompleteLogoHorizontalMini.png" height="45" style="margin: 15px"></a>

[![Pub Version](https://img.shields.io/pub/v/simple_parallax?color=blue)](https://pub.dev/packages/simple_parallax)
![Maintainer](https://img.shields.io/badge/Maintainer-Raphael_Vrient-purple)
[![License](https://img.shields.io/badge/Licence-MIT-blue)](/LICENSE)
![Maintenance](https://img.shields.io/badge/Maintained-yes-success)
![Flutter Status](https://img.shields.io/badge/Flutter_Version->=3.3-success)
![Generic badge](https://img.shields.io/badge/Platforms-Android,_iOS,_MacOS,_Windows,_Linux,_Web-22375C.svg)

This parallax Flutter plugin that adds elegant parallax effects to your widgets using two different modes: a container mode and a widget mode. This plugin helps create dynamic and visually appealing user interfaces with scrolling effects.

## Features
 - Smooth parallax scrolling for background images.
 - Configurable scroll speed for the parallax effect.
 - Simple integration with your existing Flutter projects.
 - Uses provider for state management ensuring efficient updates.

## Installation
Add simple_parallax to your pubspec.yaml file:

```yaml
dependencies:
  flutter:
    sdk: flutter
  simple_parallax: ^0.1.0
```
Replace ^0.1.0 with the latest version from <a alt="pub.dev link" href="https://pub.dev/packages/simple_parallax" target="_blank" rel="noreferrer">pub.dev</a>.

## Usage
The simple_parallax plugin provides two main widgets to create parallax effects:

### Container Mode (SimpleParallaxContainer)
The container mode is used to add a parallax effect to a child widget with a background image.

#### Exemple
```dart
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
              imagePath: 'assets/images/background.webp',
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
```

### Widget Mode (SimpleParallaxWidget)
The widget mode allows you to apply a parallax effect to multiple child widgets within a list.

#### Exemple
```dart
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
```

## API

### SimpleParallaxContainer
- **imagePath** (required): Path to the background image.
- **child** (required): The child widget to be displayed over the background image.
- **speed** (optional): Parallax effect speed. Default value is 0.3.
- **autoSpeed** (optional): Automatically calculates the speed based on the child widget's size.
- **decal** (optional): Offset for the background image. Default value is 1.0.
- **height** (optional): Height of the container. If not specified, uses the height of the screen.

### SimpleParallaxWidget
- **children** (required): List of child widgets with parallax effect.

### SimpleParallaxItem
- **imagePath** (required): Path to the background image.
- **child** (optional): Child widget to be displayed over the background image.
- **speed** (optional): Parallax effect speed. Default value is 0.3.
- **decal** (optional): Offset for the background image. Default value is 1.5.
- **width** (optional): Width of the item.
- **height** (optional): Height of the item.

## Contributing
Contributions are welcome! To contribute to this plugin, please follow these steps:

1. Fork the GitHub repository.
2. Create a branch for your feature or fix.
3. Submit a pull request with a description of your changes.

## License
This plugin is licensed under the MIT License. See the LICENSE file for more details.
