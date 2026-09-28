# SimpleParallax Versions

## 2.3.1

### Fixed

- Turning `smooth` on or off on a view already on screen no longer sends it back to the top. The
  view was built anew, since the easing wrapped it in a widget of its own only when it was on; that
  widget now stays in place either way and hands the view another controller, whose position takes
  over the offset. On iOS and Android a view with no controller is the primary one, which Flutter
  builds differently, so going from no easing to easing there still builds it anew; the easing is
  off by default on those platforms, which have no wheel to ease.

## 2.3.0

### Added

- `placeholderColor`, `fadeIn` and `errorBuilder` on both widgets, for an `image` still loading or
  failing. The colour fills the background until the picture is decoded, the picture fades in over
  it, and the builder takes its place if it cannot be loaded. An image the cache already holds is
  drawn at once, and the fade is left out under reduced motion. Until now this took a `background`
  widget, which gave up the decoding at the size drawn.
- The example's five hundred blocks fade in over a placeholder.
- A sixth README animation, a carousel in a page with each card drifting both ways.
- The example's recorders decode the pictures the way the widgets draw them. They precached the
  asset, which the widgets no longer use since they decode at the size drawn, and could have
  recorded blank backgrounds. Regenerated this way, the five animations and four screenshots
  already published match the library, so they are left as they are.

### Fixed

- A background kept its first size when the widget changed in place: a new `scrollDirection`, a
  new `overscan`, or a `crossParallax` added or removed left the layer laid out for the old one, so
  part of the view went uncovered as it drifted. The flow now lays it out again.

### Changed

- The `.slivers` constructor documents how a list built lazily estimates its extent, and what to
  hand it for the background to follow the scroll exactly.

## 2.2.0

### Added

- `crossParallax` on `SimpleParallaxItem`, a drift along the other axis that follows the nearest
  scrollable running that way. A block in a horizontal carousel inside a vertical page can now
  slide sideways with the carousel and downwards with the page at the same time, each axis at its
  own speed and overscan. The background is drawn larger on both axes for it, and decoded to match.
  The zoom and the blur keep following the main scrollable, and nothing changes when it is left
  `null`.
- A third row in the example's carousel screen, following both.

### Fixed

- A line of the `decodeAtDisplaySize` documentation broke in the middle of a sentence.

## 2.1.0

### Added

- `respectReducedMotion` on both widgets, on by default. When the platform asks for reduced motion
  (Reduce Motion on iOS, Remove animations on Android, `prefers-reduced-motion` on the web), the
  container holds its background at the top of its travel and each item draws its block as it looks
  in the middle of the screen, zoom and blur included. The smooth wheel lands each notch in one step,
  still bringing it to a horizontal view. Pass `false` for the previous behaviour.
- `controller` and `physics` on `SimpleParallaxContainer`, as `SimpleParallaxWidget` already had.
- `SmoothScrollController` is exported. Given as the `controller` of either scroll view, it keeps
  `smooth` on, so the view can be driven from outside with the wheel still eased. Any other
  controller turns `smooth` off unless it is asked for, and asking for both is an error.
- `SimpleParallaxWidget.builder`, which creates its blocks as they come into view instead of taking
  them all as a list.
- `decodeAtDisplaySize` on both widgets, on by default. An `image` is decoded at the size it is
  drawn, worked out from the layer, the overscan, the zoom and the pixel density, instead of at full
  resolution: a photo of 4000 by 3000 pixels in a block of 300 no longer sits in memory at full
  size. The size is rounded up so a small resize reuses the decode, and an image a `ResizeImage`
  already sizes is left alone. Turn it off when one decoded copy should serve a full-size view of
  the same image elsewhere, and when the image is warmed up with `precacheImage`, which decodes the
  full-size copy the widget would no longer use.
- `alignment` and `borderRadius` on `SimpleParallaxItem`. `alignment` was only on the container;
  `borderRadius` clips the whole block, which a card needs and which took a `ClipRRect` around the
  item until now.
