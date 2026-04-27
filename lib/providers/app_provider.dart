import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

class AppProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  
  bool isPremium = false;
  String currentLanguage = 'en'; 
  String apiKey = '';
  List<Map<String, dynamic>> savedMarksheets = [];

  AppProvider(this._prefs) {
    _loadSettings();
  }

  void _loadSettings() {
    apiKey = _prefs.getString('api_key') ?? '';
    currentLanguage = _prefs.getString('language') ?? 'en';
    notifyListeners();
  }

  void addMarksheet(Map<String, dynamic> marksheet) {
    savedMarksheets.insert(0, marksheet); 
    notifyListeners();
  }

  void setPremium(bool value) {
    isPremium = value;
    notifyListeners();
  }

  void setLanguage(String langCode) {
    currentLanguage = langCode;
    _prefs.setString('language', langCode);
    notifyListeners();
  }

  void setApiKey(String key) {
    apiKey = key;
    _prefs.setString('api_key', key);
    notifyListeners();
  }
}
