# Plan: Auto-validación de check-in nocturno (a partir de las 23:00)

> Origen: reserva `BF-DMW8-VJXZ` (Paulo Dos Santos, 16→17 ago 2026). El huésped envió
> el check-in a la 01:17 y quedó en `submitted` hasta que un admin lo validó a mano a
> las 06:52. Motivo: `bookings.auto_validate_checkin = false` y no existe ninguna regla
> horaria.

## Decisiones de negocio (confirmadas por el usuario)

1. **Switch manual del admin**: se mantiene igual. Si está activado, autovalida a
   cualquier hora.
2. **Regla nocturna**: a partir de las **23:00 hora española del día de entrada
   (`checkin_date`)**, **sin límite superior**, todo check-in se autovalida siempre,
   tenga o no el switch activado.
3. **Check-ins ya pendientes**: además del momento del envío, un **barrido periódico**
   autovalida los `submitted` que hayan entrado en la ventana.

> **Historial de la decisión (2026-08-17)**: se probó cerrar la franja a las 09:00
> (`20260817093000`) para que en estancias largas no se autovalidaran check-ins
> completados a mitad de estancia. Se descartó (`20260817101500`): el check-in se hace
> una sola vez, al llegar, y con la franja cerrada un check-in tardío se quedaba
> colgado esperando revisión manual para siempre. Queda la regla abierta.

### Tabla de verdad (reserva 16 → 17 ago, y también 16 → 20: sólo cuenta `checkin_date`)

| Envío del check-in | Switch OFF | Switch ON |
|---|---|---|
| 16 ago 20:00 | manual (hasta el barrido de las 23:00 → auto) | auto |
| 16 ago 22:45 | manual (hasta el barrido de las 23:00 → auto) | auto |
| 16 ago 23:30 | **auto** | auto |
| 17 ago 01:17 ← caso real | **auto** | auto |
| 17 ago 09:00 | **auto** | auto |
| 18 ago 12:00 (estancia larga) | **auto** | auto |

## Consideraciones técnicas

- **Zona horaria**: la BD corre en `UTC`. La hora de corte debe calcularse siempre con
  `AT TIME ZONE 'Europe/Madrid'` para que CEST/CET (verano/invierno) no descuadre el
  corte una hora.
- **Cron y DST**: por el mismo motivo, el job **no** se programa a las 23:00 fijas
  (serían las 21:00 UTC en verano y las 22:00 UTC en invierno). Se programa
  **cada 15 minutos** y la condición horaria se evalúa dentro de la función. Es
  idempotente y además recoge los pendientes posteriores (regla sin límite superior).
- **Bug preexistente a corregir**: `validate_checkin` (manual) hace
  `UPDATE bookings SET status = 'checked_in'`, pero las rutas de auto-validación
  (`submit_guest_checkin` y `set_booking_auto_validate_checkin`) **no**. Al pasar la
  auto-validación a ser el caso habitual, hay que igualar el comportamiento o las
  reservas autovalidadas no aparecerán como `checked_in` en el panel.
- **Notificación al huésped**: la da el trigger `trg_checkin_status_notify` en el
  `UPDATE` a `validated`. Se conserva haciendo la validación con un UPDATE propio
  (ya se hacía así).
- **Notificación al admin**: la decide el cliente en `checkin_bloc.dart`, que relee el
  estado tras el envío (`notifyAdminCheckinAutoValidated` vs `notifyAdminCheckinSubmitted`).
  Como la regla nocturna se aplica **dentro** de `submit_guest_checkin`, el bloc ya lee
  `validated` y avisa correctamente. **No requiere cambios.**

## Cambios

### 1. Base de datos (migración `auto_validate_late_night_checkins`)

- `public.checkin_auto_validate_cutoff()` → `time`, devuelve `'23:00'`. Fuente única de
  la hora de corte en SQL (espejo de `CheckinPolicy.maxCheckinTime` en Dart).
- `public.is_late_checkin_window(p_checkin_date date, p_timezone text, p_at timestamptz)`
  → `boolean`. TRUE desde `checkin_date + 23:00` en hora local de la propiedad, sin
  límite superior.
- `public.apply_checkin_validation(p_checkin_id uuid, p_booking_id uuid, p_source text)`
  → `boolean`. Helper interno: valida sólo si sigue en `submitted`, pone la reserva en
  `checked_in` y escribe en `audit_log` con el `source`. Evita triplicar la lógica.
- **Modificar `submit_guest_checkin`**: autovalida si
  `auto_validate_checkin OR is_late_checkin_window(checkin_date)`.
  `source` = `'auto_validate_flag'` o `'late_night_rule'`.
- **Modificar `set_booking_auto_validate_checkin`**: usa el helper (gana el
  `checked_in` que hoy le falta).
- **Nueva `public.auto_validate_late_checkins()`** → `integer` (nº validados). Barre
  los `checkins.status = 'submitted'` cuya reserva esté en ventana y no esté cancelada.
- **Cron** `auto-validate-late-checkins`, `*/15 * * * *`.

### 2. Dart

- `lib/core/constants/checkin_policy.dart`: añadir
  `autoValidateAfterHour = '23:00'` + comentario que apunte a la función SQL, para que
  el texto y la regla no se desincronicen.
- `lib/l10n/app_*.arb` (7 idiomas): reescribir
  `admin_booking_auto_validate_subtitle` para reflejar que después de las 23:00 se
  autovalida igualmente, y añadir `admin_booking_auto_validate_night_note`.
- `booking_detail_screen.dart`: mostrar esa nota bajo el switch.
- Regenerar `app_localizations*.dart` (`flutter gen-l10n`).

### 3. Verificación

- `dart fix --apply && dart analyze`.
- SQL: comprobar la ventana en los bordes (22:59 / 23:00 / día siguiente) y en
  invierno (CET) con fechas simuladas.
- Comprobar que el barrido es idempotente (segunda pasada valida 0).

## Fuera de alcance

- No se toca la hora límite de check-in comunicada al huésped (`maxCheckinNotice`).
- No se cambia el default de `auto_validate_checkin` (sigue `false`).
