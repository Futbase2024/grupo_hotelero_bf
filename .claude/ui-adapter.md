# UI Component Adapter

> Actualizado: 2026-01-18 (migrado a Material Design 3)
> Proyecto: futplanner_web

## Referencias

- **Design system**: `lib/core/theme/futplanner_material_theme.dart`
- **Widgets M3**: `lib/core/ui/widgets/`
- **Widgets compartidos**: `lib/core/ui/shared_widgets/`
- **Shell navegación**: `lib/core/widgets/coach_shell/`
- **Diseños Stitch**: `doc/design/` (prompts y HTML)
- **Design System Doc**: `.claude/design/DESIGN_SYSTEM.md`

---

## 1. Mapeo Stitch HTML → Flutter Material 3

### Estilo Visual FutPlanner

| Principio | Regla | Implementación |
|-----------|-------|----------------|
| Dark mode primario | El usuario usa la app de noche | `Theme.of(context).brightness` |
| Verde FutPlanner | Color primario #10B981 | `colorScheme.primary` |
| Material 3 | Widgets Material nativos | `FilledButton`, `TextField`, `Card`, etc. |
| Sombras sutiles | Usar elevation de M3 | `Card` con `elevation: 0-2` |
| Espaciado generoso | Mínimo 16px en contenedores | `EdgeInsets.all(16)` |
| Responsive | 3 layouts separados | `AppLayoutBuilder(mobile:, tablet:, desktop:)` |

### Paleta de Colores (Stitch → Flutter M3)

```dart
// PRIMARIOS (Verde FutPlanner)
#10B981 (light) → Theme.of(context).colorScheme.primary
#34D399 (dark)  → Theme.of(context).colorScheme.primary
#ECFDF5 (bg)    → Theme.of(context).colorScheme.primaryContainer

// FONDOS
#FFFFFF → colorScheme.surface
#FAFAFA → colorScheme.surfaceContainerHighest
#1A1A1A → Colors.black
#2D2D2D → colorScheme.surfaceContainerLow (dark)

// TEXTO
#FFFFFF → colorScheme.onSurface
#9CA3AF → colorScheme.onSurfaceVariant
#6B7280 → colorScheme.outline

// SEMÁNTICOS
#10B981 (success) → colorScheme.tertiary / Colors.green
#F59E0B (warning) → Colors.orange
#EF4444 (error)   → colorScheme.error
#3B82F6 (info)    → Colors.blue

// BORDES
#E5E5E5 → colorScheme.outlineVariant
```

### Espaciado (Tailwind → Flutter)

| Tailwind | Flutter | Valor |
|----------|---------|-------|
| `p-1` | `EdgeInsets.all(4)` | 4dp |
| `p-2` | `EdgeInsets.all(8)` | 8dp |
| `p-3` | `EdgeInsets.all(12)` | 12dp |
| `p-4` | `EdgeInsets.all(16)` | 16dp |
| `p-5` | `EdgeInsets.all(20)` | 20dp |
| `p-6` | `EdgeInsets.all(24)` | 24dp |
| `p-8` | `EdgeInsets.all(32)` | 32dp |
| `gap-*` | `SizedBox(height/width: *)` | Mismo valor |

### Border Radius (Tailwind → Flutter)

| Tailwind | Flutter | Valor |
|----------|---------|-------|
| `rounded-sm` | `BorderRadius.circular(4)` | 4px |
| `rounded` | `BorderRadius.circular(6)` | 6px |
| `rounded-md` | `BorderRadius.circular(10)` | 10px |
| `rounded-lg` | `BorderRadius.circular(10)` | 10px |
| `rounded-xl` | `BorderRadius.circular(16)` | 16px |
| `rounded-2xl` | `BorderRadius.circular(24)` | 24px |
| `rounded-full` | `BorderRadius.circular(9999)` | Pill |

### Tipografía (Tailwind → Flutter TextTheme)

