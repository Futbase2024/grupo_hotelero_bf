import 'package:equatable/equatable.dart';
import '../../domain/entities/guest_entity.dart';
import '../../domain/repositories/checkin_repository.dart';

/// Estados del BLoC de check-in
abstract class CheckinState extends Equatable {
  const CheckinState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class CheckinInitial extends CheckinState {
  const CheckinInitial();
}

/// Cargando datos de la reserva
class CheckinLoading extends CheckinState {
  const CheckinLoading();
}

/// Datos cargados y listos para el check-in
class CheckinLoaded extends CheckinState {
  const CheckinLoaded({
    required this.bookingData,
    required this.guests,
    required this.currentStep,
    required this.completedSteps,
    this.signatureSvg,
    this.isSubmitting = false,
  });

  /// Datos de la reserva
  final CheckinBookingData bookingData;

  /// Lista de huéspedes (incluye placeholders para niños < 14)
  final List<GuestEntity> guests;

  /// Paso actual del stepper (0-3)
  final int currentStep;

  /// Pasos completados
  final Set<int> completedSteps;

  /// Firma del titular (SVG)
  final String? signatureSvg;

  /// Si se está enviando el check-in
  final bool isSubmitting;

  /// Total de huéspedes
  int get totalGuests => guests.length;

  /// Huéspedes que requieren documento
  List<GuestEntity> get guestsRequiringDocument =>
      guests.where((g) => g.needsDocument).toList();

  /// Huéspedes que NO requieren documento (niños < 14)
  List<GuestEntity> get guestsNotRequiringDocument =>
      guests.where((g) => !g.needsDocument).toList();

  /// Huéspedes que tienen documento subido
  List<GuestEntity> get guestsWithDocument =>
      guests.where((g) => g.needsDocument && g.documentNumber != null && g.documentNumber!.isNotEmpty).toList();

  /// Huéspedes pendientes de documento
  List<GuestEntity> get guestsPendingDocument =>
      guests.where((g) => g.needsDocument && (g.documentNumber == null || g.documentNumber!.isEmpty)).toList();

  /// Si todos los huéspedes que requieren documento lo tienen
  bool get allDocumentsComplete => guestsPendingDocument.isEmpty;

  /// Si todos los huéspedes tienen nombre
  bool get allGuestsHaveName => guests.every((g) => g.fullName.trim().isNotEmpty || g.isReadOnly);

  /// Si el paso actual está completo
  bool get isCurrentStepComplete {
    switch (currentStep) {
      case 0: // Huéspedes
        return allGuestsHaveName;
      case 1: // Documentos
        return allDocumentsComplete;
      case 2: // Firma
        return signatureSvg != null && signatureSvg!.isNotEmpty;
      case 3: // Confirmar
        return true;
      default:
        return false;
    }
  }

  /// Si se puede enviar el check-in
  bool get canSubmit =>
      allGuestsHaveName &&
      allDocumentsComplete &&
      signatureSvg != null &&
      signatureSvg!.isNotEmpty;

  CheckinLoaded copyWith({
    CheckinBookingData? bookingData,
    List<GuestEntity>? guests,
    int? currentStep,
    Set<int>? completedSteps,
    String? signatureSvg,
    bool? isSubmitting,
  }) {
    return CheckinLoaded(
      bookingData: bookingData ?? this.bookingData,
      guests: guests ?? this.guests,
      currentStep: currentStep ?? this.currentStep,
      completedSteps: completedSteps ?? this.completedSteps,
      signatureSvg: signatureSvg ?? this.signatureSvg,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  @override
  List<Object?> get props => [
        bookingData,
        guests,
        currentStep,
        completedSteps,
        signatureSvg,
        isSubmitting,
      ];
}

/// Enviando check-in
class CheckinSubmitting extends CheckinState {
  const CheckinSubmitting();
}

/// Check-in enviado correctamente
class CheckinSuccess extends CheckinState {
  const CheckinSuccess();
}

/// Error en el check-in
class CheckinError extends CheckinState {
  const CheckinError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Check-in ya completado anteriormente
class CheckinAlreadyCompleted extends CheckinState {
  const CheckinAlreadyCompleted({
    required this.bookingData,
    required this.guests,
    required this.checkinStatus,
  });

  final CheckinBookingData bookingData;
  final List<GuestEntity> guests;
  final CheckinStatus checkinStatus;

  /// Si el check-in está validado por el staff
  bool get isValidated => checkinStatus == CheckinStatus.validated;

  /// Si el check-in está enviado pero pendiente de validación
  bool get isPending => checkinStatus == CheckinStatus.submitted;

  /// Mensaje descriptivo del estado
  String get statusMessage {
    switch (checkinStatus) {
      case CheckinStatus.submitted:
        return 'Check-in enviado. Pendiente de validación.';
      case CheckinStatus.validated:
        return 'Check-in validado correctamente.';
      case CheckinStatus.rejected:
        return 'Check-in rechazado. Contacte con recepción.';
      default:
        return 'Check-in completado.';
    }
  }

  @override
  List<Object?> get props => [bookingData, guests, checkinStatus];
}
