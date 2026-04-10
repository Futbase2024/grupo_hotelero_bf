import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../domain/entities/message_entity.dart';

/// Widget que muestra una burbuja de mensaje en el chat
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isFromMe,
  });

  final MessageEntity message;
  final bool isFromMe;

  @override
  Widget build(BuildContext context) {
    final alignment =
        isFromMe ? Alignment.centerRight : Alignment.centerLeft;

    return Align(
      alignment: alignment,
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
    );
  }

  Widget _buildTextContent(BuildContext context) {
    return Text(
      message.content,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.black,
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
