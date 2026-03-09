import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/enums/enums.dart';
import '../../../guest/alojamientos/domain/entities/unit_entity.dart';

/// Entity para reservas con datos completos para el panel de administración
class AdminBookingEntity extends Equatable {
  const AdminBookingEntity({
    required this.id,
    required this.bookingCode,
    this.keyboxCode,
    required this.unitId,
    required this.unitName,
    required this.propertyId,
    required this.propertyName,
    required this.checkInDate,
    required this.checkOutDate,
    required this.numGuests,
    this.numAdults = 1,
    this.numChildren = 0,
    this.childrenAges = const [],
    required this.status,
    this.bookingStatus = BookingStatus.created,
    this.checkoutStatus = CheckoutStatus.notStarted,
    required this.guestEmail,
    this.guestFirstName,
    this.guestLastName,
    this.guestPhone,
    this.staffNotes,
    this.codeFirstUsedAt,
    this.codeSentAt,
    this.checkinId,
    this.checkinStatus,
    this.signatureSvg,
    this.docsPending,
    this.activatedAt,
    this.closedAt,
    this.checkoutRequestedAt,
    this.checkoutValidatedAt,
    this.validationNotes,
    this.checkoutNotes,
    this.createdAt,
    this.updatedAt,
    this.unitType = UnitType.apartment,
  });

  final String id;
  final String bookingCode;
  final String? keyboxCode;
  final String unitId;
  final String unitName;
  final UnitType unitType;
  final String propertyId;
  final String propertyName;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int numGuests;
  final int numAdults;
  final int numChildren;
  final List<int> childrenAges;
  final String status; // Legacy: confirmed, checked_in, checked_out, cancelled
  final BookingStatus bookingStatus; // Nuevo: created, active, closed, cancelled
  final CheckoutStatus checkoutStatus; // Nuevo: not_started, requested, validated, rejected
  final String guestEmail;
  final String? guestFirstName;
  final String? guestLastName;
  final String? guestPhone;
  final String? staffNotes;
  final DateTime? codeFirstUsedAt;
  final DateTime? codeSentAt;
  final String? checkinId;
  final String? checkinStatus; // not_started, in_progress, submitted, validated, rejected
  final String? signatureSvg; // SVG de la firma del titular
  final int? docsPending;
  final DateTime? activatedAt;
  final DateTime? closedAt;
  final DateTime? checkoutRequestedAt;
  final DateTime? checkoutValidatedAt;
  final String? validationNotes;
  final String? checkoutNotes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // ==================== GETTERS BÁSICOS ====================

  /// Nombre completo del huésped
  String get guestFullName {
    if ((guestFirstName == null || guestFirstName!.isEmpty) &&
        (guestLastName == null || guestLastName!.isEmpty)) {
      return '';
    }
    if (guestFirstName == null || guestFirstName!.isEmpty) {
      return guestLastName ?? '';
    }
    if (guestLastName == null || guestLastName!.isEmpty) {
      return guestFirstName ?? '';
    }
    return '$guestFirstName $guestLastName'.trim();
  }

  /// Si el código ha sido usado
  bool get isCodeUsed => codeFirstUsedAt != null;

  /// Si el código ha sido enviado por email
  bool get isCodeSent => codeSentAt != null;

  /// Si tiene check-in iniciado
  bool get hasCheckin => checkinId != null;

  /// Si el check-in está pendiente de revisión
  bool get isCheckinPending => checkinStatus == 'submitted';

  /// Si hay documentos pendientes
  bool get hasDocsPending => (docsPending ?? 0) > 0;

  /// Número de niños menores de 14 años (no requieren documento)
  int get numChildrenUnder14 => childrenAges.where((age) => age < 14).length;

  /// Número de niños de 14 o más años (requieren documento como adultos)
  int get numChildrenOver14 => childrenAges.where((age) => age >= 14).length;

  /// Número total de huéspedes que requieren documento
  int get numGuestsRequiringDocument => numAdults + numChildrenOver14;

