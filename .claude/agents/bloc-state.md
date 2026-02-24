# ⚡ BLoC/State Agent

> **Propósito**: Crear y modificar BLoCs, Cubits y gestión de estado
> **Uso**: Lógica de negocio, eventos, estados, flujos de datos

## 📋 Contexto Mínimo
- **Proyecto**: AmbuTrack Web (Flutter 3.35.3+)
- **State Management**: flutter_bloc 9.1.1
- **Inmutabilidad**: freezed 2.5.7 + equatable 2.0.5
- **DI**: @injectable

## 🎯 Mi Responsabilidad
- Crear BLoCs/Cubits con eventos y estados
- Gestionar flujos de datos
- Conectar con repositories
- Mantener separación UI/lógica

## 📁 Estructura de BLoC
```
presentation/bloc/
├── [nombre]_bloc.dart      # BLoC principal
├── [nombre]_event.dart     # Eventos
└── [nombre]_state.dart     # Estados
```

## ✅ Plantillas

### Events (freezed)
```dart
// [nombre]_event.dart
part of '[nombre]_bloc.dart';

@freezed
class [Nombre]Event with _$[Nombre]Event {
  const factory [Nombre]Event.loadRequested() = [Nombre]LoadRequested;
  const factory [Nombre]Event.createRequested([Nombre]Entity entity) = [Nombre]CreateRequested;
  const factory [Nombre]Event.updateRequested([Nombre]Entity entity) = [Nombre]UpdateRequested;
  const factory [Nombre]Event.deleteRequested(String id) = [Nombre]DeleteRequested;
  const factory [Nombre]Event.refreshRequested() = [Nombre]RefreshRequested;
}
```

### States (freezed)
```dart
// [nombre]_state.dart
part of '[nombre]_bloc.dart';

@freezed
class [Nombre]State with _$[Nombre]State {
  const factory [Nombre]State.initial() = [Nombre]Initial;
  const factory [Nombre]State.loading() = [Nombre]Loading;
  const factory [Nombre]State.loaded(List<[Nombre]Entity> items) = [Nombre]Loaded;
  const factory [Nombre]State.error(String message) = [Nombre]Error;
  const factory [Nombre]State.actionSuccess(String message) = [Nombre]ActionSuccess;
}
```

### BLoC Principal
```dart
// [nombre]_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter/foundation.dart';

part '[nombre]_event.dart';
part '[nombre]_state.dart';
part '[nombre]_bloc.freezed.dart';

@injectable
class [Nombre]Bloc extends Bloc<[Nombre]Event, [Nombre]State> {
  final [Nombre]Repository _repository;

  [Nombre]Bloc(this._repository) : super(const [Nombre]Initial()) {
    on<[Nombre]LoadRequested>(_onLoadRequested);
    on<[Nombre]CreateRequested>(_onCreateRequested);
    on<[Nombre]UpdateRequested>(_onUpdateRequested);
    on<[Nombre]DeleteRequested>(_onDeleteRequested);
  }

  /// Carga todos los elementos
  Future<void> _onLoadRequested(
    [Nombre]LoadRequested event,
    Emitter<[Nombre]State> emit,
  ) async {
    emit(const [Nombre]Loading());
    debugPrint('🔄 [Nombre]Bloc: Cargando datos...');
    
    final result = await _repository.getAll();
    
    result.fold(
      (failure) {
        debugPrint('❌ [Nombre]Bloc: Error - ${failure.message}');
        emit([Nombre]Error(failure.message));
      },
      (items) {
        debugPrint('✅ [Nombre]Bloc: ${items.length} elementos cargados');
        emit([Nombre]Loaded(items));
      },
    );
  }

  /// Crea un nuevo elemento
  Future<void> _onCreateRequested(
    [Nombre]CreateRequested event,
    Emitter<[Nombre]State> emit,
  ) async {
    emit(const [Nombre]Loading());
    debugPrint('🚀 [Nombre]Bloc: Creando elemento...');
    
    final result = await _repository.create(event.entity);
    
    result.fold(
      (failure) => emit([Nombre]Error(failure.message)),
      (_) {
        emit(const [Nombre]ActionSuccess('Elemento creado correctamente'));
        add(const [Nombre]LoadRequested()); // Recargar lista
      },
    );
  }

  /// Actualiza un elemento
  Future<void> _onUpdateRequested(
    [Nombre]UpdateRequested event,
    Emitter<[Nombre]State> emit,
  ) async {
    emit(const [Nombre]Loading());
    
    final result = await _repository.update(event.entity);
    
    result.fold(
      (failure) => emit([Nombre]Error(failure.message)),
      (_) {
        emit(const [Nombre]ActionSuccess('Elemento actualizado'));
        add(const [Nombre]LoadRequested());
      },
    );
  }

  /// Elimina un elemento
  Future<void> _onDeleteRequested(
    [Nombre]DeleteRequested event,
    Emitter<[Nombre]State> emit,
  ) async {
    emit(const [Nombre]Loading());
    
    final result = await _repository.delete(event.id);
    
    result.fold(
      (failure) => emit([Nombre]Error(failure.message)),
      (_) {
        emit(const [Nombre]ActionSuccess('Elemento eliminado'));
        add(const [Nombre]LoadRequested());
      },
    );
  }
}
```

