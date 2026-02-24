# 🏗️ Feature Generator Agent

> **ID**: AG-01  
> **Rol**: Generador de features completas  
> **Proyecto**: Content Engine App

---

## 🎯 Propósito

Generar la estructura completa de una feature siguiendo la arquitectura del proyecto:
- Clean Architecture Lite (Domain contracts, Data implementations)
- BLoC + Freezed para estado
- Cupertino para UI
- GoRouteData para rutas

---

## 📋 Responsabilidades

1. **Crear estructura de carpetas** de la feature
2. **Generar modelos** con Freezed y JSON serialization
3. **Crear contratos** de repository en domain/
4. **Implementar repositories** en data/
5. **Generar BLoC** con Events y States Freezed
6. **Crear Page** principal con Cupertino
7. **Generar Widgets** como clases separadas
8. **Configurar Routes** con GoRouteData pattern
9. **Registrar** en DI y router

---

## 🚫 Prohibiciones

- ❌ NUNCA crear métodos que devuelvan Widget (`_buildX()`)
- ❌ NUNCA usar Material widgets
- ❌ NUNCA usar StatefulWidget cuando BLoC es apropiado
- ❌ NUNCA crear código sin preparar tests
- ❌ NUNCA olvidar `dart fix --apply`

---

## ✅ Checklist de Feature Completa

```
📁 Estructura
├── [ ] lib/data/models/{feature}_model.dart
├── [ ] lib/domain/repositories/{feature}_repository.dart
├── [ ] lib/data/repositories/{feature}_repository_impl.dart
├── [ ] lib/presentation/features/{feature}/
│   ├── [ ] bloc/
│   │   ├── [ ] {feature}_bloc.dart
│   │   ├── [ ] {feature}_event.dart
│   │   └── [ ] {feature}_state.dart
│   ├── [ ] page/
│   │   └── [ ] {feature}_page.dart
│   ├── [ ] widgets/
│   │   ├── [ ] {feature}_loaded_view.dart
│   │   ├── [ ] {feature}_empty_view.dart
│   │   └── [ ] {feature}_card.dart
│   └── [ ] routes/
│       └── [ ] {feature}_route.dart

🔧 Configuración
├── [ ] Registrar en lib/injection.dart
├── [ ] Añadir ruta en lib/core/config/router_config.dart
├── [ ] Ejecutar build_runner
└── [ ] Ejecutar dart fix --apply

🧪 Tests (preparar estructura)
├── [ ] test/unit/data/repositories/{feature}_repository_test.dart
├── [ ] test/unit/presentation/features/{feature}/bloc/{feature}_bloc_test.dart
└── [ ] test/widget/presentation/features/{feature}/widgets/
```

---

## 📝 Templates

### 1. Model Template

```dart
// lib/data/models/{feature}_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part '{feature}_model.freezed.dart';
part '{feature}_model.g.dart';

@freezed
class {Feature}Model with _${Feature}Model {
  const factory {Feature}Model({
    required String id,
    required String name,
    String? description,
    @Default('active') String status,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _{Feature}Model;

  factory {Feature}Model.fromJson(Map<String, dynamic> json) =>
      _${Feature}ModelFromJson(json);
}
```

### 2. Repository Contract Template

```dart
// lib/domain/repositories/{feature}_repository.dart
import '../../data/models/{feature}_model.dart';

/// Contrato del repositorio de {Feature}
/// Implementación: data/repositories/{feature}_repository_impl.dart
abstract class {Feature}Repository {
  Future<List<{Feature}Model>> getAll();
  Future<{Feature}Model?> getById(String id);
  Stream<List<{Feature}Model>> watchAll();
  Future<{Feature}Model> create({Feature}Model item);
  Future<void> update({Feature}Model item);
  Future<void> delete(String id);
}
```

### 3. Repository Implementation Template

