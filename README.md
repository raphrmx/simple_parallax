<a alt="ComApps Logo" href="https://comapps.be" target="_blank" rel="noreferrer"><img src="https://www.comapps.be/wp-content/uploads/2026/09/CompleteLogoHorizontalMini.png" style="margin: 15px"></a>

# Simple Parallax

Parallax widgets for Flutter, in pure Dart. Two modes, either axis, any `ImageProvider`, and no
dependencies beyond the Flutter SDK.

<p>
  <img src="https://public.comapps.be/packages/simple_parallax/container_mode.webp?v=2" alt="Container mode, scrolling down" width="330">
  &nbsp;
  <img src="https://public.comapps.be/packages/simple_parallax/container_mode_horizontal.webp?v=2" alt="Container mode, scrolling sideways" width="330">
</p>
<p>
  <img src="https://public.comapps.be/packages/simple_parallax/item_mode.webp?v=2" alt="Item mode, scrolling down" width="330">
  &nbsp;
  <img src="https://public.comapps.be/packages/simple_parallax/item_mode_horizontal.webp?v=2" alt="Item mode, scrolling sideways" width="330">
</p>

<sub>Container mode above, item mode below; scrolling down on the left, sideways on the right.</sub>

[![Build](https://img.shields.io/github/actions/workflow/status/raphrmx/simple_parallax/ci.yml?branch=main&label=build)](https://github.com/raphrmx/simple_parallax/actions/workflows/ci.yml)
[![Pub Version](https://img.shields.io/pub/v/simple_parallax?color=blue)](https://pub.dev/packages/simple_parallax)
![Maintainer](https://img.shields.io/badge/Maintainer-Raphael-purple)
[![License](https://img.shields.io/badge/Licence-MIT-blue)](/LICENSE)
![Maintenance](https://img.shields.io/badge/Maintained-yes-success)
![Platforms](https://img.shields.io/badge/Platforms-Android,_iOS,_macOS,_Windows,_Linux,_Web-22375C.svg)

## Install

```sh
flutter pub add simple_parallax
```

Requires Flutter 3.22 or later.

## Container mode

One background drifting behind a scrolling area. `autoSpeed` derives the speed from the real scroll
extent, so the background uses exactly the travel `overscan` gives it and never runs out of image:

```dart
SimpleParallaxContainer(
  image: const AssetImage('assets/images/background.webp'),
  autoSpeed: true,
  overscan: 1.5,
  child: Column(children: items),
);
```

| Parameter | Default | Effect |
| --- | --- | --- |
| `image` | required | Any `ImageProvider`: asset, network, file or memory. |
| `child` | required | The scrolling content. |
| `scrollDirection` | `Axis.vertical` | The axis the content scrolls and the background drifts along. |
| `speed` | `0.3` | Background travel per pixel scrolled. Ignored when `autoSpeed` is set. |
| `autoSpeed` | `false` | Derives the speed from the scroll extent. |
| `overscan` | `1.5` | How much larger than the viewport the background is drawn along the scroll axis. |
| `height` | `null` | Forces the viewport height instead of using the constraints. |
| `width` | `null` | Forces the viewport width instead of using the constraints. |
| `fit` | `BoxFit.cover` | How the background fills its layer. |
| `alignment` | `Alignment.center` | How the background sits inside its layer. |

## Item mode

Each block slides its own background as it crosses the viewport. The item finds the enclosing
`Scrollable` by itself, so it works in a `ListView`, a `CustomScrollView`, or anything else that
scrolls:

```dart
ListView(
  children: <Widget>[
    SimpleParallaxItem(
      image: const NetworkImage('https://example.com/cover.jpg'),
      height: 300,
      child: const Center(child: Text('Chapter one')),
    ),
  ],
);
```

| Parameter | Default | Effect |
| --- | --- | --- |
| `image` | required | Any `ImageProvider`. |
| `child` | `null` | Content drawn over the background. |
| `speed` | `1.0` | Fraction of the available travel used, from `0` to `1`. |
| `overscan` | `1.5` | How much larger than the item the background is drawn along the scroll axis. |
| `height` | screen height, or constraints when horizontal | Item height. |
| `width` | constraints, or screen width when horizontal | Item width. |
| `fit` | `BoxFit.cover` | How the background fills its layer. |

`SimpleParallaxWidget` is a convenience scroll view for a handful of items. Prefer a `ListView` when
the list is long enough to need lazy building.

```dart
SimpleParallaxWidget(
  children: <Widget>[
    const SimpleParallaxItem(image: AssetImage('assets/a.webp'), height: 300),
    Container(height: 400, color: Colors.blueGrey),
  ],
);
```

## Scrolling sideways

Both modes work on either axis. The container takes a `scrollDirection`, exactly like a
`ListView`:

```dart
SimpleParallaxContainer(
  image: const AssetImage('assets/images/background.webp'),
  scrollDirection: Axis.horizontal,
  autoSpeed: true,
  child: Row(children: items),
);
```

An item has nothing to pass: it reads the axis from the scrollable it sits in, so dropping it into a
horizontal list is enough. Give it a `width` there, the way you give it a `height` in a vertical one:

```dart
ListView(
  scrollDirection: Axis.horizontal,
  children: <Widget>[
    SimpleParallaxItem(
      image: const AssetImage('assets/images/background.webp'),
      width: 300,
      child: const Center(child: Text('Chapter one')),
    ),
  ],
);
```

`SimpleParallaxWidget` takes the same `scrollDirection` and lays its blocks out in a `Row` when it
is horizontal.

## How it performs

Scrolling repaints the background and nothing else. In container mode the moving layer sits behind a
`RepaintBoundary` and only its transform is rebuilt, so your content is built once. In item mode the
background is painted by a `Flow` bound directly to the scroll position, which repaints without
rebuilding a single widget.

## Migrating from 0.1.x

| Before | Now |
| --- | --- |
| `imagePath: 'assets/a.webp'` | `image: AssetImage('assets/a.webp')` |
| `decal: 1.5` | `overscan: 1.5` |
| `SimpleParallaxItem(speed: 0.3)` | `speed` is a `0..1` fraction now, default `1.0` |
| `SimpleParallaxItem` only inside `SimpleParallaxWidget` | works inside any scrollable |
| `autoSpeed` needed a `GlobalKey` on your child | nothing to pass |

The package is no longer a Flutter plugin: the native platform folders are gone, and so is the
`provider` dependency.

## Dependencies

None beyond the Flutter SDK.

## Tests

```sh
flutter test
```

## License

MIT, see [LICENSE](LICENSE).
