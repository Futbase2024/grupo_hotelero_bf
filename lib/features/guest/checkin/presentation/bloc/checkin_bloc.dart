import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/services/notification_service.dart';
import '../../domain/entities/guest_entity.dart';
import '../../domain/repositories/checkin_repository.dart';
import 'checkin_event.dart';
import 'checkin_state.dart';

/// BLoC para gestionar el flujo de check-in
class CheckinBloc extends Bloc<CheckinEvent, CheckinState> {
  CheckinBloc({
    required CheckinRepository repository,
  })  : _repository = repository,
        super(const CheckinInitial()) {
    on<CheckinStarted>(_onStarted);
    on<CheckinStepChanged>(_onStepChanged);
    on<CheckinGuestAdded>(_onGuestAdded);
    on<CheckinGuestUpdated>(_onGuestUpdated);
    on<CheckinGuestRemoved>(_onGuestRemoved);
    on<CheckinGuestSaved>(_onGuestSaved);
    on<CheckinDocumentUploaded>(_onDocumentUploaded);
    on<CheckinGuestDocumentUpdated>(_onGuestDocumentUpdated);
    on<CheckinSignatureSaved>(_onSignatureSaved);
    on<CheckinSubmitted>(_onSubmitted);
    on<CheckinRetry>(_onRetry);
    on<CheckinRefreshRequested>(_onRefreshRequested);
    on<CheckinStatusCheckRequested>(_onStatusCheckRequested);
  }

  final CheckinRepository _repository;

  Future<void> _onStarted(
    CheckinStarted event,
    Emitter<CheckinState> emit,
  ) async {
    emit(const CheckinLoading());

    try {
      // Cargar datos de la reserva
      final bookingData = await _repository.getBookingForCheckin(event.bookingId);

      // Verificar si el check-in ya está completado
      final checkinStatus = await _repository.getCheckinStatus(event.bookingId);
      if (checkinStatus == CheckinStatus.submitted ||
          checkinStatus == CheckinStatus.validated) {
        debugPrint('✅ [CheckinBloc] Check-in ya completado con estado: $checkinStatus');
        // Cargar huéspedes existentes para mostrarlos
        final existingGuests = await _repository.getBookingGuests(event.bookingId);
        emit(CheckinAlreadyCompleted(
          bookingData: bookingData,
          guests: existingGuests,
          checkinStatus: checkinStatus,
        ));
        return;
      }

      // Cargar huéspedes existentes (si hay check-in guardado)
      final existingGuests = await _repository.getBookingGuests(event.bookingId);

      // Si ya hay huéspedes guardados, usarlos
      if (existingGuests.isNotEmpty) {
        emit(CheckinLoaded(
          bookingData: bookingData,
          guests: existingGuests,
          currentStep: 0,
          completedSteps: {},
        ));
        return;
      }

      // Si no, crear la lista de huéspedes inicial
      final guests = <GuestEntity>[];

      // 1. Buscar datos previos del huésped (primero en profiles, luego en guests)
      DocumentType? docType;
      String? docNumber;
      String? nationality;
      DateTime? birthDate;

      if (bookingData.guestEmail.isNotEmpty) {
        debugPrint('🔍 [CheckinBloc] Buscando datos previos con email: ${bookingData.guestEmail}');

        // Buscar primero en profiles (más rápido y persistente)
        final profile = await _repository.getProfileByEmail(bookingData.guestEmail);
        if (profile != null && profile.hasDocument) {
          debugPrint('✅ [CheckinBloc] Perfil encontrado - DNI: ${profile.documentNumber}');
          docType = _parseDocumentType(profile.documentType);
          docNumber = profile.documentNumber;
          nationality = profile.nationality;
          birthDate = profile.birthDate;
        } else {
          // Si no hay profile, buscar en guests (reservas anteriores)
          debugPrint('🔍 [CheckinBloc] Buscando en huéspedes previos...');
          final existingGuestData = await _repository.findGuestByEmail(bookingData.guestEmail);
          if (existingGuestData != null) {
            debugPrint('✅ [CheckinBloc] Huésped previo encontrado - DNI: ${existingGuestData.documentNumber}');
            docType = existingGuestData.documentType;
            docNumber = existingGuestData.documentNumber;
            nationality = existingGuestData.nationality;
            birthDate = existingGuestData.birthDate;
          } else {
            debugPrint('⚠️ [CheckinBloc] No se encontraron datos previos');
          }
        }
      } else {
        debugPrint('⚠️ [CheckinBloc] Email vacío, no se puede buscar datos previos');
      }

      // 2. Añadir el titular como primer huésped
      // Si tiene datos previos, usar el documento guardado
      guests.add(GuestEntity(
        fullName: '${bookingData.guestFirstName} ${bookingData.guestLastName}'.trim(),
        email: bookingData.guestEmail,
        phone: bookingData.guestPhone,
        type: GuestType.adult,
        isPrimary: true,
        // Pre-poblar datos del documento si existen
        documentType: docType,
        documentNumber: docNumber,
        nationality: nationality,
        birthDate: birthDate,
      ));

      // 3. Añadir placeholders para adultos adicionales
      for (var i = 1; i < bookingData.numAdults; i++) {
        guests.add(GuestEntity(
          fullName: '',
          type: GuestType.adult,
          isPrimary: false,
        ));
      }

      // 4. Añadir placeholders para niños según sus edades
      for (var i = 0; i < bookingData.childrenAges.length; i++) {
        final age = bookingData.childrenAges[i];
        final isUnder14 = age < 14;

        guests.add(GuestEntity(
          fullName: isUnder14 ? 'Niño ${i + 1} ($age años)' : '',
          type: GuestType.child,
          age: age,
          isPrimary: false,
          isReadOnly: isUnder14, // Niños < 14 son readonly
        ));
      }

      emit(CheckinLoaded(
        bookingData: bookingData,
        guests: guests,
        currentStep: 0,
        completedSteps: {},
      ));
    } catch (e) {
      emit(CheckinError(e.toString()));
    }
  }

