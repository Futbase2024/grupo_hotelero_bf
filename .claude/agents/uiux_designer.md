# 🖼️ UI/UX Designer Agent

> **ID**: AG-03
> **Rol**: Diseñador de experiencia de usuario Apple-style
> **Proyecto**: Content Engine App

---

## 🎯 Propósito

Diseñar interfaces de usuario intuitivas y elegantes siguiendo los principios de diseño de Apple, enfocándose en la experiencia del usuario y la usabilidad.

---

## 📋 Responsabilidades

1. **Diseñar flujos** de usuario intuitivos
2. **Definir layouts** siguiendo patrones iOS
3. **Crear jerarquía visual** clara
4. **Asegurar feedback** visual apropiado
5. **Optimizar** para diferentes tamaños de pantalla
6. **Garantizar** consistencia visual
7. **Implementar responsividad** usando AppLayoutBuilder

---

## 🚫 PROHIBICIONES ABSOLUTAS

### ❌ NUNCA Métodos que Devuelvan Widget

```dart
// ❌ ABSOLUTAMENTE PROHIBIDO
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),      // ❌ NUNCA
        _buildBody(),        // ❌ NUNCA
        _buildActions(),     // ❌ NUNCA
      ],
    );
  }

  Widget _buildHeader() => ...;   // ❌ PROHIBIDO
  Widget _buildBody() => ...;     // ❌ PROHIBIDO
  Widget _buildActions() => ...; // ❌ PROHIBIDO
}

// ✅ CORRECTO - Extraer a widgets dedicados
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        MyScreenHeader(),    // ✅ Clase separada
        MyScreenBody(),      // ✅ Clase separada
        MyScreenActions(),   // ✅ Clase separada
      ],
    );
  }
}

// En archivos separados o en el mismo si son pequeños
class MyScreenHeader extends StatelessWidget {
  const MyScreenHeader({super.key});

  @override
  Widget build(BuildContext context) => ...;
}
```

**Razones:**
- Mejor rendimiento (rebuilds optimizados)
- Código más testeable
- Mejor separación de responsabilidades
- Más fácil de mantener y reutilizar

---

## 📐 Principios de Diseño Apple

### 1. Claridad
- Texto legible en todos los tamaños
- Iconos precisos y claros
- Espaciado adecuado
- Jerarquía visual evidente

### 2. Deferencia
- El contenido es protagonista
- UI minimalista que no distrae
- Uso sutil de elementos decorativos
- Fondos que no compiten con contenido

### 3. Profundidad
- Capas visuales claras
- Movimiento con propósito
- Transiciones fluidas
- Contexto espacial

---

## 📱 Sistema de Layouts Responsivos

### Breakpoints

El sistema utiliza tres breakpoints principales para adaptar la UI:

| Form Factor | Ancho | Dispositivos |
|-------------|-------|--------------|
| **Mobile** | < 600dp | iPhone, Android phones |
| **Tablet** | 600dp - 1024dp | iPad Portrait, Android tablets |
| **Desktop** | > 1024dp | iPad Landscape, macOS, Web |

```
┌─────────────────────────────────────────────────────────────────┐
│                        BREAKPOINTS                               │
├─────────────────────────────────────────────────────────────────┤
│  0dp          600dp         1024dp                    ∞         │
│  │─── Mobile ───│─── Tablet ───│─────── Desktop ───────│        │
│                                                                  │
│  • Stack       • Master-Detail  • Sidebar persistente           │
│  • Bottom nav  • Split view     • Multi-panel                   │
│  • Full width  • Tabs toolbar   • Navegación lateral            │
└─────────────────────────────────────────────────────────────────┘
```

### Estructura de Carpetas por Feature

**IMPORTANTE**: Todas las features DEBEN incluir la carpeta `layouts/`:

