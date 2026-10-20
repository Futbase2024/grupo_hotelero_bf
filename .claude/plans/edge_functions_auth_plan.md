# Plan: autenticación de Edge Functions (emails y push)

> Fecha: 2026-10-19 · Rama: feature/novedades · Proyecto Supabase: qwepisgdqlmqfxwqkztz

## Problema

Casi todas las Edge Functions de email y push están desplegadas con `verify_jwt=false` y
sin comprobación interna: cualquiera con la URL puede mandar correos con la marca BF Stay
(plantillas Brevo con destinatario y parámetros libres) o notificaciones push.

## Parte 1 — Retirar las `send-*-email` sin uso (~36)

- Ni la app, ni la BD, ni el cron, ni otras funciones las llaman (se verifica una a una
  contra el código de las funciones que se mantienen).
- Por cada una: copia del código desplegado en `supabase/functions/_retired/<slug>/index.ts`
  y redespliegue como stub 410 con `verify_jwt=true`.
- Reversible: redesplegar desde la copia.

## Parte 2 — Exigir staff en las 6 `send-*-email` en uso

`send-new-booking-email`, `send-checkin-email`, `send-access-code-email`,
`send-cancellation-email`, `send-checkin-cancellation-email`, `send-early-checkin-email`.

- Solo las llaman pantallas del admin (`EmailService`) y `admin-panel` (servidor).
- Guard en código (se mantiene `verify_jwt=false` para no depender del formato de claves):
  `Authorization: Bearer <SUPABASE_SERVICE_ROLE_KEY>` (llamadas internas) **o** JWT de un
  usuario con rol `admin`/`staff` en `user_roles`. Si no → 401/403.
- `admin-panel`: añadir `Authorization: Bearer <service role>` a sus `fetch` a
  `send-new-booking-email` (resend_code / regenerate_code).
- Copia del código previo de cada una en `supabase/functions/_previous/<slug>/` y versión
  nueva en `supabase/functions/<slug>/`.

## Parte 3 — Push (FCM)

Funciones: `send-fcm`, `send-fcm-notifications`, `send-checkin-notification`, `fcm-sender`,
`invoke-send-fcm`, `test-fcm`. Llamadas desde triggers/cron de BD (sin cabecera) y desde la
app (huésped y admin) vía `NotificationService`.

- Secreto interno en Vault (`internal_functions_secret`) + función `get_internal_secret()`
  solo para `service_role`, para que las Edge Functions lo lean sin variables de entorno.
- Triggers/cron de BD envían `x-internal-secret`.
- Edge Functions aceptan: secreto interno, o usuario autenticado con reglas según lo que
  pida (a concretar tras revisar `NotificationService`).
- `test-fcm` / `invoke-send-fcm`: retirar si no se usan.

## Verificación

- Sin sesión → 401 en todas.
- Admin: reenviar código de una reserva, validar un check-in (email ID 3), pedir fianza.
- Huésped: enviar check-in (push al admin), mensaje de chat (push).
- Triggers: push al validar check-in.

## Estado (2026-10-19)

- [x] Parte 1: 36 `send-*-email` sin uso retiradas (stub 410, verify_jwt) + `send-booking-code`
      (devolvía el código de acceso en la respuesta). Copias en `supabase/functions/_retired/`.
- [x] Parte 2: guard `requireStaff` (staff o service role) en las 6 `send-*-email` en uso.
      `admin-panel` envía `Authorization: Bearer <service role>` a `send-new-booking-email`.
      Versiones previas en `supabase/functions/_previous/`.
- [x] Parte 3 (push):
  - Migración `20261019190000_harden_push_notifications`: secreto en Vault +
    `internal_functions_secret()` (solo service_role), `notify_fcm` firma con
    `x-internal-secret`, trigger en `notification_queue` (huésped solo → staff con token real),
    `get_fcm_token(s)` filtradas para no-staff, REVOKE de `notify_fcm_immediately`.
  - `send-fcm` exige el secreto (o service role).
  - `send-checkin-notification` reescrita: exige sesión, datos desde BD, HTML escapado,
    enlace fijo, límite 1/10 min por reserva.
  - Retiradas `fcm-sender`, `invoke-send-fcm`, `test-fcm`.
  - `send-fcm-notifications` se deja abierta a propósito: no lee el body, solo procesa la cola.
- Pendiente de prueba manual en la app (positivos): reenviar código, validar check-in (email),
  enviar check-in como huésped (push + email al admin), mensaje de chat (push).
- Pendiente aparte: funciones de BD sin uso (`process_notification_queue*`,
  `trigger_process_notification_queue`, `notify_fcm_immediately`) se podrían borrar.
