import 'package:equatable/equatable.dart';

/// Tipo de unidad
enum UnitType { apartment, room, hotelRoom }

/// Extensión para convertir string a UnitType
extension UnitTypeExtension on UnitType {
  String get value {
    switch (this) {
      case UnitType.apartment:
        return 'apartment';
      case UnitType.room:
        return 'room';
      case UnitType.hotelRoom:
        return 'hotel_room';
    }
  }

  static UnitType fromString(String value) {
    switch (value) {
      case 'apartment':
        return UnitType.apartment;
      case 'room':
        return UnitType.room;
      case 'hotel_room':
        return UnitType.hotelRoom;
      default:
        return UnitType.apartment;
    }
  }

  String get displayName {
    switch (this) {
      case UnitType.apartment:
        return 'Apartamento';
      case UnitType.room:
        return 'Habitación';
      case UnitType.hotelRoom:
        return 'Habitación';
    }
  }
}

/// Entidad que representa una unidad dentro de una propiedad
class UnitEntity extends Equatable {
  const UnitEntity({
    required this.id,
    required this.propertyId,
    required this.name,
    required this.unitType,
    this.boxLocationText,
    this.boxCode,
    this.accessInstructions,
    // Campos de dirección
    this.addressLine1,
    this.addressLine2,
    this.neighborhood,
    this.city,
    this.province,
    this.region,
    this.postalCode,
    this.country,
    this.lat,
    this.lng,
    this.fullAddress,
  });

  final String id;
  final String propertyId;
  final String name;
  final UnitType unitType;
  final String? boxLocationText;
  final String? boxCode;
  final String? accessInstructions;

  // Campos de dirección
  final String? addressLine1;
  final String? addressLine2;
  final String? neighborhood;
  final String? city;
  final String? province;
  final String? region;
  final String? postalCode;
  final String? country;
  final double? lat;
  final double? lng;
  final String? fullAddress;

  /// Crea una copia con valores modificados
  UnitEntity copyWith({
    String? id,
    String? propertyId,
    String? name,
    UnitType? unitType,
    String? boxLocationText,
    String? boxCode,
    String? accessInstructions,
    String? addressLine1,
    String? addressLine2,
    String? neighborhood,
    String? city,
    String? province,
    String? region,
    String? postalCode,
    String? country,
    double? lat,
    double? lng,
    String? fullAddress,
  }) {
    return UnitEntity(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      name: name ?? this.name,
      unitType: unitType ?? this.unitType,
      boxLocationText: boxLocationText ?? this.boxLocationText,
      boxCode: boxCode ?? this.boxCode,
      accessInstructions: accessInstructions ?? this.accessInstructions,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      neighborhood: neighborhood ?? this.neighborhood,
      city: city ?? this.city,
      province: province ?? this.province,
      region: region ?? this.region,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      fullAddress: fullAddress ?? this.fullAddress,
    );
  }

  /// Crea una entidad desde un mapa JSON
  factory UnitEntity.fromJson(Map<String, dynamic> json) {
    return UnitEntity(
      id: json['id'] as String,
      propertyId: json['property_id'] as String,
      name: json['name'] as String,
      unitType: UnitTypeExtension.fromString(json['unit_type'] as String),
      boxLocationText: json['box_location_text'] as String?,
      boxCode: json['box_code'] as String?,
      accessInstructions: json['access_instructions'] as String?,
      // Campos de dirección
      addressLine1: json['address_line1'] as String?,
      addressLine2: json['address_line2'] as String?,
      neighborhood: json['neighborhood'] as String?,
      city: json['city'] as String?,
      province: json['province'] as String?,
      region: json['region'] as String?,
      postalCode: json['postal_code'] as String?,
      country: json['country'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      fullAddress: json['full_address'] as String?,
    );
  }

  /// Convierte la entidad a un mapa JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'property_id': propertyId,
      'name': name,
      'unit_type': unitType.value,
      'box_location_text': boxLocationText,
      'box_code': boxCode,
      'access_instructions': accessInstructions,
      // Campos de dirección
      'address_line1': addressLine1,
      'address_line2': addressLine2,
      'neighborhood': neighborhood,
      'city': city,
      'province': province,
      'region': region,
      'postal_code': postalCode,
      'country': country,
      'lat': lat,
      'lng': lng,
      'full_address': fullAddress,
    };
  }

  @override
  List<Object?> get props => [
        id,
        propertyId,
        name,
        unitType,
        boxLocationText,
        boxCode,
        accessInstructions,
        addressLine1,
        addressLine2,
        neighborhood,
        city,
        province,
        region,
        postalCode,
        country,
        lat,
        lng,
        fullAddress,
      ];
}
