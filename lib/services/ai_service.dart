import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  // Using the new Vercel Backend Proxy to keep API keys secure
  final String apiUrl = 'https://ai-study-lens-g7ji.vercel.app/api/gemini';

  Future<String> testConnection() async {
    return getAnswer("Say 'Hi'", isExplanation: false);
  }

  Future<String> getAnswerFromImage(List<int> imageBytes) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'imageBase64': base64Encode(imageBytes)
        }),
      );

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      
      if (response.statusCode == 200) {
        return data['result'] ?? "No text extracted.";
      }
      return "Error: ${data['error'] ?? 'Backend error'}";
    } catch (e) {
      return "Connection Error: $e";
    }
  }

  Future<String> getAnswer(String text, {required bool isExplanation}) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': text,
          'isExplanation': isExplanation
        }),
      );

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      
      if (response.statusCode == 200) {
        return data['result'] ?? "No answer received.";
      }
      return "Error: ${data['error'] ?? 'Backend error'}";
    } catch (e) {
      return "Connection Error: $e";
    }
  }

  Future<List<Map<String, dynamic>>> getMcqs(String text, {String difficulty = 'Medium', int count = 3}) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': text,
          'isMcq': true,
          'count': count,
          'difficulty': difficulty
        }),
      );

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      
      if (response.statusCode == 200) {
        return _extractJsonList(data['result'] ?? "");
      }
    } catch (e) {
      print("MCQ Error: $e");
    }
    return [];
  }

  List<Map<String, dynamic>> _extractJsonList(String content) {
    try {
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
}
