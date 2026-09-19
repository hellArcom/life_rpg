import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/app_theme.dart';
import 'core/offline_manager.dart';
import 'services/notification_service.dart';
import 'ui/screens/main_navigation_screen.dart';
import 'providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('fr');
  await initializeDateFormatting('en');
  final systemLang = ui.PlatformDispatcher.instance.locale.languageCode;
  if (systemLang != 'fr' && systemLang != 'en') {
    try {
      await initializeDateFormatting(systemLang);
    } catch (_) {}
  }

  await NotificationService.init();
  await OfflineManager.init();
  
  runApp(
    const ProviderScope(
      child: LifeRPGApp(),
    ),
  );
}

class LifeRPGApp extends ConsumerWidget {
  const LifeRPGApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    final ThemeData lightTheme = settings.highContrast
        ? AppTheme.lightThemeHighContrast
        : AppTheme.lightTheme;
    final ThemeData darkTheme = settings.highContrast
        ? AppTheme.darkThemeHighContrast
        : AppTheme.darkTheme;

    return MaterialApp(
      title: 'Life RPG',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: const [
        Locale('fr'),
        Locale('en'),
        Locale('es'),
        Locale('zh'),
        Locale('hi'),
        Locale('ar'),
        Locale('pt'),
        Locale('ru'),
        Locale('de'),
        Locale('ja'),
        Locale('vi'),
        Locale('tr'),
        Locale('id'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(settings.textScale),
          ),
          child: child!,
        );
      },
      home: const MainNavigationScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
