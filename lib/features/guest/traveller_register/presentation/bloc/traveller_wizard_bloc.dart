import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../checkin/domain/repositories/checkin_repository.dart';
import '../../domain/entities/traveller_entity.dart';
import '../../domain/repositories/traveller_register_repository.dart';
import '../../domain/validators/traveller_form_rules.dart';
import 'traveller_wizard_event.dart';
import 'traveller_wizard_state.dart';

/// Wizard del registro de viajeros (RD 933/2021): identificación →
/// residencia y contacto → revisión y firma.
///
/// Los datos se guardan en el servidor al avanzar de pantalla; el servidor
/// valida de nuevo y decide qué falta (`traveller_register_issues`).
class TravellerWizardBloc extends Bloc<TravellerWizardEvent, TravellerWizardState> {
  TravellerWizardBloc({
    required TravellerRegisterRepository repository,
    required CheckinRepository checkinRepository,
  })  : _repository = repository,
        _checkinRepository = checkinRepository,
        super(const TravellerWizardState()) {
    on<TravellerWizardStarted>(_onStarted);
    on<TravellerWizardStepRequested>(_onStepRequested);
    on<TravellerWizardTravellerSelected>(_onSelected);
    on<TravellerWizardTravellerChanged>(_onChanged);
    on<TravellerWizardTravellerAdded>(_onAdded);
    on<TravellerWizardTravellerRemoved>(_onRemoved);
    on<TravellerWizardDocumentPhotosAdded>(_onPhotosAdded);
    on<TravellerWizardSignatureSubmitted>(_onSignature);
    on<TravellerWizardSubmitRequested>(_onSubmit);
    on<TravellerWizardErrorDismissed>(
      (event, emit) => emit(state.copyWith(clearError: true)),
    );
  }

  final TravellerRegisterRepository _repository;
  final CheckinRepository _checkinRepository;

  Future<void> _onStarted(
    TravellerWizardStarted event,
    Emitter<TravellerWizardState> emit,
  ) async {
    final booking = event.booking;
    emit(state.copyWith(
      status: TravellerWizardStatus.loading,
      bookingId: booking.bookingId,
      checkinDate: booking.checkInDate,
      maxGuests: booking.totalGuests < 1 ? 1 : booking.totalGuests,
    ));

    try {
      var travellers = await _repository.getTravellers(booking.bookingId);
      if (travellers.isEmpty) {
        // Primer huésped: el titular, con lo que ya sabemos de la reserva
        travellers = [
          TravellerEntity(
            firstName: booking.guestFirstName,
            lastName1: booking.guestLastName,
            email: booking.guestEmail,
            mobile: booking.guestPhone ?? '',
            isPrimary: true,
          ),
        ];
      }
      final registerStatus = await _repository.getStatus(booking.bookingId);

      emit(state.copyWith(
        status: TravellerWizardStatus.ready,
        travellers: travellers,
        registerStatus: registerStatus,
        maxGuests: travellers.length > state.maxGuests
            ? travellers.length
            : state.maxGuests,
      ));
    } catch (e) {
      debugPrint('❌ [TravellerWizard] Error cargando: $e');
      emit(state.copyWith(
        status: TravellerWizardStatus.failure,
        errorCode: _codeOf(e),
      ));
    }
  }

  Future<void> _onStepRequested(
    TravellerWizardStepRequested event,
    Emitter<TravellerWizardState> emit,
  ) async {
    final target = event.step.clamp(0, TravellerWizardState.stepCount - 1);
    if (target == state.step || state.isBusy) return;

    if (target < state.step) {
      emit(state.copyWith(step: target, selectedIndex: 0, showErrors: false));
      return;
    }

    // Hacia delante: cada pantalla intermedia tiene que estar completa
    for (var step = state.step; step < target; step++) {
      final firstWithErrors = _firstIndexWithErrors(step);
      if (firstWithErrors != null) {
        emit(state.copyWith(
          step: step,
          selectedIndex: firstWithErrors,
          showErrors: true,
        ));
        return;
      }
    }

    emit(state.copyWith(isBusy: true));
    try {
      final travellers = await _saveAll();
      final registerStatus = await _repository.getStatus(state.bookingId);
      emit(state.copyWith(
        step: target,
        selectedIndex: 0,
        travellers: travellers,
        registerStatus: registerStatus,
        showErrors: false,
        isBusy: false,
      ));
    } catch (e) {
      debugPrint('❌ [TravellerWizard] Error guardando: $e');
      emit(state.copyWith(isBusy: false, errorCode: _codeOf(e)));
    }
  }

  void _onSelected(
    TravellerWizardTravellerSelected event,
    Emitter<TravellerWizardState> emit,
  ) {
    if (event.index < 0 || event.index >= state.travellers.length) return;
    emit(state.copyWith(selectedIndex: event.index));
  }

  void _onChanged(
    TravellerWizardTravellerChanged event,
    Emitter<TravellerWizardState> emit,
  ) {
    if (event.index < 0 || event.index >= state.travellers.length) return;
    final travellers = List<TravellerEntity>.from(state.travellers);
    travellers[event.index] = event.traveller;
    emit(state.copyWith(travellers: travellers));
  }

  void _onAdded(
    TravellerWizardTravellerAdded event,
    Emitter<TravellerWizardState> emit,
  ) {
    if (!state.canAddTraveller) return;
    final travellers = [...state.travellers, const TravellerEntity()];
    emit(state.copyWith(
      travellers: travellers,
      selectedIndex: travellers.length - 1,
      showErrors: false,
    ));
  }