```dart
// lib/data/repositories/{feature}_repository_impl.dart
import '../datasources/remote/supabase_datasource.dart';
import '../models/{feature}_model.dart';
import '../../domain/repositories/{feature}_repository.dart';

class {Feature}RepositoryImpl implements {Feature}Repository {
  final SupabaseDatasource _datasource;

  {Feature}RepositoryImpl({required SupabaseDatasource datasource})
      : _datasource = datasource;

  @override
  Future<List<{Feature}Model>> getAll() async {
    final response = await _datasource.client
        .from('{table_name}')
        .select()
        .order('created_at', ascending: false);
    return (response as List).map((e) => {Feature}Model.fromJson(e)).toList();
  }

  @override
  Future<{Feature}Model?> getById(String id) async {
    final response = await _datasource.client
        .from('{table_name}')
        .select()
        .eq('id', id)
        .maybeSingle();
    return response != null ? {Feature}Model.fromJson(response) : null;
  }

  @override
  Stream<List<{Feature}Model>> watchAll() {
    return _datasource.client
        .from('{table_name}')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((e) => {Feature}Model.fromJson(e)).toList());
  }

  @override
  Future<{Feature}Model> create({Feature}Model item) async {
    final response = await _datasource.client
        .from('{table_name}')
        .insert(item.toJson())
        .select()
        .single();
    return {Feature}Model.fromJson(response);
  }

  @override
  Future<void> update({Feature}Model item) async {
    await _datasource.client
        .from('{table_name}')
        .update(item.toJson())
        .eq('id', item.id);
  }

  @override
  Future<void> delete(String id) async {
    await _datasource.client.from('{table_name}').delete().eq('id', id);
  }
}
```

### 4. BLoC Templates

```dart
// lib/presentation/features/{feature}/bloc/{feature}_event.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../data/models/{feature}_model.dart';

part '{feature}_event.freezed.dart';

@freezed
class {Feature}Event with _${Feature}Event {
  const factory {Feature}Event.started() = _Started;
  const factory {Feature}Event.loadRequested() = _LoadRequested;
  const factory {Feature}Event.refreshRequested() = _RefreshRequested;
  const factory {Feature}Event.createRequested({
    required {Feature}Model item,
  }) = _CreateRequested;
  const factory {Feature}Event.updateRequested({
    required {Feature}Model item,
  }) = _UpdateRequested;
  const factory {Feature}Event.deleteRequested({
    required String id,
  }) = _DeleteRequested;
}
```

```dart
// lib/presentation/features/{feature}/bloc/{feature}_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../data/models/{feature}_model.dart';

part '{feature}_state.freezed.dart';

@freezed
class {Feature}State with _${Feature}State {
  const factory {Feature}State.initial() = _Initial;
  const factory {Feature}State.loading() = _Loading;
  const factory {Feature}State.loaded({
    required List<{Feature}Model> items,
    @Default(false) bool isRefreshing,
  }) = _Loaded;
  const factory {Feature}State.error({
    required String message,
    List<{Feature}Model>? previousItems,
  }) = _Error;
}
```

```dart
// lib/presentation/features/{feature}/bloc/{feature}_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/repositories/{feature}_repository.dart';
import '{feature}_event.dart';
import '{feature}_state.dart';

class {Feature}Bloc extends Bloc<{Feature}Event, {Feature}State> {
  final {Feature}Repository _repository;

  {Feature}Bloc({required {Feature}Repository repository})
      : _repository = repository,
        super(const {Feature}State.initial()) {
    on<{Feature}Event>(_onEvent);
  }

  Future<void> _onEvent(
    {Feature}Event event,
    Emitter<{Feature}State> emit,
  ) async {
    await event.map(
      started: (e) => _onStarted(e, emit),
      loadRequested: (e) => _onLoadRequested(e, emit),
      refreshRequested: (e) => _onRefreshRequested(e, emit),
      createRequested: (e) => _onCreateRequested(e, emit),
      updateRequested: (e) => _onUpdateRequested(e, emit),
      deleteRequested: (e) => _onDeleteRequested(e, emit),
    );
  }

  Future<void> _onStarted(_Started event, Emitter<{Feature}State> emit) async {
    emit(const {Feature}State.loading());
    await _load(emit);
  }

  Future<void> _onLoadRequested(
    _LoadRequested event,
    Emitter<{Feature}State> emit,
  ) async {
    emit(const {Feature}State.loading());
    await _load(emit);
  }

  Future<void> _onRefreshRequested(
    _RefreshRequested event,
    Emitter<{Feature}State> emit,
  ) async {
    final currentState = state;
    if (currentState is _Loaded) {
      emit(currentState.copyWith(isRefreshing: true));
    }
    await _load(emit);
  }

  Future<void> _onCreateRequested(
    _CreateRequested event,
    Emitter<{Feature}State> emit,
  ) async {
    try {
      await _repository.create(event.item);
      add(const {Feature}Event.loadRequested());
    } catch (e) {
      emit({Feature}State.error(message: e.toString()));
    }
  }

  Future<void> _onUpdateRequested(
    _UpdateRequested event,
    Emitter<{Feature}State> emit,
  ) async {
    try {
      await _repository.update(event.item);
      add(const {Feature}Event.loadRequested());
    } catch (e) {
      emit({Feature}State.error(message: e.toString()));
    }
  }

  Future<void> _onDeleteRequested(
    _DeleteRequested event,
    Emitter<{Feature}State> emit,
  ) async {
    try {
      await _repository.delete(event.id);
      add(const {Feature}Event.loadRequested());
    } catch (e) {
      emit({Feature}State.error(message: e.toString()));
    }
  }

  Future<void> _load(Emitter<{Feature}State> emit) async {
    try {
      final items = await _repository.getAll();
      emit({Feature}State.loaded(items: items));
    } catch (e) {
      emit({Feature}State.error(message: e.toString()));
    }
  }
}
```

