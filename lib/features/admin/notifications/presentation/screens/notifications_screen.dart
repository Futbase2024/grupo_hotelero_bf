import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../l10n/app_localizations.dart';
import '../../../domain/bloc/admin_dashboard_bloc.dart';
import '../../../domain/bloc/admin_dashboard_event.dart';
import '../../../domain/bloc/admin_dashboard_state.dart';
import '../../../domain/entities/admin_entities.dart';

/// Pantalla de gestión de notificaciones del panel de administración
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cargar todas las notificaciones al entrar a la pantalla
    // Usamos didChangeDependencies porque aquí el contexto ya tiene acceso al bloc
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<AdminDashboardBloc>()
          .add(const AdminDashboardNotificationsLoadRequested());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.white,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          S.of(context).admin_notifications_title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
        actions: [
          BlocBuilder<AdminDashboardBloc, AdminDashboardState>(
            buildWhen: (prev, curr) =>
                prev.notifications.isNotEmpty != curr.notifications.isNotEmpty,
            builder: (context, state) {
              if (state.notifications.isEmpty) {
                return const SizedBox.shrink();
              }
              return TextButton(
                onPressed: () => _showDeleteAllDialog(context),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  S.of(context).admin_notifications_delete_all,
                  style: const TextStyle(
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
      body: BlocBuilder<AdminDashboardBloc, AdminDashboardState>(
        buildWhen: (prev, curr) =>
            prev.notifications != curr.notifications ||
            prev.unreadNotificationsCount != curr.unreadNotificationsCount,
        builder: (context, state) {
          if (state.notifications.isEmpty) {
            return const _EmptyNotificationsView();
          }

          return Column(
            children: [
              // Barra de acciones
              if (state.unreadNotificationsCount > 0)
                _ActionBanner(
                  unreadCount: state.unreadNotificationsCount,
                  onMarkAllRead: () {
                    context.read<AdminDashboardBloc>().add(
                          const AdminDashboardNotificationsMarkAllAsReadRequested(),
                        );
                  },
                ),
              // Lista de notificaciones
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: state.notifications.length,
                  itemBuilder: (context, index) {
                    final notification = state.notifications[index];
                    return _NotificationCard(
                      notification: notification,
                      onMarkAsRead: () {
                        context.read<AdminDashboardBloc>().add(
                              AdminDashboardNotificationMarkAsReadRequested(
                                notification.id,
                              ),
                            );
                      },
                      onDelete: () {
                        context.read<AdminDashboardBloc>().add(
                              AdminDashboardNotificationDeleteRequested(
                                notification.id,
                              ),
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
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
        title: Text(
          S.of(context).admin_notifications_delete_all_title,
          style: const TextStyle(color: AppColors.white),
        ),
        content: Text(
          S.of(context).admin_notifications_delete_all_confirm,
          style: const TextStyle(color: AppColors.gray400),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              S.of(context).common_cancel,
              style: const TextStyle(color: AppColors.gray400),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<AdminDashboardBloc>().add(
                    const AdminDashboardNotificationsDeleteAllRequested(),
                  );
            },
            style: TextButton.styleFrom(
              backgroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              S.of(context).admin_notifications_delete_all,
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

/// Banner de acciones cuando hay notificaciones no leídas
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
      decoration: const BoxDecoration(
        color: AppColors.goldWithAlpha20,
        border: Border(
          bottom: BorderSide(color: AppColors.goldWithAlpha30),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.mark_email_unread_outlined,
            color: AppColors.gold,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              S.of(context).admin_notifications_unread_count(unreadCount),
              style: const TextStyle(
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
              backgroundColor: AppColors.goldWithAlpha30,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              S.of(context).admin_notifications_mark_all_read,
              style: const TextStyle(
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

/// Vista vacía cuando no hay notificaciones
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
              color: AppColors.darkSurface,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.darkBorder,
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.notifications_none_outlined,
              size: 48,
              color: AppColors.gray500,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            S.of(context).admin_notifications_empty_title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            S.of(context).admin_notifications_empty_subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.gray400,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta individual de notificación
class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onMarkAsRead,
    required this.onDelete,
  });

  final StaffNotificationEntity notification;
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
        child: const Icon(
          Icons.delete_outline,
          color: AppColors.white,
          size: 24,
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.gold,
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: notification.read ? null : onMarkAsRead,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con tipo y título
                Row(
                  children: [
                    _NotificationTypeIcon(type: notification.type),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        notification.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: notification.read
                              ? FontWeight.w400
                              : FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    if (!notification.read)
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
                // Cuerpo del mensaje
                Text(
                  notification.body,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.gray400,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                // Footer con fecha y acciones
                Row(
                  children: [
                    Text(
                      dateFormat.format(notification.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.white,
                      ),
                    ),
                    const Spacer(),
                    if (!notification.read) ...[
                      _ActionButton(
                        icon: Icons.check,
                        label: S.of(context).admin_notifications_mark_read,
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

/// Icono según el tipo de notificación
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
      case 'checkin_submitted':
        return Icons.how_to_reg_outlined;
      case 'checkin_validated':
        return Icons.check_circle_outline;
      case 'checkin_rejected':
        return Icons.cancel_outlined;
      case 'checkout_requested':
        return Icons.logout_outlined;
      case 'message_received':
        return Icons.message_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }
}

/// Botón de acción pequeño
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
      // Botón destructivo: fondo blanco, texto e icono rojos
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
              const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
              const SizedBox(width: 4),
              Text(
                S.of(context).common_delete,
                style: const TextStyle(
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

    // Botón normal
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.gray400),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.gray400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