- `restorationId`, `keyboardDismissBehavior` and `clipBehavior` on both scroll views, handed to the
  `CustomScrollView` under them.
- `scrollAxis` on `SimpleParallaxItem`, to follow a scrollable further up than the nearest one. A
  block in a horizontal carousel inside a vertical page can slide with the page instead of the
  carousel. The nearest scrollable still lays the block out, so `height` and `width` default as
  before.

### Changed

- `smooth` left unset is off on iOS and Android. There is no wheel to ease there, and the controller
  the easing needs kept the view from being the primary one, so a tap on the iOS status bar no
  longer scrolled it back to the top. It stays on on desktop and the web, and `smooth: true` still
  turns it on anywhere.
- `SimpleParallaxContainer` paints its background from a `Flow` bound to the scroll metrics, as
  item mode already did. A scroll used to rebuild the transforms and the blur around the layer on
  every frame; it now repaints that layer and rebuilds nothing.
- With a blur, the progress of the background is measured once per frame instead of twice: the flow
  works it out and the blur, painted inside the flow, reads it. The layer keeps a repaint boundary of
  its own, so a scroll moves it without drawing it again.
- The README is down to what it takes to start: the two widgets, the four effects, and a short list
  of what else there is. The parameter tables are left to the API reference, which already carried
  every one, and the 1.x migration table moved to the 2.0.0 entry below.
- The example has eleven screens instead of thirteen, grouped in the menu. The zoom and the blur
  share one screen, the video joined the other widget backgrounds, and the sideways items became a
  carousel in a page. It gains the builder, `scrollAxis`, a container `controller`, and a switch that
  shows every screen under reduced motion.

### Fixed

- Scrolls running the other way. A horizontal container on a right-to-left page drifted its
  background against the content instead of with it. An item in a right-to-left list, or in a list
  with `reverse: true`, read its crossing backwards, so a zoom shrank, a blur cleared and `reach`
  counted from the wrong end.
- Item mode did not compile on the oldest Flutter the package admits, 3.22 among them: the zoom used
  `Matrix4.translateByDouble` and `scaleByDouble`, which the `vector_math` those versions pin does not
  have. A CI job now builds and runs the package on 3.22.2.
- The background is left out of the semantics tree, in both modes and whether it is an `image` or a
  `background` widget. An unlabelled image used to mark its surroundings as an image, so a screen
  reader announced an item's caption as "Chapter one, image".

## 2.0.2

### Changed

- The README is half the length. The parameter tables stay, and so does what the package is fast
  at; the tour of every option goes, since the demo shows it running and the API reference carries
  an example per member.
- The README carries its build badge again, pointed at the branch the repository actually builds
  from.
- `SimpleParallaxItem` no longer holds a `GlobalKey` per item: the flow reads the background size
  from its own child. The widget is now stateless.

### Fixed

- `SimpleParallaxContainer` ignores a nested scrollable on its own axis too. A vertical list inside
  the content used to drive the background with its own scroll.
- `SimpleParallaxContainer` keeps its background in step when nothing scrolls: a resize, content
  that grows or shrinks, an offset restored on the first layout, or a new `parallax`, `zoom` or
  `blur`. The background used to stay where it was until the next scroll.
- A horizontal view with `smooth` on no longer holds on to the vertical wheel once it has reached
  the end it is heading for. Inside a vertical page, the page used to stop scrolling under it.
- The library example still passed `autoSpeed`, which 2.0.0 removed.

## 2.0.1

### Changed

- The README badge row carries the maintainer again, and a licence badge in a colour of its own
  rather than the grey shields puts in every label. Nothing about the library changed.

## 2.0.0

Every effect is configured on its own object, and a fixed overlay joins them.

