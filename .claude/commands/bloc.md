# /futplanner-bloc

Genera un BLoC con Freezed para una feature.

## Uso

```
/futplanner-bloc [tipo] [feature]
```

## Tipos Disponibles

| Tipo | Descripción | Archivo generado |
|------|-------------|------------------|
| `list` | Lista de elementos | `[feature]_list_bloc.dart` |
| `detail` | Detalle de elemento | `[feature]_detail_bloc.dart` |
| `form` | Formulario crear/editar | `[feature]_form_bloc.dart` |

## Ejemplos

```
/futplanner-bloc list players
/futplanner-bloc detail players
/futplanner-bloc form players
```

---

## Pre-requisitos

1. Repository debe existir en `lib/features/[feature]/domain/`
2. Entity debe existir en `futplanner_core_datasource`

---

## Template: BLoC List

### Events (`[feature]_list_event.dart`)

```dart
part of '[feature]_list_bloc.dart';

@freezed
class [Feature]ListEvent with _$[Feature]ListEvent {
  /// Cargar lista
  const factory [Feature]ListEvent.load({
    required String teamId,
  }) = _Load;

  /// Refrescar lista
  const factory [Feature]ListEvent.refresh() = _Refresh;

  /// Eliminar elemento
  const factory [Feature]ListEvent.delete({
    required String id,
  }) = _Delete;

  /// Buscar
  const factory [Feature]ListEvent.search({
    required String query,
  }) = _Search;

  /// Filtrar
  const factory [Feature]ListEvent.filter({
    String? filterValue,
  }) = _Filter;
}
```

### State (`[feature]_list_state.dart`)

```dart
part of '[feature]_list_bloc.dart';

@freezed
class [Feature]ListState with _$[Feature]ListState {
  /// Estado inicial
  const factory [Feature]ListState.initial() = _Initial;

  /// ⚠️ CRÍTICO: message OBLIGATORIO con @Default
  const factory [Feature]ListState.loading({
    @Default('Cargando...') String message,
  }) = _Loading;

  /// Lista cargada
  const factory [Feature]ListState.loaded({
    required List<[Feature]Entity> items,
    required String teamId,
    String? searchQuery,
    String? filterValue,
  }) = _Loaded;

  /// Error
  const factory [Feature]ListState.error({
    required String message,
    Exception? exception,
  }) = _Error;
}
```

### BLoC (`[feature]_list_bloc.dart`)

```dart
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:futplanner_core_datasource/futplanner_core_datasource.dart';
import 'package:injectable/injectable.dart';

import '../../domain/[feature]_repository.dart';

part '[feature]_list_bloc.freezed.dart';
part '[feature]_list_event.dart';
part '[feature]_list_state.dart';

@injectable
class [Feature]ListBloc extends Bloc<[Feature]ListEvent, [Feature]ListState> {
  [Feature]ListBloc(this._repository) : super(const [Feature]ListState.initial()) {
    on<_Load>(_onLoad);
    on<_Refresh>(_onRefresh);
    on<_Delete>(_onDelete);
    on<_Search>(_onSearch);
    on<_Filter>(_onFilter);
  }

  final [Feature]Repository _repository;
  String? _teamId;
  String? _userId;

  Future<void> _onLoad(_Load event, Emitter<[Feature]ListState> emit) async {
    emit(const [Feature]ListState.loading(
      message: 'Cargando elementos...',  // ⚠️ CRÍTICO: mensaje específico
    ));

    try {
      _teamId = event.teamId;
      // _userId = obtener del contexto de auth

      final items = await _repository.getAll(
        userId: _userId!,
        teamId: _teamId!,
      );

      emit([Feature]ListState.loaded(
        items: items,
        teamId: _teamId!,
      ));
    } catch (e) {
      emit([Feature]ListState.error(
        message: 'Error al cargar: ${e.toString()}',
        exception: e is Exception ? e : null,
      ));
    }
  }

  Future<void> _onRefresh(_Refresh event, Emitter<[Feature]ListState> emit) async {
    if (_teamId == null) return;

    emit(const [Feature]ListState.loading(
      message: 'Actualizando lista...',  // ⚠️ CRÍTICO
    ));

    try {
      final items = await _repository.getAll(
        userId: _userId!,
        teamId: _teamId!,
      );

      emit([Feature]ListState.loaded(
        items: items,
        teamId: _teamId!,
      ));
    } catch (e) {
      emit([Feature]ListState.error(message: 'Error al actualizar'));
    }
  }

  Future<void> _onDelete(_Delete event, Emitter<[Feature]ListState> emit) async {
    emit(const [Feature]ListState.loading(
      message: 'Eliminando...',  // ⚠️ CRÍTICO
    ));

    try {
      await _repository.delete(
        userId: _userId!,
        teamId: _teamId!,
        id: event.id,
      );
      add(const [Feature]ListEvent.refresh());
    } catch (e) {
      emit([Feature]ListState.error(message: 'Error al eliminar'));
    }
  }

  void _onSearch(_Search event, Emitter<[Feature]ListState> emit) {
    // Implementar búsqueda local
  }

  void _onFilter(_Filter event, Emitter<[Feature]ListState> emit) {
    // Implementar filtro
  }
}
```

