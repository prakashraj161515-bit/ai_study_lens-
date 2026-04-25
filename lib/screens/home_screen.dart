import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/feature_card.dart';
import '../services/ocr_service.dart';
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
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return;

      setState(() => _isLoading = true);
      final text = await _ocrService.extractText(File(image.path));
      setState(() => _isLoading = false);

      if (text.isNotEmpty && mounted) {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ResultScreen(extractedText: text),
        ));
      } else {
        _showError("No text found in the image.");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError("Failed to process image.");
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
      appBar: AppBar(title: const Text('AI Study Lens'), elevation: 0),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Scan Question",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FeatureCard(
                        title: 'Camera',
                        subtitle: 'Take a photo',
                        icon: Icons.camera_alt,
                        onTap: () => _processImage(ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FeatureCard(
                        title: 'Gallery',
                        subtitle: 'Upload photo',
                        icon: Icons.photo_library,
                        onTap: () => _processImage(ImageSource.gallery),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Text(
                  "Or type manually",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _manualInputController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: "Enter your question here...",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _processManualText,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Get Result', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
    );
  }
}
