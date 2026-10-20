import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bf_stay/features/guest/extras/domain/entities/extra_request_entity.dart';
import 'package:bf_stay/features/guest/extras/domain/repositories/extra_request_repository.dart';
import 'extra_requests_event.dart';
import 'extra_requests_state.dart';

/// BLoC del listado de solicitudes de extras para el admin.
///
/// Se suscribe en tiempo real a `extra_requests` (RLS filtra por propiedad) y
/// permite marcar solicitudes como gestionadas.
class ExtraRequestsBloc extends Bloc<ExtraRequestsEvent, ExtraRequestsState> {
  ExtraRequestsBloc({
    required ExtraRequestRepository repository,
    this.managedBy,
  })  : _repository = repository,
        super(const ExtraRequestsInitial()) {
    on<ExtraRequestsStarted>(_onStarted);
    on<ExtraRequestsUpdated>(_onUpdated);
    on<ExtraRequestMarkManaged>(_onMarkManaged);
    on<ExtraRequestDeleted>(_onDeleted);
    on<ExtraRequestsFilterChanged>(_onFilterChanged);
    on<ExtraRequestsErrored>(_onErrored);
  }

  final ExtraRequestRepository _repository;

  /// ID del admin que gestiona (para registrar `managed_by`).
  final String? managedBy;

  StreamSubscription<List<ExtraRequestEntity>>? _subscription;

  Future<void> _onStarted(
    ExtraRequestsStarted event,
    Emitter<ExtraRequestsState> emit,
  ) async {
    emit(const ExtraRequestsLoading());
    await _subscription?.cancel();
    _subscription = _repository.watchAll().listen(
      (requests) {
        if (!isClosed) add(ExtraRequestsUpdated(requests));
      },
      onError: (Object error) {
        if (!isClosed) add(ExtraRequestsErrored(error.toString()));
      },
    );
  }

  void _onUpdated(
    ExtraRequestsUpdated event,
    Emitter<ExtraRequestsState> emit,
  ) {
    final currentFilter = state is ExtraRequestsLoaded
        ? (state as ExtraRequestsLoaded).filter
        : null;
    emit(ExtraRequestsLoaded(
      requests: event.requests,
      filter: currentFilter,
    ));
  }

  Future<void> _onMarkManaged(
    ExtraRequestMarkManaged event,
    Emitter<ExtraRequestsState> emit,
  ) async {
    final current = state;
    try {
      await _repository.markAsManaged(event.id, managedBy: managedBy);
      // El stream realtime reflejará el cambio automáticamente.
    } catch (e) {
      debugPrint('❌ [ExtraRequestsBloc] Error al marcar gestionada: $e');
      if (current is ExtraRequestsLoaded) {
        emit(current.copyWith(
          actionError: 'No se pudo marcar la solicitud como gestionada',
        ));
      } else if (!isClosed) {
        add(ExtraRequestsErrored(e.toString()));
      }
    }
  }

  Future<void> _onDeleted(
    ExtraRequestDeleted event,
    Emitter<ExtraRequestsState> emit,
  ) async {
    final current = state;
    try {
      await _repository.delete(event.id);
      // Quitarla ya del listado: el stream realtime confirmará el borrado.
      if (current is ExtraRequestsLoaded) {
        emit(current.copyWith(
          requests:
              current.requests.where((r) => r.id != event.id).toList(),
        ));
      }
    } catch (e) {
      debugPrint('❌ [ExtraRequestsBloc] Error al eliminar solicitud: $e');
      if (current is ExtraRequestsLoaded) {
        emit(current.copyWith(actionError: 'No se pudo eliminar la solicitud'));
      } else if (!isClosed) {
        add(ExtraRequestsErrored(e.toString()));
      }
    }
  }

  void _onFilterChanged(
    ExtraRequestsFilterChanged event,
    Emitter<ExtraRequestsState> emit,
  ) {
    final current = state;
    if (current is ExtraRequestsLoaded) {
      emit(ExtraRequestsLoaded(
        requests: current.requests,
        filter: event.filter,
      ));
    }
  }

  void _onErrored(
    ExtraRequestsErrored event,
    Emitter<ExtraRequestsState> emit,
  ) {
    // Solo mostrar error si aún no hay datos cargados.
    if (state is! ExtraRequestsLoaded) {
      emit(ExtraRequestsError(event.message));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
