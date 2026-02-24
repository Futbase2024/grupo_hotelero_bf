# Skill: Integración con Datasource

Conocimiento técnico sobre la arquitectura de datos y el paquete `futplanner_core_datasource`.

**Backend:** Supabase (PostgreSQL + Real-Time)

---

## Configuración Actual

El paquete `futplanner_core_datasource` está configurado como **dependencia local vía path**:

```yaml
# futplanner_web/pubspec.yaml
futplanner_core_datasource:
  path: ../futplanner_core_datasource
```

### Ventajas de esta configuración

- Cambios instantáneos (sin `flutter pub get` tras editar datasource)
- Hot reload funciona con cambios en datasource
- Debugging con breakpoints directamente
- Versionado y CHANGELOG desde el mismo contexto
- Un solo workspace en VSCode para ambos repos

---

## Ubicación de Archivos

```
/futplanner/repositorios/
├── futplanner_web/                              # Proyecto principal
│   └── pubspec.yaml                             # path: ../futplanner_core_datasource
│
└── futplanner_core_datasource/                  # Paquete datasource (repo Git independiente)
    ├── .git/                                    # Su propio repositorio Git
    ├── CHANGELOG.md                             # Historial de cambios
    ├── pubspec.yaml                             # version: X.Y.Z
    └── lib/
        ├── futplanner_core_datasource.dart      # Barrel file (exports)
        └── src/
            ├── entities/                        # Entities Freezed
            │   ├── player_entity.dart
            │   ├── team_entity.dart
            │   └── ...
            ├── datasources/
            │   ├── contracts/                   # Interfaces abstractas
            │   └── supabase/                    # Implementaciones Supabase
            └── core/
                └── datasource_module.dart       # DI singleton
```

---

## Arquitectura de Datos

```
┌─────────────────────────────────────────────────────────────┐
│ lib/features/[feature]/                                     │
│                                                             │
│  presentation/bloc/[feature]_bloc.dart                      │
│    ↓ inyecta                                                │
│  domain/[feature]_repository.dart                           │
│    ↓ inyecta                                                │
└─────────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ ../futplanner_core_datasource/                              │
│                                                             │
│  lib/src/datasources/                                       │
│    - contracts/[entity]_datasource.dart  (interfaz)         │
│    - supabase/supabase_[entity]_impl.dart (implementación)  │
│                                                             │
│  lib/src/core/datasource_module.dart                        │
│    - DatasourceModule.registerSupabase(client)              │
│    - getters: players, teams, activities, etc.              │
└─────────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ Supabase PostgreSQL                                         │
│                                                             │
│  players      (tabla con team_id, RLS por coach)            │
│  teams        (tabla con coach_id, RLS por user)            │
│  activities   (tabla con team_id, RLS por coach)            │
└─────────────────────────────────────────────────────────────┘
```

---

## Patrón DatasourceModule

### Inicialización (en main.dart)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inicializar Supabase
  await Supabase.initialize(
    url: AppEnv.supabaseUrl,
    anonKey: AppEnv.supabaseAnonKey,
  );

  // 2. Registrar DataSources
  DatasourceModule.registerSupabase(Supabase.instance.client);

  // 3. Configurar DI (injectable)
  configureDependencies();

  runApp(const FutPlannerApp());
}
```

### Acceso a DataSources

```dart
// ✅ CORRECTO - Via getIt (inyectado por InjectableModule)
final playersDS = getIt<PlayersDataSource>();
final teams = await getIt<TeamsDataSource>().getAll();

// ❌ PROHIBIDO - Acceso directo a Supabase
final client = Supabase.instance.client;
final data = await client.from('players').select();