### Added
- `ParallaxProperties`, `ZoomProperties`, `BlurProperties` and `OverlayProperties`, one per effect.
  Each carries what belongs to it, so a zoom running the whole way and a blur stopping at the middle
  now sit in the same widget. In 1.3.0 `reach` and `back` were shared, which made that impossible.
- `overlay` on both widgets, a fixed layer of colour over the background and under the content. It
  does not drift, scale or blur with the background: it stays put while the background moves under
  it. `OverlayProperties.darken` and `.lighten` take an opacity, the default constructor takes any
  colour, and `.gradient` takes a gradient for a scrim that fades across the image. Six tests.
- `ItemOverlayDemo`, a thirteenth example screen showing the three forms one under the other.

### Changed
- `speed` means the same thing in both modes: the fraction of the available travel the background
  uses, from `0` to `1`. It used to be a travel per pixel scrolled on the container and a fraction
  on the item, under one name. Three tests.
- `zoom` and `blur` are nullable, so `null` is off and there is no longer a figure that means
  nothing.
- `smooth` defaults to `true` on both scroll views. A wheel notch landing on one frame is exactly
  what shows on a parallax background, so the flag was set on every screen of the example and on
  every sample in the README. On `SimpleParallaxWidget` it turns itself off when a `controller` is
  given, since the easing lives in a controller of the view's own; passing both is still an error.
  Pass `smooth: false` for the old behaviour.

### Removed
- `autoSpeed`. A `speed` of `1`, which is the default, spends the whole travel over the whole
  scroll, which is exactly what the flag did.
- The flat `speed`, `overscan`, `zoom`, `blur`, `reach` and `back` parameters, replaced by the four
  objects above, as follows.

### Migration

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
platform wheel behaviour.

## 1.3.0

The background can be a widget, it can push in or go soft as it travels, and the mouse wheel works
on either axis.

### Added
- `background` on both widgets, which takes the background layer as a widget in place of `image`. The
  layer is laid out to fill the box the parallax hands it, so a gradient, a `Stack` of several
  layers, a video, a shader or a `CachedNetworkImage` all work. It is also how to reach the `Image`
  parameters the package does not forward: `loadingBuilder`, `errorBuilder` and `cacheHeight` among
  them.
- `zoom` on both widgets, the scale the background gains across its travel, `0` by default. A
  negative figure runs the same range backwards, so the background starts enlarged and settles
  instead of pushing in. It turns about the middle of the viewport rather than the middle of the
  layer, so it leaves the drift alone and the two settings can be given independently. The scale
  never goes below 1, which would show the page down both sides of the layer. Eight tests.
- `blur` on both widgets, the gaussian sigma the background gains across its travel, `0` by default.
  It reads like `zoom`, a negative figure running the same range backwards, so a background can
  arrive soft and come into focus as well as the other way round. Only the background is filtered:
  the content over it stays sharp. It is the one setting here that is a filter rather than a
  transform, so the layer is blurred again on each frame it moves; the sigma is rounded to a quarter
  of a pixel and a sigma of zero pushes no layer at all. Seven tests.
- `reach` and `back` on both widgets, which shape where along the travel `zoom` and `blur` happen.
  `reach` is the point they are done by, `null` by default so they spread over the whole travel;
  `0.5` has them finished at the middle of the screen and holding there. `back` runs the range
  backwards from that point instead, which makes a zoom in and out, or a background that comes into
  focus as it passes the eye and goes soft again. With the sign of the effect saying which end it
  starts from, the three cover six shapes. The drift is never shaped this way. Nine tests.
- `smooth` on `SimpleParallaxContainer` and `SimpleParallaxWidget`. A `Scrollable` lands a wheel
  notch on one frame, which a parallax turns into a visible step, and it reads the wheel on its own
  axis alone, so a sideways view never moves under a plain wheel. The flag eases each notch in and
  feeds a sideways view the delta it would otherwise drop. Dragging and flinging are untouched.
  Seven tests.
