# Plan: que el servidor no entregue códigos de acceso antes de tiempo (punto C)

> Fecha: 2026-10-20 · Rama: `feature/novedades` · Proyecto Supabase: `qwepisgdqlmqfxwqkztz`

## Problema

Hoy las pantallas del huésped solo ocultan los códigos según la hora (14:00 del día de entrada o
`early_checkin_available_at`). El servidor los entrega por otras vías aunque no haya check-in validado:

| # | Secreto | Vía | Quién puede leerlo hoy |
|---|---------|-----|------------------------|
| 1 | `properties.main_door_keycode` (portal) | RLS `Allow public read access` (`true`) | **Cualquiera, sin sesión** (6 de 7 propiedades lo tienen) |
| 2 | `bookings.keybox_code`, `wifi_password`, json `units` con `box_code`/`access_instructions` | vista `admin_bookings_dashboard` (`security_invoker=on`) → `getBooking` | Huésped con reserva reclamada |
| 3 | `units.box_code`, `wifi_password`, `access_instructions`, `box_location_text` | RLS `units_guest_select_active_stay` (tabla cruda) → embeds de `getBooking` (`booking_units→units`) y `getAccessBox` | Huésped con reserva reclamada |
| 4 | `bookings.keybox_code` | RLS `bookings_guest_select_own` → `getAccessBox` y cualquier select directo | Huésped con reserva reclamada |

Lo único protegido de verdad es la vista `units_with_full_address` (enmascara con `can_view_unit_secrets()`).

### Restricciones
- Staff y huéspedes comparten el rol `authenticated`: no vale `REVOKE` por columna sin dar al staff otra vía.
- El catálogo público hace `properties.select()` (todas las columnas) **sin sesión**: un `REVOKE` de columna
  rompería `select *` en las apps instaladas.
- El trigger `set_keybox_code_on_insert` (no SECURITY DEFINER) lee `properties.main_door_keycode`; se ejecuta
  también con service_role desde la Edge Function `admin-panel` (`create_booking`).

## Fase 1 — Solo servidor, sin nueva versión (efecto inmediato) — ✅ APLICADA 2026-10-20

- 1a → `20261020110000_mask_secrets_admin_bookings_dashboard` (función `can_view_booking_secrets`).
  Verificado simulando sesiones: huésped no validado 0 secretos; validado y admin, todos.
- 1b → opción A, `20261020120000_protect_main_door_keycode` (tabla en `private.properties`, vista
  `public.properties`, `can_view_property_secrets`, trigger `properties_view_update`, `set_keybox_code_on_insert`
  SECURITY DEFINER sobre la tabla privada; `admin_bookings_dashboard` redefinida contra la vista).
  Probada antes en transacción con ROLLBACK (16 casos) y después por REST con la clave anon: 7 propiedades,
  16 columnas, 0 códigos; embeds `bookings→properties` OK; esquema `private` no expuesto.
  Advisors nuevos esperados: `security_definer_view` (public.properties) y RPC ejecutable de las 2 funciones
  booleanas.
- Efecto colateral aceptado: un staff no admin solo ve el código del portal de su propiedad.

### 1a. Enmascarar `admin_bookings_dashboard` (cierra vía 2)
- Redefinir la vista conservando columnas y orden; los campos secretos pasan a
  `CASE WHEN is_staff() OR can_view_unit_secrets(unit_id) THEN ... END` (incluido el json `units`, por unidad).
- Staff: sin cambios. Huésped validado: sin cambios. Huésped no validado: ve `null`.
- La app ya trata esos campos como opcionales (`keyboxCode ?? unit.boxCode`, etc.). Verificar pantallas
  `booking_detail_screen` (staff) y `my_accommodation`/`stay_guide` con null.

### 1b. Proteger `main_door_keycode` (cierra vía 1) — **decisión pendiente**
- **Opción A (sin release):** mover la tabla a un esquema no expuesto (`private.properties`) y crear la vista
  `public.properties` con las mismas columnas, `main_door_keycode` enmascarado con una función nueva
  `can_view_property_secrets(property_id)` (staff o huésped validado en esa propiedad).
  - `INSTEAD OF UPDATE` para las dos escrituras de staff (`default_deposit_cents`, `main_door_keycode`).
  - Actualizar `set_keybox_code_on_insert` y las funciones que leen `properties` para usar `private.properties`
    (si no, con service_role leerían el código enmascarado y generarían `keybox_code` erróneos).
  - Riesgo medio: 9 funciones, 1 vista y FKs dependen de la tabla. **Probar antes en una rama de Supabase.**
- **Opción B (con la release de la fase 2):** la app deja de leer `properties` completo y el código del portal se
  pide por RPC; después `REVOKE` de la columna. Más simple, pero el código sigue público hasta que todos
  actualicen.

