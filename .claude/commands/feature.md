# /futplanner-feature

Genera una feature completa E2E siguiendo Clean Architecture.

## Uso

```
/futplanner-feature [nombre] [descripcion]
```

## Ejemplo

```
/futplanner-feature players "Gestión de jugadores del equipo"
```

---

## Modelo Recomendado por Agente

| Agente | Modelo | Justificación |
|--------|--------|---------------|
| ArchitectAgent | `haiku` | Solo lectura y validación |
| DatasourceAgent | `sonnet` | Generación de código |
| FeatureBuilderAgent | `sonnet` | Generación de código |
| UIDesignerAgent | `sonnet` | Generación de código |
| QAValidatorAgent | `haiku` | Grep + analyze, no genera código |

Al lanzar `Task` tools, especificar el modelo: `model: "haiku"` o `model: "sonnet"`.

---

## Workflow Completo

### Paso 1: Validar Arquitectura (@FutPlannerArchitectAgent) — `model: haiku`

1. Verificar que la feature no existe
2. Verificar si Entity existe en `futplanner_core_datasource`
3. Definir estructura de carpetas

```bash
# Verificar si existe
ls lib/features/[nombre]/ 2>/dev/null && echo "⚠️ Feature ya existe"

# Verificar Entity en datasource
ls packages/futplanner_core_datasource/lib/src/entities/[nombre]_entity.dart 2>/dev/null
```

### Paso 2: Crear Entity si no existe (@FutPlannerDatasourceAgent) — `model: sonnet`

Si la Entity no existe en el datasource:

1. Crear Entity con Freezed
2. Crear DataSource
3. Ejecutar workflow obligatorio:

```bash
cd packages/futplanner_core_datasource
dart run build_runner build --delete-conflicting-outputs
dart analyze
# Actualizar CHANGELOG.md y versión
cd ../..
flutter pub get
```

#### ✅ CHECKPOINT 1: Validar Entity
```bash
cd packages/futplanner_core_datasource && dart analyze
# DEBE retornar 0 errores antes de continuar
```
> **Si hay errores:** Corregir ANTES de pasar al paso 3. No acumular.

### Paso 3: Crear Estructura (@FutPlannerArchitectAgent) — `model: haiku`

```bash
mkdir -p lib/features/[nombre]/{domain,presentation/{bloc,pages,layouts,widgets}}
```

### Paso 4: Crear Repository (@FutPlannerFeatureBuilderAgent) — `model: sonnet`

Crear `lib/features/[nombre]/domain/[nombre]_repository.dart`:

```dart
import 'package:futplanner_core_datasource/futplanner_core_datasource.dart';
import 'package:injectable/injectable.dart';

@LazySingleton()
class [Nombre]Repository {
  [Nombre]Repository(this._dataSource);

  final [Nombre]DataSource _dataSource;

  // CRUD methods delegando al DataSource
}
```

### Paso 5: Crear BLoCs (@FutPlannerFeatureBuilderAgent) — `model: sonnet`

Crear según necesidad:
- `[nombre]_list_bloc.dart` - Para listas
- `[nombre]_detail_bloc.dart` - Para detalles
- `[nombre]_form_bloc.dart` - Para formularios

**⚠️ CRÍTICO: State.loading DEBE tener message con @Default**

```dart
const factory [Nombre]State.loading({
  @Default('Cargando...') String message,
}) = _Loading;
```

#### ✅ CHECKPOINT 2: Validar Business Logic
```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze lib/features/[nombre]/
# DEBE retornar 0 errores antes de continuar
```
> **Si hay errores:** Corregir ANTES de pasar al paso 6. Los errores de BLoC/Repository se propagan a UI.

### Paso 6: Crear Pages y Layouts (@FutPlannerUIDesignerAgent) — `model: sonnet`

**Page principal:**
```dart
class [Nombre]ListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<[Nombre]ListBloc, [Nombre]ListState>(
      builder: (context, state) {
        return AppLayoutBuilder(
          mobile: [Nombre]ListMobileLayout(state: state),
          tablet: [Nombre]ListTabletLayout(state: state),
          desktop: [Nombre]ListDesktopLayout(state: state),
        );
      },
    );
  }
}
```

**Layouts separados:**
- `layouts/[nombre]_list_mobile_layout.dart`
- `layouts/[nombre]_list_tablet_layout.dart`
- `layouts/[nombre]_list_desktop_layout.dart`

