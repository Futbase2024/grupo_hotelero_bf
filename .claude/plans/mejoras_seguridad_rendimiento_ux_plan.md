# Plan: Seguridad, rendimiento y UX (BF Stay)

> **Fecha**: 2026-09-09
> **Estado**: ✅ Ejecutado (2026-09-09). Ver "Resultado" al final.
> **Origen**: auditoría a raíz del bug "los check-ins validados no aparecían en la lista"
> **Autorización**: "dale a todo" (owner) — alcance = los 5 puntos de la lista de recomendación

---

## 🔎 Contexto

El bug original (check-ins validados que desaparecían) resultó ser el corte de 1000 filas de
PostgREST (`db-max-rows`) sobre una consulta sin paginar. Al auditar el resto del proyecto
aparecieron más sitios con el mismo patrón y, de camino, un problema de seguridad en el RLS
de `bookings`.

### Ya resuelto antes de este plan

| Sitio | Arreglo |
|---|---|
| `listBookings` (reservas, check-ins, facturas, ocupación) | Paginación con `range()` sin tope + orden servidor descendente |
| Lista de conversaciones del chat | Vista `conversation_last_messages` (187 filas en vez de 1192) |
| Participantes e info de reservas del chat | Paginación con `_fetchAllPages` |

### Estado del `performance_degradation_plan.md` (2026-07-10)

Verificado hoy: el bloat **ya no es un problema** (`net._http_response` 59 MB → 2,6 MB;
`cron.job_run_details` 51.929 → 4.139 filas). Los `auth_rls_initplan` (73) y las FK sin
índice (14) también desaparecieron. **Sigue pendiente su causa #1**: políticas RLS
duplicadas, que han pasado de 167 a 182 avisos.

---

## FASE 1 — 🔴 Fuga de datos en `bookings`

### Diagnóstico

`bookings` tiene 4 políticas SELECT permisivas (se combinan con OR). Una de ellas:

```sql
-- bookings_anon_select_by_code, rol {public} = TODOS los roles
USING (status = ANY (ARRAY['confirmed', 'checked_in']))
```

No comprueba ningún código pese a su nombre. Como los invitados entran con
`signInAnonymously()`, **cualquiera que abra la app puede leer todas las reservas activas**.

Verificado ejecutando como rol `authenticated` sin JWT: **26 reservas visibles**, las 26 con
`keybox_code` (código de la caja de llaves), 26 con email y 10 con teléfono del huésped.

### Por qué existe

El flujo de login por código necesita leer la reserva **antes** de que exista vínculo entre
usuario y reserva:

1. `loginWithBookingCode(code)` — busca por `booking_code` + status válido.
2. `loginWithBookingCodeAndEmail(code, email)` — además valida email y hace
   `UPDATE bookings SET primary_guest_user_id = <uid>`.

Ese UPDATE está condenado a no afectar ninguna fila: la política de UPDATE
(`bookings_guest_update_own_simple`) exige `primary_guest_user_id = auth.uid()`, que es
justo lo que se intenta establecer. Coherente con que `code_first_used_at` esté a NULL en
las 1061 reservas.

### Verificación de que se puede cerrar

```sql
begin;
drop policy "bookings_anon_select_by_code" on public.bookings;
set local role authenticated;
set local request.jwt.claims = '{"sub":"<uid de un huésped real>","role":"authenticated"}';
select count(*) from bookings;  -- → 1 (solo la suya) ✅
rollback;
```

Un huésped ya vinculado sigue viendo su reserva por `bookings_guest_select_own`. Solo hay
que cubrir el momento del login.

### Trabajo

1. **RPC `claim_booking_by_code(p_code, p_email)`** — `SECURITY DEFINER`, `search_path`
   fijo, con el patrón de guard del blindaje de julio. Valida código, estado, caducidad y
   email en el servidor; vincula `primary_guest_user_id = auth.uid()`; devuelve solo los
   campos que la app necesita (**sin `keybox_code`**).
2. **Cliente**: `loginWithBookingCode` y `loginWithBookingCodeAndEmail` pasan a llamar al
   RPC en lugar de consultar la tabla.
