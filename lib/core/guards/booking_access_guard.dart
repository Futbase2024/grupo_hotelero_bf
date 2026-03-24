import '../../features/admin/domain/entities/admin_booking_entity.dart';
import '../enums/enums.dart';

/// Guard que encapsula las reglas de acceso basadas en el estado de la reserva
///
/// Este guard determina qué funcionalidades están disponibles para el huésped
/// según el estado de la reserva, check-in y check-out.
///
/// Reglas principales:
/// - Panel completo SOLO si: checkin_status = validated Y booking_status = active
/// - Si checkin_status ≠ validated: solo pantalla de check-in + subida docs + mensajes admin
/// - Si booking_status = closed: solo histórico + reseña
class BookingAccessGuard {
  const BookingAccessGuard._();

  /// Verifica si el huésped puede acceder al panel completo
  ///
  /// Panel completo incluye:
  /// - Recomendaciones / Qué ver
  /// - Parking
  /// - Chat con admin
  /// - Normas de la casa
  /// - Solicitar check-out
  static bool canAccessFullPanel(AdminBookingEntity booking) {
    return booking.checkinStatusEnum.isValidated &&
        (booking.bookingStatus == BookingStatus.active ||
            booking.bookingStatus == BookingStatus.inHouse);
  }

  /// Verifica si el huésped puede acceder a funcionalidades básicas
  ///
  /// Funcionalidades básicas incluyen:
  /// - Ver progreso del check-in
  /// - Subir documentos
  /// - Ver normas básicas
  static bool canAccessBasicFeatures(AdminBookingEntity booking) {
    return booking.bookingStatus != BookingStatus.cancelled &&
        booking.bookingStatus != BookingStatus.closed;
  }

  /// Verifica si el huésped puede iniciar/editar el check-in
  ///
  /// El check-in se puede editar si:
  /// - No ha empezado (not_started)
  /// - Está en progreso (in_progress)
  /// - Fue rechazado y necesita corrección (rejected)
  static bool canEditCheckin(AdminBookingEntity booking) {
    return booking.checkinStatusEnum.isEditable &&
        booking.bookingStatus != BookingStatus.cancelled &&
        booking.bookingStatus != BookingStatus.closed;
  }

  /// Verifica si el huésped puede solicitar check-out
  ///
  /// El check-out se puede solicitar si:
  /// - El check-in está validado
  /// - La reserva está activa
  /// - No hay check-out en curso
  static bool canRequestCheckout(AdminBookingEntity booking) {
    return booking.canRequestCheckout;
  }

  /// Verifica si el huésped está en modo subsanación
  ///
  /// Modo subsanación: el check-in fue rechazado y necesita corrección
  static bool isInCorrectionMode(AdminBookingEntity booking) {
    return booking.checkinStatusEnum.needsCorrection;
  }

  /// Verifica si la reserva está en modo solo lectura (histórico)
  ///
  /// Modo histórico permite:
  /// - Ver resumen de estancia
  /// - Dejar reseña
  /// - Descargar factura (si aplica)
  static bool isReadOnly(AdminBookingEntity booking) {
    return booking.bookingStatus == BookingStatus.closed;
  }

  /// Verifica si la reserva fue cancelada
  static bool isCancelled(AdminBookingEntity booking) {
    return booking.bookingStatus == BookingStatus.cancelled;
  }

  /// Verifica si el huésped puede usar el chat
  ///
  /// El chat está disponible si:
  /// - El check-in ha empezado (no está en not_started)
  /// - La reserva no está cancelada ni cerrada
  static bool canUseChat(AdminBookingEntity booking) {
    return booking.checkinStatusEnum.hasStarted &&
        booking.bookingStatus != BookingStatus.cancelled &&
        booking.bookingStatus != BookingStatus.closed;
  }

  /// Verifica si el huésped puede ver las normas de la casa
  static bool canViewHouseRules(AdminBookingEntity booking) {
    return booking.bookingStatus != BookingStatus.cancelled;
  }

  /// Verifica si el huésped puede ver las recomendaciones
  static bool canViewRecommendations(AdminBookingEntity booking) {
    return canAccessFullPanel(booking);
  }

  /// Verifica si el huésped puede ver el parking
  static bool canViewParking(AdminBookingEntity booking) {
    return canAccessFullPanel(booking);
  }

  /// Verifica si el huésped puede dejar una reseña
  ///
  /// Solo puede dejar reseña si la reserva está cerrada
  static bool canLeaveReview(AdminBookingEntity booking) {
    return booking.bookingStatus == BookingStatus.closed;
  }

  /// Verifica si el check-in necesita acción del admin
  static bool needsCheckinAction(AdminBookingEntity booking) {
    return booking.checkinStatusEnum.needsAdminAction;
  }

  /// Verifica si el check-out necesita acción del admin
  static bool needsCheckoutAction(AdminBookingEntity booking) {
    return booking.checkoutStatus.needsAdminAction;
  }

  /// Verifica si el check-out tiene incidencias
  static bool hasCheckoutIssues(AdminBookingEntity booking) {
    return booking.checkoutStatus.needsResolution;
  }

