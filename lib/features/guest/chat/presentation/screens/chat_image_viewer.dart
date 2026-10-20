import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../data/services/chat_media_service.dart';

/// Visor a pantalla completa para las imágenes del chat, con zoom y descarga.
///
/// Recibe la URL ya resuelta y el storage path como [cacheKey]: las URLs
/// firmadas caducan, así que usar la URL como clave de caché invalidaría el
/// archivo descargado cada vez que se renueva.
class ChatImageViewer extends StatefulWidget {
  const ChatImageViewer({
    super.key,
    required this.imageUrl,
    required this.storagePath,
    this.fileName,
  });

  final String imageUrl;

  /// Ruta en `chat-media`; sirve de clave de caché y para descargar el original.
  final String storagePath;

  final String? fileName;

  static Future<void> show(
    BuildContext context, {
    required String imageUrl,
    required String storagePath,
    String? fileName,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => ChatImageViewer(
          imageUrl: imageUrl,
          storagePath: storagePath,
          fileName: fileName,
        ),
      ),
    );
  }

  @override
  State<ChatImageViewer> createState() => _ChatImageViewerState();
}

class _ChatImageViewerState extends State<ChatImageViewer> {
  bool _isSaving = false;

  /// Descarga el original del bucket (no la versión cacheada, que puede estar
  /// redimensionada) y lo guarda en la galería del dispositivo.
  ///
  /// En web no hay galería y el plugin `gal` no está disponible, así que se
  /// abre la imagen en otra pestaña y es el navegador quien la descarga.
  Future<void> _saveToGallery() async {
    if (_isSaving) return;

    if (kIsWeb) {
      await launchUrl(
        Uri.parse(widget.imageUrl),
        webOnlyWindowName: '_blank',
      );
      return;
    }

    setState(() => _isSaving = true);

    final s = S.of(context);

    try {
      await getIt<ChatMediaService>().saveImageToGallery(
        storagePath: widget.storagePath,
        fileName: widget.fileName ?? widget.storagePath.split('/').last,
      );
      if (!mounted) return;
      _showMessage(s.chat_attachment_saved, AppColors.success);
    } on ChatMediaException catch (e) {
      if (!mounted) return;
      _showMessage(e.message, AppColors.error);
    } catch (_) {
      if (!mounted) return;
      _showMessage(s.chat_attachment_save_error, AppColors.error);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message, Color background) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: background,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isSaving ? null : _saveToGallery,
            tooltip: S.of(context).chat_attachment_save,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.gold,
                    ),
                  )
                : const Icon(Icons.download_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: CachedNetworkImage(
              imageUrl: widget.imageUrl,
              cacheKey: widget.storagePath,
              fit: BoxFit.contain,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.gold,
                ),
              ),
              errorWidget: (context, url, error) => const Icon(
                Icons.broken_image_outlined,
                color: AppColors.gray500,
                size: 48,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
