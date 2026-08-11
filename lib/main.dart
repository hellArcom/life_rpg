import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    return MaterialApp(
      title: 'Life RPG',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      locale: settings.locale,
      home: const MainNavigationScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
