# Content Engine App - Sistema de Gestión de Contenido

> **Proyecto**: Content Engine App
> **Owner**: JPS Developer (Jesús)
> **Stack**: Flutter + Supabase + n8n
> **UI Framework**: Cupertino (Apple Native Design)
> **Flutter Version**: 3.38.5 (via FVM)

---

## 🗄️ SUPABASE - CONFIGURACIÓN DEL PROYECTO

### Proyecto Futbase

| Campo | Valor |
|-------|-------|
| **Nombre** | futbase |
| **Project ID** | `xgcqpdbmzgtisulylmtd` |
| **Region** | eu-west-1 |
| **Host** | db.xgcqpdbmzgtisulylmtd.supabase.co |
| **MCP** | `mcp__supabase-Futbase__*` |

### Uso del MCP de Supabase

```dart
// Siempre usar el proyecto Futbase con el ID:
project_id: "xgcqpdbmzgtisulylmtd"

// Ejemplo de consulta:
mcp__supabase-Futbase__execute_sql(
  project_id: "xgcqpdbmzgtisulylmtd",
  query: "SELECT * FROM tpartidos LIMIT 10;"
)
```

### Vistas Importantes

| Vista | Descripción |
|-------|-------------|
| `vpartidosjugadores` | Jugadores convocados por partido |
| `veventos` | Eventos de partidos (goles, tarjetas) |

---

## 🔴 HOOKS OBLIGATORIOS (CRÍTICO)

### ⚡ Post-File Hook - EJECUTAR SIEMPRE

```bash
# DESPUÉS DE CREAR O MODIFICAR CUALQUIER ARCHIVO .dart:
# EJECUTAR OBLIGATORIAMENTE:

dart fix --apply && dart analyze
```

**Regla inquebrantable**: Cada vez que se cree o modifique un archivo `.dart`, se DEBE ejecutar:
1. `dart fix --apply` - Aplica correcciones automáticas de linting
2. `dart analyze` - Verifica que no hay errores ni warnings

**Flujo obligatorio:**
```
Crear/Modificar .dart → dart fix --apply → dart analyze → Continuar
```

### 🧪 Pre-Commit Hook
Antes de considerar CUALQUIER tarea completada:
```bash
dart fix --apply && dart analyze && flutter test --coverage
```

### 📦 Post-Build-Runner Hook
Después de ejecutar `build_runner`:
```bash
dart run build_runner build --delete-conflicting-outputs && dart fix --apply
```

---

## 🎯 Identidad del Proyecto

**Content Engine App** es una aplicación Flutter para gestión automatizada de contenido para redes sociales. Permite crear, gestionar, adaptar y publicar contenido de manera sistemática usando IA.

### Stack Tecnológico OBLIGATORIO

| Componente | Tecnología | Versión |
|------------|------------|---------|
| Framework | Flutter | 3.38.5 (FVM) |
| State Management | **flutter_bloc + Freezed** | 8.x |
| Routing | go_router | 14.x |
| Backend | Supabase (MCP disponible) | 2.x |
| UI Framework | **Cupertino** (Apple Native) | Flutter SDK |
| DI | get_it + injectable | Latest |
| Testing | flutter_test + bloc_test + mocktail | Latest |
| Cobertura mínima | **85%** | - |

### 🚫 PROHIBICIONES

- ❌ NO usar Material Design (solo Cupertino)
- ❌ NO usar StatefulWidget cuando BLoC es apropiado
- ❌ NO crear código sin tests
- ❌ NO ignorar el hook de linting
- ❌ NO usar usecases (lógica va en BLoC)
- ❌ NO hardcodear valores de entorno
- ❌ **NO crear métodos que devuelvan Widget** (usar clases separadas)
- ❌ NO usar `_buildX()` patterns - extraer a widgets dedicados
- ❌ **NO comenzar tareas no triviales sin crear plan en `.claude/plans/`**
- ❌ **NO usar tablas directamente en SELECT sin verificar si existe vista** (ver `supabase_view_checker.md`)

### ✅ OBLIGACIONES

- ✅ **CREAR PLAN** en `.claude/plans/` ANTES de tareas no triviales (3+ archivos)
- ✅ Cupertino widgets SIEMPRE
- ✅ BLoC + Freezed para estados/eventos
- ✅ Contratos (abstract class) en domain/repositories
- ✅ Implementaciones en data/repositories
- ✅ Tests con cobertura 85%+
- ✅ `dart fix --apply` después de cada cambio
- ✅ **VERIFICAR VISTAS EN SUPABASE** antes de usar tablas en operaciones de lectura (SELECT)

### 🎨 Reglas de UI/Diseño

