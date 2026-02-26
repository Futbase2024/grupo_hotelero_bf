import 'package:equatable/equatable.dart';

/// Entidad que representa una reseña de un huésped
class ReviewEntity extends Equatable {
  const ReviewEntity({
    required this.id,
    required this.propertyId,
    this.unitId,
    this.guestId,
    this.bookingId,
    required this.rating,
    this.title,
    required this.comment,
    this.isVerified = false,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    // Campos joined desde otras tablas
    this.guestName,
    this.propertyName,
    this.unitName,
  });

  final String id;
  final String propertyId;
  final String? unitId;
  final String? guestId;
  final String? bookingId;
  final int rating;
  final String? title;
  final String comment;
  final bool isVerified;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Campos de relaciones (populados desde joins)
  final String? guestName;
  final String? propertyName;
  final String? unitName;

  // ============================================
  // GETTERS
  // ============================================

  /// Indica si la reseña tiene título
  bool get hasTitle => title != null && title!.isNotEmpty;

  /// Indica si la reseña es reciente (últimos 30 días)
  bool get isRecent => DateTime.now().difference(createdAt).inDays <= 30;

  /// Devuelve las estrellas como string (★★★☆☆)
  String get ratingStars => '★' * rating + '☆' * (5 - rating);

  /// Devuelve el tiempo transcurrido en formato legible
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return 'Hace un momento';
      }
      return 'Hace ${diff.inHours} hora${diff.inHours == 1 ? '' : 's'}';
    }
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    if (diff.inDays < 14) return 'Hace 1 semana';
    if (diff.inDays < 30) {
      final weeks = diff.inDays ~/ 7;
      return 'Hace $weeks semana${weeks == 1 ? '' : 's'}';
    }
    if (diff.inDays < 60) return 'Hace 1 mes';
    if (diff.inDays < 365) {
      final months = diff.inDays ~/ 30;
      return 'Hace $months mes${months == 1 ? '' : 'es'}';
    }
    return 'Hace más de un año';
  }

  /// Devuelve el nombre del huésped o un valor por defecto
  String get displayGuestName => guestName ?? 'Huésped Anónimo';

  /// Devuelve las iniciales del huésped para el avatar
  String get guestInitials {
    if (guestName == null || guestName!.isEmpty) return '?';
    final parts = guestName!.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  /// Devuelve una versión truncada del comentario para previews
  String get commentPreview {
    if (comment.length <= 100) return comment;
    return '${comment.substring(0, 100)}...';
  }

  // ============================================
  // FACTORY METHODS
  // ============================================

  /// Crea una entidad desde un mapa JSON
  factory ReviewEntity.fromJson(Map<String, dynamic> json) {
    return ReviewEntity(
      id: json['id'] as String,
      propertyId: json['property_id'] as String,
      unitId: json['unit_id'] as String?,
      guestId: json['guest_id'] as String?,
      bookingId: json['booking_id'] as String?,
      rating: json['rating'] as int,
      title: json['title'] as String?,
      comment: json['comment'] as String,
      isVerified: json['is_verified'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      // Campos joined
      guestName: json['guest_name'] as String?,
      propertyName: json['property_name'] as String?,
      unitName: json['unit_name'] as String?,
    );
  }

  // ============================================
  // METHODS
  // ============================================

  /// Crea una copia con valores modificados
  ReviewEntity copyWith({
    String? id,
    String? propertyId,
    String? unitId,
    String? guestId,
    String? bookingId,
    int? rating,
    String? title,
    String? comment,
    bool? isVerified,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? guestName,
    String? propertyName,
    String? unitName,
  }) {
    return ReviewEntity(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      unitId: unitId ?? this.unitId,
      guestId: guestId ?? this.guestId,
      bookingId: bookingId ?? this.bookingId,
      rating: rating ?? this.rating,
      title: title ?? this.title,
      comment: comment ?? this.comment,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      guestName: guestName ?? this.guestName,
      propertyName: propertyName ?? this.propertyName,
      unitName: unitName ?? this.unitName,
    );
  }

  /// Convierte la entidad a un mapa JSON para inserción/actualización
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'property_id': propertyId,
      'unit_id': unitId,
      'guest_id': guestId,
      'booking_id': bookingId,
      'rating': rating,
      'title': title,
      'comment': comment,
      'is_verified': isVerified,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Convierte a JSON para crear (sin id ni timestamps)
  Map<String, dynamic> toJsonForCreate() {
    return {
      'property_id': propertyId,
      'unit_id': unitId,
      'guest_id': guestId,
      'booking_id': bookingId,
      'rating': rating,
      'title': title,
      'comment': comment,
      'is_verified': isVerified,
    };
  }

  @override
  List<Object?> get props => [
        id,
        propertyId,
        unitId,
        guestId,
        bookingId,
        rating,
        title,
        comment,
        isVerified,
        isActive,
        createdAt,
        updatedAt,
        guestName,
        propertyName,
        unitName,
      ];
}

/// Extensión para calcular estadísticas de una lista de reseñas
extension ReviewListStats on List<ReviewEntity> {
  /// Calcula el rating promedio
  double get averageRating {
    if (isEmpty) return 0.0;
    final sum = fold<int>(0, (sum, r) => sum + r.rating);
    return sum / length;
  }

  /// Calcula la distribución de ratings {5: 10, 4: 5, ...}
  Map<int, int> get ratingDistribution {
    final distribution = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final review in this) {
      distribution[review.rating] = (distribution[review.rating] ?? 0) + 1;
    }
    return distribution;
  }

  /// Filtra por rating mínimo
  List<ReviewEntity> filterByMinRating(int minRating) {
    return where((r) => r.rating >= minRating).toList();
  }

  /// Ordena por fecha (más reciente primero)
  List<ReviewEntity> sortedByDate({bool ascending = false}) {
    final sorted = List<ReviewEntity>.from(this);
    sorted.sort((a, b) {
      final comparison = a.createdAt.compareTo(b.createdAt);
      return ascending ? comparison : -comparison;
    });
    return sorted;
  }
}
