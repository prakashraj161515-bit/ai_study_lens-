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
    
    final aiResponse = await _aiService.getAnswer(
      widget.extractedText, 
      isExplanation: isExplanation
    );
    
    if (!mounted) return;
    
    final appProvider = context.read<AppProvider>();
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Analysis Result', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionHeader("Original Question", Icons.help_outline),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Text(
                      widget.extractedText,
                      style: const TextStyle(fontSize: 15, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      _buildSectionHeader(
                        _showingExplanation ? "Detailed Explanation" : "AI Answer", 
                        _showingExplanation ? Icons.lightbulb : Icons.auto_awesome_rounded
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.volume_up_rounded, color: Colors.blue),
                        onPressed: _speak,
                        tooltip: "Listen",
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.blue.shade50, Colors.white],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.blue.shade100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Text(
                      _displayText,
                      style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 40),
                  if (!_showingExplanation)
                    _buildActionButton(
                      onPressed: () => _fetchData(isExplanation: true),
                      icon: Icons.auto_stories_rounded,
                      label: "Explain Step-by-Step",
                      isPrimary: false,
                    ),
                  const SizedBox(height: 16),
                  _buildActionButton(
                    onPressed: _goToQuiz,
                    icon: Icons.quiz_rounded,
                    label: "Generate Practice Quiz",
                    isPrimary: true,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 13, 
            fontWeight: FontWeight.w800, 
            color: Colors.blue.shade800,
            letterSpacing: 1.2
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed, 
    required IconData icon, 
    required String label, 
    required bool isPrimary
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? Colors.blue.shade600 : Colors.white,
        foregroundColor: isPrimary ? Colors.white : Colors.blue.shade600,
        padding: const EdgeInsets.symmetric(vertical: 20),
        elevation: isPrimary ? 4 : 0,
        side: isPrimary ? null : BorderSide(color: Colors.blue.shade100),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
