# Skill: Injectable DI

Conocimiento técnico sobre inyección de dependencias con GetIt e Injectable.

---

## Setup

### Archivos de Configuración

```
lib/core/di/
├── injection.dart           # Configuración principal
└── injection.config.dart    # Generado automáticamente
```

### injection.dart

```dart
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injection.config.dart';

final GetIt getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
void configureDependencies() => getIt.init();
```

### Inicialización en main.dart

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar dependencias
  configureDependencies();

  // Inicializar Firebase, etc.
  await Firebase.initializeApp();

  runApp(const FutPlannerApp());
}
```

---

## Anotaciones Principales

### @injectable

Para clases que se instancian cada vez que se solicitan (factory).

```dart
@injectable
class PlayersListBloc extends Bloc<PlayersListEvent, PlayersListState> {
  PlayersListBloc(this._repository) : super(const PlayersListState.initial());

  final PlayersRepository _repository;
}
```

### @lazySingleton

Para clases que se instancian una sola vez (singleton perezoso).

```dart
@LazySingleton()
class PlayersRepository {
  PlayersRepository(this._dataSource);

  final PlayersDataSource _dataSource;
}
```

### @singleton

Para clases que se instancian inmediatamente al configurar DI.

```dart
@singleton
class AppConfig {
  // Se crea al llamar configureDependencies()
}
```

### @preResolve

Para dependencias async que deben resolverse antes de usar.

```dart
@module
abstract class SharedPreferencesModule {
  @preResolve
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();
}
```

---

## Patrones por Tipo de Clase

### Repository

```dart
@LazySingleton()
class PlayersRepository {
  PlayersRepository(this._dataSource);

  final PlayersDataSource _dataSource;
  // ...
}
```

### BLoC

```dart
@injectable
class PlayersListBloc extends Bloc<PlayersListEvent, PlayersListState> {
  PlayersListBloc(this._repository) : super(const PlayersListState.initial()) {
    // ...
  }

  final PlayersRepository _repository;
}
```

### DataSource (en paquete externo)

```dart
// En futplanner_core_datasource
@LazySingleton()
class PlayersDataSource {
  PlayersDataSource(this._firestore);

  final FirebaseFirestore _firestore;
}
```

### Service

```dart
@lazySingleton
class AnalyticsService {
  void logEvent(String name, Map<String, dynamic> params) {
    // ...
  }
}
```

---

## Módulos (@module)

Para registrar dependencias externas o que requieren configuración especial.

```dart
@module
abstract class FirebaseModule {
  @lazySingleton
  FirebaseFirestore get firestore => FirebaseFirestore.instance;

  @lazySingleton
  FirebaseAuth get auth => FirebaseAuth.instance;

  @lazySingleton
  FirebaseStorage get storage => FirebaseStorage.instance;
}

@module
abstract class SharedPreferencesModule {
  @preResolve
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();
}

@module
abstract class HttpModule {
  @lazySingleton
  Dio get dio {
    final dio = Dio();
    dio.options.baseUrl = 'https://api.futplanner.com';
    dio.options.connectTimeout = const Duration(seconds: 30);
    return dio;
  }
}
```

---

## Environments

Para diferentes configuraciones según ambiente.

### Definir Environments

```dart
const dev = Environment('dev');
const prod = Environment('prod');
const test = Environment('test');
```

### Usar en Clases

```dart
@dev
@LazySingleton(as: ApiClient)
class DevApiClient implements ApiClient {
  // Cliente para desarrollo
}

@prod
@LazySingleton(as: ApiClient)
class ProdApiClient implements ApiClient {
  // Cliente para producción
}
```

### Configurar al Iniciar

```dart
void main() {
  // Desarrollo
  configureDependencies(environment: 'dev');

  // Producción
  configureDependencies(environment: 'prod');
}
```

---

## Flujo de Resolución

```
┌─────────────────────────────────────────────────────────────┐
│ PlayersListPage                                             │
│   ↓                                                         │
│ BlocProvider(create: (context) => getIt<PlayersListBloc>()) │
└─────────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ GetIt resuelve PlayersListBloc                              │
│   ↓ necesita PlayersRepository                              │
│ GetIt resuelve PlayersRepository (singleton existente)      │
│   ↓ necesita PlayersDataSource                              │
│ GetIt resuelve PlayersDataSource (singleton existente)      │
│   ↓ necesita FirebaseFirestore                              │
│ GetIt resuelve FirebaseFirestore (del módulo)               │
└─────────────────────────────────────────────────────────────┘
```

---

## Uso en Código

### En Widgets (Rutas)

```dart
GoRoute(
  path: '/players',
  builder: (context, state) => AppConfigWrapper(
    child: BlocProvider(
      create: (context) => getIt<PlayersListBloc>()
        ..add(const PlayersListEvent.load(teamId: 'team1')),
      child: const PlayersListPage(),
    ),
  ),
),
```

### En Clases

```dart
class SomeService {
  // Obtener dependencia
  final repository = getIt<PlayersRepository>();

  // O inyectar en constructor
  SomeService(this._repository);
  final PlayersRepository _repository;
}
```

### Resolver Lazy

```dart
// No resuelve hasta que se use
final lazyRepo = getIt.get<PlayersRepository>();
```

---

## Testing con Mocks

### Registrar Mocks

```dart
import 'package:mocktail/mocktail.dart';

class MockPlayersRepository extends Mock implements PlayersRepository {}

void main() {
  late MockPlayersRepository mockRepository;

  setUp(() {
    // Resetear GetIt
    getIt.reset();

    // Registrar mock
    mockRepository = MockPlayersRepository();
    getIt.registerSingleton<PlayersRepository>(mockRepository);
  });

  test('should load players', () async {
    // Configurar mock
    when(() => mockRepository.getTeamPlayers(
      userId: any(named: 'userId'),
      teamId: any(named: 'teamId'),
    )).thenAnswer((_) async => [testPlayer]);

    // Usar bloc
    final bloc = getIt<PlayersListBloc>();
    bloc.add(const PlayersListEvent.load(teamId: 'team1'));

    // Verificar
    await expectLater(
      bloc.stream,
      emitsInOrder([
        isA<PlayersListState>(),
      ]),
    );
  });
}
```

### @Injectable con Environment Test

```dart
@test
@LazySingleton(as: PlayersRepository)
class MockPlayersRepository extends Mock implements PlayersRepository {}

// En test
void main() {
  setUp(() {
    configureDependencies(environment: 'test');
  });
}
```

---

## Regenerar Código

Después de agregar/modificar clases con anotaciones:

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Errores Comunes

### 1. Dependencia No Registrada

```
Error: Object/factory with type PlayersRepository is not registered
```

**Solución:** Verificar que la clase tiene `@injectable` o `@lazySingleton`.

### 2. Dependencia Circular

```
Error: Circular dependency detected
```

**Solución:** Usar `@lazySingleton` en lugar de `@singleton`, o reestructurar dependencias.

### 3. No Ejecutar build_runner

```
Error: injection.config.dart not found
```

**Solución:** Ejecutar `dart run build_runner build`.

---

## Checklist

- [ ] `@injectable` en BLoCs
- [ ] `@LazySingleton()` en Repositories
- [ ] `@LazySingleton()` en DataSources
- [ ] Módulos para dependencias externas (Firebase, Dio, etc.)
- [ ] `configureDependencies()` llamado en main
- [ ] `build_runner` ejecutado después de cambios
- [ ] Tests usan mocks registrados en GetIt
