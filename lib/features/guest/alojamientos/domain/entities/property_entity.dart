import 'package:equatable/equatable.dart';
import 'unit_entity.dart';

/// Entidad que representa una propiedad/alojamiento
class PropertyEntity extends Equatable {
  const PropertyEntity({
    required this.id,
    required this.name,
    this.address,
    this.city,
    this.country = 'ES',
    this.timezone = 'Europe/Madrid',
    this.lat,
    this.lng,
    this.units = const [],
  });

  final String id;
  final String name;
  final String? address;
  final String? city;
  final String country;
  final String timezone;
  final double? lat;
  final double? lng;
  final List<UnitEntity> units;

  /// Indica si la propiedad tiene ubicación geográfica
  bool get hasLocation => lat != null && lng != null;

  /// Devuelve la dirección completa formateada
  String get fullAddress {
    final parts = <String>[
      if (address != null) address!,
      if (city != null) city!,
    ];
    return parts.join(', ');
  }

  /// Crea una copia con valores modificados
  PropertyEntity copyWith({
    String? id,
    String? name,
    String? address,
    String? city,
    String? country,
    String? timezone,
    double? lat,
    double? lng,
    List<UnitEntity>? units,
  }) {
    return PropertyEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      timezone: timezone ?? this.timezone,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      units: units ?? this.units,
    );
  }

  /// Crea una entidad desde un mapa JSON
  factory PropertyEntity.fromJson(Map<String, dynamic> json) {
    return PropertyEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String? ?? 'ES',
      timezone: json['timezone'] as String? ?? 'Europe/Madrid',
      lat: json['lat'] as double?,
      lng: json['lng'] as double?,
      units: json['units'] != null
          ? (json['units'] as List)
              .map((u) => UnitEntity.fromJson(u as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  /// Convierte la entidad a un mapa JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'city': city,
      'country': country,
      'timezone': timezone,
      'lat': lat,
      'lng': lng,
      'units': units.map((u) => u.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        address,
        city,
        country,
        timezone,
        lat,
        lng,
        units,
      ];
}
