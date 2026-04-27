import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  final String smartPrompt = '''
You are a smart study assistant. Respond based on question complexity.
''';

  final String forceExplanationPrompt = '''
Provide a detailed step-by-step explanation.
''';

  Future<String> testConnection(String apiKey) async {
    return getAnswer("Say 'Hi'", apiKey, isExplanation: false);
  }

  Future<String> getAnswerFromImage(List<int> imageBytes, String apiKey) async {
    if (apiKey.isEmpty) return "API Key missing.";
    
    if (apiKey.startsWith('sk-')) {
       return "OpenAI Image Support not implemented yet. Use Gemini for images.";
    }

    try {
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-lite-preview:generateContent?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': smartPrompt},
                {
                  'inline_data': {
                    'mime_type': 'image/png',
                    'data': base64Encode(imageBytes)
                  }
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['candidates'][0]['content']['parts'][0]['text'];
      }
      final errorData = jsonDecode(response.body);
      return "Gemini Error: ${errorData['error']['message'] ?? response.body}";
    } catch (e) {
      return "Error: $e";
    }
  }

  // New method to find what models the user's key actually supports
  Future<String> getAvailableModels(String apiKey) async {
    if (apiKey.startsWith('sk-')) return "OpenAI Key detected. Using gpt-4o-mini.";
    
    try {
      final response = await http.get(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List models = data['models'] ?? [];
        String modelNames = models.map((m) => m['name'].toString().replaceFirst('models/', '')).join(', ');
        return "Supported Models: $modelNames";
      } else {
        return "Error fetching models: ${response.statusCode}";
      }
    } catch (e) {
      return "Connection Error: $e";
    }
  }

  Future<String> getAnswer(String text, String apiKey, {required bool isExplanation}) async {
    if (apiKey.trim().isEmpty) return "API Key missing.";

    final systemInstruction = isExplanation ? forceExplanationPrompt : smartPrompt;

    if (apiKey.startsWith('sk-')) {
      return _callOpenAI(text, apiKey, systemInstruction);
    } else {
      // We will try the most common models for Gemini
      return _callGemini(text, apiKey, systemInstruction);
    }
  }

  Future<String> _callOpenAI(String text, String apiKey, String systemInstruction) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {'role': 'system', 'content': systemInstruction},
            {'role': 'user', 'content': text}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'];
      } else {
        final errorData = jsonDecode(response.body);
        return "OpenAI Error: ${errorData['error']['message']}";
      }
    } catch (e) {
      return "OpenAI Connection Error: $e";
    }
  }

  Future<String> _callGemini(String text, String apiKey, String systemInstruction) async {
    try {
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-lite-preview:generateContent?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [{'text': "INSTRUCTION: $systemInstruction\n\nQUESTION: $text"}]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        final errorData = jsonDecode(response.body);
        return "Gemini Error: ${errorData['error']['message']}";
      }
    } catch (e) {
      return "Gemini Connection Error: $e";
    }
  }

  Future<List<Map<String, dynamic>>> getMcqs(String text, String apiKey, {String difficulty = 'Medium', int count = 3}) async {
    if (apiKey.isEmpty) return [];
    final prompt = '''
Generate $count MCQs for the following topic: $text
Difficulty: $difficulty

Return ONLY a JSON array with this exact structure:
[
  {
    "question": "The question text",
    "options": ["Option A", "Option B", "Option C", "Option D"],
    "answer": "The exact string of the correct option"
  }
]
Do NOT include any explanations or markdown formatting outside the JSON.
''';
    
    if (apiKey.startsWith('sk-')) {
      return _callOpenAIMCQs(text, apiKey, prompt);
    } else {
      return _callGeminiMCQs(text, apiKey, prompt);
    }
  }

  List<Map<String, dynamic>> _extractJsonList(String content) {
    try {
      // Find the first [ and last ] to extract the JSON array
      final start = content.indexOf('[');
      final end = content.lastIndexOf(']');
      if (start != -1 && end != -1) {
        final jsonStr = content.substring(start, end + 1);
        final decoded = jsonDecode(jsonStr) as List;
        return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      print("JSON Extraction Error: $e");
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> _callOpenAIMCQs(String text, String apiKey, String prompt) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $apiKey'},
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [{'role': 'user', 'content': prompt}],
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'];
        return _extractJsonList(content);
      }
    } catch (_) {}
    return [];
  }

  Future<List<Map<String, dynamic>>> _callGeminiMCQs(String text, String apiKey, String prompt) async {
    try {
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-lite-preview:generateContent?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{'parts': [{'text': prompt}]}]
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['candidates'][0]['content']['parts'][0]['text'];
        return _extractJsonList(content);
      }
    } catch (_) {}
    return [];
  }
}
