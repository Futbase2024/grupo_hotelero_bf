import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../entities/collection_entity.dart';
import '../entities/place_entity.dart';
import '../repositories/places_repository.dart';

// ============== EVENTS ==============

/// Eventos base del QueVerBloc
abstract class QueVerEvent extends Equatable {
  const QueVerEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para cargar datos al iniciar
class QueVerStarted extends QueVerEvent {
  const QueVerStarted();
}

/// Evento para solicitar la carga de datos
class QueVerLoadRequested extends QueVerEvent {
  const QueVerLoadRequested();
}

/// Evento para refrescar los datos
class QueVerRefreshRequested extends QueVerEvent {
  const QueVerRefreshRequested();
}

/// Evento para cambiar el filtro de categoría
class QueVerCategoryFilterChanged extends QueVerEvent {
  const QueVerCategoryFilterChanged({this.category});

  final String? category; // null significa "todas"

  @override
  List<Object?> get props => [category];
}

/// Evento para cambiar el filtro de nivel
class QueVerLevelFilterChanged extends QueVerEvent {
  const QueVerLevelFilterChanged({this.level});

  final PlaceLevel? level; // null significa "todos"

  @override
  List<Object?> get props => [level];
}

/// Evento para buscar lugares por texto
class QueVerSearchChanged extends QueVerEvent {
  const QueVerSearchChanged({required this.query});

  final String query;

  @override
  List<Object?> get props => [query];
}

/// Evento para limpiar filtros
class QueVerClearFilters extends QueVerEvent {
  const QueVerClearFilters();
}

// ============== STATES ==============

/// Estados base del QueVerBloc
abstract class QueVerState extends Equatable {
  const QueVerState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class QueVerInitial extends QueVerState {
  const QueVerInitial();
}

/// Estado de carga
class QueVerLoading extends QueVerState {
  const QueVerLoading();
}

/// Estado con datos cargados
class QueVerLoaded extends QueVerState {
  const QueVerLoaded({
    required this.allPlaces,
    required this.filteredPlaces,
    required this.collections,
    required this.categoriesWithCount,
    required this.levelsWithCount,
    this.selectedCategory,
    this.selectedLevel,
    this.searchQuery = '',
    this.isRefreshing = false,
  });

  final List<PlaceEntity> allPlaces;
  final List<PlaceEntity> filteredPlaces;
  final List<CollectionEntity> collections;
  final Map<String, int> categoriesWithCount;
  final Map<PlaceLevel, int> levelsWithCount;
  final String? selectedCategory;
  final PlaceLevel? selectedLevel;
  final String searchQuery;
  final bool isRefreshing;

  /// Indica si hay filtros activos
  bool get hasActiveFilters =>
      selectedCategory != null ||
      selectedLevel != null ||
      searchQuery.isNotEmpty;

  /// Lugares agrupados por nivel
  Map<PlaceLevel, List<PlaceEntity>> get placesByLevel {
    final map = <PlaceLevel, List<PlaceEntity>>{};
    for (final place in filteredPlaces) {
      map.putIfAbsent(place.level, () => []).add(place);
    }
    return map;
  }

  /// Categorías disponibles ordenadas por nombre
  List<String> get availableCategories => categoriesWithCount.keys.toList()..sort();

  /// Niveles disponibles ordenados
  List<PlaceLevel> get availableLevels => PlaceLevel.values
      .where((level) => levelsWithCount.containsKey(level))
      .toList();

  /// Cantidad de resultados
  int get resultCount => filteredPlaces.length;

  @override
  List<Object?> get props => [
        allPlaces,
        filteredPlaces,
        collections,
        categoriesWithCount,
        levelsWithCount,
        selectedCategory,
        selectedLevel,
        searchQuery,
        isRefreshing,
      ];
}

/// Estado de error
class QueVerError extends QueVerState {
  const QueVerError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

// ============== BLOC ==============

/// BLoC para gestionar el estado de la guía "¿Qué ver?"
class QueVerBloc extends Bloc<QueVerEvent, QueVerState> {
  QueVerBloc({
    required PlacesRepository placesRepository,
  })  : _placesRepository = placesRepository,
        super(const QueVerInitial()) {
    on<QueVerStarted>(_onStarted);
    on<QueVerLoadRequested>(_onLoadRequested);
    on<QueVerRefreshRequested>(_onRefreshRequested);
    on<QueVerCategoryFilterChanged>(_onCategoryFilterChanged);
    on<QueVerLevelFilterChanged>(_onLevelFilterChanged);
    on<QueVerSearchChanged>(_onSearchChanged);
    on<QueVerClearFilters>(_onClearFilters);
  }

  final PlacesRepository _placesRepository;

  /// Maneja el evento de inicio
  Future<void> _onStarted(
    QueVerStarted event,
    Emitter<QueVerState> emit,
  ) async {
    emit(const QueVerLoading());
    await _loadData(emit);
  }

  /// Maneja la solicitud de carga
  Future<void> _onLoadRequested(
    QueVerLoadRequested event,
    Emitter<QueVerState> emit,
  ) async {
    emit(const QueVerLoading());
    await _loadData(emit);
  }

