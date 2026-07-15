

import 'package:flutter/material.dart';

class SettingsService extends ChangeNotifier {

  List<bool> dashbordSelectedMode = [true, false];
  List<bool> eventSelectedMode = [true, false];

  Map<String, Color> themeColorToBrightness = {
    'dark': Colors.black,
    'system': Colors.grey,
    'light': Colors.white,
  };

  Map<Brightness, String> brightnessToString = {
    Brightness.dark: 'dark',
    Brightness.light: 'light',
  };

  Map<String, Color> themeColorToColor = {
    'red': Colors.red,
    'orange': Colors.orange,
    'yellow': Colors.yellow,
    'green': Colors.green,
    'teal': Colors.teal,
    'blue': Colors.blue,
    'cyan': Colors.cyan,
    'purple': Colors.deepPurple,
    'pink': Colors.pink,
    'brown': Colors.brown,
  };

  Map<Color, String> colorToThemeColor = {
    Colors.red: 'red',
    Colors.orange: 'orange',
    Colors.yellow: 'yellow',
    Colors.green: 'green',
    Colors.teal: 'teal',
    Colors.blue: 'blue',
    Colors.cyan: 'cyan',
    Colors.deepPurple: 'purple',
    Colors.pink: 'pink',
    Colors.brown: 'brown',
  };

  final Color _defaultThemeColor = Colors.orange;
  final Brightness _defaultThemeBrightness = ThemeMode.system == ThemeMode.dark ? Brightness.dark : Brightness.light;
  final bool _defaultIconButtons = false;

  SettingsService()
  {
    _themeColor = _defaultThemeColor;
    _themeMode = _defaultThemeBrightness;
    _iconButtonsActive = _defaultIconButtons;
  }

  late Brightness _themeMode;
  Brightness get themeBrightness => _themeMode;

  late Color _themeColor;
  Color get themeColor => _themeColor;

  late bool _iconButtonsActive;
  bool get iconButtonsActive => _iconButtonsActive;

  // --- PROPERTIES --- //
    Color aiButtonColor(BuildContext context) {
    return Color.alphaBlend(
      Colors.blue.withValues(alpha: 0.36),
      Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }

  ButtonStyle aiButtonStyle(BuildContext context) { 
    return ElevatedButton.styleFrom(
      backgroundColor: Color.alphaBlend(
        Colors.blue.withValues(alpha: 0.36),
        Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      foregroundColor: Theme.of(context).colorScheme.onSurface,
    );
  }

  ButtonStyle positiveButtonStyle(BuildContext context) { 
    return ElevatedButton.styleFrom(
      backgroundColor: Color.alphaBlend(
        Colors.green.withValues(alpha: 0.36),
        Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      foregroundColor: Theme.of(context).colorScheme.onSurface,
    );
  }

  ButtonStyle neutralButtonStyle(BuildContext context) { 
    return ElevatedButton.styleFrom(
      backgroundColor: Color.alphaBlend(
        Colors.pinkAccent.withValues(alpha: 0.36),
        Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      foregroundColor: Theme.of(context).colorScheme.onSurface,
    );
  }

  ButtonStyle negativeButtonStyle(BuildContext context) { 
    return ElevatedButton.styleFrom(
      backgroundColor: Color.alphaBlend(
        Colors.deepOrange.withValues(alpha: 0.36),
        Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      foregroundColor: Theme.of(context).colorScheme.onSurface,
    );
  }

  // --- SETTERS --- //
  void setThemeBrightness(Brightness mode) {
    if(_themeMode == mode) {
      return;
    }
    _themeMode = mode;
    notifyListeners();
  }

  void setThemeColor(Color color) {
    if(_themeColor == color) {
      return;
    }
    _themeColor = color;
    notifyListeners();
  }

  void setIconButtonsActive(bool value) {
    _iconButtonsActive = value;
    notifyListeners();
  }
}