| Tailwind | Flutter | TextTheme |
|----------|---------|-----------|
| `text-xs` | `fontSize: 10` | `labelSmall` |
| `text-sm` | `fontSize: 12` | `bodySmall` |
| `text-base` | `fontSize: 14` | `bodyMedium` |
| `text-lg` | `fontSize: 16` | `bodyLarge` |
| `text-xl` | `fontSize: 18` | `titleMedium` |
| `text-2xl` | `fontSize: 20` | `titleLarge` |
| `text-3xl` | `fontSize: 24` | `headlineSmall` |
| `text-4xl` | `fontSize: 32` | `headlineMedium` |
| `font-normal` | `FontWeight.w400` | |
| `font-medium` | `FontWeight.w500` | |
| `font-semibold` | `FontWeight.w600` | |
| `font-bold` | `FontWeight.w700` | |

### Componentes HTML → Flutter Material 3

| HTML/Tailwind | Flutter Widget | Notas |
|---------------|----------------|-------|
| `<div class="flex">` | `Row` / `Column` | Según dirección |
| `<div class="grid">` | `GridView` / `Wrap` | |
| `<button>` primario | `FilledButton` | Botón relleno |
| `<button>` secundario | `TextButton` | Solo texto |
| `<button>` outline | `OutlinedButton` | Con borde |
| `<input>` | `TextField` | Con `InputDecoration` |
| `<select>` | `DropdownMenu` / `showModalBottomSheet` | |
| `<textarea>` | `TextField(maxLines: 5)` | |
| `<span class="material-symbols-*">` | `Icon(Icons.*)` | |
| Card con border | `Card` con `shape: RoundedRectangleBorder` | |
| Card con shadow | `Card` con `elevation: 1-2` | |
| Loading spinner | `CircularProgressIndicator` | |
| Toggle/Switch | `Switch` | |
| Alert dialog | `AlertDialog` | Via `showDialog()` |
| Action sheet | `showModalBottomSheet` + `ListTile` | |

### Iconos (Material Symbols → Flutter)

| Material Symbol | Flutter Icon |
|-----------------|--------------|
| `sports_soccer` | `Icons.sports_soccer` |
| `calendar_today` | `Icons.calendar_today` |
| `location_on` | `Icons.location_on` |
| `people` | `Icons.people_outline` |
| `fitness_center` | `Icons.fitness_center` |
| `emoji_events` | `Icons.emoji_events` |
| `add` | `Icons.add` |
| `arrow_forward` | `Icons.arrow_forward_ios` |
| `chevron_right` | `Icons.chevron_right` |
| `edit` | `Icons.edit` |
| `delete` | `Icons.delete` |
| `search` | `Icons.search` |
| `settings` | `Icons.settings` |
| `close` | `Icons.close` |

> Nota: `CupertinoIcons` también disponibles con import selectivo

---

## 2. Design Tokens

```dart
// Ver: lib/core/theme/futplanner_material_theme.dart
// Framework: Material Design 3
```

---

## Mapeo: Componente → Widget

