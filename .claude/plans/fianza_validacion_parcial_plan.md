# Plan: Validación con fianza (validación parcial)

> Fecha: 2026-10-19 · Rama: feature/novedades

## Objetivo

Además de la validación normal, el admin puede **pedir una fianza** antes de validar.
Mientras la fianza esté pendiente, el huésped **no ve nada de acceso** (códigos, wifi,
instrucciones): para él el check-in sigue "en revisión", con un aviso de que falta la fianza.

El pago **no pasa por la app**: el admin genera el enlace en la pasarela de su banco, lo
envía (chat de la app / WhatsApp / email), comprueba el cobro en su pasarela y lo marca
como pagado en la app. Eso valida el check-in con el flujo de siempre. Tras el check-out
se registra la devolución (total o parcial) para llevar el control.

## Decisiones tomadas

| Tema | Decisión |
|---|---|
| ¿Qué ve el huésped? | "En revisión" + línea: "Pendiente de recibir el pago de la fianza. Revisa el enlace que te hemos enviado". Nunca códigos |
| Importe | Sugerido por alojamiento (`properties.default_deposit_cents`), editable al pedirla |
| Devolución | Se registra: importe devuelto, importe retenido y motivo, fecha y admin |
| Estado del check-in | **No se toca**: sigue en `submitted` hasta confirmar el pago |
| Alcance | **Opcional y por reserva.** Por defecto `none` = validación normal. Solo entra en fianza si el admin pulsa "Pedir fianza" en esa reserva. El importe sugerido del alojamiento NUNCA aplica fianza automáticamente |

## Estado actual relevante (verificado en BD)

- `apply_checkin_validation()` es el embudo único de la auto-validación:
  `submit_guest_checkin` (interruptor + regla nocturna), `auto_validate_late_checkins`
  (cron cada 15 min) y `set_booking_auto_validate_checkin`.
- `validate_checkin()` y `manual_checkin_validate()` validan por su cuenta (admin).
- `get_access_for_booking()` ya exige `checkins.status = 'validated'` → los códigos quedan
  protegidos en el backend sin cambios.
- El trigger `trg_checkin_status_notify` notifica al validar (push + aviso en la app) → no se toca.
- El email con instrucciones de acceso solo se envía desde `checkin_detail_screen`.

## Máquina de estados (`bookings.deposit_status`)

```
none ──[Pedir fianza]──► pending ──[Marcar pagada y validar]──► paid ──[Registrar devolución]──► returned
                           │  ▲
                           │  └─[Reenviar enlace]
                           └──[Eximir]──► none
```

Acceso completo = `checkins.status = 'validated'` (sin cambios). Con `pending` es imposible
llegar a `validated` porque todas las vías de validación lo bloquean.

## Fase 1 — Base de datos (migración)

### Columnas

```sql
ALTER TABLE bookings
  ADD COLUMN deposit_status text NOT NULL DEFAULT 'none'
    CHECK (deposit_status IN ('none','pending','paid','returned')),
  ADD COLUMN deposit_amount_cents int CHECK (deposit_amount_cents > 0),
  ADD COLUMN deposit_payment_link text,
  ADD COLUMN deposit_sent_via text[],            -- {'chat','whatsapp','email'}
  ADD COLUMN deposit_requested_at timestamptz,
  ADD COLUMN deposit_requested_by uuid,
  ADD COLUMN deposit_paid_at timestamptz,
  ADD COLUMN deposit_paid_by uuid,
  ADD COLUMN deposit_reference text,             -- nº operación de la pasarela
  ADD COLUMN deposit_returned_at timestamptz,
  ADD COLUMN deposit_returned_by uuid,
  ADD COLUMN deposit_returned_cents int,         -- lo devuelto
  ADD COLUMN deposit_retained_cents int,         -- lo retenido (daños)
  ADD COLUMN deposit_retained_reason text;

ALTER TABLE properties ADD COLUMN default_deposit_cents int;
```

### RPCs nuevas (SECURITY DEFINER, solo staff, con audit_log)

| RPC | Precondición | Efecto |
|---|---|---|
| `request_booking_deposit(p_booking_id, p_amount_cents, p_link, p_sent_via text[])` | checkin no `validated`/`cancelled`; deposit `none` o `pending` | `pending` + datos. Reenviar = volver a llamarla |
| `waive_booking_deposit(p_booking_id)` | deposit `pending` | vuelve a `none` (luego validación normal) |
| `confirm_deposit_and_validate(p_booking_id, p_reference)` | deposit `pending`; checkin `submitted` | `paid` + valida (misma lógica que `validate_checkin`) en una transacción |
| `register_deposit_return(p_booking_id, p_returned_cents, p_retained_reason)` | deposit `paid` | `returned`; calcula retenido = importe − devuelto; motivo obligatorio si retenido > 0 |

Si el huésped aún no ha enviado el check-in, la confirmación **solo marca `paid`**; cuando
lo envíe, `submit_guest_checkin` seguirá su curso (validación manual o auto, ya sin bloqueo).

### Controles en funciones existentes

- `apply_checkin_validation`: `RETURN false` si `deposit_status = 'pending'` (cubre interruptor,
  regla nocturna y cron).
- `validate_checkin` y `manual_checkin_validate`: error `deposit_pending` si está pendiente
  (el admin debe usar "Marcar pagada y validar" o "Eximir").
- `set_booking_auto_validate_checkin`: hereda el control vía `apply_checkin_validation`.

### Notificación al huésped

- Trigger en `bookings` al pasar a `pending`: aviso en la app (`guest_notifications`, tipo
  `deposit_requested`) + push. **Sin enlace ni códigos**, solo "Te hemos enviado el enlace
  para abonar la fianza".
