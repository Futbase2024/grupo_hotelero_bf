# Skill: BLoC con Freezed

Conocimiento técnico sobre implementación de BLoCs con Freezed en FutPlanner.

---

## BLoC vs Cubit

| Aspecto | BLoC | Cubit |
|---------|------|-------|
| Events | Sí (Events separados) | No (métodos directos) |
| Trazabilidad | Alta | Media |
| Complejidad | Mayor | Menor |
| Uso en FutPlanner | **Preferido** | Casos simples |

**Regla:** Usar BLoC para features complejas, Cubit solo para estados muy simples.

---

## Estructura de Archivos

```
presentation/bloc/
├── players_list_bloc.dart       # BLoC principal
├── players_list_bloc.freezed.dart  # Generado
├── players_list_event.dart      # Events
└── players_list_state.dart      # State
```

---

## Template: Events

```dart
part of 'players_list_bloc.dart';

@freezed
class PlayersListEvent with _$PlayersListEvent {
  /// Cargar lista de jugadores
  const factory PlayersListEvent.load({
    required String teamId,
  }) = _Load;

  /// Refrescar lista
  const factory PlayersListEvent.refresh() = _Refresh;

  /// Eliminar jugador
  const factory PlayersListEvent.delete({
    required String playerId,
  }) = _Delete;

  /// Buscar jugadores
  const factory PlayersListEvent.search({
    required String query,
  }) = _Search;

  /// Limpiar búsqueda
  const factory PlayersListEvent.clearSearch() = _ClearSearch;

  /// Filtrar por posición
  const factory PlayersListEvent.filterByPosition({
    String? position,
  }) = _FilterByPosition;

  /// Ordenar
  const factory PlayersListEvent.sort({
    required String field,
    required bool ascending,
  }) = _Sort;
}
```

---

## Template: State

### ⚠️ REGLA CRÍTICA: State.loading con message

```dart
part of 'players_list_bloc.dart';

@freezed
class PlayersListState with _$PlayersListState {
  /// Estado inicial
  const factory PlayersListState.initial() = _Initial;

  /// ⚠️ CRÍTICO: message OBLIGATORIO con @Default
  const factory PlayersListState.loading({
    @Default('Cargando...') String message,
  }) = _Loading;

  /// Lista cargada exitosamente
  const factory PlayersListState.loaded({
    required List<PlayerEntity> players,
    required String teamId,
    String? searchQuery,
    String? filterPosition,
    String? sortField,
    @Default(true) bool sortAscending,
  }) = _Loaded;

  /// Error al cargar
  const factory PlayersListState.error({
    required String message,
    Exception? exception,
  }) = _Error;
}
```

### ❌ PROHIBIDO

```dart
// ❌ Sin message
const factory PlayersListState.loading() = _Loading;

// ❌ message required
const factory PlayersListState.loading({
  required String message,
}) = _Loading;
```

---

## Template: BLoC Completo

