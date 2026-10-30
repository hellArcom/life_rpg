import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/offline_manager.dart';
import '../services/server_service.dart';

enum ColorBlindMode {
  none,
  protanopia,
  deuteranopia,
  tritanopia,
}

/// Returns the system locale if supported (fr/en/es), otherwise English.
Locale _detectSystemLocale() {
  final system = ui.PlatformDispatcher.instance.locale;
  const supported = ['fr', 'en', 'es', 'zh', 'hi', 'ar', 'pt', 'ru', 'de', 'ja', 'vi', 'tr', 'id'];
  if (supported.contains(system.languageCode)) {
    return Locale(system.languageCode);
  }
  return const Locale('en');
}

class SettingsState {
  final ThemeMode themeMode;
  final Locale locale;
  final double textScale;
  final ColorBlindMode colorBlindMode;
  final bool highContrast;
  final bool onlineServicesEnabled;
  final String serverUrl;

  SettingsState({
    this.themeMode = ThemeMode.dark,
    Locale? locale,
    this.textScale = 1.0,
    this.colorBlindMode = ColorBlindMode.none,
    this.highContrast = false,
    this.onlineServicesEnabled = false,
    this.serverUrl = '',
  }) : locale = locale ?? _detectSystemLocale();

  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    double? textScale,
    ColorBlindMode? colorBlindMode,
    bool? highContrast,
    bool? onlineServicesEnabled,
    String? serverUrl,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      textScale: textScale ?? this.textScale,
      colorBlindMode: colorBlindMode ?? this.colorBlindMode,
      highContrast: highContrast ?? this.highContrast,
      onlineServicesEnabled: onlineServicesEnabled ?? this.onlineServicesEnabled,
      serverUrl: serverUrl ?? this.serverUrl,
    );
  }

  String get colorBlindModeLabel {
    switch (colorBlindMode) {
      case ColorBlindMode.none:
        return 'Aucun';
      case ColorBlindMode.protanopia:
        return 'Protanopie (rouge)';
      case ColorBlindMode.deuteranopia:
        return 'Deutéranopie (vert)';
      case ColorBlindMode.tritanopia:
        return 'Tritanopie (bleu)';
    }
  }

  String localizedLabel(dynamic t) {
    // t is expected to be Translations, avoids import cycle by using dynamic
    try {
      switch (colorBlindMode) {
        case ColorBlindMode.none:
          return (t as dynamic).noColorBlind as String? ?? 'Aucun';
        case ColorBlindMode.protanopia:
          return (t as dynamic).protanopia as String? ?? 'Protanopie (rouge)';
        case ColorBlindMode.deuteranopia:
          return (t as dynamic).deuteranopia as String? ?? 'Deutéranopie (vert)';
        case ColorBlindMode.tritanopia:
          return (t as dynamic).tritanopia as String? ?? 'Tritanopie (bleu)';
      }
    } catch (_) {
      return colorBlindModeLabel;
    }
  }

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode.name,
    'languageCode': locale.languageCode,
    'textScale': textScale,
    'colorBlindMode': colorBlindMode.name,
    'highContrast': highContrast,
    'onlineServicesEnabled': onlineServicesEnabled,
    'serverUrl': serverUrl,
  };

  factory SettingsState.fromJson(Map<String, dynamic> json) {
    return SettingsState(
      themeMode: ThemeMode.values.byName(json['themeMode'] ?? 'dark'),
      locale: Locale(json['languageCode'] ?? _detectSystemLocale().languageCode),
      textScale: (json['textScale'] ?? 1.0).toDouble(),
      colorBlindMode: ColorBlindMode.values.byName(json['colorBlindMode'] ?? 'none'),
      highContrast: json['highContrast'] ?? false,
      onlineServicesEnabled: json['onlineServicesEnabled'] == true,
      serverUrl: json['serverUrl'] is String ? json['serverUrl'] as String : '',
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    final savedData = OfflineManager.getData('settings');
    if (savedData != null && savedData is Map<String, dynamic>) {
      final settings = SettingsState.fromJson(savedData);
      if (settings.onlineServicesEnabled && !ServerService.isValidServerUrl(settings.serverUrl)) {
        final safeSettings = settings.copyWith(onlineServicesEnabled: false);
        OfflineManager.saveData('settings', safeSettings.toJson());
        return safeSettings;
      }
      return settings;
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

  void setTextScale(double scale) {
    state = state.copyWith(textScale: scale.clamp(0.8, 1.5));
    _save();
  }

  void setColorBlindMode(ColorBlindMode mode) {
    state = state.copyWith(colorBlindMode: mode);
    _save();
  }

  void setHighContrast(bool value) {
    state = state.copyWith(highContrast: value);
    _save();
  }

  Future<void> setOnlineServicesEnabled(bool value) async {
    state = state.copyWith(onlineServicesEnabled: value);
    await _save();
  }

  Future<void> setServerUrl(String value) async {
    state = state.copyWith(serverUrl: value.trim());
    await _save();
  }

  Future<void> _save() async {
    try {
      await OfflineManager.saveData('settings', state.toJson());
    } catch (_) {}
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);
