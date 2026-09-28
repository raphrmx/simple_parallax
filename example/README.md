# simple_parallax_example

One app, eleven screens, reachable from a menu grouped by container mode, item mode and effects:

| Screen | Shows |
| --- | --- |
| `ContainerVerticalDemo` | Container mode, scrolling down |
| `ContainerHorizontalDemo` | Container mode, scrolling sideways |
| `ContainerSliversDemo` | Container mode over slivers, with a `SliverAppBar` and a `SmoothScrollController` to go back up |
| `ContainerCustomDemo` | A gradient as the background |
| `ItemVerticalDemo` | Item mode, two blocks at two speeds |
| `ItemCarouselDemo` | Blocks in a sideways row, following the row, the page with `scrollAxis`, then both with `crossParallax` |
| `ItemBuilderDemo` | Five hundred blocks from `SimpleParallaxWidget.builder`, fading in over a placeholder |
| `ItemCustomDemo` | A gradient, a tinted image and a looping video as backgrounds |
| `ItemZoomBlurDemo` | Both directions of the zoom, then of the blur |
| `ItemReachDemo` | An effect done by the middle, held or sent back |
| `ItemOverlayDemo` | A fixed tint: darkened, faded by a gradient, coloured |

The menu also carries a Reduce motion switch. It stands in for the system setting, through
`MediaQuery`, so every screen can be seen the way someone who turned that setting on sees it.

They all live in [lib/main.dart](lib/main.dart), which opens on a menu listing them. pub.dev renders
that single file on the example tab, which is why they are not split across several.

The copy is the one the README previews use, so the animations and the app you run show the same
thing. The preview widgets are laid out separately, in `tool/record_previews.dart`, because 520x260
needs tighter type and padding than a window does.

No screen sets `smooth`: it is on by default, so a mouse wheel eases in rather than stepping, and
the sideways screens answer the wheel at all. The slivers screen passes a `controller` for its back
to the top button, a `SmoothScrollController`, which keeps the easing on.

`_DragScrollBehavior` adds the mouse to `dragDevices` for the whole app. Flutter leaves dragging to
touch, stylus and trackpad, which on a desktop leaves a sideways list with nothing to drag. It is an
app-wide decision, so the package does not make it for you.

The video block needs `video_player`, which this example depends on and the package does not. It
streams a sample video over the network, and falls back to a gradient where the plugin has no
implementation, Windows and Linux at the time of writing.

`tool/` holds the two recorders, one for the README previews and one for the pub.dev
screenshots. Both draw the frames rather than capturing them, so nothing depends on a screen
recorder or on the moment a shutter fires.

```sh
flutter run
```