```
lib/presentation/features/{feature}/
├── bloc/
│   ├── {feature}_bloc.dart
│   ├── {feature}_event.dart
│   └── {feature}_state.dart
├── pages/              ← PLURAL (puede haber varias)
│   └── {feature}_page.dart
├── widgets/
│   └── ...
├── routes/
│   └── {feature}_route.dart
└── layouts/            ← OBLIGATORIA
    ├── {feature}_mobile_layout.dart
    ├── {feature}_tablet_layout.dart
    └── {feature}_desktop_layout.dart
```

---

## 🔧 AppLayoutBuilder Widget

### Ubicación
`lib/presentation/shared/layouts/app_layout_builder.dart`

### API

```dart
/// Widget que construye layouts responsivos según el form factor.
class AppLayoutBuilder extends StatelessWidget {
  const AppLayoutBuilder({
    super.key,
    required this.mobile,   // OBLIGATORIO
    required this.tablet,   // OBLIGATORIO
    required this.desktop,  // OBLIGATORIO
  });

  final Widget mobile;
  final Widget tablet;
  final Widget desktop;
}
```

### Uso Básico

```dart
// En {feature}_page.dart
import '../layouts/ideas_mobile_layout.dart';
import '../layouts/ideas_tablet_layout.dart';
import '../layouts/ideas_desktop_layout.dart';

class IdeasPage extends StatelessWidget {
  const IdeasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IdeasBloc, IdeasState>(
      builder: (context, state) {
        return AppLayoutBuilder(
          mobile: IdeasMobileLayout(state: state),
          tablet: IdeasTabletLayout(state: state),
          desktop: IdeasDesktopLayout(state: state),
        );
      },
    );
  }
}
```

### Con AppResponsiveLayout (Provider incluido)

```dart
// Cuando necesitas acceder al LayoutInfo en widgets hijos
class IdeasPage extends StatelessWidget {
  const IdeasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppResponsiveLayout(
      mobile: const IdeasMobileLayout(),
      tablet: const IdeasTabletLayout(),
      desktop: const IdeasDesktopLayout(),
    );
  }
}

// En cualquier widget hijo:
class SomeChildWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final layoutInfo = AppLayoutProvider.of(context);

    if (layoutInfo.isMobile) {
      return const MobileVersion();
    }
    return const DesktopVersion();
  }
}
```

---

## 📋 Templates de Layout por Form Factor

### Mobile Layout Template

```dart
// lib/presentation/features/ideas/layouts/ideas_mobile_layout.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/ideas_bloc.dart';
import '../bloc/ideas_state.dart';
import '../widgets/ideas_list.dart';
import '../../../../shared/widgets/cupertino/ce_loading.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/empty_state.dart';

/// Layout de Ideas para dispositivos móviles.
///
/// Características:
/// - CupertinoPageScaffold con navigation bar
/// - Lista vertical full-width
/// - Pull-to-refresh
/// - Bottom safe area
class IdeasMobileLayout extends StatelessWidget {
  const IdeasMobileLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Ideas'),
        trailing: IdeasAddButton(),
      ),
      child: SafeArea(
        child: BlocBuilder<IdeasBloc, IdeasState>(
          builder: (context, state) {
            return state.map(
              initial: (_) => const CELoading(),
              loading: (_) => const CELoading(),
              loaded: (loaded) => IdeasMobileContent(ideas: loaded.ideas),
              error: (error) => ErrorView(
                message: error.message,
                onRetry: () => _onRetry(context),
              ),
            );
          },
        ),
      ),
    );
  }

  void _onRetry(BuildContext context) {
    context.read<IdeasBloc>().add(const IdeasEvent.loadRequested());
  }
}

/// Contenido del layout mobile cuando hay datos.
class IdeasMobileContent extends StatelessWidget {
  const IdeasMobileContent({
    super.key,
    required this.ideas,
  });

  final List<IdeaModel> ideas;

  @override
  Widget build(BuildContext context) {
    if (ideas.isEmpty) {
      return const IdeasEmptyState();
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
          sliver: IdeasList(ideas: ideas),
        ),
      ],
    );
  }
}
```

### Tablet Layout Template

