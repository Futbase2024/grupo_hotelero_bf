import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Resultado de una traducción.
class TranslationResult {
  const TranslationResult({
    required this.translatedText,
    required this.detectedLanguage,
    required this.fromCache,
  });

  /// Texto traducido al idioma destino.
  final String translatedText;

  /// Código ISO 639-1 del idioma detectado en el original (vacío si no aplica).
  final String detectedLanguage;

  /// `true` si la traducción vino del caché (servidor o cliente), sin gasto de
  /// OpenAI.
  final bool fromCache;
}

/// Excepción de traducción. `code` identifica el tipo de fallo para mostrar un
/// mensaje adecuado en la UI.
class TranslationException implements Exception {
  const TranslationException({required this.code, required this.message});

  /// 'empty', 'http_STATUS', 'empty_result', 'network', ...
  final String code;
  final String message;

  @override
  String toString() => 'TranslationException($code): $message';
}

/// Repositorio de traducciones de mensajes de chat.
///
/// Llama a la Edge Function `translate-message` (que a su vez usa OpenAI
/// `gpt-4o-mini` y mantiene un caché en `message_translations`). Mantiene un
/// caché en memoria ([_cache]) durante la sesión para que la traducción
/// sobreviva al reciclaje del `ListView.builder` sin volver a llamar a la EF.
///
/// El idioma destino ([targetLang]) se resuelve una sola vez desde el locale
/// del dispositivo.
class TranslationRepository {
  TranslationRepository({required SupabaseClient client}) : _client = client;

  final SupabaseClient _client;

  /// Caché en memoria: key = "${messageId}_${targetLang}" -> texto traducido.
  final Map<String, String> _cache = {};

  String? _cachedTargetLang;

  /// Idioma destino por defecto (locale del dispositivo). Se resuelve lazy.
  String get targetLang {
    if (_cachedTargetLang != null) return _cachedTargetLang!;
    final code = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    _cachedTargetLang = code.isEmpty ? 'en' : code;
    return _cachedTargetLang!;
  }

  /// Devuelve la traducción cacheada en memoria, o `null` si no existe.
  /// Llamada **síncrona**: usar en `initState` del `MessageBubble` para
  /// restaurar la traducción al reciclar la burbuja.
  String? getCached(String messageId) => _cache[_cacheKey(messageId)];

  /// Traduce [text] para el mensaje [messageId].
  ///
  /// 1. Si ya está en el caché cliente, lo devuelve sin llamada de red.
  /// 2. Si no, invoca la Edge Function `translate-message` (que comprueba el
  ///    caché servidor y, si hace falta, llama a OpenAI).
  /// 3. Guarda el resultado en el caché cliente y lo devuelve.
  ///
  /// Lanza [TranslationException] si el texto está vacío o la llamada falla.
  Future<TranslationResult> translate({
    required String messageId,
    required String text,
  }) async {
    final lang = targetLang;
    final key = _cacheKey(messageId, lang);

    // 1. Caché cliente (ya traducido en esta sesión).
    final local = _cache[key];
    if (local != null) {
      return TranslationResult(
        translatedText: local,
        detectedLanguage: '',
        fromCache: true,
      );
    }

    // 2. Validación rápida.
    if (text.trim().isEmpty) {
      throw const TranslationException(code: 'empty', message: 'Texto vacío');
    }

    // 3. Invocar la Edge Function. El SDK inyecta el JWT del usuario
    //    automáticamente (la EF tiene verify_jwt: true).
    final FunctionResponse response;
    try {
      response = await _client.functions.invoke(
        'translate-message',
        body: {
          'messageId': messageId,
          'text': text,
          'targetLang': lang,
        },
      );
    } on Exception catch (e) {
      throw TranslationException(
        code: 'network',
        message: 'No se pudo conectar: ${e.toString()}',
      );
    }

    if (response.status != 200) {
      final errData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final detail =
          (errData['detail'] as String?) ?? (errData['error'] as String?);
      throw TranslationException(
        code: 'http_${response.status}',
        message: detail ?? 'Error en translate-message (${response.status})',
      );
    }

    final data = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : <String, dynamic>{};

    final translatedText = (data['translatedText'] as String?)?.trim() ?? '';
    if (translatedText.isEmpty) {
      throw const TranslationException(
        code: 'empty_result',
        message: 'La traducción está vacía',
      );
    }

    // 4. Guardar en caché cliente.
    _cache[key] = translatedText;

    return TranslationResult(
      translatedText: translatedText,
      detectedLanguage: (data['detectedLanguage'] as String?) ?? '',
      fromCache: (data['fromCache'] as bool?) ?? false,
    );
  }

  /// Limpia el caché en memoria (p. ej. al cerrar sesión).
  void clearCache() => _cache.clear();

  String _cacheKey(String messageId, [String? lang]) =>
      '${messageId}_${lang ?? targetLang}';
}
