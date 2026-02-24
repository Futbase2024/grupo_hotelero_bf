import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuración de la aplicación
/// Gestiona las variables de entorno para diferentes ambientes
class AppConfig {
  AppConfig._();

  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ?? '';

  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  static String get environment =>
      dotenv.env['ENVIRONMENT'] ?? 'dev';

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