---

## Template: BLoC Detail

### Events

```dart
part of '[feature]_detail_bloc.dart';

@freezed
class [Feature]DetailEvent with _$[Feature]DetailEvent {
  const factory [Feature]DetailEvent.load({
    required String id,
  }) = _Load;

  const factory [Feature]DetailEvent.refresh() = _Refresh;
}
```

### State

```dart
part of '[feature]_detail_bloc.dart';

@freezed
class [Feature]DetailState with _$[Feature]DetailState {
  const factory [Feature]DetailState.initial() = _Initial;

  const factory [Feature]DetailState.loading({
    @Default('Cargando detalles...') String message,
  }) = _Loading;

  const factory [Feature]DetailState.loaded({
    required [Feature]Entity item,
  }) = _Loaded;

  const factory [Feature]DetailState.error({
    required String message,
  }) = _Error;
}
```

---

## Template: BLoC Form

### Events

```dart
part of '[feature]_form_bloc.dart';

@freezed
class [Feature]FormEvent with _$[Feature]FormEvent {
  /// Inicializar (null = nuevo, id = edición)
  const factory [Feature]FormEvent.initialize({
    String? id,
  }) = _Initialize;

  /// Actualizar campo
  const factory [Feature]FormEvent.updateField({
    required String field,
    required dynamic value,
  }) = _UpdateField;

  /// Guardar
  const factory [Feature]FormEvent.save() = _Save;
}
```

### State

```dart
part of '[feature]_form_bloc.dart';

@freezed
class [Feature]FormState with _$[Feature]FormState {
  const factory [Feature]FormState.initial() = _Initial;

  const factory [Feature]FormState.loading({
    @Default('Preparando formulario...') String message,
  }) = _Loading;

  const factory [Feature]FormState.editing({
    required [Feature]Entity item,
    required bool isNew,
    @Default(false) bool hasChanges,
    @Default({}) Map<String, String> errors,
  }) = _Editing;

  const factory [Feature]FormState.saving({
    @Default('Guardando...') String message,
  }) = _Saving;

  const factory [Feature]FormState.saved({
    required [Feature]Entity item,
  }) = _Saved;

  const factory [Feature]FormState.error({
    required String message,
  }) = _Error;
}
```

---

## ⚠️ Regla Crítica: State.loading

### OBLIGATORIO

```dart
// ✅ CORRECTO
const factory State.loading({
  @Default('Cargando...') String message,
}) = _Loading;

// ✅ CORRECTO - Emitir con mensaje
emit(const State.loading(message: 'Cargando jugadores del equipo...'));
```

### PROHIBIDO

```dart
// ❌ PROHIBIDO - Sin message
const factory State.loading() = _Loading;

// ❌ PROHIBIDO - message required
const factory State.loading({
  required String message,
}) = _Loading;

// ❌ PROHIBIDO - Emitir sin mensaje
emit(const State.loading());
```

---

## Mensajes de Loading Recomendados

| Acción | Mensaje Recomendado |
|--------|---------------------|
| Cargar lista | `'Cargando [feature]...'` |
| Cargar detalle | `'Cargando detalles...'` |
| Preparar form | `'Preparando formulario...'` |
| Guardar nuevo | `'Creando [feature]...'` |
| Guardar cambios | `'Guardando cambios...'` |
| Eliminar | `'Eliminando [feature]...'` |
| Actualizar | `'Actualizando lista...'` |
| Buscar | `'Buscando...'` |

---

## Checklist

- [ ] `@injectable` en la clase BLoC
- [ ] Events con `@freezed`
- [ ] State con `@freezed`
- [ ] **State.loading tiene `message` con `@Default`**
- [ ] **Todos los `emit(loading)` tienen mensaje específico**
- [ ] Inyecta Repository, NO DataSource
- [ ] Handlers para cada Event
- [ ] `close()` cancela subscriptions si las hay
- [ ] Documentación de clase y events

---

## Post-creación

```bash
# Regenerar código Freezed
dart run build_runner build --delete-conflicting-outputs

# Verificar
flutter analyze
```