  void _onRemoved(
    TravellerWizardTravellerRemoved event,
    Emitter<TravellerWizardState> emit,
  ) {
    // Solo se pueden quitar huéspedes que aún no están guardados: borrar uno
    // guardado (y quizá ya firmado) lo hace el staff
    if (event.index < 0 || event.index >= state.travellers.length) return;
    if (state.travellers[event.index].id != null) return;
    if (state.travellers.length <= 1) return;

    final travellers = List<TravellerEntity>.from(state.travellers)
      ..removeAt(event.index);
    emit(state.copyWith(
      travellers: travellers,
      selectedIndex: event.index >= travellers.length
          ? travellers.length - 1
          : event.index,
    ));
  }

  Future<void> _onPhotosAdded(
    TravellerWizardDocumentPhotosAdded event,
    Emitter<TravellerWizardState> emit,
  ) async {
    if (event.index < 0 || event.index >= state.travellers.length) return;
    emit(state.copyWith(isBusy: true));

    try {
      var traveller = state.travellers[event.index].copyWith(
        documentType: event.documentType,
        documentNumber: event.documentNumber,
      );

      // Las fotos se asocian al huésped: hace falta que exista en el servidor
      final guestId = await _repository.saveTraveller(
        bookingId: state.bookingId,
        traveller: traveller,
      );
      traveller = traveller.copyWith(id: guestId);

      final frontKind = _frontDocKind(event.documentType);
      final backKind = _backDocKind(event.documentType);

      if (event.frontBytes != null) {
        await _checkinRepository.uploadDocument(
          bookingId: state.bookingId,
          guestId: guestId,
          docKind: frontKind,
          bytes: event.frontBytes!,
          mimeType: 'image/jpeg',
        );
      }
      if (event.backBytes != null && backKind != null) {
        await _checkinRepository.uploadDocument(
          bookingId: state.bookingId,
          guestId: guestId,
          docKind: backKind,
          bytes: event.backBytes!,
          mimeType: 'image/jpeg',
        );
      }
      // Igual que el flujo de fotos: al cambiar de tipo de documento se
      // retiran las caras que ya no corresponden
      if (event.frontBytes != null) {
        await _checkinRepository.deleteObsoleteDocuments(
          bookingId: state.bookingId,
          guestId: guestId,
          keepDocKinds: [frontKind, ?backKind],
        );
      }

      final travellers = List<TravellerEntity>.from(state.travellers);
      travellers[event.index] = traveller;
      emit(state.copyWith(
        travellers: travellers,
        isBusy: false,
        guestIdsWithPhotos: {...state.guestIdsWithPhotos, guestId},
      ));
    } catch (e) {
      debugPrint('❌ [TravellerWizard] Error subiendo fotos: $e');
      emit(state.copyWith(isBusy: false, errorCode: _codeOf(e)));
    }
  }

  Future<void> _onSignature(
    TravellerWizardSignatureSubmitted event,
    Emitter<TravellerWizardState> emit,
  ) async {
    if (state.isBusy) return;
    emit(state.copyWith(isBusy: true));
    try {
      await _repository.signEntryForm(
        bookingId: state.bookingId,
        guestId: event.guestId,
        signatureSvg: event.signatureSvg,
      );
      final registerStatus = await _repository.getStatus(state.bookingId);
      emit(state.copyWith(isBusy: false, registerStatus: registerStatus));
    } catch (e) {
      debugPrint('❌ [TravellerWizard] Error firmando: $e');
      emit(state.copyWith(isBusy: false, errorCode: _codeOf(e)));
    }
  }

  Future<void> _onSubmit(
    TravellerWizardSubmitRequested event,
    Emitter<TravellerWizardState> emit,
  ) async {
    if (state.isBusy) return;
    emit(state.copyWith(isBusy: true));
    try {
      await _repository.submit(state.bookingId);
      emit(state.copyWith(isBusy: false, status: TravellerWizardStatus.submitted));
    } catch (e) {
      debugPrint('❌ [TravellerWizard] Error enviando: $e');
      // Puede que algo haya cambiado: se refresca qué falta
      TravellerWizardState next = state.copyWith(isBusy: false, errorCode: _codeOf(e));
      try {
        next = next.copyWith(registerStatus: await _repository.getStatus(state.bookingId));
      } catch (_) {}
      emit(next);
    }
  }

  /// Guarda todos los huéspedes (primero los que no dependen de otro) y
  /// devuelve la lista tal como queda en el servidor (normalizada).
  Future<List<TravellerEntity>> _saveAll() async {
    final ordered = [
      ...state.travellers.where((t) => t.responsibleGuestId == null),
      ...state.travellers.where((t) => t.responsibleGuestId != null),
    ];
    for (final traveller in ordered) {
      await _repository.saveTraveller(
        bookingId: state.bookingId,
        traveller: traveller,
      );
    }
    return _repository.getTravellers(state.bookingId);
  }

  int? _firstIndexWithErrors(int step) {
    for (var i = 0; i < state.travellers.length; i++) {
      final traveller = state.travellers[i];
      final errors = step == 0
          ? TravellerFormRules.identification(traveller, state.effectiveCheckinDate)
          : TravellerFormRules.residenceAndContact(
              traveller,
              state.effectiveCheckinDate,
              state.travellers,
            );
      if (errors.isNotEmpty) return i;
    }
    return null;
  }

  /// `doc_kind` de `guest_documents` (mismos valores que el flujo de fotos)
  static String _frontDocKind(TravellerDocumentType type) {
    switch (type) {
      case TravellerDocumentType.dni:
      case TravellerDocumentType.nie:
        return 'dni_front';
      case TravellerDocumentType.passport:
        return 'passport';
      case TravellerDocumentType.other:
        return 'other';
    }
  }

  static String? _backDocKind(TravellerDocumentType type) =>
      type == TravellerDocumentType.passport ? null : 'dni_back';

  static String _codeOf(Object error) =>
      error is TravellerRegisterException ? error.code : 'unknown';
}
