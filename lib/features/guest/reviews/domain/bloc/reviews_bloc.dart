import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../entities/review_entity.dart';
import '../repositories/reviews_repository.dart';

// ============== EVENTS ==============

/// Eventos base del ReviewsBloc
abstract class ReviewsEvent extends Equatable {
  const ReviewsEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para cargar reseñas al iniciar (por propiedad)
class ReviewsStarted extends ReviewsEvent {
  const ReviewsStarted({required this.propertyId});

  final String propertyId;

  @override
  List<Object?> get props => [propertyId];
}

/// Evento para cargar reseñas de una unidad específica
class ReviewsLoadByUnit extends ReviewsEvent {
  const ReviewsLoadByUnit({required this.unitId});

  final String unitId;

  @override
  List<Object?> get props => [unitId];
}

/// Evento para refrescar la lista de reseñas
class ReviewsRefreshRequested extends ReviewsEvent {
  const ReviewsRefreshRequested();
}

/// Evento para crear una nueva reseña
class ReviewsCreate extends ReviewsEvent {
  const ReviewsCreate({required this.review});

  final ReviewEntity review;

  @override
  List<Object?> get props => [review];
}

/// Evento para actualizar una reseña existente
class ReviewsUpdate extends ReviewsEvent {
  const ReviewsUpdate({required this.review});

  final ReviewEntity review;

  @override
  List<Object?> get props => [review];
}

/// Evento para eliminar una reseña
class ReviewsDelete extends ReviewsEvent {
  const ReviewsDelete({required this.reviewId});

  final String reviewId;

  @override
  List<Object?> get props => [reviewId];
}

/// Evento para filtrar por rating mínimo
class ReviewsFilterByRating extends ReviewsEvent {
  const ReviewsFilterByRating({this.minRating});

  final int? minRating;

  @override
  List<Object?> get props => [minRating];
}

/// Evento para verificar si el usuario puede reseñar
class ReviewsCheckCanReview extends ReviewsEvent {
  const ReviewsCheckCanReview({
    required this.guestId,
    required this.propertyId,
  });

  final String guestId;
  final String propertyId;

  @override
  List<Object?> get props => [guestId, propertyId];
}

// ============== STATES ==============

/// Estados base del ReviewsBloc
abstract class ReviewsState extends Equatable {
  const ReviewsState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class ReviewsInitial extends ReviewsState {
  const ReviewsInitial();
}

/// Estado de carga
class ReviewsLoading extends ReviewsState {
  const ReviewsLoading();
}

/// Estado con datos cargados
class ReviewsLoaded extends ReviewsState {
  const ReviewsLoaded({
    required this.reviews,
    required this.propertyId,
    this.unitId,
    this.filterMinRating,
    this.isRefreshing = false,
    this.canReview,
  });

  final List<ReviewEntity> reviews;
  final String propertyId;
  final String? unitId;
  final int? filterMinRating;
  final bool isRefreshing;
  final bool? canReview;

  /// Reseñas filtradas
  List<ReviewEntity> get filteredReviews {
    if (filterMinRating == null) return reviews;
    return reviews.where((r) => r.rating >= filterMinRating!).toList();
  }

  /// Rating promedio
  double get averageRating => filteredReviews.averageRating;

  /// Distribución de ratings
  Map<int, int> get ratingDistribution => filteredReviews.ratingDistribution;

  /// Total de reseñas
  int get totalReviews => filteredReviews.length;

  /// Indica si hay reseñas
  bool get hasReviews => filteredReviews.isNotEmpty;

  /// Indica si el usuario puede crear reseña
  bool get userCanReview => canReview ?? false;

  @override
  List<Object?> get props => [
        reviews,
        propertyId,
        unitId,
        filterMinRating,
        isRefreshing,
        canReview,
      ];
}

/// Estado de error
class ReviewsError extends ReviewsState {
  const ReviewsError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Estado mientras se crea una reseña
class ReviewCreating extends ReviewsState {
  const ReviewCreating();
}

/// Estado cuando se ha creado una reseña exitosamente
class ReviewCreated extends ReviewsState {
  const ReviewCreated({required this.review});

  final ReviewEntity review;

  @override
  List<Object?> get props => [review];
}

/// Estado mientras se actualiza una reseña
class ReviewUpdating extends ReviewsState {
  const ReviewUpdating();
}

/// Estado mientras se elimina una reseña
class ReviewDeleting extends ReviewsState {
  const ReviewDeleting();
}

// ============== BLOC ==============

/// BLoC para gestionar el estado de las reseñas
class ReviewsBloc extends Bloc<ReviewsEvent, ReviewsState> {
  ReviewsBloc({
    required ReviewsRepository reviewsRepository,
  })  : _reviewsRepository = reviewsRepository,
        super(const ReviewsInitial()) {
    on<ReviewsStarted>(_onStarted);
    on<ReviewsLoadByUnit>(_onLoadByUnit);
    on<ReviewsRefreshRequested>(_onRefreshRequested);
    on<ReviewsCreate>(_onCreate);
    on<ReviewsUpdate>(_onUpdate);
    on<ReviewsDelete>(_onDelete);
    on<ReviewsFilterByRating>(_onFilterByRating);
    on<ReviewsCheckCanReview>(_onCheckCanReview);
  }

  final ReviewsRepository _reviewsRepository;

  /// Maneja el evento de inicio
  Future<void> _onStarted(
    ReviewsStarted event,
    Emitter<ReviewsState> emit,
  ) async {
    emit(const ReviewsLoading());
    await _loadReviewsByProperty(emit, event.propertyId);
  }