3. **Eliminar políticas**: `bookings_anon_select_by_code` (la fuga),
   `guest_select_own_booking` (duplicado exacto de `bookings_guest_select_own`) y
   `bookings_staff_select_property` (ya cubierta por `bookings_staff_manage_property`, que
   es `FOR ALL`).

### ⚠️ Orden de despliegue

Dos migraciones separadas, porque la app publicada hoy depende de la política abierta:

- **1A** (aplicable ya): crear el RPC. No rompe nada.
- **1B** (aplicar SOLO tras publicar la app nueva): eliminar las 3 políticas.

---

## FASE 2 — 🟠 Consolidar políticas RLS duplicadas

182 avisos `multiple_permissive_policies` en 23 tablas. Cada política permisiva extra se
evalúa **en cada fila de cada consulta**.

| Tabla | Avisos | Filas |
|---|---|---|
| `booking_guests`, `guest_documents`, `guests`, `profiles`, `fcm_tokens` | 15 c/u | 900–2.500 |
| `bookings`, `checkins`, `extra_requests`, `incidents`, `user_roles` | 10 c/u | 1.061 y menores |
| 13 tablas más | 1–5 c/u | pequeñas |

**Método**: las políticas permisivas se combinan con OR, así que fusionar N políticas del
mismo `cmd` y mismos roles en una sola con las expresiones unidas por OR es **equivalente
por construcción**. Solo se fusionan políticas con idéntico conjunto de roles.

**Verificación obligatoria por tabla**: antes/después, contar filas visibles para
(a) staff, (b) huésped vinculado, (c) usuario anónimo sin vínculo. Los tres números deben
ser idénticos.

Empezar por las tablas grandes (`guest_documents`, `guests`, `booking_guests`, `bookings`,
`checkins`) y bajar. Cada tabla, su migración con `.ROLLBACK.sql`.

Además: **47 índices sin uso** (invoices, marketing_campaigns, reviews, conversations...)
penalizan cada escritura → eliminar en una migración aparte.

---

## FASE 3 — 🎨 Rediseño del tab de check-ins

Archivo: `lib/features/admin/dashboard/presentation/widgets/checkins_tab.dart` (1382 líneas).

| Problema | Arreglo |
|---|---|
| Cabecera dorada sólida en las 1026 tarjetas → muro amarillo donde nada destaca | Dorado reservado a lo accionable ("Por revisar"); validados en tarjeta neutra con acento verde |
| Badge verde sobre dorado (peor combinación para daltonismo) | Fondo neutro + icono + punto de color |
| Lista plana de 1026 elementos | Encabezados sticky por día (Hoy · Ayer · 06/09) |
| Contador "1026" sin contexto | "1026 validados" |
| `AppColors.white` / `darkSurface` fijos → texto invisible en tema claro | `getTextPrimaryColor(context)` / `getCardColor(context)` |
| 34 textos hardcodeados en español (vs 3 `S.of(context)`) en app con 7 idiomas | Mover a `.arb` |
| `CircularProgressIndicator` ×3 | `CELoading` |
| `showSnackBar` en acciones destructivas | `CeInfoDialog` |
| 4 colores hardcodeados `Color(0xFF...)` | `AppColors` |
| Métodos `_buildX()` que devuelven Widget | Widgets como clases |

---

## FASE 4 — 🟡 Rendimiento del cliente

1. **Realtime incremental**: hoy cada cambio en `checkins` recarga las 1026 filas
   (`admin_dashboard_bloc.dart`, `_subscribeToCheckins`). Actualizar solo la fila afectada.
2. **Tipar la lista**: `_CheckinListTile` recibe `dynamic` → `AdminBookingEntity`
   (dispatch dinámico en cada `build` + cero comprobación en compilación).
3. **Cachear `units` y `properties`**: 14 y 7 filas casi inmutables, consultadas en cada
   `listBookings`.

---

## FASE 5 — 📜 Scroll infinito en check-ins y reservas

**Requisito previo**: mover el filtro de fechas y el orden al servidor. Hoy
`_computeFilteredCheckins` filtra en memoria; con carga parcial la búsqueda daría falsos
"sin resultados".

