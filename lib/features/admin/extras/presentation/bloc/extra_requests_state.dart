import 'package:equatable/equatable.dart';

import 'package:bf_stay/features/guest/extras/domain/entities/extra_request_entity.dart';

/// Estados del BLoC del listado de solicitudes de extras (admin).
abstract class ExtraRequestsState extends Equatable {
  const ExtraRequestsState();

  @override
  List<Object?> get props => [];
}

class ExtraRequestsInitial extends ExtraRequestsState {
  const ExtraRequestsInitial();
}

class ExtraRequestsLoading extends ExtraRequestsState {
  const ExtraRequestsLoading();
}

class ExtraRequestsLoaded extends ExtraRequestsState {
  const ExtraRequestsLoaded({
    required this.requests,
    this.filter,
    this.actionError,
  });

  /// Todas las solicitudes recibidas (sin filtrar).
  final List<ExtraRequestEntity> requests;

  /// Filtro de estado activo (null = todas).
  final ExtraRequestStatus? filter;

  /// Error puntual de una acción (borrar, marcar gestionada) sin perder el
  /// listado ya cargado. Se limpia en la siguiente emisión.
  final String? actionError;

  /// Solicitudes visibles según el filtro.
  List<ExtraRequestEntity> get visibleRequests {
    if (filter == null) return requests;
    return requests.where((r) => r.status == filter).toList();
  }

  /// Nº de solicitudes pendientes de gestionar.
  int get pendingCount =>
      requests.where((r) => r.status == ExtraRequestStatus.requested).length;

  ExtraRequestsLoaded copyWith({
    List<ExtraRequestEntity>? requests,
    ExtraRequestStatus? filter,
    bool clearFilter = false,
    String? actionError,
  }) {
    return ExtraRequestsLoaded(
      requests: requests ?? this.requests,
      filter: clearFilter ? null : (filter ?? this.filter),
      // Transitorio: no se arrastra si no se pasa explícitamente.
      actionError: actionError,
    );
  }

  @override
  List<Object?> get props => [requests, filter, actionError];
}

class ExtraRequestsError extends ExtraRequestsState {
  const ExtraRequestsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
