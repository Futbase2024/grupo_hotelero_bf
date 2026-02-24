# /futplanner-page

Genera una Page con layouts responsive para una feature.

## Uso

```
/futplanner-page [tipo] [feature]
```

## Tipos Disponibles

| Tipo | Descripción | Archivos generados |
|------|-------------|-------------------|
| `list` | Lista de elementos | Page + 3 layouts + widgets |
| `detail` | Detalle de elemento | Page + 3 layouts |
| `form` | Formulario | Page + 3 layouts + form widgets |

## Ejemplos

```
/futplanner-page list players
/futplanner-page detail players
/futplanner-page form players
```

---

## Pre-requisitos

1. BLoC debe existir en `lib/features/[feature]/presentation/bloc/`
2. Entity debe existir en `futplanner_core_datasource`

---

## Estructura Generada

```
lib/features/[feature]/presentation/
├── pages/
│   └── [feature]_[tipo]_page.dart
├── layouts/
│   ├── [feature]_[tipo]_mobile_layout.dart
│   ├── [feature]_[tipo]_tablet_layout.dart
│   └── [feature]_[tipo]_desktop_layout.dart
└── widgets/
    └── [feature]_card.dart  (si tipo=list)
```

---

## Template: Page (List)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/ui/app_layout_builder.dart';
import '../bloc/[feature]_list_bloc.dart';
import '../layouts/[feature]_list_mobile_layout.dart';
import '../layouts/[feature]_list_tablet_layout.dart';
import '../layouts/[feature]_list_desktop_layout.dart';

/// Página de lista de [Feature]
///
/// Usa AppLayoutBuilder para responsive.
/// BLoC se provee desde el router.
class [Feature]ListPage extends StatelessWidget {
  const [Feature]ListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<[Feature]ListBloc, [Feature]ListState>(
      builder: (context, state) {
        return AppLayoutBuilder(
          mobile: [Feature]ListMobileLayout(state: state),
          tablet: [Feature]ListTabletLayout(state: state),
          desktop: [Feature]ListDesktopLayout(state: state),
        );
      },
    );
  }
}
```

---

## Template: Layout Mobile

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/ui/loading_overlay.dart';
import '../bloc/[feature]_list_bloc.dart';
import '../widgets/[feature]_card.dart';
import '../widgets/[feature]_empty_state.dart';

/// Layout mobile de lista de [Feature] (< 600px)
///
/// Optimizado para uso en campo:
/// - Lista vertical simple
/// - Cards touch-friendly
/// - FAB para agregar
class [Feature]ListMobileLayout extends StatelessWidget {
  const [Feature]ListMobileLayout({
    required this.state,
    super.key,
  });

  final [Feature]ListState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.[feature]Title),
        actions: [
          // ✅ IconButton nativo en AppBar (excepción)
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(context),
          ),
        ],
      ),
      body: _buildBody(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/[feature]/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return state.when(
      initial: () => const SizedBox.shrink(),
      // ✅ LoadingOverlay OBLIGATORIO
      loading: (message) => LoadingOverlay(message: message),
      loaded: (items, teamId, _, __) => items.isEmpty
          ? const [Feature]EmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: [Feature]Card(
                  item: items[index],
                  onTap: () => context.push('/[feature]/${items[index].id}'),
                ),
              ),
            ),
      error: (message, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(message),
            const SizedBox(height: 16),
            DSButton(
              label: context.lang.commonRetry,
              config: DSButtonConfig(
                onPressed: () => context
                    .read<[Feature]ListBloc>()
                    .add(const [Feature]ListEvent.refresh()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearch(BuildContext context) {
    // Implementar
  }
}
```

---

## Template: Layout Tablet

```dart
import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/ui/loading_overlay.dart';
import '../bloc/[feature]_list_bloc.dart';
import '../widgets/[feature]_card.dart';

/// Layout tablet de lista de [Feature] (600-1024px)
///
/// Optimizado para vestuarios:
/// - Grid de 2 columnas
/// - Cards más grandes
class [Feature]ListTabletLayout extends StatelessWidget {
  const [Feature]ListTabletLayout({
    required this.state,
    super.key,
  });

  final [Feature]ListState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.[feature]Title),
      ),
      body: state.when(
        initial: () => const SizedBox.shrink(),
        loading: (message) => LoadingOverlay(message: message),
        loaded: (items, _, __, ___) => GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,  // 2 columnas
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => [Feature]Card(item: items[index]),
        ),
        error: (message, _) => Center(child: Text(message)),
      ),
    );
  }
}
```