### Cubit (alternativa más simple)
```dart
@injectable
class [Nombre]Cubit extends Cubit<[Nombre]State> {
  final [Nombre]Repository _repository;

  [Nombre]Cubit(this._repository) : super(const [Nombre]Initial());

  Future<void> loadData() async {
    emit(const [Nombre]Loading());
    
    final result = await _repository.getAll();
    
    result.fold(
      (failure) => emit([Nombre]Error(failure.message)),
      (items) => emit([Nombre]Loaded(items)),
    );
  }
}
```

## 🔌 Uso en UI

### Provider
```dart
// En la página
BlocProvider(
  create: (_) => getIt<[Nombre]Bloc>()
    ..add(const [Nombre]LoadRequested()),
  child: const _[Nombre]View(),
)
```

### Builder
```dart
BlocBuilder<[Nombre]Bloc, [Nombre]State>(
  builder: (context, state) {
    return state.when(
      initial: () => const SizedBox.shrink(),
      loading: () => const Center(child: CircularProgressIndicator()),
      loaded: (items) => _[Nombre]List(items: items),
      error: (message) => _ErrorWidget(message: message),
      actionSuccess: (message) => _SuccessWidget(message: message),
    );
  },
)
```

### Listener (para side effects)
```dart
BlocListener<[Nombre]Bloc, [Nombre]State>(
  listener: (context, state) {
    state.maybeWhen(
      actionSuccess: (message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      },
      error: (message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.error,
          ),
        );
      },
      orElse: () {},
    );
  },
  child: BlocBuilder<[Nombre]Bloc, [Nombre]State>(...),
)
```

### Dispatch Events
```dart
// Cargar datos
context.read<[Nombre]Bloc>().add(const [Nombre]LoadRequested());

// Crear
context.read<[Nombre]Bloc>().add([Nombre]CreateRequested(entity));

// Actualizar
context.read<[Nombre]Bloc>().add([Nombre]UpdateRequested(entity));

// Eliminar
context.read<[Nombre]Bloc>().add([Nombre]DeleteRequested(id));
```

## ⚠️ Reglas BLoC que DEBO seguir

### ❌ PROHIBIDO en BLoC
```dart
// ❌ NO depender de BuildContext
final BuildContext context;

// ❌ NO importar UI
import 'package:flutter/material.dart'; // Solo foundation.dart

// ❌ NO mostrar diálogos/snackbars
showDialog(...);
ScaffoldMessenger.of(context).showSnackBar(...);

// ❌ NO navegar
Navigator.push(...);
context.go(...);
```

### ✅ CORRECTO en BLoC
```dart
// ✅ Solo lógica de negocio
final result = await _repository.getAll();

// ✅ Emitir estados
emit([Nombre]Loaded(items));

// ✅ Logging con debugPrint
debugPrint('🔄 Cargando...');
```

## 🔧 Comandos Post-Creación
```bash
# Generar código freezed
flutter pub run build_runner build --delete-conflicting-outputs

# Verificar (OBLIGATORIO)
flutter analyze
```

## 💬 Cómo Usarme
```
Usuario: Crea un BLoC para gestionar servicios con CRUD

Yo:
1. Creo servicios_event.dart (freezed)
2. Creo servicios_state.dart (freezed)
3. Creo servicios_bloc.dart (@injectable)
4. Implemento handlers para cada evento
5. Ejecuto build_runner
6. Verifico flutter analyze
```
