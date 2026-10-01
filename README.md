# Simple Parallax

Parallax backgrounds for Flutter, in pure Dart with no dependencies. Put one background behind a
whole page, or give each block of a list its own.

<p>
  <img src="https://public.comapps.be/packages/simple_parallax/travel_page.webp?v=1" alt="A travel page, every picture on it a parallax block" width="670">
</p>

<p>
  <img src="https://public.comapps.be/packages/simple_parallax/container_mode.webp?v=4" alt="Container mode, scrolling down" width="330">
  &nbsp;
  <img src="https://public.comapps.be/packages/simple_parallax/container_mode_horizontal.webp?v=4" alt="Container mode, scrolling sideways" width="330">
</p>
<p>
  <img src="https://public.comapps.be/packages/simple_parallax/item_mode.webp?v=4" alt="Item mode, scrolling down" width="330">
  &nbsp;
  <img src="https://public.comapps.be/packages/simple_parallax/item_mode_horizontal.webp?v=4" alt="Item mode, scrolling sideways" width="330">
</p>

<p>
  <img src="https://public.comapps.be/packages/simple_parallax/widget_background.webp?v=4" alt="A gradient as the background" width="330">
  &nbsp;
  <img src="https://public.comapps.be/packages/simple_parallax/item_mode_carousel.webp?v=2" alt="A carousel in a page, each card drifting with the row and with the page" width="330">
</p>

[![Video tour](https://img.shields.io/badge/Video-Guided_tour-c4302b?logo=youtube&logoColor=white)](https://www.youtube.com/watch?v=RO3DF8OXI5w)
[![Live demo](https://img.shields.io/badge/Live_demo-packages.comapps.be-3c9a70)](https://packages.comapps.be/simple_parallax/)
[![Pub Version](https://img.shields.io/pub/v/simple_parallax?color=0175C2)](https://pub.dev/packages/simple_parallax)
[![Build](https://img.shields.io/github/actions/workflow/status/raphrmx/simple_parallax/ci.yml?branch=main&label=build)](https://github.com/raphrmx/simple_parallax/actions/workflows/ci.yml)
![Maintainer](https://img.shields.io/badge/Maintainer-Raphael_Vrient-733d90)
[![Licence](https://img.shields.io/badge/Licence-MIT-8C6A3F)](LICENSE)
![Platforms](https://img.shields.io/badge/Platforms-Android,_iOS,_macOS,_Windows,_Linux,_Web-22375C.svg)

## Install

```sh
flutter pub add simple_parallax
```

Requires Flutter 3.22 or later.

## One background behind a page

```dart
SimpleParallaxContainer(
  image: const AssetImage('assets/images/background.webp'),
  child: Column(children: items),
);
```

## A background per block

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

That is all it takes. Everything below is optional.

## Effects

Both widgets take the same four, each set on its own:

```dart
SimpleParallaxItem(
  image: const AssetImage('assets/images/background.webp'),
  height: 620,
  parallax: const ParallaxProperties(speed: 0.4),
  zoom: const ZoomProperties(0.6),
  blur: const BlurProperties(-16),
  overlay: const OverlayProperties.darken(0.45),
);
```

| Parameter | Effect |
| --- | --- |
| `parallax` | The drift. `speed` goes from `0` to `1`, `overscan` is how much larger than the view the background is drawn. |
| `zoom` | Grows as it crosses: `0.25` ends a quarter larger. Negative runs it the other way. |
| `blur` | Softens as it crosses, as a sigma in pixels. Negative sharpens instead. |
| `overlay` | A fixed tint: `.darken`, `.lighten`, a colour or a `.gradient`. |

`zoom` and `blur` also take `reach` and `back`, to finish part way, `0.5` being the middle of the
screen, then hold there or turn back.

## Leaning with the mouse or the phone

`tilt` leans the background away from an offset you feed it, on top of the drift. A
`TiltController` smooths that offset, and `PointerTilt` aims it at the mouse:

```dart
PointerTilt(
  controller: tilt, // a TiltController, created with a vsync
  child: SimpleParallaxContainer(
    image: const AssetImage('assets/images/background.webp'),
    tilt: TiltProperties(tilt, distance: 24),
    child: Column(children: items),
  ),
);
```

For the phone, aim the same controller from how the phone is held: the example reads the
accelerometer with `sensors_plus` in an app, and the `deviceorientation` event in a browser, which
Safari on iOS only sends once a tap has allowed it. The package itself stays free of dependencies.
Items take `tilt` as well, so a whole page of them can lean with one controller.

## Good to know

- `background` takes a widget instead of an `image`: a gradient, a video, or an `Image` you set up
  yourself, with `cacheHeight` or an `errorBuilder`.
- The container scrolls sideways with `scrollDirection: Axis.horizontal`. Items read the axis of
  the list they sit in.
- `SimpleParallaxContainer.slivers` takes slivers, for a long list or a `SliverAppBar` over the
  background.
- `SimpleParallaxWidget`, and `SimpleParallaxWidget.builder` for long lists, is a ready-made scroll
  view for items.
- Items take `borderRadius` for a rounded card, and `alignment` to keep the top of a portrait in
  the frame.
- For an image that loads over the network, `placeholderColor` fills the block meanwhile, `fadeIn`
  brings the picture in, and `errorBuilder` takes its place if it fails.
- In nested scrollables, `scrollAxis` picks the one an item follows, for instance the page around
  a carousel, and `crossParallax` has it follow the other one as well.
- The mouse wheel is eased on desktop and the web. To drive the view from outside and keep that,
  pass a `SmoothScrollController` as its `controller`.
- The platform's reduced motion setting is followed: backgrounds hold still. Pass
  `respectReducedMotion: false` to keep the effect regardless.

Every parameter is documented in the
[API reference](https://pub.dev/documentation/simple_parallax/latest/).

## Performance

Scrolling repaints the background and rebuilds no widget, and lists build as they scroll. Images
are decoded at the size they are drawn, not at full resolution. The drift and the zoom cost next to
nothing; the blur is the one effect worth profiling on an older phone. A tilt repaints the
background each time its offset moves, and a `TiltController` stops ticking once it has settled.

## Example

`example/` is the app behind the [live demo](https://packages.comapps.be/simple_parallax/), one screen
per feature.

```sh
cd example && flutter run
```

It also shows how to let a mouse drag a list, which Flutter does not allow by default:
`_DragScrollBehavior`.

## Upgrading

Coming from 1.x or 0.1.x, see the [CHANGELOG](CHANGELOG.md).

## License

MIT, see [LICENSE](LICENSE).
