import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../l10n/app_localizations.dart';

/// Burbuja provisional que se muestra mientras un adjunto se sube al bucket.
///
/// La subida puede tardar varios segundos, así que se refleja en la lista para
/// que el usuario sepa que su archivo está en camino.
class AttachmentUploadingBubble extends StatelessWidget {
  const AttachmentUploadingBubble({
    super.key,
    required this.fileName,
    this.currentIndex = 1,
    this.total = 1,
  });

  final String fileName;

  /// Archivo en curso dentro del lote (1-based).
  final int currentIndex;

  /// Total de archivos del lote.
  final int total;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
        padding: const EdgeInsets.all(AppTheme.spacing12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: AppColors.goldWithAlpha50,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppTheme.radiusMedium),
            topRight: const Radius.circular(AppTheme.radiusMedium),
            bottomLeft: const Radius.circular(AppTheme.radiusMedium),
            bottomRight: const Radius.circular(0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.black,
              ),
            ),
            const SizedBox(width: AppTheme.spacing8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    total > 1
                        ? S
                            .of(context)
                            .chat_attachment_uploading_progress(
                              currentIndex,
                              total,
                            )
                        : S.of(context).chat_attachment_uploading,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.black,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.gray800,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