```dart
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:futplanner_core_datasource/futplanner_core_datasource.dart';
import 'package:injectable/injectable.dart';

import '../../domain/players_repository.dart';

part 'players_list_bloc.freezed.dart';
part 'players_list_event.dart';
part 'players_list_state.dart';

/// BLoC para lista de jugadores
@injectable
class PlayersListBloc extends Bloc<PlayersListEvent, PlayersListState> {
  PlayersListBloc(this._repository) : super(const PlayersListState.initial()) {
    on<_Load>(_onLoad);
    on<_Refresh>(_onRefresh);
    on<_Delete>(_onDelete);
    on<_Search>(_onSearch);
    on<_ClearSearch>(_onClearSearch);
    on<_FilterByPosition>(_onFilterByPosition);
    on<_Sort>(_onSort);
  }

  final PlayersRepository _repository;

  String? _teamId;
  String? _userId;
  List<PlayerEntity> _allPlayers = [];
  StreamSubscription<List<PlayerEntity>>? _subscription;

  Future<void> _onLoad(_Load event, Emitter<PlayersListState> emit) async {
    // ⚠️ CRÍTICO: Emitir loading CON mensaje
    emit(const PlayersListState.loading(
      message: 'Cargando jugadores del equipo...',
    ));

    try {
      _teamId = event.teamId;
      // Obtener userId del auth context
      // _userId = ...

      final players = await _repository.getTeamPlayers(
        userId: _userId!,
        teamId: _teamId!,
      );

      _allPlayers = players;

      emit(PlayersListState.loaded(
        players: players,
        teamId: _teamId!,
      ));
    } catch (e) {
      emit(PlayersListState.error(
        message: 'Error al cargar jugadores: ${e.toString()}',
        exception: e is Exception ? e : null,
      ));
    }
  }

  Future<void> _onRefresh(_Refresh event, Emitter<PlayersListState> emit) async {
    if (_teamId == null) return;

    // ⚠️ Mensaje específico para refresh
    emit(const PlayersListState.loading(
      message: 'Actualizando lista...',
    ));

    try {
      final players = await _repository.getTeamPlayers(
        userId: _userId!,
        teamId: _teamId!,
      );

      _allPlayers = players;

      emit(PlayersListState.loaded(
        players: players,
        teamId: _teamId!,
      ));
    } catch (e) {
      emit(PlayersListState.error(
        message: 'Error al actualizar: ${e.toString()}',
      ));
    }
  }

  Future<void> _onDelete(_Delete event, Emitter<PlayersListState> emit) async {
    final currentState = state;
    if (currentState is! _Loaded) return;

    // ⚠️ Mensaje específico para delete
    emit(const PlayersListState.loading(
      message: 'Eliminando jugador...',
    ));

    try {
      await _repository.deletePlayer(
        userId: _userId!,
        teamId: _teamId!,
        playerId: event.playerId,
      );

      add(const PlayersListEvent.refresh());
    } catch (e) {
      emit(PlayersListState.error(
        message: 'Error al eliminar: ${e.toString()}',
      ));
    }
  }

  void _onSearch(_Search event, Emitter<PlayersListState> emit) {
    final currentState = state;
    if (currentState is! _Loaded) return;

    final query = event.query.toLowerCase();
    final filtered = _allPlayers.where((player) {
      return player.name.toLowerCase().contains(query) ||
          player.position.toLowerCase().contains(query);
    }).toList();

    emit(currentState.copyWith(
      players: filtered,
      searchQuery: event.query,
    ));
  }

  void _onClearSearch(_ClearSearch event, Emitter<PlayersListState> emit) {
    final currentState = state;
    if (currentState is! _Loaded) return;

    emit(currentState.copyWith(
      players: _allPlayers,
      searchQuery: null,
    ));
  }

  void _onFilterByPosition(
    _FilterByPosition event,
    Emitter<PlayersListState> emit,
  ) {
    final currentState = state;
    if (currentState is! _Loaded) return;

    List<PlayerEntity> filtered;
    if (event.position == null) {
      filtered = _allPlayers;
    } else {
      filtered = _allPlayers
          .where((p) => p.position == event.position)
          .toList();
    }

    emit(currentState.copyWith(
      players: filtered,
      filterPosition: event.position,
    ));
  }

  void _onSort(_Sort event, Emitter<PlayersListState> emit) {
    final currentState = state;
    if (currentState is! _Loaded) return;

    final sorted = List<PlayerEntity>.from(currentState.players);
    sorted.sort((a, b) {
      int comparison;
      switch (event.field) {
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'number':
          comparison = a.number.compareTo(b.number);
          break;
        case 'position':
          comparison = a.position.compareTo(b.position);
          break;
        default:
          comparison = 0;
      }
      return event.ascending ? comparison : -comparison;
    });

    emit(currentState.copyWith(
      players: sorted,
      sortField: event.field,
      sortAscending: event.ascending,
    ));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
```

---

## Mensajes de Loading Recomendados

| Acción | Mensaje |
|--------|---------|
| Cargar lista | `'Cargando [items]...'` |
| Cargar detalle | `'Cargando detalles...'` |
| Cargar formulario | `'Preparando formulario...'` |
| Guardar nuevo | `'Creando [item]...'` |
| Guardar cambios | `'Guardando cambios...'` |
| Eliminar | `'Eliminando [item]...'` |
| Actualizar | `'Actualizando lista...'` |
| Buscar | `'Buscando...'` |
| Filtrar | `'Aplicando filtros...'` |
| Subir archivo | `'Subiendo archivo...'` |
| Enviar | `'Enviando...'` |

