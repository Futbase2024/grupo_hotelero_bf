import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../entities/campaign_entity.dart';
import '../repositories/marketing_repository.dart';

// ============================================
// EVENTS
// ============================================

abstract class CampaignsEvent extends Equatable {
  const CampaignsEvent();

  @override
  List<Object?> get props => [];
}

/// Inicializa el BLoC con el propertyId
class CampaignsStarted extends CampaignsEvent {
  const CampaignsStarted({required this.propertyId});

  final String propertyId;

  @override
  List<Object?> get props => [propertyId];
}

/// Solicita cargar las campañas
class CampaignsLoadRequested extends CampaignsEvent {
  const CampaignsLoadRequested();
}

/// Solicita crear una nueva campaña
class CampaignCreateRequested extends CampaignsEvent {
  const CampaignCreateRequested({required this.campaign});

  final CampaignEntity campaign;

  @override
  List<Object?> get props => [campaign];
}

/// Solicita actualizar una campaña
class CampaignUpdateRequested extends CampaignsEvent {
  const CampaignUpdateRequested({required this.campaign});

  final CampaignEntity campaign;

  @override
  List<Object?> get props => [campaign];
}

/// Solicita eliminar una campaña
class CampaignDeleteRequested extends CampaignsEvent {
  const CampaignDeleteRequested({required this.id});

  final String id;

  @override
  List<Object?> get props => [id];
}

/// Cambia el estado de una campaña
class CampaignStatusChanged extends CampaignsEvent {
  const CampaignStatusChanged({
    required this.id,
    required this.status,
  });

  final String id;
  final CampaignStatus status;

  @override
  List<Object?> get props => [id, status];
}

/// Libera recursos
class CampaignsDisposed extends CampaignsEvent {
  const CampaignsDisposed();
}

// ============================================
// STATES
// ============================================

abstract class CampaignsState extends Equatable {
  const CampaignsState();

  @override
  List<Object?> get props => [];
}

class CampaignsInitial extends CampaignsState {
  const CampaignsInitial();
}

class CampaignsLoading extends CampaignsState {
  const CampaignsLoading();
}

class CampaignsLoaded extends CampaignsState {
  const CampaignsLoaded({
    required this.campaigns,
    this.isCreating = false,
  });

  final List<CampaignEntity> campaigns;
  final bool isCreating;

  @override
  List<Object?> get props => [campaigns, isCreating];

  CampaignsLoaded copyWith({
    List<CampaignEntity>? campaigns,
    bool? isCreating,
  }) {
    return CampaignsLoaded(
      campaigns: campaigns ?? this.campaigns,
      isCreating: isCreating ?? this.isCreating,
    );
  }
}

class CampaignsError extends CampaignsState {
  const CampaignsError({required this.message, this.previousCampaigns});

  final String message;
  final List<CampaignEntity>? previousCampaigns;

  @override
  List<Object?> get props => [message, previousCampaigns];
}

// ============================================
// BLOC
// ============================================

class CampaignsBloc extends Bloc<CampaignsEvent, CampaignsState> {
  CampaignsBloc({required MarketingRepository repository})
      : _repository = repository,
        super(const CampaignsInitial()) {
    on<CampaignsStarted>(_onStarted);
    on<CampaignsLoadRequested>(_onLoadRequested);
    on<CampaignCreateRequested>(_onCreateRequested);
    on<CampaignUpdateRequested>(_onUpdateRequested);
    on<CampaignDeleteRequested>(_onDeleteRequested);
    on<CampaignStatusChanged>(_onStatusChanged);
    on<CampaignsDisposed>(_onDisposed);
  }

  final MarketingRepository _repository;
  String? _propertyId;

  Future<void> _onStarted(
    CampaignsStarted event,
    Emitter<CampaignsState> emit,
  ) async {
    _propertyId = event.propertyId;
    emit(const CampaignsLoading());

    try {
      final campaigns = await _repository.getCampaigns(event.propertyId);
      emit(CampaignsLoaded(campaigns: campaigns));
    } catch (e) {
      emit(CampaignsError(message: e.toString()));
    }
  }

  Future<void> _onLoadRequested(
    CampaignsLoadRequested event,
    Emitter<CampaignsState> emit,
  ) async {
    if (_propertyId == null) return;

    emit(const CampaignsLoading());

    try {
      final campaigns = await _repository.getCampaigns(_propertyId!);
      emit(CampaignsLoaded(campaigns: campaigns));
    } catch (e) {
      emit(CampaignsError(message: e.toString()));
    }
  }

  Future<void> _onCreateRequested(
    CampaignCreateRequested event,
    Emitter<CampaignsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! CampaignsLoaded) return;

    emit(currentState.copyWith(isCreating: true));

    try {
      final newCampaign = await _repository.createCampaign(event.campaign);

      final updatedCampaigns = [newCampaign, ...currentState.campaigns];
      emit(CampaignsLoaded(campaigns: updatedCampaigns));
    } catch (e) {
      emit(CampaignsLoaded(
        campaigns: currentState.campaigns,
        isCreating: false,
      ));
      // Podríamos emitir un estado de error temporal aquí
    }
  }

  Future<void> _onUpdateRequested(
    CampaignUpdateRequested event,
    Emitter<CampaignsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! CampaignsLoaded) return;

    try {
      final updatedCampaign = await _repository.updateCampaign(event.campaign);

      final updatedCampaigns = currentState.campaigns.map((c) {
        return c.id == updatedCampaign.id ? updatedCampaign : c;
      }).toList();

      emit(CampaignsLoaded(campaigns: updatedCampaigns));
    } catch (e) {
      emit(CampaignsError(
        message: e.toString(),
        previousCampaigns: currentState.campaigns,
      ));
    }
  }

  Future<void> _onDeleteRequested(
    CampaignDeleteRequested event,
    Emitter<CampaignsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! CampaignsLoaded) return;

    try {
      await _repository.deleteCampaign(event.id);

      final updatedCampaigns = currentState.campaigns
          .where((c) => c.id != event.id)
          .toList();

      emit(CampaignsLoaded(campaigns: updatedCampaigns));
    } catch (e) {
      emit(CampaignsError(
        message: e.toString(),
        previousCampaigns: currentState.campaigns,
      ));
    }
  }

  Future<void> _onStatusChanged(
    CampaignStatusChanged event,
    Emitter<CampaignsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! CampaignsLoaded) return;

    try {
      final updatedCampaign = await _repository.updateCampaignStatus(
        event.id,
        event.status,
      );

      final updatedCampaigns = currentState.campaigns.map((c) {
        return c.id == updatedCampaign.id ? updatedCampaign : c;
      }).toList();

      emit(CampaignsLoaded(campaigns: updatedCampaigns));
    } catch (e) {
      emit(CampaignsError(
        message: e.toString(),
        previousCampaigns: currentState.campaigns,
      ));
    }
  }

  void _onDisposed(
    CampaignsDisposed event,
    Emitter<CampaignsState> emit,
  ) {
    _repository.dispose();
  }

  @override
  Future<void> close() {
    _repository.dispose();
    return super.close();
  }
}
