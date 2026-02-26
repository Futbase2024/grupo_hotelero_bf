import 'package:equatable/equatable.dart';

import 'place_entity.dart';

/// Entidad que representa una colección curada de lugares
class CollectionEntity extends Equatable {
  const CollectionEntity({
    required this.id,
    required this.externalId,
    required this.title,
    this.description,
    this.level,
    required this.placeIds,
    this.imageUrl,
    this.sortOrder = 0,
    this.isActive = true,
  });

  final String id;
  final String externalId;
  final String title;
  final String? description;
  final PlaceLevel? level;
  final List<String> placeIds;
  final String? imageUrl;
  final int sortOrder;
  final bool isActive;

  /// Indica si tiene descripción
  bool get hasDescription =>
      description != null && description!.isNotEmpty;

  /// Indica si tiene imagen
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  /// Número de lugares en la colección
  int get placeCount => placeIds.length;

  /// Crea una copia con valores modificados
  CollectionEntity copyWith({
    String? id,
    String? externalId,
    String? title,
    String? description,
    PlaceLevel? level,
    List<String>? placeIds,
    String? imageUrl,
    int? sortOrder,
    bool? isActive,
  }) {
    return CollectionEntity(
      id: id ?? this.id,
      externalId: externalId ?? this.externalId,
      title: title ?? this.title,
      description: description ?? this.description,
      level: level ?? this.level,
      placeIds: placeIds ?? this.placeIds,
      imageUrl: imageUrl ?? this.imageUrl,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Crea una entidad desde un mapa JSON
  factory CollectionEntity.fromJson(Map<String, dynamic> json) {
    return CollectionEntity(
      id: json['id'] as String,
      externalId: json['external_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      level: json['level'] != null
          ? PlaceLevel.fromString(json['level'] as String)
          : null,
      placeIds:
          (json['place_ids'] as List<dynamic>).map((e) => e as String).toList(),
      imageUrl: json['image_url'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  /// Convierte la entidad a un mapa JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'external_id': externalId,
      'title': title,
      'description': description,
      'level': level?.name,
      'place_ids': placeIds,
      'image_url': imageUrl,
      'sort_order': sortOrder,
      'is_active': isActive,
    };
  }

  @override
  List<Object?> get props => [
        id,
        externalId,
        title,
        description,
        level,
        placeIds,
        imageUrl,
        sortOrder,
        isActive,
      ];
}
