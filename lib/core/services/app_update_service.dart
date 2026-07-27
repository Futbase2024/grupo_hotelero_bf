import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Modelo para la información de versión desde Supabase
class AppVersionInfo {
  final String latestVersion;
  final String minimumVersion;
  final bool forceUpdate;
  final String? updateMessage;
  final String? iosAppStoreId;
  final String? androidPackageName;

  const AppVersionInfo({
    required this.latestVersion,
    required this.minimumVersion,
    required this.forceUpdate,
    this.updateMessage,
    this.iosAppStoreId,
    this.androidPackageName,
  });

  factory AppVersionInfo.fromJson(Map<String, dynamic> json) {
    return AppVersionInfo(
      latestVersion: json['latest_version'] as String? ?? '1.0.0',
      minimumVersion: json['minimum_version'] as String? ?? '1.0.0',
      forceUpdate: json['force_update'] as bool? ?? false,
      updateMessage: json['update_message'] as String?,
      // Soportar ambos formatos: nuevo (app_store_id) y legacy (ios_app_store_id)
      iosAppStoreId: json['app_store_id'] as String? ?? json['ios_app_store_id'] as String?,
      androidPackageName: json['package_name'] as String? ?? json['android_package_name'] as String?,
    );
  }
}

/// Servicio para gestionar actualizaciones de la aplicación
/// Controla versiones desde Supabase y permite actualizaciones forzadas u opcionales
class AppUpdateService {
  AppUpdateService._();
  static final AppUpdateService instance = AppUpdateService._();

  SupabaseClient get _client => Supabase.instance.client;

  AppVersionInfo? _versionInfo;
  String? _currentVersion;
  String? _packageName;

  /// Future de la inicialización en curso.
  ///
  /// Permite lanzar `initialize()` en segundo plano (sin bloquear el arranque)
  /// y que `checkForUpdate()` espere a que termine antes de comparar versiones.
  Future<void>? _initFuture;

  /// Inicializa el servicio de actualizaciones
  ///
  /// Es idempotente: llamadas sucesivas reutilizan la misma inicialización.
  Future<void> initialize({
    String? iosAppStoreId,
    String? androidPackageName,
  }) {
    return _initFuture ??= _doInitialize(
      iosAppStoreId: iosAppStoreId,
      androidPackageName: androidPackageName,
    );
  }

