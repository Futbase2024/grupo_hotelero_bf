import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../data/repositories/translation_repository.dart';
import '../../domain/entities/message_entity.dart';

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

  MessageEntity get message => widget.message;
  bool get isFromMe => widget.isFromMe;

  /// Indica si se puede eliminar este mensaje (propio + callback disponible).
  bool get _canDelete => isFromMe && widget.onDelete != null;

  @override
  void initState() {
    super.initState();
    // Restaura la traducción cacheada al reciclar la burbuja (scroll).
    _translation = getIt<TranslationRepository>().getCached(message.id);
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      child: CachedNetworkImage(
        imageUrl: message.content,
        fit: BoxFit.cover,
        width: 200,
        height: 150,
        errorWidget: (context, url, error) => Container(
          width: 200,
          height: 150,
          color: AppColors.blackWithAlpha20,
          child: const Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: AppColors.gray500,
            ),
          ),
        ),
        placeholder: (context, url) => Container(
          width: 200,
          height: 150,
          color: AppColors.blackWithAlpha05,
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.gold,
            ),
          ),
        ),
      ),
    );
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