---

## Template: Layout Desktop

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iautomat_design_system/iautomat_design_system.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/ui/loading_overlay.dart';
import '../bloc/[feature]_list_bloc.dart';
import '../widgets/[feature]_card.dart';

/// Layout desktop de lista de [Feature] (>= 1024px)
///
/// Optimizado para oficina:
/// - NavigationRail lateral
/// - Grid de 3 columnas
/// - Panel de filtros
class [Feature]ListDesktopLayout extends StatelessWidget {
  const [Feature]ListDesktopLayout({
    required this.state,
    super.key,
  });

  final [Feature]ListState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // NavigationRail
          const AppNavigationRail(),

          // Contenido
          Expanded(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(child: _buildContent(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Text(
            context.lang.[feature]Title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const Spacer(),
          DSButton(
            label: context.lang.[feature]AddNew,
            leading: const Icon(Icons.add),
            config: DSButtonConfig(
              onPressed: () => context.push('/[feature]/new'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return state.when(
      initial: () => const SizedBox.shrink(),
      loading: (message) => LoadingOverlay(message: message),
      loaded: (items, _, __, ___) => GridView.builder(
        padding: const EdgeInsets.all(24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,  // 3 columnas
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          childAspectRatio: 1.2,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) => [Feature]Card(item: items[index]),
      ),
      error: (message, _) => Center(child: Text(message)),
    );
  }
}
```

---

## Template: Widget Card

```dart
import 'package:flutter/material.dart';
import 'package:futplanner_core_datasource/futplanner_core_datasource.dart';
import 'package:iautomat_design_system/iautomat_design_system.dart';

import '../../../../core/extensions/context_extensions.dart';

/// Card de [Feature] para listas
class [Feature]Card extends StatelessWidget {
  const [Feature]Card({
    required this.item,
    this.onTap,
    super.key,
  });

  final [Feature]Entity item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DSCard(
      config: DSCardConfig(
        variant: DSCardVariant.elevated,
        isInteractive: onTap != null,
        onTap: onTap,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.name,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            item.description ?? '',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
```

---

## Configurar Ruta GoRouter

Agregar en `lib/core/router/app_router.dart`:

```dart
GoRoute(
  path: '/[feature]',
  name: '[feature]List',
  builder: (context, state) => AppConfigWrapper(
    child: BlocProvider(
      create: (context) => getIt<[Feature]ListBloc>()
        ..add([Feature]ListEvent.load(teamId: teamId)),
      child: const [Feature]ListPage(),
    ),
  ),
  routes: [
    GoRoute(
      path: 'new',
      name: '[feature]New',
      builder: (context, state) => AppConfigWrapper(
        child: BlocProvider(
          create: (context) => getIt<[Feature]FormBloc>()
            ..add(const [Feature]FormEvent.initialize()),
          child: const [Feature]FormPage(),
        ),
      ),
    ),
    GoRoute(
      path: ':id',
      name: '[feature]Detail',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return AppConfigWrapper(
          child: BlocProvider(
            create: (context) => getIt<[Feature]DetailBloc>()
              ..add([Feature]DetailEvent.load(id: id)),
            child: const [Feature]DetailPage(),
          ),
        );
      },
    ),
  ],
),
```

---

## Traducciones Necesarias

Agregar en `lib/core/lang/app_es.arb`:

```json
"[feature]Title": "Título de [Feature]",
"[feature]AddNew": "Añadir [feature]",
"[feature]Empty": "No hay [feature]",
"[feature]Detail": "Detalle de [feature]"
```

Regenerar:
```bash
flutter gen-l10n
```

---

## Checklist

- [ ] Page con AppLayoutBuilder
- [ ] 3 layouts en archivos separados
- [ ] LoadingOverlay en `state.when(loading: ...)`
- [ ] Traducciones con `context.lang`
- [ ] UI components (Material 3 preferido, DS opcional si aporta valor)
- [ ] Widgets extraídos en `widgets/`
- [ ] Ruta configurada en GoRouter
- [ ] AppConfigWrapper en builder
- [ ] BlocProvider con getIt
- [ ] NO métodos `Widget _buildXxx()` en layouts

---

## Post-creación

```bash
# Regenerar traducciones
flutter gen-l10n

# Verificar
flutter analyze
```