- Al validar → trigger actual `trg_checkin_status_notify` (sin cambios).

## Estado

- [x] Fase 1 — migración `20261019120000_add_booking_deposit` aplicada y probada (2026-10-19)
- [x] Fase 2 — admin (2026-10-19). Desviaciones respecto al plan:
  - Email: se abre el correo del admin con el mensaje redactado (`mailto:`), no plantilla Brevo.
  - Importe sugerido: casilla "Guardar como sugerido" en el diálogo de pedir fianza, en
    lugar de un campo en la pantalla de alojamientos.
  - La fianza se lee con `getBookingDeposit` (tabla `bookings`), sin tocar la vista
    `admin_bookings_dashboard`.
- [x] Fase 3 — huésped (2026-10-19): `UserEntity.depositStatus`, línea de fianza pendiente en
  la home y en la pantalla de check-in. El refresco usa el push `checkin_deposit` (el bus ya
  reacciona a tipos `checkin*`) y el Realtime de `checkins` al validar. `bookings` NO está en
  la publicación Realtime: si el admin exime la fianza, el texto se actualiza al recargar.
- [x] Seguridad — `20261019150000_guard_guest_direct_updates` aplicada y probada como huésped
  y como admin (2026-10-19): el huésped ya no puede validarse por UPDATE directo ni tocar la
  fianza o `auto_validate_checkin`.
- [x] Seguridad 2 — `20261019170000_restrict_guest_direct_updates` aplicada y probada
  (2026-10-19): eliminada `bookings_guest_update_own_simple`, `checkins_update` solo staff,
  y la validación con fianza pendiente se bloquea para cualquier rol (también service_role).
  `validateCheckin` del repositorio usa la RPC en vez de la acción de `admin-panel`.
  Edge Function `complete-checkin` (sin uso, filtraba box_code) redesplegada como stub 410
  con `verify_jwt`; copia en `supabase/functions/_retired/complete-checkin/`.
- [x] Email de fianza (2026-10-19): plantilla Brevo **ID 8** (copia en
  `docs/email_templates/brevo_template_fianza_pendiente.html`) enviada por la Edge Function
  `send-deposit-email` (verify_jwt, solo staff, datos leídos de BD, copia en `email_logs`).
  Sustituye al `mailto:`. Si falla un canal, el mensaje se copia al portapapeles.
  Retirada `send-generic-email` (sin auth, relay de Brevo); copia en `supabase/functions/_retired/`.
  Pendiente: revisar la autenticación del resto de `send-*-email`.
- [x] Fase 4 — tests (2026-10-19): `money_cents_test`, `booking_deposit_entity_test`,
  `booking_deposit_card_test`. Suite completa 94/94, `dart analyze` limpio.

## Fase 2 — Admin (Flutter)

- `DepositStatus` enum en `lib/core/enums/` (con l10n en 6 idiomas).
- `AdminBookingEntity` + `CheckinDetailEntity`: campos de fianza.
- Contrato + implementación en `AdminPanelRepository`: `requestDeposit`, `waiveDeposit`,
  `confirmDepositAndValidate`, `registerDepositReturn`.
- `checkin_detail_screen`: botón **Pedir fianza** junto a Rechazar/Validar. Si hay fianza
  pendiente, "Validar" se sustituye por **Marcar pagada y validar**.
- Widgets nuevos (clases, no métodos `_buildX`):
  - `RequestDepositSheet`: importe sugerido editable, enlace, canales (chat/WhatsApp/email).
  - `ConfirmDepositPaidDialog`: "¿Has comprobado en tu pasarela…?" + referencia opcional.
  - `RegisterDepositReturnSheet`: devuelto total/parcial, motivo si se retiene.
  - `BookingDepositCard`: en `booking_detail_screen`, estado + acciones según estado.
- Envío del enlace:
  - Chat: insertar mensaje en la conversación del huésped (datasource de chat existente).
  - WhatsApp: `url_launcher` → `https://wa.me/<tel>?text=<mensaje>`.
  - Email: nueva plantilla en `EmailService` (Edge Function `send-checkin-email` u otra).
- Badge **"Pendiente de pago"** en el listado de check-ins (`checkin_status_style`).
- Ficha del alojamiento: campo "Fianza sugerida".
- **Email de acceso**: sacarlo de `checkin_detail_screen` a un servicio común y enviarlo
  también tras `confirm_deposit_and_validate` desde `booking_detail_screen`.
- Avisos con `CeInfoDialog` (no SnackBar).

## Fase 3 — Huésped (Flutter)

- `UserEntity`: añadir `depositStatus` (leído junto a `checkinStatus` en `auth_repository_impl`).
- `guest_home_screen`: en la tarjeta "Pendiente de validación", si `depositStatus == pending`
  mostrar el texto de fianza pendiente.
- `_CheckinRealtimeRefresher`: escuchar también cambios de `bookings.deposit_status` y el
  push `deposit_requested`.
- `booking_access_guard`: mensaje específico (`GuestAction.waitDepositPayment`).

## Fase 4 — Tests

- BLoC/guard: fianza pendiente ⇒ sin acceso; pagada ⇒ flujo normal.
- SQL (manual en rama/preview): auto-validación bloqueada con `pending`; validación normal
  bloqueada; confirmar ⇒ `validated` + `paid`; devolución con/sin retención.

## Riesgos

- Edge Function `admin-panel` (no está en el repo) llama a `validate_checkin` → hereda el
  bloqueo, pero conviene comprobar que propaga bien el error `deposit_pending`.
- Reservas existentes: `deposit_status` por defecto `none` ⇒ cero cambios de comportamiento.