  Future<void> _doInitialize({
    String? iosAppStoreId,
    String? androidPackageName,
  }) async {
    try {
      debugPrint('🔄 [AppUpdateService] Inicializando...');

      // 1. Obtener versión actual de la app
      // package_info_plus no funciona en web, usar valores por defecto
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        _currentVersion = packageInfo.version;
        _packageName = packageInfo.packageName;
        debugPrint('📱 [AppUpdateService] Versión actual: $_currentVersion');
        debugPrint('📦 [AppUpdateService] Package: $_packageName');
      } catch (e) {
        // En web o plataformas no soportadas, usar valores por defecto
        debugPrint('⚠️ [AppUpdateService] PackageInfo no disponible, usando valores por defecto');
        _currentVersion = '1.0.1'; // Valor por defecto
        _packageName = 'com.bfstay.app';
      }

      // 2. Obtener configuración desde Supabase
      await _loadVersionConfig();

      debugPrint('✅ [AppUpdateService] Inicializado correctamente');
    } catch (e, s) {
      debugPrint('❌ [AppUpdateService] Error inicializando: $e');
      debugPrint('❌ StackTrace: $s');
    }
  }

  /// Carga la configuración de versión desde Supabase
  Future<void> _loadVersionConfig() async {
    try {
      final response = await _client
          .from('app_config')
          .select()
          .eq('key', 'app_version')
          .maybeSingle();

      if (response != null && response['value'] != null) {
        final value = response['value'] as Map<String, dynamic>;

        // Determinar qué configuración de plataforma usar
        final platformKey = defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
        final platformConfig = value[platformKey] as Map<String, dynamic>?;

        if (platformConfig != null) {
          _versionInfo = AppVersionInfo.fromJson(platformConfig);
          debugPrint(
            '📋 [AppUpdateService] Config cargada ($platformKey): '
            'latest=${_versionInfo!.latestVersion}, '
            'min=${_versionInfo!.minimumVersion}, '
            'force=${_versionInfo!.forceUpdate}',
          );
        } else {
          _useDefaultConfig();
        }
      } else {
        _useDefaultConfig();
      }
    } catch (e) {
      debugPrint('⚠️ [AppUpdateService] Error cargando config: $e');
      _useDefaultConfig();
    }
  }

  void _useDefaultConfig() {
    _versionInfo = AppVersionInfo(
      latestVersion: '1.0.0',
      minimumVersion: '1.0.0',
      forceUpdate: false,
      iosAppStoreId: defaultTargetPlatform == TargetPlatform.iOS ? '6759832221' : null,
      androidPackageName: defaultTargetPlatform == TargetPlatform.android ? 'com.bfstay.app' : null,
    );
    debugPrint('📋 [AppUpdateService] Usando configuración por defecto');
  }

  /// Recarga la configuración desde Supabase (útil para refrescar)
  Future<void> refreshConfig() async {
    await _loadVersionConfig();
  }

  /// Verifica si hay una actualización disponible
  Future<UpdateStatus> checkForUpdate() async {
    debugPrint('🔍 [AppUpdateService] checkForUpdate llamado');

    // Esperar a la inicialización si aún está en curso (se lanza en segundo
    // plano durante el arranque para no bloquear la primera pantalla)
    await _initFuture;

    debugPrint('🔍 [AppUpdateService] _versionInfo: $_versionInfo');
    debugPrint('🔍 [AppUpdateService] _currentVersion: $_currentVersion');

    if (_versionInfo == null || _currentVersion == null) {
      debugPrint('⚠️ [AppUpdateService] Datos insuficientes para verificar');
      return UpdateStatus.unknown;
    }

    try {
      final current = _parseVersion(_currentVersion!);
      final minimum = _parseVersion(_versionInfo!.minimumVersion);
      final latest = _parseVersion(_versionInfo!.latestVersion);

      debugPrint('🔍 [AppUpdateService] Comparando versiones:');
      debugPrint('   Current: $current ($_currentVersion)');
      debugPrint('   Minimum: $minimum (${_versionInfo!.minimumVersion})');
      debugPrint('   Latest: $latest (${_versionInfo!.latestVersion})');
      debugPrint('   ForceUpdate: ${_versionInfo!.forceUpdate}');

      // Si la versión actual es menor que la mínima, actualización forzada
      final currentVsMin = _compareVersions(current, minimum);
      debugPrint('   Current vs Minimum: $currentVsMin');

      if (currentVsMin < 0) {
        debugPrint('🔴 [AppUpdateService] Actualización FORZADA requerida (versión menor que mínima)');
        return UpdateStatus.forceRequired;
      }

      // Si la versión actual es menor que la última, actualización opcional
      final currentVsLatest = _compareVersions(current, latest);
      debugPrint('   Current vs Latest: $currentVsLatest');

      if (currentVsLatest < 0) {
        // Pero si forceUpdate está activado, es forzada
        if (_versionInfo!.forceUpdate) {
          debugPrint('🟠 [AppUpdateService] Actualización FORZADA por configuración');
          return UpdateStatus.forceRequired;
        }
        debugPrint('🟡 [AppUpdateService] Actualización OPCIONAL disponible');
        return UpdateStatus.available;
      }

      debugPrint('🟢 [AppUpdateService] App actualizada');
      return UpdateStatus.notAvailable;
    } catch (e) {
      debugPrint('❌ [AppUpdateService] Error verificando actualización: $e');
      return UpdateStatus.unknown;
    }
  }

  /// Abre la tienda para actualizar la app
  Future<bool> openStore() async {
    try {
      Uri storeUrl;

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        // App Store - usar app_store_id de la configuración iOS
        final appId = _versionInfo?.iosAppStoreId ?? '6759832221';
        storeUrl = Uri.parse('https://apps.apple.com/app/id$appId');
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        // Google Play Store - usar package_name de la configuración Android
        final packageName = _versionInfo?.androidPackageName ?? _packageName ?? 'com.bfstay.app';
        storeUrl = Uri.parse('market://details?id=$packageName');
      } else {
        debugPrint('⚠️ [AppUpdateService] Plataforma no soportada');
        return false;
      }

      debugPrint('🔗 [AppUpdateService] Abriendo tienda: $storeUrl');

      if (await canLaunchUrl(storeUrl)) {
        final launched = await launchUrl(
          storeUrl,
          mode: LaunchMode.externalApplication,
        );
        if (!launched) {
          // Fallback para Android si market:// no funciona
          if (defaultTargetPlatform == TargetPlatform.android) {
            final packageName = _versionInfo?.androidPackageName ?? _packageName ?? 'com.bfstay.app';
            final playStoreUrl = Uri.parse('https://play.google.com/store/apps/details?id=$packageName');
            return await launchUrl(playStoreUrl, mode: LaunchMode.externalApplication);
          }
        }
        return launched;
      }
      return false;
    } catch (e) {
      debugPrint('❌ [AppUpdateService] Error abriendo tienda: $e');
      return false;
    }
  }

  /// Obtiene la información de versión
  AppVersionInfo? get versionInfo => _versionInfo;

  /// Obtiene la versión actual
  String? get currentVersion => _currentVersion;

  /// Parsea una versión string a lista de enteros
  List<int> _parseVersion(String version) {
    return version
        .split('.')
        .map((e) => int.tryParse(e.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();
  }

  /// Compara dos versiones
  /// Retorna: negativo si v1 < v2, 0 si iguales, positivo si v1 > v2
  int _compareVersions(List<int> v1, List<int> v2) {
    final maxLen = v1.length > v2.length ? v1.length : v2.length;

    for (var i = 0; i < maxLen; i++) {
      final num1 = i < v1.length ? v1[i] : 0;
      final num2 = i < v2.length ? v2[i] : 0;

      if (num1 != num2) {
        return num1.compareTo(num2);
      }
    }
    return 0;
  }
}

/// Estado de la actualización
enum UpdateStatus {
  unknown,
  notAvailable,
  available,
  forceRequired,
}
