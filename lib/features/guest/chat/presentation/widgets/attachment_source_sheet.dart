import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../l10n/app_localizations.dart';

/// Origen del adjunto elegido por el usuario.
enum AttachmentSource { camera, gallery, document }

/// Hoja inferior para elegir el origen de un adjunto del chat.
///
/// Devuelve el [AttachmentSource] elegido, o `null` si se descarta.
class AttachmentSourceSheet extends StatelessWidget {
  const AttachmentSourceSheet({super.key});

  static Future<AttachmentSource?> show(BuildContext context) {
    return showModalBottomSheet<AttachmentSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const AttachmentSourceSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    // El fondo lo pinta un Material, no un Container decorado: los ListTile de
    // dentro dibujan su color y su ripple sobre el Material más cercano, y una
    // caja con color por medio los taparía (Flutter lo avisa con un assert).
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing12),
        child: Material(
          color: AppColors.getCardColor(context),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
            side: BorderSide(color: AppColors.getBorderColor(context)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppTheme.spacing8),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing20,
                  vertical: AppTheme.spacing12,
                ),
                child: Row(
                  children: [
                    Text(
                      s.chat_attach_title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.getTextPrimaryColor(context),
                          ),
                    ),
                  ],
                ),
              ),
              _AttachmentOption(
                icon: Icons.photo_camera_outlined,
                label: s.chat_attach_camera,
                source: AttachmentSource.camera,
              ),
              _AttachmentOption(
                icon: Icons.photo_library_outlined,
                label: s.chat_attach_gallery,
                source: AttachmentSource.gallery,
              ),
              _AttachmentOption(
                icon: Icons.description_outlined,
                label: s.chat_attach_document,
                source: AttachmentSource.document,
              ),
              const SizedBox(height: AppTheme.spacing8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Una fila del selector de origen.
class _AttachmentOption extends StatelessWidget {
  const _AttachmentOption({
    required this.icon,
    required this.label,
    required this.source,
  });

  final IconData icon;
  final String label;
  final AttachmentSource source;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.goldWithAlpha20,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.gold, size: 20),
      ),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.getTextPrimaryColor(context),
              fontWeight: FontWeight.w500,
            ),
      ),
      onTap: () => Navigator.of(context).pop(source),
    );
  }
}