| Componente | Widget | Ubicación | Estado |
|------------|--------|-----------|--------|
| **NAVIGATION** |
| Bottom Navigation | `CoachBottomNavBar` | `core/widgets/coach_shell/` | ✅ |
| Side Panel | `CoachSidePanel` | `core/widgets/coach_shell/` | ✅ |
| Shell/Scaffold | `CoachShell` | `core/widgets/coach_shell/` | ✅ |
| Navbar (Landing) | `HomeNavbar` | `features/home/presentation/widgets/navbar/` | ✅ |
| Footer (Landing) | `HomeFooter` | `features/home/presentation/widgets/footer/` | ✅ |
| **DATA DISPLAY** |
| Card | `FMCard` | `core/ui/widgets/` | ✅ |
| Bento Card | `BentoCard` | `core/ui/shared_widgets/` | ✅ |
| Feature Card | `BentoFeatureCard` | `core/ui/shared_widgets/` | ✅ |
| Pricing Card | `BentoPricingCard` | `core/ui/shared_widgets/` | ✅ |
| Player Card | `FMPlayerCard` | `core/ui/widgets/` | ✅ |
| Player Avatar | `PlayerAvatar` | `core/ui/shared_widgets/` | ✅ |
| Stats Indicator | `StatsIndicator` | `core/ui/shared_widgets/` | ✅ |
| Status Badge | `StatusBadge` | `core/ui/shared_widgets/` | ✅ |
| Chip | `FMChip` | `core/ui/widgets/` | ✅ |
| Expansion Tile | `FMExpansionTile` | `core/ui/widgets/` | ✅ |
| **SELECTION** |
| Chip (selectable) | `FMChip` / `FilterChip` | `core/ui/widgets/` | ✅ |
| Language Selector | `LanguageSelector` | `features/app_config/presentation/widgets/` | ✅ |
| Theme Selector | `ThemeModeSelector` | `features/app_config/presentation/widgets/` | ✅ |
| **DATA ENTRY** |
| Form Field | `FMFormField` | `core/ui/widgets/` | ✅ |
| Contact Form | `ContactForm` | `features/home/features/contact/presentation/widgets/` | ✅ |
| **FEEDBACK** |
| Confirmation Dialog | `FMConfirmationDialog` | `core/ui/widgets/` | ✅ |
| Empty State | `FMEmptyState` | `core/ui/widgets/` | ✅ |
| Error State | `FMErrorState` | `core/ui/widgets/` | ✅ |
| Loading State | `FMLoadingState` | `core/ui/widgets/` | ✅ |
| Loading Overlay | `LoadingOverlay` | `core/ui/shared_widgets/` | ✅ |
| Player Stats Popup | `PlayerStatsPopup` | `core/ui/shared_widgets/` | ✅ |
| Notification Overlay | `NotificationOverlay` | `core/notifications/` | ✅ |
| **CONTEXT MENUS** |
| Player Context Menu | `PlayerContextMenu` | `core/ui/shared_widgets/` | ✅ |
| Activity Context Menu | `ActivityContextMenu` | `core/ui/shared_widgets/` | ✅ |
| **LAYOUT** |
| Layout Builder | `AppLayoutBuilder` | `core/ui/` | ✅ |
| Feature Gate | `FeatureGate` | `core/ui/shared_widgets/` | ✅ |

---

## Convenciones

- **Prefijo**: `FM` para widgets custom de FutPlanner
- **Estructura**: Por tipo (`widgets/`, `shared_widgets/`)
- **Nomenclatura**: `snake_case` para archivos, `PascalCase` para clases
- **Framework**: **Material Design 3**
- **Layouts**: Usar `AppLayoutBuilder` con 3 layouts separados

---

## Barrel Files

```dart
// lib/core/ui/widgets/widgets.dart
export 'fm_card.dart';
export 'fm_chip.dart';
export 'fm_confirmation_dialog.dart';
export 'fm_empty_state.dart';
export 'fm_error_state.dart';
export 'fm_expansion_tile.dart';
export 'fm_form_field.dart';
export 'fm_loading_state.dart';
export 'fm_player_card.dart';

// lib/core/ui/shared_widgets/shared_widgets.dart
export 'activity_context_menu.dart';
export 'bento_card.dart';
export 'bento_feature_card.dart';
export 'bento_pricing_card.dart';
export 'confirmation_dialog.dart';
export 'feature_gate.dart';
export 'floating_quick_actions_bar.dart';
export 'loading_overlay.dart';
export 'player_avatar.dart';
export 'player_card.dart';
export 'player_context_menu.dart';
export 'player_stats_popup.dart';
export 'quick_action_item.dart';
export 'stats_indicator.dart';
export 'status_badge.dart';
```

---

## Uso

Cuando `/plan` analiza un PRD:

1. Consulta este adapter para saber:
   - ¿Existe ya? → Reutilizar
   - ¿No existe? → Crear tarea en el plan
2. Usa los design tokens de `futplanner_material_theme.dart`
3. Aplica colores via `Theme.of(context).colorScheme`

---

> ⚠️ **Mantener actualizado**: Ejecutar `/adapt-ui` después de crear nuevos widgets core.
