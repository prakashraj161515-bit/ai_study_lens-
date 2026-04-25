import 'package:flutter/material.dart';

class AppProvider with ChangeNotifier {
  bool isPremium = false;
  String currentLanguage = 'en'; // en, hi, pa, es, fr
  String apiKey = ''; // API Key
  List<Map<String, dynamic>> savedMarksheets = [];

  void addMarksheet(Map<String, dynamic> marksheet) {
    savedMarksheets.insert(0, marksheet); // Add at the beginning
    notifyListeners();
  }

  void setPremium(bool value) {
    isPremium = value;
    notifyListeners();
  }

  void setLanguage(String langCode) {
    currentLanguage = langCode;
    notifyListeners();
  }

  void setApiKey(String key) {
    apiKey = key;
    notifyListeners();
  }
}
