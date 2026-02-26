import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../entities/house_rule_entity.dart';
import '../repositories/house_rules_repository.dart';

// ============== EVENTS ==============

/// Eventos base del HouseRulesBloc
abstract class HouseRulesEvent extends Equatable {
  const HouseRulesEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para cargar las normas al iniciar
class HouseRulesStarted extends HouseRulesEvent {
  const HouseRulesStarted({this.propertyId});

  final String? propertyId;

  @override
  List<Object?> get props => [propertyId];
}

/// Evento para solicitar la carga de normas
class HouseRulesLoadRequested extends HouseRulesEvent {
  const HouseRulesLoadRequested({this.propertyId});

  final String? propertyId;

  @override
  List<Object?> get props => [propertyId];
}

/// Evento para refrescar la lista de normas
class HouseRulesRefreshRequested extends HouseRulesEvent {
  const HouseRulesRefreshRequested();
}

// ============== STATES ==============

/// Estados base del HouseRulesBloc
abstract class HouseRulesState extends Equatable {
  const HouseRulesState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class HouseRulesInitial extends HouseRulesState {
  const HouseRulesInitial();
}

/// Estado de carga
class HouseRulesLoading extends HouseRulesState {
  const HouseRulesLoading();
}

/// Estado con datos cargados
class HouseRulesLoaded extends HouseRulesState {
  const HouseRulesLoaded({
    required this.rules,
    required this.groupedRules,
    this.propertyId,
    this.isRefreshing = false,
  });

  final List<HouseRuleEntity> rules;
  final Map<String, List<HouseRuleEntity>> groupedRules;
  final String? propertyId;
  final bool isRefreshing;

  /// Lista de categorías ordenadas
  List<String> get categories => groupedRules.keys.toList();

  /// Obtiene las normas de una categoría
  List<HouseRuleEntity> getRulesByCategory(String category) =>
      groupedRules[category] ?? [];

  @override
  List<Object?> get props => [rules, groupedRules, propertyId, isRefreshing];
}

/// Estado de error
class HouseRulesError extends HouseRulesState {
  const HouseRulesError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

// ============== BLOC ==============

/// BLoC para gestionar el estado de las normas de la casa
class HouseRulesBloc extends Bloc<HouseRulesEvent, HouseRulesState> {
  HouseRulesBloc({
    required HouseRulesRepository houseRulesRepository,
  })  : _houseRulesRepository = houseRulesRepository,
        super(const HouseRulesInitial()) {
    on<HouseRulesStarted>(_onStarted);
    on<HouseRulesLoadRequested>(_onLoadRequested);
    on<HouseRulesRefreshRequested>(_onRefreshRequested);
  }

  final HouseRulesRepository _houseRulesRepository;

  /// Maneja el evento de inicio
  Future<void> _onStarted(
    HouseRulesStarted event,
    Emitter<HouseRulesState> emit,
  ) async {
    emit(const HouseRulesLoading());
    await _loadRules(emit, event.propertyId);
  }

  /// Maneja la solicitud de carga
  Future<void> _onLoadRequested(
    HouseRulesLoadRequested event,
    Emitter<HouseRulesState> emit,
  ) async {
    emit(const HouseRulesLoading());
    await _loadRules(emit, event.propertyId);
  }

  /// Maneja la solicitud de refresco
  Future<void> _onRefreshRequested(
    HouseRulesRefreshRequested event,
    Emitter<HouseRulesState> emit,
  ) async {
    final currentState = state;
    if (currentState is HouseRulesLoaded) {
      emit(HouseRulesLoaded(
        rules: currentState.rules,
        groupedRules: currentState.groupedRules,
        propertyId: currentState.propertyId,
        isRefreshing: true,
      ));
      await _loadRules(emit, currentState.propertyId);
    }
  }

  /// Carga las normas desde el repositorio
  Future<void> _loadRules(
    Emitter<HouseRulesState> emit,
    String? propertyId,
  ) async {
    try {
      final List<HouseRuleEntity> rules;
      final Map<String, List<HouseRuleEntity>> groupedRules;

      if (propertyId != null) {
        // Cargar normas de una propiedad específica
        rules = await _houseRulesRepository.getByPropertyId(propertyId);
        groupedRules =
            await _houseRulesRepository.getByPropertyIdGrouped(propertyId);
      } else {
        // Cargar todas las normas (generales)
        rules = await _houseRulesRepository.getAll();
        groupedRules = await _houseRulesRepository.getAllGrouped();
      }

      emit(HouseRulesLoaded(
        rules: rules,
        groupedRules: groupedRules,
        propertyId: propertyId,
      ));
    } catch (e) {
      emit(HouseRulesError(message: _getErrorMessage(e)));
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
      return 'No tienes permisos para ver las normas de la casa.';
    }

    return 'Ha ocurrido un error al cargar las normas. Por favor, intenta de nuevo.';
  }
}
