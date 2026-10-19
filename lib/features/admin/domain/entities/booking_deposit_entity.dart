import 'package:equatable/equatable.dart';
import '../../../../core/enums/enums.dart';

/// Fianza opcional de una reserva, con los datos necesarios para pedirla,
/// confirmarla y registrar su devolución desde el panel de administración.
///
/// Se lee directamente de `bookings` (más el importe sugerido del alojamiento
/// y el estado del check-in) para que la usen igual el detalle de la reserva y
/// el detalle del check-in.
class BookingDepositEntity extends Equatable {
  const BookingDepositEntity({
    required this.bookingId,
    required this.bookingCode,
    required this.propertyId,
    required this.propertyName,
    required this.guestName,
    this.guestEmail,
    this.guestPhone,
    this.guestUserId,
    this.checkinStatus,
    this.status = DepositStatus.none,
    this.amountCents,
    this.paymentLink,
    this.sentVia = const [],
    this.requestedAt,
    this.paidAt,
    this.reference,
    this.returnedAt,
    this.returnedCents,
    this.retainedCents,
    this.retainedReason,
    this.suggestedAmountCents,
  });

  final String bookingId;
  final String bookingCode;
  final String propertyId;
  final String propertyName;

  // Datos de contacto para enviar el enlace
  final String guestName;
  final String? guestEmail;
  final String? guestPhone;

  /// Usuario del huésped en la app (necesario para enviarlo por el chat)
  final String? guestUserId;

  /// Estado del check-in (`submitted`, `validated`…), `null` si no existe
  final String? checkinStatus;

  final DepositStatus status;
  final int? amountCents;
  final String? paymentLink;

  /// Canales por los que se envió el enlace: `chat`, `whatsapp`, `email`
  final List<String> sentVia;
  final DateTime? requestedAt;
  final DateTime? paidAt;

  /// Nº de operación de la pasarela (opcional)
  final String? reference;
  final DateTime? returnedAt;
  final int? returnedCents;
  final int? retainedCents;
  final String? retainedReason;

  /// Importe sugerido del alojamiento (`properties.default_deposit_cents`)
  final int? suggestedAmountCents;

  bool get _isCheckinClosed =>
      checkinStatus == 'validated' || checkinStatus == 'cancelled';

  /// Se puede pedir mientras el check-in no esté validado ni cancelado
  bool get canRequest => status == DepositStatus.none && !_isCheckinClosed;

  /// Si al confirmar el pago se validará el check-in en el acto
  bool get willValidateOnConfirm => checkinStatus == 'submitted';

  bool get hasGuestPhone => (guestPhone ?? '').trim().isNotEmpty;
  bool get hasGuestEmail => (guestEmail ?? '').trim().isNotEmpty;
  bool get hasGuestAppUser => (guestUserId ?? '').isNotEmpty;

  factory BookingDepositEntity.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String key) {
      final value = json[key] as String?;
      return value != null ? DateTime.parse(value) : null;
    }

    // Las relaciones embebidas pueden llegar como objeto o como lista
    Map<String, dynamic>? embedded(String key) {
      final value = json[key];
      if (value is Map<String, dynamic>) return value;
      if (value is List && value.isNotEmpty) {
        return value.first as Map<String, dynamic>;
      }
      return null;
    }

    final property = embedded('properties');
    final checkin = embedded('checkins');

    final firstName = (json['guest_first_name'] as String? ?? '').trim();
    final lastName = (json['last_name'] as String? ?? '').trim();

    return BookingDepositEntity(
      bookingId: json['id'] as String,
      bookingCode: json['booking_code'] as String? ?? '',
      propertyId: json['property_id'] as String? ?? '',
      propertyName: property?['name'] as String? ?? '',
      guestName: '$firstName $lastName'.trim(),
      guestEmail: json['guest_email'] as String?,
      guestPhone: json['guest_phone'] as String?,
      guestUserId: json['primary_guest_user_id'] as String?,
      checkinStatus: checkin?['status'] as String?,
      status: DepositStatus.fromString(json['deposit_status'] as String?),
      amountCents: json['deposit_amount_cents'] as int?,
      paymentLink: json['deposit_payment_link'] as String?,
      sentVia: (json['deposit_sent_via'] as List?)?.cast<String>() ?? const [],
      requestedAt: parseDate('deposit_requested_at'),
      paidAt: parseDate('deposit_paid_at'),
      reference: json['deposit_reference'] as String?,
      returnedAt: parseDate('deposit_returned_at'),
      returnedCents: json['deposit_returned_cents'] as int?,
      retainedCents: json['deposit_retained_cents'] as int?,
      retainedReason: json['deposit_retained_reason'] as String?,
      suggestedAmountCents: property?['default_deposit_cents'] as int?,
    );
  }

  @override
  List<Object?> get props => [
        bookingId,
        bookingCode,
        propertyId,
        propertyName,
        guestName,
        guestEmail,
        guestPhone,
        guestUserId,
        checkinStatus,
        status,
        amountCents,
        paymentLink,
        sentVia,
        requestedAt,
        paidAt,
        reference,
        returnedAt,
        returnedCents,
        retainedCents,
        retainedReason,
        suggestedAmountCents,
      ];
}
