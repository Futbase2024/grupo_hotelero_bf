import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../data/repositories/translation_repository.dart';
import '../../data/services/chat_media_service.dart';
import '../../domain/entities/message_entity.dart';
import '../screens/chat_image_viewer.dart';

/// Widget que muestra una burbuja de mensaje en el chat.
///
/// Si el mensaje es de texto, muestra un botón «Traducir» que invoca la Edge
/// Function `translate-message` (vía [TranslationRepository]) y pinta la
/// traducción bajo el original. La traducción se cachea en memoria y se
/// restaura al reciclar la burbuja (scroll).
class MessageBubble extends StatefulWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isFromMe,
    this.onDelete,
  });

  final MessageEntity message;
  final bool isFromMe;

  /// Callback opcional para eliminar el mensaje. Solo se ofrece la acción
  /// (mantener pulsado) cuando el mensaje es propio y este callback existe.
  final VoidCallback? onDelete;

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  String? _translation;
  bool _isTranslating = false;
  bool _showTranslation = true;

  /// URL firmada del adjunto, resuelta bajo demanda.
  String? _attachmentUrl;
  bool _attachmentFailed = false;

  MessageEntity get message => widget.message;
  bool get isFromMe => widget.isFromMe;

  /// Indica si se puede eliminar este mensaje (propio + callback disponible).
  bool get _canDelete => isFromMe && widget.onDelete != null;

  @override
  void initState() {
    super.initState();
    // Restaura la traducción cacheada al reciclar la burbuja (scroll).
    _translation = getIt<TranslationRepository>().getCached(message.id);

    if (message.hasAttachment) {
      _resolveAttachmentUrl();
    }
  }

  /// En `content` se guarda el storage path; la URL firmada se pide aparte
  /// (y el servicio la cachea en memoria para el resto de la sesión).
  Future<void> _resolveAttachmentUrl() async {
    final path = message.attachmentPath;
    if (path == null || path.isEmpty) {
      setState(() => _attachmentFailed = true);
      return;
    }

    try {
      final url = await getIt<ChatMediaService>().resolveUrl(path);
      if (!mounted) return;
      setState(() => _attachmentUrl = url);
    } catch (_) {
      if (!mounted) return;
      setState(() => _attachmentFailed = true);
    }
  }

  Future<void> _openAttachment() async {
    final url = _attachmentUrl;
    if (url == null) return;

    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );

    if (!opened && mounted) {
      _showError(S.of(context).chat_attachment_open_error);
    }
  }

  void _openImageViewer() {
    final url = _attachmentUrl;
    final path = message.attachmentPath;
    if (url == null || path == null) return;

    ChatImageViewer.show(
      context,
      imageUrl: url,
      storagePath: path,
      fileName: message.fileName,
    );
  }

  Future<void> _onTranslate() async {
    if (_translation != null) {
      setState(() => _showTranslation = !_showTranslation);
      return;
    }
    setState(() => _isTranslating = true);
    try {
      final result = await getIt<TranslationRepository>().translate(
        messageId: message.id,
        text: message.content,
      );
      if (!mounted) return;
      setState(() {
        _translation = result.translatedText;
        _showTranslation = true;
        _isTranslating = false;
      });
    } on TranslationException catch (e) {
      if (!mounted) return;
      setState(() => _isTranslating = false);
      _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isTranslating = false);
      _showError('No se pudo traducir el mensaje');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alignment =
        isFromMe ? Alignment.centerRight : Alignment.centerLeft;

    return Align(
      alignment: alignment,
      child: GestureDetector(
        onLongPress: _canDelete ? () => widget.onDelete!() : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
          padding: const EdgeInsets.all(AppTheme.spacing12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
        decoration: BoxDecoration(
          color: isFromMe ? AppColors.gold : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppTheme.radiusMedium),
            topRight: const Radius.circular(AppTheme.radiusMedium),
            bottomLeft: isFromMe
                ? const Radius.circular(AppTheme.radiusMedium)
                : const Radius.circular(0),
            bottomRight: isFromMe
                ? const Radius.circular(0)
                : const Radius.circular(AppTheme.radiusMedium),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mostrar nombre del remitente si no es mi mensaje
            if (!isFromMe) _buildSenderName(context),
            if (message.isImage) ...[
              _buildImageContent(context),
            ] else if (message.isFile) ...[
              _buildFileContent(context),
            ] else ...[
              _buildTextContent(context),
            ],
            const SizedBox(height: 4),
            _buildTimeLabel(context),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message.content,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.black,
              ),
        ),
        if (_translation != null && _showTranslation) ...[
          const SizedBox(height: 4),
          Divider(height: 1, thickness: 1, color: AppColors.blackWithAlpha20),
          const SizedBox(height: 4),
          Text(
            _translation!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.gray700,
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
        if (message.isText && message.content.trim().isNotEmpty)
          _buildTranslateAction(context),
      ],
    );
  }

  /// Botón/spinner de traducción bajo el texto.
  Widget _buildTranslateAction(BuildContext context) {
    // Ya traducido: toggle mostrar/ocultar.
    if (_translation != null) {
      return _translateButton(
        context,
        label: _showTranslation ? 'Ocultar traducción' : 'Mostrar traducción',
        onTap: () => setState(() => _showTranslation = !_showTranslation),
      );
    }
    // Cargando.
    if (_isTranslating) {
      return Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Traduciendo…',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.gray700,
                  ),
            ),
          ],
        ),
      );
    }
    // Acción inicial.
    return _translateButton(
      context,
      label: 'Traducir',
      icon: Icons.translate,
      onTap: _onTranslate,
    );
  }

  Widget _translateButton(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return TextButton.icon(
      onPressed: onTap,
      icon: icon != null
          ? Icon(icon, size: 16, color: AppColors.gray700)
          : const SizedBox.shrink(),
      label: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.gray700,
              fontWeight: FontWeight.w600,
            ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.only(top: 2),
        minimumSize: const Size(0, 28),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        alignment: Alignment.centerLeft,
      ),
    );
  }

  Widget _buildSenderName(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        message.displaySenderName,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: message.isFromStaff ? AppColors.gold : AppColors.gray600,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildImageContent(BuildContext context) {
    if (_attachmentFailed) return const _AttachmentThumbnailError();

    final url = _attachmentUrl;
    if (url == null) return const _AttachmentThumbnailLoading();

    return GestureDetector(
      onTap: _openImageViewer,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        child: CachedNetworkImage(
          imageUrl: url,
          // La URL firmada caduca; el path es la identidad estable del archivo.
          cacheKey: message.attachmentPath,
          fit: BoxFit.cover,
          width: 200,
          height: 150,
          errorWidget: (context, url, error) =>
              const _AttachmentThumbnailError(),
          placeholder: (context, url) => const _AttachmentThumbnailLoading(),
        ),
      ),
    );
  }

  /// Tarjeta de documento adjunto: icono por tipo, nombre y tamaño.
  Widget _buildFileContent(BuildContext context) {
    final isReady = _attachmentUrl != null && !_attachmentFailed;

    return GestureDetector(
      onTap: isReady ? _openAttachment : null,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(AppTheme.spacing8),
        decoration: BoxDecoration(
          color: AppColors.blackWithAlpha05,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.blackWithAlpha20,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Icon(
                _fileIcon(message.mimeType),
                color: AppColors.black,
                size: 20,
              ),
            ),
            const SizedBox(width: AppTheme.spacing8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.displayFileName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.black,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (message.fileSizeFormatted.isNotEmpty)
                    Text(
                      message.fileSizeFormatted,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.gray700,
                          ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.spacing4),
            if (isReady)
              const Icon(
                Icons.download_rounded,
                size: 18,
                color: AppColors.gray700,
              )
            else if (_attachmentFailed)
              const Icon(
                Icons.error_outline,
                size: 18,
                color: AppColors.error,
              )
            else
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.gold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Icono representativo según el MIME type del adjunto.
  IconData _fileIcon(String? mimeType) {
    final mime = mimeType ?? '';
    if (mime == 'application/pdf') return Icons.picture_as_pdf_outlined;
    if (mime.contains('word')) return Icons.article_outlined;
    if (mime.contains('sheet') || mime.contains('excel')) {
      return Icons.table_chart_outlined;
    }
    if (mime.startsWith('text/')) return Icons.description_outlined;
    return Icons.insert_drive_file_outlined;
  }

  Widget _buildTimeLabel(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message.formattedTime,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.black.withValues(alpha: 0.7),
                fontSize: 10,
              ),
        ),
        if (isFromMe) ...[
          const SizedBox(width: 4),
          _buildReadIndicator(context),
        ],
      ],
    );
  }

  /// Indicador visual de lectura (✓✓)
  Widget _buildReadIndicator(BuildContext context) {
    final isRead = message.isRead;

    return Icon(
      isRead ? Icons.done_all : Icons.done,
      size: 14,
      color: isRead
          ? AppColors.success
          : AppColors.black.withValues(alpha: 0.5),
    );
  }
}

/// Marco del thumbnail mientras se resuelve o descarga la imagen.
class _AttachmentThumbnailLoading extends StatelessWidget {
  const _AttachmentThumbnailLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 150,
      decoration: BoxDecoration(
        color: AppColors.blackWithAlpha05,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.gold,
        ),
      ),
    );
  }
}

/// Marco del thumbnail cuando la imagen no se puede mostrar.
class _AttachmentThumbnailError extends StatelessWidget {
  const _AttachmentThumbnailError();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 150,
      decoration: BoxDecoration(
        color: AppColors.blackWithAlpha20,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: const Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: AppColors.gray500,
        ),
      ),
    );
  }
}

/// Widget para mostrar un indicador de "escribiendo..."
class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing16,
          vertical: AppTheme.spacing12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(0),
            const SizedBox(width: 4),
            _buildDot(1),
            const SizedBox(width: 4),
            _buildDot(2),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 150)),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: value),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
