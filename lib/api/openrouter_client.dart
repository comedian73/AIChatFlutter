// Import JSON library
import 'dart:convert';
// Import HTTP client
import 'package:http/http.dart' as http;
// Import Flutter core classes
import 'package:flutter/foundation.dart';
import 'package:ai_chat_flutter/services/app_settings_service.dart';

// Класс клиента для работы с API OpenRouter
class OpenRouterClient {
  // API ключ для авторизации
  String? _apiKey;
  // Базовый URL API
  String? _baseUrl;
  // Заголовки HTTP запросов
  Map<String, String>? _headers;
  // Максимальное количество токенов
  int? _maxTokens;
  // Температура генерации
  double? _temperature;

  // Единственный экземпляр класса (Singleton)
  static OpenRouterClient? _instance;
  static bool _isInitialized = false;

  // Фабричный метод для получения экземпляра
  factory OpenRouterClient() {
    if (_instance == null) {
      throw Exception(
          'OpenRouterClient must be initialized using OpenRouterClient.initialize() before use.');
    }
    return _instance!;
  }

  // Приватный конструктор для реализации Singleton
  OpenRouterClient._internal();

  // Статический метод для инициализации клиента
  static Future<void> initialize(AppSettingsService appSettingsService) async {
    if (_isInitialized && _instance != null) {
      // If already initialized, update existing instance
      _instance!._apiKey = appSettingsService.openRouterApiKey;
      _instance!._baseUrl = appSettingsService.baseUrl;
      _instance!._maxTokens = appSettingsService.maxTokens;
      _instance!._temperature = appSettingsService.temperature;
      _instance!._headers = {
        'Authorization': 'Bearer ${_instance!._apiKey}',
        'Content-Type': 'application/json',
        'X-Title': 'AI Chat Flutter',
      };
      _instance!._initializeClient();
    } else {
      // Otherwise, create a new instance
      _instance = OpenRouterClient._internal();
      _instance!._apiKey = appSettingsService.openRouterApiKey;
      _instance!._baseUrl = appSettingsService.baseUrl;
      _instance!._maxTokens = appSettingsService.maxTokens;
      _instance!._temperature = appSettingsService.temperature;
      _instance!._headers = {
        'Authorization': 'Bearer ${_instance!._apiKey}',
        'Content-Type': 'application/json',
        'X-Title': 'AI Chat Flutter',
      };
      _instance!._initializeClient();
      _isInitialized = true;
    }
  }

