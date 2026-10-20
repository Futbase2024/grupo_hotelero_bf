# Plan: refresco y rendimiento del tab de Check-ins (admin)

> **Fecha**: 2026-07-27
> **Origen**: reporte de admin — "llegan los FCM de check-in, pero al entrar en Check-ins tarda y no aparecen los *Por revisar*; hay que entrar 3-4 veces".

---

## Diagnóstico

| # | Causa | Evidencia |
|---|-------|-----------|
| 1 | El tab de check-ins **nunca se recarga** al entrar | `_onTabChanged` case 2 → `if (state.checkins.isEmpty)`. Tras la carga inicial la lista nunca está vacía. |
| 2 | Único punto de recarga = realtime, y es frágil | Sin reacción a `AppLifecycleState.resumed` (el WS cae en background), debounce 3 s, y `_onCheckinsChanged` **descarta** el evento si `isLoadingCheckins`. |
| 3 | El admin ignora el push recibido | `NotificationRefreshBus` sólo lo escucha `guest_home_screen`. |
| 4 | Carga pesada | `listBookings(fromDate: hoy-90d)` → 527 filas + 3 queries auxiliares, para pintar 0-2 `submitted`. Además el snapshot inicial del `.stream()` dispara un segundo refetch completo a los 3 s del arranque. |

Datos de BD (2026-07-27): 694 reservas (527 en ventana de 90 d), 694 check-ins (672 `validated`, 22 `draft`, 0 `submitted`). `checkins.booking_id` es UNIQUE y la tabla está en `supabase_realtime` con REPLICA IDENTITY FULL → el embed y el realtime son correctos, el fallo es de cliente.

---

## Cambios

### 1. Recarga al entrar en el tab (silenciosa)
`lib/features/admin/domain/bloc/admin_dashboard_bloc.dart`
- `_onTabChanged` case 2 → disparar siempre `AdminDashboardCheckinsLoadRequested`.
- `_onCheckinsLoadRequested` → no vaciar la lista: `isLoadingCheckins = true` sólo si `state.checkins.isEmpty`; si ya hay datos, refresco en segundo plano (la lista sigue visible y se sustituye al llegar).
- Mismo criterio para el tab 1 (reservas) por coherencia.

### 2. Filtro de estado server-side
`admin_panel_repository.dart` (contrato) + `admin_panel_repository_impl.dart`
- Nuevo parámetro `String? checkinStatusFilter` en `listBookings`.
- Cuando llega != null/'all': embed `checkins!inner(id,status)` + `.eq('checkins.status', filtro)`.
- `_fetchCheckinsSource()` en el BLoC lo pasa desde `state.checkinsStatusFilter`.
- Efecto: el caso por defecto ("Por revisar") pasa de 527 filas + 3 queries auxiliares a ~2 filas.

### 3. Refresco por ciclo de vida y por push
`lib/features/admin/dashboard/presentation/screens/admin_dashboard_screen.dart`
- `WidgetsBindingObserver` → en `resumed`, si el tab actual es 2 (o 0) disparar recarga.
- Suscripción a `NotificationRefreshBus.instance.stream`: ante tipos de check-in (`checkin_status`, `checkin_submitted`, `new_checkin`…) disparar `AdminDashboardCheckinsLoadRequested` + recarga de notificaciones.
- Cancelar la suscripción y quitar el observer en `dispose`.

### 4. Robustez del realtime
`admin_dashboard_bloc.dart`
- `_onCheckinsChanged`: si hay carga en curso, reintentar (reencolar con un pequeño retardo) en lugar de descartar.
- Ignorar el snapshot inicial del `.stream()` (`skip(1)` sobre la señal) → elimina el refetch duplicado del arranque.

---

---

## Fase 2 — arranque en frío del panel (2026-07-27)

Medido en el proyecto real: RPC `get_dashboard_summary` **202 ms**; `bookings` de la
ventana de 90 días = **527 filas / ~557 kB**; `booking_units` de esas reservas = 541
filas; ~11 round-trips hasta pintar el dashboard.

1. **La carga inicial ya no descarga las reservas.** El tab de resumen se sirve
   entero del RPC. El único dato que faltaba era la ocupación de hoy, que se
   calculaba en cliente recorriendo las 527 reservas → ahora lo devuelve el RPC
   como `occupied_today` (migración `20260727120000_...`, con su ROLLBACK).
   Cambia la semántica: cuenta **unidades distintas** ocupadas (una reserva de 3
   habitaciones cuenta 3), coherente con dividir entre `total_units`. Hoy ambos
   criterios dan 8/14.
2. **`listBookings` paraleliza** `units` / `properties` / `booking_units` con
   `Future.wait` → de 4 idas y vueltas encadenadas a 2.
3. `getNotifications` deja de ser secuencial respecto al RPC (van a la vez).

Pendiente (no abordado): mínimo de splash de 600 ms, `AlojamientosBloc` arrancando
también para admin, y los 202 ms del RPC.

---

## Fase 3 — tab de Reservas (2026-07-27)

1. Ventana deslizante **90 → 30 días** (`_bookingsWindowDays`): 527 → 210 filas.
   Búsqueda y rango personalizado siguen consultando el histórico completo.
2. `booking_units(count)` embebido en la consulta principal → desaparece la
   tercera consulta auxiliar (541 filas menos, un round-trip menos).
3. `listBookings(lightweight: true)` para los listados del panel: SELECT sin
   `guest_email`, `guest_phone`, `staff_notes`, `code_*`, `created_at`,
   `num_adults/children`, `booking_status`. Facturas, ocupación y el detalle
   siguen llamando SIN el flag porque sí usan esos campos.
4. Correctitud: con filtro de estado de check-in **ya no se aplica la ventana**
   (el join interno acota de sobra), así que un check-in pendiente de una
   reserva antigua no queda oculto.

### Acceso al histórico con la ventana reducida

- Nuevo `DateFilter.allHistory` ("Todo el histórico"): consulta sin límite de
  fechas. Aparece solo en los diálogos de filtros (iteran `DateFilter.values`).
- **Cada preset pide su propio rango al servidor** (`DateFilter.serverFromDate`)
  y cualquier cambio de período recarga. Antes solo recargaba el rango
  personalizado y los presets se resolvían en cliente sobre lo ya descargado:
  con la ventana de 30 días, "mes anterior" habría salido incompleto.
- `_onBookingsLoadRequested` gana el mismo control de solapamiento que
  check-ins (dos cambios de filtro seguidos podían pintar el resultado de la
  consulta más lenta).

## Verificación

```bash
dart fix --apply && dart analyze
```

- Abrir el panel, dejar en background, enviar un check-in desde un huésped, volver a la app → aparece en "Por revisar" sin reentrar.
- Pulsar el KPI "Check-ins pendientes" → lista fresca, sin pantalla en blanco mientras refresca.
- Comprobar en logs `📋 [listBookings] Respuesta recibida: N registros` → N pequeño con el filtro por defecto.