- ✅ **TODOS los iconos en tarjetas KPI deben usar `AppColors.primary`** (mismo color para mantener consistencia visual)
- ✅ **Tarjetas KPI deben expandirse equitativamente** usando `Row` + `Expanded` (no ancho fijo)
- ✅ **Tarjetas en filas deben tener la MISMA ALTURA** usando `IntrinsicHeight` + `crossAxisAlignment: CrossAxisAlignment.stretch`
- ✅ Usar SIEMPRE `AppColors` para colores, nunca hardcodear valores hexadecimales

### ⚽ Widget de Loading OBLIGATORIO (CELoading)

**REGLA CRÍTICA**: SIEMPRE usar `CELoading` en lugar de `CircularProgressIndicator` en toda la aplicación.

#### ❌ PROHIBIDO
```dart
// ❌ NUNCA usar CircularProgressIndicator
const CircularProgressIndicator()
const Center(child: CircularProgressIndicator())
CircularProgressIndicator(strokeWidth: 2)
```

#### ✅ OBLIGATORIO
```dart
import 'package:futbase/shared/widgets/shared_widgets.dart';

// ✅ Loading a pantalla completa (splash, inicialización)
const CELoading.fullscreen(message: 'Cargando...')

// ✅ Loading inline para estados de carga en páginas
const CELoading.inline()
const CELoading.inline(message: 'Cargando jugadores...')

// ✅ Loading para botones
const CELoading.button()
// O con color personalizado:
const CELoading.button(color: AppColors.white)

// ✅ Loading con overlay (modal, diálogos)
const CELoading.overlay(message: 'Guardando cambios...')
```

#### Variantes disponibles

| Variante | Uso | Tamaño por defecto |
|----------|-----|-------------------|
| `.fullscreen` | Splash screens, carga inicial de app | 64px |
| `.inline` | Estados de carga en páginas, listas | 32px |
| `.button` | Dentro de botones mientras procesan | 20px |
| `.overlay` | Modales, diálogos de espera | 48px |

#### Ejemplo en BLoC Builder
```dart
BlocBuilder<PlayersBloc, PlayersState>(
  builder: (context, state) {
    return state.when(
      initial: () => const CELoading.inline(),
      loading: () => const CELoading.inline(message: 'Cargando...'),
      loaded: (players) => PlayersList(players: players),
      error: (message) => ErrorView(message: message),
    );
  },
)
```

---

### ⚠️ Widget de Diálogos de Información OBLIGATORIO (CeInfoDialog)

**REGLA CRÍTICA**: SIEMPRE usar `CeInfoDialog` para mostrar alertas, errores, warnings o confirmaciones al usuario. NUNCA usar SnackBar para mensajes críticos.

#### ❌ PROHIBIDO
```dart
// ❌ NUNCA usar SnackBar para mensajes críticos
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Error al guardar')),
);
```

#### ✅ OBLIGATORIO
```dart
import 'package:futbase/shared/widgets/shared_widgets.dart';

// ✅ Diálogo de error
await CeInfoDialog.error(
  context,
  title: 'Error',
  message: 'No se pudo guardar el dorsal',
);

// ✅ Diálogo de advertencia
await CeInfoDialog.warning(
  context,
  title: 'Dorsal duplicado',
  message: 'El dorsal 10 ya está asignado a otro jugador',
);

// ✅ Diálogo de éxito
await CeInfoDialog.success(
  context,
  title: 'Guardado',
  message: 'Los cambios se han guardado correctamente',
);

// ✅ Diálogo de información
await CeInfoDialog.info(
  context,
  title: 'Información',
  message: 'El jugador ha sido convocado',
);

// ✅ Diálogo de confirmación (retorna bool)
final confirmed = await CeConfirmDialog.show(
  context,
  title: '¿Eliminar jugador?',
  message: 'Esta acción no se puede deshacer',
  confirmText: 'Eliminar',
  cancelText: 'Cancelar',
);
if (confirmed) {
  // Usuario confirmó
}
```

#### Tipos disponibles

| Tipo | Color | Icono | Uso |
|------|-------|-------|-----|
| `.error` | Rojo | `Icons.error_outline` | Errores críticos |
| `.warning` | Rojo | `Icons.warning_amber_rounded` | Advertencias, validaciones |
| `.success` | Verde | `Icons.check_circle_outline` | Confirmaciones de éxito |
| `.info` | Verde olive | `Icons.info_outline` | Información general |

#### Cuándo usar cada tipo
- **Error**: Operaciones que fallaron (guardar, cargar, eliminar)
- **Warning**: Validaciones, conflictos (duplicados, datos inválidos)
- **Success**: Confirmaciones importantes (guardado exitoso)
- **Info**: Mensajes informativos no críticos

