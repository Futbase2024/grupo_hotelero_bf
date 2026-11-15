import 'package:equatable/equatable.dart';

import '../../domain/entities/traveller_entity.dart';
import '../../domain/entities/traveller_register_status.dart';
import '../../domain/validators/traveller_form_rules.dart';

enum TravellerWizardStatus { loading, ready, failure, submitted }

class TravellerWizardState extends Equatable {
  const TravellerWizardState({
    this.status = TravellerWizardStatus.loading,
    this.bookingId = '',
    this.checkinDate,
    this.maxGuests = 1,
    this.step = 0,
    this.selectedIndex = 0,
    this.travellers = const [],
    this.registerStatus,
    this.showErrors = false,
    this.isBusy = false,
    this.errorCode,
    this.guestIdsWithPhotos = const {},
  });

  /// Pantallas: 0 identificación · 1 residencia y contacto · 2 revisión y firma
  static const int stepCount = 3;

  final TravellerWizardStatus status;
  final String bookingId;

  /// Fecha de entrada: la edad legal se calcula con ella
  final DateTime? checkinDate;

  /// Huéspedes previstos en la reserva (tope para añadir)
  final int maxGuests;
  final int step;
  final int selectedIndex;
  final List<TravellerEntity> travellers;

  /// Respuesta del servidor (qué falta y quién firma)
  final TravellerRegisterStatus? registerStatus;

  /// Se marcan los errores en el formulario tras intentar avanzar
  final bool showErrors;

  /// Guardando, firmando o enviando
  final bool isBusy;

  /// Error pendiente de mostrar (código del servidor o local)
  final String? errorCode;

  /// Huéspedes a los que se han subido fotos en esta sesión
  final Set<String> guestIdsWithPhotos;

  DateTime get effectiveCheckinDate => checkinDate ?? DateTime.now();

  TravellerEntity? get selected =>
      selectedIndex < travellers.length ? travellers[selectedIndex] : null;

  bool get canAddTraveller => travellers.length < maxGuests;

  Map<String, TravellerFieldError> errorsFor(int index) {
    if (index >= travellers.length) return const {};
    final traveller = travellers[index];
    return step == 0
        ? TravellerFormRules.identification(traveller, effectiveCheckinDate)
        : TravellerFormRules.residenceAndContact(
            traveller,
            effectiveCheckinDate,
            travellers,
          );
  }

  bool hasErrorsAt(int index) => errorsFor(index).isNotEmpty;

  TravellerWizardState copyWith({
    TravellerWizardStatus? status,
    String? bookingId,
    DateTime? checkinDate,
    int? maxGuests,
    int? step,
    int? selectedIndex,
    List<TravellerEntity>? travellers,
    TravellerRegisterStatus? registerStatus,
    bool? showErrors,
    bool? isBusy,
    String? errorCode,
    bool clearError = false,
    Set<String>? guestIdsWithPhotos,
  }) {
    return TravellerWizardState(
      status: status ?? this.status,
      bookingId: bookingId ?? this.bookingId,
      checkinDate: checkinDate ?? this.checkinDate,
      maxGuests: maxGuests ?? this.maxGuests,
      step: step ?? this.step,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      travellers: travellers ?? this.travellers,
      registerStatus: registerStatus ?? this.registerStatus,
      showErrors: showErrors ?? this.showErrors,
      isBusy: isBusy ?? this.isBusy,
      errorCode: clearError ? null : errorCode ?? this.errorCode,
      guestIdsWithPhotos: guestIdsWithPhotos ?? this.guestIdsWithPhotos,
    );
  }

  @override
  List<Object?> get props => [
        status,
        bookingId,
        checkinDate,
        maxGuests,
        step,
        selectedIndex,
        travellers,
        registerStatus,
        showErrors,
        isBusy,
        errorCode,
        guestIdsWithPhotos,
      ];
}
