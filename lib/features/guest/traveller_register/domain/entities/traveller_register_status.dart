import 'package:equatable/equatable.dart';

/// Un dato que falta o es incorrecto, según `traveller_register_issues`
class TravellerIssue extends Equatable {
  const TravellerIssue({
    required this.field,
    required this.code,
    required this.isBlocking,
  });

  /// Campo afectado: first_name, document_number, contact…
  final String field;

  /// required | invalid | recommended | legacy_format | responsible_not_adult…
  final String code;

  /// `level = error`: impide firmar y enviar. `warning`: solo avisa.
  final bool isBlocking;

  factory TravellerIssue.fromJson(Map<String, dynamic> json) {
    return TravellerIssue(
      field: json['field'] as String? ?? '',
      code: json['code'] as String? ?? '',
      isBlocking: (json['level'] as String? ?? 'error') == 'error',
    );
  }

  @override
  List<Object?> get props => [field, code, isBlocking];
}

/// Situación de un huésped dentro del registro de la reserva
class TravellerGuestStatus extends Equatable {
  const TravellerGuestStatus({
    required this.guestId,
    required this.isPrimary,
    required this.ageOnCheckin,
    required this.needsOwnSignature,
    required this.signed,
    required this.coveredByResponsible,
    required this.issues,
  });

  final String guestId;
  final bool isPrimary;
  final int? ageOnCheckin;

  /// 14 años o más: firma su propio parte
  final bool needsOwnSignature;

  /// Tiene un parte vigente firmado
  final bool signed;

  /// Menor de 14 incluido en el parte vigente de su responsable
  final bool coveredByResponsible;
  final List<TravellerIssue> issues;

  bool get hasBlockingIssues => issues.any((issue) => issue.isBlocking);

  /// Puede firmar ya: le toca firmar y no le falta ningún dato obligatorio
  bool get canSign => needsOwnSignature && !hasBlockingIssues;

  bool get isDone => !hasBlockingIssues &&
      ageOnCheckin != null &&
      (needsOwnSignature ? signed : coveredByResponsible);

  factory TravellerGuestStatus.fromJson(Map<String, dynamic> json) {
    final rawIssues = json['issues'] as List? ?? const [];
    return TravellerGuestStatus(
      guestId: json['guest_id'] as String,
      isPrimary: json['is_primary'] as bool? ?? false,
      ageOnCheckin: json['age_on_checkin'] as int?,
      needsOwnSignature: json['needs_own_signature'] as bool? ?? false,
      signed: json['signed'] as bool? ?? false,
      coveredByResponsible: json['covered_by_responsible'] as bool? ?? false,
      issues: rawIssues
          .whereType<Map<String, dynamic>>()
          .map(TravellerIssue.fromJson)
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
        guestId,
        isPrimary,
        ageOnCheckin,
        needsOwnSignature,
        signed,
        coveredByResponsible,
        issues,
      ];
}

/// Estado del registro de viajeros de una reserva
class TravellerRegisterStatus extends Equatable {
  const TravellerRegisterStatus({
    required this.bookingId,
    required this.isComplete,
    required this.guests,
  });

  final String bookingId;

  /// Todos los datos obligatorios y todas las firmas: se puede enviar
  final bool isComplete;
  final List<TravellerGuestStatus> guests;

  TravellerGuestStatus? guest(String guestId) {
    for (final status in guests) {
      if (status.guestId == guestId) return status;
    }
    return null;
  }

  factory TravellerRegisterStatus.fromJson(Map<String, dynamic> json) {
    final rawGuests = json['guests'] as List? ?? const [];
    return TravellerRegisterStatus(
      bookingId: json['booking_id'] as String,
      isComplete: json['complete'] as bool? ?? false,
      guests: rawGuests
          .whereType<Map<String, dynamic>>()
          .map(TravellerGuestStatus.fromJson)
          .toList(),
    );
  }

  @override
  List<Object?> get props => [bookingId, isComplete, guests];
}
