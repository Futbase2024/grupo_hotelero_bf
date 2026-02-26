import 'package:equatable/equatable.dart';

/// Entidad que representa una foto de una unidad
class UnitPhotoEntity extends Equatable {
  const UnitPhotoEntity({
    required this.id,
    required this.unitId,
    required this.path,
    required this.sortOrder,
    this.isCover = false,
    this.alt,
  });

  final String id;
  final String unitId;
  final String path;
  final int sortOrder;
  final bool isCover;
  final String? alt;

  /// Crea una entidad desde un mapa JSON
  factory UnitPhotoEntity.fromJson(Map<String, dynamic> json) {
    return UnitPhotoEntity(
      id: json['id'] as String,
      unitId: json['unit_id'] as String,
      path: json['path'] as String,
      sortOrder: json['sort_order'] as int? ?? 0,
      isCover: json['is_cover'] as bool? ?? false,
      alt: json['alt'] as String?,
    );
  }

  /// Convierte la entidad a un mapa JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'unit_id': unitId,
      'path': path,
      'sort_order': sortOrder,
      'is_cover': isCover,
      'alt': alt,
    };
  }

  @override
  List<Object?> get props => [id, unitId, path, sortOrder, isCover, alt];
}
