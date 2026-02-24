# AmbuTrack Web - Convenciones de Desarrollo

> **Convenciones y templates de código para AmbuTrack Web**

---

## ⚠️ REGLAS CRÍTICAS - PAQUETES

### ❌ PAQUETE DEPRECADO
- **NUNCA** usar `ambutrack_core` - Paquete deprecado y obsoleto
- **NUNCA** importar `package:ambutrack_core/...`

### ✅ PAQUETE ACTUAL
- **SIEMPRE** usar `ambutrack_core_datasource` - Paquete activo y mantenido
- **SIEMPRE** importar `package:ambutrack_core_datasource/...`

**Razón**: `ambutrack_core` está siendo migrado a `ambutrack_core_datasource`. Usar el paquete deprecado causará conflictos de dependencias y errores de compilación.

---

## 1. Arquitectura Clean

```
lib/features/[feature]/
├── domain/
│   └── [feature]_repository.dart    # @LazySingleton
└── presentation/
    ├── bloc/                        # @injectable + Freezed
    │   ├── [feature]_bloc.dart
    │   ├── [feature]_event.dart
    │   └── [feature]_state.dart
    ├── pages/
    │   └── [feature]_page.dart
    └── widgets/
        └── [component]_widget.dart
```

**❌ PROHIBIDO:** `data/` (excepto repositories impl), `domain/entities/`

---

## 2. Repository Pass-Through Template

```dart
import 'package:ambutrack_core_datasource/ambutrack_core_datasource.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: VehiculoRepository)
class VehiculoRepositoryImpl implements VehiculoRepository {
  VehiculoRepositoryImpl() : _dataSource = VehiculoDataSourceFactory.createSupabase();
  final VehiculoDataSource _dataSource;

  @override
  Future<List<VehiculoEntity>> getAll() async {
    debugPrint('📦 Repository: Solicitando datos...');
    return await _dataSource.getAll();  // ✅ Pass-through directo
  }

  @override
  Future<VehiculoEntity> getById(String id) async {
    return await _dataSource.getById(id);
  }

  @override
  Future<VehiculoEntity> create(VehiculoEntity item) async {
    return await _dataSource.create(item);
  }

  @override
  Future<VehiculoEntity> update(VehiculoEntity item) async {
    return await _dataSource.update(item);
  }

  @override
  Future<void> delete(String id) async {
    return await _dataSource.delete(id);
  }
}
```

**⚠️ CRÍTICO:**
- ✅ UN solo import del core
- ✅ Pass-through directo al datasource
- ❌ SIN conversiones Entity ↔ Entity
- ❌ SIN imports dobles (as core/as app)

---

## 3. BLoC con Freezed

### Event Template

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'vehiculo_event.freezed.dart';

@freezed
class VehiculoEvent with _$VehiculoEvent {
  const factory VehiculoEvent.started() = _Started;
  const factory VehiculoEvent.loadRequested() = _LoadRequested;
  const factory VehiculoEvent.refreshRequested() = _RefreshRequested;
  const factory VehiculoEvent.createRequested(VehiculoEntity vehiculo) = _CreateRequested;
  const factory VehiculoEvent.updateRequested(VehiculoEntity vehiculo) = _UpdateRequested;
  const factory VehiculoEvent.deleteRequested(String id) = _DeleteRequested;
}
```

### State Template

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'vehiculo_state.freezed.dart';

@freezed
class VehiculoState with _$VehiculoState {
  const factory VehiculoState.initial() = _Initial;
  const factory VehiculoState.loading({
    @Default('Cargando vehículos...') String message,
  }) = _Loading;
  const factory VehiculoState.loaded(List<VehiculoEntity> vehiculos) = _Loaded;
  const factory VehiculoState.error(String message) = _Error;
}
```

### BLoC Template

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/vehiculo_repository.dart';
import 'vehiculo_event.dart';
import 'vehiculo_state.dart';

@injectable
class VehiculoBloc extends Bloc<VehiculoEvent, VehiculoState> {
  final VehiculoRepository _repository;

  VehiculoBloc(this._repository) : super(const VehiculoState.initial()) {
    on<VehiculoEvent>(_onEvent);
  }

  Future<void> _onEvent(VehiculoEvent event, Emitter<VehiculoState> emit) async {
    await event.when(
      started: () => _onStarted(emit),
      loadRequested: () => _onLoadRequested(emit),
      refreshRequested: () => _onRefreshRequested(emit),
      createRequested: (vehiculo) => _onCreateRequested(emit, vehiculo),
      updateRequested: (vehiculo) => _onUpdateRequested(emit, vehiculo),
      deleteRequested: (id) => _onDeleteRequested(emit, id),
    );
  }

