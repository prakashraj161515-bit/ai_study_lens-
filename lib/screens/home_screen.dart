import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../widgets/feature_card.dart';
import '../services/ocr_service.dart';
import '../services/ai_service.dart';
import '../providers/app_provider.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  final OcrService _ocrService = OcrService();
  final TextEditingController _manualInputController = TextEditingController();
  bool _isLoading = false;

  Future<void> _processImage(ImageSource source) async {
    final appProvider = context.read<AppProvider>();
    if (appProvider.apiKey.isEmpty) {
      _showError("Please set your API Key in Settings first.");
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return;

      setState(() => _isLoading = true);

      String text = "";
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        text = await AiService().getAnswerFromImage(bytes, appProvider.apiKey);
      } else {
        text = await _ocrService.extractText(File(image.path));
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (text.isNotEmpty) {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ResultScreen(extractedText: text),
        ));
      } else {
        _showError("No text found in the image.");
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showError("Failed to process image: $e");
    }
  }

  void _processManualText() {
    if (_manualInputController.text.trim().isEmpty) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ResultScreen(extractedText: _manualInputController.text),
    ));
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _manualInputController.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Study Lens', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'), // Assuming you might add routing, or just use the nav bar
          )
        ],
      ),
      body: _isLoading 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text("Analyzing your question...", style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          )
        : SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: FeatureCard(
                        title: 'Camera',
                        subtitle: 'Snap a photo',
                        icon: Icons.camera_alt_rounded,
                        onTap: () => _processImage(ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FeatureCard(
                        title: 'Gallery',
                        subtitle: 'Upload image',
                        icon: Icons.image_rounded,
                        onTap: () => _processImage(ImageSource.gallery),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    const Text(
                      "Manual Input",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _manualInputController.clear(),
                      child: const Text("Clear"),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: TextField(
                    controller: _manualInputController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: "Paste or type your question here...",
                      contentPadding: EdgeInsets.all(16),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _processManualText,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Analyze Question', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Study Smarter,",
                  style: TextStyle(fontSize: 16, color: Theme.of(context).primaryColor, fontWeight: FontWeight.w500),
                ),
                const Text(
                  "Scan Anything!",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Icon(Icons.auto_awesome, size: 40, color: Theme.of(context).primaryColor),
        ],
      ),
    );
  }
}
