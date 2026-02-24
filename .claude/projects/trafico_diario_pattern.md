# 🚦 Patrón de Tráfico Diario - AmbuTrack

> **Feature**: `/features/trafico_diario/`
> **Propósito**: Gestión completa de planificación de servicios diarios
> **Tipo**: CRUD con paginación profesional y filtros avanzados

---

## 📋 Descripción del Feature

**Tráfico Diario** es el módulo central para planificación diaria de servicios de ambulancia. Permite:

- ✅ Visualizar servicios planificados del día
- ✅ Crear nuevos servicios (urgentes y programados)
- ✅ Editar servicios existentes
- ✅ Eliminar servicios cancelados
- ✅ Asignar vehículos, personal y equipamiento
- ✅ Filtrar por fecha, estado, centro, tipo
- ✅ Exportar planificación diaria

---

## 🏗️ Estructura de Archivos OBLIGATORIA

```
lib/features/trafico_diario/
├── presentation/
│   ├── pages/
│   │   └── planificar_servicios_page.dart      (≤200 líneas)
│   │       └─ Orquestación BLoC + Layout principal
│   │
│   ├── widgets/
│   │   ├── servicios_header.dart               (≤150 líneas)
│   │   │   └─ Título, búsqueda, botón agregar
│   │   │
│   │   ├── servicios_filters.dart              (≤200 líneas)
│   │   │   └─ Filtros por fecha/estado/centro/tipo
│   │   │
│   │   ├── servicios_table.dart                (≤350 líneas)
│   │   │   └─ AppDataGridV5 + paginación
│   │   │
│   │   ├── servicio_form_dialog.dart           (≤350 líneas)
│   │   │   └─ Formulario create/edit completo
│   │   │
│   │   ├── servicio_detail_dialog.dart         (≤250 líneas)
│   │   │   └─ Vista detallada solo lectura
│   │   │
│   │   └── servicio_card.dart                  (≤120 líneas)
│   │       └─ Card individual para tabla
│   │
│   └── bloc/
│       ├── servicios_bloc.dart                 (≤300 líneas)
│       ├── servicios_event.dart                (≤80 líneas)
│       └── servicios_state.dart                (≤60 líneas)
│
├── domain/
│   └── repositories/
│       └── servicio_repository.dart            (≤100 líneas)
│           └─ Contrato abstracto
│
└── data/
    └── repositories/
        └── servicio_repository_impl.dart       (≤300 líneas)
            └─ Implementación con pass-through a datasource
```

**Límites respetados**:
- ✅ Ningún archivo supera 350 líneas
- ✅ Promedio: ~180 líneas por archivo
- ✅ Total feature: ~2,400 líneas en 13 archivos

---

## 🎨 Componentes Visuales

### 1. PlanificarServiciosPage (Page Principal)

**Responsabilidad**: Orquestación y layout

```dart
class PlanificarServiciosPage extends StatelessWidget {
  const PlanificarServiciosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: BlocProvider(
        create: (_) => getIt<ServiciosBloc>()
          ..add(const ServiciosEvent.loadRequested()),
        child: const _PlanificarServiciosView(),
      ),
    );
  }
}

class _PlanificarServiciosView extends StatelessWidget {
  const _PlanificarServiciosView();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header fijo
        const ServiciosHeader(),
        const SizedBox(height: AppSizes.spacing),

        // Filtros fijos
        const ServiciosFilters(),
        const SizedBox(height: AppSizes.spacing),

        // Tabla con scroll y paginación
        Expanded(
          child: BlocBuilder<ServiciosBloc, ServiciosState>(
            builder: (context, state) {
              return state.map(
                initial: (_) => const _LoadingView(),
                loading: (_) => const _LoadingView(),
                loaded: (loaded) => ServiciosTable(
                  servicios: loaded.servicios,
                  currentPage: loaded.currentPage,
                  totalPages: loaded.totalPages,
                ),
                error: (error) => _ErrorView(message: error.message),
              );
            },
          ),
        ),
      ],
    );
  }
}
```

**Características**:
- ✅ Máximo 200 líneas
- ✅ Solo orquestación (no lógica)
- ✅ Widgets separados
- ✅ SafeArea obligatorio

---

### 2. ServiciosHeader (Encabezado con Búsqueda)

**Responsabilidad**: Título, búsqueda, botón agregar

