import 'package:equatable/equatable.dart';

/// Entidad que representa los códigos de acceso a la propiedad
class AccessBoxEntity extends Equatable {
  const AccessBoxEntity({
    required this.mainCode,
    this.wifiNetwork,
    this.wifiPassword,
    this.additionalCodes = const [],
    required this.validFrom,
    required this.validUntil,
    this.accessInstructions,
    this.boxLocation,
  });

  /// Código principal de acceso (keybox/puerta principal)
  final String mainCode;

  /// Nombre de la red WiFi
  final String? wifiNetwork;

  /// Contraseña WiFi
  final String? wifiPassword;

  /// Códigos adicionales (habitación, gimnasio, etc.)
  final List<AdditionalCode> additionalCodes;

  /// Fecha de inicio de validez (check-in)
  final DateTime validFrom;

  /// Fecha de fin de validez (check-out)
  final DateTime validUntil;

  /// Instrucciones de acceso
  final String? accessInstructions;

  /// Ubicación del box
  final String? boxLocation;

  /// Duración de la estancia en noches
  int get nights => validUntil.difference(validFrom).inDays;

  /// Si la estancia está activa ahora
  bool get isCurrentlyValid {
    final now = DateTime.now();
    return now.isAfter(validFrom.subtract(const Duration(hours: 12))) &&
        now.isBefore(validUntil.add(const Duration(hours: 12)));
  }

  factory AccessBoxEntity.fromJson(Map<String, dynamic> json) {
    final additionalCodesList = (json['additional_codes'] as List<dynamic>?)
            ?.map((e) => AdditionalCode.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return AccessBoxEntity(
      mainCode: json['main_code'] as String? ?? '',
      wifiNetwork: json['wifi_network'] as String?,
      wifiPassword: json['wifi_password'] as String?,
      additionalCodes: additionalCodesList,
      validFrom: DateTime.parse(json['valid_from'] as String),
      validUntil: DateTime.parse(json['valid_until'] as String),
      accessInstructions: json['access_instructions'] as String?,
      boxLocation: json['box_location'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'main_code': mainCode,
      'wifi_network': wifiNetwork,
      'wifi_password': wifiPassword,
      'additional_codes': additionalCodes.map((e) => e.toJson()).toList(),
      'valid_from': validFrom.toIso8601String(),
      'valid_until': validUntil.toIso8601String(),
      'access_instructions': accessInstructions,
      'box_location': boxLocation,
    };
  }

  @override
  List<Object?> get props => [
        mainCode,
        wifiNetwork,
        wifiPassword,
        additionalCodes,
        validFrom,
        validUntil,
        accessInstructions,
        boxLocation,
      ];
}

/// Código adicional de acceso (habitación, gimnasio, etc.)
class AdditionalCode extends Equatable {
  const AdditionalCode({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.code,
  });

  final String icon;
  final String title;
  final String subtitle;
  final String code;

  factory AdditionalCode.fromJson(Map<String, dynamic> json) {
    return AdditionalCode(
      icon: json['icon'] as String? ?? 'key',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      code: json['code'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'icon': icon,
      'title': title,
      'subtitle': subtitle,
      'code': code,
    };
  }

  @override
  List<Object?> get props => [icon, title, subtitle, code];
}
