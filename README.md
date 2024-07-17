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

```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SimpleParallax(
          imagePath: 'assets/images/background.jpg', // Background image
          speed: 0.3, // Speed of parallax effect 
          decal: 1.0, // Start position of background image
          // Scrollable content
          child: Column(
            children: List.generate(
              20,
              (index) => Container(
                height: 100,
                margin: const EdgeInsets.symmetric(vertical: 10),
                color: Colors.white.withOpacity(0.8),
                child: Center(child: Text('Item $index')),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

## Tip to avoid background image overflow
Calculate best parallax speed
```dart
// Use a Statefull widget
class _MyAppState extends State<MyApp> {
  double _contentHeight = 1;
  // We use a GlobalKey to get a reference to the content widget.
  final _contentKey = GlobalKey();
  
  void _calculateHeight() {
    // This method uses the GlobalKey to get the size of the content after rendering. 
    // RenderBox is used to access the dimensions of the widget.
    final RenderBox renderBox = _columnKey.currentContext!.findRenderObject() as RenderBox;
    setState(() {
      _contentHeight = renderBox.size.height;
    });
  }

  @override
  void initState() {
    super.initState();
    // We add a postFrameCallback in initState to calculate the height of
    // the content after the widget has been rendered.
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
              speed: widgetHeight / _contentHeight, // Calculating the ideal speed
              decal: 1.0,
              child: Column(
                key: _contentKey,
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
```
