import 'package:equatable/equatable.dart';

import 'place_photo_entity.dart';

/// Nivel geográfico del lugar
enum PlaceLevel {
  jerez,
  alrededores,
  provincia;

  String get displayName {
    switch (this) {
      case PlaceLevel.jerez:
        return 'Jerez';
      case PlaceLevel.alrededores:
        return 'Alrededores';
      case PlaceLevel.provincia:
        return 'Provincia de Cádiz';
    }
  }

  String get shortName {
    switch (this) {
      case PlaceLevel.jerez:
        return 'Jerez';
      case PlaceLevel.alrededores:
        return 'Alrededores';
      case PlaceLevel.provincia:
        return 'Provincia';
    }
  }

  static PlaceLevel fromString(String value) {
    switch (value.toLowerCase()) {
      case 'jerez':
        return PlaceLevel.jerez;
      case 'alrededores':
        return PlaceLevel.alrededores;
      case 'provincia':
        return PlaceLevel.provincia;
      default:
        return PlaceLevel.jerez;
    }
  }
}

/// Nivel de precio
enum PriceLevel {
  gratis,
  unEuro,
  dosEuros,
  tresEuros;

  String get displayName {
    switch (this) {
      case PriceLevel.gratis:
        return 'Gratis';
      case PriceLevel.unEuro:
        return '€';
      case PriceLevel.dosEuros:
        return '€€';
      case PriceLevel.tresEuros:
        return '€€€';
    }
  }

  static PriceLevel? fromString(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase()) {
      case 'gratis':
      case 'free':
        return PriceLevel.gratis;
      case '€':
      case '1':
      case 'un_euro':
        return PriceLevel.unEuro;
      case '€€':
      case '2':
      case 'dos_euros':
        return PriceLevel.dosEuros;
      case '€€€':
      case '3':
      case 'tres_euros':
        return PriceLevel.tresEuros;
      default:
        return null;
    }
  }
}

/// Entidad que representa un lugar o experiencia turística
class PlaceEntity extends Equatable {
  const PlaceEntity({
    required this.id,
    required this.externalId,
    required this.level,
    required this.title,
    required this.shortDescription,
    required this.longDescription,
    required this.categories,
    this.recommendedDurationMinutes,
    this.bestTimeToVisit,
    this.priceLevel,
    this.address,
    this.geoLat,
    this.geoLng,
    this.bookingUrl,
    this.websiteUrl,
    required this.tips,
    required this.tags,
    this.imageUrl,
    this.imageAlt,
    this.sortOrder = 0,
    this.isActive = true,
    this.photos = const [],
  });

  final String id;
  final String externalId;
  final PlaceLevel level;
  final String title;
  final String shortDescription;
  final String longDescription;
  final List<String> categories;
  final int? recommendedDurationMinutes;
  final String? bestTimeToVisit;
  final PriceLevel? priceLevel;
  final String? address;
  final double? geoLat;
  final double? geoLng;
  final String? bookingUrl;
  final String? websiteUrl;
  final List<String> tips;
  final List<String> tags;
  final String? imageUrl;
  final String? imageAlt;
  final int sortOrder;
  final bool isActive;
  final List<PlacePhotoEntity> photos;

  /// Indica si tiene coordenadas para mostrar en mapa
  bool get hasLocation => geoLat != null && geoLng != null;

  /// Indica si tiene imagen
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  /// Indica si tiene tips
  bool get hasTips => tips.isNotEmpty;

  /// Indica si tiene URL de reserva
  bool get hasBookingUrl => bookingUrl != null && bookingUrl!.isNotEmpty;

  /// Indica si tiene web oficial
  bool get hasWebsite => websiteUrl != null && websiteUrl!.isNotEmpty;

  /// Indica si tiene fotos adicionales
  bool get hasPhotos => photos.isNotEmpty;

  /// Obtiene todas las imágenes (principal + adicionales) sin duplicados
  List<String> get allImages {
    // Usar LinkedHashSet para mantener orden y eliminar TODOS los duplicados
    final images = <String>{};
    if (hasImage) images.add(imageUrl!);
    // Añadir fotos adicionales - el Set elimina duplicados automáticamente
    for (final photo in photos) {
      images.add(photo.imageUrl);
    }
    return images.toList();
  }

