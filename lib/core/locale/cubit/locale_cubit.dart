import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cubit para gestionar el idioma de la aplicación
/// Sigue el mismo patrón que ThemeCubit: SharedPreferences + Cubit
class LocaleCubit extends Cubit<Locale> {
  static const String _localePreferenceKey = 'app_locale';

  /// Locales soportados por la aplicación
  static const List<Locale> supportedLocales = [
    Locale('es'),
    Locale('en'),
    Locale('fr'),
    Locale('de'),
    Locale('it'),
    Locale('pt'),
  ];

  /// Nativos de cada idioma (siempre se muestran en su propio idioma)
  static const Map<String, String> nativeNames = {
    'es': 'Español',
    'en': 'English',
    'fr': 'Français',
    'de': 'Deutsch',
    'it': 'Italiano',
    'pt': 'Português',
  };

  LocaleCubit() : super(const Locale('es')) {
    _loadLocalePreference();
  }

  /// Carga la preferencia de idioma guardada
  Future<void> _loadLocalePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localePreferenceKey);
    if (code != null && supportedLocales.any((l) => l.languageCode == code)) {
      emit(Locale(code));
    }
  }

  /// Cambia el idioma y persiste la preferencia
  Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localePreferenceKey, locale.languageCode);
    emit(locale);
  }

  /// Nombre nativo del locale actual
  String get currentNativeName =>
      nativeNames[state.languageCode] ?? state.languageCode;
}
