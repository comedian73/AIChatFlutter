import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Added this import
import 'package:ai_chat_flutter/services/app_settings_service.dart';
import 'package:ai_chat_flutter/api/openrouter_client.dart';
import 'package:ai_chat_flutter/providers/chat_provider.dart'; // Import ChatProvider
import 'package:ai_chat_flutter/screens/chat_screen.dart'; // Import ChatScreen

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettingsService _appSettingsService;
  final TextEditingController _apiKeyController = TextEditingController();
  String? _selectedBaseUrl;
  bool _isApiKeyHidden = true;

  final Map<String, String> _baseUrlOptions = {
    "OpenRouter.ai": 'https://openrouter.ai/api/v1',
    "VseGPT.ru": 'https://api.vsegpt.ru/v1',
  };

  @override
  void initState() {
    super.initState();
    _appSettingsService =
        Provider.of<AppSettingsService>(context, listen: false);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _apiKeyController.text = _appSettingsService.openRouterApiKey;
    String? loadedBaseUrl = _appSettingsService.baseUrl;

    if (_baseUrlOptions.containsValue(loadedBaseUrl)) {
      _selectedBaseUrl = loadedBaseUrl;
    } else {
      // Default to OpenRouter.ai if the loaded URL is null or not in the options
      _selectedBaseUrl = _baseUrlOptions["OpenRouter.ai"];
    }
    setState(() {});
  }

  Future<void> _saveSettings() async {
    await _appSettingsService.setOpenRouterApiKey(_apiKeyController.text);
    if (_selectedBaseUrl != null) {
      await _appSettingsService.setBaseUrl(_selectedBaseUrl!);
    }
    // Re-initialize OpenRouterClient with new settings
    await OpenRouterClient.initialize(_appSettingsService);

    // Get ChatProvider instance and reinitialize it
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    await chatProvider.reinitializeClient();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved!')),
    );

    // Check if API key is now present
    if (_appSettingsService.openRouterApiKey.isNotEmpty) {
      // If API key is present, navigate to ChatScreen and remove all previous routes
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const ChatScreen()),
        (Route<dynamic> route) => false,
      );
    } else {
      // If API key is still empty, just pop the settings screen
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Провайдер:'),
            DropdownButton<String>(
              value: _selectedBaseUrl,
              hint: const Text('Выбирите провайдера:'),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedBaseUrl = newValue;
                });
              },
              items: _baseUrlOptions.entries.map<DropdownMenuItem<String>>(
                  (MapEntry<String, String> entry) {
                return DropdownMenuItem<String>(
                  value: entry.value,
                  child: Text(entry.key),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _apiKeyController,
              obscureText: _isApiKeyHidden,
              decoration: InputDecoration(
                labelText: 'API-ключ провайдера',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isApiKeyHidden ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _isApiKeyHidden = !_isApiKeyHidden;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveSettings,
              child: const Text('Сохранить'),
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
