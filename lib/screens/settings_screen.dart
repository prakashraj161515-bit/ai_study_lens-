import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/ai_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            subtitle: Text(_getLanguageName(appProvider.currentLanguage)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showLanguagePicker(context, appProvider),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.vpn_key),
            title: const Text('API Key (Gemini or OpenAI)'),
            subtitle: Text(appProvider.apiKey.isEmpty ? 'Not Set' : 'Set (Tap to change)'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showApiKeyDialog(context, appProvider),
          ),
          if (appProvider.apiKey.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _testApi(context, appProvider.apiKey),
                    icon: const Icon(Icons.security),
                    label: const Text('Test API Connection'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade50,
                      minimumSize: const Size(double.infinity, 45),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _checkModels(context, appProvider.apiKey),
                    icon: const Icon(Icons.list),
                    label: const Text('Check Available Models'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 45),
                    ),
                  ),
                ],
              ),
            ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('About'),
            subtitle: Text('AI Study Lens v1.0.0'),
          )
        ],
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'en': return 'English';
      case 'hi': return 'Hindi';
      case 'pa': return 'Punjabi';
      case 'es': return 'Spanish';
      case 'fr': return 'French';
      default: return 'English';
    }
  }

  void _showLanguagePicker(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLangOption(context, provider, 'en', 'English'),
              _buildLangOption(context, provider, 'hi', 'Hindi'),
              _buildLangOption(context, provider, 'pa', 'Punjabi'),
              _buildLangOption(context, provider, 'es', 'Spanish'),
              _buildLangOption(context, provider, 'fr', 'French'),
            ],
          ),
        );
      }
    );
  }

  Widget _buildLangOption(BuildContext context, AppProvider provider, String code, String name) {
    return ListTile(
      title: Text(name),
      trailing: provider.currentLanguage == code ? const Icon(Icons.check, color: Colors.blue) : null,
      onTap: () {
        provider.setLanguage(code);
        Navigator.pop(context);
      },
    );
  }

  void _showApiKeyDialog(BuildContext context, AppProvider provider) {
    final TextEditingController controller = TextEditingController(text: provider.apiKey);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('API Key'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'sk-... or AIza...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                provider.setApiKey(controller.text.trim());
                Navigator.pop(context);
              },
              child: const Text('Save'),
            )
          ],
        );
      },
    );
  }

  Future<void> _testApi(BuildContext context, String apiKey) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final response = await AiService().testConnection(apiKey);
    Navigator.pop(context); // Close loading

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API Test Result'),
        content: Text(response),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  Future<void> _checkModels(BuildContext context, String apiKey) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final response = await AiService().getAvailableModels(apiKey);
    Navigator.pop(context); // Close loading

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supported Models'),
        content: SingleChildScrollView(child: Text(response)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }
}
