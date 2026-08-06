import '../entities/guest_entity.dart';

/// Contrato del repositorio de check-in
abstract class CheckinRepository {
  /// Obtiene los datos de la reserva para el check-in
  /// Incluye el número de adultos y niños esperados
  Future<CheckinBookingData> getBookingForCheckin(String bookingId);

  /// Obtiene los huéspedes guardados de una reserva
  Future<List<GuestEntity>> getBookingGuests(String bookingId);

  /// Guarda o actualiza un huésped
  /// Si el huésped no tiene ID, crea uno nuevo
  Future<GuestEntity> saveGuest({
    required String bookingId,
    required GuestEntity guest,
  });

  /// Elimina un huésped (no se puede eliminar el titular)
  Future<void> deleteGuest(String guestId);

  /// Sube un documento al storage
  /// Retorna la ruta del archivo subido
  Future<String> uploadDocument({
    required String bookingId,
    required String guestId,
    required String docKind,
    required List<int> bytes,
    required String mimeType,
  });

  /// Elimina documentos previos de un huésped para un tipo de documento concreto
  /// Se usa antes de subir uno nuevo para evitar duplicados
  Future<void> deleteGuestDocuments({
    required String bookingId,
    required String guestId,
    required String docKind,
    String? exceptStoragePath,
  });

  /// Elimina los documentos del huésped cuyo `doc_kind` no esté en
  /// [keepDocKinds], p. ej. las caras del DNI cuando pasa a pasaporte
  Future<void> deleteObsoleteDocuments({
    required String bookingId,
    required String guestId,
    required List<String> keepDocKinds,
  });

  /// Obtiene la URL firmada para ver un documento
  Future<String> getDocumentUrl(String storagePath);

  /// Envía el check-in completo
  Future<void> submitCheckin({
    required String bookingId,
    required String signatureSvg,
  });

  /// Obtiene el estado actual del check-in
  Future<CheckinStatus> getCheckinStatus(String bookingId);

  /// Busca un huésped por email (para pre-poblar datos de reservas anteriores)
  /// Retorna null si no encuentra ninguno
  Future<GuestEntity?> findGuestByEmail(String email);

  /// Busca el perfil de usuario por email (tabla profiles)
  /// Retorna null si no encuentra ninguno
  Future<ProfileData?> getProfileByEmail(String email);

  /// Guarda o actualiza el perfil del usuario
  /// Se usa para persistir datos como DNI entre reservas
  Future<void> saveProfile(ProfileData profile);

  /// Suscribe a cambios en tiempo real del estado del check-in
  /// Retorna un Stream que emite el nuevo estado cada vez que cambia
  Stream<CheckinStatus> watchCheckinStatus(String bookingId);
}

/// Datos de la reserva necesarios para el check-in
class CheckinBookingData {
  const CheckinBookingData({
    required this.bookingId,
    required this.bookingCode,
    required this.unitName,
    required this.propertyName,
    required this.propertyId,
    required this.checkInDate,
    required this.checkOutDate,
    required this.numAdults,
    required this.numChildren,
    required this.childrenAges,
    required this.guestFirstName,
    required this.guestLastName,
    required this.guestEmail,
    this.guestPhone,
    this.checkinId,
    this.checkinStatus,
  });

  final String bookingId;
  final String bookingCode;
  final String unitName;
  final String propertyName;
  final String propertyId;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int numAdults;
  final int numChildren;
  final List<int> childrenAges;
  final String guestFirstName;
  final String guestLastName;
  final String guestEmail;
  final String? guestPhone;
  final String? checkinId;
  final String? checkinStatus;

  /// Nombre completo del titular
  String get guestFullName => '$guestFirstName $guestLastName'.trim();

  /// Número total de huéspedes
  int get totalGuests => numAdults + numChildren;

  /// Número de niños menores de 14 años
  int get numChildrenUnder14 => childrenAges.where((age) => age < 14).length;

