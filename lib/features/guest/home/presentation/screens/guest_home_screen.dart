import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:bf_stay/core/di/injection.dart';
import 'package:bf_stay/core/theme/app_colors.dart';
import 'package:bf_stay/core/theme/app_theme.dart';
import 'package:bf_stay/core/theme/responsive.dart';
import 'package:bf_stay/features/auth/domain/bloc/auth_bloc.dart';
import 'package:bf_stay/features/admin/domain/repositories/admin_panel_repository.dart';
import 'package:bf_stay/features/guest/alojamientos/domain/entities/unit_entity.dart';
import 'package:bf_stay/shared/utils/unit_image_helper.dart';
import 'package:bf_stay/shared/widgets/logout_confirmation_dialog.dart';
import 'package:bf_stay/shared/widgets/exit_confirmation_dialog.dart';
import '../../domain/bloc/guest_home_bloc.dart';
import '../../domain/bloc/guest_home_event.dart';
import '../../domain/bloc/guest_home_state.dart';

/// Pantalla principal del huésped
class GuestHomeScreen extends StatelessWidget {
  const GuestHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        // Mientras carga la autenticación, mostrar loading
        if (state is AuthLoading || state is AuthInitial) {
          return Scaffold(
            backgroundColor: AppColors.getSurfaceColor(context),
            body: SafeArea(
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.gold,
                ),
              ),
            ),
          );
        }

        final user = state is AuthAuthenticated ? state.user : null;
        debugPrint('🏠 [GuestHomeScreen] AuthState: ${state.runtimeType}, user?.bookingId: "${user?.bookingId}"');

        // Si no hay usuario autenticado, no mostrar nada (debería redirigir a login)
        if (user == null) {
          return Scaffold(
            backgroundColor: AppColors.getSurfaceColor(context),
            body: SafeArea(
              child: Center(
                child: Text('No autenticado'),
              ),
            ),
          );
        }

        // Obtener estado del check-in
        final checkinStatus = user.checkinStatus;
        final checkinRejectionReason = user.checkinRejectionReason;
        final isCheckinValidated = checkinStatus == 'validated';
        final isCheckinSubmitted = checkinStatus == 'submitted';

        return BlocProvider(
          create: (context) => GuestHomeBloc(
            repository: getIt<AdminPanelRepository>(),
          )
            ..add(GuestHomeLoadBooking(user.bookingId ?? ''))
            ..add(GuestHomeLoadNotifications(user.id)),
          child: PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;
              await ExitConfirmationDialog.show(context);
            },
            child: Scaffold(
            backgroundColor: AppColors.getSurfaceColor(context),
            body: SafeArea(
              child: ResponsiveContent(
                child: Builder(
                  builder: (innerContext) {
                    return RefreshIndicator(
                      onRefresh: () async {
                        final bookingId = user.bookingId;
                        if (bookingId == null || bookingId.isEmpty) return;

                        // Refrescar datos de la reserva y estado del usuario
                        innerContext.read<GuestHomeBloc>().add(GuestHomeRefreshBooking(bookingId));
                        innerContext.read<AuthBloc>().add(const AuthCheckRequested());
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                          vertical: innerContext.responsive(mobile: AppTheme.spacing24, tablet: AppTheme.spacing32),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header con saludo
                            _buildHeader(innerContext, user),
                            SizedBox(height: innerContext.responsive(mobile: AppTheme.spacing24, tablet: AppTheme.spacing32)),

                            // Tu Estancia - con datos reales del BLoC
                            _buildSectionTitle(innerContext, 'Tu Estancia'),
                            const SizedBox(height: AppTheme.spacing16),
                            const _StayInfoCard(),
                            SizedBox(height: innerContext.responsive(mobile: AppTheme.spacing24, tablet: AppTheme.spacing32)),

                            // Status message basado en el estado - Solo si NO está validado
                            if (!isCheckinValidated) ...[
                              _buildStatusBanner(innerContext, checkinStatus, checkinRejectionReason, user.checkinCancellationReason),
                              const SizedBox(height: AppTheme.spacing16),
                            ],

                            // Quick actions
                            _buildSectionTitle(innerContext, 'Acciones Rápidas'),
                            const SizedBox(height: AppTheme.spacing16),
                            BlocBuilder<GuestHomeBloc, GuestHomeState>(
                              builder: (context, state) {
                                // Solo obtener unitName, unitType y unitId si el estado es GuestHomeLoaded
                                // Si está cargando, usar null (se mostrará loading en _StayInfoCard)
                                final unitName = state is GuestHomeLoaded ? state.booking.unitName : null;
                                final unitType = state is GuestHomeLoaded ? state.booking.unitType : UnitType.apartment;
                                final unitId = state is GuestHomeLoaded ? state.booking.unitId : null;
                                // Si está cargando, no llamar a UnitImageHelper todavía
                                if (state is GuestHomeInitial || state is GuestHomeLoading) {
                                  return _buildQuickActions(context, isCheckinValidated, isCheckinSubmitted, user.bookingId, null, UnitType.apartment, null);
                                }
                                return _buildQuickActions(context, isCheckinValidated, isCheckinSubmitted, user.bookingId, unitName, unitType, unitId);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
      },
    );
  }

  /// Banner de estado que muestra información según el estado del check-in
  Widget _buildStatusBanner(BuildContext context, String? checkinStatus, String? rejectionReason, String? cancellationReason) {
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

    // Estado rejected - Rechazado (puede corregir)
    if (checkinStatus == 'rejected') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                        'Debes corregir los errores y volver a enviarlo.',
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
            // Mostrar motivo del rechazo si existe
            if (rejectionReason != null && rejectionReason.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.blackWithAlpha30 : AppColors.whiteWithAlpha90,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Motivo del rechazo:',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      rejectionReason,
                      style: TextStyle(
                        color: AppColors.getTextPrimaryColor(context),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Estado cancelled - Reserva cancelada (NO permite corregir)
    if (checkinStatus == 'cancelled') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.block, color: AppColors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reserva cancelada',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tu reserva ha sido cancelada.',
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
            // Mostrar motivo de la cancelación si existe
            if (cancellationReason != null && cancellationReason.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.blackWithAlpha30 : AppColors.whiteWithAlpha90,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Motivo de la cancelación:',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      cancellationReason,
                      style: TextStyle(
                        color: AppColors.getTextPrimaryColor(context),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Añadir aviso de contacto
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.phone, color: AppColors.gold, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Contacta con recepción',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
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
        // Notification bell
        BlocBuilder<GuestHomeBloc, GuestHomeState>(
          buildWhen: (prev, curr) => curr is GuestHomeLoaded,
          builder: (context, state) {
            final unreadCount = state is GuestHomeLoaded ? state.unreadNotificationsCount : 0;
            return Stack(
              children: [
                IconButton(
                  onPressed: () => context.go('/guest/notifications'),
                  icon: Icon(
                    Icons.notifications_outlined,
                    color: AppColors.getTextSecondaryColor(context),
                  ),
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : '$unreadCount',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        // Logout button
        IconButton(
          onPressed: () async {
            final confirmed = await LogoutConfirmationDialog.show(context);
            if (confirmed && context.mounted) {
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            }
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

  Widget _buildQuickActions(BuildContext context, bool isCheckinValidated, bool isCheckinSubmitted, String? bookingId, String? unitName, UnitType unitType, String? unitId) {
    // Si está submitted, el check-in está deshabilitado (ya enviado)
    final canDoCheckin = !isCheckinSubmitted && !isCheckinValidated;
    // Obtener imagen dinámica del alojamiento
    final accommodationImagePath = UnitImageHelper.getLocalImagePath(unitName);
    // Determinar si es hotel para mostrar Registro Físico
    final isHotel = unitType == UnitType.hotelRoom;

    // Si NO está validado: Check-in, Chat, Pack Romántico y Registro Físico
    if (!isCheckinValidated) {
      return Column(
        children: [
          // Primera fila: Check-in y Chat
          Row(
            children: [
              Expanded(
                child: _ServiceCard(
                  icon: Icons.fact_check_outlined,
                  title: 'Check-in',
                  imagePath: 'assets/images/checkin.png',
                  onTap: canDoCheckin && bookingId != null ? () => context.go('/guest/checkin/$bookingId') : null,
                ),
              ),
              const SizedBox(width: AppTheme.spacing8),
              Expanded(
                child: _ServiceCard(
                  icon: Icons.chat_bubble_outline,
                  title: 'Chat',
                  imagePath: 'assets/images/chat.png',
                  onTap: () => context.go('/guest/chat'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing8),
          // Segunda fila: Pack Romántico y (Registro Físico solo si es hotel)
          Row(
            children: [
              Expanded(
                child: _ServiceCard(
                  icon: Icons.favorite_outline,
                  title: 'Pack Romántico',
                  imagePath: 'assets/images/pack_romantico.png',
                  onTap: () => context.go('/guest/romantic-pack'),
                ),
              ),
              // Solo mostrar Registro Físico si es hotel
              if (isHotel) ...[
                const SizedBox(width: AppTheme.spacing8),
                Expanded(
                  child: _ServiceCard(
                    icon: Icons.assignment_outlined,
                    title: 'Registro Físico',
                    imagePath: 'assets/images/registro_fisico.png',
                    onTap: () => context.go('/guest/physical-registration'),
                  ),
                ),
              ],
            ],
          ),
        ],
      );
    }

    // Si está validado: Grid de 3 columnas con todos los servicios
    final services = <_ServiceItem>[
      _ServiceItem(
        icon: Icons.home_outlined,
        title: 'Mi Alojamiento',
        imagePath: accommodationImagePath,
        onTap: () => context.push('/guest/my-accommodation'),
      ),
      _ServiceItem(
        icon: Icons.rule_outlined,
        title: 'Normas',
        imagePath: 'assets/images/normas.png',
        onTap: bookingId != null ? () => context.push('/guest/normas/$bookingId') : null,
      ),
      _ServiceItem(
        icon: Icons.info_outline,
        title: 'Instrucciones',
        imagePath: 'assets/images/servicios.png',
        onTap: () => context.push('/guest/access-instructions'),
      ),
      _ServiceItem(
        icon: Icons.chat_bubble_outline,
        title: 'Chat',
        imagePath: 'assets/images/chat.png',
        onTap: () => context.go('/guest/chat'),
      ),
      _ServiceItem(
        icon: Icons.book_outlined,
        title: 'Guía',
        imagePath: 'assets/images/info.png',
        onTap: () => context.go('/guest/guide'),
      ),
      _ServiceItem(
        icon: Icons.logout_outlined,
        title: 'Check-out',
        imagePath: 'assets/images/checkout.png',
        onTap: bookingId != null ? () => context.go('/guest/checkout/$bookingId') : null,
      ),
      // Nuevas acciones al final
      _ServiceItem(
        icon: Icons.apartment_outlined,
        title: 'Alojamientos',
        imagePath: 'assets/images/alojamiento.png',
        onTap: () => context.go('/guest/alojamientos'),
      ),
      _ServiceItem(
        icon: Icons.local_parking_outlined,
        title: 'Parkings',
        imagePath: 'assets/images/parking.png',
        onTap: unitId != null ? () => context.go('/guest/parkings/$unitId') : null,
      ),
      _ServiceItem(
        icon: Icons.explore_outlined,
        title: '¿Qué ver?',
        imagePath: 'assets/images/quever.png',
        onTap: () => context.go('/guest/que-ver'),
      ),
      // Pack Romántico (siempre disponible)
      _ServiceItem(
        icon: Icons.favorite_outline,
        title: 'Pack Romántico',
        imagePath: 'assets/images/pack_romantico.png',
        onTap: () => context.go('/guest/romantic-pack'),
      ),
      // Registro Físico solo para hoteles
      if (isHotel)
        _ServiceItem(
          icon: Icons.assignment_outlined,
          title: 'Registro Físico',
          imagePath: 'assets/images/registro_fisico.png',
          onTap: () => context.go('/guest/physical-registration'),
        ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 4,
        childAspectRatio: 0.8,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return _ServiceCard(
          icon: service.icon,
          title: service.title,
          imagePath: service.imagePath,
          onTap: service.onTap,
        );
      },
    );
  }
}

/// Widget para mostrar la información de la estancia usando el BLoC
class _StayInfoCard extends StatelessWidget {
  const _StayInfoCard();

  /// Obtiene la ruta de la imagen local para una unidad
  String? _getLocalImagePath(String? unitName) {
    return UnitImageHelper.getLocalImagePath(unitName);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GuestHomeBloc, GuestHomeState>(
      builder: (context, state) {
        if (state is GuestHomeLoading) {
          return _buildLoadingCard(context);
        }

        if (state is GuestHomeError) {
          return _buildErrorCard(context, state.message);
        }

        if (state is GuestHomeNoBooking) {
          return _buildErrorCard(context, 'No hay reserva asociada');
        }

        if (state is GuestHomeLoaded) {
          return _buildBookingCard(context, state.booking, state.isRefreshing);
        }

        return _buildLoadingCard(context);
      },
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
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

  Widget _buildErrorCard(BuildContext context, String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppColors.getBorderColor(context)),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color: AppColors.getTextSecondaryColor(context),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, booking, bool isRefreshing) {
    final dateFormat = DateFormat('d MMM');
    final checkInStr = dateFormat.format(booking.checkInDate);
    final checkOutStr = dateFormat.format(booking.checkOutDate);
    final nights = booking.stayDurationNights;
    final imagePath = _getLocalImagePath(booking.unitName);

    return Container(
      padding: EdgeInsets.all(context.responsive(mobile: AppTheme.spacing16, tablet: AppTheme.spacing24)),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: AppColors.gold,
          width: 1.5,
        ),
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
              // Foto del alojamiento o icono como fallback
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: imagePath != null
                    ? Image.asset(
                        imagePath,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 44,
                          height: 44,
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
                      )
                    : Container(
                        width: 44,
                        height: 44,
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
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            booking.unitName.isNotEmpty ? booking.unitName : 'Alojamiento',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.getTextPrimaryColor(context),
                            ),
                          ),
                        ),
                        if (isRefreshing)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.gold,
                            ),
                          ),
                      ],
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

/// Modelo para los items de servicio
class _ServiceItem {
  const _ServiceItem({
    required this.icon,
    required this.title,
    this.imagePath,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? imagePath;
  final VoidCallback? onTap;
}

/// Widget para las tarjetas de servicio con imagen y texto debajo
class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.icon,
    required this.title,
    this.imagePath,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? imagePath;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.5,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Contenedor con imagen o gradiente
            Flexible(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.gold,
                      width: 1.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10.5),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: imagePath == null
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.gold,
                                  AppColors.goldLight,
                                ],
                              )
                            : null,
                      ),
                      child: imagePath != null
                          ? Image.asset(
                              imagePath!,
                              fit: BoxFit.cover,
                            )
                          : Icon(
                              icon,
                              color: AppColors.black,
                              size: 32,
                            ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Título debajo del recuadro
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isEnabled
                    ? AppColors.getTextPrimaryColor(context)
                    : AppColors.getTextSecondaryColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