  // Метод инициализации клиента
  void _initializeClient() {
    try {
      if (kDebugMode) {
        print('Initializing OpenRouterClient...');
        print('Base URL: $_baseUrl');
      }

      // Проверка наличия API ключа
      if (_apiKey == null || _apiKey!.isEmpty) {
        throw Exception('OpenRouter API key not found in settings.');
      }
      // Проверка наличия базового URL
      if (_baseUrl == null || _baseUrl!.isEmpty) {
        throw Exception('BASE_URL not found in settings.');
      }

      if (kDebugMode) {
        print('OpenRouterClient initialized successfully');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error initializing OpenRouterClient: $e');
        print('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  // Метод получения списка доступных моделей
  Future<List<Map<String, dynamic>>> getModels() async {
    try {
      // Выполнение GET запроса для получения моделей
      final response = await http.get(
        Uri.parse('$_baseUrl/models'),
        headers: _headers!,
      );

      if (kDebugMode) {
        print('Models response status: ${response.statusCode}');
        print('Models response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        // Парсинг данных о моделях
        final modelsData = json.decode(response.body);
        if (modelsData['data'] != null) {
          return (modelsData['data'] as List)
              .map((model) => {
                    'id': model['id'] as String,
                    'name': (() {
                      try {
                        return utf8.decode((model['name'] as String).codeUnits);
                      } catch (e) {
                        // Remove invalid UTF-8 characters and try again
                        final cleaned = (model['name'] as String)
                            .replaceAll(RegExp(r'[^\x00-\x7F]'), '');
                        return utf8.decode(cleaned.codeUnits);
                      }
                    })(),
                    'pricing': {
                      'prompt': model['pricing']['prompt'] as String,
                      'completion': model['pricing']['completion'] as String,
                    },
                    'context_length': (model['context_length'] ??
                            model['top_provider']['context_length'] ??
                            0)
                        .toString(),
                  })
              .toList();
        }
        throw Exception('Invalid API response format');
      } else {
        // Возвращение моделей по умолчанию, если API недоступен
        return [
          {'id': 'deepseek-coder', 'name': 'DeepSeek'},
          {'id': 'claude-3-sonnet', 'name': 'Claude 3.5 Sonnet'},
          {'id': 'gpt-3.5-turbo', 'name': 'GPT-3.5 Turbo'},
        ];
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting models: $e');
      }
      // Возвращение моделей по умолчанию в случае ошибки
      return [
        {'id': 'deepseek-coder', 'name': 'DeepSeek'},
        {'id': 'claude-3-sonnet', 'name': 'Claude 3.5 Sonnet'},
        {'id': 'gpt-3.5-turbo', 'name': 'GPT-3.5 Turbo'},
      ];
    }
  }

  // Метод отправки сообщения через API
  Future<Map<String, dynamic>> sendMessage(String message, String model) async {
    try {
      // Подготовка данных для отправки
      final data = {
        'model': model, // Модель для генерации ответа
        'messages': [
          {'role': 'user', 'content': message} // Сообщение пользователя
        ],
        'max_tokens': _maxTokens, // Максимальное количество токенов
        'temperature': _temperature, // Температура генерации
        'stream': false, // Отключение потоковой передачи
      };

      if (kDebugMode) {
        print('Sending message to API: ${json.encode(data)}');
      }

      // Выполнение POST запроса
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: _headers!,
        body: json.encode(data),
      );

      if (kDebugMode) {
        print('Message response status: ${response.statusCode}');
        print('Message response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        // Успешный ответ
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        return responseData;
      } else {
        // Обработка ошибки
        final errorData = json.decode(utf8.decode(response.bodyBytes));
        return {
          'error': errorData['error']?['message'] ?? 'Unknown error occurred'
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending message: $e');
      }
      return {'error': e.toString()};
    }
  }

  // Метод получения текущего баланса
  Future<String> getBalance() async {
    try {
      // Выполнение GET запроса для получения баланса
      final response = await http.get(
        Uri.parse(_baseUrl?.contains('vsegpt.ru') == true
            ? '$_baseUrl/balance'
            : '$_baseUrl/credits'),
        headers: _headers!,
      );

      if (kDebugMode) {
        print('Balance response status: ${response.statusCode}');
        print('Balance response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        // Парсинг данных о балансе
        final data = json.decode(response.body);
        if (data != null && data['data'] != null) {
          if (_baseUrl?.contains('vsegpt.ru') == true) {
            final credits =
                double.tryParse(data['data']['credits'].toString()) ??
                    0.0; // Доступно средств
            return '${credits.toStringAsFixed(2)}₽'; // Расчет доступного баланса
          } else {
            final credits = data['data']['total_credits'] ?? 0; // Общие кредиты
            final usage =
                data['data']['total_usage'] ?? 0; // Использованные кредиты
            return '\$${(credits - usage).toStringAsFixed(2)}'; // Расчет доступного баланса
          }
        }
      }
      return _baseUrl?.contains('vsegpt.ru') == true
          ? '0.00₽'
          : '\$0.00'; // Возвращение нулевого баланса по умолчанию
    } catch (e) {
      if (kDebugMode) {
        print('Error getting balance: $e');
      }
      return 'Error'; // Возвращение ошибки в случае исключения
    }
  }

  // Метод форматирования цен
  String formatPricing(double pricing) {
    try {
      if (_baseUrl?.contains('vsegpt.ru') == true) {
        return '${pricing.toStringAsFixed(3)}₽/K';
      } else {
        return '\$${(pricing * 1000000).toStringAsFixed(3)}/M';
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error formatting pricing: $e');
      }
      return '0.00';
    }
  }
}