  /// Maneja la carga de reseñas por unidad
  Future<void> _onLoadByUnit(
    ReviewsLoadByUnit event,
    Emitter<ReviewsState> emit,
  ) async {
    emit(const ReviewsLoading());
    await _loadReviewsByUnit(emit, event.unitId);
  }

  /// Maneja la solicitud de refresco
  Future<void> _onRefreshRequested(
    ReviewsRefreshRequested event,
    Emitter<ReviewsState> emit,
  ) async {
    final currentState = state;
    if (currentState is ReviewsLoaded) {
      emit(ReviewsLoaded(
        reviews: currentState.reviews,
        propertyId: currentState.propertyId,
        unitId: currentState.unitId,
        filterMinRating: currentState.filterMinRating,
        isRefreshing: true,
        canReview: currentState.canReview,
      ));

      if (currentState.unitId != null) {
        await _loadReviewsByUnit(emit, currentState.unitId!);
      } else {
        await _loadReviewsByProperty(emit, currentState.propertyId);
      }
    }
  }

  /// Maneja la creación de una reseña
  Future<void> _onCreate(
    ReviewsCreate event,
    Emitter<ReviewsState> emit,
  ) async {
    emit(const ReviewCreating());
    try {
      final review = await _reviewsRepository.create(event.review);
      emit(ReviewCreated(review: review));
    } catch (e) {
      emit(ReviewsError(message: _getErrorMessage(e)));
    }
  }

  /// Maneja la actualización de una reseña
  Future<void> _onUpdate(
    ReviewsUpdate event,
    Emitter<ReviewsState> emit,
  ) async {
    emit(const ReviewUpdating());
    try {
      await _reviewsRepository.update(event.review);
      // Recargar las reseñas después de actualizar
      final currentState = state;
      if (currentState is ReviewsLoaded) {
        await _loadReviewsByProperty(emit, currentState.propertyId);
      }
    } catch (e) {
      emit(ReviewsError(message: _getErrorMessage(e)));
    }
  }

  /// Maneja la eliminación de una reseña
  Future<void> _onDelete(
    ReviewsDelete event,
    Emitter<ReviewsState> emit,
  ) async {
    emit(const ReviewDeleting());
    try {
      await _reviewsRepository.delete(event.reviewId);
      // Recargar las reseñas después de eliminar
      final currentState = state;
      if (currentState is ReviewsLoaded) {
        await _loadReviewsByProperty(emit, currentState.propertyId);
      }
    } catch (e) {
      emit(ReviewsError(message: _getErrorMessage(e)));
    }
  }

  /// Maneja el filtrado por rating
  Future<void> _onFilterByRating(
    ReviewsFilterByRating event,
    Emitter<ReviewsState> emit,
  ) async {
    final currentState = state;
    if (currentState is ReviewsLoaded) {
      emit(ReviewsLoaded(
        reviews: currentState.reviews,
        propertyId: currentState.propertyId,
        unitId: currentState.unitId,
        filterMinRating: event.minRating,
        canReview: currentState.canReview,
      ));
    }
  }

  /// Maneja la verificación de si puede reseñar
  Future<void> _onCheckCanReview(
    ReviewsCheckCanReview event,
    Emitter<ReviewsState> emit,
  ) async {
    final currentState = state;
    if (currentState is ReviewsLoaded) {
      try {
        final canReview = await _reviewsRepository.canGuestReview(
          event.guestId,
          event.propertyId,
        );
        emit(ReviewsLoaded(
          reviews: currentState.reviews,
          propertyId: currentState.propertyId,
          unitId: currentState.unitId,
          filterMinRating: currentState.filterMinRating,
          canReview: canReview,
        ));
      } catch (_) {
        // Si hay error, mantener el estado actual
      }
    }
  }

  /// Carga las reseñas desde el repositorio por propiedad
  Future<void> _loadReviewsByProperty(
    Emitter<ReviewsState> emit,
    String propertyId,
  ) async {
    try {
      final reviews =
          await _reviewsRepository.getByPropertyId(propertyId);

      emit(ReviewsLoaded(
        reviews: reviews,
        propertyId: propertyId,
      ));
    } catch (e) {
      emit(ReviewsError(message: _getErrorMessage(e)));
    }
  }

  /// Carga las reseñas desde el repositorio por unidad
  Future<void> _loadReviewsByUnit(
    Emitter<ReviewsState> emit,
    String unitId,
  ) async {
    try {
      final reviews = await _reviewsRepository.getByUnitId(unitId);

      // Obtener propertyId de la primera reseña si existe
      final propertyId = reviews.isNotEmpty
          ? reviews.first.propertyId
          : '';

      emit(ReviewsLoaded(
        reviews: reviews,
        propertyId: propertyId,
        unitId: unitId,
      ));
    } catch (e) {
      emit(ReviewsError(message: _getErrorMessage(e)));
    }
  }

  /// Obtiene un mensaje de error amigable
  String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') ||
        errorString.contains('connection')) {
      return 'Error de conexión. Por favor, verifica tu conexión a internet.';
    }

    if (errorString.contains('timeout')) {
      return 'La solicitud ha tardado demasiado. Por favor, intenta de nuevo.';
    }

    if (errorString.contains('unauthorized') ||
        errorString.contains('forbidden')) {
      return 'No tienes permisos para realizar esta acción.';
    }

    if (errorString.contains('duplicate') ||
        errorString.contains('already exists')) {
      return 'Ya has dejado una reseña para esta propiedad.';
    }

    return 'Ha ocurrido un error. Por favor, intenta de nuevo.';
  }
}
