import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/router/app_router.dart';
import '../../../domain/bloc/bloc.dart';

/// Tab de resumen del dashboard de administración
class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminDashboardBloc, AdminDashboardState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.gold,
            ),
          );
        }

        if (state.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar datos',
                  style: TextStyle(
                    color: AppColors.getTextPrimaryColor(context),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.error!,
                  style: TextStyle(
                    color: AppColors.getTextSecondaryColor(context),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<AdminDashboardBloc>().add(
                          const AdminDashboardLoadRequested(),
                        );
                  },
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.gold,
          backgroundColor: AppColors.darkSurface,
          onRefresh: () async {
            context.read<AdminDashboardBloc>().add(
                  const AdminDashboardRefreshRequested(),
                );
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting
                _buildGreeting(context),
                const SizedBox(height: 24),

                // Stat cards
                _buildStatCards(context, state),
                const SizedBox(height: 24),

                // Recent check-ins
                _buildRecentCheckins(context, state),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGreeting(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Buenos días';
    } else if (hour < 20) {
      greeting = 'Buenas tardes';
    } else {
      greeting = 'Buenas noches';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w300,
            color: AppColors.getTextSecondaryColor(context),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Panel de administración',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: AppColors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCards(BuildContext context, AdminDashboardState state) {
    final summary = state.summary;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.pending_actions_outlined,
                value: summary?.pendingCheckins.toString() ?? '0',
                label: 'Check-ins pendientes',
                onTap: () {
                  context.read<AdminDashboardBloc>().add(
                        const AdminDashboardTabChanged(2),
                      );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.flight_land_outlined,
                value: summary?.upcomingCheckins.toString() ?? '0',
                label: 'Llegadas próximas 7 días',
                onTap: () {
                  context.read<AdminDashboardBloc>().add(
                        const AdminDashboardTabChanged(1),
                      );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.chat_bubble_outline,
                value: 'Chat',
                label: 'Mensajes de huéspedes',
                onTap: () {
                  context.go(AppRoutes.adminChat);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.apartment_outlined,
                value: summary?.totalUnits.toString() ?? '0',
                label: 'Alojamientos activos',
                onTap: () {
                  context.read<AdminDashboardBloc>().add(
                        const AdminDashboardTabChanged(3),
                      );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentCheckins(BuildContext context, AdminDashboardState state) {
    final recentCheckins = state.summary?.recentCheckins ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Últimos check-ins',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.white,
              ),
            ),
            if (state.checkins.isNotEmpty)
              TextButton(
                onPressed: () {
                  context.read<AdminDashboardBloc>().add(
                        const AdminDashboardTabChanged(2),
                      );
                },
                child: const Text(
                  'Ver todos',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.gold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (recentCheckins.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.how_to_reg_outlined,
                    size: 40,
                    color: AppColors.gray500,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No hay check-ins recientes',
                    style: TextStyle(
                      color: AppColors.getTextSecondaryColor(context),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: recentCheckins.take(5).map((checkin) {
              return _RecentCheckinTile(
                checkin: checkin,
                onTap: () {
                  // TODO: Navigate to booking detail
                },
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.goldWithAlpha20,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.whiteWithAlpha70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentCheckinTile extends StatelessWidget {
  const _RecentCheckinTile({
    required this.checkin,
    this.onTap,
  });

  final dynamic checkin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 40,
              decoration: BoxDecoration(
                color: checkin.checkinStatus == 'submitted'
                    ? const Color(0xFFE67E22)
                    : const Color(0xFF27AE60),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    checkin.guestName ?? 'Huésped',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    checkin.unitName ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.getTextSecondaryColor(context),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              checkin.bookingCode ?? '',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.gold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
