import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../../providers/game_provider.dart';
import '../../core/translations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final gameNotifier = ref.read(gameProvider.notifier);
    final user = ref.watch(gameProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(t.appearance),
          ListTile(
            title: Text(t.theme),
            subtitle: Text(_themeModeToString(settings.themeMode, t)),
            leading: const Icon(Icons.palette),
            onTap: () => _showThemeDialog(context, settingsNotifier, settings.themeMode, t),
          ),
          const Divider(),
          ListTile(
            title: Text(t.language),
            subtitle: Text(_localeToString(settings.locale)),
            leading: const Icon(Icons.language),
            onTap: () => _showLanguageDialog(context, settingsNotifier, settings.locale, t),
          ),
          const Divider(),
          // Accessibility: Text scaling
          ListTile(
            title: Text(t.textScale),
            subtitle: Slider(
              value: settings.textScale,
              min: 0.8,
              max: 1.5,
              divisions: 7,
              label: '${(settings.textScale * 100).round()}%',
              onChanged: (v) => settingsNotifier.setTextScale(v),
            ),
            leading: const Icon(Icons.text_fields),
          ),
          const Divider(),
          // Accessibility: Color blind mode
          ListTile(
            title: Text(t.colorBlindMode),
            subtitle: Text(settings.colorBlindModeLabel),
            leading: const Icon(Icons.color_lens),
            onTap: () => _showColorBlindDialog(context, settingsNotifier, settings.colorBlindMode, t),
          ),
          const Divider(),
          // Accessibility: High contrast
          ListTile(
            title: Text(t.highContrast),
            subtitle: Text(settings.highContrast ? t.enabled : t.disabled),
            leading: const Icon(Icons.contrast),
            trailing: Switch(
              value: settings.highContrast,
              onChanged: (v) => settingsNotifier.setHighContrast(v),
            ),
          ),
          const Divider(),
          _buildSectionHeader('Audio'),
          ListTile(
            title: Text(t.soundVolume),
            subtitle: Slider(
              value: user.soundVolume,
              min: 0,
              max: 1,
              divisions: 10,
              label: '${(user.soundVolume * 100).round()}%',
              onChanged: (v) => gameNotifier.setSoundVolume(v),
            ),
            leading: Icon(
              user.soundVolume == 0 ? Icons.volume_off : Icons.volume_up,
            ),
          ),
          ListTile(
            title: Text(t.hapticLevel),
            subtitle: ToggleButtons(
              isSelected: [
                user.hapticLevel == 0,
                user.hapticLevel == 1,
                user.hapticLevel == 2,
                user.hapticLevel == 3,
              ],
              onPressed: (i) => gameNotifier.setHapticLevel(i),
              borderRadius: BorderRadius.circular(8),
              constraints: const BoxConstraints(minWidth: 48, minHeight: 36),
              children: [
                const Icon(Icons.vibration, size: 18),
                const Text('Faible', style: TextStyle(fontSize: 10)),
                const Text('Moyen', style: TextStyle(fontSize: 10)),
                const Text('Fort', style: TextStyle(fontSize: 10)),
              ],
            ),
            leading: const Icon(Icons.vibration),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.cyan,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  String _themeModeToString(ThemeMode mode, Translations t) {
    switch (mode) {
      case ThemeMode.system:
        return t.system;
      case ThemeMode.light:
        return t.light;
      case ThemeMode.dark:
        return t.dark;
    }
  }

  String _localeToString(Locale locale) {
    switch (locale.languageCode) {
      case 'fr':
        return 'Français';
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      case 'zh':
        return '中文';
      case 'hi':
        return 'हिंदी';
      case 'ar':
        return 'العربية';
      case 'pt':
        return 'Português';
      case 'ru':
        return 'Русский';
      case 'de':
        return 'Deutsch';
      case 'ja':
        return '日本語';
      case 'vi':
        return 'Tiếng Việt';
      case 'tr':
        return 'Türkçe';
      case 'id':
        return 'Indonesia';
      default:
        return locale.languageCode;
    }
  }

  void _showThemeDialog(BuildContext context, SettingsNotifier notifier, ThemeMode currentMode, Translations t) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.chooseTheme),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeMode.values.map((mode) {
            return RadioListTile<ThemeMode>(
              title: Text(_themeModeToString(mode, t)),
              value: mode,
              // ignore: deprecated_member_use
              groupValue: currentMode,
              // ignore: deprecated_member_use
              onChanged: (val) {
                if (val != null) {
                  notifier.setThemeMode(val);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, SettingsNotifier notifier, Locale currentLocale, Translations t) {
    final languages = [
      const Locale('fr'),
      const Locale('en'),
      const Locale('es'),
      const Locale('zh'),
      const Locale('hi'),
      const Locale('ar'),
      const Locale('pt'),
      const Locale('ru'),
      const Locale('de'),
      const Locale('ja'),
      const Locale('vi'),
      const Locale('tr'),
      const Locale('id'),
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.chooseLanguage),
        content: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: languages.map((locale) {
                return RadioListTile<Locale>(
                  title: Text(_localeToString(locale)),
                  value: locale,
                  // ignore: deprecated_member_use
                  groupValue: currentLocale,
                  // ignore: deprecated_member_use
                  onChanged: (val) {
                    if (val != null) {
                      notifier.setLocale(val);
                      Navigator.pop(context);
                    }
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  void _showColorBlindDialog(BuildContext context, SettingsNotifier notifier, ColorBlindMode currentMode, Translations t) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.chooseColorBlindMode),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ColorBlindMode.values.map((mode) {
            return RadioListTile<ColorBlindMode>(
              title: Text(_colorBlindModeToString(mode, t)),
              value: mode,
              // ignore: deprecated_member_use
              groupValue: currentMode,
              // ignore: deprecated_member_use
              onChanged: (val) {
                if (val != null) {
                  notifier.setColorBlindMode(val);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  String _colorBlindModeToString(ColorBlindMode mode, Translations t) {
    switch (mode) {
      case ColorBlindMode.none:
        return t.none;
      case ColorBlindMode.protanopia:
        return t.protanopia;
      case ColorBlindMode.deuteranopia:
        return t.deuteranopia;
      case ColorBlindMode.tritanopia:
        return t.tritanopia;
    }
  }
}
