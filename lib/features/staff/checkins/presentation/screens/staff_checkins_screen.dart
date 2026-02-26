import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bf_stay/core/theme/app_colors.dart';
import 'package:bf_stay/core/theme/app_theme.dart';

/// Pantalla de gestión de check-ins para el personal
class StaffCheckinsScreen extends StatefulWidget {
  const StaffCheckinsScreen({super.key});

  @override
  State<StaffCheckinsScreen> createState() => _StaffCheckinsScreenState();
}

class _StaffCheckinsScreenState extends State<StaffCheckinsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/staff'),
        ),
        title: const Text('Gestión de Check-ins'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.gold,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.gold,
          tabs: const [
            Tab(text: 'Pendientes'),
            Tab(text: 'En proceso'),
            Tab(text: 'Completados'),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: TabBarView(
          controller: _tabController,
          children: [
            _PendingCheckinsTab(),
            _InProgressCheckinsTab(),
            _CompletedCheckinsTab(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppColors.gold,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nuevo Check-in',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class _PendingCheckinsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return _CheckinCard(
          guestName: 'Huésped ${index + 1}',
          room: '${100 + index + 1}',
          checkinTime: '${14 + index}:00',
          status: CheckinStatus.pending,
        );
      },
    );
  }
}

class _InProgressCheckinsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      itemCount: 2,
      itemBuilder: (context, index) {
        return _CheckinCard(
          guestName: 'Huésped en proceso ${index + 1}',
          room: '${200 + index + 1}',
          checkinTime: '${15 + index}:30',
          status: CheckinStatus.inProgress,
        );
      },
    );
  }
}

class _CompletedCheckinsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      itemCount: 8,
      itemBuilder: (context, index) {
        return _CheckinCard(
          guestName: 'Huésped completado ${index + 1}',
          room: '${300 + index + 1}',
          checkinTime: '${10 + index}:00',
          status: CheckinStatus.completed,
        );
      },
    );
  }
}

enum CheckinStatus { pending, inProgress, completed }

class _CheckinCard extends StatelessWidget {
  const _CheckinCard({
    required this.guestName,
    required this.room,
    required this.checkinTime,
    required this.status,
  });

  final String guestName;
  final String room;
  final String checkinTime;
  final CheckinStatus status;

  Color get _statusColor {
    switch (status) {
      case CheckinStatus.pending:
        return AppColors.warning;
      case CheckinStatus.inProgress:
        return AppColors.info;
      case CheckinStatus.completed:
        return AppColors.success;
    }
  }

  String get _statusText {
    switch (status) {
      case CheckinStatus.pending:
        return 'Pendiente';
      case CheckinStatus.inProgress:
        return 'En proceso';
      case CheckinStatus.completed:
        return 'Completado';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.goldWithAlpha10,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Center(
                    child: Text(
                      room,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.gold,
                          ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        guestName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            checkinTime,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing12,
                    vertical: AppTheme.spacing4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Text(
                    _statusText,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: _statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            if (status != CheckinStatus.completed) ...[
              const SizedBox(height: AppTheme.spacing12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: const Text('Ver detalles'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppTheme.spacing8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: Icon(
                        status == CheckinStatus.pending
                            ? Icons.play_arrow
                            : Icons.check,
                        size: 18,
                      ),
                      label: Text(
                        status == CheckinStatus.pending ? 'Iniciar' : 'Completar',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppTheme.spacing8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
