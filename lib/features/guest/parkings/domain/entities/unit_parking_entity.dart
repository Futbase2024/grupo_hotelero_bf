import 'package:equatable/equatable.dart';

import '../../../alojamientos/domain/entities/unit_entity.dart';
import 'parking_entity.dart';

/// Entidad que representa la relación entre una unidad y un parking
/// Incluye información de prioridad y notas específicas
class UnitParkingEntity extends Equatable {
  const UnitParkingEntity({
    required this.id,
    required this.unitId,
    required this.parkingId,
    required this.priority,
    this.notes,
    this.parking,
    this.unitName,
    this.unitType,
    this.propertyId,
    this.propertyName,
  });

  final String id;
  final String unitId;
  final String parkingId;
  final int priority;
  final String? notes;
  final ParkingEntity? parking;
  final String? unitName;
  final UnitType? unitType;
  final String? propertyId;
  final String? propertyName;

  /// Indica si la unidad es una habitación de hotel
  bool get isHotelRoom => unitType == UnitType.hotelRoom;

  /// Indica si tiene notas
  bool get hasNotes => notes != null && notes!.isNotEmpty;

  /// Etiqueta de prioridad para mostrar al usuario
  String get priorityLabel {
    switch (priority) {
      case 0:
        return 'Más cercano';
      case 1:
        return 'Recomendado';
      case 2:
        return 'Alternativa';
      default:
        return 'Opción ${priority + 1}';
    }
  }

  /// Crea una copia con valores modificados
  UnitParkingEntity copyWith({
    String? id,
    String? unitId,
    String? parkingId,
    int? priority,
    String? notes,
    ParkingEntity? parking,
    String? unitName,
    UnitType? unitType,
    String? propertyId,
    String? propertyName,
  }) {
    return UnitParkingEntity(
      id: id ?? this.id,
      unitId: unitId ?? this.unitId,
      parkingId: parkingId ?? this.parkingId,
      priority: priority ?? this.priority,
      notes: notes ?? this.notes,
      parking: parking ?? this.parking,
      unitName: unitName ?? this.unitName,
      unitType: unitType ?? this.unitType,
      propertyId: propertyId ?? this.propertyId,
      propertyName: propertyName ?? this.propertyName,
    );
  }

  /// Crea una entidad desde un mapa JSON
  factory UnitParkingEntity.fromJson(Map<String, dynamic> json) {
    final unitsJson = json['units'] as Map<String, dynamic>?;
    final propertiesJson = json['properties'] as Map<String, dynamic>?;

    return UnitParkingEntity(
      id: json['id'] as String,
      unitId: json['unit_id'] as String,
      parkingId: json['parking_id'] as String,
      priority: json['priority'] as int? ?? 0,
      notes: json['notes'] as String?,
      parking: json['parkings'] != null
          ? ParkingEntity.fromJson(
              json['parkings'] as Map<String, dynamic>,
            )
          : null,
      unitName: unitsJson?['name'] as String?,
      unitType: unitsJson?['unit_type'] != null
          ? UnitTypeExtension.fromString(unitsJson!['unit_type'] as String)
          : null,
      propertyId: unitsJson?['property_id'] as String?,
      propertyName: propertiesJson?['name'] as String?,
    );
  }

  /// Convierte la entidad a un mapa JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'unit_id': unitId,
      'parking_id': parkingId,
      'priority': priority,
      'notes': notes,
    };
  }

  @override
  List<Object?> get props => [
        id,
        unitId,
        parkingId,
        priority,
        notes,
        parking,
        unitName,
        unitType,
        propertyId,
        propertyName,
      ];
}