  void _onStepChanged(
    CheckinStepChanged event,
    Emitter<CheckinState> emit,
  ) {
    final currentState = state;
    if (currentState is CheckinLoaded) {
      emit(currentState.copyWith(currentStep: event.step));
    }
  }

  void _onGuestAdded(
    CheckinGuestAdded event,
    Emitter<CheckinState> emit,
  ) {
    final currentState = state;
    if (currentState is CheckinLoaded) {
      final newGuests = [...currentState.guests, event.guest];
      emit(currentState.copyWith(guests: newGuests));
    }
  }

  void _onGuestUpdated(
    CheckinGuestUpdated event,
    Emitter<CheckinState> emit,
  ) {
    final currentState = state;
    if (currentState is CheckinLoaded) {
      final newGuests = List<GuestEntity>.from(currentState.guests);
      if (event.index >= 0 && event.index < newGuests.length) {
        newGuests[event.index] = event.guest;
        emit(currentState.copyWith(guests: newGuests));
      }
    }
  }

  void _onGuestRemoved(
    CheckinGuestRemoved event,
    Emitter<CheckinState> emit,
  ) {
    final currentState = state;
    if (currentState is CheckinLoaded) {
      final newGuests = List<GuestEntity>.from(currentState.guests);
      if (event.index >= 0 && event.index < newGuests.length) {
        // No se puede eliminar el titular
        if (!newGuests[event.index].isPrimary) {
          newGuests.removeAt(event.index);
          emit(currentState.copyWith(guests: newGuests));
        }
      }
    }
  }

  Future<void> _onGuestSaved(
    CheckinGuestSaved event,
    Emitter<CheckinState> emit,
  ) async {
    final currentState = state;
    if (currentState is CheckinLoaded) {
      try {
        // Guardar en la base de datos
        final savedGuest = await _repository.saveGuest(
          bookingId: currentState.bookingData.bookingId,
          guest: event.guest,
        );

        // Actualizar la lista local
        final newGuests = List<GuestEntity>.from(currentState.guests);
        if (event.index >= 0 && event.index < newGuests.length) {
          newGuests[event.index] = savedGuest;
        }

        emit(currentState.copyWith(guests: newGuests));
      } catch (e) {
        emit(CheckinError('Error al guardar huésped: $e'));
      }
    }
  }

  Future<void> _onDocumentUploaded(
    CheckinDocumentUploaded event,
    Emitter<CheckinState> emit,
  ) async {
    final currentState = state;
    if (currentState is CheckinLoaded) {
      try {
        final guest = currentState.guests[event.guestIndex];

        // Subir documento
        await _repository.uploadDocument(
          bookingId: currentState.bookingData.bookingId,
          guestId: guest.id ?? '',
          docKind: event.docKind,
          bytes: event.bytes,
          mimeType: event.mimeType,
        );

        // Aquí podrías actualizar el estado del documento en el huésped
        // Por ahora solo confirmamos la subida
      } catch (e) {
        emit(CheckinError('Error al subir documento: $e'));
      }
    }
  }

