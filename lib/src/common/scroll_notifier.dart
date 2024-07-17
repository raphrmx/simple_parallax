import 'package:flutter/cupertino.dart';

/// Scroll notifier class
class ScrollNotifier extends ChangeNotifier {
  double _scrollOffset = 0;

  /// Get scrolling offset pixels
  double get scrollOffset => _scrollOffset;

  /// Set scrolling offset pixels and notify it
  void setScrollOffset(double offset) {
    _scrollOffset = offset;
    notifyListeners();
  }
}
