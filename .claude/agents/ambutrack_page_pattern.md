# Agente: Patrón de Página AmbuTrack con UI/UX Estandarizada

## Propósito
Crear páginas en AmbuTrack Web siguiendo el patrón UI/UX estandarizado usado en Vehículos, Personal y Mantenimiento Preventivo.

## Patrón de Diseño Obligatorio

### 1. PageHeader (OBLIGATORIO)
```dart
import 'package:ambutrack_web/core/widgets/headers/page_header.dart';

BlocBuilder<MyBloc, MyState>(
  builder: (BuildContext context, MyState state) {
    return PageHeader(
      config: PageHeaderConfig(
        icon: Icons.my_icon,
        title: 'Título de la Página',
        subtitle: 'Descripción breve',
        addButtonLabel: 'Agregar Item',
        stats: _buildHeaderStats(state),
        onAdd: _showAddDialog,
      ),
    );
  },
)
```

**Reglas del PageHeader:**
- ✅ **Stats SIN parámetro `color`**: Solo `value` e `icon`
- ✅ **Icons semánticos**: Usar Material Icons apropiados
- ✅ **BlocBuilder**: Envolver en BlocBuilder para reactividad

**Ejemplo de _buildHeaderStats:**
```dart
List<HeaderStat> _buildHeaderStats(MyState state) {
  String total = '-';
  String activos = '-';
  String inactivos = '-';

  if (state is MyLoaded) {
    total = state.items.length.toString();
    activos = state.items.where((i) => i.activo).length.toString();
    inactivos = state.items.where((i) => !i.activo).length.toString();
  }

  return <HeaderStat>[
    HeaderStat(
      value: total,
      icon: Icons.category,
    ),
    HeaderStat(
      value: activos,
      icon: Icons.check_circle,
    ),
    HeaderStat(
      value: inactivos,
      icon: Icons.cancel,
    ),
  ];
}
```

### 2. AppDataGridV5 (OBLIGATORIO)
```dart
import 'package:ambutrack_web/core/widgets/tables/app_data_grid_v5.dart';

Expanded(
  child: AppDataGridV5<MyEntity>(
    columns: const <DataGridColumn>[
      DataGridColumn(label: 'COLUMNA1', flexWidth: 2, sortable: true),
      DataGridColumn(label: 'COLUMNA2', sortable: true),
      DataGridColumn(label: 'ESTADO', flexWidth: 2, sortable: true),
    ],
    rows: itemsPaginados,
    buildCells: _buildCells,
    sortColumnIndex: _sortColumnIndex,
    sortAscending: _sortAscending,
    onSort: _onSort,
    rowHeight: 72,
    outerBorderColor: AppColors.gray300,
    emptyMessage: _filterData.hasActiveFilters
        ? 'No se encontraron items con los filtros aplicados'
        : 'No hay items registrados',
    onView: (MyEntity item) => _showDetails(context, item),
    onEdit: (MyEntity item) => _editItem(context, item),
    onDelete: (MyEntity item) => _confirmDelete(context, item),
  ),
)
```

**Reglas de AppDataGridV5:**
- ✅ **Columnas en mayúsculas**: 'NOMBRE', 'ESTADO', etc.
- ✅ **flexWidth**: Usar para columnas que necesitan más espacio
- ✅ **sortable**: true para columnas ordenables
- ✅ **rowHeight**: 72px estándar
- ✅ **emptyMessage**: Condicional según filtros activos

### 3. Paginación Profesional (OBLIGATORIO)

**Variables de estado:**
```dart
int _currentPage = 0;
static const int _itemsPerPage = 25;
int? _sortColumnIndex;
bool _sortAscending = true;
```

