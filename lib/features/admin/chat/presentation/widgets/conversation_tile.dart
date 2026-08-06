import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../guest/chat/domain/entities/conversation_entity.dart';
import 'conversation_preview_thumbnail.dart';

/// Widget que muestra una conversación en la lista con swipe-to-delete y long-press menu
class ConversationTile extends StatelessWidget {
  const ConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
    required this.onDelete,
  });

  final ConversationEntity conversation;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(conversation.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async => _confirmDelete(context),
      onDismissed: (direction) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppTheme.spacing20),
        color: AppColors.error,
        child: const Icon(
          Icons.delete_outline,
          color: AppColors.white,
          size: 28,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: () => _showContextMenu(context),
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final guestParticipant = conversation.guestParticipant;

    // Usar el nuevo getter que muestra nombre + código de reserva
    final displayName = conversation.displayNameForAdmin;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: AppTheme.spacing12,
      ),
      decoration: BoxDecoration(
        color: conversation.hasUnread
            ? AppColors.goldWithAlpha10
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: AppColors.blackWithAlpha20,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          _buildAvatar(guestParticipant),
          const SizedBox(width: AppTheme.spacing12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre y hora
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        displayName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: conversation.hasUnread
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (conversation.hasMessages)
                      Text(
                        conversation.lastMessageTimeAgo,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.gray500,
                              fontSize: 11,
                            ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                // Último mensaje
                Row(
                  children: [
                    if (conversation.lastMessage?.isImage ?? false)
                      ConversationPreviewThumbnail(
                        storagePath: conversation.lastMessage!.content,
                      ),
                    Expanded(
                      child: Text(
                        conversation.lastMessagePreview,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: conversation.hasUnread
                                  ? AppColors.white
                                  : AppColors.gray500,
                              fontWeight: conversation.hasUnread
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                            ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    // Badge de no leídos
                    if (conversation.hasUnread) ...[
                      const SizedBox(width: AppTheme.spacing8),
                      _buildUnreadBadge(context),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(ParticipantEntity? guestParticipant) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.goldWithAlpha20,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          guestParticipant?.initials ?? '?',
          style: const TextStyle(
            color: AppColors.gold,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildUnreadBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.gold,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        conversation.unreadCount > 99
            ? '99+'
            : conversation.unreadCount.toString(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.black,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  /// Muestra diálogo de confirmación antes de eliminar
  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        title: const Text(
          'Eliminar conversación',
          style: TextStyle(color: AppColors.white),
        ),
        content: Text(
          '¿Estás seguro de que quieres eliminar la conversación con '
          '${conversation.displayNameForAdmin}?\n\n'
          'Se eliminarán todos los mensajes y no se podrá recuperar.',
          style: const TextStyle(color: AppColors.gray300),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.gray400),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Muestra menú contextual al mantener pulsado
  void _showContextMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLarge),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: AppTheme.spacing12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
              child: Text(
                conversation.displayNameForAdmin,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            // Opciones
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.goldWithAlpha20,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  color: AppColors.gold,
                ),
              ),
              title: const Text('Abrir conversación'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                onTap();
              },
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                ),
              ),
              title: const Text(
                'Eliminar conversación',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                final confirmed = await _confirmDelete(context);
                if (confirmed) {
                  onDelete();
                }
              },
            ),
            const SizedBox(height: AppTheme.spacing16),
          ],
        ),
      ),
    );
  }
}
