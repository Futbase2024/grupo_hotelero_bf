import 'package:equatable/equatable.dart';
import '../../domain/entities/guest_entity.dart';

/// Eventos del BLoC de check-in
abstract class CheckinEvent extends Equatable {
  const CheckinEvent();

  @override
  List<Object?> get props => [];
}

/// Iniciar el check-in cargando datos de la reserva
class CheckinStarted extends CheckinEvent {
  const CheckinStarted(this.bookingId);

  final String bookingId;

  @override
  List<Object?> get props => [bookingId];
}

/// Cambiar al siguiente paso
class CheckinStepChanged extends CheckinEvent {
  const CheckinStepChanged(this.step);

  final int step;

  @override
  List<Object?> get props => [step];
}

/// Añadir un nuevo huésped
class CheckinGuestAdded extends CheckinEvent {
  const CheckinGuestAdded(this.guest);

  final GuestEntity guest;

  @override
  List<Object?> get props => [guest];
}

/// Actualizar un huésped existente
class CheckinGuestUpdated extends CheckinEvent {
  const CheckinGuestUpdated(this.index, this.guest);

  final int index;
  final GuestEntity guest;

  @override
  List<Object?> get props => [index, guest];
}

/// Eliminar un huésped
class CheckinGuestRemoved extends CheckinEvent {
  const CheckinGuestRemoved(this.index);

  final int index;

  @override
  List<Object?> get props => [index];
}

/// Guardar los datos de un huésped
class CheckinGuestSaved extends CheckinEvent {
  const CheckinGuestSaved(this.index, this.guest);

  final int index;
  final GuestEntity guest;

  @override
  List<Object?> get props => [index, guest];
}

/// Subir un documento
class CheckinDocumentUploaded extends CheckinEvent {
  const CheckinDocumentUploaded({
    required this.guestIndex,
    required this.docKind,
    required this.bytes,
    required this.mimeType,
  });

  final int guestIndex;
  final String docKind;
  final List<int> bytes;
  final String mimeType;

  @override
  List<Object?> get props => [guestIndex, docKind, bytes, mimeType];
}

/// Actualizar documento del huésped (tipo, número y fotos de las caras)
class CheckinGuestDocumentUpdated extends CheckinEvent {
  const CheckinGuestDocumentUpdated({
    required this.guestIndex,
    required this.documentType,
    required this.documentNumber,
    this.frontBytes,
    this.backBytes,
  });

  final int guestIndex;
  final DocumentType documentType;
  final String documentNumber;

  /// Anverso del DNI/NIE o página de datos del pasaporte
  final List<int>? frontBytes;

  /// Reverso del DNI/NIE (null en pasaporte)
  final List<int>? backBytes;

  @override
  List<Object?> get props => [guestIndex, documentType, documentNumber, frontBytes, backBytes];
}

/// Guardar la firma del titular
class CheckinSignatureSaved extends CheckinEvent {
  const CheckinSignatureSaved(this.signatureSvg);

  final String? signatureSvg;

  @override
  List<Object?> get props => [signatureSvg];
}

/// Enviar el check-in completo
class CheckinSubmitted extends CheckinEvent {
  const CheckinSubmitted();
}

/// Reintentar después de un error
class CheckinRetry extends CheckinEvent {
  const CheckinRetry();
}

/// Refrescar el estado del check-in (pull-to-refresh)
class CheckinRefreshRequested extends CheckinEvent {
  const CheckinRefreshRequested(this.bookingId);

  final String bookingId;

  @override
  List<Object?> get props => [bookingId];
}

/// Verificar el estado del check-in (desde notificación o realtime)
class CheckinStatusCheckRequested extends CheckinEvent {
  const CheckinStatusCheckRequested(this.bookingId);

  final String bookingId;

  @override
  List<Object?> get props => [bookingId];
}
