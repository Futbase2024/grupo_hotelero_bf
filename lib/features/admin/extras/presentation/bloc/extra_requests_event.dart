import 'package:equatable/equatable.dart';

import 'package:bf_stay/features/guest/extras/domain/entities/extra_request_entity.dart';

/// Eventos del BLoC del listado de solicitudes de extras (admin).
abstract class ExtraRequestsEvent extends Equatable {
  const ExtraRequestsEvent();

  @override
  List<Object?> get props => [];
}

/// Carga inicial + suscripción realtime.
class ExtraRequestsStarted extends ExtraRequestsEvent {
  const ExtraRequestsStarted();
}

/// Emitido internamente cuando llegan datos nuevos por realtime.
class ExtraRequestsUpdated extends ExtraRequestsEvent {
  const ExtraRequestsUpdated(this.requests);

  final List<ExtraRequestEntity> requests;

  @override
  List<Object?> get props => [requests];
}

/// Marca una solicitud como gestionada.
class ExtraRequestMarkManaged extends ExtraRequestsEvent {
  const ExtraRequestMarkManaged(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

/// Elimina definitivamente una solicitud.
class ExtraRequestDeleted extends ExtraRequestsEvent {
  const ExtraRequestDeleted(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

/// Cambia el filtro de estado del listado.
class ExtraRequestsFilterChanged extends ExtraRequestsEvent {
  const ExtraRequestsFilterChanged(this.filter);

  final ExtraRequestStatus? filter;

  @override
  List<Object?> get props => [filter];
}

/// Error emitido internamente desde el stream.
class ExtraRequestsErrored extends ExtraRequestsEvent {
  const ExtraRequestsErrored(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
