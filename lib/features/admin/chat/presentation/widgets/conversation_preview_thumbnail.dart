import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/image_decode_size.dart';
import '../../../../guest/chat/data/services/chat_media_service.dart';

/// Miniatura del último mensaje cuando este es una imagen.
///
/// Se muestra junto al texto de vista previa en la lista de conversaciones.
/// Mientras se resuelve la URL firmada ocupa su hueco con un marco neutro, para
/// que la fila no dé saltos al cargar.
class ConversationPreviewThumbnail extends StatefulWidget {
  const ConversationPreviewThumbnail({super.key, required this.storagePath});

  /// Ruta del objeto en `chat-media`.
  final String storagePath;

  static const double size = 28;

  @override
  State<ConversationPreviewThumbnail> createState() =>
      _ConversationPreviewThumbnailState();
}

class _ConversationPreviewThumbnailState
    extends State<ConversationPreviewThumbnail> {
  String? _url;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(ConversationPreviewThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    // La lista se refresca en tiempo real: si llega otra imagen, recargar.
    if (oldWidget.storagePath != widget.storagePath) {
      _url = null;
      _failed = false;
      _resolve();
    }
  }

  Future<void> _resolve() async {
    final path = widget.storagePath;
    if (path.isEmpty) {
      setState(() => _failed = true);
      return;
    }

    try {
      final url = await getIt<ChatMediaService>().resolveUrl(path);
      if (!mounted || path != widget.storagePath) return;
      setState(() => _url = url);
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    const size = ConversationPreviewThumbnail.size;
    final url = _url;

    return Padding(
      padding: const EdgeInsets.only(right: AppTheme.spacing8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        child: SizedBox(
          width: size,
          height: size,
          child: url == null || _failed
              ? Container(
                  color: AppColors.whiteWithAlpha10,
                  child: Icon(
                    _failed ? Icons.broken_image_outlined : Icons.image_outlined,
                    size: 14,
                    color: AppColors.gray500,
                  ),
                )
              : CachedNetworkImage(
                  imageUrl: url,
                  cacheKey: widget.storagePath,
                  fit: BoxFit.cover,
                  // Miniatura de lista: decodificar al tamaño real evita mantener la foto
                  // completa en memoria por cada conversación visible.
                  memCacheWidth: ImageDecodeSize.forLogical(context, size),
                  memCacheHeight: ImageDecodeSize.forLogical(context, size),
                  errorWidget: (context, _, __) => Container(
                    color: AppColors.whiteWithAlpha10,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      size: 14,
                      color: AppColors.gray500,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
