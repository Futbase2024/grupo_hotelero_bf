import 'package:equatable/equatable.dart';

/// Entidad que representa una norma de la casa
class HouseRuleEntity extends Equatable {
  const HouseRuleEntity({
    required this.id,
    required this.propertyId,
    required this.title,
    this.description,
    this.icon = 'info',
    this.category = 'general',
    this.sortOrder = 0,
    this.isActive = true,
  });

  final String id;
  final String propertyId;
  final String title;
  final String? description;
  final String icon;
  final String category;
  final int sortOrder;
  final bool isActive;

  /// Indica si la norma tiene descripción
  bool get hasDescription => description != null && description!.isNotEmpty;

  /// Devuelve el nombre de la categoría para mostrar
  String get categoryName => getCategoryDisplayName(category);

  /// Devuelve el color de la categoría
  String get categoryColor => _getCategoryColor(category);

  /// Obtiene el nombre de visualización de una categoría
  static String getCategoryDisplayName(String category) {
    switch (category) {
      case 'noise':
        return 'Silencio';
      case 'cleanliness':
        return 'Limpieza';
      case 'safety':
        return 'Seguridad';
      case 'general':
        return 'General';
      default:
        return 'Otro';
    }
  }

  /// Obtiene el color de una categoría
  static String _getCategoryColor(String category) {
    switch (category) {
      case 'noise':
        return 'purple';
      case 'cleanliness':
        return 'green';
      case 'safety':
        return 'red';
      case 'general':
        return 'blue';
      default:
        return 'gray';
    }
  }

  /// Crea una copia con valores modificados
  HouseRuleEntity copyWith({
    String? id,
    String? propertyId,
    String? title,
    String? description,
    String? icon,
    String? category,
    int? sortOrder,
    bool? isActive,
  }) {
    return HouseRuleEntity(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      category: category ?? this.category,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Crea una entidad desde un mapa JSON
  factory HouseRuleEntity.fromJson(Map<String, dynamic> json) {
    return HouseRuleEntity(
      id: json['id'] as String,
      propertyId: json['property_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String? ?? 'info',
      category: json['category'] as String? ?? 'general',
      sortOrder: json['sort_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  /// Convierte la entidad a un mapa JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'property_id': propertyId,
      'title': title,
      'description': description,
      'icon': icon,
      'category': category,
      'sort_order': sortOrder,
      'is_active': isActive,
    };
  }

  @override
  List<Object?> get props => [
        id,
        propertyId,
        title,
        description,
        icon,
        category,
        sortOrder,
        isActive,
      ];
}