  Future<void> _onStarted(Emitter<VehiculoState> emit) async {
    emit(const VehiculoState.loading(message: 'Cargando vehículos...'));
    await _loadVehiculos(emit);
  }

  Future<void> _onLoadRequested(Emitter<VehiculoState> emit) async {
    emit(const VehiculoState.loading(message: 'Cargando vehículos...'));
    await _loadVehiculos(emit);
  }

  Future<void> _loadVehiculos(Emitter<VehiculoState> emit) async {
    try {
      final vehiculos = await _repository.getAll();
      emit(VehiculoState.loaded(vehiculos));
    } catch (e) {
      emit(VehiculoState.error(e.toString()));
    }
  }

  // ... más métodos
}
```

---

## 4. UI Material Design 3

### Imports estándar

```dart
import 'package:flutter/material.dart';
import 'package:ambutrack_web/core/theme/app_colors.dart';
import 'package:ambutrack_web/core/theme/app_sizes.dart';
```

### Colores (vía AppColors)

```dart
// ✅ AppColors.primary, AppColors.secondary, AppColors.error, etc.
Container(
  color: AppColors.primary,  // Azul médico
)

// ❌ Colors.blue, Color(0xFF...) (excepto white/black/transparent)
Container(
  color: Colors.blue,  // NO HACER ESTO
)
```

### Widgets Material 3 Preferidos

| Widget | Uso |
|--------|-----|
| `Scaffold` | Layout de página |
| `AppBar` | Barra de navegación |
| `FilledButton` | Botón primario |
| `TextButton` | Botón secundario |
| `OutlinedButton` | Botón con borde |
| `TextField` | Campo de texto |
| `Card` | Contenedor con sombra |
| `CircularProgressIndicator` | Indicador de carga |

### AmbuTrack Widgets Custom (lib/core/widgets/)

| Widget | Uso |
|--------|-----|
| `AppDropdown` | Dropdown simple (≤10 items) |
| `AppSearchableDropdown` | Dropdown con búsqueda (>10 items) |
| `AppLoadingIndicator` | Indicador de carga |
| `AppButton` | Botón personalizado |
| `AppTextField` | Campo de texto personalizado |
| `AppDataGridV5` | Tabla de datos con paginación |
| `StatusBadge` | Badge de estado |
| `CrudOperationHandler` | Handler de operaciones CRUD |

---

## 5. SafeArea (OBLIGATORIO)

```dart
class VehiculosPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(  // ✅ OBLIGATORIO
      child: Scaffold(
        appBar: AppBar(title: const Text('Vehículos')),
        body: BlocBuilder<VehiculoBloc, VehiculoState>(
          builder: (context, state) {
            return state.when(
              initial: () => const SizedBox.shrink(),
              loading: (message) => AppLoadingIndicator(message: message),
              loaded: (vehiculos) => VehiculosListView(vehiculos: vehiculos),
              error: (message) => ErrorView(message: message),
            );
          },
        ),
      ),
    );
  }
}
```

---

## 6. Traducciones

```dart
// ✅ SIEMPRE
Text(context.tr.vehiculosTitle)

// ❌ NUNCA
Text('Vehículos')
```

---

## 7. Widgets como Clases

```dart
// ✅ Clases extraídas
class VehiculoCard extends StatelessWidget {
  const VehiculoCard({required this.vehiculo, super.key});

  final VehiculoEntity vehiculo;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(vehiculo.matricula),
        subtitle: Text(vehiculo.modelo),
      ),
    );
  }
}

// ❌ PROHIBIDO métodos
Widget _buildVehiculoCard(VehiculoEntity vehiculo) { ... }
```

---

## 8. Navegación GoRouter

```dart
GoRoute(
  path: '/vehiculos',
  name: 'vehiculos',
  builder: (context, state) => BlocProvider(
    create: (_) => getIt<VehiculoBloc>()..add(const VehiculoEvent.started()),
    child: const VehiculosPage(),
  ),
),
```

---

## 9. Backend: Supabase (NO Firebase)

### Inicialización (main.dart)

```dart
await Supabase.initialize(
  url: AppEnv.supabaseUrl,
  anonKey: AppEnv.supabaseAnonKey,
);
```

### Acceso a DataSources

```dart
// ✅ SIEMPRE via getIt
final vehiculosDS = getIt<VehiculosDataSource>();
final vehiculos = await vehiculosDS.getAll();