  /// Duración formateada
  String? get formattedDuration {
    if (recommendedDurationMinutes == null) return null;
    final hours = recommendedDurationMinutes! ~/ 60;
    final minutes = recommendedDurationMinutes! % 60;
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}min';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}min';
    }
  }

  /// Crea una copia con valores modificados
  PlaceEntity copyWith({
    String? id,
    String? externalId,
    PlaceLevel? level,
    String? title,
    String? shortDescription,
    String? longDescription,
    List<String>? categories,
    int? recommendedDurationMinutes,
    String? bestTimeToVisit,
    PriceLevel? priceLevel,
    String? address,
    double? geoLat,
    double? geoLng,
    String? bookingUrl,
    String? websiteUrl,
    List<String>? tips,
    List<String>? tags,
    String? imageUrl,
    String? imageAlt,
    int? sortOrder,
    bool? isActive,
    List<PlacePhotoEntity>? photos,
  }) {
    return PlaceEntity(
      id: id ?? this.id,
      externalId: externalId ?? this.externalId,
      level: level ?? this.level,
      title: title ?? this.title,
      shortDescription: shortDescription ?? this.shortDescription,
      longDescription: longDescription ?? this.longDescription,
      categories: categories ?? this.categories,
      recommendedDurationMinutes:
          recommendedDurationMinutes ?? this.recommendedDurationMinutes,
      bestTimeToVisit: bestTimeToVisit ?? this.bestTimeToVisit,
      priceLevel: priceLevel ?? this.priceLevel,
      address: address ?? this.address,
      geoLat: geoLat ?? this.geoLat,
      geoLng: geoLng ?? this.geoLng,
      bookingUrl: bookingUrl ?? this.bookingUrl,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      tips: tips ?? this.tips,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
      imageAlt: imageAlt ?? this.imageAlt,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      photos: photos ?? this.photos,
    );
  }

  /// Crea una entidad desde un mapa JSON
  factory PlaceEntity.fromJson(Map<String, dynamic> json) {
    return PlaceEntity(
      id: json['id'] as String,
      externalId: json['external_id'] as String,
      level: PlaceLevel.fromString(json['level'] as String),
      title: json['title'] as String,
      shortDescription: json['short_description'] as String,
      longDescription: json['long_description'] as String,
      categories: (json['categories'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      recommendedDurationMinutes:
          json['recommended_duration_minutes'] as int?,
      bestTimeToVisit: json['best_time_to_visit'] as String?,
      priceLevel: PriceLevel.fromString(json['price_level'] as String?),
      address: json['address'] as String?,
      geoLat: (json['geo_lat'] as num?)?.toDouble(),
      geoLng: (json['geo_lng'] as num?)?.toDouble(),
      bookingUrl: json['booking_url'] as String?,
      websiteUrl: json['website_url'] as String?,
      tips:
          (json['tips'] as List<dynamic>).map((e) => e as String).toList(),
      tags:
          (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      imageUrl: json['image_url'] as String?,
      imageAlt: json['image_alt'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      photos: json['photos'] != null
          ? (json['photos'] as List<dynamic>)
              .map((e) => PlacePhotoEntity.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  /// Convierte la entidad a un mapa JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'external_id': externalId,
      'level': level.name,
      'title': title,
      'short_description': shortDescription,
      'long_description': longDescription,
      'categories': categories,
      'recommended_duration_minutes': recommendedDurationMinutes,
      'best_time_to_visit': bestTimeToVisit,
      'price_level': priceLevel?.name,
      'address': address,
      'geo_lat': geoLat,
      'geo_lng': geoLng,
      'booking_url': bookingUrl,
      'website_url': websiteUrl,
      'tips': tips,
      'tags': tags,
      'image_url': imageUrl,
      'image_alt': imageAlt,
      'sort_order': sortOrder,
      'is_active': isActive,
    };
  }

  @override
  List<Object?> get props => [
        id,
        externalId,
        level,
        title,
        shortDescription,
        longDescription,
        categories,
        recommendedDurationMinutes,
        bestTimeToVisit,
        priceLevel,
        address,
        geoLat,
        geoLng,
        bookingUrl,
        websiteUrl,
        tips,
        tags,
        imageUrl,
        imageAlt,
        sortOrder,
        isActive,
        photos,
      ];
}