  /// Descripción de los huéspedes para mostrar en UI
  String get guestsDescription {
    final parts = <String>[];
    if (numAdults > 0) parts.add('$numAdults ${numAdults == 1 ? "adulto" : "adultos"}');
    if (numChildren > 0) parts.add('$numChildren ${numChildren == 1 ? "niño" : "niños"}');
    return parts.join(', ');
  }

  // ==================== GETTERS DE ESTADO (USANDO ENUMS) ====================

  /// Estado del check-in como enum
  CheckinStatus get checkinStatusEnum {
    if (checkinStatus == null) return CheckinStatus.notStarted;
    return CheckinStatus.fromString(checkinStatus!);
  }

  /// Si la reserva está activa (panel completo accesible)
  bool get isPanelAccessible =>
      bookingStatus.isPanelAccessible && checkinStatusEnum.isValidated;

  /// Si la reserva está cerrada (solo lectura)
  bool get isReadOnly => bookingStatus.isReadOnly;

  /// Si la reserva fue cancelada
  bool get isCancelled => bookingStatus.isCancelled;

  /// Si la reserva está pendiente de activación
  bool get isPending => bookingStatus.isPending;

  /// Si el check-in puede ser editado por el huésped
  bool get canEditCheckin => checkinStatusEnum.isEditable;

  /// Si el check-in necesita acción del admin
  bool get needsCheckinAction => checkinStatusEnum.needsAdminAction;

  /// Si el check-out puede ser solicitado
  bool get canRequestCheckout =>
      checkoutStatus.canRequest &&
      checkinStatusEnum.isValidated &&
      bookingStatus == BookingStatus.active;

  /// Si el check-out necesita acción del admin
  bool get needsCheckoutAction => checkoutStatus.needsAdminAction;

  /// Si el check-out tiene incidencias
  bool get hasCheckoutIssues => checkoutStatus.needsResolution;

  /// Duración de la estancia en noches
  int get stayDurationNights {
    return checkOutDate.difference(checkInDate).inDays;
  }

  /// Si la estancia está en curso actualmente
  bool get isStayInProgress {
    final now = DateTime.now();
    return now.isAfter(checkInDate) && now.isBefore(checkOutDate);
  }

  /// Si la fecha de check-in ya pasó
  bool get isCheckinDatePassed {
    final now = DateTime.now();
    return now.isAfter(checkInDate) || now.isAtSameMomentAs(checkInDate);
  }

  /// Si es el día de check-out hoy
  bool get isCheckoutDay {
    final now = DateTime.now();
    return now.year == checkOutDate.year &&
        now.month == checkOutDate.month &&
        now.day == checkOutDate.day;
  }

  // ==================== FACTORY ====================