Después: primera página de ~100 y cargar más al llegar al final de la lista.

---

## Reglas de ejecución

- Cada cambio SQL va en `supabase/migrations/` con su `.ROLLBACK.sql`.
- Nada de RLS se da por bueno sin la verificación de 3 roles descrita en la Fase 2.
- `dart fix --apply && dart analyze` tras cada archivo `.dart` tocado.
- La Fase 1B se aplica **después** de publicar la app; el resto es independiente.

---

## ✅ Resultado (2026-09-09)

### Aplicado en Supabase

| Migración | Estado |
|---|---|
| `20260909120000_conversation_last_messages_view` | ✅ Aplicada |
| `20260909130000_claim_booking_by_code_rpc` | ✅ Aplicada (+ fix de columnas) |
| `20260909150000_rls_drop_duplicate_policies` | ✅ Aplicada |
| `20260909160000_rls_fix_profiles_policies` | ✅ Aplicada |
| `20260909170000_rls_consolidate_staff_guest_policies` | ✅ Aplicada |
| `20260909140000_close_bookings_select_leak` | ⏸️ **PENDIENTE — aplicar tras publicar la app** |

Verificación de accesos tras consolidar RLS (idénticos antes y después):

| perfil | checkins | guest_documents | booking_guests | guests |
|---|---|---|---|---|
| admin | 1061 | 2483 | 1849 | 1886 |
| huésped vinculado | 1 | 4 | 2 | 2 |
| usuario sin vínculo | 0 | 0 | 0 | 0 |

### Cambios en la app

- `auth_repository_impl.dart` — login por código vía RPC (`_claimBooking`, `_ensureAnonymousSession`)
- `admin_panel_repository_impl.dart` — paginación sin tope, caché de catálogos, `bookingIds`, `limit`, Realtime con ids
- `admin_dashboard_bloc.dart` — refresco incremental + primera pantalla rápida (100 filas)
- `chat_datasource.dart` — vista de últimos mensajes + `_fetchAllPages`
- `checkins_tab.dart` + 6 widgets nuevos en `widgets/checkins/`

`dart analyze`: sin errores ni warnings nuevos. `flutter test`: 30/30 (2 tests nuevos).

### Hallazgos extra encontrados por el camino

1. **`profiles` tenía las políticas rotas**: comparaban el email contra `auth.users`,
   tabla sin permisos para `authenticated` → `ERROR: permission denied for table users`.
   No se notaba porque la app no consulta `profiles` directamente. Arreglado con `auth.jwt()`.
2. **`profiles_insert_all`** permitía a cualquier autenticado crear perfiles con el
   `user_id` de otro. Eliminada.
3. **`code_expires_at` no existe** en `bookings`, pero el login con email la pedía:
   ese flujo devolvía error de PostgREST. Ya no se usa esa columna.
4. **`fcm_tokens`** deja ver los tokens de los admins a cualquier usuario. Es la
   consecuencia de enviar FCM desde el cliente → sigue pendiente la "Migración 5"
   ya documentada (mover el envío a edge/service_role).

### Decisiones tomadas y NO ejecutadas (con motivo)

- **47 índices sin uso**: medido → suman 1,1 MB y la tabla con más escrituras recibe
  ~19/día. El beneficio es despreciable y quitarlos solo añade riesgo. **Descartado.**
- **i18n del tab de check-ins** (34 textos): el panel es interno y en español; serían
  ~238 traducciones en 7 idiomas. **Pendiente si se decide abrir el panel a más idiomas.**
- **`CELoading` / `CeInfoDialog`**: no existen en este proyecto (son reglas de FutBase).
  **No aplica.**
- **Scroll infinito puro**: en su lugar se hizo carga progresiva (bloque de 100 + resto
  de fondo). Motivo: el scroll infinito exige mover *todos* los filtros al servidor;
  con carga parcial, buscar "Marta" diría "sin resultados" si no está en las primeras
  100. La carga progresiva da la misma sensación de rapidez sin romper búsqueda ni
  filtros. Coste: una petición extra en la primera carga. Revisar cuando se superen
  las ~5000 reservas.
