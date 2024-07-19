# SimpleParallax Plugin for Flutter
<a alt="ComApps Logo" href="https://www.comapps.be" target="_blank" rel="noreferrer"><img src="https://www.comapps.be/public/images/CompleteLogoHorizontalMini.png" height="45" style="margin: 15px"></a>

[![Pub Version](https://img.shields.io/pub/v/simple_parallax?color=blue)](https://pub.dev/packages/simple_parallax)
![Maintainer](https://img.shields.io/badge/Maintainer-Raphael_Vrient-purple)
[![License](https://img.shields.io/badge/Licence-MIT-blue)](/LICENSE)
![Maintenance](https://img.shields.io/badge/Maintained-yes-success)
![Flutter Status](https://img.shields.io/badge/Flutter_Version->=3.3-success)
![Generic badge](https://img.shields.io/badge/Platforms-Android,_iOS,_MacOS,_Windows,_Linux,_Web-22375C.svg)

This Flutter plugin provides a simple and customizable parallax effect for your applications. Easily create stunning visual experiences by incorporating parallax scrolling into your widgets.

## Features
 - Smooth parallax scrolling for background images.
 - Configurable scroll speed for the parallax effect.
 - Simple integration with your existing Flutter projects.
 - Uses provider for state management ensuring efficient updates.

## Usage
To use this plugin, wrap your scrollable content with the "**SimpleParallax**" and provide the path to your background image. Adjust the speed parameter to control the intensity of the parallax effect.

## Exemple of SimpleParallaxContainer
```dart
class MyApp extends StatelessWidget {
  /// App demo constructor
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            height: 300, // Optional
            width: 600, // Optional
            child: SimpleParallaxContainer(
              height: 300, // Optional
              imagePath: 'assets/images/background.jpg',
              speed: 0.3, // Optional
              autoSpeed: true, // Optional
              decal: 1.0, // Optional
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

## Exemple of SimpleParallaxWidget
```dart
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
              imagePath: 'assets/images/background.jpg',
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
              imagePath: 'assets/images/background.jpg',
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
