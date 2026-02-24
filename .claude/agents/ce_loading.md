# CELoading - Widget de Loading Profesional con Temática de Fútbol

> **Ubicación**: `lib/shared/widgets/ce_loading.dart`
> **Exportado en**: `lib/shared/widgets/shared_widgets.dart`

---

## 🎯 Propósito

Widget de loading profesional con temática de fútbol base para FutBase 3.0. Reemplaza a `CircularProgressIndicator` en toda la aplicación para mantener una identidad visual coherente.

---

## ⚠️ REGLA CRÍTICA

**SIEMPRE usar `CELoading` en lugar de `CircularProgressIndicator`**

### ❌ PROHIBIDO
```dart
const CircularProgressIndicator()
const Center(child: CircularProgressIndicator())
CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
```

### ✅ OBLIGATORIO
```dart
import 'package:futbase/shared/widgets/shared_widgets.dart';

const CELoading.inline()
const CELoading.fullscreen(message: 'Cargando...')
const CELoading.button()
```

---

## 📋 Variantes Disponibles

### 1. CELoading.fullscreen()
**Uso**: Splash screens, carga inicial de la aplicación, pantallas de autenticación

```dart
// Sin mensaje
const CELoading.fullscreen()

// Con mensaje
const CELoading.fullscreen(message: 'Iniciando sesión...')

// Con tamaño y color personalizados
const CELoading.fullscreen(
  message: 'Cargando datos...',
  size: 80,
  color: AppColors.primary,
)
```

**Características**:
- Fondo oscuro (`AppColors.backgroundDark`)
- Balón grande (64px por defecto)
- Color accent por defecto
- Mensaje opcional en blanco

---

### 2. CELoading.inline()
**Uso**: Estados de carga en páginas, listas, contenido dentro de widgets

```dart
// Básico
const CELoading.inline()

// Con mensaje
const CELoading.inline(message: 'Cargando jugadores...')

// Personalizado
const CELoading.inline(
  message: 'Sincronizando...',
  size: 40,
  color: AppColors.primary,
)
```

**Características**:
- Centrado en su contenedor
- Balón mediano (32px por defecto)
- Color primary por defecto
- Mensaje opcional en gris

---

### 3. CELoading.button()
**Uso**: Dentro de botones mientras procesan acciones

```dart
// En botón
CEButton(
  isLoading: true,
  onPressed: () {},
  child: const CELoading.button(),
)

// Con color personalizado
const CELoading.button(color: AppColors.white)
```

**Características**:
- Tamaño compacto (20px por defecto)
- Color blanco por defecto
- Sin mensaje

---

### 4. CELoading.overlay()
**Uso**: Modales, diálogos de espera, operaciones bloqueantes

```dart
// Básico
const CELoading.overlay()

// Con mensaje
const CELoading.overlay(message: 'Guardando cambios...')

// Personalizado
const CELoading.overlay(
  message: 'Procesando pago...',
  size: 56,
  color: AppColors.accent,
)
```

**Características**:
- Overlay semitransparente oscuro
- Tarjeta con fondo `AppColors.cardDark`
- Balón grande (48px por defecto)
- Color accent por defecto
- Mensaje opcional en blanco

---

## 🔧 Uso en BLoC Builder

```dart
BlocBuilder<PlayersBloc, PlayersState>(
  builder: (context, state) {
    return state.when(
      initial: () => const CELoading.inline(),
      loading: () => const CELoading.inline(message: 'Cargando jugadores...'),
      loaded: (players) => PlayersList(players: players),
      error: (message) => ErrorView(message: message),
    );
  },
)
```

---

## 🎨 Personalización

### Parámetros comunes

| Parámetro | Tipo | Por defecto | Descripción |
|-----------|------|-------------|-------------|
| `message` | `String?` | `null` | Mensaje opcional bajo el balón |
| `size` | `double?` | Ver variantes | Tamaño del balón en píxeles |
| `color` | `Color?` | Ver variantes | Color principal del balón |

### Colores recomendados

```dart
// Para fondos oscuros
color: AppColors.accent      // Verde neón (default para fullscreen/overlay)
color: AppColors.white       // Para botones

// Para fondos claros
color: AppColors.primary     // Verde oscuro (default para inline)
color: AppColors.primaryLight
```

---

## 📐 Tamaños por Defecto

| Variante | Tamaño | Constante AppSpacing |
|----------|--------|---------------------|
| `.fullscreen` | 64px | `iconXxl` |
| `.inline` | 32px | `iconLg` |
| `.button` | 20px | `iconSm` |
| `.overlay` | 48px | `iconXl` |

---

## ⚽ Diseño del Balón

El widget dibuja un balón de fútbol estilizado con:

1. **Círculo principal**: Gradiente radial con el color especificado
2. **Patrón de pentágonos**: 1 central + 5 exteriores (patrón clásico de balón)
3. **Líneas de conexión**: Entre pentágonos central y exteriores
4. **Efecto de brillo**: Gradiente radial para dar profundidad
5. **Borde sutil**: Línea blanca semitransparente

### Animación
- **Duración**: 1500ms por rotación completa
- **Tipo**: Rotación continua infinita
- **Curva**: Lineal

---

## 📦 Importación

```dart
// Importación directa
import 'package:futbase/shared/widgets/ce_loading.dart';

// Importación via barrel (recomendado)
import 'package:futbase/shared/widgets/shared_widgets.dart';
```

---

## ✅ Checklist de Uso

- [ ] Importar `shared_widgets.dart`
- [ ] Elegir la variante correcta según el contexto
- [ ] NO usar `CircularProgressIndicator`
- [ ] Considerar añadir mensaje para mejor UX
- [ ] Usar colores de `AppColors`, nunca hardcodear
