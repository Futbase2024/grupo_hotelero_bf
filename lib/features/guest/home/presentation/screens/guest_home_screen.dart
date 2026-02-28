import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:bf_stay/core/di/injection.dart';
import 'package:bf_stay/core/theme/app_colors.dart';
import 'package:bf_stay/core/theme/app_theme.dart';
import 'package:bf_stay/core/theme/responsive.dart';
import 'package:bf_stay/features/auth/domain/bloc/auth_bloc.dart';
import 'package:bf_stay/features/admin/domain/entities/admin_booking_entity.dart';
import 'package:bf_stay/features/admin/domain/repositories/admin_panel_repository.dart';

/// Pantalla principal del huésped
class GuestHomeScreen extends StatelessWidget {
  const GuestHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;
        // Obtener estado del check-in
        final checkinStatus = user?.checkinStatus;
        final isCheckinValidated = checkinStatus == 'validated';
        final isCheckinSubmitted = checkinStatus == 'submitted';

        // Solo acceso completo cuando check-in está validado
        final canAccessFullPanel = isCheckinValidated;

        return Scaffold(
          backgroundColor: AppColors.getSurfaceColor(context),
          body: SafeArea(
            child: ResponsiveContent(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  vertical: context.responsive(mobile: AppTheme.spacing24, tablet: AppTheme.spacing32),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header con saludo
                    _buildHeader(context, user),
                    SizedBox(height: context.responsive(mobile: AppTheme.spacing24, tablet: AppTheme.spacing32)),

                    // Tu Estancia - con datos reales
                    _buildSectionTitle(context, 'Tu Estancia'),
                    const SizedBox(height: AppTheme.spacing16),
                    _StayInfoCard(bookingId: user?.bookingId),
                    SizedBox(height: context.responsive(mobile: AppTheme.spacing24, tablet: AppTheme.spacing32)),

                    // Status message basado en el estado
                    _buildStatusBanner(context, checkinStatus),
                    const SizedBox(height: AppTheme.spacing16),

                    // Quick actions
                    _buildSectionTitle(context, 'Acciones Rápidas'),
                    const SizedBox(height: AppTheme.spacing16),
                    _buildQuickActions(context, isCheckinValidated, isCheckinSubmitted, user?.bookingId),
                    SizedBox(height: context.responsive(mobile: AppTheme.spacing24, tablet: AppTheme.spacing32)),

                    // Services - Solo visibles después del check-in validado
                    if (canAccessFullPanel) ...[
                      _buildSectionTitle(context, 'Servicios'),
                      const SizedBox(height: AppTheme.spacing16),
                      _buildServicesGrid(context),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Banner de estado que muestra información según el estado del check-in
  Widget _buildStatusBanner(BuildContext context, String? checkinStatus) {
    final isDark = AppColors.isDarkMode(context);

    // Estado validado - Acceso completo
    if (checkinStatus == 'validated') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline, color: AppColors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡Bienvenido!',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tu estancia está activa. Disfruta de todos los servicios.',
                    style: TextStyle(
                      color: AppColors.getTextSecondaryColor(context),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Estado submitted - Pendiente de validación
    if (checkinStatus == 'submitted') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceWithAlpha40 : AppColors.gray200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gold, width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.info,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.hourglass_empty, color: AppColors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pendiente de validación',
                    style: TextStyle(
                      color: AppColors.info,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tu check-in ha sido enviado. Espera la validación del personal.',
                    style: TextStyle(
                      color: AppColors.getTextSecondaryColor(context),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Estado rejected - Rechazado
    if (checkinStatus == 'rejected') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, color: AppColors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Check-in rechazado',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Hay incidencias con tu check-in. Contacta con el personal.',
                    style: TextStyle(
                      color: AppColors.getTextSecondaryColor(context),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Estado por defecto - Check-in pendiente
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.warning,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.pending_actions, color: AppColors.black, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Check-in pendiente',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Completa tu check-in para acceder a todos los servicios.',
                  style: TextStyle(
                    color: AppColors.getTextSecondaryColor(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, user) {
    final avatarSize = context.responsive<double>(mobile: 48.0, tablet: 56.0);
    final fontSize = context.responsive<double>(mobile: 16.0, tablet: 20.0);

    return Row(
      children: [
        // Avatar
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            gradient: AppColors.goldGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          ),
          child: Center(
            child: Text(
              user?.initials ?? 'G',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spacing16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user?.displayName != null && user!.displayName.isNotEmpty
                    ? '¡Hola, ${user.displayName}!'
                    : '¡Bienvenido!',
                style: TextStyle(
                  fontSize: ResponsiveFontSize.titleLarge(context),
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextPrimaryColor(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Bienvenido a tu estancia',
                style: TextStyle(
                  fontSize: ResponsiveFontSize.bodyMedium(context),
                  color: AppColors.getTextSecondaryColor(context),
                ),
              ),
            ],
          ),
        ),
        // Logout button
        IconButton(
          onPressed: () {
            context.read<AuthBloc>().add(const AuthLogoutRequested());
          },
          icon: const Icon(Icons.logout_outlined),
          color: AppColors.getTextSecondaryColor(context),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: ResponsiveFontSize.titleMedium(context),
        fontWeight: FontWeight.w600,
        color: AppColors.getTextPrimaryColor(context),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isCheckinValidated, bool isCheckinSubmitted, String? bookingId) {
    // En tablet/desktop, mostrar más acciones en fila
    final isWide = context.isTablet || context.isDesktop;
    // Si está submitted, el check-in está deshabilitado (ya enviado)
    final canDoCheckin = !isCheckinSubmitted && !isCheckinValidated;

    if (isWide) {
      return Row(
        children: [
          Expanded(
            child: _QuickActionCard(
              icon: Icons.fact_check_outlined,
              title: 'Check-in',
              onTap: canDoCheckin && bookingId != null ? () => context.go('/guest/checkin/$bookingId') : null,
            ),
          ),
          const SizedBox(width: AppTheme.spacing16),
          Expanded(
            child: _QuickActionCard(
              icon: Icons.chat_bubble_outline,
              title: 'Chat',
              onTap: () => context.go('/guest/chat'),
            ),
          ),
          const SizedBox(width: AppTheme.spacing16),
          Expanded(
            child: _QuickActionCard(
              icon: Icons.lock_open_outlined,
              title: 'Access Box',
              onTap: isCheckinValidated ? () => context.go('/guest/access-box') : null,
            ),
          ),
          const SizedBox(width: AppTheme.spacing16),
          Expanded(
            child: _QuickActionCard(
              icon: Icons.book_outlined,
              title: 'Guía',
              onTap: isCheckinValidated ? () => context.go('/guest/guide') : null,
            ),
          ),
        ],
      );
    }

    // En móvil, mostrar en 2 columnas
    // Sin check-in: Check-in + Chat activos
    // Con check-in validado: Todos activos
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.fact_check_outlined,
                title: 'Check-in',
                onTap: canDoCheckin && bookingId != null ? () => context.go('/guest/checkin/$bookingId') : null,
              ),
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.chat_bubble_outline,
                title: 'Chat',
                onTap: () => context.go('/guest/chat'),
              ),
            ),
          ],
        ),
        if (isCheckinValidated) ...[
          const SizedBox(height: AppTheme.spacing12),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.lock_open_outlined,
                  title: 'Access Box',
                  onTap: () => context.go('/guest/access-box'),
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.book_outlined,
                  title: 'Guía',
                  onTap: () => context.go('/guest/guide'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildServicesGrid(BuildContext context) {
    final services = [
      _ServiceItem(
        icon: Icons.star_outline,
        title: 'Reseñas',
        route: '/guest/reviews/bf000000-0000-0000-0000-000000000001',
      ),
      _ServiceItem(
        icon: Icons.room_service_outlined,
        title: 'Servicios',
        route: null,
      ),
      _ServiceItem(
        icon: Icons.report_problem_outlined,
        title: 'Incidencias',
        route: null,
      ),
      _ServiceItem(
        icon: Icons.rule_outlined,
        title: 'Normas de la Casa',
        route: '/guest/house-rules/bf000000-0000-0000-0000-000000000001',
      ),
    ];

    return Column(
      children: services.map((service) => Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
        child: _ServiceListTile(
          icon: service.icon,
          title: service.title,
          onTap: service.route != null
              ? () => context.go(service.route!)
              : null,
        ),
      )).toList(),
    );
  }
}

/// Widget para mostrar la información de la estancia con datos reales
class _StayInfoCard extends StatefulWidget {
  const _StayInfoCard({required this.bookingId});

  final String? bookingId;

  @override
  State<_StayInfoCard> createState() => _StayInfoCardState();
}

class _StayInfoCardState extends State<_StayInfoCard> {
  AdminBookingEntity? _booking;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    if (widget.bookingId == null) {
      setState(() {
        _isLoading = false;
        _error = 'No hay reserva asociada';
      });
      return;
    }

    try {
      final repository = getIt<AdminPanelRepository>();
      final booking = await repository.getBooking(widget.bookingId!);

      if (mounted) {
        setState(() {
          _booking = booking;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar la reserva';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.getCardColor(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: AppColors.getBorderColor(context)),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.gold,
            ),
          ),
        ),
      );
    }

    if (_error != null || _booking == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.getCardColor(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: AppColors.getBorderColor(context)),
        ),
        child: Center(
          child: Text(
            _error ?? 'No hay información de reserva',
            style: TextStyle(
              color: AppColors.getTextSecondaryColor(context),
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    final booking = _booking!;
    final dateFormat = DateFormat('d MMM');
    final checkInStr = dateFormat.format(booking.checkInDate);
    final checkOutStr = dateFormat.format(booking.checkOutDate);
    final nights = booking.stayDurationNights;

    return Container(
      padding: EdgeInsets.all(context.responsive(mobile: AppTheme.spacing16, tablet: AppTheme.spacing24)),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppColors.getBorderColor(context)),
        boxShadow: context.isDesktop
            ? [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          // Header con nombre de unidad y propiedad
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.home_outlined,
                  color: AppColors.black,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.unitName.isNotEmpty ? booking.unitName : 'Alojamiento',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getTextPrimaryColor(context),
                      ),
                    ),
                    Text(
                      booking.propertyName.isNotEmpty ? booking.propertyName : 'BF Stay',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.getTextSecondaryColor(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Divider(height: AppTheme.spacing24, color: AppColors.getBorderColor(context)),
          // Info items: Check-in, Check-out, Noches, Huéspedes
          Row(
            children: [
              Expanded(
                child: _StayInfoItem(
                  icon: Icons.login,
                  label: 'Check-in',
                  value: checkInStr,
                ),
              ),
              Expanded(
                child: _StayInfoItem(
                  icon: Icons.logout,
                  label: 'Check-out',
                  value: checkOutStr,
                ),
              ),
              Expanded(
                child: _StayInfoItem(
                  icon: Icons.bed_outlined,
                  label: 'Noches',
                  value: '$nights',
                ),
              ),
              Expanded(
                child: _StayInfoItem(
                  icon: Icons.people_outline,
                  label: 'Huéspedes',
                  value: '${booking.numGuests}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Widget para cada item de información de estancia
class _StayInfoItem extends StatelessWidget {
  const _StayInfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.getTextPrimaryColor(context),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.getTextSecondaryColor(context),
          ),
        ),
      ],
    );
  }
}

class _ServiceItem {
  const _ServiceItem({
    required this.icon,
    required this.title,
    this.route,
  });

  final IconData icon;
  final String title;
  final String? route;
}

class _ServiceListTile extends StatelessWidget {
  const _ServiceListTile({
    required this.icon,
    required this.title,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: AppColors.getCardColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: BorderSide(color: AppColors.getBorderColor(context)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.black, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: AppColors.getTextPrimaryColor(context),
          ),
        ),
        trailing: onTap != null
            ? Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.getTextSecondaryColor(context))
            : null,
        enabled: onTap != null,
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final padding = context.responsive(
      mobile: AppTheme.spacing16,
      tablet: AppTheme.spacing20,
    );
    final iconSize = context.responsive(mobile: 28.0, tablet: 32.0);
    final isEnabled = onTap != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: AppColors.getCardColor(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: isEnabled ? AppColors.gold : AppColors.getBorderColor(context),
            width: isEnabled ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: AppColors.black,
                size: iconSize,
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              title,
              style: TextStyle(
                fontSize: ResponsiveFontSize.labelLarge(context),
                color: isEnabled ? AppColors.getTextPrimaryColor(context) : AppColors.getTextSecondaryColor(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
