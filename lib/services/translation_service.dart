import 'package:translator/translator.dart';

class TranslationService {
  final GoogleTranslator _translator = GoogleTranslator();

  Future<String> translate(String text, String targetLanguageCode) async {
    if (targetLanguageCode == 'en') return text;
    try {
      final translation = await _translator.translate(text, to: targetLanguageCode);
      return translation.text;
    } catch (e) {
      return text; // Return original if fails
    }
  }
}