---

## 🏗️ Arquitectura del Proyecto

### Estructura de Carpetas

```
content_engine_app/
├── .claude/                      # Configuración Claude Code
│   ├── CLAUDE.md                 # Este archivo (prompt maestro)
│   ├── orchestrator.md           # Orquestador de subagentes
│   ├── quickstart.md             # Guía rápida y comandos
│   ├── agents/                   # Subagentes especializados
│   │   ├── feature_generator.md
│   │   ├── apple_design.md
│   │   ├── uiux_designer.md
│   │   ├── supabase_specialist.md
│   │   └── qa_validation.md
│   ├── commands/                 # Comandos slash personalizados
│   ├── plans/                    # Planes de implementación generados
│   └── templates/                # Templates de código
│
├── lib/
│   ├── main_dev.dart             # Entry point DESARROLLO
│   ├── main_prod.dart            # Entry point PRODUCCIÓN
│   ├── app.dart                  # CupertinoApp + BlocProviders
│   ├── injection.dart            # Dependency Injection (get_it)
│   │
│   ├── core/
│   │   ├── config/
│   │   │   ├── env_config.dart       # Variables por entorno
│   │   │   ├── supabase_config.dart  # Setup Supabase
│   │   │   └── router_config.dart    # go_router principal
│   │   │
│   │   ├── theme/
│   │   │   ├── app_theme.dart        # CupertinoThemeData
│   │   │   ├── app_colors.dart       # Paleta de colores
│   │   │   └── app_typography.dart   # SF Pro / System fonts
│   │   │
│   │   ├── extensions/
│   │   │   ├── context_x.dart
│   │   │   ├── string_x.dart
│   │   │   └── datetime_x.dart
│   │   │
│   │   ├── error/
│   │   │   ├── failures.dart         # Clases de Failure
│   │   │   └── exceptions.dart       # Excepciones custom
│   │   │
│   │   └── constants/
│   │       ├── app_constants.dart
│   │       ├── supabase_tables.dart
│   │       └── route_paths.dart
│   │
│   ├── data/
│   │   ├── models/                   # DTOs con Freezed + JSON
│   │   │   ├── idea_model.dart
│   │   │   ├── script_model.dart
│   │   │   ├── platform_adaptation_model.dart
│   │   │   ├── media_asset_model.dart
│   │   │   └── publication_model.dart
│   │   │
│   │   ├── datasources/
│   │   │   ├── remote/
│   │   │   │   ├── supabase_datasource.dart
│   │   │   │   └── n8n_datasource.dart
│   │   │   └── local/
│   │   │       └── local_datasource.dart
│   │   │
│   │   └── repositories/             # ⚡ IMPLEMENTACIONES
│   │       ├── idea_repository_impl.dart
│   │       ├── script_repository_impl.dart
│   │       └── workflow_repository_impl.dart
│   │
│   ├── domain/
│   │   └── repositories/             # 📋 SOLO CONTRATOS
│   │       ├── idea_repository.dart
│   │       ├── script_repository.dart
│   │       └── workflow_repository.dart
│   │
│   ├── presentation/
│   │   └── features/
│   │       ├── app_shell/            # Shell con CupertinoTabScaffold
│   │       │   ├── bloc/
│   │       │   ├── page/
│   │       │   ├── widgets/
│   │       │   └── routes/
│   │       │
│   │       ├── dashboard/
│   │       │   ├── bloc/
│   │       │   │   ├── dashboard_bloc.dart
│   │       │   │   ├── dashboard_event.dart
│   │       │   │   └── dashboard_state.dart
│   │       │   ├── page/
│   │       │   │   └── dashboard_page.dart
│   │       │   ├── widgets/
│   │       │   │   └── ...
│   │       │   └── routes/
│   │       │       └── dashboard_route.dart
│   │       │
│   │       ├── ideas/
│   │       │   ├── bloc/
│   │       │   ├── page/
│   │       │   ├── widgets/
│   │       │   └── routes/
│   │       │
│   │       ├── scripts/
│   │       │   ├── bloc/
│   │       │   ├── page/
│   │       │   ├── widgets/
│   │       │   └── routes/
│   │       │
│   │       ├── adaptations/
│   │       │   ├── bloc/
│   │       │   ├── page/
│   │       │   ├── widgets/
│   │       │   └── routes/
│   │       │
│   │       ├── media/
│   │       │   ├── bloc/
│   │       │   ├── page/
│   │       │   ├── widgets/
│   │       │   └── routes/
│   │       │
│   │       ├── calendar/
│   │       │   ├── bloc/
│   │       │   ├── page/
│   │       │   ├── widgets/
│   │       │   └── routes/
│   │       │
│   │       └── settings/
│   │           ├── bloc/
│   │           ├── page/
│   │           ├── widgets/
│   │           └── routes/
│   │
│   └── shared/
│       ├── widgets/
│       │   ├── cupertino/            # Widgets Cupertino custom
│       │   │   ├── ce_navigation_bar.dart
│       │   │   ├── ce_list_tile.dart
│       │   │   ├── ce_card.dart
│       │   │   ├── ce_button.dart
│       │   │   ├── ce_text_field.dart
│       │   │   └── ce_loading.dart
│       │   ├── empty_state.dart
│       │   └── error_view.dart
│       │
│       └── dialogs/
│           ├── ce_action_sheet.dart
│           └── ce_alert_dialog.dart
│
├── test/
│   ├── unit/
│   │   ├── data/
│   │   │   └── repositories/
│   │   └── presentation/
│   │       └── features/
│   │           └── {feature}/
│   │               └── bloc/
│   │                   └── {feature}_bloc_test.dart
│   ├── widget/
│   │   └── presentation/
│   │       └── features/
│   ├── integration/
│   │   └── flows/
│   ├── mocks/
│   │   ├── mock_repositories.dart
│   │   └── mock_datasources.dart
│   └── fixtures/
│       └── idea_fixtures.dart
│
├── .env.dev                      # Variables desarrollo
├── .env.prod                     # Variables producción
└── pubspec.yaml
```

