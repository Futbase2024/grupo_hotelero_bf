import '../entities/admin_entities.dart';

/// Contrato del repositorio del panel de administración.
/// Todas las operaciones van a través de Edge Functions de Supabase.
abstract class AdminPanelRepository {
  /// Obtiene el resumen del dashboard
  Future<DashboardSummaryEntity> getDashboardSummary({
    String? propertyId,
  });

  /// Lista reservas con filtros opcionales.
  ///
  /// [checkinStatusFilter] filtra en el servidor por el estado del check-in
  /// asociado (`submitted`, `draft`, `validated`, `rejected`). Al usarlo, solo
  /// se devuelven reservas CON check-in en ese estado (join interno), lo que
  /// reduce drásticamente el volumen de la consulta del tab de check-ins.
  ///
  /// [lightweight] pide solo las columnas que necesitan los LISTADOS del panel
  /// (reservas y check-ins). Con él NO vienen `guestEmail`, `guestPhone`,
  /// `staffNotes`, `codeSentAt`, `codeFirstUsedAt` ni `createdAt`: quien los
  /// use (facturas, ocupación, detalle) debe llamar sin este flag.
  Future<List<AdminBookingEntity>> listBookings({
    String? propertyId,
    String? statusFilter,
    DateTime? fromDate,
    DateTime? toDate,
    String? searchQuery,
    String? checkinStatusFilter,
    bool lightweight = false,
  });

  /// Obtiene una reserva por ID
  Future<AdminBookingEntity?> getBooking(String bookingId);

  /// Crea una nueva reserva
  /// Retorna el código BF generado y el estado del envío de email
  /// [unitIds] Lista de IDs de unidades/habitaciones (soporte multi-unidad, 1-9 habitaciones)
  Future<CreateBookingResult> createBooking({
    required List<String> unitIds,
    required String guestFirstName,
    required String guestLastName,
    required String guestEmail,
    String? guestPhone,
    required DateTime checkInDate,
    required DateTime checkOutDate,
    required int numGuests,
    int numAdults = 1,
    int numChildren = 0,
    List<int> childrenAges = const [],
    String? staffNotes,
    String? propertyId,
  });

  /// Regenera el código de una reserva
  Future<String> regenerateCode(String bookingId);

  /// Reenvía el email con el código al huésped
  Future<ResendCodeResult> resendCode(String bookingId);

  /// Valida un check-in
  Future<void> validateCheckin({
    required String checkinId,
    required String bookingId,
  });

  /// Rechaza un check-in con motivo
  Future<void> rejectCheckin({
    required String checkinId,
    required String bookingId,
    String? reason,
  });

  /// Cancela un check-in con motivo
  /// A diferencia del rechazo, la cancelación NO permite corrección por el huésped
  Future<void> cancelCheckin({
    required String checkinId,
    required String bookingId,
    String? reason,
  });

  /// Valida un check-in manualmente sin datos del huésped
  /// Útil cuando el check-in se ha hecho offline o en recepción
  /// Si no existe check-in, lo crea directamente en estado validated
  /// Retorna el ID del check-in creado/actualizado
  Future<String> manualCheckinValidate(String bookingId);

  /// Obtiene el detalle completo de un check-in
  /// Incluye huéspedes, documentos y firma
  Future<CheckinDetailEntity> getCheckinDetail(String checkinId);

  /// Obtiene la URL firmada para ver un documento
  Future<String> getDocumentUrl(String storagePath);

  // ==================== MÉTODOS DE CHECK-OUT ====================

  /// Valida el check-out de una reserva
  /// Esto marca checkout_status = validated y booking_status = closed
  Future<void> validateCheckout({
    required String bookingId,
    String? notes,
  });

  /// Rechaza el check-out con motivo (incidencias)
  /// El huésped deberá resolver las incidencias y volver a solicitar
  Future<void> rejectCheckout({
    required String bookingId,
    required String reason,
  });

