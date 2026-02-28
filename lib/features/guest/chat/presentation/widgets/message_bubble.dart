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

  Widget _buildImageContent(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      child: Image.network(
        message.content,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 200,
            height: 150,
            color: AppColors.blackWithAlpha20,
            child: const Center(
              child: Icon(
                Icons.broken_image_outlined,
                color: AppColors.gray500,
              ),
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 200,
            height: 150,
            color: AppColors.blackWithAlpha05,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
                color: AppColors.gold,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeLabel(BuildContext context) {
    return Text(
      message.formattedTime,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.black.withValues(alpha: 0.7),
            fontSize: 10,
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
