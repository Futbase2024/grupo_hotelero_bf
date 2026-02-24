# AmbuTrack Web - Design System

> **Sistema de diseño para AmbuTrack Web - Gestión de Ambulancias**

---

## Brand Identity

### Personalidad
**Profesional, confiable y eficiente.** AmbuTrack transmite seguridad, rapidez y compasión en la gestión de servicios médicos de emergencia.

### Valores
**Seguridad · Eficiencia · Compasión · Profesionalismo · Confianza**

### Tagline
> "Gestión integral de servicios médicos de emergencia"

### Tono de comunicación
- Claro y directo
- Profesional pero cercano
- Inspirador y motivador
- Habla como un coordinador médico que entiende las necesidades del equipo

---

## Color Palette

### Primary Colors

| Token | Hex | RGB | Usage |
|-------|-----|-----|-------|
| `primary` | #1E40AF | 30, 64, 175 | Azul médico - Color principal |
| `primaryLight` | #3B82F6 | 59, 130, 246 | Azul claro - Hover states |
| `primaryDark` | #1E3A8A | 30, 58, 138 | Azul oscuro - Active states |
| `primarySurface` | #F0F4FF | 240, 244, 255 | Fondo con tinte azul |

### Secondary Colors

| Token | Hex | RGB | Usage |
|-------|-----|-----|-------|
| `secondary` | #059669 | 5, 150, 105 | Verde médico - Salud y positividad |
| `secondaryLight` | #10B981 | 16, 185, 129 | Verde claro - Hover states |
| `secondaryDark` | #047857 | 4, 120, 87 | Verde oscuro - Active states |
| `secondarySurface` | #F0FDF4 | 240, 253, 244 | Fondo con tinte verde |

### Semantic Colors

| Token | Hex | Usage |
|-------|-----|-------|
| `success` | #10B981 | Confirmaciones, estados positivos |
| `warning` | #F59E0B | Advertencias, precaución |
| `error` | #EF4444 | Errores, estados negativos |
| `info` | #3B82F6 | Información general |

### Emergency Colors (AmbuTrack específico)

| Token | Hex | Usage |
|-------|-----|-------|
| `emergency` | #DC2626 | Rojo emergencia - Alertas críticas |
| `highPriority` | #EA580C | Naranja - Alta prioridad |
| `mediumPriority` | #D97706 | Amarillo oscuro - Media prioridad |
| `lowPriority` | #059669 | Verde - Baja prioridad |
| `inactive` | #6B7280 | Gris - Inactivo |

### Grayscale

| Token | Hex | Usage |
|-------|-----|-------|
| `gray50` | #F9FAFB | Fondo muy claro |
| `gray100` | #F3F4F6 | Fondo claro |
| `gray200` | #E5E7EB | Bordes sutiles |
| `gray300` | #D1D5DB | Bordes normales |
| `gray400` | #9CA3AF | Texto secundario |
| `gray500` | #6B7280 | Texto terciario |
| `gray600` | #4B5563 | Texto medio |
| `gray700` | #374151 | Texto oscuro |
| `gray800` | #1F2937 | Texto muy oscuro |
| `gray900` | #111827 | Texto principal |

### Badge Colors (Profesionales)

| Estado | Fondo | Texto | Borde |
|--------|-------|-------|-------|
| Disponible | #F0FDF4 | #166534 | #BBF7D0 |
| En servicio | #EFF6FF | #1E40AF | #BFDBFE |
| Mantenimiento | #FFFBEB | #92400E | #FDE68A |
| Inactivo | #F9FAFB | #4B5563 | #E5E7EB |

---

## Typography

### Font Family
**Primary:** Google Fonts - Inter (fallback: system-ui, sans-serif)

### Scale

| Name | Size | Weight | Line Height | Usage |
|------|------|--------|-------------|-------|
| `display` | 32px | 700 | 1.2 | Hero titles |
| `h1` | 24px | 600 | 1.3 | Page titles |
| `h2` | 20px | 600 | 1.3 | Section headers |
| `h3` | 18px | 600 | 1.4 | Card titles |
| `body` | 16px | 400 | 1.5 | Primary body text |
| `body-sm` | 14px | 400 | 1.5 | Secondary text |
| `caption` | 12px | 400 | 1.4 | Labels, hints |

### Weights
- **Regular:** 400 (body text)
- **Medium:** 500 (emphasis)
- **Semi-bold:** 600 (headings)
- **Bold:** 700 (display, CTAs)

---

## Spacing

### Base Unit: 4px

| Token | Value | Usage |
|-------|-------|-------|
| `space-xs` | 4px | Tight spacing, icons |
| `space-sm` | 8px | Component internal padding |
| `space-md` | 16px | Standard spacing |
| `space-lg` | 24px | Section spacing |
| `space-xl` | 32px | Page margins |
| `space-2xl` | 48px | Major sections |

---

## Border Radius

