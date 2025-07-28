// Импорт основных виджетов Flutter
import 'package:flutter/material.dart';
// Импорт пакета для работы с .env файлами
// Импорт пакета для локализации приложения
import 'package:flutter_localizations/flutter_localizations.dart';
// Импорт пакета для работы с провайдерами состояния
import 'package:provider/provider.dart';
// Импорт кастомного провайдера для управления состоянием чата
import 'providers/chat_provider.dart';
// Импорт основного экрана чата
import 'screens/chat_screen.dart';
import 'screens/api_key_required_screen.dart'; // Import the new screen
import 'package:ai_chat_flutter/services/app_settings_service.dart';
import 'package:ai_chat_flutter/api/openrouter_client.dart';

// Виджет для обработки и отлова ошибок в приложении
class ErrorBoundaryWidget extends StatelessWidget {
  // Дочерний виджет, который будет обернут в обработчик ошибок
  final Widget child;

  // Конструктор с обязательным параметром child
  const ErrorBoundaryWidget({super.key, required this.child});

  // Метод построения виджета
  @override
  Widget build(BuildContext context) {
    // Используем Builder для создания нового контекста
    return Builder(
      // Функция построения виджета с обработкой ошибок
      builder: (context) {
        // Пытаемся построить дочерний виджет
        try {
          // Возвращаем дочерний виджет, если ошибок нет
          return child;
          // Ловим и обрабатываем ошибки
        } catch (error, stackTrace) {
          // Логируем ошибку в консоль
          debugPrint('Error in ErrorBoundaryWidget: $error');
          // Логируем стек вызовов для отладки
          debugPrint('Stack trace: $stackTrace');
          // Возвращаем MaterialApp с экраном ошибки
          return MaterialApp(
            // Основной экран приложения
            home: Scaffold(
              // Красный фон для экрана ошибки
              backgroundColor: Colors.red,
              // Центрируем содержимое
              body: Center(
                // Добавляем отступы
                child: Padding(
                  // Отступы 16 пикселей со всех сторон
                  padding: const EdgeInsets.all(16.0),
                  // Текст с описанием ошибки
                  child: Text(
                    // Отображаем текст ошибки
                    'Error: $error',
                    // Белый цвет текста
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }
}

// Основная точка входа в приложение
void main() async {
  try {
    // Инициализация Flutter биндингов
    WidgetsFlutterBinding.ensureInitialized();

    // Настройка обработки ошибок Flutter
    FlutterError.onError = (FlutterErrorDetails details) {
      // Отображение ошибки
      FlutterError.presentError(details);
      // Логирование ошибки
      debugPrint('Flutter error: ${details.exception}');
      // Логирование стека вызовов
      debugPrint('Stack trace: ${details.stack}');
    };

    final appSettingsService = AppSettingsService();
    await appSettingsService.init();

    // Determine the initial screen based on API key presence
    final Widget initialScreen;
    if (appSettingsService.openRouterApiKey.isEmpty) {
      initialScreen = const ApiKeyRequiredScreen();
    } else {
      // Initialize OpenRouterClient with the app settings only if API key is present
      await OpenRouterClient.initialize(appSettingsService);
      initialScreen = const ChatScreen();
    }

    // Запуск приложения с обработчиком ошибок
    runApp(
      ChangeNotifierProvider<AppSettingsService>.value(
        value: appSettingsService,
        child: ErrorBoundaryWidget(child: MyApp(initialScreen: initialScreen)),
      ),
    );
  } catch (e, stackTrace) {
    // Логирование ошибки запуска приложения
    debugPrint('Error starting app: $e');
    // Логирование стека вызовов
    debugPrint('Stack trace: $stackTrace');
    // Запуск приложения с экраном ошибки
    runApp(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.red,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error starting app: $e',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Основной виджет приложения
class MyApp extends StatelessWidget {
  final Widget initialScreen; // Add initialScreen parameter
  const MyApp({super.key, required this.initialScreen}); // Update constructor

  @override
  Widget build(BuildContext context) {
    // Listen to AppSettingsService for changes
    final appSettingsService = Provider.of<AppSettingsService>(context);

    return ChangeNotifierProvider(
      create: (_) {
        try {
          return ChatProvider(appSettingsService);
        } catch (e, stackTrace) {
          debugPrint('Error creating ChatProvider: $e');
          debugPrint('Stack trace: $stackTrace');
          rethrow;
        }
      },
      child: MaterialApp(
        // Настройка поведения прокрутки
        builder: (context, child) {
          return ScrollConfiguration(
            behavior: ScrollBehavior(),
            child: child!,
          );
        },
        // Заголовок приложения
        title: 'AI Chat',
        // Скрытие баннера debug
        debugShowCheckedModeBanner: false,
        // Установка локали по умолчанию (русский)
        locale: const Locale('ru', 'RU'),
        // Поддерживаемые локали
        supportedLocales: const [
          Locale('ru', 'RU'), // Русский
          Locale('en', 'US'), // Английский (США)
        ],
        // Делегаты для локализации
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate, // Локализация Material виджетов
          GlobalWidgetsLocalizations.delegate, // Локализация базовых виджетов
          GlobalCupertinoLocalizations
              .delegate, // Локализация Cupertino виджетов
        ],
        // Настройка темы приложения
        theme: ThemeData(
          // Цветовая схема на основе синего цвета
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue, // Основной цвет
            brightness: Brightness.dark, // Темная тема
          ),
          // Использование Material 3
          useMaterial3: true,
          // Цвет фона Scaffold
          scaffoldBackgroundColor: const Color(0xFF1E1E1E),
          // Настройка темы AppBar
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF262626), // Цвет фона
            foregroundColor: Colors.white, // Цвет текста
          ),
          // Настройка темы диалогов
          dialogTheme: const DialogThemeData(
            backgroundColor: Color(0xFF333333), // Цвет фона
            titleTextStyle: TextStyle(
              color: Colors.white, // Цвет заголовка
              fontSize: 20, // Размер шрифта
              fontWeight: FontWeight.bold, // Жирный шрифт
              fontFamily: 'Roboto', // Шрифт
            ),
            contentTextStyle: TextStyle(
              color: Colors.white70, // Цвет текста
              fontSize: 16, // Размер шрифта
              fontFamily: 'Roboto', // Шрифт
            ),
          ),
          // Настройка текстовой темы
          textTheme: const TextTheme(
            bodyLarge: TextStyle(
              fontFamily: 'Roboto', // Шрифт
              fontSize: 16, // Размер шрифта
              color: Colors.white, // Цвет текста
            ),
            bodyMedium: TextStyle(
              fontFamily: 'Roboto', // Шрифт
              fontSize: 14, // Размер шрифта
              color: Colors.white, // Цвет текста
            ),
          ),
          // Настройка темы кнопок
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white, // Цвет текста
              textStyle: const TextStyle(
                fontFamily: 'Roboto', // Шрифт
                fontSize: 14, // Размер шрифта
              ),
            ),
          ),
          // Настройка темы текстовых кнопок
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white, // Цвет текста
              textStyle: const TextStyle(
                fontFamily: 'Roboto', // Шрифт
                fontSize: 14, // Размер шрифта
              ),
            ),
          ),
        ),
        // Основной экран приложения
        home: initialScreen, // Use the initialScreen
      ),
    );
  }
}