  /// Número de niños de 14+ años
  int get numChildrenOver14 => childrenAges.where((age) => age >= 14).length;

  /// Número de huéspedes que requieren documento
  int get numGuestsRequiringDocument => numAdults + numChildrenOver14;

  /// Si ya tiene un check-in iniciado
  bool get hasCheckin => checkinId != null;

  /// Si el check-in está en borrador (se puede continuar)
  bool get isCheckinDraft => checkinStatus == 'draft';

  factory CheckinBookingData.fromJson(Map<String, dynamic> json) {
    List<int> childrenAges = [];
    if (json['children_ages'] != null) {
      final agesList = json['children_ages'] as List;
      childrenAges = agesList.map((e) => e as int).toList();
    }

    return CheckinBookingData(
      bookingId: json['id'] as String,
      bookingCode: json['booking_code'] as String,
      unitName: json['unit_name'] as String? ?? '',
      propertyName: json['property_name'] as String? ?? '',
      propertyId: json['property_id'] as String? ?? '',
      checkInDate: DateTime.parse(json['checkin_date'] as String),
      checkOutDate: DateTime.parse(json['checkout_date'] as String),
      numAdults: json['num_adults'] as int? ?? 1,
      numChildren: json['num_children'] as int? ?? 0,
      childrenAges: childrenAges,
      guestFirstName: json['guest_first_name'] as String? ?? '',
      guestLastName: json['last_name'] as String? ?? '',
      guestEmail: json['guest_email'] as String? ?? '',
      guestPhone: json['guest_phone'] as String?,
      checkinId: json['checkin_id'] as String?,
      checkinStatus: json['checkin_status'] as String?,
    );
  }
}

/// Estado del check-in
enum CheckinStatus {
  none,
  draft,
  submitted,
  validated,
  rejected,
}

/// Datos del perfil de usuario (tabla profiles)
class ProfileData {
  const ProfileData({
    required this.email,
    this.userId,
    this.fullName,
    this.phone,
    this.documentType,
    this.documentNumber,
    this.nationality,
    this.birthDate,
  });

  final String email;
  final String? userId;
  final String? fullName;
  final String? phone;
  final String? documentType;
  final String? documentNumber;
  final String? nationality;
  final DateTime? birthDate;

  /// Si tiene documento guardado
  bool get hasDocument => documentNumber != null && documentNumber!.isNotEmpty;

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    return ProfileData(
      email: json['email'] as String? ?? '',
      userId: json['user_id'] as String?,
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      documentType: json['document_type'] as String?,
      documentNumber: json['document_number'] as String?,
      nationality: json['nationality'] as String?,
      birthDate: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      if (userId != null) 'user_id': userId,
      if (fullName != null) 'full_name': fullName,
      if (phone != null) 'phone': phone,
      if (documentType != null) 'document_type': documentType,
      if (documentNumber != null) 'document_number': documentNumber,
      if (nationality != null) 'nationality': nationality,
      if (birthDate != null) 'birth_date': birthDate!.toIso8601String().split('T').first,
    };
  }
}

/// Extensión para obtener el valor de la base de datos
extension CheckinStatusExtension on CheckinStatus {
  String get dbValue {
    switch (this) {
      case CheckinStatus.none:
        return 'none';
      case CheckinStatus.draft:
        return 'draft';
      case CheckinStatus.submitted:
        return 'submitted';
      case CheckinStatus.validated:
        return 'validated';
      case CheckinStatus.rejected:
        return 'rejected';
    }
  }

  static CheckinStatus fromDbValue(String? value) {
    switch (value) {
      case 'draft':
        return CheckinStatus.draft;
      case 'submitted':
        return CheckinStatus.submitted;
      case 'validated':
        return CheckinStatus.validated;
      case 'rejected':
        return CheckinStatus.rejected;
      default:
        return CheckinStatus.none;
    }
  }
}