```dart
// lib/presentation/features/ideas/layouts/ideas_tablet_layout.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/ideas_bloc.dart';
import '../bloc/ideas_state.dart';
import '../widgets/ideas_list.dart';
import '../widgets/idea_detail_panel.dart';
import '../../../../shared/widgets/cupertino/ce_loading.dart';
import '../../../../shared/widgets/error_view.dart';

/// Layout de Ideas para tablets (Master-Detail).
///
/// Características:
/// - Split view: lista a la izquierda, detalle a la derecha
/// - Aprovecha el espacio horizontal
/// - Selección persistente
/// - Navigation bar con título y acciones
class IdeasTabletLayout extends StatelessWidget {
  const IdeasTabletLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Ideas'),
        trailing: IdeasAddButton(),
      ),
      child: SafeArea(
        child: BlocBuilder<IdeasBloc, IdeasState>(
          builder: (context, state) {
            return state.map(
              initial: (_) => const CELoading(),
              loading: (_) => const CELoading(),
              loaded: (loaded) => IdeasTabletContent(
                ideas: loaded.ideas,
                selectedId: loaded.selectedId,
              ),
              error: (error) => ErrorView(
                message: error.message,
                onRetry: () => _onRetry(context),
              ),
            );
          },
        ),
      ),
    );
  }

  void _onRetry(BuildContext context) {
    context.read<IdeasBloc>().add(const IdeasEvent.loadRequested());
  }
}

/// Contenido del layout tablet con master-detail.
class IdeasTabletContent extends StatelessWidget {
  const IdeasTabletContent({
    super.key,
    required this.ideas,
    this.selectedId,
  });

  final List<IdeaModel> ideas;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Master (Lista)
        SizedBox(
          width: 320,
          child: IdeasMasterPanel(
            ideas: ideas,
            selectedId: selectedId,
          ),
        ),
        // Divider
        Container(
          width: 1,
          color: CupertinoColors.separator.resolveFrom(context),
        ),
        // Detail
        Expanded(
          child: selectedId != null
              ? IdeaDetailPanel(ideaId: selectedId!)
              : const IdeasNoSelectionView(),
        ),
      ],
    );
  }
}

/// Vista cuando no hay idea seleccionada.
class IdeasNoSelectionView extends StatelessWidget {
  const IdeasNoSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.lightbulb,
            size: 64,
            color: CupertinoColors.systemGrey.resolveFrom(context),
          ),
          const SizedBox(height: 16),
          Text(
            'Selecciona una idea',
            style: TextStyle(
              fontSize: 17,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }
}
```

### Desktop Layout Template

```dart
// lib/presentation/features/ideas/layouts/ideas_desktop_layout.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/ideas_bloc.dart';
import '../bloc/ideas_state.dart';
import '../widgets/ideas_sidebar.dart';
import '../widgets/ideas_content_area.dart';
import '../widgets/ideas_inspector_panel.dart';
import '../../../../shared/widgets/cupertino/ce_loading.dart';
import '../../../../shared/widgets/error_view.dart';

/// Layout de Ideas para desktop (Multi-panel).
///
/// Características:
/// - Sidebar persistente para filtros/categorías
/// - Área de contenido principal amplia
/// - Panel inspector opcional a la derecha
/// - Toolbar con acciones rápidas
class IdeasDesktopLayout extends StatelessWidget {
  const IdeasDesktopLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IdeasBloc, IdeasState>(
      builder: (context, state) {
        return state.map(
          initial: (_) => const CELoading(),
          loading: (_) => const CELoading(),
          loaded: (loaded) => IdeasDesktopContent(
            ideas: loaded.ideas,
            selectedId: loaded.selectedId,
            filter: loaded.filter,
          ),
          error: (error) => ErrorView(
            message: error.message,
            onRetry: () => _onRetry(context),
          ),
        );
      },
    );
  }

  void _onRetry(BuildContext context) {
    context.read<IdeasBloc>().add(const IdeasEvent.loadRequested());
  }
}

/// Contenido del layout desktop con multi-panel.
class IdeasDesktopContent extends StatelessWidget {
  const IdeasDesktopContent({
    super.key,
    required this.ideas,
    required this.filter,
    this.selectedId,
  });

  final List<IdeaModel> ideas;
  final IdeasFilter filter;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Sidebar (Filtros/Navegación)
        SizedBox(
          width: 240,
          child: IdeasSidebar(
            currentFilter: filter,
            onFilterChanged: (newFilter) {
              context.read<IdeasBloc>().add(
                IdeasEvent.filterChanged(filter: newFilter),
              );
            },
          ),
        ),
        // Divider
        Container(
          width: 1,
          color: CupertinoColors.separator.resolveFrom(context),
        ),
        // Content Area (Lista principal)
        Expanded(
          flex: 2,
          child: IdeasContentArea(
            ideas: ideas,
            selectedId: selectedId,
          ),
        ),
        // Inspector Panel (Detalle/Acciones)
        if (selectedId != null) ...[
          Container(
            width: 1,
            color: CupertinoColors.separator.resolveFrom(context),
          ),
          SizedBox(
            width: 320,
            child: IdeasInspectorPanel(ideaId: selectedId!),
          ),
        ],
      ],
    );
  }
}
```

