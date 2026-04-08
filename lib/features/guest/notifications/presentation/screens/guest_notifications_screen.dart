import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../home/domain/bloc/guest_home_bloc.dart';
import '../../../home/domain/bloc/guest_home_event.dart';
import '../../../home/domain/bloc/guest_home_state.dart';
import '../../../home/domain/entities/guest_notification_entity.dart';

/// Pantalla de notificaciones del huesped
class GuestNotificationsScreen extends StatefulWidget {
  const GuestNotificationsScreen({super.key});

  @override
  State<GuestNotificationsScreen> createState() => _GuestNotificationsScreenState();
}

class _GuestNotificationsScreenState extends State<GuestNotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return Scaffold(
      backgroundColor: AppColors.getSurfaceColor(context),
      appBar: AppBar(
        backgroundColor: AppColors.getSurfaceColor(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.getTextPrimaryColor(context),
            size: 20,
          ),
          onPressed: () => context.go('/guest'),
        ),
        title: Text(
          S.of(context).guest_notifications_title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.getTextPrimaryColor(context),
          ),
        ),
        actions: [
          BlocBuilder<GuestHomeBloc, GuestHomeState>(
            buildWhen: (prev, curr) {
              if (prev is GuestHomeLoaded && curr is GuestHomeLoaded) {
                return prev.notifications.isNotEmpty != curr.notifications.isNotEmpty;
              }
              return true;
            },
            builder: (context, state) {
              final notifications = state is GuestHomeLoaded ? state.notifications : <GuestNotificationEntity>[];
              if (notifications.isEmpty) {
                return const SizedBox.shrink();
              }
              return TextButton(
                onPressed: () => _showDeleteAllDialog(context),
                style: TextButton.styleFrom(
                  backgroundColor: isDark ? AppColors.white : AppColors.blackWithAlpha05,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  S.of(context).guest_notifications_delete_all,
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<GuestHomeBloc, GuestHomeState>(
        buildWhen: (prev, curr) {
          if (prev is GuestHomeLoaded && curr is GuestHomeLoaded) {
            return prev.notifications != curr.notifications ||
                prev.unreadNotificationsCount != curr.unreadNotificationsCount;
          }
          return true;
        },
        builder: (context, state) {
          final notifications = state is GuestHomeLoaded ? state.notifications : <GuestNotificationEntity>[];
          final unreadCount = state is GuestHomeLoaded ? state.unreadNotificationsCount : 0;

          if (notifications.isEmpty) {
            return const _EmptyNotificationsView();
          }

          return Column(
            children: [
              if (unreadCount > 0)
                _ActionBanner(
                  unreadCount: unreadCount,
                  onMarkAllRead: () {
                    context.read<GuestHomeBloc>().add(
                          const GuestHomeNotificationsMarkAllAsRead(),
                        );
                  },
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return _NotificationCard(
                      notification: notification,
                      onMarkAsRead: () {
                        context.read<GuestHomeBloc>().add(
                              GuestHomeNotificationMarkAsRead(notification.id),
                            );
                      },
                      onDelete: () {
                        context.read<GuestHomeBloc>().add(
                              GuestHomeNotificationDelete(notification.id),
                            );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteAllDialog(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.getCardColor(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.getBorderColor(context)),
        ),
        title: Text(
          S.of(context).guest_notifications_delete_all_title,
          style: TextStyle(color: AppColors.getTextPrimaryColor(context)),
        ),
        content: Text(
          S.of(context).guest_notifications_delete_all_confirm,
          style: TextStyle(color: AppColors.getTextSecondaryColor(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              S.of(context).common_cancel,
              style: TextStyle(color: AppColors.getTextSecondaryColor(context)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<GuestHomeBloc>().add(
                    const GuestHomeNotificationsDeleteAll(),
                  );
            },
            style: TextButton.styleFrom(
              backgroundColor: isDark ? AppColors.white : AppColors.blackWithAlpha05,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              S.of(context).guest_notifications_delete_all,
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner de acciones cuando hay notificaciones no leidas
class _ActionBanner extends StatelessWidget {
  const _ActionBanner({
    required this.unreadCount,
    required this.onMarkAllRead,
  });

  final int unreadCount;
  final VoidCallback onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.getGoldWithAlpha(context, alpha: 0.1),
        border: Border(
          bottom: BorderSide(color: AppColors.getGoldWithAlpha(context, alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.mark_email_unread_outlined,
            color: AppColors.gold,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              S.of(context).guest_notifications_unread_count(unreadCount),
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: onMarkAllRead,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              backgroundColor: AppColors.getGoldWithAlpha(context, alpha: 0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              S.of(context).guest_notifications_mark_all,
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Vista vacia cuando no hay notificaciones
class _EmptyNotificationsView extends StatelessWidget {
  const _EmptyNotificationsView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.getCardColor(context),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.getBorderColor(context),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.notifications_none_outlined,
              size: 48,
              color: AppColors.getTextSecondaryColor(context),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            S.of(context).guest_notifications_empty_title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            S.of(context).guest_notifications_empty_subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.getTextSecondaryColor(context),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta individual de notificacion
class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onMarkAsRead,
    required this.onDelete,
  });

  final GuestNotificationEntity notification;
  final VoidCallback onMarkAsRead;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: Icon(
          Icons.delete_outline,
          color: AppColors.white,
          size: 24,
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.getCardColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.gold,
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: notification.isRead ? null : onMarkAsRead,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _NotificationTypeIcon(type: notification.type),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        notification.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: notification.isRead
                              ? FontWeight.w400
                              : FontWeight.w600,
                          color: AppColors.getTextPrimaryColor(context),
                        ),
                      ),
                    ),
                    if (!notification.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  notification.body,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.getTextSecondaryColor(context),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      dateFormat.format(notification.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.getTextSecondaryColor(context),
                      ),
                    ),
                    const Spacer(),
                    if (!notification.isRead) ...[
                      _ActionButton(
                        icon: Icons.check,
                        label: S.of(context).guest_notifications_read,
                        onTap: onMarkAsRead,
                      ),
                      const SizedBox(width: 8),
                    ],
                    _ActionButton(
                      icon: Icons.delete_outline,
                      label: S.of(context).common_delete,
                      onTap: onDelete,
                      isDestructive: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Icono segun el tipo de notificacion
class _NotificationTypeIcon extends StatelessWidget {
  const _NotificationTypeIcon({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final iconData = _getIcon();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.gold,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        size: 18,
        color: AppColors.black,
      ),
    );
  }

  IconData _getIcon() {
    switch (type) {
      case 'checkin_validated':
        return Icons.check_circle_outline;
      case 'checkin_rejected':
        return Icons.cancel_outlined;
      case 'booking_cancelled':
        return Icons.block;
      case 'checkin_status_update':
        return Icons.update;
      default:
        return Icons.notifications_outlined;
    }
  }
}

/// Boton de accion pequeno
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    if (isDestructive) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_outline, size: 16, color: AppColors.error),
              const SizedBox(width: 4),
              Text(
                S.of(context).common_delete,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.getTextSecondaryColor(context)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.getTextSecondaryColor(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