**Método _buildPaginationControls (dentro de la clase State):**
```dart
/// Construye controles de paginación
Widget _buildPaginationControls({
  required int currentPage,
  required int totalPages,
  required int totalItems,
  required void Function(int) onPageChanged,
}) {
  final int startItem = totalItems == 0 ? 0 : currentPage * _itemsPerPage + 1;
  final int endItem = totalItems == 0
      ? 0
      : ((currentPage + 1) * _itemsPerPage).clamp(0, totalItems);

  return Container(
    padding: const EdgeInsets.all(AppSizes.paddingMedium),
    decoration: BoxDecoration(
      color: AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      border: Border.all(color: AppColors.gray200),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        // Info de elementos mostrados
        Text(
          'Mostrando $startItem-$endItem de $totalItems items',
          style: AppTextStyles.bodySmallSecondary,
        ),

        // Botones de navegación
        Row(
          children: <Widget>[
            // Primera página
            IconButton(
              icon: const Icon(Icons.first_page),
              onPressed: currentPage > 0
                  ? () => onPageChanged(0)
                  : null,
              tooltip: 'Primera página',
            ),

            // Página anterior
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: currentPage > 0
                  ? () => onPageChanged(currentPage - 1)
                  : null,
              tooltip: 'Página anterior',
            ),

            // Indicador de página
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingMedium,
                vertical: AppSizes.paddingSmall,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              ),
              child: Text(
                'Página ${currentPage + 1} de $totalPages',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textPrimaryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Página siguiente
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: currentPage < totalPages - 1
                  ? () => onPageChanged(currentPage + 1)
                  : null,
              tooltip: 'Página siguiente',
            ),

            // Última página
            IconButton(
              icon: const Icon(Icons.last_page),
              onPressed: currentPage < totalPages - 1
                  ? () => onPageChanged(totalPages - 1)
                  : null,
              tooltip: 'Última página',
            ),
          ],
        ),
      ],
    ),
  );
}
```

**Uso en build():**
```dart
// Paginación (siempre visible)
_buildPaginationControls(
  currentPage: _currentPage,
  totalPages: totalPages,
  totalItems: totalItems,
  onPageChanged: (int page) {
    setState(() {
      _currentPage = page;
    });
  },
),
```

**Cálculo de paginación:**
```dart
final int totalPages = (totalItems / _itemsPerPage).ceil();
final int startIndex = _currentPage * _itemsPerPage;
final int endIndex = (startIndex + _itemsPerPage).clamp(0, totalItems);
final List<MyEntity> itemsPaginados = itemsFiltrados.sublist(startIndex, endIndex);
```

### 4. StatusBadge (OBLIGATORIO)
```dart
import 'package:ambutrack_web/core/widgets/badges/status_badge.dart';

StatusBadge(
  label: entity.estado.displayName,
  type: _getEstadoBadgeType(entity.estado),
)
```

**Valores disponibles de StatusBadgeType:**
- `StatusBadgeType.disponible` - Azul (informativo)
- `StatusBadgeType.enServicio` - Naranja (en uso)
- `StatusBadgeType.mantenimiento` - Amarillo (advertencia)
- `StatusBadgeType.inactivo` - Gris (inactivo)
- `StatusBadgeType.success` - Verde (éxito)
- `StatusBadgeType.warning` - Amarillo (advertencia)
- `StatusBadgeType.error` - Rojo (error)

**Ejemplo de mapeo:**
```dart
StatusBadgeType _getEstadoBadgeType(Estado estado) {
  switch (estado) {
    case Estado.activo:
      return StatusBadgeType.success;
    case Estado.pendiente:
      return StatusBadgeType.warning;
    case Estado.cancelado:
      return StatusBadgeType.error;
    case Estado.inactivo:
      return StatusBadgeType.inactivo;
  }
}
```

