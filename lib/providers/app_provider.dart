import 'package:flutter/material.dart';

class AppProvider with ChangeNotifier {
  bool isPremium = false;
  String currentLanguage = 'en'; // en, hi, pa, es, fr
  String apiKey = ''; // OpenAI API Key

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