---

## 🧭 Patrones de Navegación por Form Factor

### Mobile Navigation

```dart
/// AppShell para móvil con CupertinoTabScaffold.
class AppShellMobileLayout extends StatelessWidget {
  const AppShellMobileLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.house),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.lightbulb),
            label: 'Ideas',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.doc_text),
            label: 'Scripts',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.calendar),
            label: 'Calendario',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        return CupertinoTabView(
          builder: (context) {
            return switch (index) {
              0 => const DashboardPage(),
              1 => const IdeasPage(),
              2 => const ScriptsPage(),
              3 => const CalendarPage(),
              4 => const SettingsPage(),
              _ => const SizedBox.shrink(),
            };
          },
        );
      },
    );
  }
}
```

### Tablet Navigation

```dart
/// AppShell para tablet con tabs en toolbar.
class AppShellTabletLayout extends StatelessWidget {
  const AppShellTabletLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const AppTabletNavigationTabs(),
        trailing: const AppToolbarActions(),
      ),
      child: const AppTabletContent(),
    );
  }
}

/// Tabs de navegación para tablet.
class AppTabletNavigationTabs extends StatelessWidget {
  const AppTabletNavigationTabs({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoSegmentedControl<int>(
      children: const {
        0: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('Dashboard'),
        ),
        1: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('Ideas'),
        ),
        2: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('Scripts'),
        ),
        3: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('Calendario'),
        ),
      },
      groupValue: context.watch<AppShellBloc>().state.currentIndex,
      onValueChanged: (index) {
        context.read<AppShellBloc>().add(
          AppShellEvent.tabChanged(index: index),
        );
      },
    );
  }
}
```

### Desktop Navigation