---

## Pattern Matching en UI

### Con state.when()

```dart
state.when(
  initial: () => const SizedBox.shrink(),
  loading: (message) => LoadingOverlay(message: message),
  loaded: (players, teamId, search, filter, sort, asc) => PlayersList(
    players: players,
  ),
  error: (message, exception) => ErrorView(
    message: message,
    onRetry: () => context.read<PlayersListBloc>().add(
      const PlayersListEvent.refresh(),
    ),
  ),
)
```

### Con state.maybeWhen()

```dart
state.maybeWhen(
  loaded: (players, _, __, ___, ____, _____) => Text('${players.length} jugadores'),
  orElse: () => const SizedBox.shrink(),
)
```

### Con state.map()

```dart
state.map(
  initial: (_) => const SizedBox.shrink(),
  loading: (s) => LoadingOverlay(message: s.message),
  loaded: (s) => PlayersList(players: s.players),
  error: (s) => ErrorView(message: s.message),
)
```

---

## BLoC con Stream (Tiempo Real)

```dart
Future<void> _onLoad(_Load event, Emitter<PlayersListState> emit) async {
  emit(const PlayersListState.loading(
    message: 'Conectando con el servidor...',
  ));

  try {
    _teamId = event.teamId;

    // Cancelar subscription anterior
    await _subscription?.cancel();

    // Suscribirse al stream
    _subscription = _repository
        .watchTeamPlayers(userId: _userId!, teamId: _teamId!)
        .listen(
      (players) {
        _allPlayers = players;
        add(const _PlayersUpdated(players));
      },
      onError: (error) {
        add(_Error(error.toString()));
      },
    );
  } catch (e) {
    emit(PlayersListState.error(message: e.toString()));
  }
}

// Event interno para actualizaciones del stream
on<_PlayersUpdated>((event, emit) {
  emit(PlayersListState.loaded(
    players: event.players,
    teamId: _teamId!,
  ));
});
```

---

## Testing de BLoCs

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPlayersRepository extends Mock implements PlayersRepository {}

void main() {
  late PlayersListBloc bloc;
  late MockPlayersRepository repository;

  setUp(() {
    repository = MockPlayersRepository();
    bloc = PlayersListBloc(repository);
  });

  tearDown(() {
    bloc.close();
  });

  group('PlayersListBloc', () {
    blocTest<PlayersListBloc, PlayersListState>(
      'emits [loading, loaded] when load succeeds',
      build: () {
        when(() => repository.getTeamPlayers(
          userId: any(named: 'userId'),
          teamId: any(named: 'teamId'),
        )).thenAnswer((_) async => [testPlayer]);

        return bloc;
      },
      act: (bloc) => bloc.add(const PlayersListEvent.load(teamId: 'team1')),
      expect: () => [
        isA<PlayersListState>()
            .having((s) => s, 'is loading', isA<_Loading>()),
        isA<PlayersListState>()
            .having((s) => s, 'is loaded', isA<_Loaded>()),
      ],
    );

    blocTest<PlayersListBloc, PlayersListState>(
      'emits [loading, error] when load fails',
      build: () {
        when(() => repository.getTeamPlayers(
          userId: any(named: 'userId'),
          teamId: any(named: 'teamId'),
        )).thenThrow(Exception('Network error'));

        return bloc;
      },
      act: (bloc) => bloc.add(const PlayersListEvent.load(teamId: 'team1')),
      expect: () => [
        isA<PlayersListState>().having((s) => s, 'is loading', isA<_Loading>()),
        isA<PlayersListState>().having((s) => s, 'is error', isA<_Error>()),
      ],
    );
  });
}
```

---

## Checklist

- [ ] `@injectable` en la clase BLoC
- [ ] Events con `@freezed`
- [ ] State con `@freezed`
- [ ] **State.loading tiene `message` con `@Default`**
- [ ] **Todos los `emit(loading)` tienen mensaje específico**
- [ ] Inyecta Repository (NO DataSource)
- [ ] Handlers para cada Event
- [ ] `close()` cancela subscriptions
- [ ] Documentación de clase y Events
