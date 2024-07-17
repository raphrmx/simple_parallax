
import 'package:flutter/cupertino.dart';

class ScrollNotifier extends ChangeNotifier {
  double _scrollOffset = 0;

  double get scrollOffset => _scrollOffset;

  void setScrollOffset(double offset) {
    _scrollOffset = offset;
    notifyListeners();
  }
}
