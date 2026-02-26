import 'package:equatable/equatable.dart';

/// Entidad que representa una foto adicional de un lugar
class PlacePhotoEntity extends Equatable {
  const PlacePhotoEntity({
    required this.id,
    required this.placeId,
    required this.imageUrl,
    this.imageAlt,
    this.sortOrder = 0,
  });

  final String id;
  final String placeId;
  final String imageUrl;
  final String? imageAlt;
  final int sortOrder;

  /// Crea una entidad desde un mapa JSON
  factory PlacePhotoEntity.fromJson(Map<String, dynamic> json) {
    return PlacePhotoEntity(
      id: json['id'] as String,
      placeId: json['place_id'] as String,
      imageUrl: json['image_url'] as String,
      imageAlt: json['image_alt'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  /// Convierte la entidad a un mapa JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'place_id': placeId,
      'image_url': imageUrl,
      'image_alt': imageAlt,
      'sort_order': sortOrder,
    };
  }

  @override
  List<Object?> get props => [id, placeId, imageUrl, imageAlt, sortOrder];
}
