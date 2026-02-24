import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cubit para gestionar el tema de la aplicación
/// Permite cambiar entre tema claro, oscuro o seguir el sistema
class ThemeCubit extends Cubit<ThemeMode> {
  static const String _themePreferenceKey = 'theme_mode';

  ThemeCubit() : super(ThemeMode.light) {
    _loadThemePreference();
  }

  /// Carga la preferencia de tema guardada
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themePreferenceKey);

    if (themeIndex != null) {
      emit(ThemeMode.values[themeIndex]);
    }
  }

  /// Cambia el tema y persiste la preferencia
  Future<void> setThemeMode(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themePreferenceKey, themeMode.index);
    emit(themeMode);
  }

  /// Alterna entre tema claro y oscuro
  /// Si está en sistema, cambia a claro
  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(newMode);
  }

  /// Establece tema claro
  Future<void> setLightTheme() async {
    await setThemeMode(ThemeMode.light);
  }

  /// Establece tema oscuro
  Future<void> setDarkTheme() async {
    await setThemeMode(ThemeMode.dark);
  }

  /// Establece tema del sistema
  Future<void> setSystemTheme() async {
    await setThemeMode(ThemeMode.system);
  }

  /// Retorna true si el tema actual es oscuro
  bool get isDarkMode => state == ThemeMode.dark;

  /// Retorna true si está usando el tema del sistema
  bool get isSystemMode => state == ThemeMode.system;
}