// ❌ PROHIBIDO - Acceso directo a Supabase
final client = Supabase.instance.client;
final data = await client.from('vehiculos').select();

// ❌ PROHIBIDO - Firebase (proyecto migrado)
import 'package:cloud_firestore/cloud_firestore.dart';
```

### Real-Time Subscriptions

```dart
// Los DataSources exponen streams para real-time
Stream<List<VehiculoEntity>> watchAll();
```

---

## 10. CRUD Feedback

### En BlocListener

```dart
BlocListener<VehiculoBloc, VehiculoState>(
  listener: (context, state) {
    state.maybeWhen(
      loaded: (vehiculos) {
        if (_isSaving) {
          CrudOperationHandler.handleSuccess(
            context: context,
            isSaving: _isSaving,
            isEditing: _isEditing,
            entityName: 'Vehículo',
            onClose: () => setState(() => _isSaving = false),
          );
        }
      },
      error: (message) {
        CrudOperationHandler.handleError(
          context: context,
          isSaving: _isSaving,
          isEditing: _isEditing,
          entityName: 'Vehículo',
          errorMessage: message,
          onClose: () => setState(() => _isSaving = false),
        );
      },
      orElse: () {},
    );
  },
  child: ...,
)
```

### Loading Overlays

| Operación | Mensaje | Color | Icono |
|-----------|---------|-------|-------|
| Crear | "Creando [entidad]..." | `AppColors.primary` | `Icons.add_circle_outline` |
| Editar | "Actualizando [entidad]..." | `AppColors.secondary` | `Icons.edit` |
| Eliminar | "Eliminando [entidad]..." | `AppColors.emergency` | `Icons.delete_forever` |

---

## 11. Diálogos Profesionales

**REGLA:** Usar diálogos profesionales para notificaciones importantes (NO SnackBar).

```dart
Future<void> _mostrarDialogoEliminacion(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, size: 48, color: AppColors.warning),
            const SizedBox(height: 20),
            Text('Eliminar Vehículo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text('¿Estás seguro de que deseas eliminar este vehículo?...', style: TextStyle(fontSize: 15)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
                child: const Text('Entendido'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
```

---

## 12. Badges en Tablas

**⚠️ CRÍTICO:** Los badges DEBEN ajustarse al texto, NO ocupar todo el ancho.

```dart
// ✅ CORRECTO - Badge ajustado al texto
Align(
  alignment: Alignment.centerLeft,
  child: IntrinsicWidth(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      ),
      child: Text('DISPONIBLE'),
    ),
  ),
)

// ❌ INCORRECTO - Badge ocupa todo el ancho
Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  decoration: BoxDecoration(
    color: AppColors.success.withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
  ),
  child: Text('DISPONIBLE'),
)
```

---

## 13. Dropdowns

- **≤10 items**: `AppDropdown` (`lib/core/widgets/dropdowns/app_dropdown.dart`)
- **>10 items**: `AppSearchableDropdown` (`lib/core/widgets/dropdowns/app_searchable_dropdown.dart`)

---

## 14. Estructura de Documentación

```
docs/
├── plans/                               # Planes de implementación
│   └── {feature}_plan.md
├── arquitectura/                        # Documentos técnicos
├── vehiculos/                           # Docs de vehículos
├── personal/                            # Docs de personal
└── tablas/                              # Docs de tablas maestras
```

**Reglas:**
- ✅ Planes SIEMPRE en `docs/plans/`, NUNCA en `.claude/`

---

## 15. Comandos Útiles

```bash
flutter analyze                                           # OBLIGATORIO → 0 warnings
flutter pub run build_runner build --delete-conflicting-outputs  # Freezed/Injectable
./scripts/run_dev.sh                                      # Ejecutar dev
./scripts/run_prod.sh                                     # Ejecutar prod
```

---

## Checklist Pre-Commit

- [ ] `flutter analyze` = 0 errores
- [ ] NO `data/` ni `domain/entities/` en features
- [ ] Repository `@LazySingleton`, BLoC `@injectable`
- [ ] `State.loading` tiene `message` con `@Default`
- [ ] SafeArea en todas las páginas
- [ ] `context.tr()` para todos los textos
- [ ] Material 3 widgets (NO Cupertino)
- [ ] AppColors para colores (NO hardcoded)
- [ ] Widgets extraídos como clases (NO métodos `_buildXxx()`)
- [ ] **DataSources via `getIt<>()`, NO acceso directo a Supabase**
- [ ] **NO imports de Firebase/Firestore**

---

**⚠️ SIEMPRE:** `flutter analyze` → 0 warnings antes de dar por terminada cualquier tarea
