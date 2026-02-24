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
  });

  final String id;
  final String email;
  final UserRole role;
  final String? name;
  final String? phone;
  final String? avatarUrl;
  final String? bookingId;
  final String? propertyId;

  /// Nombre para mostrar (nombre completo o email)
  String get displayName => name ?? email.split('@').first;

  /// Iniciales del usuario para avatar
  String get initials {
    if (name != null && name!.isNotEmpty) {
      final parts = name!.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return name![0].toUpperCase();
    }
    return email[0].toUpperCase();
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
      ];
}