### 5. Page Template (Cupertino)

```dart
// lib/presentation/features/{feature}/page/{feature}_page.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/{feature}_bloc.dart';
import '../bloc/{feature}_state.dart';
import '../bloc/{feature}_event.dart';
import '../widgets/{feature}_loaded_view.dart';
import '../../../../shared/widgets/cupertino/ce_loading.dart';
import '../../../../shared/widgets/error_view.dart';

class {Feature}Page extends StatelessWidget {
  const {Feature}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('{Feature}'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.add),
          onPressed: () => _showAddSheet(context),
        ),
      ),
      child: SafeArea(
        child: BlocBuilder<{Feature}Bloc, {Feature}State>(
          builder: (context, state) {
            // ✅ Usar widgets separados, NO métodos
            return state.map(
              initial: (_) => const CELoading(),
              loading: (_) => const CELoading(),
              loaded: (loaded) => {Feature}LoadedView(
                items: loaded.items,
                isRefreshing: loaded.isRefreshing,
              ),
              error: (error) => ErrorView(
                message: error.message,
                onRetry: () => context.read<{Feature}Bloc>().add(
                  const {Feature}Event.loadRequested(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => const {Feature}FormSheet(),
    );
  }
}
```

### 6. Widget Separado Template

```dart
// lib/presentation/features/{feature}/widgets/{feature}_loaded_view.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/models/{feature}_model.dart';
import '../bloc/{feature}_bloc.dart';
import '../bloc/{feature}_event.dart';
import '../routes/{feature}_route.dart';
import '{feature}_card.dart';
import '{feature}_empty_view.dart';

/// ✅ Widget separado para estado loaded
class {Feature}LoadedView extends StatelessWidget {
  const {Feature}LoadedView({
    super.key,
    required this.items,
    this.isRefreshing = false,
  });

  final List<{Feature}Model> items;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const {Feature}EmptyView();
    }

    return CustomScrollView(
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            context.read<{Feature}Bloc>().add(
              const {Feature}Event.refreshRequested(),
            );
          },
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: {Feature}Card(
                  item: item,
                  onTap: () => {Feature}DetailRoute.pushNamed(
                    context,
                    id: item.id,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
```

### 7. Route Template

```dart
// lib/presentation/features/{feature}/routes/{feature}_route.dart
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../page/{feature}_page.dart';
import '../page/{feature}_detail_page.dart';

class {Feature}Route extends GoRouteData {
  static const routeName = '/{feature}';
  static const routePath = '{feature}';

  static GoRoute goRoute({List<RouteBase> routes = const []}) {
    return GoRoute(
      name: routeName,
      path: routePath,
      builder: (context, state) => const {Feature}Page(),
      routes: [
        {Feature}DetailRoute.goRoute(),
        ...routes,
      ],
    );
  }

  static Future<void> pushNamed(BuildContext context) =>
      context.pushNamed(routeName);

  static void goNamed(BuildContext context) =>
      context.goNamed(routeName);
}

class {Feature}DetailRoute extends GoRouteData {
  static const routeName = '/{feature}/:id';
  static const routePath = ':id';

  final String id;
  
  const {Feature}DetailRoute({required this.id});

  static GoRoute goRoute({List<RouteBase> routes = const []}) {
    return GoRoute(
      name: routeName,
      path: routePath,
      builder: (context, state) => {Feature}DetailPage(
        id: state.pathParameters['id']!,
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

---

## 🔄 Proceso de Generación

1. **Recibir solicitud** con nombre de feature y requisitos
2. **Verificar** que no existe ya la feature
3. **Crear estructura** de carpetas
4. **Generar archivos** usando templates
5. **Adaptar** a requisitos específicos
6. **Ejecutar** build_runner
7. **Ejecutar** dart fix --apply
8. **Preparar** estructura de tests
9. **Notificar** a AG-05 (QA) para tests

---

## 📌 Notas Importantes

- Cada feature debe ser **autocontenida** en su carpeta
- Los widgets deben ser **clases separadas**, nunca métodos
- Usar **Freezed** para todos los modelos, events y states
- Registrar **siempre** en DI antes de usar
- **Verificar** con `dart analyze` que no hay errores
