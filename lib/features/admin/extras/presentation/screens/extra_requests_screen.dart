import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bf_stay/core/di/injection.dart';
import 'package:bf_stay/core/theme/app_colors.dart';
import 'package:bf_stay/features/auth/domain/bloc/auth_bloc.dart';
import 'package:bf_stay/features/guest/extras/domain/entities/extra_request_entity.dart';
import 'package:bf_stay/features/guest/extras/domain/repositories/extra_request_repository.dart';
import '../bloc/extra_requests_bloc.dart';
import '../bloc/extra_requests_event.dart';
import '../bloc/extra_requests_state.dart';
import '../widgets/extra_request_card.dart';

/// Pantalla de administración: listado de solicitudes de extras (Pack Romántico).
class ExtraRequestsScreen extends StatelessWidget {
  const ExtraRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final adminId = authState is AuthAuthenticated ? authState.user.id : null;

    return BlocProvider(
      create: (_) => ExtraRequestsBloc(
        repository: getIt<ExtraRequestRepository>(),
        managedBy: adminId,
      )..add(const ExtraRequestsStarted()),
      child: Scaffold(
        backgroundColor: AppColors.getSurfaceColor(context),
        appBar: AppBar(
          backgroundColor: AppColors.getSurfaceColor(context),
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.getTextPrimaryColor(context)),
          title: Text(
            'Solicitudes de extras',
            style: TextStyle(
              color: AppColors.getTextPrimaryColor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: SafeArea(
          child: BlocConsumer<ExtraRequestsBloc, ExtraRequestsState>(
            listenWhen: (prev, curr) =>
                curr is ExtraRequestsError ||
                (curr is ExtraRequestsLoaded && curr.actionError != null),
            listener: (context, state) {
              final message = switch (state) {
                ExtraRequestsError(:final message) => 'Error: $message',
                ExtraRequestsLoaded(:final actionError?) => actionError,
                _ => null,
              };
              if (message != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is ExtraRequestsLoading ||
                  state is ExtraRequestsInitial) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is ExtraRequestsError) {
                return _ErrorView(message: state.message);
              }
              if (state is ExtraRequestsLoaded) {
                return _LoadedView(state: state);
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  const _LoadedView({required this.state});

  final ExtraRequestsLoaded state;

  @override
  Widget build(BuildContext context) {
    final items = state.visibleRequests;

    return Column(
      children: [
        _FilterBar(active: state.filter, pendingCount: state.pendingCount),
        Expanded(
          child: items.isEmpty
              ? const _EmptyView()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final request = items[index];
                    return ExtraRequestCard(
                      request: request,
                      onMarkManaged: () => _confirmManaged(context, request),
                      onDelete: () => _confirmDelete(context, request),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _confirmManaged(
    BuildContext context,
    ExtraRequestEntity request,
  ) async {
    final bloc = context.read<ExtraRequestsBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.getCardColor(dialogContext),
        title: Text(
          'Marcar como gestionada',
          style: TextStyle(color: AppColors.getTextPrimaryColor(dialogContext)),
        ),
        content: Text(
          '¿Confirmas que ya has gestionado esta solicitud de "${request.extraName}"?',
          style: TextStyle(color: AppColors.getTextSecondaryColor(dialogContext)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      bloc.add(ExtraRequestMarkManaged(request.id));
    }
  }

  /// Borra definitivamente la solicitud (acción irreversible).
  Future<void> _confirmDelete(
    BuildContext context,
    ExtraRequestEntity request,
  ) async {
    final bloc = context.read<ExtraRequestsBloc>();
    final guest = request.guestName?.isNotEmpty == true
        ? ' de ${request.guestName}'
        : '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.getCardColor(dialogContext),
        title: Text(
          'Eliminar solicitud',
          style: TextStyle(color: AppColors.getTextPrimaryColor(dialogContext)),
        ),
        content: Text(
          'Se eliminará definitivamente la solicitud de "${request.extraName}"$guest. '
          'Esta acción no se puede deshacer y el huésped podrá volver a solicitarlo '
          'si sigue en plazo.',
          style: TextStyle(color: AppColors.getTextSecondaryColor(dialogContext)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      bloc.add(ExtraRequestDeleted(request.id));
    }
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.active, required this.pendingCount});

  final ExtraRequestStatus? active;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          _FilterChip(
            label: pendingCount > 0 ? 'Pendientes ($pendingCount)' : 'Pendientes',
            selected: active == ExtraRequestStatus.requested,
            filter: ExtraRequestStatus.requested,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Gestionadas',
            selected: active == ExtraRequestStatus.managed,
            filter: ExtraRequestStatus.managed,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Todas',
            selected: active == null,
            filter: null,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.filter,
  });

  final String label;
  final bool selected;
  final ExtraRequestStatus? filter;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          context.read<ExtraRequestsBloc>().add(ExtraRequestsFilterChanged(filter)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.gold
              : AppColors.getChipBackgroundColor(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.gold
                : AppColors.getBorderColor(context),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected
                ? AppColors.black
                : AppColors.getTextSecondaryColor(context),
          ),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.card_giftcard_outlined,
            size: 64,
            color: AppColors.getTextSecondaryColor(context),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay solicitudes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Cuando un huésped solicite un extra, aparecerá aquí.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.getTextSecondaryColor(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'No se pudieron cargar las solicitudes',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.getTextPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.getTextSecondaryColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
