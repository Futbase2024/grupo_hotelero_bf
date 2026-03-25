import 'package:equatable/equatable.dart';

/// Entity para representar una unidad/habitación dentro de una reserva
class BookingUnitEntity extends Equatable {
  const BookingUnitEntity({
    required this.id,
    required this.unitId,
    required this.name,
    this.unitType,
    this.wifiNetwork,
    this.wifiPassword,
    this.boxCode,
    this.accessInstructions,
  });

  final String id;
  final String unitId;
  final String name;
  final String? unitType;
  final String? wifiNetwork;
  final String? wifiPassword;
  final String? boxCode;
  final String? accessInstructions;

  factory BookingUnitEntity.fromJson(Map<String, dynamic> json) {
    return BookingUnitEntity(
      id: json['id'] as String? ?? '',
      unitId: json['unit_id'] as String? ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      unitType: json['unit_type'] as String? ?? json['type'] as String?,
      wifiNetwork: json['wifi_network'] as String?,
      wifiPassword: json['wifi_password'] as String?,
      boxCode: json['box_code'] as String?,
      accessInstructions: json['access_instructions'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'unit_id': unitId,
      'name': name,
      'type': unitType,
      'wifi_network': wifiNetwork,
      'wifi_password': wifiPassword,
      'box_code': boxCode,
      'access_instructions': accessInstructions,
    };
  }

  BookingUnitEntity copyWith({
    String? id,
    String? unitId,
    String? name,
    String? unitType,
    String? wifiNetwork,
    String? wifiPassword,
    String? boxCode,
    String? accessInstructions,
  }) {
    return BookingUnitEntity(
      id: id ?? this.id,
      unitId: unitId ?? this.unitId,
      name: name ?? this.name,
      unitType: unitType ?? this.unitType,
      wifiNetwork: wifiNetwork ?? this.wifiNetwork,
      wifiPassword: wifiPassword ?? this.wifiPassword,
      boxCode: boxCode ?? this.boxCode,
      accessInstructions: accessInstructions ?? this.accessInstructions,
    );
  }

  @override
  List<Object?> get props => [
        id,
        unitId,
        name,
        unitType,
        wifiNetwork,
        wifiPassword,
        boxCode,
        accessInstructions,
      ];
}