---

## 📐 Patrones de Código OBLIGATORIOS

### 1. Rutas por Feature (GoRouteData Pattern)

```dart
// lib/presentation/features/ideas/routes/ideas_route.dart
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../page/ideas_page.dart';
import '../page/idea_detail_page.dart';

class IdeasRoute extends GoRouteData {
  static const routeName = '/ideas';
  static const routePath = 'ideas';

  /// Coloca la ruta donde sea necesario en appRoutes
  static GoRoute goRoute({List<RouteBase> routes = const <RouteBase>[]}) {
    return GoRoute(
      name: routeName,
      path: routePath,
      builder: (context, state) => const IdeasPage(),
      routes: [
        IdeaDetailRoute.goRoute(),
        ...routes,
      ],
    );
  }

  /// pushNamed asíncrono que se puede esperar
  static Future<void> pushNamed(BuildContext context) => 
      context.pushNamed(routeName);

  /// goNamed no asíncrono que no permite espera
  static void goNamed(BuildContext context) => 
      context.goNamed(routeName);
}

class IdeaDetailRoute extends GoRouteData {
  static const routeName = '/ideas/:id';
  static const routePath = ':id';

  final String id;
  
  const IdeaDetailRoute({required this.id});

  static GoRoute goRoute({List<RouteBase> routes = const <RouteBase>[]}) {
    return GoRoute(
      name: routeName,
      path: routePath,
      builder: (context, state) => IdeaDetailPage(
        ideaId: state.pathParameters['id']!,
      ),
      routes: routes,
    );
  }

  static Future<void> pushNamed(BuildContext context, {required String id}) =>
      context.pushNamed(routeName, pathParameters: {'id': id});

  static void goNamed(BuildContext context, {required String id}) =>
      context.goNamed(routeName, pathParameters: {'id': id});
}
```

### 2. BLoC con Freezed (Estados y Eventos)

```dart
// lib/presentation/features/ideas/bloc/ideas_event.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'ideas_event.freezed.dart';

@freezed
class IdeasEvent with _$IdeasEvent {
  const factory IdeasEvent.started() = _Started;
  const factory IdeasEvent.loadRequested() = _LoadRequested;
  const factory IdeasEvent.refreshRequested() = _RefreshRequested;
  const factory IdeasEvent.createRequested({
    required String rawIdea,
    required String pillar,
    int? priority,
  }) = _CreateRequested;
  const factory IdeasEvent.updateRequested({required IdeaModel idea}) = _UpdateRequested;
  const factory IdeasEvent.deleteRequested({required String id}) = _DeleteRequested;
  const factory IdeasEvent.filterChanged({required IdeasFilter filter}) = _FilterChanged;
}
```

```dart
// lib/presentation/features/ideas/bloc/ideas_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'ideas_state.freezed.dart';

@freezed
class IdeasState with _$IdeasState {
  const factory IdeasState.initial() = _Initial;
  const factory IdeasState.loading() = _Loading;
  const factory IdeasState.loaded({
    required List<IdeaModel> ideas,
    required IdeasFilter filter,
    @Default(false) bool isRefreshing,
  }) = _Loaded;
  const factory IdeasState.error({
    required String message,
    List<IdeaModel>? previousIdeas,
  }) = _Error;
}
```

