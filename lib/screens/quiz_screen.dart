import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ai_service.dart';
import '../providers/app_provider.dart';

class QuizScreen extends StatefulWidget {
  final String sourceText;

  const QuizScreen({super.key, required this.sourceText});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final AiService _aiService = AiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _mcqs = [];
  int _currentIndex = 0;
  String? _selectedOption;
  bool _showAnswer = false;

  @override
  void initState() {
    super.initState();
    _fetchQuiz();
  }

  Future<void> _fetchQuiz() async {
    final apiKey = context.read<AppProvider>().apiKey;
    final mcqs = await _aiService.getMcqs(widget.sourceText, apiKey);
    if (!mounted) return;
    setState(() {
      _mcqs = mcqs;
      _isLoading = false;
    });
  }

  void _checkAnswer(String option) {
    if (_showAnswer) return;
    setState(() {
      _selectedOption = option;
      _showAnswer = true;
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _mcqs.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _showAnswer = false;
      });
    } else {
      Navigator.pop(context); // End of quiz
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Practice Quiz')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Question \${_currentIndex + 1} of \${_mcqs.length}",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _mcqs[_currentIndex]['question'],
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),
                  ...(_mcqs[_currentIndex]['options'] as List<String>).map((option) {
                    final isCorrect = option == _mcqs[_currentIndex]['answer'];
                    final isSelected = option == _selectedOption;
                    
                    Color? bgColor;
                    if (_showAnswer) {
                      if (isCorrect) {
                        bgColor = Colors.green[300];
                      } else if (isSelected) {
                        bgColor = Colors.red[300];
                      }
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: bgColor,
                          padding: const EdgeInsets.all(16),
                          alignment: Alignment.centerLeft,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        onPressed: () => _checkAnswer(option),
                        child: Text(option, style: const TextStyle(color: Colors.black87, fontSize: 16)),
                      ),
                    );
                  }),
                  const Spacer(),
                  if (_showAnswer)
                    ElevatedButton(
                      onPressed: _nextQuestion,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      child: Text(_currentIndex < _mcqs.length - 1 ? 'Next Question' : 'Finish Quiz', style: const TextStyle(fontSize: 16)),
                    ),
                ],
              ),
            ),
    );
  }
}
