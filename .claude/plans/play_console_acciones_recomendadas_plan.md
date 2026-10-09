# Plan: 4 acciones recomendadas de Google Play Console (v1.0.45)

> Fecha: 2026-09-09
> Origen: Play Console → Acciones recomendadas sobre el build 45 (1.0.45)

## Avisos reportados por Play

1. "Es posible que la vista de extremo a extremo no funcione para todos los usuarios" (UX)
2. "Tu aplicación usa APIs o parámetros obsoletos para la vista de extremo a extremo" (UX)
3. "Mejora el rendimiento con la reducción de resolución de mapas de bits" (Memoria)
4. "Mejora la memoria y el rendimiento con la optimización de R8" (Memoria)

---

## 1 + 2 — Edge-to-edge

### Causa raíz

| Fichero | Problema |
|---|---|
| `android/app/src/main/res/values/styles.xml` | `statusBarColor`, `navigationBarColor`, `windowDrawsSystemBarBackgrounds` → deprecados y no-op en API 35+ |
| `.../values-v31/styles.xml` | idem |
| `.../values-night/styles.xml` | idem |
| `.../values-night-v31/styles.xml` | idem + `android:windowFullscreen=true` → **rompe edge-to-edge** solo en modo oscuro Android 12+ |
| `MainActivity.kt:15` | `WindowCompat.setDecorFitsSystemWindows(window, false)` deprecado y redundante (Flutter ya aplica `SystemUiMode.edgeToEdge`) |
| `lib/main.dart:41-44` | `SystemUiOverlayStyle` fija `Brightness.light` siempre → iconos de barra blancos e invisibles en tema claro |

`targetSdk = 36`, por lo que Play evalúa la app con las reglas de Android 15+.

### Acciones

- [x] Eliminar los 4 atributos deprecados de los 4 `styles.xml` (se conserva `windowBackground`, `forceDarkAllowed` y `windowLayoutInDisplayCutoutMode`, que siguen siendo válidos)
- [x] Eliminar `android:windowFullscreen` de `values-night-v31`
- [x] Vaciar `MainActivity.onCreate()` de la llamada deprecada
- [x] `main.dart`: dejar solo el estilo inicial del splash (dark) y envolver la app en `AnnotatedRegion` que deriva el brillo del tema activo
- [x] `app_theme.dart`: añadir `systemOverlayStyle` explícito a `AppBarTheme` en tema claro y oscuro

### Por qué es seguro quitar los atributos en API < 35

El engine de Flutter, al recibir `SystemUiMode.edgeToEdge`, aplica en runtime los flags de layout
(`LAYOUT_STABLE | LAYOUT_HIDE_NAVIGATION | LAYOUT_FULLSCREEN`) y transparenta las barras desde API 29.
No dependemos de los atributos de tema salvo durante los ~200 ms del splash.

---

## 3 — Reducción de resolución de mapas de bits

### Causa raíz
12 usos de `CachedNetworkImage` y 23 de `Image.asset` sin **ningún** `memCacheWidth` / `cacheWidth` /
`maxWidthDiskCache`. Las fotos se decodifican a resolución completa aunque se pinten en tarjetas de 160 px.

### Acción
Añadir `memCacheWidth` / `memCacheHeight` dimensionado al tamaño real de render en los `CachedNetworkImage`,
priorizando los que aparecen en listas y grids (mayor multiplicidad):

- `que_ver/widgets/place_card.dart`, `collection_card.dart` (grids)
- `admin/chat/widgets/conversation_preview_thumbnail.dart` (miniaturas de lista)
- `guest/chat/widgets/message_bubble.dart` (burbujas de chat)
- `alojamientos/screens/unit_detail_screen.dart`, `hotel_common_areas_screen.dart` (carruseles)

Los visores a pantalla completa (`chat_image_viewer`, `place_detail_screen` galería,
`checkin_detail_screen`, `normas_screen`) se dejan a resolución completa: ahí sí se necesita el detalle.

---

## 4 — R8 / tamaño del bundle

### Causa raíz
`isMinifyEnabled = true` ya estaba, pero falta `isShrinkResources`. R8 full mode ya es el
predeterminado en AGP 8.9. Además `abiFilters` incluye `x86_64` (solo útil para emuladores), lo que
infla el AAB de producción.

### Acciones
- [x] `isShrinkResources = true` en `buildTypes.release`
- [x] Quitar `x86_64` de `abiFilters` (el propio comentario del fichero ya lo pedía)

### ⚠️ Verificación obligatoria antes de subir
`shrinkResources` puede eliminar recursos referenciados solo por reflexión. Hay que compilar
`--release` y probar al menos: splash, notificaciones FCM, cámara de check-in y galería de imágenes.

---

## Validación final

```bash
dart fix --apply && dart analyze
flutter build appbundle --release
```
