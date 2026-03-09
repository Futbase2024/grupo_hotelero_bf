import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuración de la aplicación
/// Gestiona las variables de entorno para diferentes ambientes
/// Soporta tanto dotenv (desarrollo) como compile-time variables (producción web)
class AppConfig {
  AppConfig._();

  /// Valores por defecto hardcodeados para desarrollo web
  /// Estos valores se usan cuando no hay .env ni compile-time constants
  static const String _defaultSupabaseUrl = 'https://qwepisgdqlmqfxwqkztz.supabase.co';
  static const String _defaultSupabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF3ZXBpc2dkcWxtcWZ4d3FrenR6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE5MDYxOTIsImV4cCI6MjA4NzQ4MjE5Mn0.pUdETUpzY4wdnK54CVxUdo3BDe0GDFles82IG000SY0';

  /// Obtiene variable de entorno con fallback a valores por defecto
  /// Prioriza: 1) dotenv, 2) compile-time constant, 3) valor por defecto hardcodeado
  static String _getEnvVar(String key, String compileTimeDefault, String hardcodedDefault) {
    // 1. Intentar obtener de dotenv primero (desarrollo móvil/desktop)
    final dotEnvValue = dotenv.env[key];
    if (dotEnvValue != null && dotEnvValue.isNotEmpty) {
      debugPrint('✅ $key cargado desde .env');
      return dotEnvValue;
    }

    // 2. Fallback a compile-time variable (producción web con --dart-define)
    if (compileTimeDefault.isNotEmpty) {
      debugPrint('✅ $key cargado desde compile-time constant');
      return compileTimeDefault;
    }

    // 3. Fallback a valor hardcodeado (desarrollo web sin --dart-define)
    debugPrint('⚠️ $key usando valor por defecto hardcodeado');
    return hardcodedDefault;
  }

  static String get supabaseUrl =>
      _getEnvVar('SUPABASE_URL', const String.fromEnvironment('SUPABASE_URL', defaultValue: ''), _defaultSupabaseUrl);

  static String get supabaseAnonKey =>
      _getEnvVar('SUPABASE_ANON_KEY', const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: ''), _defaultSupabaseAnonKey);

  static String get environment =>
      _getEnvVar('ENVIRONMENT', const String.fromEnvironment('ENVIRONMENT', defaultValue: ''), 'dev');

  static bool get isProduction => environment == 'prod';
  static bool get isDevelopment => environment == 'dev';
  static bool get isStaging => environment == 'staging';

  /// Valida que las configuraciones críticas estén presentes
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Retorna información del ambiente actual
  static String get environmentInfo {
    if (isProduction) return 'Producción';
    if (isStaging) return 'Staging';
    return 'Desarrollo';
  }
}