```dart
// lib/presentation/features/ideas/bloc/ideas_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/repositories/idea_repository.dart';
import 'ideas_event.dart';
import 'ideas_state.dart';

class IdeasBloc extends Bloc<IdeasEvent, IdeasState> {
  final IdeaRepository _repository;

  IdeasBloc({required IdeaRepository repository})
      : _repository = repository,
        super(const IdeasState.initial()) {
    on<IdeasEvent>(_onEvent);
  }

  Future<void> _onEvent(IdeasEvent event, Emitter<IdeasState> emit) async {
    // IMPORTANTE: Usar `when` en lugar de `map` para mejor legibilidad
    await event.when(
      started: () => _onStarted(emit),
      loadRequested: () => _onLoadRequested(emit),
      refreshRequested: () => _onRefreshRequested(emit),
      createRequested: (rawIdea, pillar, priority) =>
          _onCreateRequested(emit, rawIdea: rawIdea, pillar: pillar, priority: priority),
      updateRequested: (idea) => _onUpdateRequested(emit, idea: idea),
      deleteRequested: (id) => _onDeleteRequested(emit, id: id),
      filterChanged: (filter) => _onFilterChanged(emit, filter: filter),
    );
  }

  Future<void> _onStarted(Emitter<IdeasState> emit) async {
    emit(const IdeasState.loading());
    await _loadIdeas(emit, const IdeasFilter());
  }

  Future<void> _onLoadRequested(Emitter<IdeasState> emit) async {
    emit(const IdeasState.loading());
    final currentFilter = state.maybeWhen(
      loaded: (ideas, filter, isRefreshing) => filter,
      orElse: () => const IdeasFilter(),
    );
    await _loadIdeas(emit, currentFilter);
  }

  Future<void> _onRefreshRequested(Emitter<IdeasState> emit) async {
    state.whenOrNull(
      loaded: (ideas, filter, isRefreshing) {
        emit(IdeasState.loaded(ideas: ideas, filter: filter, isRefreshing: true));
        _loadIdeas(emit, filter);
      },
    );
  }

  Future<void> _onCreateRequested(
    Emitter<IdeasState> emit, {
    required String rawIdea,
    required String pillar,
    int? priority,
  }) async {
    try {
      final idea = IdeaModel(
        id: const Uuid().v4(),
        rawIdea: rawIdea,
        pillar: pillar,
        priority: priority ?? 5,
        createdAt: DateTime.now(),
      );
      await _repository.create(idea);
      add(const IdeasEvent.loadRequested());
    } catch (e) {
      emit(IdeasState.error(message: e.toString()));
    }
  }

  Future<void> _onUpdateRequested(_UpdateRequested event, Emitter<IdeasState> emit) async {
    try {
      await _repository.update(event.idea);
      add(const IdeasEvent.loadRequested());
    } catch (e) {
      emit(IdeasState.error(message: e.toString()));
    }
  }

  Future<void> _onDeleteRequested(_DeleteRequested event, Emitter<IdeasState> emit) async {
    try {
      await _repository.delete(event.id);
      add(const IdeasEvent.loadRequested());
    } catch (e) {
      emit(IdeasState.error(message: e.toString()));
    }
  }

  Future<void> _onFilterChanged(_FilterChanged event, Emitter<IdeasState> emit) async {
    emit(const IdeasState.loading());
    await _loadIdeas(emit, event.filter);
  }

  Future<void> _loadIdeas(Emitter<IdeasState> emit, IdeasFilter filter) async {
    try {
      final ideas = await _repository.getAll();
      emit(IdeasState.loaded(ideas: ideas, filter: filter));
    } catch (e) {
      emit(IdeasState.error(message: e.toString()));
    }
  }
}
```

### 3. Contrato de Repository (Domain) - SOLO INTERFAZ

```dart
// lib/domain/repositories/idea_repository.dart
import '../../data/models/idea_model.dart';

/// Contrato del repositorio de Ideas
/// La implementación está en data/repositories/idea_repository_impl.dart
abstract class IdeaRepository {
  /// Obtiene todas las ideas
  Future<List<IdeaModel>> getAll();
  
  /// Obtiene una idea por ID
  Future<IdeaModel?> getById(String id);
  
  /// Stream de ideas en tiempo real
  Stream<List<IdeaModel>> watchAll();
  
  /// Crea una nueva idea
  Future<IdeaModel> create(IdeaModel idea);
  
  /// Actualiza una idea existente
  Future<void> update(IdeaModel idea);
  
  /// Elimina una idea
  Future<void> delete(String id);
  
  /// Busca ideas por query
  Future<List<IdeaModel>> search(String query);
  
  /// Filtra ideas por pillar
  Future<List<IdeaModel>> getByPillar(String pillar);
  
  /// Filtra ideas por status
  Future<List<IdeaModel>> getByStatus(String status);
}
```

