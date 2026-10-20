import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Archivo elegido por el usuario, aún no subido.
class ChatAttachmentDraft {
  const ChatAttachmentDraft({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
    required this.isImage,
  });

  final Uint8List bytes;
  final String fileName;
  final String mimeType;
  final bool isImage;

  int get size => bytes.length;
}

/// Adjunto ya subido a Supabase Storage.
class ChatAttachmentUpload {
  const ChatAttachmentUpload({
    required this.storagePath,
    required this.fileName,
    required this.mimeType,
    required this.size,
    required this.isImage,
  });

  final String storagePath;
  final String fileName;
  final String mimeType;
  final int size;
  final bool isImage;
}

/// Error controlado al adjuntar un archivo al chat.
class ChatMediaException implements Exception {
  const ChatMediaException(this.message);

  final String message;

  @override
  String toString() => 'ChatMediaException: $message';
}

/// Gestiona la selección, subida y descarga de adjuntos del chat.
///
/// Los archivos viven en el bucket privado `chat-media` bajo la ruta
/// `{conversation_id}/{uuid}.{ext}`, de modo que las policies de
/// `storage.objects` puedan autorizar por participación en la conversación.
///
/// En `messages.content` se guarda el **storage path**, no la URL: las URLs
/// firmadas caducan y dejarían el mensaje roto. La URL se resuelve bajo demanda
/// y se cachea en memoria durante la sesión.
class ChatMediaService {
  ChatMediaService({required SupabaseClient client}) : _client = client;

  final SupabaseClient _client;

  static const String bucketId = 'chat-media';

  /// Límite del bucket (10 MB). Debe coincidir con `file_size_limit`.
  static const int maxFileSizeBytes = 10 * 1024 * 1024;

  /// Caducidad de las URLs firmadas: 1 año.
  static const int _signedUrlExpiresIn = 31536000;

  /// Extensiones aceptadas para documentos.
  static const List<String> documentExtensions = [
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'txt',
  ];