```dart
class ServiciosHeader extends StatefulWidget {
  const ServiciosHeader({super.key});

  @override
  State<ServiciosHeader> createState() => _ServiciosHeaderState();
}

class _ServiciosHeaderState extends State<ServiciosHeader> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Título
        Expanded(
          child: Text(
            'Planificación de Servicios Diarios',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryLight,
            ),
          ),
        ),

        // Búsqueda
        SizedBox(
          width: 300,
          child: _SearchField(
            controller: _searchController,
            onSearchChanged: (query) {
              context.read<ServiciosBloc>().add(
                ServiciosEvent.searchChanged(query: query),
              );
            },
          ),
        ),

        const SizedBox(width: AppSizes.spacing),

        // Botón agregar
        AppButton(
          onPressed: () => _showCreateDialog(context),
          label: 'Agregar Servicio',
          icon: Icons.add,
        ),
      ],
    );
  }

  void _showCreateDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<ServiciosBloc>(),
        child: const ServicioFormDialog(),
      ),
    );
  }
}
```

**Características**:
- ✅ Máximo 150 líneas
- ✅ TextEditingController manejado correctamente
- ✅ Dispose obligatorio
- ✅ Búsqueda reactiva

---

### 3. ServiciosFilters (Filtros Avanzados)

**Responsabilidad**: Filtros por fecha, estado, centro, tipo

```dart
class ServiciosFilters extends StatelessWidget {
  const ServiciosFilters({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ServiciosBloc, ServiciosState>(
      builder: (context, state) {
        final filters = state.maybeWhen(
          loaded: (_, filters, __, ___, ____) => filters,
          orElse: () => const ServiciosFiltersData(),
        );

        return Container(
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            border: Border.all(color: AppColors.gray200),
          ),
          child: Row(
            children: [
              // Filtro fecha
              Expanded(
                child: _DateFilter(
                  selectedDate: filters.fechaInicio,
                  onChanged: (date) => _onDateChanged(context, date),
                ),
              ),

              const SizedBox(width: AppSizes.spacing),

              // Filtro estado
              Expanded(
                child: AppSearchableDropdown<String>(
                  value: filters.estado,
                  label: 'Estado',
                  items: _buildEstadoItems(),
                  onChanged: (estado) => _onEstadoChanged(context, estado),
                ),
              ),

              const SizedBox(width: AppSizes.spacing),

              // Filtro centro
              Expanded(
                child: AppSearchableDropdown<String>(
                  value: filters.centroId,
                  label: 'Centro Hospitalario',
                  items: _buildCentroItems(),
                  onChanged: (centro) => _onCentroChanged(context, centro),
                ),
              ),

              const SizedBox(width: AppSizes.spacing),

              // Botón limpiar filtros
              AppButton(
                onPressed: () => _onClearFilters(context),
                label: 'Limpiar',
                icon: Icons.clear,
                variant: AppButtonVariant.text,
              ),
            ],
          ),
        );
      },
    );
  }

  void _onDateChanged(BuildContext context, DateTime? date) {
    context.read<ServiciosBloc>().add(
      ServiciosEvent.filterChanged(fechaInicio: date),
    );
  }

  // ... métodos helper
}
```

**Características**:
- ✅ Máximo 200 líneas
- ✅ AppSearchableDropdown para listas grandes
- ✅ Filtros reactivos (actualizan BLoC)
- ✅ Botón limpiar filtros

---

### 4. ServiciosTable (Tabla con Paginación)

**Responsabilidad**: AppDataGridV5 + paginación profesional

