# Plan · Pack Romántico: sin duplicados y con plazo de 24 h

## Objetivo

1. **Una sola solicitud de Pack Romántico por reserva** (no duplicados).
2. **Plazo**: solo se puede solicitar hasta **24 h antes de la entrada** (check-in a las 14:00 →
   límite = día anterior al check-in a las 14:00).

## Decisiones acordadas

| Punto | Decisión |
|-------|----------|
| Hora de referencia | 14:00 del día de `bookings.checkin_date` (misma hora que llaves/códigos) |
| Deadline | `checkin_date 14:00 - 24 h` |
| Duplicados existentes en BD | **Borrado físico**, conservando la gestionada si existe; si no, la más antigua |
| Solicitud cancelada | Libera el bloqueo (el bloqueo cuenta `requested` + `managed`) |
| Alcance | Solo `extra_type = 'romantic_pack'` (otros extras futuros no quedan atados a esta regla) |
| Zona horaria | Servidor: timezone de la propiedad con fallback `Europe/Madrid`. Cliente: hora local del dispositivo (el servidor es la autoridad) |

## Cambios

### 1. Base de datos — `supabase/migrations/20260815145004_extra_requests_romantic_pack_rules.sql`

> Aplicada el 15/08/2026 en `qwepisgdqlmqfxwqkztz` (versión `20260815145004`).
> Se borraron 6 solicitudes duplicadas.

1. `DELETE` de duplicados de `romantic_pack` (conserva 1 por reserva).
2. Índice único parcial:
   `UNIQUE (booking_id, extra_type) WHERE extra_type='romantic_pack' AND status <> 'cancelled'`.
3. Función + trigger `BEFORE INSERT` que rechaza la solicitud si `now()` supera el deadline
   (24 h antes de las 14:00 del día de check-in). El staff queda exento (puede registrar a mano).
4. Fichero `.ROLLBACK.sql` correspondiente.

### 2. Dominio — `lib/features/guest/extras/domain/`

- `extras_policy.dart` (nuevo): constantes `romanticPackType`, hora de entrada y
  `romanticPackDeadline(checkInDate)` / `canRequestRomanticPack(...)`.
- `repositories/extra_request_repository.dart`: nuevo método
  `getActiveByBookingAndType({bookingId, extraType})`.

### 3. Datos — `extra_request_repository_impl.dart`

- Implementación de `getActiveByBookingAndType` (filtra `status <> 'cancelled'`).
- `create`: traduce el error `23505` (único) y el `P0001` del trigger a excepciones de dominio
  (`ExtraAlreadyRequestedException`, `ExtraRequestWindowClosedException`).

### 4. UI — `romantic_pack_screen.dart`

- Pasa a `StatefulWidget`: al abrir carga el booking (`checkInDate`, `unitName`) y la solicitud
  activa existente.
- El botón "Reservar Ahora" refleja tres estados: cargando / disponible / bloqueado
  (ya solicitado o fuera de plazo), con texto explicativo bajo el precio.
- Revalidación antes de enviar + diálogo de error si el servidor rechaza.
- Se mantiene la apertura de la web de pago solo cuando la solicitud es válida.

### 5. i18n — `lib/l10n/app_{es,en,de,fr,it,pt}.arb` + regeneración

Claves nuevas:
`guest_romantic_deadline_info`, `guest_romantic_already_requested`,
`guest_romantic_already_requested_desc`, `guest_romantic_deadline_passed`,
`guest_romantic_deadline_passed_desc`, `guest_romantic_blocked_title`.

### 6. Borrado de solicitudes desde el panel admin

- `ExtraRequestRepository.delete(id)` + implementación (DELETE físico; la RLS
  `extra_requests_staff_all` ya cubre el borrado del staff de la propiedad).
- Evento `ExtraRequestDeleted` y handler en `ExtraRequestsBloc` con borrado
  optimista del listado.
- `ExtraRequestsLoaded.actionError`: mensaje transitorio para que un fallo de
  acción (borrar / marcar gestionada) se vea en pantalla sin perder la lista.
- `ExtraRequestCard`: icono de papelera + diálogo de confirmación destructivo.

Al borrar una solicitud, el huésped puede volver a pedir el pack si sigue en plazo
(el bloqueo anti-duplicados solo cuenta solicitudes vivas).

## Verificación

- `dart fix --apply && dart analyze` (requiere autorización).
- `flutter gen-l10n` tras editar los `.arb` (requiere autorización).
- Aplicar migración en Supabase `qwepisgdqlmqfxwqkztz` (requiere autorización).
