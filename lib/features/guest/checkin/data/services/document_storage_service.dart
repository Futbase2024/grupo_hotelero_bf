import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Servicio para gestionar la subida de documentos a Supabase Storage
///
/// Flujo:
/// 1. Capturar imagen con compresión
/// 2. Comprimir adicionalmente si es necesario
/// 3. Subir a bucket 'guest-documents'
/// 4. Devolver URL firmada para acceso
class DocumentStorageService {
  DocumentStorageService(this._supabase);

  final SupabaseClient _supabase;
  static const String _bucketId = 'guest-documents';

  /// Tamaño máximo de archivo (500KB)
  static const int maxFileSizeBytes = 500 * 1024;

  /// Dimensiones máximas para compresión
  static const int maxDimension = 1200;

  /// Calidad de compresión JPEG
  static const int compressionQuality = 80;

  /// Captura imagen con compresión inicial
  Future<Uint8List?> captureImage({
    required ImageSource source,
    int maxWidth = 1200,
    int maxHeight = 1200,
    int quality = 85,
  }) async {
    final picker = ImagePicker();

    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: maxWidth.toDouble(),
      maxHeight: maxHeight.toDouble(),
      imageQuality: quality,
    );

    if (image == null) return null;

    return await image.readAsBytes();
  }

  /// Comprime una imagen si excede el tamaño máximo
  ///
  /// Usa [intrinsic] para redimensionar manteniendo aspect ratio
  Future<Uint8List> compressIfNeeded(Uint8List imageBytes) async {
    // Si ya está por debajo del límite, devolver tal cual
    if (imageBytes.length <= maxFileSizeBytes) {
      return imageBytes;
    }

    debugPrint('📦 [DocumentStorage] Comprimiendo imagen: ${imageBytes.length} bytes');

    // Decodificar imagen
    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    // Calcular nuevas dimensiones manteniendo aspect ratio
    var width = image.width.toDouble();
    var height = image.height.toDouble();

    if (width > maxDimension || height > maxDimension) {
      final ratio = width / height;
      if (width > height) {
        width = maxDimension.toDouble();
        height = width / ratio;
      } else {
        height = maxDimension.toDouble();
        width = height * ratio;
      }
    }

    // Redimensionar
    final byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    if (byteData == null) {
      throw Exception('No se pudo comprimir la imagen');
    }

    final compressedBytes = byteData.buffer.asUint8List();
    debugPrint('📦 [DocumentStorage] Imagen comprimida: ${compressedBytes.length} bytes');

    image.dispose();
    codec.dispose();

    return compressedBytes;
  }

  /// Sube un documento a Supabase Storage
  ///
  /// [imageBytes] - Bytes de la imagen
  /// [guestId] - ID del huésped (para organizar carpetas)
  /// [documentType] - Tipo de documento (dni, nie, passport)
  ///
  /// Retorna la ruta del archivo en el bucket
  Future<String> uploadDocument({
    required Uint8List imageBytes,
    required String guestId,
    required String documentType,
  }) async {
    try {
      // Comprimir si es necesario
      final compressedBytes = await compressIfNeeded(imageBytes);

      // Generar nombre único
      final fileName = '${const Uuid().v4()}.$documentType.jpg';
      final filePath = '$guestId/$fileName';

      debugPrint('📤 [DocumentStorage] Subiendo: $filePath');

      // Subir a Supabase Storage
      await _supabase.storage.from(_bucketId).uploadBinary(
        filePath,
        compressedBytes,
        fileOptions: FileOptions(
          contentType: 'image/jpeg',
          upsert: true,
        ),
      );

      debugPrint('✅ [DocumentStorage] Archivo subido correctamente');
      return filePath;
    } catch (e) {
      debugPrint('❌ [DocumentStorage] Error al subir: $e');
      rethrow;
    }
  }

  /// Obtiene URL firmada para acceder a un documento
  ///
  /// [storagePath] - Ruta del archivo en el bucket
  /// [expiresIn] - Segundos hasta que expire la URL (default: 1 año)
  /// ✅ OPTIMIZACIÓN: Aumentado a 1 año para evitar regeneración de URLs
  Future<String> getSignedUrl(
    String storagePath, {
    int expiresIn = 31536000, // 1 año
  }) async {
    final url = await _supabase.storage
        .from(_bucketId)
        .createSignedUrl(storagePath, expiresIn);

    return url;
  }

  /// Obtiene URL pública para un documento
  ///
  /// NOTA: Solo funciona si el bucket es público
  /// Para buckets privados, usar [getSignedUrl]
  String getPublicUrl(String storagePath) {
    return _supabase.storage
        .from(_bucketId)
        .getPublicUrl(storagePath);
  }

  /// Elimina un documento del storage
  Future<void> deleteDocument(String storagePath) async {
    await _supabase.storage.from(_bucketId).remove([storagePath]);
    debugPrint('🗑️ [DocumentStorage] Documento eliminado: $storagePath');
  }

  /// Flujo completo: capturar, comprimir, subir y obtener URL
  ///
  /// Retorna [storagePath, signedUrl] o null si se cancela
  Future<UploadResult?> captureAndUpload({
    required ImageSource source,
    required String guestId,
    required String documentType,
  }) async {
    // 1. Capturar imagen
    final imageBytes = await captureImage(source: source);
    if (imageBytes == null) return null;

    // 2. Subir (incluye compresión automática)
    final storagePath = await uploadDocument(
      imageBytes: imageBytes,
      guestId: guestId,
      documentType: documentType,
    );

    // 3. Obtener URL firmada
    final signedUrl = await getSignedUrl(storagePath);

    return UploadResult(
      storagePath: storagePath,
      signedUrl: signedUrl,
      fileSize: imageBytes.length,
    );
  }
}

/// Resultado de subir un documento
class UploadResult {
  const UploadResult({
    required this.storagePath,
    required this.signedUrl,
    required this.fileSize,
  });

  /// Ruta del archivo en el bucket (para guardar en BD)
  final String storagePath;

  /// URL firmada para acceso temporal
  final String signedUrl;

  /// Tamaño del archivo en bytes
  final int fileSize;

  /// Tamaño formateado legible
  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