```dart
class ServiciosTable extends StatelessWidget {
  const ServiciosTable({
    super.key,
    required this.servicios,
    required this.currentPage,
    required this.totalPages,
  });

  final List<ServicioEntity> servicios;
  final int currentPage;
  final int totalPages;

  @override
  Widget build(BuildContext context) {
    if (servicios.isEmpty) {
      return const _EmptyView();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tabla con scroll interno
        Expanded(
          child: AppDataGridV5<ServicioEntity>(
            columns: _buildColumns(),
            rows: servicios,
            buildCells: _buildCells,
            onView: (servicio) => _onView(context, servicio),
            onEdit: (servicio) => _onEdit(context, servicio),
            onDelete: (servicio) => _onDelete(context, servicio),
            emptyMessage: 'No hay servicios registrados',
          ),
        ),

        const SizedBox(height: AppSizes.spacing),

        // Paginación fija abajo
        _buildPaginationControls(context),
      ],
    );
  }

  List<DataGridColumn> _buildColumns() {
    return const [
      DataGridColumn(label: 'FECHA/HORA', sortable: true),
      DataGridColumn(label: 'PACIENTE', sortable: true),
      DataGridColumn(label: 'ORIGEN', sortable: false),
      DataGridColumn(label: 'DESTINO', sortable: false),
      DataGridColumn(label: 'TIPO', sortable: true),
      DataGridColumn(label: 'VEHÍCULO', sortable: true),
      DataGridColumn(label: 'ESTADO', sortable: true),
    ];
  }

  List<Widget> _buildCells(ServicioEntity servicio) {
    return [
      _buildFechaHoraCell(servicio),
      _buildPacienteCell(servicio),
      _buildOrigenCell(servicio),
      _buildDestinoCell(servicio),
      _buildTipoCell(servicio),
      _buildVehiculoCell(servicio),
      _buildEstadoCell(servicio),
    ];
  }

  Widget _buildPaginationControls(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Mostrando ${_startItem} - ${_endItem} de ${_totalItems} servicios',
            style: AppTextStyles.bodySmallSecondary,
          ),

          Row(
            children: [
              _PaginationButton(
                onPressed: currentPage > 0 ? () => _goToFirstPage(context) : null,
                icon: Icons.first_page,
                tooltip: 'Primera página',
              ),
              // ... resto de botones paginación
            ],
          ),
        ],
      ),
    );
  }

  // ... métodos helper para cells y paginación
}
```

**Características**:
- ✅ Máximo 350 líneas
- ✅ AppDataGridV5 con scroll interno
- ✅ Paginación fija abajo (siempre visible)
- ✅ 25 items por página
- ✅ 4 botones navegación (First | Prev | Next | Last)
- ✅ Badge azul central "Página X de Y"

---

### 5. ServicioFormDialog (Formulario Create/Edit)

**Responsabilidad**: Formulario completo con validaciones

```dart
class ServicioFormDialog extends StatefulWidget {
  const ServicioFormDialog({super.key, this.servicio});

  final ServicioEntity? servicio;

  @override
  State<ServicioFormDialog> createState() => _ServicioFormDialogState();
}

class _ServicioFormDialogState extends State<ServicioFormDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Controllers
  late TextEditingController _observacionesController;

  // Valores del form
  DateTime? _fechaHora;
  String? _pacienteId;
  String? _origenId;
  String? _destinoId;
  String? _tipoServicioId;
  String? _vehiculoId;

  bool get _isEditing => widget.servicio != null;

  @override
  void initState() {
    super.initState();
    _observacionesController = TextEditingController(
      text: widget.servicio?.observaciones,
    );
    // Inicializar otros valores si es edición
    if (_isEditing) {
      _fechaHora = widget.servicio!.fechaHora;
      _pacienteId = widget.servicio!.pacienteId;
      // ... resto de valores
    }
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ServiciosBloc, ServiciosState>(
      listener: (context, state) {
        if (state is ServiciosLoaded) {
          CrudOperationHandler.handleSuccess(
            context: context,
            isSaving: _isSaving,
            isEditing: _isEditing,
            entityName: 'Servicio',
            onClose: () => setState(() => _isSaving = false),
          );
        } else if (state is ServiciosError) {
          CrudOperationHandler.handleError(
            context: context,
            isSaving: _isSaving,
            isEditing: _isEditing,
            entityName: 'Servicio',
            errorMessage: state.message,
            onClose: () => setState(() => _isSaving = false),
          );
        }
      },
      child: AppDialog(
        title: _isEditing ? 'Editar Servicio' : 'Crear Servicio',
        width: 800,
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Fecha y hora
                _DateTimeField(
                  value: _fechaHora,
                  onChanged: (date) => setState(() => _fechaHora = date),
                ),

                const SizedBox(height: AppSizes.spacing),

                // Paciente
                AppSearchableDropdown<String>(
                  value: _pacienteId,
                  label: 'Paciente *',
                  items: _buildPacienteItems(),
                  onChanged: (id) => setState(() => _pacienteId = id),
                ),

                const SizedBox(height: AppSizes.spacing),

                // Origen y Destino (Row)
                Row(
                  children: [
                    Expanded(
                      child: AppSearchableDropdown<String>(
                        value: _origenId,
                        label: 'Origen *',
                        items: _buildCentroItems(),
                        onChanged: (id) => setState(() => _origenId = id),
                      ),
                    ),
                    const SizedBox(width: AppSizes.spacing),
                    Expanded(
                      child: AppSearchableDropdown<String>(
                        value: _destinoId,
                        label: 'Destino *',
                        items: _buildCentroItems(),
                        onChanged: (id) => setState(() => _destinoId = id),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSizes.spacing),

                // Tipo y Vehículo (Row)
                Row(
                  children: [
                    Expanded(
                      child: AppSearchableDropdown<String>(
                        value: _tipoServicioId,
                        label: 'Tipo de Servicio *',
                        items: _buildTipoItems(),
                        onChanged: (id) => setState(() => _tipoServicioId = id),
                      ),
                    ),
                    const SizedBox(width: AppSizes.spacing),
                    Expanded(
                      child: AppSearchableDropdown<String>(
                        value: _vehiculoId,
                        label: 'Vehículo *',
                        items: _buildVehiculoItems(),
                        onChanged: (id) => setState(() => _vehiculoId = id),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSizes.spacing),

                // Observaciones
                TextFormField(
                  controller: _observacionesController,
                  maxLines: 3,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    labelText: 'Observaciones',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          AppButton(
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
            label: 'Cancelar',
            variant: AppButtonVariant.text,
          ),
          AppButton(
            onPressed: _isSaving ? null : _onSave,
            label: _isEditing ? 'Actualizar' : 'Guardar',
            icon: _isEditing ? Icons.save : Icons.add,
          ),
        ],
      ),
    );
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    // Mostrar loading overlay
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AppLoadingOverlay(
          message: _isEditing ? 'Actualizando servicio...' : 'Creando servicio...',
          color: _isEditing ? AppColors.secondary : AppColors.primary,
          icon: _isEditing ? Icons.edit : Icons.add_circle_outline,
        );
      },
    );

    // Crear entity y disparar evento
    final ServicioEntity servicio = ServicioEntity(
      id: _isEditing ? widget.servicio!.id : const Uuid().v4(),
      fechaHora: _fechaHora!,
      pacienteId: _pacienteId!,
      origenId: _origenId!,
      destinoId: _destinoId!,
      tipoServicioId: _tipoServicioId!,
      vehiculoId: _vehiculoId,
      observaciones: _observacionesController.text.trim(),
      estado: _isEditing ? widget.servicio!.estado : 'pendiente',
    );

    if (_isEditing) {
      context.read<ServiciosBloc>().add(
        ServiciosEvent.updateRequested(servicio: servicio),
      );
    } else {
      context.read<ServiciosBloc>().add(
        ServiciosEvent.createRequested(servicio: servicio),
      );
    }
  }

  // ... métodos helper para items de dropdowns
}
```