```dart
/// AppShell para desktop con sidebar persistente.
class AppShellDesktopLayout extends StatelessWidget {
  const AppShellDesktopLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Sidebar persistente
        const AppDesktopSidebar(),
        // Divider
        Container(
          width: 1,
          color: CupertinoColors.separator.resolveFrom(context),
        ),
        // Content
        const Expanded(
          child: AppDesktopContent(),
        ),
      ],
    );
  }
}

/// Sidebar para desktop.
class AppDesktopSidebar extends StatelessWidget {
  const AppDesktopSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final currentIndex = context.watch<AppShellBloc>().state.currentIndex;

    return SizedBox(
      width: 220,
      child: ColoredBox(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            const SizedBox(height: 16),
            const AppLogo(),
            const SizedBox(height: 24),
            AppSidebarItem(
              icon: CupertinoIcons.house,
              label: 'Dashboard',
              isSelected: currentIndex == 0,
              onTap: () => _onTabChanged(context, 0),
            ),
            AppSidebarItem(
              icon: CupertinoIcons.lightbulb,
              label: 'Ideas',
              isSelected: currentIndex == 1,
              onTap: () => _onTabChanged(context, 1),
            ),
            AppSidebarItem(
              icon: CupertinoIcons.doc_text,
              label: 'Scripts',
              isSelected: currentIndex == 2,
              onTap: () => _onTabChanged(context, 2),
            ),
            AppSidebarItem(
              icon: CupertinoIcons.calendar,
              label: 'Calendario',
              isSelected: currentIndex == 3,
              onTap: () => _onTabChanged(context, 3),
            ),
            const Spacer(),
            AppSidebarItem(
              icon: CupertinoIcons.settings,
              label: 'Ajustes',
              isSelected: currentIndex == 4,
              onTap: () => _onTabChanged(context, 4),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _onTabChanged(BuildContext context, int index) {
    context.read<AppShellBloc>().add(
      AppShellEvent.tabChanged(index: index),
    );
  }
}

/// Item del sidebar.
class AppSidebarItem extends StatelessWidget {
  const AppSidebarItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? CupertinoColors.systemBlue.withOpacity(0.1)
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? CupertinoColors.systemBlue
                  : CupertinoColors.label.resolveFrom(context),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? CupertinoColors.systemBlue
                    : CupertinoColors.label.resolveFrom(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 🎨 Patrones de Layout

### Master-Detail (iPad/Desktop)

```dart
/// ✅ Widget separado para layout master-detail
class MasterDetailLayout extends StatelessWidget {
  const MasterDetailLayout({
    super.key,
    required this.masterChild,
    required this.detailChild,
    this.masterWidth = 320,
  });

  final Widget masterChild;
  final Widget detailChild;
  final double masterWidth;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: masterWidth,
          child: masterChild,
        ),
        Container(
          width: 1,
          color: CupertinoColors.separator.resolveFrom(context),
        ),
        Expanded(child: detailChild),
      ],
    );
  }
}
```

### Lista con Secciones

```dart
/// ✅ Widget separado para sección de lista
class ContentListSection extends StatelessWidget {
  const ContentListSection({
    super.key,
    required this.title,
    required this.items,
    this.onItemTap,
  });

  final String title;
  final List<ContentItem> items;
  final void Function(ContentItem)? onItemTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoListSection.insetGrouped(
      header: Text(title.toUpperCase()),
      children: items.map((item) => ContentListTile(
        item: item,
        onTap: () => onItemTap?.call(item),
      )).toList(),
    );
  }
}

/// ✅ Widget separado para cada tile
class ContentListTile extends StatelessWidget {
  const ContentListTile({
    super.key,
    required this.item,
    this.onTap,
  });

  final ContentItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoListTile(
      leading: ContentStatusIndicator(status: item.status),
      title: Text(item.title),
      subtitle: Text(item.subtitle),
      trailing: const CupertinoListTileChevron(),
      onTap: onTap,
    );
  }
}
```

### Card Grid

```dart
/// ✅ Widget separado para grid de cards
class ContentCardGrid extends StatelessWidget {
  const ContentCardGrid({
    super.key,
    required this.items,
    this.crossAxisCount = 2,
  });

  final List<ContentItem> items;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.2,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => ContentCard(item: items[index]),
          childCount: items.length,
        ),
      ),
    );
  }
}

/// ✅ Widget separado para cada card
class ContentCard extends StatelessWidget {
  const ContentCard({
    super.key,
    required this.item,
  });

