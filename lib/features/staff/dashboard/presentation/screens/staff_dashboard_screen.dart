import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:bf_stay/core/theme/app_colors.dart';
import 'package:bf_stay/core/theme/app_theme.dart';
import 'package:bf_stay/features/auth/domain/bloc/auth_bloc.dart';
import 'package:bf_stay/l10n/app_localizations.dart';

/// Dashboard del personal
class StaffDashboardScreen extends StatelessWidget {
  const StaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacing24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(context, user),
                  const SizedBox(height: AppTheme.spacing32),

                  // Stats
                  _buildSectionTitle(context, S.of(context).staff_dashboard_daily_summary),
                  const SizedBox(height: AppTheme.spacing16),
                  _buildStatsGrid(context),
                  const SizedBox(height: AppTheme.spacing32),

                  // Pending tasks
                  _buildSectionTitle(context, S.of(context).staff_dashboard_pending_tasks),
                  const SizedBox(height: AppTheme.spacing16),
                  _buildPendingTasks(context),
                  const SizedBox(height: AppTheme.spacing32),

                  // Quick actions
                  _buildSectionTitle(context, S.of(context).staff_dashboard_quick_actions),
                  const SizedBox(height: AppTheme.spacing16),
                  _buildQuickActions(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, user) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: AppColors.goldGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          ),
          child: Center(
            child: Text(
              user?.initials ?? 'S',
              style: const TextStyle(
                fontSize: 20,
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
                S.of(context).staff_dashboard_greeting(user?.displayName ?? 'Staff'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                S.of(context).staff_dashboard_control_panel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
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
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: AppTheme.spacing12,
      crossAxisSpacing: AppTheme.spacing12,
      childAspectRatio: 1.4,
      children: [
        _StatCard(
          title: S.of(context).staff_dashboard_checkins_today,
          value: '8',
          icon: Icons.login,
          color: AppColors.success,
        ),
        _StatCard(
          title: S.of(context).staff_dashboard_checkouts_today,
          value: '5',
          icon: Icons.logout,
          color: AppColors.warning,
        ),
        _StatCard(
          title: S.of(context).staff_dashboard_occupancy,
          value: '85%',
          icon: Icons.hotel,
          color: AppColors.info,
        ),
        _StatCard(
          title: S.of(context).staff_dashboard_pending,
          value: '3',
          icon: Icons.pending_actions,
          color: AppColors.error,
        ),
      ],
    );
  }

  Widget _buildPendingTasks(BuildContext context) {
    return Column(
      children: [
        _TaskCard(
          title: S.of(context).staff_dashboard_pending_checkin,
          subtitle: S.of(context).staff_dashboard_room_guest('204', 'Juan García'),
          time: '14:00',
          type: TaskType.checkin,
        ),
        const SizedBox(height: AppTheme.spacing8),
        _TaskCard(
          title: S.of(context).staff_dashboard_pending_checkout,
          subtitle: S.of(context).staff_dashboard_room_guest('102', 'María López'),
          time: '11:00',
          type: TaskType.checkout,
        ),
        const SizedBox(height: AppTheme.spacing8),
        _TaskCard(
          title: S.of(context).staff_dashboard_cleaning_request,
          subtitle: S.of(context).staff_dashboard_room_extras('305'),
          time: '16:30',
          type: TaskType.cleaning,
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.fact_check_outlined,
            title: S.of(context).staff_dashboard_manage_checkins,
            color: AppColors.gold,
            onTap: () => context.go('/staff/checkins'),
          ),
        ),
        const SizedBox(width: AppTheme.spacing12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.people_outline,
            title: S.of(context).staff_dashboard_view_guests,
            color: AppColors.info,
            onTap: () {},
          ),
        ),
        const SizedBox(width: AppTheme.spacing12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.report_outlined,
            title: S.of(context).staff_dashboard_generate_report,
            color: AppColors.success,
            onTap: () {},
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

enum TaskType { checkin, checkout, cleaning }

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.type,
  });

  final String title;
  final String subtitle;
  final String time;
  final TaskType type;

  Color get _color {
    switch (type) {
      case TaskType.checkin:
        return AppColors.success;
      case TaskType.checkout:
        return AppColors.warning;
      case TaskType.cleaning:
        return AppColors.info;
    }
  }

  IconData get _icon {
    switch (type) {
      case TaskType.checkin:
        return Icons.login;
      case TaskType.checkout:
        return Icons.logout;
      case TaskType.cleaning:
        return Icons.cleaning_services;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing8),
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(_icon, color: _color, size: 20),
          ),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing8,
              vertical: AppTheme.spacing4,
            ),
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Text(
              time,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
        ],
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              title,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
