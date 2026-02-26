import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../entities/property_entity.dart';
import '../entities/unit_entity.dart';
import '../entities/unit_photo_entity.dart';
import '../repositories/properties_repository.dart';

// ============== EVENTS ==============

/// Eventos base del AlojamientosBloc
abstract class AlojamientosEvent extends Equatable {
  const AlojamientosEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para cargar los alojamientos al iniciar
class AlojamientosStarted extends AlojamientosEvent {
  const AlojamientosStarted();
}

/// Evento para solicitar la carga de alojamientos
class AlojamientosLoadRequested extends AlojamientosEvent {
  const AlojamientosLoadRequested();
}

/// Evento para refrescar la lista de alojamientos
class AlojamientosRefreshRequested extends AlojamientosEvent {
  const AlojamientosRefreshRequested();
}

/// Evento para buscar alojamientos
class AlojamientosSearchChanged extends AlojamientosEvent {
  const AlojamientosSearchChanged({required this.query});

  final String query;

  @override
  List<Object?> get props => [query];
}

/// Evento para limpiar la búsqueda
class AlojamientosSearchCleared extends AlojamientosEvent {
  const AlojamientosSearchCleared();
}

/// Evento para cargar el detalle de un alojamiento
class AlojamientoDetailRequested extends AlojamientosEvent {
  const AlojamientoDetailRequested({required this.propertyId});

  final String propertyId;

  @override
  List<Object?> get props => [propertyId];
}

/// Evento para cargar el detalle de una unidad
class UnitDetailRequested extends AlojamientosEvent {
  const UnitDetailRequested({required this.unitId});

  final String unitId;

  @override
  List<Object?> get props => [unitId];
}

// ============== STATES ==============

/// Estados base del AlojamientosBloc
abstract class AlojamientosState extends Equatable {
  const AlojamientosState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class AlojamientosInitial extends AlojamientosState {
  const AlojamientosInitial();
}

/// Estado de carga
class AlojamientosLoading extends AlojamientosState {
  const AlojamientosLoading();
}

/// Estado con datos cargados
class AlojamientosLoaded extends AlojamientosState {
  const AlojamientosLoaded({
    required this.properties,
    this.coverPhotos = const {},
    this.searchQuery = '',
    this.isRefreshing = false,
  });

  final List<PropertyEntity> properties;
  final Map<String, UnitPhotoEntity> coverPhotos;
  final String searchQuery;
  final bool isRefreshing;

