# 🏗️ Feature Creator Agent

> **Propósito**: Crear features completas siguiendo Clean Architecture
> **Uso**: Cuando necesites crear un nuevo módulo/feature desde cero

## 📋 Contexto Mínimo
- **Proyecto**: AmbuTrack Web (Flutter 3.35.3+)
- **Arquitectura**: Clean Architecture + BLoC
- **Backend**: Supabase (PostgreSQL)
- **DI**: GetIt + Injectable

## 🎯 Mi Responsabilidad
Crear la estructura completa de una feature:
1. Domain (entities, repositories abstractos)
2. Data (datasources, repositories impl)
3. Presentation (bloc, pages, widgets)
4. Routing y DI

## 📁 Estructura a Generar
```
lib/features/[nombre]/
├── domain/
│   ├── entities/[nombre]_entity.dart
│   └── repositories/[nombre]_repository.dart
├── data/
│   ├── datasources/[nombre]_datasource.dart
│   └── repositories/[nombre]_repository_impl.dart
└── presentation/
    ├── bloc/
    │   ├── [nombre]_bloc.dart
    │   ├── [nombre]_event.dart
    │   └── [nombre]_state.dart
    ├── pages/[nombre]_page.dart
    └── widgets/
```

## ✅ Checklist de Creación

### 1. Domain Layer
```dart
// entities/[nombre]_entity.dart
class [Nombre]Entity extends Equatable {
  final String id;
  // campos...
  
  const [Nombre]Entity({required this.id});
  
  @override
  List<Object?> get props => [id];
}

// repositories/[nombre]_repository.dart
abstract class [Nombre]Repository {
  Future<Either<Failure, List<[Nombre]Entity>>> getAll();
  Future<Either<Failure, [Nombre]Entity>> getById(String id);
  Future<Either<Failure, void>> create([Nombre]Entity entity);
  Future<Either<Failure, void>> update([Nombre]Entity entity);
  Future<Either<Failure, void>> delete(String id);
}
```

### 2. Data Layer
```dart
// datasources/[nombre]_datasource.dart
@injectable
class [Nombre]DataSource {
  final SupabaseClient _client;
  
  [Nombre]DataSource(this._client);
  
  Future<List<[Nombre]Model>> getAll() async {
    final response = await _client
        .from('[tabla]')
        .select();
    return (response as List)
        .map((e) => [Nombre]Model.fromJson(e))
        .toList();
  }
}

// repositories/[nombre]_repository_impl.dart
@LazySingleton(as: [Nombre]Repository)
class [Nombre]RepositoryImpl implements [Nombre]Repository {
  final [Nombre]DataSource _dataSource;
  
  [Nombre]RepositoryImpl(this._dataSource);
  
  @override
  Future<Either<Failure, List<[Nombre]Entity>>> getAll() async {
    try {
      final result = await _dataSource.getAll();
      return Right(result.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
```

### 3. Presentation Layer
```dart
// bloc/[nombre]_bloc.dart
@injectable
class [Nombre]Bloc extends Bloc<[Nombre]Event, [Nombre]State> {
  final [Nombre]Repository _repository;
  
  [Nombre]Bloc(this._repository) : super(const [Nombre]Initial()) {
    on<[Nombre]LoadRequested>(_onLoadRequested);
  }
  
  Future<void> _onLoadRequested(
    [Nombre]LoadRequested event,
    Emitter<[Nombre]State> emit,
  ) async {
    emit(const [Nombre]Loading());
    final result = await _repository.getAll();
    result.fold(
      (failure) => emit([Nombre]Error(failure.message)),
      (data) => emit([Nombre]Loaded(data)),
    );
  }
}

// pages/[nombre]_page.dart
class [Nombre]Page extends StatelessWidget {
  const [Nombre]Page({super.key});
  
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: BlocProvider(
        create: (_) => getIt<[Nombre]Bloc>()
          ..add(const [Nombre]LoadRequested()),
        child: const _[Nombre]View(),
      ),
    );
  }
}

class _[Nombre]View extends StatelessWidget {
  const _[Nombre]View();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: BlocBuilder<[Nombre]Bloc, [Nombre]State>(
        builder: (context, state) {
          if (state is [Nombre]Loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is [Nombre]Error) {
            return Center(
              child: Text(
                state.message,
                style: TextStyle(color: AppColors.error),
              ),
            );
          }
          if (state is [Nombre]Loaded) {
            return _[Nombre]Content(items: state.items);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
```

### 4. Registrar Ruta
```dart
// En lib/core/router/app_router.dart
GoRoute(
  path: '/[nombre]',
  name: '[nombre]',
  builder: (context, state) => const [Nombre]Page(),
),
```

## 🔧 Comandos Post-Creación
```bash
# 1. Generar código (Injectable, Freezed)
flutter pub run build_runner build --delete-conflicting-outputs

# 2. Verificar warnings (OBLIGATORIO)
flutter analyze
# Resultado esperado: No issues found!
```

## ⚠️ Reglas que DEBO seguir
1. **AppColors**: Siempre, nunca Colors directo
2. **SafeArea**: Obligatorio en páginas
3. **Límites**: Archivo <350, Widget <150, Método <40
4. **Widgets**: StatelessWidget, no métodos _build
5. **BLoC**: Sin BuildContext ni UI imports
6. **Supabase**: Nunca Firebase
7. **0 Warnings**: flutter analyze limpio

## 💬 Cómo Usarme
```
Usuario: Crea la feature de "pacientes" con CRUD completo

Yo: 
1. Creo domain/entities/paciente_entity.dart
2. Creo domain/repositories/paciente_repository.dart
3. Creo data/datasources/paciente_datasource.dart
4. Creo data/repositories/paciente_repository_impl.dart
5. Creo presentation/bloc/* 
6. Creo presentation/pages/pacientes_page.dart
7. Registro ruta en app_router.dart
8. Ejecuto build_runner
9. Ejecuto flutter analyze
```
