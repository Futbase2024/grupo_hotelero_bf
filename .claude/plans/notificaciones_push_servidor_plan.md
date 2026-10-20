# Plan: notificaciones (push e in-app) generadas solo en el servidor ("Migración 5")

> Fecha: 2026-10-20 · Rama: `feature/novedades` · Proyecto Supabase: `qwepisgdqlmqfxwqkztz`

## Problema

El huésped (sesión anónima = rol `authenticated`) genera desde el cliente los avisos al staff
([notification_service.dart](../../lib/core/services/notification_service.dart)): lee los admins en `user_roles`,
pide sus tokens FCM, inserta en `staff_notifications` y en `notification_queue` y dispara
`send-fcm-notifications`. Para permitirlo, el servidor deja abiertas varias puertas:

| # | Hueco | Impacto |
|---|-------|---------|
| 1 | `guest_notifications` INSERT con `auth.uid() IS NOT NULL` | Cualquier huésped crea notificaciones en la app de **otro** huésped (phishing: "check-in rechazado, paga aquí") |
| 2 | `staff_notifications` INSERT con `auth.uid() IS NOT NULL` | Cualquier huésped crea avisos falsos en el panel del staff de cualquier propiedad |
| 3 | `fcm_tokens` SELECT: cualquiera ve los tokens de los admins; `get_fcm_token(s)_for_user(s)` devuelve tokens de staff a no-staff | Exposición de tokens e IDs de admins |
| 4 | `notification_queue` INSERT de no-staff hacia staff (con token válido) | Push con texto arbitrario a los móviles de los admins |
| 5 | `user_roles_select_admins` (`role = 'admin'`) visible para cualquiera | Enumeración de admins |

Ya existe en el servidor: `trg_checkin_status_notify` (validado/rechazado → huésped), `trg_booking_status_notify`,
`trg_deposit_requested_notify`, `notify_chat_message`, todos con `notify_fcm()` → Edge Function `send-fcm`
(protegida con `x-internal-secret`, resuelve tokens con service_role y acepta `user_ids`).

## Hallazgos del barrido de RLS (2026-10-20)

- ✅ **Cerrado** `user_roles_insert_own`: cualquier sesión (también anónima) podía insertarse como `admin` global
  (`20261020165000_lock_user_roles`).
- ✅ **Cerrado** `clients` abierto a cualquier sesión (`20261020166000_restrict_clients_to_staff`).
- ✅ **Cerrado (20261020167000)** **Chat**: `participants_insert_temp` / `conversations_insert_any_user` (`auth.uid() IS NOT NULL`): con el UUID
  de una conversación ajena cualquiera se añade como participante (incluso `role='admin'`) y lee sus mensajes.
  Revisar cómo crea la app las conversaciones antes de restringir (añadir a esta migración o a una propia).
- ✅ **Cerrado (20261020167000)** **`reviews`** (además UPDATE/DELETE permitían editar/borrar reseñas ajenas) INSERT abierto a cualquier sesión: restringir a reseñas de la propia reserva.

## Avisos que hoy genera el cliente

| Aviso | Quién | Dónde | Pasa a |
|-------|-------|-------|--------|
| Check-in enviado (pendiente) | huésped → admins | `checkin_bloc.dart` → `notifyAdminCheckinSubmitted` | trigger en `checkins` |
| Check-in auto-validado | huésped → admins | `checkin_bloc.dart` → `notifyAdminCheckinAutoValidated` | trigger en `checkins` |
| Solicitud de extra (Pack Romántico) | huésped → admins | `romantic_pack_screen.dart` → `notifyAdminExtraRequested` | trigger en `extra_requests` |
| Check-in cancelado | staff → huésped | `checkin_detail_screen.dart` → `notifyGuestCheckinStatus('cancelled')` | se mantiene (staff) o trigger |
| Email check-in completado | huésped → Edge Function | `sendCheckinCompletedEmail` | fuera de alcance (EF ya exige staff/servicio: revisar) |

## Fase 1 — ✅ APLICADA 2026-10-20 (`20261020170000_server_side_notifications`)

Probada en transacción: envío normal → 1 aviso "pendiente" + 1 push; auto-validado → 1 aviso "validado
automáticamente"; extra → 1 aviso + push; anónimo no inserta en ninguna tabla ni ve tokens/admins; staff
sigue creando la notificación de cancelación y leyendo tokens por RPC. También se cerró `email_logs`.
Nota: reenviar un check-in que ya estaba `submitted` no vuelve a avisar (antes la app avisaba en cada envío).

### Diseño aplicado

Una única migración que hace a la vez (para que no haya ventana con avisos dobles):

1. **Función `notify_property_admins(property_id, type, title, body, booking_id, data)`** SECURITY DEFINER, solo
   invocable desde triggers (REVOKE a anon/authenticated): inserta en `staff_notifications` y llama a
   `notify_fcm` con `user_ids` = admins de la propiedad o globales (mismo criterio que `notifyAdmins`).
2. **Trigger en `checkins`** (AFTER INSERT/UPDATE de `status`):
   - pasa a `submitted` → "📝 Nuevo Check-in Pendiente" (texto actual, con nombre del huésped y unidad desde BD);
   - pasa a `validated` por auto-validación → "✅ Check-in validado automáticamente".
   ⚠️ Verificar cómo distingue `submit_guest_checkin` la auto-validación (flag `bookings.auto_validate_checkin` y
   cambio `submitted → validated` en la misma transacción) para no notificar como "pendiente" y "auto" a la vez.
3. **Trigger en `extra_requests`** (AFTER INSERT) → "💝 Nueva solicitud: {extra_name}" con `guest_name`/`unit_name`.
4. **Cerrar huecos:**
   - `guest_notifications` y `staff_notifications`: INSERT solo staff (los triggers son DEFINER y no se ven afectados).
   - `notification_queue`: el guard rechaza cualquier INSERT de no-staff.
   - `get_fcm_token_for_user` / `get_fcm_tokens_for_users`: solo staff o service_role (quitar rama `is_staff_user`).
   - `fcm_tokens` SELECT: solo los propios tokens (el staff usa la RPC).
   - `user_roles_select_admins`: eliminar (comprobar antes que nada más la necesita).
5. **Compatibilidad con apps instaladas:** sus llamadas fallan en silencio (todo `NotificationService` está en
   try/catch y devuelve `false`) y el aviso lo genera el trigger: el admin recibe **uno**, no dos.
6. **Pruebas** en transacción con ROLLBACK simulando huésped/staff/anon: no-staff no inserta en ninguna de las tres
   tablas, no lee tokens ni admins; enviar check-in y crear extra generan `staff_notifications` + llamada a
   `notify_fcm` (verificar en `net._http_response` tras aplicar con una reserva de prueba).

## Fase 2 — App (próxima versión, limpieza)

- Quitar de `checkin_bloc.dart` y `romantic_pack_screen.dart` las llamadas `notifyAdmin*`.
- Reducir `NotificationService` a lo que usa el staff (o mover la cancelación a trigger y eliminarlo).
- Tests de los blocs afectados · `dart fix --apply && dart analyze`.

## Fuera de alcance
- `send-fcm-notifications` sigue abierta (solo procesa la cola; con el guard ya no hay entradas de no-staff).
- `bookings` sin Realtime (UX de la fianza).

## Rollback
- Migración con `.ROLLBACK.sql` que restaura políticas, funciones y elimina los triggers nuevos.
