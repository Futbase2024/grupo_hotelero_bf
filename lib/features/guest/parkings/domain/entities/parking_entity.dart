import 'package:equatable/equatable.dart';

/// Entidad que representa un parking cercano a los alojamientos
class ParkingEntity extends Equatable {
  const ParkingEntity({
    required this.id,
    required this.name,
    required this.addressText,
    this.phone,
    this.provider,
    this.lat,
    this.lng,
    this.googleMapsUrl,
    this.appleMapsUrl,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String addressText;
  final String? phone;
  final String? provider;
  final double? lat;
  final double? lng;
  final String? googleMapsUrl;
  final String? appleMapsUrl;
  final bool isActive;

  /// Indica si tiene coordenadas geográficas
  bool get hasLocation => lat != null && lng != null;

  /// Indica si tiene teléfono
  bool get hasPhone => phone != null && phone!.isNotEmpty;

  /// Indica si tiene URL de Google Maps
  bool get hasGoogleMapsUrl =>
      googleMapsUrl != null && googleMapsUrl!.isNotEmpty;

  /// Indica si tiene URL de Apple Maps
  bool get hasAppleMapsUrl =>
      appleMapsUrl != null && appleMapsUrl!.isNotEmpty;

  /// URL generada para Google Maps si no existe
  String? get effectiveGoogleMapsUrl {
    if (googleMapsUrl != null && googleMapsUrl!.isNotEmpty) {
      return googleMapsUrl;
    }
    if (hasLocation) {
      return 'https://www.google.com/maps?q=$lat,$lng';
    }
    // Buscar por dirección
    return 'https://www.google.com/maps/search/${Uri.encodeComponent(addressText)}';
  }

  /// URL generada para Apple Maps si no existe
  String? get effectiveAppleMapsUrl {
    if (appleMapsUrl != null && appleMapsUrl!.isNotEmpty) {
      return appleMapsUrl;
    }
    if (hasLocation) {
      return 'https://maps.apple.com/?ll=$lat,$lng';
    }
    // Buscar por dirección
    return 'https://maps.apple.com/?q=${Uri.encodeComponent(addressText)}';
  }

  /// Crea una copia con valores modificados
  ParkingEntity copyWith({
    String? id,
    String? name,
    String? addressText,
    String? phone,
    String? provider,
    double? lat,
    double? lng,
    String? googleMapsUrl,
    String? appleMapsUrl,
    bool? isActive,
  }) {
    return ParkingEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      addressText: addressText ?? this.addressText,
      phone: phone ?? this.phone,
      provider: provider ?? this.provider,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      googleMapsUrl: googleMapsUrl ?? this.googleMapsUrl,
      appleMapsUrl: appleMapsUrl ?? this.appleMapsUrl,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Crea una entidad desde un mapa JSON
  factory ParkingEntity.fromJson(Map<String, dynamic> json) {
    return ParkingEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      addressText: json['address_text'] as String,
      phone: json['phone'] as String?,
      provider: json['provider'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      googleMapsUrl: json['google_maps_url'] as String?,
      appleMapsUrl: json['apple_maps_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  /// Convierte la entidad a un mapa JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address_text': addressText,
      'phone': phone,
      'provider': provider,
      'lat': lat,
      'lng': lng,
      'google_maps_url': googleMapsUrl,
      'apple_maps_url': appleMapsUrl,
      'is_active': isActive,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        addressText,
        phone,
        provider,
        lat,
        lng,
        googleMapsUrl,
        appleMapsUrl,
        isActive,
      ];
}