- Seven example screens: `ContainerCustomDemo` and `ItemCustomDemo` for the widget background,
  `ContainerVideoDemo` and `ItemVideoDemo` drifting a looping video, `ItemZoomDemo`, which puts a
  block zooming in above one zooming out so the sign can be read off the screen, `ItemBlurDemo`,
  which does the same for the blur, and `ItemReachDemo`, which puts a zoom held at the middle above
  the same zoom sent back from it. Eight tests.
- The README previews are rendered again from the current package, and a fifth is added for the
  widget background. They are no longer captured by hand: `example/tool/record_previews.dart` draws
  each frame from a scroll offset it computes, and `example/tool/assemble_previews.py` turns the
  frames into the animated WebP files. The motion is exactly regular as a result, and the loop
  closes on itself.
- Four screenshots for pub.dev, declared in the pubspec and rendered from the example's own
  screens by `example/tool/record_screenshots.dart`, so one cannot show what the example does
  not.
- The example is rebuilt: twelve screens behind a menu, a way back over each one, inset cards that
  leave the background visible, captions on a scrim, and `smooth` set throughout. It also shows the
  `ScrollBehavior` a desktop needs for a mouse to drag a list at all, which the package leaves to
  the app. Its content is the copy the README previews use, so the two show the same thing.

### Fixed
- An item's background stood still for the first and last stretch of the block being on screen. The
  effect was measured from the middle of the block against the viewport alone, so it only ran while
  that middle crossed, which is `viewport` of scrolling out of the `viewport + height` the block is
  visible for. On a block half as tall as the screen that was a third of the way in and a third of
  the way out with nothing moving. It now runs from the moment the leading edge appears to the
  moment the trailing edge goes. The drift and the zoom both cover the whole crossing as a result,
  and both read as stronger for the same `speed` and `zoom`.

### Changed
- `image` is now optional, and exactly one of `image` and `background` must be given, which an assert
  checks. No constructor was added: the container still has two, one per content form, and the item
  still has one. What the background is made of is a parameter, not a constructor name.
- `image` is nullable, so code reading `widget.image` from the outside now has a null to handle.
  Nothing changes at a call site.
- `fit` and `alignment` apply to `image` only: a widget background fills the layer as it stands.

## 1.2.1

Modify topic widgets to sliver in to pubspec.yaml

## 1.2.0

Both scroll views move to slivers.

### Added
- `SimpleParallaxContainer.slivers`, which takes the content as a list of slivers instead of a
  single child. The content then builds as it scrolls, and a `SliverAppBar` or a `SliverGrid` can
  ride over the background. On a long list prefer a fixed `speed`: `autoSpeed` spreads the travel
  `overscan` allows over the whole extent, so the drift becomes imperceptible.
- A fifth example screen, `ContainerSliversDemo`.

### Changed
- `SimpleParallaxContainer` builds a `CustomScrollView` rather than a `SingleChildScrollView`. The
  default constructor puts `child` in a `SliverToBoxAdapter`, which lays it out exactly as before.
- `SimpleParallaxWidget` builds a `CustomScrollView` over one `SliverList` rather than a
  `SingleChildScrollView` over a `Column` or a `Row`, so its blocks build as they come into view.
  Two consequences, both of them `ListView` behaviour: a block is laid out across the full cross
  axis instead of being centred on it, and a block outside the viewport is not in the tree. Pass a
  block that must keep a narrower cross extent through an `Align` or a `Center`.

## 1.1.1

Documentation and example, no library change.

- The example covers all four combinations, two modes by two axes, behind a menu. They share
  `example/lib/main.dart` because that is the only file pub.dev renders on the example tab, so the
  three separate entry points only ever showed one of them there.
- The four preview animations are redone in one format, 520x260 at 25 frames a second, and laid out
  as a grid: modes in rows, axes in columns. 1.1.0 shipped before they were regenerated, so its
  README sized the vertical pair as portrait.

## 1.1.0

Horizontal parallax.

