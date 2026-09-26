<a alt="ComApps Logo" href="https://comapps.be" target="_blank" rel="noreferrer"><img src="https://www.comapps.be/wp-content/uploads/2026/09/CompleteLogoHorizontalMini.png" style="margin: 15px"></a>

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
[![Licence](https://img.shields.io/badge/Licence-MIT-5B6470)](LICENSE)
![Platforms](https://img.shields.io/badge/Platforms-Android,_iOS,_macOS,_Windows,_Linux,_Web-22375C.svg)

## Install

```sh
flutter pub add simple_parallax
```

Requires Flutter 3.22 or later.

## Container mode

One background drifting behind a scrolling area. Nothing is required beyond the image and the
content: the background spends exactly the travel `overscan` gives it, over the whole page, and
never runs out of image.

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

### Slivers

The container is a `CustomScrollView`, and `child` is put in a single box sliver. Use the
`.slivers` constructor instead to hand it the slivers yourself, so the content builds as it scrolls
and other slivers can ride over the background:

```dart
SimpleParallaxContainer.slivers(
  image: const AssetImage('assets/images/background.webp'),
  slivers: <Widget>[
    const SliverAppBar(title: Text('Chapters'), floating: true),
    SliverList.builder(
      itemCount: 500,
      itemBuilder: (BuildContext context, int index) =>
          ListTile(title: Text('Chapter $index')),
    ),
  ],
);
```

Everything else behaves the same: the background still drifts along `scrollDirection`, over the real
scroll extent. On a very long list that extent is large, so the same travel is spread thin and the
drift becomes hard to see. Raise `overscan` to give it more room, or reach for item mode, where each
block has a crossing of its own.

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

`SimpleParallaxWidget` is a convenience scroll view for a list of items. It is a `CustomScrollView`
over one `SliverList`, so the blocks build as they come into view and each one is laid out across
the full cross axis, the way a `ListView` lays its children out.

```dart
SimpleParallaxWidget(
  children: <Widget>[
    const SimpleParallaxItem(image: AssetImage('assets/a.webp'), height: 300),
    Container(height: 400, color: Colors.blueGrey),
  ],
);
```

## A widget as the background

`image` covers the common case. When the background is not a plain image, pass `background` instead
and hand over the layer itself:

```dart
SimpleParallaxContainer(
  background: const DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[Color(0xFF1A237E), Color(0xFF80DEEA)],
      ),
    ),
  ),
  child: Column(children: items),
);
```

Both modes take it, and so does the `.slivers` form: it is a parameter, not a constructor of its own.
Exactly one of `image` and `background` is required, and an assert fires if both or neither is given.
Everything else behaves the same, `speed`, `overscan` and the axis included.

The layer is handed the cross-axis extent and `overscan` times the scrolled extent, both tight, so
anything that fills the box it is given works: a gradient, a `Stack` of several layers, a video, a
shader, a `CachedNetworkImage`. `fit` and `alignment` apply to `image` only, since a widget fills the
layer as it stands.

A layer that carries an aspect ratio of its own has to be covered the way `BoxFit.cover` covered it
for you. A video, for instance:

```dart
FittedBox(
  fit: BoxFit.cover,
  clipBehavior: Clip.hardEdge,
  child: SizedBox(
    width: controller.value.size.width,
    height: controller.value.size.height,
    child: VideoPlayer(controller),
  ),
)
```

`ContainerVideoDemo` in the example runs that end to end. `video_player` is a dependency of the
example, not of this package.

This is also how you reach the `Image` parameters the package does not forward. A network background
wants a `loadingBuilder` and an `errorBuilder`, and a background drawn at 1.5 times the viewport is
the largest bitmap on the page, so `cacheHeight` is worth passing:

```dart
SimpleParallaxItem(
  height: 300,
  background: Image(
    image: const NetworkImage('https://example.com/cover.jpg'),
    fit: BoxFit.cover,
    cacheHeight: 900,
    loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? progress) =>
        progress == null ? child : const ColoredBox(color: Color(0xFF263238)),
    errorBuilder: (BuildContext context, Object error, StackTrace? stack) =>
        const ColoredBox(color: Color(0xFF263238)),
  ),
);
```

## Pushing the background in

`parallax` moves the background, `zoom` scales it. The two are separate objects, so either works on
its own:

```dart
SimpleParallaxContainer(
  image: const AssetImage('assets/images/background.webp'),
  parallax: const ParallaxProperties(speed: 0.3),
  zoom: const ZoomProperties(0.25),
  child: Column(children: items),
);
```

| What you want | What you write |
| --- | --- |
| Drift alone | `parallax: ParallaxProperties(speed: 0.3)` |
| A push-in alone | `parallax: ParallaxProperties(speed: 0), zoom: ZoomProperties(0.25)` |
| Both | both, as above |
| Neither | leave both out |

The figure a `ZoomProperties` takes is the scale the background gains across its travel: `0.25` ends
a quarter larger. It means the same thing in both modes, the container scaling across the page and
an item across its own crossing of the viewport.

A negative figure runs the same range backwards, so the background starts enlarged and settles
rather than pushing in:

| `zoom` | The background |
| --- | --- |
| `0.3` | Starts at `1`, ends at `1.3`, pushing in |
| `-0.3` | Starts at `1.3`, ends at `1`, coming to rest |

The scale turns about the middle of the viewport rather than the middle of the layer, which sits off
screen and moves as the background drifts. That is what keeps the two settings independent: turning
the zoom up does not make the drift faster.

The scale never goes below `1`, either way round, and it cannot: `overscan` pads the scrolled axis
alone, so the layer is exactly as wide as the viewport across that axis. Anything smaller would show
the page behind it down both sides. That is also why there is nothing to work out between `zoom` and
`overscan`.

### When the background already looks close at rest

That is almost never the zoom, and usually not `overscan` either. It is what `BoxFit.cover` has to
crop between the shape of your image and the shape of the block.

`cover` scales by whichever of `boxWidth / imageWidth` and `boxHeight / imageHeight` is larger, and
`overscan` only raises the second. So on a wide, short block with an upright image the width decides,
and `overscan` changes nothing you can see: it makes the layer taller, which is room for the drift,
not a different framing.

A portrait image of 1392x1765 in a block 927 wide shows this:

| Block | `overscan` | `cover` driven by | Of the image height, you see |
| --- | --- | --- | --- |
| 430 tall | `2` | the width | 37% |
| 430 tall | `1` | the width | 37% |
| 700 tall | `2` | the height | 50% |
| a screenful | `1.4` | the height | 71% |

So the lever is the shape of the block, or an image shaped more like it. Not `overscan`, and not
`zoom`, which only multiplies whatever `cover` already decided.

The zoom does compound with all of it, though, and that is worth watching at the far end: at
`overscan: 2` with a zoom of `0.5` the layer is drawn at three times the block extent by the time it
is done, and a large figure will soften a modest asset.

## Softening the background

`blur` is the third thing the scroll can drive, and it is read exactly like `zoom`: a positive
figure is gained across the travel, a negative one is spent across it.

```dart
SimpleParallaxItem(
  image: const AssetImage('assets/images/background.webp'),
  height: 620,
  blur: const BlurProperties(16),
  child: const Center(child: Text('Chapter one')),
);
```

| What you write | The background |
| --- | --- |
| `BlurProperties(16)` | Arrives sharp, leaves at a sigma of sixteen |
| `BlurProperties(-16)` | Arrives at a sigma of sixteen, leaves sharp |
| nothing | Never filtered at all |

The figure is a sigma in logical pixels, not a fraction: a zoom of `0.3` means three tenths of the
layer, a blur of `16` means sixteen pixels whatever the layer is. Sixteen is a heavy blur on a phone
and a moderate one on a desktop, so it is worth setting per breakpoint if the page is responsive.

Only the background is filtered. `child` sits over it untouched, which is what makes a caption or a
form readable over a background that is going soft.

`blur` and `zoom` are independent and can be given together, the blur applying to the layer before
the zoom scales it.

### What it costs

The drift and the zoom are transforms: the background is drawn once and moved. A blur is a filter,
so the layer is run through a gaussian on every frame it moves, at `overscan` times the viewport
along the scrolled axis. That is the one setting in this package that can cost a frame on a low-end
device, and it is worth profiling on the oldest phone you support rather than taking a figure from
here.

Two things are done for you. The sigma is rounded to a quarter of a pixel, so the filter itself is
left alone between frames that would look the same. And a sigma of zero pushes no layer at all,
which is the whole of one end of a `blur` given in either direction.

## Finishing before the end

Left alone, a zoom and a blur are spread over the whole travel. `reach` packs one into the stretch
before a point, so it is done there instead:

```dart
SimpleParallaxItem(
  image: const AssetImage('assets/images/background.webp'),
  height: 620,
  zoom: const ZoomProperties(0.6, reach: 0.5),
  child: const Center(child: Text('Chapter one')),
);
```

`0.5` is the middle of the screen, which is the one you want nine times in ten. What happens over
the rest of the travel is `back`: the far end held, or the same range run backwards.

Because each effect carries its own `reach` and `back`, a zoom running the whole way and a blur
stopping at the middle sit in the same widget. With the sign saying which end the effect starts
from, that covers six shapes per effect:

| What you write | The background |
| --- | --- |
| `ZoomProperties(0.6)` | Pushes in across the whole crossing |
| `ZoomProperties(0.6, reach: 0.5)` | Pushes in to the middle and stays there |
| `ZoomProperties(0.6, reach: 0.5, back: true)` | Pushes in to the middle and backs out again |
| `BlurProperties(-16)` | Arrives soft and clears |
| `BlurProperties(-16, reach: 0.5)` | Arrives soft, clear from the middle on |
| `BlurProperties(-16, reach: 0.5, back: true)` | Arrives soft, sharp in passing, soft again |

Any other fraction moves the point: `reach: 0.3` is done a third of the way in and spends the rest
of the crossing holding or coming back.

The drift is never shaped this way. It follows the scroll whatever `reach` is set to, because a
background walking back up the page would read as the content scrolling the other way.

## A tint over the background

A photo is rarely the right contrast for text on its own. `overlay` is a fixed layer of colour over
the background and under the content, so the image is knocked back and nothing written on it is:

```dart
SimpleParallaxItem(
  image: const AssetImage('assets/images/background.webp'),
  height: 620,
  overlay: const OverlayProperties.darken(0.45),
  child: const Center(child: Text('Chapter one')),
);
```

| What you write | What is drawn |
| --- | --- |
| `OverlayProperties.darken(0.45)` | Black at 45 percent |
| `OverlayProperties.lighten(0.2)` | White at 20 percent |
| `OverlayProperties(Color(0xFF1A237E), opacity: 0.5)` | Any colour, at any opacity |
| `OverlayProperties.gradient(LinearGradient(...))` | A scrim that fades across the background |

The gradient form is what a caption sitting at one edge wants: opaque enough to read against there,
and gone by the other edge, so the image is not dulled where nothing is drawn over it.

Fixed means fixed. It does not drift, scale or blur with the background: it stays where it is while
the background moves under it, which is what makes it read as a treatment of the page rather than as
part of the image.

## The mouse wheel

A `Scrollable` lands a wheel notch on a single frame, and it reads the wheel on its own axis alone.
Both show in a parallax. The background moves in steps instead of drifting, and a sideways view does
not move at all under a plain wheel, which carries a vertical delta and nothing else.

`smooth` fixes both, and it is on by default, since a stepping background is what a parallax is
there to avoid. Turn it off to get the platform behaviour back:

```dart
SimpleParallaxContainer(
  image: const AssetImage('assets/images/background.webp'),
  smooth: false,
  child: Column(children: items),
);
```

Dragging, flinging and touch are untouched either way, so this is a mouse and trackpad setting.

`SimpleParallaxWidget` takes the same flag, and the easing lives in a controller of its own, so it
turns itself off when you pass a `controller`. Passing both `smooth: true` and a controller is an
error rather than a silent no-op.

One thing the package deliberately leaves alone: a mouse cannot drag a scroll view in Flutter at
all, since `dragDevices` covers touch, stylus and trackpad. That is an app-wide decision, so it
belongs to a `ScrollBehavior` of yours rather than to a widget. The example makes it in one class,
`_DragScrollBehavior` in [example/lib/main.dart](example/lib/main.dart).

## Scrolling sideways

Both modes work on either axis. The container takes a `scrollDirection`, exactly like a
`ListView`:

```dart
SimpleParallaxContainer(
  image: const AssetImage('assets/images/background.webp'),
  scrollDirection: Axis.horizontal,
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

`SimpleParallaxWidget` takes the same `scrollDirection` and lays its blocks out along that axis.

## How it performs

Scrolling repaints the background and nothing else. In container mode the moving layer sits behind a
`RepaintBoundary` and only its transform is rebuilt, so your content is built once. In item mode the
background is painted by a `Flow` bound directly to the scroll position, which repaints without
rebuilding a single widget.

Both scroll views are `CustomScrollView`s, so content handed over as slivers is built only as far as
the viewport reaches.

## Migrating from 1.x

The settings are grouped into four objects, one per effect, so each carries its own `reach` and
`back` instead of sharing one pair. `speed` now means the same thing in both modes: a fraction of
the available travel, `1` spending all of it over the whole scroll. That is what `autoSpeed` used to
do, so the flag is gone.

| Before | Now |
| --- | --- |
| `speed: 0.4, overscan: 2` | `parallax: ParallaxProperties(speed: 0.4, overscan: 2)` |
| `autoSpeed: true` | nothing: `speed` defaults to `1`, which is the same thing |
| `speed: 0.3` on a container | a fraction now, not a travel per pixel. Pick one between `0` and `1` |
| `zoom: 0.25` | `zoom: ZoomProperties(0.25)` |
| `blur: 16` | `blur: BlurProperties(16)` |
| `zoom: 0.6, reach: 0.5, back: true` | `zoom: ZoomProperties(0.6, reach: 0.5, back: true)` |
| a hand-rolled scrim in `child` | `overlay: OverlayProperties.darken(0.45)` |

Nothing else moves. `image`, `background`, `child`, `slivers`, `scrollDirection`, `height`, `width`,
`fit` and `alignment` are where they were. `smooth` is too, but it now defaults to `true`; pass
`smooth: false` to keep the old behaviour.

## Migrating from 0.1.x

| Before | Now |
| --- | --- |
| `imagePath: 'assets/a.webp'` | `image: AssetImage('assets/a.webp')` |
| `decal: 1.5` | `overscan: 1.5` |
| `SimpleParallaxItem(speed: 0.3)` | `parallax: ParallaxProperties(speed: 0.3)` |
| `SimpleParallaxItem` only inside `SimpleParallaxWidget` | works inside any scrollable |
| `autoSpeed` needed a `GlobalKey` on your child | gone: a `speed` of `1` is the same thing |

The package is no longer a Flutter plugin: the native platform folders are gone, and so is the
`provider` dependency.

## Dependencies

None beyond the Flutter SDK.

## Example

`example/` is one app with thirteen screens: container mode and item mode, each vertical and
sideways, the container over slivers, both directions of the zoom and both of the blur, an effect
finishing at the middle and one sent back from it, the three forms of the overlay, a widget
background in each mode, and a looping video behind each.

```sh
cd example && flutter run
```

## Tests

```sh
flutter test
```

## License

MIT, see [LICENSE](LICENSE).
