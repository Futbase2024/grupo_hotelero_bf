# Plan: Arranque lento de la app (tiempo hasta primera pantalla)

> **Fecha**: 2026-07-27
> **Estado**: ✅ Fases 1, 2, 3 y 4 implementadas (2026-07-27). Fase 5 descartada. Pendiente de medición en dispositivo real.
> **Decisiones del owner**: suelo de splash = 600 ms · RLS fuera de alcance (queda en `performance_degradation_plan.md`)
> **Prioridad**: Alta
> **Origen**: "¿por qué tarda tanto en cargar la app al principio?"
> **Ámbito**: SOLO tiempo de arranque en cliente. La degradación progresiva del backend está en `performance_degradation_plan.md` (complementario, no solapa).

---

## 🔎 Diagnóstico (medido sobre el código, no supuesto)

El arranque en frío se compone de tres bloques que van **en serie**:

```
[Firebase] → [init secuencial: dotenv → Supabase → DI → FCM → AppUpdate] → [suelo fijo del splash 4s] → primera pantalla
```

### Causas por impacto

| # | Causa | Dónde | Coste estimado |
|---|-------|-------|----------------|
| **1** | **Suelo fijo de ~4 s en el splash** | `splash_screen.dart` L45 (2000 ms) + L101 (500 ms) + L105 `await reverse()` sobre controller de 1500 ms (L57) | **~4 s siempre**, aunque todo cargue en 300 ms |
| **2** | **FCM bloquea el arranque** | `main.dart` L123 `await fcmService.initialize()` → `fcm_service_io.dart` L36-73 | **0,5-3 s**, y **indefinido** la 1ª vez (diálogo de permisos del sistema bloquea hasta que el usuario responde). Incluye un `Future.delayed(2 s)` de retry si `getToken()` devuelve null (L104-113) |
| **3** | **AppUpdateService bloquea el arranque** | `main.dart` L133 → `app_update_service.dart` L50-80 | **~200-600 ms** (`PackageInfo` + query a `app_config`) |
| **4** | **3 queries inútiles en la home pública** | `app_router.dart` L189-193: la ruta `/` crea `AlojamientosBloc` con `AlojamientosStarted()`, pero `PublicHomeScreen` **nunca lo consume** (su único `context.read` es `LocaleCubit`, L560) | **~300-800 ms** de red compitiendo con el resto |
| **5** | **Token FCM guardado 2 veces en Supabase** | `fcm_service_io.dart` L112 (dentro de `_getToken`) y L56 (otra vez tras los listeners) | 1 escritura de red redundante |
| **6** | **Firebase antes de `runApp`** | `main.dart` L51 | ~200-500 ms antes del primer píxel |

### Lo que NO es el problema
- ❌ `configureDependencies()` (`injection.dart`) → todo `registerLazySingleton`, coste ~0.
- ❌ El `AlojamientosBloc` global de `main.dart` L177 → `BlocProvider` es **lazy** por defecto y nadie lo lee en el arranque, así que no dispara nada. **No tocar**: sí lo necesitan las rutas `alojamiento-detail` y `hotel-common-areas`, que no tienen provider propio.
- ❌ El caché de 30 min de `PropertiesRepositoryImpl` ya está bien hecho.

> **Suma teórica de recorte: ~3,5-5 s** sin quitar ninguna funcionalidad.

---

## 📅 Fases

Cada fase es independiente y revertible por commit. Todas pasan por `dart fix --apply && dart analyze`.

### FASE 1 — Recortar el suelo del splash 🟢 (mayor ganancia, riesgo nulo)

**Archivo**: `lib/shared/widgets/splash_screen.dart`

| Cambio | Antes | Después |
|--------|-------|---------|
| 1.1 `_minimumSplashDuration` (L45) | 2000 ms | **600 ms** (evita el parpadeo si la init es instantánea, sin castigar) |
| 1.2 Pausa de "Listo" (L101) | 500 ms | **eliminar** (el estado "Listo" apenas se percibe) |
| 1.3 Fade-out (L105) | `await reverse()` sobre controller de 1500 ms | **`AnimationController` con `reverseDuration: 300 ms`**, manteniendo los 1500 ms de entrada |

**Ganancia**: ~3,1 s. **Riesgo**: solo estético — hay que ver que la transición al primer frame no dé tirón.

---

### FASE 2 — Sacar del camino crítico lo que no hace falta para pintar 🟠 (2ª mayor ganancia, riesgo medio)

**Archivo**: `lib/main.dart` (`_initializeApp`, L85-151)

Se mantiene bloqueante lo imprescindible: `dotenv` → `SupabaseConfig.initialize()` → `configureDependencies()`.
Se lanzan **sin `await`** (fire-and-forget con `unawaited`) tras marcar `_isInitialized = true`:

- 2.1 `fcmService.initialize()` — nada de la primera pantalla depende del token FCM. Además así el **diálogo de permisos deja de bloquear el arranque** (se mostrará sobre la app ya pintada, que es además mejor UX: el usuario ve el contexto).
- 2.2 `AppUpdateService.instance.initialize()`.

**⚠️ Dependencia que hay que resolver antes de aplicar 2.2**:
`UpdateChecker` llama a `checkForUpdate()` ~100 ms después del primer frame (`update_dialog.dart` L242). `checkForUpdate()` **no hace red**: lee `_versionInfo`, que hoy está garantizado porque `initialize()` era `await`. Si lo movemos a background, devolvería `UpdateStatus.unknown` y **una actualización forzada dejaría de mostrarse**.

