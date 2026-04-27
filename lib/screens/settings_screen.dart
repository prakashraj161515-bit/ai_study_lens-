import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/ai_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _testingApi = false;
  bool _checkingModels = false;

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
          const ListTile(
            leading: Icon(Icons.security),
            title: Text('API Key Security'),
            subtitle: Text('API keys are now securely managed by the Vercel Backend Proxy.'),
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
}
