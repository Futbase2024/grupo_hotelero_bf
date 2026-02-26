import '../entities/admin_entities.dart';

/// Contrato del repositorio del panel de administración.
/// Todas las operaciones van a través de Edge Functions de Supabase.
abstract class AdminPanelRepository {
  /// Obtiene el resumen del dashboard
  Future<DashboardSummaryEntity> getDashboardSummary({
    String? propertyId,
  });

  /// Lista reservas con filtros opcionales
  Future<List<AdminBookingEntity>> listBookings({
    String? propertyId,
    String? statusFilter,
    DateTime? fromDate,
    DateTime? toDate,
    String? searchQuery,
  });

  /// Obtiene una reserva por ID
  Future<AdminBookingEntity?> getBooking(String bookingId);

  /// Crea una nueva reserva
  /// Retorna el código BF generado y el estado del envío de email
  Future<CreateBookingResult> createBooking({
    required String unitId,
    required String guestFirstName,
    required String guestLastName,
    required String guestEmail,
    String? guestPhone,
    required DateTime checkInDate,
    required DateTime checkOutDate,
    required int numGuests,
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

  /// Lista unidades de una propiedad
  Future<List<AdminUnitEntity>> listUnits(String propertyId);

  /// Lista unidades con disponibilidad para un rango de fechas
  /// Si propertyId es null, carga todas las unidades de todas las propiedades
  Future<List<UnitWithAvailability>> listUnitsWithAvailability({
    String? propertyId,
    DateTime? checkInDate,
    DateTime? checkOutDate,
  });

  /// Obtiene notificaciones
  Future<List<StaffNotificationEntity>> getNotifications({
    String? propertyId,
    bool? unreadOnly,
  });

  /// Marca notificaciones como leídas
  Future<void> markNotificationsAsRead(List<String> notificationIds);

  /// Stream de notificaciones en tiempo real
  Stream<StaffNotificationEntity> watchNotifications({
    String? propertyId,
  });
}

/// Resultado de crear una reserva
class CreateBookingResult {
  const CreateBookingResult({
    required this.bookingId,
    required this.bookingCode,
    required this.emailSent,
    this.emailError,
    this.simulated = false,
  });

  final String bookingId;
  final String bookingCode;
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
