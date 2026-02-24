# ⚡ Quickstart - AmbuTrack Web

> **Guía rápida para el desarrollo de AmbuTrack Web**

---

## 🔴 Hooks Obligatorios

### Post-Modificación de .dart (SIEMPRE)
```bash
dart fix --apply && dart analyze
```

### Post-Build Runner
```bash
dart run build_runner build --delete-conflicting-outputs && dart fix --apply
```

### Pre-Commit
```bash
dart fix --apply && dart analyze && flutter test --coverage
```

---

## 🚀 Comandos Frecuentes

### Desarrollo

```bash
# Ejecutar en DEV
flutter run --flavor dev -t lib/main_dev.dart

# Ejecutar en PROD
flutter run --flavor prod -t lib/main.dart

# Ejecutar scripts
./scripts/run_dev.sh
./scripts/run_prod.sh
```

### Code Generation

```bash
# Build una vez
dart run build_runner build --delete-conflicting-outputs

# Watch (desarrollo continuo)
dart run build_runner watch --delete-conflicting-outputs

# Limpiar y regenerar
dart run build_runner clean && dart run build_runner build --delete-conflicting-outputs
```

### Testing

```bash
# Ejecutar todos los tests
flutter test

# Con coverage
flutter test --coverage

# Generar reporte HTML de coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Análisis y Linting

```bash
# Analizar código (OBLIGATORIO → 0 warnings)
flutter analyze

# Aplicar fixes automáticos
dart fix --apply

# Formatear código
dart format lib/ test/
```

---

## 📁 Estructura de Feature

```
lib/features/{feature_name}/
├── domain/
│   └── {feature}_repository.dart
└── presentation/
    ├── bloc/
    │   ├── {feature}_bloc.dart
    │   ├── {feature}_event.dart      # Freezed
    │   └── {feature}_state.dart      # Freezed
    ├── pages/
    │   └── {feature}_page.dart
    └── widgets/
        ├── {feature}_loaded_view.dart    # ✅ Widget separado
        ├── {feature}_empty_view.dart     # ✅ Widget separado
        └── {feature}_card.dart
```

---

## 🎨 Widgets Material 3 Comunes

```dart
// Layout
Scaffold
AppBar
Drawer
NavigationBar

// Inputs
TextField
TextFormField
DropdownButton
Checkbox
Radio
Switch
Slider

// Buttons
FilledButton
TextButton
OutlinedButton
IconButton

// Feedback
CircularProgressIndicator
LinearProgressIndicator
SnackBar
Dialog
AlertDialog

// Containers
Card
ListTile
DataTable
ExpansionTile
Chip
Badge

// Refresh
RefreshIndicator
CustomScrollView + Slivers
```

---

## 📝 Snippets Rápidos

### Nuevo Repository Pass-Through

```dart
import 'package:ambutrack_core_datasource/ambutrack_core_datasource.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: VehiculoRepository)
class VehiculoRepositoryImpl implements VehiculoRepository {
  VehiculoRepositoryImpl() : _dataSource = VehiculoDataSourceFactory.createSupabase();
  final VehiculoDataSource _dataSource;

  @override
  Future<List<VehiculoEntity>> getAll() async {
    return await _dataSource.getAll();  // ✅ Pass-through directo
  }
}
```

### Nuevo BLoC Event

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part '{name}_event.freezed.dart';

@freezed
class {Name}Event with _${Name}Event {
  const factory {Name}Event.started() = _Started;
  const factory {Name}Event.loadRequested() = _LoadRequested;
  const factory {Name}Event.refreshRequested() = _RefreshRequested;
  const factory {Name}Event.createRequested({Name}Entity item) = _CreateRequested;
  const factory {Name}Event.updateRequested({Name}Entity item) = _UpdateRequested;
  const factory {Name}Event.deleteRequested(String id) = _DeleteRequested;
}
```

### Nuevo BLoC State

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part '{name}_state.freezed.dart';

@freezed
class {Name}State with _${Name}State {
  const factory {Name}State.initial() = _Initial;
  const factory {Name}State.loading({
    @Default('Cargando...') String message,
  }) = _Loading;
  const factory {Name}State.loaded(List<{Name}Entity> items) = _Loaded;
  const factory {Name}State.error(String message) = _Error;
}
```

### Widget Separado (NO método)

```dart
// ✅ CORRECTO: Widget como clase separada
class {Name}LoadedView extends StatelessWidget {
  const {Name}LoadedView({
    super.key,
    required this.items,
  });

  final List<{Name}Entity> items;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) => {Name}Card(item: items[index]),
    );
  }
}

// ❌ INCORRECTO: Método que devuelve Widget
Widget _buildLoadedView() {
  // NUNCA hacer esto
}
```

---

## 🗄️ Supabase

### Acceso via getIt (SIEMPRE)

```dart
// ✅ CORRECTO
final vehiculosDS = getIt<VehiculosDataSource>();
final vehiculos = await vehiculosDS.getAll();

// ❌ INCORRECTO
final client = Supabase.instance.client;
final data = await client.from('vehiculos').select();
```

### MCP Disponible

El agente `supabase_specialist.md` tiene acceso al MCP de Supabase para:
- Consultar schemas
- Ejecutar queries
- Crear migraciones
- Verificar RLS policies

---

## 🚨 REGLA OBLIGATORIA: Planes de Implementación

**ANTES de comenzar cualquier tarea no trivial, SIEMPRE:**

1. Crear plan en `docs/plans/{feature}_plan.md`
2. Documentar fases, archivos a crear/modificar
3. Listar agentes involucrados
4. Definir comandos de validación

**Esto aplica a:**
- Nuevas features completas
- Refactors significativos
- Implementación de layouts responsivos
- Cualquier cambio que afecte múltiples archivos

---

## 📋 Checklist Rápida

### Nueva Feature
```
□ CREAR PLAN en docs/plans/{feature}_plan.md
□ Crear/verificar Entity en ambutrack_core_datasource
□ Crear Repository pass-through
□ Crear BLoC + Events + States
□ Crear Page (Material 3 + SafeArea)
□ Crear Widgets separados (NO métodos _buildX)
□ Registrar en DI
□ Añadir al router
□ build_runner
□ dart fix --apply
□ flutter analyze → 0 warnings
```

### Nuevo Widget
```
□ Crear como clase StatelessWidget
□ Usar Material 3 widgets
□ AppColors para colores
□ Parámetros en constructor
□ SafeArea si es página principal
□ dart fix --apply
```

---

## 🔗 Referencias

| Recurso | Ubicación |
|---------|-----------|
| Prompt maestro | `CLAUDE.md` |
| Orquestador | `.claude/ORCHESTRATOR.md` |
| Convenciones | `.claude/memory/CONVENTIONS.md` |
| Design System | `.claude/design/DESIGN_SYSTEM.md` |
| Project Context | `.claude/design/PROJECT_CONTEXT.md` |
| AmbuTrack Datasource | `packages/ambutrack_core_datasource/` |

---

## 🎨 Reglas Críticas de AmbuTrack

1. **Material Design 3** - NO Cupertino
2. **AppColors** - NO hardcoded colors
3. **SafeArea** - OBLIGATORIO en todas las páginas
4. **Repository pass-through** - SIN conversiones Entity↔Entity
5. **flutter analyze** - 0 warnings OBLIGATORIO
6. **Supabase** - NO Firebase
7. **Widgets como clases** - NO métodos `_buildXxx()`
8. **Diálogos profesionales** - NO SnackBar para notificaciones importantes

---

**Última actualización:** 2025-02-09