## Fase 2 — App (nueva versión)

1. `PropertiesRepository.getAll/getById`: seleccionar columnas explícitas, sin `main_door_keycode`.
2. ✅ APLICADA 2026-10-20 (`20261020130000_get_guest_access`). RPC `get_guest_access(p_booking_id)` → jsonb:
   `{booking_id, can_view, reason: ok|checkin_not_validated|before_checkin|outside_window, checkin_date,
   checkout_date, early_checkin_available_at, timezone, server_time, keybox_code, main_door_keycode,
   units: [{unit_id, name, wifi_network, wifi_password, box_code, box_location_text, locker_number,
   access_instructions, welcome_instructions}]}` (unidad principal primero). Secretos a null si
   `can_view_booking_secrets` no lo permite; reserva ajena → `not_allowed`; anon sin EXECUTE.
   Probada: no validado, validado, reserva ajena, admin, anon y reserva multiunidad.
   `get_access_for_booking` no sirve (devuelve `units.box_code`, no `keybox_code`, ni WiFi ni multiunidad).
3. `my_accommodation_screen`, `access_instructions_wrapper_screen`, `stay_guide_screen`: obtener los secretos de
   la RPC; dejar de usar `AdminPanelRepository.getBooking` en el lado huésped (también en `guest_home_bloc`,
   `normas_screen`, `romantic_pack_screen`, que lo usan solo para datos no secretos → repositorio de huésped).
4. `access_box`: pantalla sin enlaces (solo alcanzable tecleando la URL en web) → eliminar feature y ruta.
5. `checkin_repository_impl` / `checkout_repository_impl`: `from('units').select('name')` → vista
   `units_with_full_address` (prepara la fase 3).
6. Tests de BLoC/repositorio para la RPC (85 %+) · `dart fix --apply && dart analyze`.
7. Publicar y subir `app_config.minimum_version` en Android e iOS.

## Fase 3 — ✅ APLICADA 2026-10-20 SIN esperar release (cambio de enfoque)

Quitar la política de `units` a huéspedes habría roto `getBooking` (home, notificaciones, normas, pack
romántico, Guía y guard la usan para datos no secretos). Se aplicó el mismo patrón que `properties`:
- `20261020150000_protect_units_secrets`: tabla en `private.units`, vista `public.units` (DEFINER) que replica la
  RLS con `can_read_unit()` y enmascara con `can_view_unit_secrets()` (ahora acepta service_role y conexión
  directa); `units_view_update` para escrituras de staff; funciones DEFINER (`get_all_units_availability`,
  `get_checkin_details`, `set_keybox_code_on_insert`, `get_guest_access`) leen `private.units`;
  `admin_bookings_dashboard` (unidades materializadas) y `booking_checkin_status` redefinidas contra la vista.
  Probada en transacción (24 casos) y por REST. Dashboard por reserva: admin 191→~251 ms, huésped ~32 ms.
  ⚠️ Crear unidades ya no es posible por la API (la app no lo hace): insertar en `private.units`.
- `20261020160000_protect_bookings_keybox`: `anon`/`authenticated` con SELECT por columna en `bookings` salvo
  `keybox_code`; el dashboard la obtiene con `booking_keybox_code()` (DEFINER). Probada (13 casos) y por REST.
  ⚠️ Columnas nuevas en `bookings` necesitan `GRANT SELECT (col)` para ser legibles por la API.

Pendiente opcional: eliminar `AccessBoxScreen` (ruta sin enlaces; su consulta a `keybox_code` ya falla) y
migrar home/normas/pack a un repositorio de huésped (limpieza, ya no es de seguridad).

## Fase 3 (plan original, descartado)

- Eliminar la política `units_guest_select_active_stay` (el huésped solo lee unidades por la vista).
- `bookings.keybox_code`: inventario de lecturas de staff de `bookings` con `select('*')`; dar al staff acceso
  por vista/RPC SECURITY DEFINER y `REVOKE SELECT (keybox_code)` a `authenticated`/`anon`.
- Si se eligió la opción B: `REVOKE` de `main_door_keycode`.
- Re-ejecutar advisors y actualizar la memoria `guest-secrets-direct-read`.

## Fuera de alcance / decisiones
- La regla de las 14:00 sigue solo en la UI; el servidor exige check-in validado y estar en el día de entrada.
  Un huésped validado podría obtener los códigos entre las 00:00 y las 14:00 de su día de entrada.
- `wifi_network` (nombre de la red) se considera no sensible.

## Rollback
- Cada migración con su `.ROLLBACK.sql` (mismo patrón que `20261020100000_protect_unit_secrets_and_bookings`).
