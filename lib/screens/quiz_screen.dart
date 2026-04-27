import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ai_service.dart';
import '../providers/app_provider.dart';

class QuizScreen extends StatefulWidget {
  final String sourceText;
  final List<Map<String, dynamic>>? preGeneratedMcqs;

  const QuizScreen({super.key, required this.sourceText, this.preGeneratedMcqs});

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
  int _correctAnswers = 0;
  bool _isQuizFinished = false;

  @override
  void initState() {
    super.initState();
    if (widget.preGeneratedMcqs != null && widget.preGeneratedMcqs!.isNotEmpty) {
      _mcqs = widget.preGeneratedMcqs!;
      _isLoading = false;
    } else {
      _fetchQuiz();
    }
  }

  Future<void> _fetchQuiz() async {
    setState(() => _isLoading = true);
    try {
      final mcqs = await _aiService.getMcqs(widget.sourceText);
      if (!mounted) return;
      setState(() {
        _mcqs = mcqs;
        _isLoading = false;
        _currentIndex = 0;
        _correctAnswers = 0;
        _isQuizFinished = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _checkAnswer(String option) {
    if (_showAnswer) return;
    final isCorrect = option == _mcqs[_currentIndex]['answer'];
    setState(() {
      _selectedOption = option;
      _showAnswer = true;
      if (isCorrect) _correctAnswers++;
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
      _finishQuiz();
    }
  }

  void _finishQuiz() {
    setState(() => _isQuizFinished = true);
    final percentage = (_correctAnswers / _mcqs.length) * 100;
    
    final marksheet = {
      'topic': widget.sourceText,
      'score': "$_correctAnswers / ${_mcqs.length}",
      'percentage': "${percentage.toStringAsFixed(1)}%",
      'date': DateTime.now().toString(),
    };

    final appProvider = context.read<AppProvider>();
    if (appProvider.isPremium) {
      appProvider.addMarksheet(marksheet);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Practice Quiz')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _mcqs.isEmpty
              ? _buildErrorUI()
              : _isQuizFinished
                  ? _buildMarksheetUI()
                  : _buildQuizUI(),
    );
  }

  Widget _buildErrorUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text("Failed to generate MCQs.\nPlease try again.", textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _fetchQuiz, child: const Text("Retry")),
        ],
      ),
    );
  }

  Widget _buildMarksheetUI() {
    final percentage = (_correctAnswers / _mcqs.length) * 100;
    final isPremium = context.read<AppProvider>().isPremium;

    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.stars, size: 80, color: Colors.amber),
              const SizedBox(height: 16),
              const Text("Quiz Marksheet", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const Divider(height: 32),
              _buildMarksheetRow("Total Questions", "${_mcqs.length}"),
              _buildMarksheetRow("Correct Answers", "$_correctAnswers"),
              _buildMarksheetRow("Score Percentage", "${percentage.toStringAsFixed(1)}%"),
              const SizedBox(height: 24),
              if (!isPremium)
                const Text("Upgrade to Premium to auto-save marksheets!", 
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Close"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Marksheet Downloaded! (Simulation)"))
                        );
                      },
                      child: const Text("Download"),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarksheetRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
        ],
      ),
    );
  }

  Widget _buildQuizUI() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Question ${_currentIndex + 1} of ${_mcqs.length}",
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Text(
            _mcqs[_currentIndex]['question'],
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          ...(_mcqs[_currentIndex]['options'] as List<dynamic>).map((option) {
            final isCorrect = option.toString() == _mcqs[_currentIndex]['answer'].toString();
            final isSelected = option.toString() == _selectedOption;
            
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
                onPressed: () => _checkAnswer(option.toString()),
                child: Text(option.toString(), style: const TextStyle(color: Colors.black87, fontSize: 16)),
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
    );
  }
}