### 4. Implementación Repository (Data)

```dart
// lib/data/repositories/idea_repository_impl.dart
import '../datasources/remote/supabase_datasource.dart';
import '../models/idea_model.dart';
import '../../domain/repositories/idea_repository.dart';

class IdeaRepositoryImpl implements IdeaRepository {
  final SupabaseDatasource _datasource;

  IdeaRepositoryImpl({required SupabaseDatasource datasource})
      : _datasource = datasource;

  @override
  Future<List<IdeaModel>> getAll() async {
    final response = await _datasource.client
        .from('ideas')
        .select()
        .order('created_at', ascending: false);
    return (response as List).map((e) => IdeaModel.fromJson(e)).toList();
  }

  @override
  Future<IdeaModel?> getById(String id) async {
    final response = await _datasource.client
        .from('ideas')
        .select()
        .eq('id', id)
        .maybeSingle();
    return response != null ? IdeaModel.fromJson(response) : null;
  }

  @override
  Stream<List<IdeaModel>> watchAll() {
    return _datasource.client
        .from('ideas')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((e) => IdeaModel.fromJson(e)).toList());
  }

  @override
  Future<IdeaModel> create(IdeaModel idea) async {
    final response = await _datasource.client
        .from('ideas')
        .insert(idea.toJson())
        .select()
        .single();
    return IdeaModel.fromJson(response);
  }

  @override
  Future<void> update(IdeaModel idea) async {
    await _datasource.client
        .from('ideas')
        .update(idea.toJson())
        .eq('id', idea.id);
  }

  @override
  Future<void> delete(String id) async {
    await _datasource.client.from('ideas').delete().eq('id', id);
  }

  @override
  Future<List<IdeaModel>> search(String query) async {
    final response = await _datasource.client
        .from('ideas')
        .select()
        .ilike('raw_idea', '%$query%')
        .order('created_at', ascending: false);
    return (response as List).map((e) => IdeaModel.fromJson(e)).toList();
  }

  @override
  Future<List<IdeaModel>> getByPillar(String pillar) async {
    final response = await _datasource.client
        .from('ideas')
        .select()
        .eq('pillar', pillar)
        .order('created_at', ascending: false);
    return (response as List).map((e) => IdeaModel.fromJson(e)).toList();
  }

  @override
  Future<List<IdeaModel>> getByStatus(String status) async {
    final response = await _datasource.client
        .from('ideas')
        .select()
        .eq('status', status)
        .order('created_at', ascending: false);
    return (response as List).map((e) => IdeaModel.fromJson(e)).toList();
  }
}
```

### 5. Model con Freezed

```dart
// lib/data/models/idea_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'idea_model.freezed.dart';
part 'idea_model.g.dart';

@freezed
class IdeaModel with _$IdeaModel {
  const factory IdeaModel({
    required String id,
    @JsonKey(name: 'raw_idea') required String rawIdea,
    @JsonKey(name: 'refined_idea') String? refinedIdea,
    required String pillar,
    @Default('idea') String status,
    @Default(5) int priority,
    String? source,
    @JsonKey(name: 'estimated_effort') int? estimatedEffort,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'archived_at') DateTime? archivedAt,
  }) = _IdeaModel;

  factory IdeaModel.fromJson(Map<String, dynamic> json) =>
      _$IdeaModelFromJson(json);
}
```

### 6. Page con Cupertino (OBLIGATORIO)

**⚠️ REGLA: NUNCA crear métodos que devuelvan Widget. Usar widgets como clases separadas.**

```dart
// lib/presentation/features/ideas/page/ideas_page.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/ideas_bloc.dart';
import '../bloc/ideas_state.dart';
import '../bloc/ideas_event.dart';
import '../widgets/ideas_loaded_view.dart';
import '../../../../shared/widgets/cupertino/ce_loading.dart';
import '../../../../shared/widgets/error_view.dart';

class IdeasPage extends StatelessWidget {
  const IdeasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Ideas'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.add),
          onPressed: () => _showAddIdeaSheet(context),
        ),
      ),
      child: SafeArea(
        child: BlocBuilder<IdeasBloc, IdeasState>(
          builder: (context, state) {
            // ✅ Usar widgets separados, NO métodos que devuelvan Widget
            return state.map(
              initial: (_) => const CELoading(),
              loading: (_) => const CELoading(),
              loaded: (loaded) => IdeasLoadedView(
                ideas: loaded.ideas,
                filter: loaded.filter,
                isRefreshing: loaded.isRefreshing,
              ),
              error: (error) => ErrorView(
                message: error.message,
                onRetry: () => context.read<IdeasBloc>().add(
                  const IdeasEvent.loadRequested(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showAddIdeaSheet(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => const IdeaFormSheet(),
    );
  }
}
```

