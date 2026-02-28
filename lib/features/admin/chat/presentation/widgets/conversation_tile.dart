import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../guest/chat/domain/entities/conversation_entity.dart';

/// Widget que muestra una conversación en la lista
class ConversationTile extends StatelessWidget {
  const ConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  final ConversationEntity conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final guestParticipant = conversation.guestParticipant;

    return InkWell(
      onTap: onTap,
      child: Container(
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
                          guestParticipant?.displayName ?? 'Huésped',
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
}
