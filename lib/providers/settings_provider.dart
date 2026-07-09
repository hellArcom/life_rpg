import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/offline_manager.dart';

class SettingsState {
  final ThemeMode themeMode;
  final Locale locale;

  SettingsState({
    this.themeMode = ThemeMode.dark,
    this.locale = const Locale('fr'),
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
    );
  }

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode.name,
    'languageCode': locale.languageCode,
  };

  factory SettingsState.fromJson(Map<String, dynamic> json) {
    return SettingsState(
      themeMode: ThemeMode.values.byName(json['themeMode'] ?? 'dark'),
      locale: Locale(json['languageCode'] ?? 'fr'),
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    final savedData = OfflineManager.getData('settings');
    if (savedData != null && savedData is Map<String, dynamic>) {
      return SettingsState.fromJson(savedData);
    }
    return SettingsState();
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _save();
  }

  void setLocale(Locale locale) {
    state = state.copyWith(locale: locale);
    _save();
  }

  Future<void> _save() async {
    try {
      await OfflineManager.saveData('settings', state.toJson());
    } catch (_) {}
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);