### 5. Estructura de Layout (OBLIGATORIO)
```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: AppColors.backgroundLight,
    body: Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.paddingXl,
        AppSizes.paddingXl,
        AppSizes.paddingXl,
        AppSizes.paddingLarge,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // PageHeader
          BlocBuilder<MyBloc, MyState>(
            builder: (BuildContext context, MyState state) {
              return PageHeader(
                config: PageHeaderConfig(
                  // ...
                ),
              );
            },
          ),
          const SizedBox(height: AppSizes.spacingXl),

          // Tabla ocupa el espacio restante
          Expanded(
            child: MyTableWidget(onFilterChanged: _onFilterChanged),
          ),
        ],
      ),
    ),
  );
}
```

### 6. Ordenamiento (OBLIGATORIO)
```dart
void _onSort(int columnIndex, {required bool ascending}) {
  setState(() {
    _sortColumnIndex = columnIndex;
    _sortAscending = ascending;
  });
}

List<MyEntity> _sortItems(List<MyEntity> items) {
  if (_sortColumnIndex == null) return items;

  final List<MyEntity> sorted = List<MyEntity>.from(items);
  sorted.sort((MyEntity a, MyEntity b) {
    int compare = 0;

    switch (_sortColumnIndex!) {
      case 0: // Nombre
        compare = a.nombre.compareTo(b.nombre);
      case 1: // Fecha
        compare = a.fecha.compareTo(b.fecha);
      case 2: // Estado
        compare = a.estado.index.compareTo(b.estado.index);
      default:
        compare = 0;
    }

    return _sortAscending ? compare : -compare;
  });

  return sorted;
}
```

**⚠️ IMPORTANTE**: El callback `onSort` DEBE usar **named parameter** `{required bool ascending}`

### 7. Filtros (OPCIONAL pero Recomendado)
```dart
// Info de filtros activos
if (_filterData.hasActiveFilters) ...<Widget>[
  const SizedBox(width: AppSizes.spacingSmall),
  Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSizes.paddingSmall,
      vertical: AppSizes.spacingXs,
    ),
    decoration: BoxDecoration(
      color: AppColors.warning.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
    ),
    child: Text(
      'Filtros activos',
      style: GoogleFonts.inter(
        fontSize: AppSizes.fontXs,
        color: AppColors.warning,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
],
```

### 8. Vistas de Loading y Error (OBLIGATORIO)
```dart
/// Vista de carga
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacingMassive),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: AppColors.gray200),
      ),
      constraints: const BoxConstraints(minHeight: 400),
      child: const Center(
        child: AppLoadingIndicator(
          message: 'Cargando items...',
        ),
      ),
    );
  }
}

/// Vista de error
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingXl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: AppColors.error),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: AppSizes.spacing),
          Text(
            'Error al cargar items',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: AppSizes.spacingSmall),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
```

## Imports Obligatorios
```dart
import 'package:ambutrack_core_datasource/ambutrack_core_datasource.dart';
import 'package:ambutrack_web/core/di/locator.dart';
import 'package:ambutrack_web/core/theme/app_colors.dart';
import 'package:ambutrack_web/core/theme/app_sizes.dart';
import 'package:ambutrack_web/core/theme/app_text_styles.dart';
import 'package:ambutrack_web/core/widgets/badges/status_badge.dart';
import 'package:ambutrack_web/core/widgets/headers/page_header.dart';
import 'package:ambutrack_web/core/widgets/loading/app_loading_indicator.dart';
import 'package:ambutrack_web/core/widgets/tables/app_data_grid_v5.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
```

## Checklist de Verificación

### PageHeader
- [ ] PageHeader envuelto en BlocBuilder
- [ ] HeaderStat **SIN** parámetro `color`
- [ ] Solo `value` e `icon` en cada stat
- [ ] Icons semánticos (check_circle, error, etc.)

### Tabla
- [ ] Usa AppDataGridV5 (NO ModernDataTableV3)
- [ ] Columnas en MAYÚSCULAS
- [ ] rowHeight: 72
- [ ] outerBorderColor: AppColors.gray300
- [ ] emptyMessage condicional según filtros

