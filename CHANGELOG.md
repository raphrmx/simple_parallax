# SimpleParallax Versions

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