  static const Map<String, String> _mimeByExtension = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
    'heic': 'image/heic',
    'gif': 'image/gif',
    'pdf': 'application/pdf',
    'doc': 'application/msword',
    'docx':
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'xls': 'application/vnd.ms-excel',
    'xlsx':
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'txt': 'text/plain',
  };

  /// Caché de URLs firmadas por storage path (válidas toda la sesión).
  final Map<String, String> _signedUrlCache = {};

  // ============================================
  // SELECCIÓN
  // ============================================

  /// Captura una foto con la cámara. Devuelve `null` si el usuario cancela.
  Future<ChatAttachmentDraft?> pickImage({required ImageSource source}) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 80,
    );
    if (picked == null) return null;

    return _draftFromXFile(picked);
  }

  /// Abre la galería permitiendo elegir varias fotos.
  ///
  /// Devuelve una lista vacía si el usuario cancela.
  Future<List<ChatAttachmentDraft>> pickImages() async {
    final picked = await ImagePicker().pickMultiImage(
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 80,
    );
    if (picked.isEmpty) return const [];

    return Future.wait(picked.map(_draftFromXFile));
  }

  /// Abre el selector de documentos permitiendo elegir varios.
  ///
  /// Devuelve una lista vacía si el usuario cancela.
  Future<List<ChatAttachmentDraft>> pickDocuments() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: documentExtensions,
      allowMultiple: true,
      withData: true,
    );

    final files = result?.files ?? const <PlatformFile>[];
    if (files.isEmpty) return const [];

    final drafts = <ChatAttachmentDraft>[];
    for (final file in files) {
      final bytes = file.bytes;
      if (bytes == null) {
        throw ChatMediaException('No se pudo leer «${file.name}»');
      }

      final extension = _extensionOf(file.name, fallback: file.extension ?? '');
      drafts.add(ChatAttachmentDraft(
        bytes: bytes,
        fileName: file.name,
        mimeType: _mimeByExtension[extension] ?? 'application/octet-stream',
        isImage: false,
      ));
    }

    return drafts;
  }

  Future<ChatAttachmentDraft> _draftFromXFile(XFile file) async {
    final bytes = await file.readAsBytes();
    final extension = _extensionOf(file.name, fallback: 'jpg');

    return ChatAttachmentDraft(
      bytes: bytes,
      fileName: file.name,
      mimeType: _mimeByExtension[extension] ?? 'image/jpeg',
      isImage: true,
    );
  }

  // ============================================
  // SUBIDA
  // ============================================

  /// Sube el adjunto al bucket y devuelve sus datos ya persistibles.
  ///
  /// Lanza [ChatMediaException] si supera [maxFileSizeBytes].
  Future<ChatAttachmentUpload> upload({
    required String conversationId,
    required ChatAttachmentDraft draft,
  }) async {
    if (draft.size > maxFileSizeBytes) {
      throw const ChatMediaException('El archivo supera el límite de 10 MB');
    }

    final extension = _extensionOf(draft.fileName, fallback: 'bin');
    final storagePath = '$conversationId/${const Uuid().v4()}.$extension';

    debugPrint('📤 [ChatMedia] Subiendo $storagePath (${draft.size} bytes)');

    await _client.storage.from(bucketId).uploadBinary(
          storagePath,
          draft.bytes,
          fileOptions: FileOptions(contentType: draft.mimeType),
        );

    return ChatAttachmentUpload(
      storagePath: storagePath,
      fileName: draft.fileName,
      mimeType: draft.mimeType,
      size: draft.size,
      isImage: draft.isImage,
    );
  }

  // ============================================
  // LECTURA
  // ============================================

  /// Resuelve la URL de descarga de un adjunto.
  ///
  /// Si [pathOrUrl] ya es una URL absoluta se devuelve tal cual, para tolerar
  /// mensajes antiguos o enlaces externos.
  Future<String> resolveUrl(String pathOrUrl) async {
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return pathOrUrl;
    }

    final cached = _signedUrlCache[pathOrUrl];
    if (cached != null) return cached;

    final url = await _client.storage
        .from(bucketId)
        .createSignedUrl(pathOrUrl, _signedUrlExpiresIn);

    _signedUrlCache[pathOrUrl] = url;
    return url;
  }

  /// Descarga y guarda una imagen del chat en la galería del dispositivo.
  ///
  /// Lanza [ChatMediaException] si faltan permisos o la descarga falla.
  Future<void> saveImageToGallery({
    required String storagePath,
    required String fileName,
  }) async {
    try {
      if (!await Gal.hasAccess(toAlbum: true)) {
        final granted = await Gal.requestAccess(toAlbum: true);
        if (!granted) {
          throw const ChatMediaException(
            'Sin permiso para acceder a la galería',
          );
        }
      }

      final bytes = await _client.storage.from(bucketId).download(storagePath);
      await Gal.putImageBytes(bytes, name: _galleryNameFor(fileName));

      debugPrint('💾 [ChatMedia] Imagen guardada en la galería');
    } on ChatMediaException {
      rethrow;
    } on GalException catch (e) {
      throw ChatMediaException(e.type.message);
    } catch (e) {
      debugPrint('❌ [ChatMedia] Error guardando en galería: $e');
      throw const ChatMediaException('No se pudo guardar la imagen');
    }
  }

  /// `gal` añade la extensión por su cuenta, así que se le pasa sin ella.
  String _galleryNameFor(String fileName) {
    final dot = fileName.lastIndexOf('.');
    final base = dot == -1 ? fileName : fileName.substring(0, dot);
    return base.isEmpty ? 'bf-stay' : base;
  }

  // ============================================
  // BORRADO
  // ============================================

  /// Elimina un adjunto concreto. Nunca lanza: el borrado del mensaje manda.
  Future<void> deleteAttachment(String storagePath) async {
    if (storagePath.isEmpty || storagePath.startsWith('http')) return;

    try {
      await _client.storage.from(bucketId).remove([storagePath]);
      _signedUrlCache.remove(storagePath);
      debugPrint('🗑️ [ChatMedia] Adjunto eliminado: $storagePath');
    } catch (e) {
      debugPrint('⚠️ [ChatMedia] No se pudo eliminar $storagePath: $e');
    }
  }

  /// Elimina todos los adjuntos de una conversación. Nunca lanza.
  Future<void> deleteConversationAttachments(String conversationId) async {
    try {
      final objects =
          await _client.storage.from(bucketId).list(path: conversationId);
      if (objects.isEmpty) return;

      final paths = objects.map((o) => '$conversationId/${o.name}').toList();
      await _client.storage.from(bucketId).remove(paths);
      for (final path in paths) {
        _signedUrlCache.remove(path);
      }

      debugPrint(
        '🗑️ [ChatMedia] ${paths.length} adjuntos eliminados de $conversationId',
      );
    } catch (e) {
      debugPrint('⚠️ [ChatMedia] No se pudieron limpiar los adjuntos: $e');
    }
  }

  // ============================================
  // HELPERS
  // ============================================

  String _extensionOf(String fileName, {required String fallback}) {
    final dot = fileName.lastIndexOf('.');
    if (dot == -1 || dot == fileName.length - 1) return fallback.toLowerCase();
    return fileName.substring(dot + 1).toLowerCase();
  }
}