```dart
// lib/presentation/features/ideas/widgets/ideas_loaded_view.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/models/idea_model.dart';
import '../bloc/ideas_bloc.dart';
import '../bloc/ideas_event.dart';
import '../routes/ideas_route.dart';
import 'idea_card.dart';
import '../../../../shared/widgets/empty_state.dart';

/// ✅ Widget separado para el estado loaded - NO un método
class IdeasLoadedView extends StatelessWidget {
  const IdeasLoadedView({
    super.key,
    required this.ideas,
    required this.filter,
    this.isRefreshing = false,
  });

  final List<IdeaModel> ideas;
  final IdeasFilter filter;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    if (ideas.isEmpty) {
      return const IdeasEmptyView();
    }

    return CustomScrollView(
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            context.read<IdeasBloc>().add(const IdeasEvent.refreshRequested());
          },
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList.builder(
            itemCount: ideas.length,
            itemBuilder: (context, index) {
              final idea = ideas[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: IdeaCard(
                  idea: idea,
                  onTap: () => IdeaDetailRoute.pushNamed(context, id: idea.id),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// ✅ Widget separado para estado vacío
class IdeasEmptyView extends StatelessWidget {
  const IdeasEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: CupertinoIcons.lightbulb,
      title: 'No hay ideas',
      subtitle: 'Crea tu primera idea para empezar',
      actionLabel: 'Crear idea',
      onAction: () {
        showCupertinoModalPopup<void>(
          context: context,
          builder: (context) => const IdeaFormSheet(),
        );
      },
    );
  }
}
```

---

## 🌍 Configuración de Entornos

### Variables de Entorno

```dart
// lib/core/config/env_config.dart
enum Environment { dev, prod }

class EnvConfig {
  static late Environment _environment;
  
  static Environment get environment => _environment;
  static bool get isDev => _environment == Environment.dev;
  static bool get isProd => _environment == Environment.prod;

  static void init(Environment env) {
    _environment = env;
  }

  // Supabase
  static String get supabaseUrl => const String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  
  static String get supabaseAnonKey => const String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  // n8n
  static String get n8nWebhookUrl => const String.fromEnvironment(
    'N8N_WEBHOOK_URL',
    defaultValue: '',
  );

  // App
  static String get appName => isDev ? 'Content Engine DEV' : 'Content Engine';
}
```

### Entry Points

```dart
// lib/main_dev.dart
import 'package:flutter/cupertino.dart';
import 'app.dart';
import 'core/config/env_config.dart';
import 'injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  EnvConfig.init(Environment.dev);
  await configureDependencies();
  runApp(const ContentEngineApp());
}
```

```dart
// lib/main_prod.dart
import 'package:flutter/cupertino.dart';
import 'app.dart';
import 'core/config/env_config.dart';
import 'injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  EnvConfig.init(Environment.prod);
  await configureDependencies();
  runApp(const ContentEngineApp());
}
```

### Archivos .env

```bash
# .env.dev
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_ANON_KEY=eyJxxx
N8N_WEBHOOK_URL=https://n8n.tudominio.dev/webhook

# .env.prod  
SUPABASE_URL=https://yyy.supabase.co
SUPABASE_ANON_KEY=eyJyyy
N8N_WEBHOOK_URL=https://n8n.tudominio.com/webhook
```

---

## 🧪 Testing - Cobertura 85%+ OBLIGATORIA

### Estructura de Test para BLoC

