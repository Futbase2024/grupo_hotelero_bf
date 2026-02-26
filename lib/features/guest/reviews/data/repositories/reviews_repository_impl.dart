import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/constants/supabase_tables.dart';
import '../../domain/entities/review_entity.dart';
import '../../domain/repositories/reviews_repository.dart';

/// Implementación del repositorio de reseñas
class ReviewsRepositoryImpl implements ReviewsRepository {
  ReviewsRepositoryImpl({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  @override
  Future<List<ReviewEntity>> getByPropertyId(String propertyId) async {
    try {
      // Intentar usar la vista primero (con datos de guest)
      try {
        final response = await _supabase
            .from(SupabaseTables.reviewsWithGuest)
            .select()
            .eq('property_id', propertyId)
            .eq('is_active', true)
            .order('created_at', ascending: false);

        return response
            .map<ReviewEntity>((json) => ReviewEntity.fromJson(json))
            .toList();
      } catch (_) {
        // Si la vista no existe, usar la tabla directamente
        final response = await _supabase
            .from(SupabaseTables.reviews)
            .select()
            .eq('property_id', propertyId)
            .eq('is_active', true)
            .order('created_at', ascending: false);

        return response
            .map<ReviewEntity>((json) => ReviewEntity.fromJson(json))
            .toList();
      }
    } catch (e) {
      throw Exception('Error al cargar las reseñas: $e');
    }
  }

  @override
  Future<List<ReviewEntity>> getByUnitId(String unitId) async {
    try {
      try {
        final response = await _supabase
            .from(SupabaseTables.reviewsWithGuest)
            .select()
            .eq('unit_id', unitId)
            .eq('is_active', true)
            .order('created_at', ascending: false);

        return response
            .map<ReviewEntity>((json) => ReviewEntity.fromJson(json))
            .toList();
      } catch (_) {
        final response = await _supabase
            .from(SupabaseTables.reviews)
            .select()
            .eq('unit_id', unitId)
            .eq('is_active', true)
            .order('created_at', ascending: false);

        return response
            .map<ReviewEntity>((json) => ReviewEntity.fromJson(json))
            .toList();
      }
    } catch (e) {
      throw Exception('Error al cargar las reseñas: $e');
    }
  }

  @override
  Future<ReviewEntity?> getById(String id) async {
    try {
      try {
        final response = await _supabase
            .from(SupabaseTables.reviewsWithGuest)
            .select()
            .eq('id', id)
            .maybeSingle();

        if (response == null) return null;

        return ReviewEntity.fromJson(response);
      } catch (_) {
        final response = await _supabase
            .from(SupabaseTables.reviews)
            .select()
            .eq('id', id)
            .maybeSingle();

        if (response == null) return null;

        return ReviewEntity.fromJson(response);
      }
    } catch (e) {
      throw Exception('Error al cargar la reseña: $e');
    }
  }

  @override
  Future<List<ReviewEntity>> getByGuestId(String guestId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.reviews)
          .select()
          .eq('guest_id', guestId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return response
          .map<ReviewEntity>((json) => ReviewEntity.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al cargar las reseñas del huésped: $e');
    }
  }

  @override
  Future<ReviewEntity> create(ReviewEntity review) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.reviews)
          .insert(review.toJsonForCreate())
          .select()
          .single();

      return ReviewEntity.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear la reseña: $e');
    }
  }

  @override
  Future<ReviewEntity> update(ReviewEntity review) async {
    try {
      final updateData = {
        'rating': review.rating,
        'title': review.title,
        'comment': review.comment,
        'is_verified': review.isVerified,
      };

      final response = await _supabase
          .from(SupabaseTables.reviews)
          .update(updateData)
          .eq('id', review.id)
          .select()
          .single();

      return ReviewEntity.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar la reseña: $e');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      // Soft delete
      await _supabase
          .from(SupabaseTables.reviews)
          .update({'is_active': false}).eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar la reseña: $e');
    }
  }

  @override
  Future<double> getAverageRating(String propertyId) async {
    try {
      final reviews = await getByPropertyId(propertyId);
      return reviews.averageRating;
    } catch (e) {
      throw Exception('Error al obtener el rating promedio: $e');
    }
  }

  @override
  Future<Map<int, int>> getRatingDistribution(String propertyId) async {
    try {
      final reviews = await getByPropertyId(propertyId);
      return reviews.ratingDistribution;
    } catch (e) {
      throw Exception('Error al obtener la distribución de ratings: $e');
    }
  }

  @override
  Future<bool> canGuestReview(String guestId, String propertyId) async {
    try {
      // Verificar si el huésped ya dejó una reseña para esta propiedad
      final existingReviews = await _supabase
          .from(SupabaseTables.reviews)
          .select('id')
          .eq('guest_id', guestId)
          .eq('property_id', propertyId)
          .eq('is_active', true);

      if (existingReviews.isNotEmpty) {
        return false; // Ya dejó una reseña
      }

      // Verificar si el huésped tiene una reserva completada
      final bookings = await _supabase
          .from('bookings')
          .select('id')
          .eq('guest_id', guestId)
          .eq('property_id', propertyId)
          .eq('status', 'completed')
          .limit(1);

      return bookings.isNotEmpty;
    } catch (e) {
      // Si hay error, permitir reseñar por defecto
      return true;
    }
  }

  @override
  Stream<List<ReviewEntity>> watchByPropertyId(String propertyId) {
    return _supabase
        .from(SupabaseTables.reviews)
        .stream(primaryKey: ['id'])
        .asyncMap((reviews) async {
      // Filtrar por property_id y is_active
      final filteredReviews = reviews.where((review) {
        final reviewPropertyId = review['property_id'] as String?;
        final isActive = review['is_active'] as bool? ?? true;
        return reviewPropertyId == propertyId && isActive;
      }).toList();

      return filteredReviews
          .map((json) => ReviewEntity.fromJson(json))
          .toList();
    });
  }
}