### Paginación
- [ ] 4 botones: Primera | Anterior | Siguiente | Última
- [ ] Indicador central con fondo AppColors.primary
- [ ] Info "Mostrando X-Y de Z items"
- [ ] Container con AppColors.surfaceLight
- [ ] Siempre visible (no depende de totalPages > 1)
- [ ] _itemsPerPage = 25

### Badges
- [ ] Usa StatusBadge (NO Container personalizado)
- [ ] Mapeo correcto de estados a StatusBadgeType
- [ ] Solo usar tipos existentes (disponible, success, warning, error, etc.)

### Ordenamiento
- [ ] Callback onSort con named parameter: `{required bool ascending}`
- [ ] _sortColumnIndex y _sortAscending en estado
- [ ] Método _sortItems implementado

### Layout
- [ ] SafeArea en página principal
- [ ] Scaffold con AppColors.backgroundLight
- [ ] Padding: EdgeInsets.fromLTRB(xl, xl, xl, large)
- [ ] Column con crossAxisAlignment.stretch
- [ ] Expanded para tabla

### Colores
- [ ] SIEMPRE usar AppColors (NO Colors directamente)
- [ ] Excepciones: Colors.white, Colors.black, Colors.transparent
- [ ] AppTextStyles para textos

### Vistas Especiales
- [ ] _LoadingView con AppLoadingIndicator
- [ ] _ErrorView con diseño consistente
- [ ] BlocListener para tracking de performance (opcional)

## Ejemplos de Referencia

### Implementaciones Completas
- ✅ `/lib/features/vehiculos/vehiculos_page.dart`
- ✅ `/lib/features/vehiculos/presentation/widgets/vehiculos_table_v4.dart`
- ✅ `/lib/features/personal/presentation/widgets/personal_table_v4.dart`
- ✅ `/lib/features/mantenimiento/presentation/pages/mantenimiento_preventivo_page_v2.dart`
- ✅ `/lib/features/mantenimiento/presentation/widgets/mantenimiento_table_v4.dart`

## Comandos Obligatorios al Finalizar
```bash
# 1. Generar código (si usaste @JsonSerializable, @injectable, etc.)
flutter pub run build_runner build --delete-conflicting-outputs

# 2. OBLIGATORIO: Verificar warnings
flutter analyze
# DEBE retornar: "No issues found!" o máximo los mismos warnings que antes

# 3. Si hay warnings nuevos, corregirlos TODOS antes de continuar
```

## Reglas Críticas

1. ✅ **NUNCA** usar `color` en `HeaderStat`
2. ✅ **SIEMPRE** usar `AppDataGridV5` (NO `ModernDataTableV3`)
3. ✅ **SIEMPRE** usar `StatusBadge` (NO Container personalizado)
4. ✅ **SIEMPRE** 4 botones de paginación
5. ✅ **SIEMPRE** named parameter en `onSort`: `{required bool ascending}`
6. ✅ **SIEMPRE** usar `AppColors` (excepto white/black/transparent)
7. ✅ **SIEMPRE** ejecutar `flutter analyze` y corregir TODOS los warnings
8. ✅ **NUNCA** hardcodear strings (usar localización cuando esté disponible)
9. ✅ **SIEMPRE** `SafeArea` en página principal
10. ✅ **SIEMPRE** paginación visible (no condicional)

## Métricas de Calidad

Al finalizar, tu implementación debe cumplir:
- ✅ **0 errores** en `flutter analyze`
- ✅ **0 warnings nuevos** (máximo mantener los existentes)
- ✅ **Líneas por archivo**: Máximo 500 (dividir si excede)
- ✅ **Consistencia visual**: Idéntico a Vehículos/Personal/Mantenimiento
- ✅ **Performance**: Lazy loading con paginación de 25 items

---

**Creado**: 2024-12-25
**Basado en**: Vehículos, Personal, Mantenimiento Preventivo
**Versión**: 1.0