  /// Obtiene el mensaje de estado para mostrar al huésped
  static String getStatusMessage(AdminBookingEntity booking) {
    if (booking.bookingStatus == BookingStatus.cancelled) {
      return 'Esta reserva ha sido cancelada';
    }

    if (booking.bookingStatus == BookingStatus.closed) {
      return 'Tu estancia ha finalizado. ¡Gracias por hospedarte con nosotros!';
    }

    if (booking.checkinStatusEnum.needsCorrection) {
      return 'Tu check-in necesita corrección. Por favor, revisa las observaciones y actualiza los datos.';
    }

    if (booking.checkinStatusEnum.needsAdminAction) {
      return 'Tu check-in está siendo revisado. Te notificaremos cuando sea validado.';
    }

    if (booking.checkinStatusEnum.isValidated && booking.bookingStatus == BookingStatus.active) {
      if (booking.checkoutStatus == CheckoutStatus.requested) {
        return 'Tu solicitud de check-out está siendo procesada.';
      }
      return '¡Bienvenido! Tu estancia está activa. Disfruta tu alojamiento.';
    }

    if (booking.bookingStatus == BookingStatus.inHouse) {
      if (booking.checkoutStatus == CheckoutStatus.requested) {
        return 'Tu solicitud de check-out está siendo procesada.';
      }
      return '¡Bienvenido! Disfruta tu estancia.';
    }

    if (booking.checkinStatusEnum == CheckinStatus.inProgress) {
      return 'Por favor, completa tu check-in para acceder a todas las funcionalidades.';
    }

    if (booking.checkinStatusEnum == CheckinStatus.notStarted) {
      return 'Por favor, inicia tu check-in para comenzar.';
    }

    return 'Reserva confirmada. Esperamos tu llegada.';
  }

  /// Obtiene la acción principal sugerida para el huésped
  static GuestAction getSuggestedAction(AdminBookingEntity booking) {
    if (booking.bookingStatus == BookingStatus.cancelled) {
      return GuestAction.none;
    }

    if (booking.bookingStatus == BookingStatus.closed) {
      return GuestAction.leaveReview;
    }

    if (booking.checkinStatusEnum == CheckinStatus.notStarted) {
      return GuestAction.startCheckin;
    }

    if (booking.checkinStatusEnum == CheckinStatus.inProgress) {
      return GuestAction.continueCheckin;
    }

    if (booking.checkinStatusEnum.needsCorrection) {
      return GuestAction.correctCheckin;
    }

    if (booking.checkinStatusEnum.needsAdminAction) {
      return GuestAction.waitCheckinValidation;
    }

    if (booking.checkinStatusEnum.isValidated &&
        (booking.bookingStatus == BookingStatus.active ||
            booking.bookingStatus == BookingStatus.inHouse)) {
      if (booking.checkoutStatus == CheckoutStatus.notStarted && booking.isCheckoutDay) {
        return GuestAction.requestCheckout;
      }
      return GuestAction.explorePanel;
    }

    if (booking.checkoutStatus == CheckoutStatus.requested) {
      return GuestAction.waitCheckoutValidation;
    }

    if (booking.checkoutStatus.needsResolution) {
      return GuestAction.resolveCheckoutIssues;
    }

    return GuestAction.none;
  }
}

/// Acciones que el huésped puede realizar según el estado
enum GuestAction {
  /// Sin acción específica
  none,

  /// Iniciar check-in
  startCheckin,

  /// Continuar check-in
  continueCheckin,

  /// Corregir check-in rechazado
  correctCheckin,

  /// Esperar validación del check-in
  waitCheckinValidation,

  /// Explorar panel completo
  explorePanel,

  /// Solicitar check-out
  requestCheckout,

  /// Esperar validación del check-out
  waitCheckoutValidation,

  /// Resolver incidencias del check-out
  resolveCheckoutIssues,

  /// Dejar reseña
  leaveReview,
}

/// Extensión para obtener información de la acción
extension GuestActionExtension on GuestAction {
  /// Etiqueta de la acción
  String get label {
    return switch (this) {
      GuestAction.none => '',
      GuestAction.startCheckin => 'Iniciar check-in',
      GuestAction.continueCheckin => 'Continuar check-in',
      GuestAction.correctCheckin => 'Corregir check-in',
      GuestAction.waitCheckinValidation => 'Esperando validación',
      GuestAction.explorePanel => 'Explorar',
      GuestAction.requestCheckout => 'Solicitar check-out',
      GuestAction.waitCheckoutValidation => 'Procesando salida',
      GuestAction.resolveCheckoutIssues => 'Resolver incidencias',
      GuestAction.leaveReview => 'Dejar reseña',
    };
  }

  /// Si la acción requiere interacción del usuario
  bool get requiresUserAction {
    return this == GuestAction.startCheckin ||
        this == GuestAction.continueCheckin ||
        this == GuestAction.correctCheckin ||
        this == GuestAction.requestCheckout ||
        this == GuestAction.resolveCheckoutIssues ||
        this == GuestAction.leaveReview ||
        this == GuestAction.explorePanel;
  }
}