```dart
// test/unit/presentation/features/ideas/bloc/ideas_bloc_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:content_engine_app/data/models/idea_model.dart';
import 'package:content_engine_app/domain/repositories/idea_repository.dart';
import 'package:content_engine_app/presentation/features/ideas/bloc/ideas_bloc.dart';
import 'package:content_engine_app/presentation/features/ideas/bloc/ideas_event.dart';
import 'package:content_engine_app/presentation/features/ideas/bloc/ideas_state.dart';

import '../../../../../mocks/mock_repositories.dart';
import '../../../../../fixtures/idea_fixtures.dart';

void main() {
  late MockIdeaRepository mockRepository;
  late IdeasBloc bloc;

  setUp(() {
    mockRepository = MockIdeaRepository();
    bloc = IdeasBloc(repository: mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  group('IdeasBloc', () {
    test('initial state is IdeasState.initial()', () {
      expect(bloc.state, const IdeasState.initial());
    });

    group('on Started', () {
      blocTest<IdeasBloc, IdeasState>(
        'emits [loading, loaded] when getAll succeeds',
        build: () {
          when(() => mockRepository.getAll())
              .thenAnswer((_) async => IdeaFixtures.list);
          return bloc;
        },
        act: (bloc) => bloc.add(const IdeasEvent.started()),
        expect: () => [
          const IdeasState.loading(),
          IdeasState.loaded(
            ideas: IdeaFixtures.list,
            filter: const IdeasFilter(),
          ),
        ],
        verify: (_) {
          verify(() => mockRepository.getAll()).called(1);
        },
      );

      blocTest<IdeasBloc, IdeasState>(
        'emits [loading, error] when getAll fails',
        build: () {
          when(() => mockRepository.getAll())
              .thenThrow(Exception('Failed to load'));
          return bloc;
        },
        act: (bloc) => bloc.add(const IdeasEvent.started()),
        expect: () => [
          const IdeasState.loading(),
          isA<IdeasState>().having(
            (s) => s.maybeMap(error: (e) => e.message, orElse: () => ''),
            'error message',
            contains('Failed to load'),
          ),
        ],
      );
    });
  });
}
```

### Comando para verificar cobertura

```bash
flutter test --coverage
# Generar reporte HTML:
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## 📦 Dependencias (pubspec.yaml)

```yaml
name: content_engine_app
description: Content management system for social media automation
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.2.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # Cupertino
  cupertino_icons: ^1.0.8
  
  # State Management
  flutter_bloc: ^8.1.6
  
  # Routing
  go_router: ^14.6.2
  
  # Supabase
  supabase_flutter: ^2.8.3
  
  # DI
  get_it: ^8.0.3
  injectable: ^2.5.0
  
  # Code Generation
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0
  
  # Utils
  uuid: ^4.5.1
  intl: ^0.20.1
  equatable: ^2.0.7
  dartz: ^0.10.1
  
  # Logging
  logger: ^2.5.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  
  # Code Generation
  build_runner: ^2.4.13
  freezed: ^2.5.7
  json_serializable: ^6.9.0
  injectable_generator: ^2.6.2
  
  # Testing
  bloc_test: ^9.1.7
  mocktail: ^1.0.4
  
  # Linting
  flutter_lints: ^5.0.0
  
  # Coverage
  coverage: ^1.10.0

flutter:
  uses-material-design: false  # ⚠️ SOLO CUPERTINO
```

---

## 🔗 Sistema de Subagentes

Este proyecto utiliza un sistema de subagentes especializados orquestados desde `orchestrator.md`:

| Agente | Archivo | Responsabilidad |
|--------|---------|-----------------|
| 🎨 Apple Design | `agents/apple_design.md` | Cupertino widgets, HIG compliance |
| 🖼️ UI/UX Designer | `agents/uiux_designer.md` | Diseño interfaces Apple-style |
| 🏗️ Feature Generator | `agents/feature_generator.md` | Crear features completas |
| 🗄️ Supabase Specialist | `agents/supabase_specialist.md` | DB, queries, MCP integration |
| 🔍 Supabase View Checker | `agents/supabase_view_checker.md` | Verificar vistas antes de usar tablas |
| 🧪 QA Validation | `agents/qa_validation.md` | Testing, coverage, quality |

Ver `orchestrator.md` para detalles de coordinación.

---

## 📋 Checklist de Nueva Feature

```
□ Crear plan en .claude/plans/{feature}_plan.md
□ Crear carpeta features/{feature}/
□ Crear subcarpetas: bloc/, page/, widgets/, routes/
□ Definir modelo con Freezed en data/models/
□ Crear contrato en domain/repositories/
□ Crear implementación en data/repositories/
□ Crear eventos con Freezed
□ Crear estados con Freezed
□ Crear BLoC
□ Crear page principal (Cupertino)
□ Crear route con GoRouteData pattern
□ Registrar en DI (injection.dart)
□ Añadir ruta en router_config.dart
□ Ejecutar build_runner
□ Ejecutar dart fix --apply
□ Crear tests (85%+ coverage)
□ Verificar con flutter test --coverage
```

---

## 🚨 Recordatorio Final

**SIEMPRE después de modificar archivos .dart:**
```bash
dart fix --apply && dart analyze
```

**SIEMPRE antes de commit:**
```bash
dart fix --apply && dart analyze && flutter test --coverage
```