  /// Propiedades filtradas por búsqueda
  List<PropertyEntity> get filteredProperties {
    if (searchQuery.isEmpty) return properties;
    final query = searchQuery.toLowerCase();
    return properties.where((p) {
      return p.name.toLowerCase().contains(query) ||
          (p.city?.toLowerCase().contains(query) ?? false) ||
          (p.address?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  List<Object?> get props => [properties, coverPhotos, searchQuery, isRefreshing];
}

/// Estado de detalle de alojamiento cargado
class AlojamientoDetailLoaded extends AlojamientosState {
  const AlojamientoDetailLoaded({required this.property});

  final PropertyEntity property;

  @override
  List<Object?> get props => [property];
}

/// Estado de detalle de unidad cargado
class UnitDetailLoaded extends AlojamientosState {
  const UnitDetailLoaded({
    required this.unit,
    this.photos = const [],
  });

  final UnitEntity unit;
  final List<UnitPhotoEntity> photos;

  @override
  List<Object?> get props => [unit, photos];
}

/// Estado de error
class AlojamientosError extends AlojamientosState {
  const AlojamientosError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

// ============== BLOC ==============

/// BLoC para gestionar el estado de alojamientos
class AlojamientosBloc extends Bloc<AlojamientosEvent, AlojamientosState> {
  AlojamientosBloc({
    required PropertiesRepository propertiesRepository,
  })  : _propertiesRepository = propertiesRepository,
        super(const AlojamientosInitial()) {
    on<AlojamientosStarted>(_onStarted);
    on<AlojamientosLoadRequested>(_onLoadRequested);
    on<AlojamientosRefreshRequested>(_onRefreshRequested);
    on<AlojamientosSearchChanged>(_onSearchChanged);
    on<AlojamientosSearchCleared>(_onSearchCleared);
    on<AlojamientoDetailRequested>(_onDetailRequested);
    on<UnitDetailRequested>(_onUnitDetailRequested);
  }

  final PropertiesRepository _propertiesRepository;

  /// Maneja el evento de inicio
  Future<void> _onStarted(
    AlojamientosStarted event,
    Emitter<AlojamientosState> emit,
  ) async {
    emit(const AlojamientosLoading());
    await _loadProperties(emit);
  }

  /// Maneja la solicitud de carga
  Future<void> _onLoadRequested(
    AlojamientosLoadRequested event,
    Emitter<AlojamientosState> emit,
  ) async {
    emit(const AlojamientosLoading());
    await _loadProperties(emit);
  }

  /// Maneja la solicitud de refresco
  Future<void> _onRefreshRequested(
    AlojamientosRefreshRequested event,
    Emitter<AlojamientosState> emit,
  ) async {
    final currentState = state;
    if (currentState is AlojamientosLoaded) {
      emit(AlojamientosLoaded(
        properties: currentState.properties,
        searchQuery: currentState.searchQuery,
        isRefreshing: true,
      ));
    }
    await _loadProperties(emit);
  }

  /// Maneja el cambio de búsqueda
  void _onSearchChanged(
    AlojamientosSearchChanged event,
    Emitter<AlojamientosState> emit,
  ) {
    final currentState = state;
    if (currentState is AlojamientosLoaded) {
      emit(AlojamientosLoaded(
        properties: currentState.properties,
        searchQuery: event.query,
      ));
    }
  }

  /// Maneja la limpieza de búsqueda
  void _onSearchCleared(
    AlojamientosSearchCleared event,
    Emitter<AlojamientosState> emit,
  ) {
    final currentState = state;
    if (currentState is AlojamientosLoaded) {
      emit(AlojamientosLoaded(
        properties: currentState.properties,
        searchQuery: '',
      ));
    }
  }

  /// Maneja la solicitud de detalle
  Future<void> _onDetailRequested(
    AlojamientoDetailRequested event,
    Emitter<AlojamientosState> emit,
  ) async {
    emit(const AlojamientosLoading());

    try {
      final property = await _propertiesRepository.getById(event.propertyId);

      if (property != null) {
        emit(AlojamientoDetailLoaded(property: property));
      } else {
        emit(const AlojamientosError(
          message: 'Alojamiento no encontrado',
        ));
      }
    } catch (e) {
      emit(AlojamientosError(message: _getErrorMessage(e)));
    }
  }

  /// Maneja la solicitud de detalle de unidad
  Future<void> _onUnitDetailRequested(
    UnitDetailRequested event,
    Emitter<AlojamientosState> emit,
  ) async {
    emit(const AlojamientosLoading());

    try {
      final unit = await _propertiesRepository.getUnitById(event.unitId);

      if (unit != null) {
        // Cargar las fotos de la unidad
        final photos = await _propertiesRepository.getUnitPhotos(event.unitId);
        emit(UnitDetailLoaded(unit: unit, photos: photos));
      } else {
        emit(const AlojamientosError(
          message: 'Unidad no encontrada',
        ));
      }
    } catch (e) {
      emit(AlojamientosError(message: _getErrorMessage(e)));
    }
  }

  /// Carga las propiedades desde el repositorio
  Future<void> _loadProperties(Emitter<AlojamientosState> emit) async {
    try {
      final properties = await _propertiesRepository.getAll();

      // Obtener IDs de todas las unidades para cargar sus fotos de cobertura
      final unitIds = properties
          .expand((p) => p.units)
          .map((u) => u.id)
          .toList();

      // Cargar fotos de cobertura
      final coverPhotos = await _propertiesRepository.getCoverPhotos(unitIds);

      emit(AlojamientosLoaded(
        properties: properties,
        coverPhotos: coverPhotos,
        searchQuery: '',
      ));
    } catch (e) {
      emit(AlojamientosError(message: _getErrorMessage(e)));
    }
  }

  /// Obtiene un mensaje de error amigable
  String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Error de conexión. Por favor, verifica tu conexión a internet.';
    }

    if (errorString.contains('timeout')) {
      return 'La solicitud ha tardado demasiado. Por favor, intenta de nuevo.';
    }

    if (errorString.contains('unauthorized') ||
        errorString.contains('forbidden')) {
      return 'No tienes permisos para ver los alojamientos.';
    }

    return 'Ha ocurrido un error al cargar los alojamientos. Por favor, intenta de nuevo.';
  }
}