  /// Actualiza el documento del huésped (tipo, número e imagen)
  Future<void> _onGuestDocumentUpdated(
    CheckinGuestDocumentUpdated event,
    Emitter<CheckinState> emit,
  ) async {
    final currentState = state;
    if (currentState is CheckinLoaded) {
      try {
        var guest = currentState.guests[event.guestIndex];

        // Actualizar el huésped con los datos del documento primero
        guest = guest.copyWith(
          documentType: event.documentType,
          documentNumber: event.documentNumber,
        );

        // Si el huésped no tiene ID, guardarlo primero para obtener uno
        if (guest.id == null) {
          debugPrint('💾 [CheckinBloc] Guardando huésped antes de subir documento...');
          guest = await _repository.saveGuest(
            bookingId: currentState.bookingData.bookingId,
            guest: guest,
          );
          debugPrint('✅ [CheckinBloc] Huésped guardado con ID: ${guest.id}');
        }

        // Si hay imagen, subirla al storage
        bool hasImage = false;
        if (event.imageBytes != null && guest.id != null) {
          debugPrint('📤 [CheckinBloc] Subiendo documento al storage...');
          await _repository.uploadDocument(
            bookingId: currentState.bookingData.bookingId,
            guestId: guest.id!,
            docKind: event.documentType.dbValue,
            bytes: event.imageBytes!,
            mimeType: 'image/jpeg',
          );
          hasImage = true;
          debugPrint('✅ [CheckinBloc] Documento subido correctamente');
        } else {
          debugPrint('⚠️ [CheckinBloc] No se puede subir documento: imageBytes=${event.imageBytes != null}, guestId=${guest.id}');
        }

        // Actualizar el huésped con el flag de imagen
        guest = guest.copyWith(hasDocumentImage: hasImage);

        // Actualizar la lista de huéspedes
        final newGuests = List<GuestEntity>.from(currentState.guests);
        newGuests[event.guestIndex] = guest;

        emit(currentState.copyWith(guests: newGuests));
      } catch (e, s) {
        debugPrint('❌ [CheckinBloc] Error al actualizar documento: $e');
        debugPrint('❌ [CheckinBloc] StackTrace: $s');
        emit(CheckinError('Error al actualizar documento: $e'));
      }
    }
  }

  void _onSignatureSaved(
    CheckinSignatureSaved event,
    Emitter<CheckinState> emit,
  ) {
    final currentState = state;
    if (currentState is CheckinLoaded) {
      emit(currentState.copyWith(signatureSvg: event.signatureSvg));
    }
  }

  Future<void> _onSubmitted(
    CheckinSubmitted event,
    Emitter<CheckinState> emit,
  ) async {
    final currentState = state;
    if (currentState is CheckinLoaded) {
      // Validar firma
      if (currentState.signatureSvg == null) {
        emit(const CheckinError('Falta la firma del titular'));
        return;
      }

      // Validar que todos los huéspedes que necesitan documento tengan foto
      for (var i = 0; i < currentState.guests.length; i++) {
        final guest = currentState.guests[i];
        if (guest.needsDocument && !guest.isReadOnly) {
          if (guest.documentNumber == null || guest.documentNumber!.isEmpty) {
            emit(CheckinError('Falta el documento de ${guest.fullName.isEmpty ? "huésped ${i + 1}" : guest.fullName}'));
            return;
          }
          if (!guest.hasDocumentImage) {
            emit(CheckinError('Falta la foto del documento de ${guest.fullName.isEmpty ? "huésped ${i + 1}" : guest.fullName}'));
            return;
          }
        }
      }

      emit(const CheckinSubmitting());

      try {
        // Guardar todos los huéspedes primero
        for (var i = 0; i < currentState.guests.length; i++) {
          final guest = currentState.guests[i];
          if (!guest.isReadOnly) {
            await _repository.saveGuest(
              bookingId: currentState.bookingData.bookingId,
              guest: guest,
            );
          }
        }

        // Guardar el perfil del titular para futuras reservas
        final primaryGuest = currentState.guests.firstWhere(
          (g) => g.isPrimary,
          orElse: () => currentState.guests.first,
        );
        if (primaryGuest.email != null && primaryGuest.email!.isNotEmpty && primaryGuest.documentNumber != null) {
          debugPrint('💾 [CheckinBloc] Guardando perfil del titular...');
          await _repository.saveProfile(ProfileData(
            email: primaryGuest.email!,
            fullName: primaryGuest.fullName,
            phone: primaryGuest.phone,
            documentType: primaryGuest.documentType?.dbValue,
            documentNumber: primaryGuest.documentNumber,
            nationality: primaryGuest.nationality,
            birthDate: primaryGuest.birthDate,
          ));
        }

        // Enviar el check-in
        await _repository.submitCheckin(
          bookingId: currentState.bookingData.bookingId,
          signatureSvg: currentState.signatureSvg!,
        );

        // Notificar al admin del nuevo check-in pendiente
        if (currentState.bookingData.propertyId.isNotEmpty) {
          debugPrint('📬 [CheckinBloc] Notificando al admin...');
          await NotificationService().notifyAdminCheckinSubmitted(
            bookingId: currentState.bookingData.bookingId,
            propertyId: currentState.bookingData.propertyId,
            guestName: currentState.bookingData.guestFullName,
            unitName: currentState.bookingData.unitName,
          );
          debugPrint('✅ [CheckinBloc] Admin notificado');

          // Enviar email de notificación de check-in completado
          debugPrint('📧 [CheckinBloc] Enviando email de notificación...');
          await NotificationService().sendCheckinCompletedEmail(
            bookingId: currentState.bookingData.bookingId,
            guestName: currentState.bookingData.guestFullName,
            propertyName: currentState.bookingData.propertyName,
            bookingCode: currentState.bookingData.bookingCode,
            checkInDate: currentState.bookingData.checkInDate,
            checkOutDate: currentState.bookingData.checkOutDate,
          );
          debugPrint('✅ [CheckinBloc] Email de notificación enviado');
        }

        emit(const CheckinSuccess());
      } catch (e) {
        emit(CheckinError('Error al enviar check-in: $e'));
      }
    }
  }