  final ContentItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ContentCardContent(item: item),
    );
  }
}
```

---

## 🔄 Estados de UI

### Empty State

```dart
/// ✅ Widget separado para estado vacío
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: CupertinoColors.systemGrey,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 15,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              CupertinoButton.filled(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

### Loading State

```dart
/// ✅ Widget separado para estado de carga
class LoadingStateView extends StatelessWidget {
  const LoadingStateView({
    super.key,
    this.message,
  });

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CupertinoActivityIndicator(radius: 14),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
```

### Error State

```dart
/// ✅ Widget separado para estado de error
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_circle,
              size: 48,
              color: CupertinoColors.systemRed,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 15),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              CupertinoButton(
                onPressed: onRetry,
                child: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

---

## 🎭 Feedback Visual

### Status Indicators

```dart
/// ✅ Widget separado para indicador de estado
class StatusIndicator extends StatelessWidget {
  const StatusIndicator({
    super.key,
    required this.status,
    this.size = 12,
  });

  final ContentStatus status;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _colorForStatus(status),
        shape: BoxShape.circle,
      ),
    );
  }

  Color _colorForStatus(ContentStatus status) {
    return switch (status) {
      ContentStatus.idea => CupertinoColors.systemGrey,
      ContentStatus.scripted => CupertinoColors.systemBlue,
      ContentStatus.adapted => CupertinoColors.systemOrange,
      ContentStatus.ready => CupertinoColors.systemGreen,
      ContentStatus.published => CupertinoColors.systemPurple,
      ContentStatus.archived => CupertinoColors.systemGrey3,
    };
  }
}
```

### Progress Badge

```dart
/// ✅ Widget separado para badge de progreso
class ProgressBadge extends StatelessWidget {
  const ProgressBadge({
    super.key,
    required this.current,
    required this.total,
  });

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey5.resolveFrom(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$current/$total',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
        ),
      ),
    );
  }
}
```

---

## ✅ Checklist de Responsividad

### Antes de Implementar una Feature

```
Estructura
□ ¿Existe carpeta layouts/?
□ ¿Hay archivo {feature}_mobile_layout.dart?
□ ¿Hay archivo {feature}_tablet_layout.dart?
□ ¿Hay archivo {feature}_desktop_layout.dart?
□ ¿La page usa AppLayoutBuilder?
```

### Mobile Layout

```
□ ¿Usa CupertinoPageScaffold?
□ ¿Tiene NavigationBar con título?
□ ¿Contenido es full-width?
□ ¿Tiene Pull-to-refresh donde aplique?
□ ¿Respeta SafeArea?
□ ¿Bottom navigation si es tab principal?
```

### Tablet Layout

```
□ ¿Usa Master-Detail pattern?
□ ¿Lista tiene ancho fijo (300-400dp)?
□ ¿Detalle se expande?
□ ¿Hay estado "no seleccionado"?
□ ¿Aprovecha el espacio horizontal?
```

### Desktop Layout

```
□ ¿Tiene sidebar persistente?
□ ¿Área de contenido es amplia?
□ ¿Hay panel inspector opcional?
□ ¿Navegación lateral siempre visible?
□ ¿Soporta multi-panel si aplica?
```

---

## ✅ Checklist de UX General

```
Navegación
□ ¿Flujo de navegación claro?
□ ¿Back button siempre visible?
□ ¿Títulos descriptivos?
□ ¿Acciones principales accesibles?

Feedback
□ ¿Estados de carga visibles?
□ ¿Errores comunicados claramente?
□ ¿Confirmaciones de acciones?
□ ¿Pull-to-refresh donde aplique?

Contenido
□ ¿Jerarquía visual clara?
□ ¿Contenido prioritizado correctamente?
□ ¿Empty states informativos?
□ ¿Texto legible y conciso?

Código
□ ¿Widgets como clases separadas? (NO métodos)
□ ¿Nombres descriptivos?
□ ¿Parámetros documentados?
□ ¿Tests de widget?
```

---

## 📱 Features a Aplicar (Todas DEBEN usar AppLayoutBuilder)

### Existentes (actualizar)
- [ ] Auth
- [ ] App Shell

### Futuras (seguir patrón)
- [ ] Dashboard
- [ ] Ideas
- [ ] Scripts
- [ ] Adaptations
- [ ] Media
- [ ] Publications
- [ ] Settings

---

## 📌 Regla de Oro

> **Si algo se puede extraer a un widget separado, DEBE extraerse a un widget separado.**

Nunca usar `Widget _buildX()`. Siempre crear `class X extends StatelessWidget`.

> **TODOS los layouts (mobile, tablet, desktop) son OBLIGATORIOS** en AppLayoutBuilder.
