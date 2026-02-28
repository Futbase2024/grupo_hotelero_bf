/// Contrato del repositorio de check-out
abstract class CheckoutRepository {
  /// Obtiene los datos de la reserva para el check-out
  Future<CheckoutBookingData> getBookingForCheckout(String bookingId);

  /// Verifica si el check-out ya fue realizado
  Future<bool> isCheckoutCompleted(String bookingId);

  /// Realiza el check-out de la reserva
  /// Actualiza el estado del check-in a 'checked_out'
  Future<void> completeCheckout({
    required String bookingId,
    String? feedback,
    int? rating,
  });
}

/// Datos de la reserva necesarios para el check-out
class CheckoutBookingData {
  const CheckoutBookingData({
    required this.bookingId,
    required this.bookingCode,
    required this.unitName,
    required this.propertyName,
    required this.checkInDate,
    required this.checkOutDate,
    required this.numGuests,
    required this.guestFullName,
    required this.guestEmail,
    this.propertyId,
  });

  final String bookingId;
  final String bookingCode;
  final String unitName;
  final String propertyName;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int numGuests;
  final String guestFullName;
  final String guestEmail;
  final String? propertyId;

  /// Número de noches de la estancia
  int get stayNights => checkOutDate.difference(checkInDate).inDays;

  /// Si el check-out es hoy
  bool get isCheckoutToday {
    final now = DateTime.now();
    return now.year == checkOutDate.year &&
        now.month == checkOutDate.month &&
        now.day == checkOutDate.day;
  }

  factory CheckoutBookingData.fromJson(Map<String, dynamic> json) {
    return CheckoutBookingData(
      bookingId: json['id'] as String,
      bookingCode: json['booking_code'] as String,
      unitName: json['unit_name'] as String? ?? '',
      propertyName: json['property_name'] as String? ?? '',
      checkInDate: DateTime.parse(json['checkin_date'] as String),
      checkOutDate: DateTime.parse(json['checkout_date'] as String),
      numGuests: (json['num_adults'] as int? ?? 1) + (json['num_children'] as int? ?? 0),
      guestFullName: '${json['guest_first_name'] ?? ''} ${json['last_name'] ?? ''}'.trim(),
      guestEmail: json['guest_email'] as String? ?? '',
      propertyId: json['property_id'] as String?,
    );
  }
}
