import 'package:equatable/equatable.dart';

/// Roles de usuario en el sistema
enum UserRole {
  guest,
  staff,
  admin;

  String get displayName {
    switch (this) {
      case UserRole.guest:
        return 'Huésped';
      case UserRole.staff:
        return 'Personal';
      case UserRole.admin:
        return 'Administrador';
    }
  }

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.name.toLowerCase() == value.toLowerCase(),
      orElse: () => UserRole.guest,
    );
  }
}

/// Entidad de usuario del sistema
class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.email,
    required this.role,
    this.name,
    this.phone,
    this.avatarUrl,
    this.bookingId,
    this.propertyId,
    this.checkInCompleted = false,
    this.checkinStatus,
    this.checkinRejectionReason,
    this.checkinCancellationReason,
  });

  final String id;
  final String email;
  final UserRole role;
  final String? name;
  final String? phone;
  final String? avatarUrl;
  final String? bookingId;
  final String? propertyId;
  final bool checkInCompleted;
  /// Estado del check-in: 'not_started', 'in_progress', 'submitted', 'validated', 'rejected', 'cancelled'
  final String? checkinStatus;
  /// Motivo del rechazo del check-in (si aplica, permite corrección)
  final String? checkinRejectionReason;
  /// Motivo de la cancelación del check-in (si aplica, NO permite corrección)
  final String? checkinCancellationReason;

  /// Nombre para mostrar (nombre completo, email o vacío)
  String get displayName {
    if (name != null && name!.isNotEmpty) {
      return name!;
    }
    if (email.isNotEmpty) {
      return email.split('@').first;
    }
    return '';
  }

  /// Iniciales del usuario para avatar
  String get initials {
    if (name != null && name!.isNotEmpty) {
      final parts = name!.split(' ').where((p) => p.isNotEmpty).toList();
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      if (parts.isNotEmpty) {
        return parts[0][0].toUpperCase();
      }
    }
    if (email.isNotEmpty) {
      return email[0].toUpperCase();
    }
    return 'G'; // Guest por defecto
  }

  /// Verifica si el usuario es huésped
  bool get isGuest => role == UserRole.guest;

  /// Verifica si el usuario es staff
  bool get isStaff => role == UserRole.staff || role == UserRole.admin;

  /// Verifica si el usuario es admin
  bool get isAdmin => role == UserRole.admin;

  UserEntity copyWith({
    String? id,
    String? email,
    UserRole? role,
    String? name,
    String? phone,
    String? avatarUrl,
    String? bookingId,
    String? propertyId,
    bool? checkInCompleted,
    String? checkinStatus,
    String? checkinRejectionReason,
    String? checkinCancellationReason,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bookingId: bookingId ?? this.bookingId,
      propertyId: propertyId ?? this.propertyId,
      checkInCompleted: checkInCompleted ?? this.checkInCompleted,
      checkinStatus: checkinStatus ?? this.checkinStatus,
      checkinRejectionReason: checkinRejectionReason ?? this.checkinRejectionReason,
      checkinCancellationReason: checkinCancellationReason ?? this.checkinCancellationReason,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        role,
        name,
        phone,
        avatarUrl,
        bookingId,
        propertyId,
        checkInCompleted,
        checkinStatus,
        checkinRejectionReason,
        checkinCancellationReason,
      ];
}