**Solución**: en `app_update_service.dart`, guardar el future de init y esperarlo dentro de `checkForUpdate()`:
```dart
Future<void>? _initFuture;

Future<void> initialize({...}) {
  return _initFuture ??= _doInitialize(iosAppStoreId: ..., androidPackageName: ...);
}

Future<UpdateStatus> checkForUpdate() async {
  await _initFuture;           // ← no bloquea el arranque, solo la comprobación
  if (_versionInfo == null || _currentVersion == null) return UpdateStatus.unknown;
  ...
}
```

**Ganancia**: 0,7 s en el mejor caso, **varios segundos** en el arranque con permisos pendientes.
**Riesgo**: el de arriba, cubierto. Verificar que el diálogo de update forzado sigue apareciendo.

---

### FASE 3 — Quitar las 3 queries que no mira nadie 🟢 (riesgo bajo)

**Archivo**: `lib/core/router/app_router.dart` (L188-195)

Eliminar el `BlocProvider<AlojamientosBloc>` que envuelve `PublicHomeScreen`, dejando:
```dart
GoRoute(
  path: AppRoutes.publicHome,
  name: 'public-home',
  builder: (context, state) => const PublicHomeScreen(),
),
```

**Verificación obligatoria antes de aplicar**: recorrer el árbol de `PublicHomeScreen` (952 líneas) confirmando que ningún widget hijo hace `context.read/watch<AlojamientosBloc>()`. El grep inicial dice que no, pero hay que confirmarlo también en los widgets que importa.

**Ganancia**: 3 queries menos en el arranque (`properties`, la vista `units_with_full_address` **completa sin filtro**, y `unit_photos` de portada), liberando ancho de banda para lo que sí se pinta.

> Nota aparte (no bloqueante): `units_with_full_address` se trae **entera** en `properties_repository_impl.dart` L58-62. Con el volumen actual (unidades ~decenas) da igual; si crece, conviene filtrar. Fuera del alcance de este plan.

---

### FASE 4 — Limpieza del init de FCM 🟢 (riesgo bajo)

**Archivo**: `lib/core/services/fcm_service/fcm_service_io.dart`

- 4.1 Eliminar la llamada duplicada a `_saveTokenToSupabase()`: se llama en L112 (dentro de `_getToken()`) y otra vez en L56. Dejar **solo la de L56**.
- 4.2 Revisar el retry de `Future.delayed(2 s)` en `_getToken()` (L106-110): una vez la fase 2 lo saca del camino crítico ya no penaliza el arranque, así que **se puede dejar tal cual**. Se documenta y no se toca.

---

### FASE 5 — (Opcional) Firebase en paralelo 🟠 (riesgo medio, ganancia menor)

**Archivo**: `lib/main.dart` L51

`Firebase.initializeApp()` se hace antes de `runApp()`. Se podría mover dentro del splash junto al resto, pero Crashlytics (L56-62) depende de que esté listo y perderíamos captura de errores muy tempranos.

**Recomendación: NO hacerlo.** Ganancia ~300 ms a cambio de un hueco de observabilidad en el arranque. Se deja documentado y descartado salvo que digas lo contrario.

---

## ✅ Verificación

**Medición antes/después** (misma condición: app cerrada del todo, red móvil, dispositivo real):
1. Añadir un `Stopwatch` temporal en `main()` y loguear el tiempo hasta el primer frame de `PublicHomeScreen`.
2. Medir 3 arranques en frío antes de tocar nada → baseline.
3. Medir tras cada fase.
4. Quitar el `Stopwatch` temporal al terminar.

**Checklist funcional tras las fases:**
- [ ] Splash se ve y transiciona sin tirón
- [ ] Permisos de notificación se piden correctamente en instalación limpia (Android 13+ e iOS)
- [ ] Llega una push de prueba tras el arranque (token guardado bien pese al cambio de 4.1)
- [ ] Diálogo de **actualización forzada** sigue apareciendo (subir `minimum_version` en `app_config` para probarlo)
- [ ] Home pública pinta igual
- [ ] Navegar a alojamientos / detalle de alojamiento / detalle de unidad / hotel sigue cargando datos
- [ ] `dart fix --apply && dart analyze` limpio

## ↩️ Rollback
Un commit por fase. `git revert` de la fase concreta.

---

## 🧭 Orden recomendado

1. **Medir baseline** (sin esto no sabemos si mejoramos)
2. **FASE 1** (splash) — la mayor ganancia con riesgo cero
3. **FASE 3** (queries inútiles) — aislada y simple
4. **FASE 2** (init en background) — la que requiere más cuidado, con el fix de `_initFuture`
5. **FASE 4** (limpieza FCM)
6. FASE 5 descartada salvo indicación contraria

---

## ❓ Decisiones pendientes

1. **Suelo del splash**: ¿600 ms te parece bien, o prefieres 0 ms (lo más rápido posible, con riesgo de parpadeo) o 1000 ms (más "marca")?
2. **Permisos de notificación al arrancar**: con la FASE 2 el diálogo del sistema aparecerá **sobre la app ya pintada** en vez de sobre el splash. ¿OK? (es lo habitual y suele mejorar la tasa de aceptación).
3. ¿Aplicamos también las fases del `performance_degradation_plan.md` (RLS)? Las queries del arranque también se benefician, pero es otro plan y otro riesgo.
</content>
</invoke>