### Added
- `SimpleParallaxContainer.scrollDirection` and `SimpleParallaxWidget.scrollDirection`. The
  background drifts along the scrolled axis, and `overscan` sizes it on that axis.
- `SimpleParallaxItem` reads the axis from the scrollable it sits in, so it slides sideways in a
  horizontal list with nothing to pass. Its `height` and `width` defaults swap accordingly: the
  scrolled axis falls back to the screen extent, the cross axis to the incoming constraints.
- `SimpleParallaxContainer.width`, the horizontal counterpart of `height`.
- A horizontal example, `example/lib/main_horizontal.dart`, and horizontal previews in the README.

### Fixed
- `SimpleParallaxContainer` ignores scroll notifications from a nested scrollable running on the
  other axis, which used to drag the background along.

## 1.0.2

Add animated previews in to README.md

## 1.0.1

Improve example and comments.

## 1.0.0

Rewrite. **Breaking changes**, see the migration table below.

### Changed
- The package is no longer a Flutter plugin. The `android`, `ios`, `linux`, `macos` and `windows`
  folders held nothing but the `flutter create --template=plugin` scaffold, whose only method was
  never called from Dart. They are gone, along with the `flutter: plugin:` declaration and
  `lib/simple_parallax_web.dart`.
- No dependencies left beyond the Flutter SDK. `provider` was replaced by `ValueListenableBuilder`
  and by `Flow`, both from the SDK, and `flutter_web_plugins` went with the plugin declaration.
- Both widgets now take an `ImageProvider` instead of an asset path, so network images, files and
  raw bytes work.
- `decal` is renamed `overscan`, which is what it actually controls.
- `SimpleParallaxItem` finds the enclosing `Scrollable` on its own. It works inside a `ListView`, a
  `CustomScrollView` or any other scroll view, and no longer throws when used outside
  `SimpleParallaxWidget`.
- `SimpleParallaxItem.speed` is now a `0..1` fraction of the available travel, default `1.0`.
- `autoSpeed` derives the speed from the real scroll extent instead of requiring the caller to put a
  `GlobalKey` on their child, which was undocumented and silently did nothing when absent.
- `SimpleParallaxWidget` gained `controller`, `padding` and `physics`.

### Fixed
- Scrolling rebuilt the whole subtree, content included, on every frame: the `Consumer` wrapped the
  user's widgets. Container mode now rebuilds only the background transform, behind a
  `RepaintBoundary`, and item mode repaints without rebuilding anything at all.
- Two `ChangeNotifier` instances were never disposed, one per parallax item and one per parallax
  widget.
- `_key.currentContext!.findRenderObject()!` in a post-frame callback crashed when the item left the
  tree before the next frame. The measurement now happens at paint time, with no force-unwrap.
- `setState` was called from a post-frame callback without checking `mounted`.
- The scroll notification was swallowed by returning `true`, so an ancestor listener never saw it.
- A non-finite scroll metric could place the background nowhere.
- The background could travel past its overscan and uncover its bottom edge; the offset is clamped.

### Removed
- `provider` and `flutter_web_plugins` dependencies.
- Dead code: `ScrollNotifier.speed` and `setSpeed`, never called, and the unused scroll offset on the
  per-item notifier.
- Two lints removed from Dart years ago, still listed in `analysis_options.yaml`.

### Added
- A test suite. There was none.

### Migration

| Before | Now |
| --- | --- |
| `imagePath: 'assets/a.webp'` | `image: AssetImage('assets/a.webp')` |
| `decal: 1.5` | `overscan: 1.5` |
| `SimpleParallaxItem(speed: 0.3)` | `speed` is a `0..1` fraction, default `1.0` |
| `SimpleParallaxItem` only inside `SimpleParallaxWidget` | works inside any scrollable |

## 0.1.1

* Improved README.md

## 0.1.0

* Add parallax mods container and widget.
* Rename all classes

## 0.0.2

* Add comments
* Update depedencies

## 0.0.1

* Initial release
