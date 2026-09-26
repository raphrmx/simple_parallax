# simple_parallax_example

One app, twelve screens, reachable from a menu:

| Screen | Shows |
| --- | --- |
| `ContainerVerticalDemo` | Container mode, scrolling down |
| `ContainerHorizontalDemo` | Container mode, scrolling sideways |
| `ContainerSliversDemo` | Container mode over slivers, with a `SliverAppBar` |
| `ItemVerticalDemo` | Item mode, two blocks at two speeds |
| `ItemHorizontalDemo` | The same blocks in a sideways list |
| `ItemZoomDemo` | Two blocks at the same drift, zooming in and out |
| `ItemBlurDemo` | The same two blocks, blurring in and out |
| `ItemReachDemo` | An effect done by the middle, held or sent back |
| `ContainerCustomDemo` | A gradient as the background |
| `ItemCustomDemo` | A gradient and a tinted image as backgrounds |
| `ContainerVideoDemo` | A looping video behind the page |
| `ItemVideoDemo` | A looping video inside one block |

They all live in [lib/main.dart](lib/main.dart), which opens on a menu listing them. pub.dev renders
that single file on the example tab, which is why they are not split across several.

The copy is the one the README previews use, so the animations and the app you run show the same
thing. The preview widgets are laid out separately, in `tool/record_previews.dart`, because 520x260
needs tighter type and padding than a window does.

Every screen sets `smooth: true`, so a mouse wheel eases in rather than stepping, and the sideways
screens answer the wheel at all.

`_DragScrollBehavior` adds the mouse to `dragDevices` for the whole app. Flutter leaves dragging to
touch, stylus and trackpad, which on a desktop leaves a sideways list with nothing to drag. It is an
app-wide decision, so the package does not make it for you.

The two video screens need `video_player`, which this example depends on and the package does not.
They stream a sample video over the network, and fall back to a gradient where the plugin has no
implementation, Windows and Linux at the time of writing.

`tool/` holds the two recorders, one for the README previews and one for the pub.dev
screenshots. Both draw the frames rather than capturing them, so nothing depends on a screen
recorder or on the moment a shutter fires.

```sh
flutter run
```