**Características**:
- ✅ Máximo 350 líneas
- ✅ CrudOperationHandler para resultados
- ✅ AppSearchableDropdown para listas grandes
- ✅ Validaciones completas
- ✅ Loading overlay
- ✅ barrierDismissible: false

---

## 🎯 BLoC Pattern

### Eventos

```dart
@freezed
class ServiciosEvent with _$ServiciosEvent {
  const factory ServiciosEvent.started() = _Started;
  const factory ServiciosEvent.loadRequested() = _LoadRequested;
  const factory ServiciosEvent.refreshRequested() = _RefreshRequested;

  const factory ServiciosEvent.createRequested({
    required ServicioEntity servicio,
  }) = _CreateRequested;

  const factory ServiciosEvent.updateRequested({
    required ServicioEntity servicio,
  }) = _UpdateRequested;

  const factory ServiciosEvent.deleteRequested({
    required String id,
  }) = _DeleteRequested;

  const factory ServiciosEvent.searchChanged({
    required String query,
  }) = _SearchChanged;

  const factory ServiciosEvent.filterChanged({
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? estado,
    String? centroId,
  }) = _FilterChanged;

  const factory ServiciosEvent.pageChanged({
    required int page,
  }) = _PageChanged;
}
```

### Estados

```dart
@freezed
class ServiciosState with _$ServiciosState {
  const factory ServiciosState.initial() = _Initial;

  const factory ServiciosState.loading() = _Loading;

  const factory ServiciosState.loaded({
    required List<ServicioEntity> servicios,
    required ServiciosFiltersData filters,
    @Default(0) int currentPage,
    @Default(0) int totalPages,
    @Default(0) int totalItems,
  }) = _Loaded;

  const factory ServiciosState.error({
    required String message,
  }) = _Error;
}
```

### BLoC