  /// Convierte desde un mapa JSON (respuesta de Supabase/Edge Function)
  factory AdminBookingEntity.fromJson(Map<String, dynamic> json) {
    debugPrint('🟢 [AdminBookingEntity.fromJson] Starting parse...');
    debugPrint('🟢 [AdminBookingEntity.fromJson] JSON keys: ${json.keys.toList()}');

    try {
      // Parsear children_ages como lista de int
      List<int> childrenAges = [];
      if (json['children_ages'] != null) {
        final agesList = json['children_ages'] as List;
        childrenAges = agesList.map((e) => e as int).toList();
      }

      // Helper para obtener String con fallback a múltiples nombres de campo
      String? getStringField(List<String> fieldNames) {
        for (final name in fieldNames) {
          if (json[name] != null) return json[name] as String;
        }
        return null;
      }

      // Helper para obtener DateTime
      DateTime? getDateTimeField(List<String> fieldNames) {
        final str = getStringField(fieldNames);
        return str != null ? DateTime.parse(str) : null;
      }

      // ID: puede venir como 'id' o 'booking_id'
      final id = getStringField(['id', 'booking_id']) ?? '';

      // Booking code
      final bookingCode = getStringField(['booking_code']) ?? '';

      // Unit ID
      final unitId = getStringField(['unit_id']) ?? '';

      // Unit name
      final unitName = getStringField(['unit_name']) ?? '';

      // Property ID
      final propertyId = getStringField(['property_id']) ?? '';

      // Property name
      final propertyName = getStringField(['property_name']) ?? '';

      // Check-in date
      final checkInDateStr = getStringField(['check_in_date', 'checkin_date']) ?? '';
      final checkInDate = checkInDateStr.isNotEmpty
          ? DateTime.parse(checkInDateStr)
          : DateTime.now();

      // Check-out date
      final checkOutDateStr = getStringField(['check_out_date', 'checkout_date']) ?? '';
      final checkOutDate = checkOutDateStr.isNotEmpty
          ? DateTime.parse(checkOutDateStr)
          : DateTime.now().add(const Duration(days: 1));

      // Status legacy
      final status = getStringField(['status']) ?? 'confirmed';

      // Booking status (nuevo)
      final bookingStatusStr = getStringField(['booking_status']);
      final bookingStatus = bookingStatusStr != null
          ? BookingStatus.fromString(bookingStatusStr)
          : BookingStatus.fromString(status);

      // Checkout status (nuevo)
      final checkoutStatusStr = getStringField(['checkout_status']);
      final checkoutStatus = checkoutStatusStr != null
          ? CheckoutStatus.fromString(checkoutStatusStr)
          : CheckoutStatus.notStarted;

      // Guest email
      final guestEmail = getStringField(['guest_email']) ?? '';

      // Guest first name
      final guestFirstName = getStringField(['guest_first_name', 'first_name']);
      debugPrint('🟢 [AdminBookingEntity.fromJson] guest_first_name: $guestFirstName');

      // Guest last name
      final guestLastNameRaw = getStringField(['guest_last_name', 'last_name']);
      debugPrint('🟢 [AdminBookingEntity.fromJson] guest_last_name raw: $guestLastNameRaw');

      final guestFirstNameFinal = guestFirstName ?? '';
      final guestLastNameFinal = guestLastNameRaw ?? '';

      // Unit type
      final unitTypeStr = getStringField(['unit_type']) ?? 'apartment';
      final unitType = UnitTypeExtension.fromString(unitTypeStr);

      // Otros campos
      final guestPhone = getStringField(['guest_phone', 'phone']);
      final staffNotes = getStringField(['staff_notes']);
      final keyboxCode = getStringField(['keybox_code']);
      final checkinId = getStringField(['checkin_id']);
      final checkinStatus = getStringField(['checkin_status']);
      final signatureSvg = getStringField(['signature_svg']);
      final validationNotes = getStringField(['validation_notes']);
      final checkoutNotes = getStringField(['checkout_notes']);

      // Timestamps
      final codeFirstUsedAt = getDateTimeField(['code_first_used_at']);
      final codeSentAt = getDateTimeField(['code_sent_at']);
      final createdAt = getDateTimeField(['created_at']);
      final updatedAt = getDateTimeField(['updated_at']);
      final activatedAt = getDateTimeField(['activated_at']);
      final closedAt = getDateTimeField(['closed_at']);
      final checkoutRequestedAt = getDateTimeField(['checkout_requested_at']);
      final checkoutValidatedAt = getDateTimeField(['checkout_validated_at']);

      debugPrint('🟢 [AdminBookingEntity.fromJson] Creating entity...');
      final entity = AdminBookingEntity(
        id: id,
        bookingCode: bookingCode,
        keyboxCode: keyboxCode,
        unitId: unitId,
        unitName: unitName,
        unitType: unitType,
        propertyId: propertyId,
        propertyName: propertyName,
        checkInDate: checkInDate,
        checkOutDate: checkOutDate,
        numGuests: json['num_guests'] as int? ?? 1,
        numAdults: json['num_adults'] as int? ?? 1,
        numChildren: json['num_children'] as int? ?? 0,
        childrenAges: childrenAges,
        status: status,
        bookingStatus: bookingStatus,
        checkoutStatus: checkoutStatus,
        guestEmail: guestEmail,
        guestFirstName: guestFirstNameFinal,
        guestLastName: guestLastNameFinal,
        guestPhone: guestPhone,
        staffNotes: staffNotes,
        codeFirstUsedAt: codeFirstUsedAt,
        codeSentAt: codeSentAt,
        checkinId: checkinId,
        checkinStatus: checkinStatus,
        signatureSvg: signatureSvg,
        docsPending: json['docs_pending'] as int?,
        activatedAt: activatedAt,
        closedAt: closedAt,
        checkoutRequestedAt: checkoutRequestedAt,
        checkoutValidatedAt: checkoutValidatedAt,
        validationNotes: validationNotes,
        checkoutNotes: checkoutNotes,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      debugPrint('🟢 [AdminBookingEntity.fromJson] Parse completed successfully');
      return entity;
    } catch (e, stackTrace) {
      debugPrint('🔴 [AdminBookingEntity.fromJson] ERROR: $e');
      debugPrint('🔴 [AdminBookingEntity.fromJson] StackTrace: $stackTrace');
      debugPrint('🔴 [AdminBookingEntity.fromJson] JSON: $json');
      rethrow;
    }
  }

  /// Crea una entidad vacía para casos donde se necesita un placeholder
  static AdminBookingEntity empty() {
    return AdminBookingEntity(
      id: '',
      bookingCode: '',
      unitId: '',
      unitName: '',
      propertyId: '',
      propertyName: '',
      checkInDate: DateTime.now(),
      checkOutDate: DateTime.now().add(const Duration(days: 1)),
      numGuests: 1,
      numAdults: 1,
      numChildren: 0,
      childrenAges: const [],
      status: 'confirmed',
      bookingStatus: BookingStatus.created,
      checkoutStatus: CheckoutStatus.notStarted,
      guestEmail: '',
      guestFirstName: null,
      guestLastName: null,
      guestPhone: null,
      staffNotes: null,
      codeFirstUsedAt: null,
      codeSentAt: null,
      checkinId: null,
      checkinStatus: null,
      signatureSvg: null,
      docsPending: null,
      activatedAt: null,
      closedAt: null,
      checkoutRequestedAt: null,
      checkoutValidatedAt: null,
      validationNotes: null,
      checkoutNotes: null,
      createdAt: null,
      updatedAt: null,
    );
  }

  /// Convierte a un mapa JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_code': bookingCode,
      'keybox_code': keyboxCode,
      'unit_id': unitId,
      'unit_name': unitName,
      'unit_type': unitType.value,
      'property_id': propertyId,
      'property_name': propertyName,
      'check_in_date': checkInDate.toIso8601String(),
      'check_out_date': checkOutDate.toIso8601String(),
      'num_guests': numGuests,
      'num_adults': numAdults,
      'num_children': numChildren,
      'children_ages': childrenAges,
      'status': status,
      'booking_status': bookingStatus.toDbString(),
      'checkout_status': checkoutStatus.toDbString(),
      'guest_email': guestEmail,
      'guest_first_name': guestFirstName,
      'guest_last_name': guestLastName,
      'guest_phone': guestPhone,
      'staff_notes': staffNotes,
      'code_first_used_at': codeFirstUsedAt?.toIso8601String(),
      'code_sent_at': codeSentAt?.toIso8601String(),
      'checkin_id': checkinId,
      'checkin_status': checkinStatus,
      'signature_svg': signatureSvg,
      'docs_pending': docsPending,
      'activated_at': activatedAt?.toIso8601String(),
      'closed_at': closedAt?.toIso8601String(),
      'checkout_requested_at': checkoutRequestedAt?.toIso8601String(),
      'checkout_validated_at': checkoutValidatedAt?.toIso8601String(),
      'validation_notes': validationNotes,
      'checkout_notes': checkoutNotes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Crea una copia con campos actualizados
  AdminBookingEntity copyWith({
    String? id,
    String? bookingCode,
    String? keyboxCode,
    String? unitId,
    String? unitName,
    UnitType? unitType,
    String? propertyId,
    String? propertyName,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    int? numGuests,
    int? numAdults,
    int? numChildren,
    List<int>? childrenAges,
    String? status,
    BookingStatus? bookingStatus,
    CheckoutStatus? checkoutStatus,
    String? guestEmail,
    String? guestFirstName,
    String? guestLastName,
    String? guestPhone,
    String? staffNotes,
    DateTime? codeFirstUsedAt,
    DateTime? codeSentAt,
    String? checkinId,
    String? checkinStatus,
    String? signatureSvg,
    int? docsPending,
    DateTime? activatedAt,
    DateTime? closedAt,
    DateTime? checkoutRequestedAt,
    DateTime? checkoutValidatedAt,
    String? validationNotes,
    String? checkoutNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdminBookingEntity(
      id: id ?? this.id,
      bookingCode: bookingCode ?? this.bookingCode,
      keyboxCode: keyboxCode ?? this.keyboxCode,
      unitId: unitId ?? this.unitId,
      unitName: unitName ?? this.unitName,
      unitType: unitType ?? this.unitType,
      propertyId: propertyId ?? this.propertyId,
      propertyName: propertyName ?? this.propertyName,
      checkInDate: checkInDate ?? this.checkInDate,
      checkOutDate: checkOutDate ?? this.checkOutDate,
      numGuests: numGuests ?? this.numGuests,
      numAdults: numAdults ?? this.numAdults,
      numChildren: numChildren ?? this.numChildren,
      childrenAges: childrenAges ?? this.childrenAges,
      status: status ?? this.status,
      bookingStatus: bookingStatus ?? this.bookingStatus,
      checkoutStatus: checkoutStatus ?? this.checkoutStatus,
      guestEmail: guestEmail ?? this.guestEmail,
      guestFirstName: guestFirstName ?? this.guestFirstName,
      guestLastName: guestLastName ?? this.guestLastName,
      guestPhone: guestPhone ?? this.guestPhone,
      staffNotes: staffNotes ?? this.staffNotes,
      codeFirstUsedAt: codeFirstUsedAt ?? this.codeFirstUsedAt,
      codeSentAt: codeSentAt ?? this.codeSentAt,
      checkinId: checkinId ?? this.checkinId,
      checkinStatus: checkinStatus ?? this.checkinStatus,
      signatureSvg: signatureSvg ?? this.signatureSvg,
      docsPending: docsPending ?? this.docsPending,
      activatedAt: activatedAt ?? this.activatedAt,
      closedAt: closedAt ?? this.closedAt,
      checkoutRequestedAt: checkoutRequestedAt ?? this.checkoutRequestedAt,
      checkoutValidatedAt: checkoutValidatedAt ?? this.checkoutValidatedAt,
      validationNotes: validationNotes ?? this.validationNotes,
      checkoutNotes: checkoutNotes ?? this.checkoutNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        bookingCode,
        keyboxCode,
        unitId,
        unitName,
        unitType,
        propertyId,
        propertyName,
        checkInDate,
        checkOutDate,
        numGuests,
        numAdults,
        numChildren,
        childrenAges,
        status,
        bookingStatus,
        checkoutStatus,
        guestEmail,
        guestFirstName,
        guestLastName,
        guestPhone,
        staffNotes,
        codeFirstUsedAt,
        codeSentAt,
        checkinId,
        checkinStatus,
        signatureSvg,
        docsPending,
        activatedAt,
        closedAt,
        checkoutRequestedAt,
        checkoutValidatedAt,
        validationNotes,
        checkoutNotes,
        createdAt,
        updatedAt,
      ];
}
