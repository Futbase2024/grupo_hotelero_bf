import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:bf_stay/core/theme/app_colors.dart';
import 'package:bf_stay/core/theme/app_theme.dart';
import 'package:bf_stay/core/theme/responsive.dart';
import 'package:bf_stay/features/auth/domain/bloc/auth_bloc.dart';

/// Pantalla principal del huésped
class GuestHomeScreen extends StatelessWidget {
  const GuestHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;

        return Scaffold(
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

                    // Quick actions
                    _buildSectionTitle(context, 'Acciones Rápidas'),
                    const SizedBox(height: AppTheme.spacing16),
                    _buildQuickActions(context),
                    SizedBox(height: context.responsive(mobile: AppTheme.spacing24, tablet: AppTheme.spacing32)),

                    // Stay info
                    _buildSectionTitle(context, 'Tu Estadía'),
                    const SizedBox(height: AppTheme.spacing16),
                    _buildStayInfoCard(context),
                    SizedBox(height: context.responsive(mobile: AppTheme.spacing24, tablet: AppTheme.spacing32)),

                    // Services
                    _buildSectionTitle(context, 'Servicios'),
                    const SizedBox(height: AppTheme.spacing16),
                    _buildServicesGrid(context),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
                color: Colors.white,
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
                '¡Hola, ${user?.displayName ?? "Huésped"}!',
                style: TextStyle(
                  fontSize: ResponsiveFontSize.titleLarge(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Bienvenido a tu estadía',
                style: TextStyle(
                  fontSize: ResponsiveFontSize.bodyMedium(context),
                  color: AppColors.textSecondary,
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
          color: AppColors.textSecondary,
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
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    // En tablet/desktop, mostrar más acciones en fila
    final isWide = context.isTablet || context.isDesktop;

    if (isWide) {
      return Row(
        children: [
          Expanded(
            child: _QuickActionCard(
              icon: Icons.fact_check_outlined,
              title: 'Check-in',
              color: AppColors.success,
              onTap: () => context.go('/guest/checkin'),
            ),
          ),
          const SizedBox(width: AppTheme.spacing16),
          Expanded(
            child: _QuickActionCard(
              icon: Icons.lock_open_outlined,
              title: 'Access Box',
              color: AppColors.gold,
              onTap: () => context.go('/guest/access-box'),
            ),
          ),
          const SizedBox(width: AppTheme.spacing16),
          Expanded(
            child: _QuickActionCard(
              icon: Icons.book_outlined,
              title: 'Guía',
              color: AppColors.info,
              onTap: () => context.go('/guest/guide'),
            ),
          ),
          const SizedBox(width: AppTheme.spacing16),
          Expanded(
            child: _QuickActionCard(
              icon: Icons.chat_bubble_outline,
              title: 'Chat',
              color: AppColors.info,
              onTap: () => context.go('/guest/chat'),
            ),
          ),
        ],
      );
    }

    // En móvil, mostrar en 2 columnas
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.fact_check_outlined,
            title: 'Check-in',
            color: AppColors.success,
            onTap: () => context.go('/guest/checkin'),
          ),
        ),
        const SizedBox(width: AppTheme.spacing12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.lock_open_outlined,
            title: 'Access Box',
            color: AppColors.gold,
            onTap: () => context.go('/guest/access-box'),
          ),
        ),
      ],
    );
  }

  Widget _buildStayInfoCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.responsive(mobile: AppTheme.spacing16, tablet: AppTheme.spacing24)),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppColors.border),
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
          Row(
            children: [
              Icon(
                Icons.home_outlined,
                color: AppColors.gold,
                size: context.responsive(mobile: 24.0, tablet: 28.0),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Suite Premium',
                      style: TextStyle(
                        fontSize: ResponsiveFontSize.titleMedium(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Propiedad BF Stay',
                      style: TextStyle(
                        fontSize: ResponsiveFontSize.bodySmall(context),
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (context.isDesktop)
                TextButton(
                  onPressed: () {},
                  child: const Text('Ver detalles'),
                ),
            ],
          ),
          const Divider(height: AppTheme.spacing24),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  context,
                  icon: Icons.calendar_today_outlined,
                  label: 'Check-in',
                  value: '24 Feb',
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  context,
                  icon: Icons.calendar_today_outlined,
                  label: 'Check-out',
                  value: '28 Feb',
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  context,
                  icon: Icons.bed_outlined,
                  label: 'Noches',
                  value: '4',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.gold),
        const SizedBox(height: AppTheme.spacing4),
        Text(
          value,
          style: TextStyle(
            fontSize: ResponsiveFontSize.titleSmall(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveFontSize.bodySmall(context),
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildServicesGrid(BuildContext context) {
    final services = [
      _ServiceItem(
        icon: Icons.book_outlined,
        title: 'Guía de Estadía',
        route: '/guest/guide',
      ),
      _ServiceItem(
        icon: Icons.chat_bubble_outline,
        title: 'Chat',
        route: '/guest/chat',
      ),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.gold),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        trailing: onTap != null
            ? const Icon(Icons.arrow_forward_ios, size: 16)
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
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final padding = context.responsive(
      mobile: AppTheme.spacing16,
      tablet: AppTheme.spacing20,
    );
    final iconSize = context.responsive(mobile: 28.0, tablet: 32.0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: iconSize),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              title,
              style: TextStyle(
                fontSize: ResponsiveFontSize.labelLarge(context),
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
