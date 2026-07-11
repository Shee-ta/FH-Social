
import 'package:flutter/material.dart';

class CreateEventController extends ChangeNotifier {

  bool _isPickingLocation = false;
  bool get isPickingLocation => _isPickingLocation;

  bool _hasPickedLocation = false;
  bool get hasPickedLocation => _hasPickedLocation;

  bool _isUsingCustomLocation = false;
  bool get isUsingCustomLocation => _isUsingCustomLocation;

  void setHasPickedLocation(bool value) {
    _hasPickedLocation = value;
    notifyListeners();
  }
  void setPickingLocation(bool value) {
    _isPickingLocation = value;
    notifyListeners();
  }
  void setUsingCustomLocation(bool value) {
    _isUsingCustomLocation = value;
    notifyListeners();
  }

}