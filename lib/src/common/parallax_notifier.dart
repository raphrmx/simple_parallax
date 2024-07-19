import 'package:flutter/cupertino.dart';
/// Parallax Widget Notifier
class ParallaxNotifier extends ChangeNotifier {
  double _widgetPosition = 0;
  double _scrollOffset = 0;
  /// Get parallax widget item position
  double get widgetPosition => _widgetPosition;
  /// Get actual scroll position
  double get scrollOffset => _scrollOffset;
  /// Set parallax widget item position
  void updatePosition(double position) {
    if (position != _widgetPosition) {
      _widgetPosition = position;
      notifyListeners();
    }
  }
  /// Set scroll position
  void updateScrollOffset(double offset) {
    if (offset != _scrollOffset) {
      _scrollOffset = offset;
      notifyListeners();
    }
  }
}