  /// Cierra una reserva manualmente
  /// Útil para cerrar reservas sin check-out solicitado
  Future<void> closeBooking({
    required String bookingId,
    String? notes,
  });

  /// Cancela una reserva
  Future<void> cancelBooking({
    required String bookingId,
    String? reason,
  });

  /// Elimina completamente una reserva y todos sus datos relacionados
  /// Solo funciona si la reserva NO está en estado checked_out, closed o in_house
  /// Retorna la lista de paths de storage que deben eliminarse desde el cliente
  Future<List<String>> deleteBooking({
    required String bookingId,
  });

  // ==================== MÉTODOS DE UNIDADES ====================

  /// Lista unidades de una propiedad
  Future<List<AdminUnitEntity>> listUnits(String propertyId);

  /// Lista unidades con disponibilidad para un rango de fechas
  /// Si propertyId es null, carga todas las unidades de todas las propiedades
  Future<List<UnitWithAvailability>> listUnitsWithAvailability({
    String? propertyId,
    DateTime? checkInDate,
    DateTime? checkOutDate,
  });

  /// Actualiza los datos de WiFi de una unidad
  Future<void> updateUnitWifi({
    required String unitId,
    required String wifiNetwork,
    required String wifiPassword,
  });

  /// Actualiza el código de caja (keybox) de una unidad
  Future<void> updateUnitBoxCode({
    required String unitId,
    required String boxCode,
  });

  /// Actualiza el código de la puerta principal de una propiedad
  Future<void> updatePropertyMainDoorKeycode({
    required String propertyId,
    required String keycode,
  });

  /// Actualiza el código KeyBox de una reserva
  Future<void> updateBookingKeyboxCode({
    required String bookingId,
    required String keyboxCode,
  });

  /// Actualiza el teléfono del huésped de una reserva
  Future<void> updateBookingGuestPhone({
    required String bookingId,
    required String guestPhone,
  });

  /// Marca que el early check-in está disponible para una reserva
  /// Esto actualiza early_checkin_available_at con el timestamp actual
  Future<void> setEarlyCheckinAvailable({
    required String bookingId,
  });

  /// Obtiene notificaciones
  Future<List<StaffNotificationEntity>> getNotifications({
    String? propertyId,
    bool? unreadOnly,
  });

  /// Marca notificaciones como leídas
  Future<void> markNotificationsAsRead(List<String> notificationIds);

  /// Marca todas las notificaciones como leídas
  Future<void> markAllNotificationsAsRead();

  /// Elimina una notificación
  Future<void> deleteNotification(String notificationId);

  /// Elimina todas las notificaciones
  Future<void> deleteAllNotifications();

  /// Stream de notificaciones en tiempo real
  Stream<StaffNotificationEntity> watchNotifications({
    String? propertyId,
  });

  /// Stream de cambios en checkins en tiempo real
  Stream<void> watchCheckins({
    String? propertyId,
  });

  // ==================== MÉTODOS DE DOCUMENTOS ====================

  /// Limpia documentos expirados (más de 1 año)
  /// Retorna el número de documentos eliminados
  Future<CleanupResult> cleanupExpiredDocuments();

  /// Obtiene documentos próximos a expirar
  Future<List<ExpiringDocument>> getDocumentsExpiringSoon({int daysBefore = 7});

  /// Obtiene la hora actual del servidor (para evitar manipulación del reloj del dispositivo)
  /// Retorna la fecha/hora UTC del servidor de Supabase
  Future<DateTime> getServerTime();
}

/// Resultado de crear una reserva
class CreateBookingResult {
  const CreateBookingResult({
    required this.bookingId,
    required this.bookingCode,
    required this.keyboxCode,
    required this.emailSent,
    this.emailError,
    this.simulated = false,
  });

  final String bookingId;
  final String bookingCode;
  final String keyboxCode;
  final bool emailSent;
  final String? emailError;
  final bool simulated;