#### 🔀 PARALELIZABLE: Pasos 7 y 8 pueden ejecutarse en paralelo con Paso 6

### Paso 7: Configurar Navegación — puede ser paralelo con Paso 6

Agregar en `lib/core/router/app_router.dart`:

```dart
GoRoute(
  path: '/[nombre]',
  name: '[nombre]',
  builder: (context, state) => AppConfigWrapper(
    child: BlocProvider(
      create: (context) => getIt<[Nombre]ListBloc>()
        ..add(const [Nombre]ListEvent.load()),
      child: const [Nombre]ListPage(),
    ),
  ),
),
```

### Paso 8: Agregar Traducciones — puede ser paralelo con Paso 6

En `lib/core/lang/app_es.arb`:
```json
"[nombre]Title": "Título",
"[nombre]AddNew": "Añadir nuevo",
"[nombre]Empty": "No hay elementos"
```

En `lib/core/lang/app_en.arb`:
```json
"[nombre]Title": "Title",
"[nombre]AddNew": "Add new",
"[nombre]Empty": "No items"
```

Regenerar:
```bash
flutter gen-l10n
```

#### ✅ CHECKPOINT 3: Validar UI + Navegación + i18n
```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
# DEBE retornar 0 errores antes de continuar
```
> **Si hay errores:** Corregir ANTES de pasar a QA. La mayoría de errores aquí son imports o tipos.

### Paso 9: Validar (@FutPlannerQAValidatorAgent) — `model: haiku`

Validación final exhaustiva:

```bash
flutter analyze
```

Verificar:
- [ ] 0 errores en analyze
- [ ] Repository con @LazySingleton
- [ ] BLoC con @injectable
- [ ] State.loading con message
- [ ] LoadingOverlay en layouts
- [ ] Traducciones con context.lang
- [ ] Material 3 UI (NO Cupertino)
- [ ] NO métodos _buildXxx
- [ ] AppLayoutBuilder con 3 layouts
- [ ] Paridad funcional mobile-desktop
- [ ] Ruta en GoRouter con AppConfigWrapper

---

## Grafo de Dependencias (Paralelización)

```
Paso 1 (Architect) ──────────────────────────────────────────► secuencial
     │
     ▼
Paso 2 (Datasource, si necesario) ──► CHECKPOINT 1 ──────────► secuencial
     │
     ▼
Paso 3 (Estructura) ─────────────────────────────────────────► secuencial
     │
     ▼
Paso 4+5 (Repository + BLoC) ───────► CHECKPOINT 2 ──────────► secuencial
     │
     ├──► Paso 6 (Pages + Layouts + Widgets) ─┐
     ├──► Paso 7 (Navegación GoRouter)        ├──► PARALELO
     └──► Paso 8 (Traducciones i18n)          ┘
                                                │
                                                ▼
                                          CHECKPOINT 3
                                                │
                                                ▼
                                     Paso 9 (QA final)
```

**Ahorro estimado:** ~27% menos tiempo al paralelizar pasos 6/7/8.

---

## Estructura Final

```
lib/features/[nombre]/
├── domain/
│   └── [nombre]_repository.dart
└── presentation/
    ├── bloc/
    │   ├── [nombre]_list_bloc.dart
    │   ├── [nombre]_list_event.dart
    │   └── [nombre]_list_state.dart
    ├── pages/
    │   └── [nombre]_list_page.dart
    ├── layouts/
    │   ├── [nombre]_list_mobile_layout.dart
    │   ├── [nombre]_list_tablet_layout.dart
    │   └── [nombre]_list_desktop_layout.dart
    └── widgets/
        └── [nombre]_card.dart
```

---

## Archivos Generados

| Archivo | Agente Responsable | Modelo |
|---------|-------------------|--------|
| Entity | DatasourceAgent | sonnet |
| DataSource | DatasourceAgent | sonnet |
| Repository | FeatureBuilderAgent | sonnet |
| BLoC + Events + State | FeatureBuilderAgent | sonnet |
| Page | UIDesignerAgent | sonnet |
| Layouts (3) | UIDesignerAgent | sonnet |
| Widgets | UIDesignerAgent | sonnet |
| Rutas GoRouter | UIDesignerAgent | sonnet |
| Traducciones | UIDesignerAgent | sonnet |
| Validación QA | QAValidatorAgent | haiku |
