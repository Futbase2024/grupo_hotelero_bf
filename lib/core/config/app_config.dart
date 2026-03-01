import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuración de la aplicación
/// Gestiona las variables de entorno para diferentes ambientes
/// Soporta tanto dotenv (desarrollo) como compile-time variables (producción web)
class AppConfig {
  AppConfig._();

  /// Obtiene variable de entorno con fallback a compile-time constant
  /// Prioriza dotenv para desarrollo, luego usa String.fromEnvironment para web
  static String _getEnvVar(String key, String compileTimeDefault) {
    // Intentar obtener de dotenv primero (desarrollo)
    final dotEnvValue = dotenv.env[key];
    if (dotEnvValue != null && dotEnvValue.isNotEmpty) {
      return dotEnvValue;
    }
    // Fallback a compile-time variable (producción web)
    return compileTimeDefault;
  }

  static String get supabaseUrl =>
      _getEnvVar('SUPABASE_URL', const String.fromEnvironment('SUPABASE_URL', defaultValue: ''));

  static String get supabaseAnonKey =>
      _getEnvVar('SUPABASE_ANON_KEY', const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: ''));

  static String get environment =>
      _getEnvVar('ENVIRONMENT', const String.fromEnvironment('ENVIRONMENT', defaultValue: 'dev'));

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
