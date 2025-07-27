import 'package:flutter/material.dart';
import 'package:ai_chat_flutter/services/app_settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AppSettingsService _appSettingsService = AppSettingsService();
  final TextEditingController _apiKeyController = TextEditingController();
  String? _selectedBaseUrl;

  final List<String> _baseUrlOptions = [
    'https://openrouter.ai/api/v1',
    'https://api.vsetgpt.ru/v1',
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _apiKeyController.text = _appSettingsService.openRouterApiKey;
    _selectedBaseUrl = _appSettingsService.baseUrl;
    setState(() {});
  }

  Future<void> _saveSettings() async {
    await _appSettingsService.setOpenRouterApiKey(_apiKeyController.text);
    if (_selectedBaseUrl != null) {
      await _appSettingsService.setBaseUrl(_selectedBaseUrl!);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('BASE_URL:'),
            DropdownButton<String>(
              value: _selectedBaseUrl,
              hint: const Text('Select a base URL'),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedBaseUrl = newValue;
                });
              },
              items:
                  _baseUrlOptions.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _apiKeyController,
              decoration: const InputDecoration(
                labelText: 'OPENROUTER_API_KEY',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveSettings,
              child: const Text('Save Settings'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }
}