  /// Maneja la solicitud de refresco
  Future<void> _onRefreshRequested(
    QueVerRefreshRequested event,
    Emitter<QueVerState> emit,
  ) async {
    final currentState = state;
    if (currentState is QueVerLoaded) {
      emit(QueVerLoaded(
        allPlaces: currentState.allPlaces,
        filteredPlaces: currentState.filteredPlaces,
        collections: currentState.collections,
        categoriesWithCount: currentState.categoriesWithCount,
        levelsWithCount: currentState.levelsWithCount,
        selectedCategory: currentState.selectedCategory,
        selectedLevel: currentState.selectedLevel,
        searchQuery: currentState.searchQuery,
        isRefreshing: true,
      ));
      await _loadData(
        emit,
        preserveFilters: true,
        previousCategory: currentState.selectedCategory,
        previousLevel: currentState.selectedLevel,
        previousSearch: currentState.searchQuery,
      );
    }
  }

  /// Maneja el cambio de filtro de categoría
  Future<void> _onCategoryFilterChanged(
    QueVerCategoryFilterChanged event,
    Emitter<QueVerState> emit,
  ) async {
    final currentState = state;
    if (currentState is QueVerLoaded) {
      _applyFilters(
        emit,
        allPlaces: currentState.allPlaces,
        collections: currentState.collections,
        categoriesWithCount: currentState.categoriesWithCount,
        levelsWithCount: currentState.levelsWithCount,
        category: event.category,
        level: currentState.selectedLevel,
        search: currentState.searchQuery,
      );
    }
  }

  /// Maneja el cambio de filtro de nivel
  Future<void> _onLevelFilterChanged(
    QueVerLevelFilterChanged event,
    Emitter<QueVerState> emit,
  ) async {
    final currentState = state;
    if (currentState is QueVerLoaded) {
      _applyFilters(
        emit,
        allPlaces: currentState.allPlaces,
        collections: currentState.collections,
        categoriesWithCount: currentState.categoriesWithCount,
        levelsWithCount: currentState.levelsWithCount,
        category: currentState.selectedCategory,
        level: event.level,
        search: currentState.searchQuery,
      );
    }
  }

  /// Maneja el cambio de búsqueda
  Future<void> _onSearchChanged(
    QueVerSearchChanged event,
    Emitter<QueVerState> emit,
  ) async {
    final currentState = state;
    if (currentState is QueVerLoaded) {
      _applyFilters(
        emit,
        allPlaces: currentState.allPlaces,
        collections: currentState.collections,
        categoriesWithCount: currentState.categoriesWithCount,
        levelsWithCount: currentState.levelsWithCount,
        category: currentState.selectedCategory,
        level: currentState.selectedLevel,
        search: event.query,
      );
    }
  }

  /// Maneja la limpieza de filtros
  Future<void> _onClearFilters(
    QueVerClearFilters event,
    Emitter<QueVerState> emit,
  ) async {
    final currentState = state;
    if (currentState is QueVerLoaded) {
      _applyFilters(
        emit,
        allPlaces: currentState.allPlaces,
        collections: currentState.collections,
        categoriesWithCount: currentState.categoriesWithCount,
        levelsWithCount: currentState.levelsWithCount,
        category: null,
        level: null,
        search: '',
      );
    }
  }

  /// Carga los datos desde el repositorio
  Future<void> _loadData(
    Emitter<QueVerState> emit, {
    bool preserveFilters = false,
    String? previousCategory,
    PlaceLevel? previousLevel,
    String? previousSearch,
  }) async {
    try {
      final places = await _placesRepository.getAllPlaces();
      final collections = await _placesRepository.getAllCollections();
      final categoriesWithCount = await _placesRepository.getCategoriesWithCount();
      final levelsWithCount = await _placesRepository.getLevelsWitCount();

      final category = preserveFilters ? previousCategory : null;
      final level = preserveFilters ? previousLevel : null;
      final search = preserveFilters ? (previousSearch ?? '') : '';

      _applyFilters(
        emit,
        allPlaces: places,
        collections: collections,
        categoriesWithCount: categoriesWithCount,
        levelsWithCount: levelsWithCount,
        category: category,
        level: level,
        search: search,
      );
    } catch (e) {
      emit(QueVerError(message: _getErrorMessage(e)));
    }
  }

  /// Aplica los filtros a los lugares
  void _applyFilters(
    Emitter<QueVerState> emit, {
    required List<PlaceEntity> allPlaces,
    required List<CollectionEntity> collections,
    required Map<String, int> categoriesWithCount,
    required Map<PlaceLevel, int> levelsWithCount,
    required String? category,
    required PlaceLevel? level,
    required String search,
  }) {
    var filteredPlaces = List<PlaceEntity>.from(allPlaces);

    // Filtrar por categoría
    if (category != null) {
      filteredPlaces = filteredPlaces
          .where((place) => place.categories.contains(category))
          .toList();
    }

    // Filtrar por nivel
    if (level != null) {
      filteredPlaces = filteredPlaces
          .where((place) => place.level == level)
          .toList();
    }

    // Filtrar por búsqueda
    if (search.isNotEmpty) {
      final lowerSearch = search.toLowerCase();
      filteredPlaces = filteredPlaces.where((place) {
        return place.title.toLowerCase().contains(lowerSearch) ||
            place.shortDescription.toLowerCase().contains(lowerSearch) ||
            place.tags.any((tag) => tag.toLowerCase().contains(lowerSearch));
      }).toList();
    }

    emit(QueVerLoaded(
      allPlaces: allPlaces,
      filteredPlaces: filteredPlaces,
      collections: collections,
      categoriesWithCount: categoriesWithCount,
      levelsWithCount: levelsWithCount,
      selectedCategory: category,
      selectedLevel: level,
      searchQuery: search,
    ));
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

    return 'Ha ocurrido un error al cargar los lugares. Por favor, intenta de nuevo.';
  }
}
