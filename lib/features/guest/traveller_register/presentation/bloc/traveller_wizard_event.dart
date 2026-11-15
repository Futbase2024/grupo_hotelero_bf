import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import '../../../checkin/domain/repositories/checkin_repository.dart';
import '../../domain/entities/traveller_entity.dart';

sealed class TravellerWizardEvent extends Equatable {
  const TravellerWizardEvent();

  @override
  List<Object?> get props => [];
}

/// Carga los huéspedes de la reserva y el estado del registro
class TravellerWizardStarted extends TravellerWizardEvent {
  const TravellerWizardStarted(this.booking);

  final CheckinBookingData booking;

  @override
  List<Object?> get props => [booking.bookingId];
}

/// Ir a una pantalla. Hacia delante valida y guarda antes de avanzar.
class TravellerWizardStepRequested extends TravellerWizardEvent {
  const TravellerWizardStepRequested(this.step);

  final int step;

  @override
  List<Object?> get props => [step];
}

class TravellerWizardTravellerSelected extends TravellerWizardEvent {
  const TravellerWizardTravellerSelected(this.index);

  final int index;

  @override
  List<Object?> get props => [index];
}

/// Cambio de un campo en el formulario (solo en memoria hasta avanzar)
class TravellerWizardTravellerChanged extends TravellerWizardEvent {
  const TravellerWizardTravellerChanged(this.index, this.traveller);

  final int index;
  final TravellerEntity traveller;

  @override
  List<Object?> get props => [index, traveller];
}

class TravellerWizardTravellerAdded extends TravellerWizardEvent {
  const TravellerWizardTravellerAdded();
}

/// Quita un huésped que aún no se ha guardado
class TravellerWizardTravellerRemoved extends TravellerWizardEvent {
  const TravellerWizardTravellerRemoved(this.index);

  final int index;

  @override
  List<Object?> get props => [index];
}

/// Fotos del documento con la marca COPIA ya aplicada (sistema existente)
class TravellerWizardDocumentPhotosAdded extends TravellerWizardEvent {
  const TravellerWizardDocumentPhotosAdded({
    required this.index,
    required this.documentType,
    required this.documentNumber,
    this.frontBytes,
    this.backBytes,
  });

  final int index;
  final TravellerDocumentType documentType;
  final String documentNumber;
  final Uint8List? frontBytes;
  final Uint8List? backBytes;

  @override
  List<Object?> get props => [index, documentType, documentNumber, frontBytes, backBytes];
}

/// Firma del parte de entrada de un huésped de 14 años o más
class TravellerWizardSignatureSubmitted extends TravellerWizardEvent {
  const TravellerWizardSignatureSubmitted({
    required this.guestId,
    required this.signatureSvg,
  });

  final String guestId;
  final String signatureSvg;

  @override
  List<Object?> get props => [guestId, signatureSvg];
}

class TravellerWizardSubmitRequested extends TravellerWizardEvent {
  const TravellerWizardSubmitRequested();
}

/// El aviso de error ya se ha mostrado
class TravellerWizardErrorDismissed extends TravellerWizardEvent {
  const TravellerWizardErrorDismissed();
}
