import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Servicio helper para reportar errores a Firebase Crashlytics
///
/// Uso:
/// ```dart
/// try {
///   // operación crítica
/// } catch (e, s) {
///   CrashlyticsService.recordError(e, s, reason: 'Descripción del contexto');
///   rethrow;
/// }
/// ```
class CrashlyticsService {
  CrashlyticsService._();

  static final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  /// Registra un error no fatal
  ///
  /// [error] - El error ocurrido
  /// [stackTrace] - La traza del error
  /// [reason] - Descripción del contexto donde ocurrió el error
  /// [information] - Información adicional (lista de strings)
  static Future<void> recordError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    Iterable<String> information = const [],
  }) async {
    if (kDebugMode) {
      debugPrint('🔴 [Crashlytics] Error: $error');
      if (reason != null) debugPrint('🔴 [Crashlytics] Reason: $reason');
      if (stackTrace != null) {
        debugPrint('🔴 [Crashlytics] StackTrace: $stackTrace');
      }
    }

    await _crashlytics.recordError(
      error,
      stackTrace,
      reason: reason,
      information: information,
    );
  }

  /// Registra un error fatal (la app se cerrará)
  static Future<void> recordFatalError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
  }) async {
    if (kDebugMode) {
      debugPrint('💀 [Crashlytics] FATAL Error: $error');
      if (reason != null) debugPrint('💀 [Crashlytics] Reason: $reason');
    }

    await _crashlytics.recordError(
      error,
      stackTrace,
      reason: reason,
      fatal: true,
    );
  }

  /// Registra un mensaje de log para debugging
  ///
  /// Los logs se asocian con el siguiente crash report
  static Future<void> log(String message) async {
    if (kDebugMode) {
      debugPrint('📝 [Crashlytics] Log: $message');
    }
    await _crashlytics.log(message);
  }

  /// Establece un identificador de usuario para los crash reports
  static Future<void> setUserIdentifier(String identifier) async {
    if (kDebugMode) {
      debugPrint('👤 [Crashlytics] User: $identifier');
    }
    await _crashlytics.setUserIdentifier(identifier);
  }

  /// Establece una clave-valor personalizada
  static Future<void> setCustomKey(String key, dynamic value) async {
    if (kDebugMode) {
      debugPrint('🔑 [Crashlytics] Key: $key = $value');
    }
    await _crashlytics.setCustomKey(key, value);
  }

  /// Fuerza el envío de crash reports pendientes
  static Future<void> sendUnsentReports() async {
    await _crashlytics.sendUnsentReports();
  }

  /// Verifica si Crashlytics está habilitado
  static Future<bool> isCrashlyticsCollectionEnabled() async {
    return _crashlytics.isCrashlyticsCollectionEnabled;
  }
}
