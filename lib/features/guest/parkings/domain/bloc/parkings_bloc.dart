import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../entities/unit_parking_entity.dart';
import '../repositories/parkings_repository.dart';

// ============== EVENTS ==============

/// Eventos base del ParkingsBloc
abstract class ParkingsEvent extends Equatable {
  const ParkingsEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para cargar todos los parkings agrupados por unidad
class ParkingsStarted extends ParkingsEvent {
  const ParkingsStarted();
}

/// Evento para solicitar la carga de datos
class ParkingsLoadRequested extends ParkingsEvent {
  const ParkingsLoadRequested();
}

/// Evento para refrescar los datos
class ParkingsRefreshRequested extends ParkingsEvent {
  const ParkingsRefreshRequested();
}

/// Evento para cargar parkings de una unidad específica
class ParkingsByUnitRequested extends ParkingsEvent {
  const ParkingsByUnitRequested({required this.unitId});

  final String unitId;

  @override
  List<Object?> get props => [unitId];
}

// ============== STATES ==============

/// Estados base del ParkingsBloc
abstract class ParkingsState extends Equatable {
  const ParkingsState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class ParkingsInitial extends ParkingsState {
  const ParkingsInitial();
}

/// Estado de carga
class ParkingsLoading extends ParkingsState {
  const ParkingsLoading();
}

/// Estado con todos los parkings agrupados por unidad
class AllUnitParkingsLoaded extends ParkingsState {
  const AllUnitParkingsLoaded({
    required this.unitParkings,
    this.isRefreshing = false,
  });

  final List<UnitParkingEntity> unitParkings;
  final bool isRefreshing;

  /// Parkings únicos de habitaciones de hotel (sin duplicar)
  List<UnitParkingEntity> get hotelParkings {
    final hotelRooms = unitParkings.where((up) => up.isHotelRoom).toList();
    final seenParkingIds = <String>{};
    final uniqueParkings = <UnitParkingEntity>[];

    for (final up in hotelRooms) {
      if (!seenParkingIds.contains(up.parkingId)) {
        seenParkingIds.add(up.parkingId);
        uniqueParkings.add(up);
      }
    }

    // Ordenar por prioridad
    uniqueParkings.sort((a, b) => a.priority.compareTo(b.priority));
    return uniqueParkings;
  }

  /// Parkings que no son de hotel (apartamentos y habitaciones normales)
  List<UnitParkingEntity> get nonHotelParkings =>
      unitParkings.where((up) => !up.isHotelRoom).toList();

  /// Indica si hay parkings de hotel
  bool get hasHotelParkings => hotelParkings.isNotEmpty;

  /// Nombre del hotel (tomado del primer parking de hotel)
  String? get hotelName =>
      hotelParkings.isNotEmpty ? hotelParkings.first.propertyName : null;

  /// Agrupa los parkings por unidad (solo no-hotel)
  Map<String, List<UnitParkingEntity>> get groupedParkings {
    final map = <String, List<UnitParkingEntity>>{};
    for (final up in nonHotelParkings) {
      final unitId = up.unitId;
      map.putIfAbsent(unitId, () => []);
      map[unitId]!.add(up);
    }
    // Ordenar cada grupo por prioridad
    for (final unitId in map.keys) {
      map[unitId]!.sort((a, b) => a.priority.compareTo(b.priority));
    }
    return map;
  }

  /// Cantidad total de parkings
  int get count => unitParkings.length;

  /// Cantidad de unidades con parkings (excluyendo hotel)
  int get unitsCount => groupedParkings.length;

  @override
  List<Object?> get props => [unitParkings, isRefreshing];
}

/// Estado con parkings de una unidad específica
class UnitParkingsLoaded extends ParkingsState {
  const UnitParkingsLoaded({
    required this.unitId,
    required this.unitParkings,
    this.isRefreshing = false,
  });

  final String unitId;
  final List<UnitParkingEntity> unitParkings;
  final bool isRefreshing;

  /// Cantidad de parkings
  int get count => unitParkings.length;

  /// Lista de parkings ordenados por prioridad
  List<UnitParkingEntity> get sortedParkings =>
      List.from(unitParkings)..sort((a, b) => a.priority.compareTo(b.priority));

  /// Parking más cercano (prioridad 0)
  UnitParkingEntity? get closestParking =>
      unitParkings.isEmpty ? null : sortedParkings.first;

  @override
  List<Object?> get props => [unitId, unitParkings, isRefreshing];
}

/// Estado de error
class ParkingsError extends ParkingsState {
  const ParkingsError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

// ============== BLOC ==============

/// BLoC para gestionar el estado de los parkings
class ParkingsBloc extends Bloc<ParkingsEvent, ParkingsState> {
  ParkingsBloc({
    required ParkingsRepository parkingsRepository,
  })  : _parkingsRepository = parkingsRepository,
        super(const ParkingsInitial()) {
    on<ParkingsStarted>(_onStarted);
    on<ParkingsLoadRequested>(_onLoadRequested);
    on<ParkingsRefreshRequested>(_onRefreshRequested);
    on<ParkingsByUnitRequested>(_onByUnitRequested);
  }

  final ParkingsRepository _parkingsRepository;

  /// Maneja el evento de inicio - carga todos los parkings agrupados
  Future<void> _onStarted(
    ParkingsStarted event,
    Emitter<ParkingsState> emit,
  ) async {
    emit(const ParkingsLoading());
    await _loadAllUnitParkings(emit);
  }

  /// Maneja la solicitud de carga
  Future<void> _onLoadRequested(
    ParkingsLoadRequested event,
    Emitter<ParkingsState> emit,
  ) async {
    emit(const ParkingsLoading());
    await _loadAllUnitParkings(emit);
  }

  /// Maneja la solicitud de refresco
  Future<void> _onRefreshRequested(
    ParkingsRefreshRequested event,
    Emitter<ParkingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is AllUnitParkingsLoaded) {
      emit(AllUnitParkingsLoaded(
        unitParkings: currentState.unitParkings,
        isRefreshing: true,
      ));
      await _loadAllUnitParkings(emit);
    } else if (currentState is UnitParkingsLoaded) {
      emit(UnitParkingsLoaded(
        unitId: currentState.unitId,
        unitParkings: currentState.unitParkings,
        isRefreshing: true,
      ));
      await _loadParkingsByUnit(emit, currentState.unitId);
    }
  }

  /// Maneja la solicitud de parkings por unidad
  Future<void> _onByUnitRequested(
    ParkingsByUnitRequested event,
    Emitter<ParkingsState> emit,
  ) async {
    emit(const ParkingsLoading());
    await _loadParkingsByUnit(emit, event.unitId);
  }

  /// Carga todos los parkings agrupados por unidad
  Future<void> _loadAllUnitParkings(Emitter<ParkingsState> emit) async {
    try {
      final unitParkings = await _parkingsRepository.getAllUnitParkings();
      emit(AllUnitParkingsLoaded(unitParkings: unitParkings));
    } catch (e) {
      emit(ParkingsError(message: _getErrorMessage(e)));
    }
  }

  /// Carga los parkings de una unidad específica
  Future<void> _loadParkingsByUnit(
    Emitter<ParkingsState> emit,
    String unitId,
  ) async {
    try {
      final unitParkings =
          await _parkingsRepository.getParkingsByUnitId(unitId);
      emit(UnitParkingsLoaded(
        unitId: unitId,
        unitParkings: unitParkings,
      ));
    } catch (e) {
      emit(ParkingsError(message: _getErrorMessage(e)));
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

    return 'Ha ocurrido un error al cargar los parkings. Por favor, intenta de nuevo.';
  }
}