```dart
class ServiciosBloc extends Bloc<ServiciosEvent, ServiciosState> {
  final ServicioRepository _repository;
  static const int _itemsPerPage = 25;

  ServiciosBloc({required ServicioRepository repository})
      : _repository = repository,
        super(const ServiciosState.initial()) {
    on<_Started>(_onStarted);
    on<_LoadRequested>(_onLoadRequested);
    on<_RefreshRequested>(_onRefreshRequested);
    on<_CreateRequested>(_onCreateRequested);
    on<_UpdateRequested>(_onUpdateRequested);
    on<_DeleteRequested>(_onDeleteRequested);
    on<_SearchChanged>(_onSearchChanged);
    on<_FilterChanged>(_onFilterChanged);
    on<_PageChanged>(_onPageChanged);
  }

  Future<void> _onStarted(_Started event, Emitter<ServiciosState> emit) async {
    emit(const ServiciosState.loading());
    await _loadServicios(emit);
  }

  Future<void> _loadServicios(
    Emitter<ServiciosState> emit, {
    ServiciosFiltersData filters = const ServiciosFiltersData(),
    int page = 0,
  }) async {
    try {
      final servicios = await _repository.getAll();

      // Aplicar filtros
      final filteredServicios = _applyFilters(servicios, filters);

      // Calcular paginación
      final totalItems = filteredServicios.length;
      final totalPages = (totalItems / _itemsPerPage).ceil();
      final startIndex = page * _itemsPerPage;
      final endIndex = (startIndex + _itemsPerPage).clamp(0, totalItems);
      final paginatedServicios = filteredServicios.sublist(startIndex, endIndex);

      emit(ServiciosState.loaded(
        servicios: paginatedServicios,
        filters: filters,
        currentPage: page,
        totalPages: totalPages,
        totalItems: totalItems,
      ));
    } catch (e) {
      emit(ServiciosState.error(message: e.toString()));
    }
  }

  List<ServicioEntity> _applyFilters(
    List<ServicioEntity> servicios,
    ServiciosFiltersData filters,
  ) {
    var result = servicios;

    if (filters.searchQuery.isNotEmpty) {
      result = result.where((s) {
        final query = filters.searchQuery.toLowerCase();
        return s.pacienteNombre.toLowerCase().contains(query) ||
               s.origenNombre.toLowerCase().contains(query) ||
               s.destinoNombre.toLowerCase().contains(query);
      }).toList();
    }

    if (filters.fechaInicio != null) {
      result = result.where((s) {
        return s.fechaHora.isAfter(filters.fechaInicio!) ||
               s.fechaHora.isAtSameMomentAs(filters.fechaInicio!);
      }).toList();
    }

    if (filters.estado != null) {
      result = result.where((s) => s.estado == filters.estado).toList();
    }

    if (filters.centroId != null) {
      result = result.where((s) {
        return s.origenId == filters.centroId ||
               s.destinoId == filters.centroId;
      }).toList();
    }

    return result;
  }

  // ... resto de handlers
}
```

**Características**:
- ✅ Máximo 300 líneas
- ✅ Lógica de filtrado en el BLoC
- ✅ Paginación manejada en el BLoC
- ✅ 25 items por página (constante)

---

## ✅ Checklist de Implementación

Antes de considerar completo el feature:

- [ ] **Estructura de carpetas** creada según patrón
- [ ] **Todos los archivos** bajo 350-400 líneas
- [ ] **Page principal** solo orquestación (≤200 líneas)
- [ ] **Header** con búsqueda y botón agregar (≤150 líneas)
- [ ] **Filters** con dropdowns searchable (≤200 líneas)
- [ ] **Table** con AppDataGridV5 y paginación (≤350 líneas)
- [ ] **Form dialog** con validaciones (≤350 líneas)
- [ ] **BLoC** con filtros y paginación (≤300 líneas)
- [ ] **Repository** con pass-through (≤300 líneas)
- [ ] **CrudOperationHandler** para resultados
- [ ] **flutter analyze** → 0 warnings
- [ ] **Tests** con cobertura mínima

---

## 📚 Referencias

- **Pattern Base**: [ITVRevisionesTableV4](../../itv_revisiones/presentation/widgets/itv_revisiones_table_v4.dart)
- **Paginación**: [Patrón AppDataGridV5](../../CLAUDE.md#paginación-profesional)
- **Formularios**: [CrudOperationHandler](../../core/widgets/handlers/crud_operation_handler.dart)
- **Límites**: [ambutrack_file_limits.md](./ambutrack_file_limits.md)

---

**Última actualización**: 2025-01-07
