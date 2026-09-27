# Simple Parallax

Parallax widgets for Flutter, in pure Dart. Two modes, either axis, any `ImageProvider` or any
widget as the background, and no dependencies beyond the Flutter SDK. The drift, the zoom, the blur
and the overlay are each configured on their own.

<p>
  <img src="https://public.comapps.be/packages/simple_parallax/container_mode.webp?v=3" alt="Container mode, scrolling down" width="330">
  &nbsp;
  <img src="https://public.comapps.be/packages/simple_parallax/container_mode_horizontal.webp?v=3" alt="Container mode, scrolling sideways" width="330">
</p>
<p>
  <img src="https://public.comapps.be/packages/simple_parallax/item_mode.webp?v=3" alt="Item mode, scrolling down" width="330">
  &nbsp;
  <img src="https://public.comapps.be/packages/simple_parallax/item_mode_horizontal.webp?v=3" alt="Item mode, scrolling sideways" width="330">
</p>

<p>
  <img src="https://public.comapps.be/packages/simple_parallax/widget_background.webp?v=3" alt="A gradient as the background" width="330">
</p>

<sub>Container mode on the first row, item mode on the second; scrolling down on the left, sideways
on the right. Last one: the background as a widget rather than an image.</sub>

[![Live demo](https://img.shields.io/badge/Live_demo-comapps.web.app-3c9a70)](https://comapps.web.app/simple_parallax/)
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

## Container mode

One background drifting behind a scrolling area, over the whole page.

```dart
SimpleParallaxContainer(
  image: const AssetImage('assets/images/background.webp'),
  child: Column(children: items),
);
```

| Parameter | Default | Effect |
| --- | --- | --- |
| `image` | one of the two | Any `ImageProvider`: asset, network, file or memory. |
| `background` | one of the two | The background as a widget, when the layer is not a plain image. |
| `child` | required | The scrolling content, laid out as a single box sliver. |
| `slivers` | required | The scrolling content as slivers, on the `.slivers` constructor. |
| `scrollDirection` | `Axis.vertical` | The axis the content scrolls and the background drifts along. |
| `parallax` | `ParallaxProperties()` | How the background drifts: its `speed` and its `overscan`. |
| `zoom` | `null` | How it scales down the page. |
| `blur` | `null` | How it is blurred down the page. |
| `overlay` | `null` | A fixed tint over it, under the content. |
| `height` | `null` | Forces the viewport height instead of using the constraints. |
| `width` | `null` | Forces the viewport width instead of using the constraints. |
| `fit` | `BoxFit.cover` | How the background fills its layer. Applies to `image` only. |
| `alignment` | `Alignment.center` | How the background sits inside its layer. Applies to `image` only. |
| `smooth` | `true` | Eases the mouse wheel in, and brings it to a horizontal view. |

The `.slivers` constructor takes the slivers itself, so the content builds as it scrolls and a
`SliverAppBar` can ride over the background.

## Item mode

Each block slides its own background as it crosses the viewport. The item finds the enclosing
`Scrollable` by itself, so it works in a `ListView`, a `CustomScrollView`, or anything else that
scrolls.

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
| `image` | one of the two | Any `ImageProvider`. |
| `background` | one of the two | The background as a widget, when the layer is not a plain image. |
| `child` | `null` | Content drawn over the background. |
| `parallax` | `ParallaxProperties()` | How the background drifts: its `speed` and its `overscan`. |
| `zoom` | `null` | How it scales as the block crosses. |
| `blur` | `null` | How it is blurred as the block crosses. |
| `overlay` | `null` | A fixed tint over it, under `child`. |
| `height` | screen height, or constraints when horizontal | Item height. |
| `width` | constraints, or screen width when horizontal | Item width. |
| `fit` | `BoxFit.cover` | How the background fills its layer. Applies to `image` only. |

`SimpleParallaxWidget` is a scroll view for a list of items, laying each one across the full cross
axis the way a `ListView` does.

## Beyond `image`

`background` takes the layer itself instead of an `ImageProvider`, on both modes and on `.slivers`.
It is handed the cross-axis extent and `overscan` times the scrolled extent, both tight, so anything
that fills the box it is given works: a gradient, a `Stack`, a shader, a video. `fit` and
`alignment` apply to `image` only, since a widget fills the layer as it stands.

It is also how you reach the `Image` parameters the package does not forward. A background drawn at
one and a half times the viewport is the largest bitmap on the page, so `cacheHeight` earns its
keep:

```dart
SimpleParallaxItem(
  height: 300,
  background: Image(
    image: const NetworkImage('https://example.com/cover.jpg'),
    fit: BoxFit.cover,
    cacheHeight: 900,
    errorBuilder: (BuildContext context, Object error, StackTrace? stack) =>
        const ColoredBox(color: Color(0xFF263238)),
  ),
);
```

A layer carrying an aspect ratio of its own, a video for one, has to be covered the way `BoxFit`
covered it for you. `ContainerVideoDemo` in the example does that end to end.

## The four effects

Each one is its own object, so they are set, left out and shaped independently.

```dart
SimpleParallaxItem(
  image: const AssetImage('assets/images/background.webp'),
  height: 620,
  parallax: const ParallaxProperties(speed: 0.4),
  zoom: const ZoomProperties(0.6, reach: 0.5, back: true),
  blur: const BlurProperties(-16),
  overlay: const OverlayProperties.darken(0.45),
  child: const Center(child: Text('Chapter one')),
);
```

| Object | What it drives |
| --- | --- |
| `ParallaxProperties(speed, overscan)` | The drift. `speed` is the fraction of the available travel it spends, `overscan` the image it has to spend. |
| `ZoomProperties(amount, {reach, back})` | The scale. `0.25` ends a quarter larger. |
| `BlurProperties(sigma, {reach, back})` | The blur, as a sigma in logical pixels. |
| `OverlayProperties` | A fixed tint. `.darken`, `.lighten`, a colour, or `.gradient`. |

A negative `amount` or `sigma` runs the range backwards, so the background settles or clears instead
of pushing in or softening. `reach` packs the effect into the stretch before a point, `0.5` being
the middle of the screen, and `back` runs it the other way over the rest. Between the sign and the
pair, that is six shapes per effect. The drift is never shaped this way: it follows the scroll,
because a background walking back up the page reads as the content scrolling the other way.

The overlay is fixed. It does not drift, scale or blur with the background, which is what makes it
read as a treatment of the page rather than as part of the image.

## How it performs

Scrolling this package repaints the background and rebuilds nothing.

**Container mode.** The moving layer sits behind a `RepaintBoundary` and the scroll drives a
transform on it alone. Your content is built once and never touched again, however far the page
runs.

**Item mode.** The background is painted by a `Flow` bound straight to the scroll position, so it
repaints without a single widget rebuild. No `setState`, no `AnimatedBuilder` over your subtree, no
listener rebuilding a block because the page moved under it.

**Both.** The two scroll views are `CustomScrollView`s, so content handed over as slivers is built
only as far as the viewport reaches. A list of five hundred blocks costs what the ones on screen
cost.

The drift and the zoom are transforms: the background is drawn once and moved, which is nearly free.
The blur is the one exception, and the one setting here that can cost a frame, since it runs a
gaussian over `overscan` times the viewport on every frame the layer moves. Profile it on the oldest
phone you support. Two things are done for you: the sigma is rounded to a quarter of a pixel so the
filter is left alone between frames that would look the same, and a sigma of zero pushes no layer at
all.

## Moving from 1.x

| Before | Now |
| --- | --- |
| `speed: 0.4, overscan: 2` | `parallax: ParallaxProperties(speed: 0.4, overscan: 2)` |
| `autoSpeed: true` | nothing: `speed` defaults to `1`, which is the same thing |
| `speed: 0.3` on a container | a fraction now, not a travel per pixel. Pick one between `0` and `1` |
| `zoom: 0.25` | `zoom: ZoomProperties(0.25)` |
| `blur: 16` | `blur: BlurProperties(16)` |
| `zoom: 0.6, reach: 0.5, back: true` | `zoom: ZoomProperties(0.6, reach: 0.5, back: true)` |
| a hand-rolled scrim in `child` | `overlay: OverlayProperties.darken(0.45)` |

Nothing else moves, except `smooth`, which now defaults to `true`. Pass `smooth: false` for the
platform wheel behaviour. Coming from 0.1.x, see the [CHANGELOG](CHANGELOG.md).

## Example

`example/` is one app with thirteen screens, and it is what the
[live demo](https://comapps.web.app/simple_parallax/) runs: both modes, each vertical and sideways,
the container over slivers, both directions of the zoom and of the blur, an effect finishing at the
middle and one sent back from it, the three forms of the overlay, a widget background in each mode,
and a looping video behind each.

```sh
cd example && flutter run
```

It also carries the one thing this page only mentions: `_DragScrollBehavior`, which lets a mouse
drag a scroll view, since Flutter's `dragDevices` covers touch, stylus and trackpad and not the
mouse. That is an app-wide decision, so it belongs to a `ScrollBehavior` of yours rather than to a
widget here.

## Dependencies

None beyond the Flutter SDK.

## Tests

```sh
flutter test
```

## License

MIT, see [LICENSE](LICENSE).
