import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ai_service.dart';
import '../services/tts_service.dart';
import '../services/translation_service.dart';
import '../providers/app_provider.dart';
import 'quiz_screen.dart';

class ResultScreen extends StatefulWidget {
  final String extractedText;

  const ResultScreen({super.key, required this.extractedText});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final AiService _aiService = AiService();
  final TtsService _ttsService = TtsService();
  final TranslationService _translationService = TranslationService();

  bool _isLoading = true;
  String _displayText = "";
  bool _showingExplanation = false;

  @override
  void initState() {
    super.initState();
    _fetchData(isExplanation: false);
  }

  Future<void> _fetchData({required bool isExplanation}) async {
    setState(() => _isLoading = true);
    
    final appProvider = context.read<AppProvider>();
    final aiResponse = await _aiService.getAnswer(
      widget.extractedText, 
      appProvider.apiKey, 
      isExplanation: isExplanation
    );
    
    if (!mounted) return;
    
    final currentLang = appProvider.currentLanguage;
    final translatedResponse = await _translationService.translate(aiResponse, currentLang);
    
    setState(() {
      _displayText = translatedResponse;
      _showingExplanation = isExplanation;
      _isLoading = false;
    });
  }

  void _speak() {
    if (_displayText.isNotEmpty) {
      _ttsService.speak(_displayText);
    }
  }

  void _goToQuiz() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => QuizScreen(sourceText: widget.extractedText),
    ));
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Result')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Original Question:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(widget.extractedText),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _showingExplanation ? "Detailed Explanation:" : "Direct Answer:",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      IconButton(
                        icon: const Icon(Icons.volume_up, color: Colors.blue),
                        onPressed: _speak,
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!)
                    ),
                    child: Text(
                      _displayText,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  if (!_showingExplanation)
                    OutlinedButton.icon(
                      onPressed: () => _fetchData(isExplanation: true),
                      icon: const Icon(Icons.lightbulb),
                      label: const Text("Get Detailed Explanation"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _goToQuiz,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Generate Practice MCQ', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
    );
  }
}