  factory CreateBookingResult.fromJson(Map<String, dynamic> json) {
    // La respuesta de la EF tiene: { success, booking: {...}, email_sent, email_result }
    // Pero el repositorio pasa solo response['booking'] aquí
    // Así que intentamos leer tanto del objeto principal como de 'booking' anidado
    final booking = json['booking'] as Map<String, dynamic>? ?? json;

    return CreateBookingResult(
      bookingId: (booking['id'] ?? booking['booking_id']) as String,
      bookingCode: (booking['booking_code'] ?? booking['code']) as String,
      keyboxCode: (booking['keybox_code'] ?? '') as String,
      emailSent: json['email_sent'] as bool? ?? false,
      emailError: (json['email_result'] ?? json['email_error']) as String?,
      simulated: json['simulated'] as bool? ?? false,
    );
  }
}

/// Resultado de reenviar código
class ResendCodeResult {
  const ResendCodeResult({
    required this.success,
    this.error,
    this.simulated = false,
  });

  final bool success;
  final String? error;
  final bool simulated;

  factory ResendCodeResult.fromJson(Map<String, dynamic> json) {
    return ResendCodeResult(
      success: json['success'] as bool? ?? false,
      error: json['error'] as String?,
      simulated: json['simulated'] as bool? ?? false,
    );
  }
}

/// Unidad con información de disponibilidad
class UnitWithAvailability {
  const UnitWithAvailability({
    required this.unit,
    required this.isAvailable,
    this.conflictingBookingId,
    this.conflictingGuestName,
  });

  final AdminUnitEntity unit;
  final bool isAvailable;
  final String? conflictingBookingId;
  final String? conflictingGuestName;

  factory UnitWithAvailability.fromJson(Map<String, dynamic> json) {
    return UnitWithAvailability(
      unit: AdminUnitEntity.fromJson(json['unit'] as Map<String, dynamic>),
      isAvailable: json['is_available'] as bool? ?? true,
      conflictingBookingId: json['conflicting_booking_id'] as String?,
      conflictingGuestName: json['conflicting_guest_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'unit': unit.toJson(),
      'is_available': isAvailable,
      'conflicting_booking_id': conflictingBookingId,
      'conflicting_guest_name': conflictingGuestName,
    };
  }
}

/// Resultado de limpiar documentos expirados
class CleanupResult {
  const CleanupResult({
    required this.deletedCount,
    required this.errorCount,
    this.details = const [],
  });

  final int deletedCount;
  final int errorCount;
  final List<CleanupDetail> details;

  factory CleanupResult.fromJson(Map<String, dynamic> json) {
    final detailsList = (json['details'] as List<dynamic>?) ?? [];
    return CleanupResult(
      deletedCount: json['deleted_count'] as int? ?? 0,
      errorCount: json['error_count'] as int? ?? 0,
      details: detailsList
          .map((e) => CleanupDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Detalle de un documento eliminado
class CleanupDetail {
  const CleanupDetail({
    required this.id,
    required this.path,
    required this.status,
    this.error,
  });

  final String id;
  final String path;
  final String status;
  final String? error;

  factory CleanupDetail.fromJson(Map<String, dynamic> json) {
    return CleanupDetail(
      id: json['id'] as String? ?? '',
      path: json['path'] as String? ?? '',
      status: json['status'] as String? ?? '',
      error: json['error'] as String?,
    );
  }
}

/// Documento próximo a expirar
class ExpiringDocument {
  const ExpiringDocument({
    required this.id,
    required this.storagePath,
    required this.expiresAt,
    this.guestId,
    required this.bookingId,
    required this.daysRemaining,
  });

  final String id;
  final String storagePath;
  final DateTime expiresAt;
  final String? guestId;
  final String bookingId;
  final int daysRemaining;

  factory ExpiringDocument.fromJson(Map<String, dynamic> json) {
    return ExpiringDocument(
      id: json['id'] as String,
      storagePath: json['storage_path'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      guestId: json['guest_id'] as String?,
      bookingId: json['booking_id'] as String,
      daysRemaining: json['days_remaining'] as int? ?? 0,
    );
  }
}