  void _onRetry(
    CheckinRetry event,
    Emitter<CheckinState> emit,
  ) {
    // Volver al estado anterior si hay error
    if (state is CheckinError) {
      emit(const CheckinInitial());
    }
  }

  /// Convierte string a DocumentType
  DocumentType? _parseDocumentType(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase()) {
      case 'dni':
      case 'dni_front':
        return DocumentType.dniFront;
      case 'dni_back':
        return DocumentType.dniBack;
      case 'nie':
        // NIE se trata como DNI front
        return DocumentType.dniFront;
      case 'passport':
        return DocumentType.passport;
      case 'other':
        return DocumentType.other;
      default:
        return null;
    }
  }

  /// Maneja el evento de refresh (pull-to-refresh)
  Future<void> _onRefreshRequested(
    CheckinRefreshRequested event,
    Emitter<CheckinState> emit,
  ) async {
    debugPrint('🔄 [CheckinBloc] Refresh solicitado...');
    final currentState = state;

    if (currentState is CheckinAlreadyCompleted) {
      // Si estamos en estado completado, recargar el estado del check-in
      final bookingData = await _repository.getBookingForCheckin(event.bookingId);
      final existingGuests = await _repository.getBookingGuests(event.bookingId);
      final newStatus = await _repository.getCheckinStatus(event.bookingId);

      emit(CheckinAlreadyCompleted(
        bookingData: bookingData,
        guests: existingGuests,
        checkinStatus: newStatus,
      ));
      debugPrint('✅ [CheckinBloc] Estado actualizado: $newStatus');
    } else if (currentState is CheckinLoaded) {
      // Si estamos en el flujo de check-in, recargar datos sin perder el progreso
      final bookingData = await _repository.getBookingForCheckin(event.bookingId);
      final existingGuests = await _repository.getBookingGuests(event.bookingId);

      emit(currentState.copyWith(
        bookingData: bookingData,
        guests: existingGuests,
      ));
      debugPrint('✅ [CheckinBloc] Datos refrescados');
    }
  }

  /// Maneja el evento de verificación de estado (desde Realtime o notificación)
  Future<void> _onStatusCheckRequested(
    CheckinStatusCheckRequested event,
    Emitter<CheckinState> emit,
  ) async {
    debugPrint('🔄 [CheckinBloc] Verificando estado del check-in...');
    final currentStatus = await _repository.getCheckinStatus(event.bookingId);

    final currentState = state;

    if (currentStatus == CheckinStatus.validated && currentState is CheckinAlreadyCompleted) {
      // Si cambió a validado, recargar y mostrar la vista actualizada
      final bookingData = await _repository.getBookingForCheckin(event.bookingId);
      final existingGuests = await _repository.getBookingGuests(event.bookingId);

      emit(CheckinAlreadyCompleted(
        bookingData: bookingData,
        guests: existingGuests,
        checkinStatus: CheckinStatus.validated,
      ));
      debugPrint('✅ [CheckinBloc] Check-in validado!');
    } else if (currentStatus == CheckinStatus.rejected && currentState is CheckinAlreadyCompleted) {
      // Si fue rechazado, mostrar error
      emit(const CheckinError('Tu check-in ha sido rechazado. Por favor, contacta con recepción.'));
    }
  }
}