// ❌ PROHIBIDO - Factory pattern antiguo
final ds = PlayersDataSourceFactory.createFirebase();
```

---

## Workflow: Modificar Datasource

### Claude PUEDE hacer directamente:

1. **Editar código** en `../futplanner_core_datasource/lib/`
2. **Ejecutar build_runner** en el datasource
3. **Ejecutar analyze** en ambos repos
4. **Leer** CHANGELOG.md y proponer cambios
5. **Leer** pubspec.yaml y proponer nueva versión

### Claude debe PROPONER (usuario ejecuta):

1. **Actualizar CHANGELOG.md** - Claude sugiere el texto
2. **Incrementar versión** - Claude sugiere el número
3. **Git commit/push** - Usuario ejecuta manualmente

---

## Workflow Paso a Paso

### 1️⃣ Modificar Código

```bash
# Claude edita directamente:
../futplanner_core_datasource/lib/src/datasources/supabase/supabase_player_impl.dart
```

### 2️⃣ Regenerar Código (si hay cambios en entities)

```bash
cd ../futplanner_core_datasource
dart run build_runner build --delete-conflicting-outputs
```

### 3️⃣ Verificar

```bash
# En datasource
cd ../futplanner_core_datasource
dart analyze

# En proyecto principal
cd ../futplanner_web
flutter analyze
```

### 4️⃣ Proponer Documentación

Claude sugiere entrada para CHANGELOG.md y nueva versión.

### 5️⃣ Usuario Ejecuta Git

```bash
cd ../futplanner_core_datasource
git add .
git commit -m "fix: [descripción]"
git push origin main
```

---

## Tablas PostgreSQL

| Tabla | Campos clave | RLS |
|-------|--------------|-----|
| `users` | `id` (auth.uid), `email`, `name` | auth.uid() |
| `teams` | `coach_id`, `name`, `season` | coach_id = auth.uid() |
| `players` | `team_id`, `nickname`, `position_id` | via team.coach_id |
| `activities` | `team_id`, `activity_type`, `start_time` | via team.coach_id |
| `player_positions` | `id`, `code`, `name` | público (lookup) |
| `activity_types` | `id`, `type`, `subtype` | público (lookup) |

---

## DataSources Disponibles

| DataSource | Entity | Métodos principales |
|------------|--------|---------------------|
| `UsersDataSource` | `UserEntity` | `getById()`, `create()`, `update()` |
| `TeamsDataSource` | `TeamEntity` | `getAll()`, `watchByCoach()` |
| `PlayersDataSource` | `PlayerEntity` | `getByTeam()`, `watchByTeam()` |
| `ActivitiesDataSource` | `ActivityEntity` | `watchByYearWeek()`, `create()` |
| `ActivityTypesDataSource` | `ActivityTypeEntity` | `getAll()`, `getById()` |
| `PlayerPositionsDataSource` | `PlayerPositionEntity` | `getAll()` |
| `RivalsDataSource` | `RivalEntity` | `getByUser()`, `create()` |
| `ReportsDataSource` | `ReportEntity` | `getByRival()`, `create()` |

---

## Imports Correctos

### ✅ CORRECTO

```dart
// En Repository
import 'package:futplanner_core_datasource/futplanner_core_datasource.dart';

// Acceso via DI
final playersDS = getIt<PlayersDataSource>();
```

### ❌ PROHIBIDO

```dart
// NUNCA importar implementaciones directamente
import 'package:futplanner_core_datasource/src/datasources/supabase/...';

// NUNCA usar Supabase directamente en features
import 'package:supabase_flutter/supabase_flutter.dart';

// NUNCA usar Firebase (proyecto migrado)
import 'package:cloud_firestore/cloud_firestore.dart';
```

---

## Rutas Absolutas para Claude

```
# Proyecto principal
/Users/jesusperezsanchez/Desktop/Proyectos/futplanner/repositorios/futplanner_web/

# Datasource (accesible vía path relativo)
/Users/jesusperezsanchez/Desktop/Proyectos/futplanner/repositorios/futplanner_core_datasource/

# Archivos clave del datasource
../futplanner_core_datasource/lib/src/core/datasource_module.dart
../futplanner_core_datasource/lib/src/datasources/supabase/
../futplanner_core_datasource/lib/src/entities/
../futplanner_core_datasource/CHANGELOG.md
../futplanner_core_datasource/pubspec.yaml
```

---

## Verificación Rápida

```bash
# Desde futplanner_web, verificar que todo compila
flutter analyze

# Ver estado del datasource
git -C ../futplanner_core_datasource status

# Ver versión actual
grep "version:" ../futplanner_core_datasource/pubspec.yaml
```
