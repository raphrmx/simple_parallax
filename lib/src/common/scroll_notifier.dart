import 'package:flutter/cupertino.dart';

/// Scroll notifier for parallax container
class ScrollNotifier extends ChangeNotifier {
  double _scrollOffset = 0;
  double _speed = 0.3;

  /// Get actual scroll position
  double get scrollOffset => _scrollOffset;

  /// Get parallax speed
  double get speed => _speed;

  /// Set scroll position
  void setScrollOffset(double offset) {
    if (offset != _scrollOffset) {
      _scrollOffset = offset;
      notifyListeners();
    }
  }

  /// Set parallax speed
  void setSpeed(double speed) {
    if (speed != _speed) {
      _speed = speed;
      notifyListeners();
    }
  }
}
