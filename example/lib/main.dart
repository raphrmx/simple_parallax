import 'package:flutter/material.dart';
import 'package:simple_parallax/simple_parallax.dart';

void main() => runApp(const ExampleApp());

const AssetImage _background = AssetImage('assets/images/background.webp');

/// The combinations the package offers: two modes, two axes, and the sliver
/// form of the container.
class ExampleApp extends StatelessWidget {
  /// Creates the example app.
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Parallax',
      home: Builder(
        builder: (BuildContext context) => Scaffold(
          appBar: AppBar(title: const Text('Simple Parallax')),
          body: ListView(
            children: <Widget>[
              _entry(
                context,
                'Container mode, vertical',
                const ContainerVerticalDemo(),
              ),
              _entry(
                context,
                'Container mode, horizontal',
                const ContainerHorizontalDemo(),
              ),
              _entry(
                context,
                'Container mode, slivers',
                const ContainerSliversDemo(),
              ),
              _entry(
                context,
                'Item mode, vertical',
                const ItemVerticalDemo(),
              ),
              _entry(
                context,
                'Item mode, horizontal',
                const ItemHorizontalDemo(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _entry(BuildContext context, String label, Widget demo) => ListTile(
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (BuildContext context) => demo),
        ),
      );
}

/// Container mode: one background drifting behind a scrolling column.
///
/// `autoSpeed` derives the speed from the real scroll extent, so the background
/// uses exactly the travel `overscan` gives it and never runs out of image.
class ContainerVerticalDemo extends StatelessWidget {
  /// Creates the vertical container demo.
  const ContainerVerticalDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SimpleParallaxContainer(
        image: _background,
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
    );
  }
}

/// The same container, scrolling sideways.
///
/// Only `scrollDirection` changes: the background then drifts on the horizontal
/// axis, and `overscan` widens it instead of heightening it.
class ContainerHorizontalDemo extends StatelessWidget {
  /// Creates the horizontal container demo.
  const ContainerHorizontalDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SimpleParallaxContainer(
        image: _background,
        scrollDirection: Axis.horizontal,
        autoSpeed: true,
        overscan: 1.5,
        child: Row(
          children: List<Widget>.generate(
            20,
            (int index) => Container(
              height: 150,
              width: 150,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              color: const Color(0xCCFFFFFF),
              child: Center(child: Text('Item $index')),
            ),
          ),
        ),
      ),
    );
  }
}

/// Container mode over slivers, so the content builds as it scrolls.
///
/// `SimpleParallaxContainer.slivers` takes the content as slivers instead of a
/// single child, which lets a `SliverAppBar` ride over the background and a
/// list build only the rows the viewport needs.
class ContainerSliversDemo extends StatelessWidget {
  /// Creates the sliver container demo.
  const ContainerSliversDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SimpleParallaxContainer.slivers(
        image: _background,
        autoSpeed: true,
        overscan: 1.5,
        slivers: <Widget>[
          const SliverAppBar(
            title: Text('Slivers'),
            backgroundColor: Color(0x66000000),
            foregroundColor: Color(0xFFFFFFFF),
            floating: true,
          ),
          SliverList.builder(
            itemCount: 40,
            itemBuilder: (BuildContext context, int index) => Container(
              height: 100,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: const Color(0xCCFFFFFF),
              child: Center(child: Text('Item $index')),
            ),
          ),
        ],
      ),
    );
  }
}

/// Item mode: each block slides its own background as it crosses the viewport.
///
/// `SimpleParallaxWidget` is a convenience scroll view built on a `SliverList`,
/// so its blocks build as they come into view; a `ListView` works just as well.
class ItemVerticalDemo extends StatelessWidget {
  /// Creates the vertical item demo.
  const ItemVerticalDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SimpleParallaxWidget(
        children: <Widget>[
          Container(height: 400, color: Colors.red),
          const SimpleParallaxItem(
            image: _background,
            height: 300,
            child: Center(child: Text('TEST 1')),
          ),
          Container(height: 250, color: Colors.greenAccent),
          const SimpleParallaxItem(
            image: _background,
            height: 300,
            speed: 0.5,
            child: Center(child: Text('TEST 2')),
          ),
          Container(height: 500, color: Colors.blueGrey),
        ],
      ),
    );
  }
}

/// The same items in a horizontal list.
///
/// Nothing is passed to the items about the axis: each one reads it from the
/// scrollable it sits in. Give them a `width` here, the way you give them a
/// `height` in a vertical list.
class ItemHorizontalDemo extends StatelessWidget {
  /// Creates the horizontal item demo.
  const ItemHorizontalDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          Container(width: 400, color: Colors.red),
          const SimpleParallaxItem(
            image: _background,
            width: 300,
            child: Center(child: Text('TEST 1')),
          ),
          Container(width: 250, color: Colors.greenAccent),
          const SimpleParallaxItem(
            image: _background,
            width: 300,
            speed: 0.5,
            child: Center(child: Text('TEST 2')),
          ),
          Container(width: 500, color: Colors.blueGrey),
        ],
      ),
    );
  }
}