| Token | Value | Usage |
|-------|-------|-------|
| `radius-xs` | 4px | Small chips, badges |
| `radius-sm` | 8px | Inputs, small buttons |
| `radius-md` | 12px | Buttons, cards (mobile) |
| `radius-lg` | 16px | Large cards, dialogs |
| `radius-full` | 9999px | Pills, avatars |

---

## Shadows

### Material Design 3 Elevation

```dart
// Level 1 - Dropdowns, menus
BoxShadow(
  color: Colors.black.withValues(alpha: 0.2),
  blurRadius: 8,
  offset: const Offset(0, 2),
)

// Level 2 - Cards, raised buttons
BoxShadow(
  color: Colors.black.withValues(alpha: 0.3),
  blurRadius: 12,
  offset: const Offset(0, 4),
)

// Level 3 - Dialogs, bottom sheets
BoxShadow(
  color: Colors.black.withValues(alpha: 0.4),
  blurRadius: 16,
  offset: const Offset(0, 8),
)
```

---

## Breakpoints

| Name | Width | Layout |
|------|-------|--------|
| `mobile` | < 600px | Single column |
| `tablet` | 600-1023px | 2 columns |
| `desktop` | ≥1024px | 3+ columns |

---

## Component Tokens

### Buttons

| Variant | Background | Text | Border |
|---------|------------|------|--------|
| Primary | `AppColors.primary` | White | none |
| Secondary | `AppColors.secondary` | White | none |
| Danger | `AppColors.emergency` | White | none |
| Outline | Transparent | `AppColors.primary` | `AppColors.primary` |
| Ghost | Transparent | `AppColors.gray700` | none |

### Inputs

| State | Background | Border | Text |
|-------|------------|--------|------|
| Default | White | `AppColors.gray300` | `AppColors.gray900` |
| Focused | White | `AppColors.primary` | `AppColors.gray900` |
| Error | White | `AppColors.error` | `AppColors.error` |
| Disabled | `AppColors.gray50` | `AppColors.gray200` | `AppColors.gray400` |

### Cards

| Property | Value |
|----------|-------|
| Background | White |
| Border Radius | 12px |
| Padding | 16px |
| Shadow | Level 2 |

---

## Iconography

### Style
- Material Icons (filled style preferred)
- 24px default size
- Custom icons for AmbuTrack específico (ambulance, medical, etc.)

### Sizes

| Size | Pixels | Usage |
|------|--------|-------|
| `xs` | 16px | Inline, badges |
| `sm` | 20px | Buttons, inputs |
| `md` | 24px | Standard |
| `lg` | 32px | Empty states |
| `xl` | 48px | Hero, illustrations |

---

## Motion

### Durations

| Token | Value | Usage |
|-------|-------|-------|
| `fast` | 150ms | Micro-interactions |
| `normal` | 250ms | Standard transitions |
| `slow` | 350ms | Page transitions |

### Easing

- **Default:** ease-out
- **Enter:** ease-out
- **Exit:** ease-in

---

## Touch Targets

| Platform | Minimum Size |
|----------|--------------|
| Mobile | 44 × 44 pt |
| Tablet | 40 × 40 pt |
| Desktop | 36 × 36 px |

---

## Status Colors (AmbuTrack específico)

| Estado | Color | Token |
|--------|-------|-------|
| Disponible | Verde | `AppColors.success` |
| En servicio | Azul | `AppColors.primary` |
| Mantenimiento | Amarillo | `AppColors.warning` |
| Inactivo | Gris | `AppColors.inactive` |
| Emergencia | Rojo | `AppColors.emergency` |

---

## Components Reference

| Component | File | Description |
|-----------|------|-------------|
| AppDropdown | `lib/core/widgets/dropdowns/` | Dropdown simple (≤10 items) |
| AppSearchableDropdown | `lib/core/widgets/dropdowns/` | Dropdown con búsqueda (>10) |
| AppLoadingIndicator | `lib/core/widgets/loading/` | Indicador de carga |
| AppDataGridV5 | `lib/core/widgets/tables/` | Tabla con paginación |
| StatusBadge | `lib/core/widgets/badges/` | Badge de estado |
| CrudOperationHandler | `lib/core/widgets/handlers/` | Handler CRUD |
| ConfirmationDialog | `lib/core/widgets/dialogs/` | Diálogo de confirmación |
| ResultDialog | `lib/core/widgets/dialogs/` | Diálogo de resultado |

---

## Material Design 3 Guidelines

AmbuTrack sigue las [Material Design 3 Guidelines](https://m3.material.io/) con adaptaciones específicas para el sector de emergencias médicas.

### Key Principles:
- **Professional and clean** - UI clara y sin distracciones
- **Fast and responsive** - Interacciones rápidas para emergencias
- **Accessible** - Alto contraste para entornos con poca luz
- **Consistent** - Lenguaje visual coherente en toda la app

---

**Última actualización:** 2025-02-09
