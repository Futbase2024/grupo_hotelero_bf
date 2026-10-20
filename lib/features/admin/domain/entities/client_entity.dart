import 'package:equatable/equatable.dart';

class ClientEntity extends Equatable {
  const ClientEntity({
    required this.id,
    required this.name,
    this.propertyId,
    this.nif,
    this.email,
    this.phone,
    this.address,
    this.city,
    this.postalCode,
    this.country = 'España',
    this.notes,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String? propertyId;
  final String? nif;
  final String? email;
  final String? phone;
  final String? address;
  final String? city;
  final String? postalCode;
  final String country;
  final String? notes;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ClientEntity copyWith({
    String? id,
    String? name,
    String? propertyId,
    String? nif,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? postalCode,
    String? country,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClientEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      propertyId: propertyId ?? this.propertyId,
      nif: nif ?? this.nif,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ClientEntity.fromJson(Map<String, dynamic> json) {
    return ClientEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      propertyId: json['property_id'] as String?,
      nif: json['nif'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      postalCode: json['postal_code'] as String?,
      country: json['country'] as String? ?? 'España',
      notes: json['notes'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (propertyId != null) 'property_id': propertyId,
      if (nif != null) 'nif': nif,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (postalCode != null) 'postal_code': postalCode,
      'country': country,
      if (notes != null) 'notes': notes,
      'is_active': isActive,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        propertyId,
        nif,
        email,
        phone,
        address,
        city,
        postalCode,
        country,
        notes,
        isActive,
      ];
}
