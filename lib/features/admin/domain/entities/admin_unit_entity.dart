import 'package:equatable/equatable.dart';

/// Entity para unidades/alojamientos en el panel de administración
class AdminUnitEntity extends Equatable {
  const AdminUnitEntity({
    required this.id,
    required this.propertyId,
    required this.name,
    required this.unitType,
    this.addressLine1,
    this.city,
    this.postalCode,
    this.boxCode,
    this.accessInstructions,
    this.wifiNetwork,
    this.wifiPassword,
    this.activeBookingsCount,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String propertyId;
  final String name;
  final String unitType; // Apartamento, Casa, Habitación, Suite, Villa, Estudio
  final String? addressLine1;
  final String? city;
  final String? postalCode;
  final String? boxCode;
  final String? accessInstructions;
  final String? wifiNetwork;
  final String? wifiPassword;
  final int? activeBookingsCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Dirección completa formateada
  String get fullAddress {
    final parts = <String>[];
    if (addressLine1 != null) parts.add(addressLine1!);
    if (city != null) parts.add(city!);
    if (postalCode != null) parts.add(postalCode!);
    return parts.join(', ');
  }

  /// Si tiene código de caja configurado
  bool get hasBoxCode => boxCode != null && boxCode!.isNotEmpty;

  /// Si tiene instrucciones de acceso
  bool get hasAccessInstructions =>
      accessInstructions != null && accessInstructions!.isNotEmpty;

  /// Si tiene WiFi configurado
  bool get hasWifi => wifiNetwork != null && wifiNetwork!.isNotEmpty;

  /// Convierte desde un mapa JSON
  factory AdminUnitEntity.fromJson(Map<String, dynamic> json) {
    return AdminUnitEntity(
      id: json['id'] as String,
      propertyId: json['property_id'] as String,
      name: json['name'] as String,
      unitType: json['unit_type'] as String? ?? 'Apartamento',
      addressLine1: json['address_line1'] as String?,
      city: json['city'] as String?,
      postalCode: json['postal_code'] as String?,
      boxCode: json['box_code'] as String?,
      accessInstructions: json['access_instructions'] as String?,
      wifiNetwork: json['wifi_network'] as String?,
      wifiPassword: json['wifi_password'] as String?,
      activeBookingsCount: json['active_bookings_count'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convierte a un mapa JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'property_id': propertyId,
      'name': name,
      'unit_type': unitType,
      'address_line1': addressLine1,
      'city': city,
      'postal_code': postalCode,
      'box_code': boxCode,
      'access_instructions': accessInstructions,
      'wifi_network': wifiNetwork,
      'wifi_password': wifiPassword,
      'active_bookings_count': activeBookingsCount,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        propertyId,
        name,
        unitType,
        addressLine1,
        city,
        postalCode,
        boxCode,
        accessInstructions,
        wifiNetwork,
        wifiPassword,
        activeBookingsCount,
        createdAt,
        updatedAt,
      ];
}
