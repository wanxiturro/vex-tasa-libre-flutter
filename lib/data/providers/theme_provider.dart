// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  static const Color _darkBackground = Color.fromARGB(255, 22, 21, 25);
  static const Color _darkAppBar = Color.fromARGB(255, 28, 27, 32);
  static const Color _darkCardColor = Color(0xFF1E1F24);
  static const Color _darkTextColor = Colors.white;
  static const Color _darkSecondaryTextColor = Colors.grey;
  
  static const Color _lightBackground = Color.fromARGB(255, 245, 245, 245);
  static const Color _lightAppBar = Colors.white;
  static const Color _lightCardColor = Colors.white;
  static const Color _lightTextColor = Color.fromARGB(255, 33, 33, 33);
  static const Color _lightSecondaryTextColor = Color.fromARGB(255, 117, 117, 117);
  
  Color _backgroundColor = _darkBackground;
  Color _appBarColor = _darkAppBar;
  Color _rateCardColor = _darkCardColor;
  Color _textColor = _darkTextColor;
  Color _secondaryTextColor = _darkSecondaryTextColor;
  Color _selectedTabColor = const Color.fromARGB(255, 91, 165, 35);
  Color _converterCardColor = const Color.fromARGB(255, 91, 165, 35);
  
  bool _isDarkMode = true;

  Color get lineCardColor => _darkenColor(_converterCardColor, 0.2); // 0.3 = 30% más oscuro

  Color get backgroundColor => _backgroundColor;
  Color get appBarColor => _appBarColor;
  Color get rateCardColor => _rateCardColor;
  Color get textColor => _textColor;
  Color get secondaryTextColor => _secondaryTextColor;
  Color get selectedTabColor => _selectedTabColor;
  Color get converterCardColor => _converterCardColor;
  bool get isDarkMode => _isDarkMode;

  Color _darkenColor(Color color, double factor) {
    assert(factor >= 0 && factor <= 1, 'Factor debe estar entre 0 y 1');
    
    return Color.fromARGB(
      color.alpha,
      (color.red * (1 - factor)).round(),
      (color.green * (1 - factor)).round(),
      (color.blue * (1 - factor)).round(),
    );
  }

  void setConverterCardColor(Color color) {
    _converterCardColor = color;
    notifyListeners();
  }

  void setSelectedTabColor(Color color) {
    _selectedTabColor = color;
    notifyListeners();
  }

  void setLightMode() {
    _isDarkMode = false;
    _backgroundColor = _lightBackground;
    _appBarColor = _lightAppBar;
    _rateCardColor = _lightCardColor;
    _textColor = _lightTextColor;
    _secondaryTextColor = _lightSecondaryTextColor;
    notifyListeners();
  }

  void setDarkMode() {
    _isDarkMode = true;
    _backgroundColor = _darkBackground;
    _appBarColor = _darkAppBar;
    _rateCardColor = _darkCardColor;
    _textColor = _darkTextColor;
    _secondaryTextColor = _darkSecondaryTextColor;
    notifyListeners();
  }

  void resetToDefault() {
    setDarkMode();
    _converterCardColor = const Color.fromARGB(255, 91, 165, 35);
    _selectedTabColor = const Color.fromARGB(255, 91, 165, 35);
    notifyListeners();
  }
}