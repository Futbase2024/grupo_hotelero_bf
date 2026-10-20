# Plan: Solicitudes de Extras (Pack Romántico) → Aviso al Admin

## Objetivo

Cuando un huésped pulsa **"Reservar Ahora"** en el Pack Romántico, registrar una
**SOLICITUD de interés** (NO una reserva/pedido confirmado, porque el pago se hace
en una web externa `boutiquejerez.es` y no podemos confirmar si se completa) y
**avisar al admin**, que la gestiona desde un **listado con estados** (solicitado →
gestionado).

> Terminología deliberada: "solicitud" / "solicitado", nunca "reserva confirmada".

## Estado actual (verificado)

- [romantic_pack_screen.dart:305](../../lib/features/guest/extras/presentation/screens/romantic_pack_screen.dart#L305)
  "Reservar Ahora" → diálogo → `launchUrl` a web externa. **No guarda nada, no avisa a nadie.**
- No existe tabla de extras/pedidos en Supabase (consulta confirmada: vacío).
- Ya existe `NotificationService.notifyAdmins({propertyId, type, title, body, bookingId, data})`
  que crea `staff_notifications` (in-app) + push FCM a todos los admins. **Se reutiliza tal cual.**
- `UserEntity` (AuthBloc) expone: `id`, `name`/`displayName`, `bookingId`, `propertyId`.

## Modelo de datos (Supabase)

Nueva tabla `extra_requests` (genérica, reutilizable para otros extras futuros):

| Campo | Tipo | Notas |
|-------|------|-------|
| id | uuid PK | default gen_random_uuid() |
| booking_id | uuid FK bookings | |
| property_id | uuid FK properties | para filtrar por propiedad |
| user_id | uuid | huésped (auth.uid) |
| guest_name | text | nombre del huésped |
| unit_name | text null | nombre de la unidad (si disponible) |
| extra_type | text | ej. `romantic_pack` |
| extra_name | text | ej. `Pack Romántico Básico` |
| price | numeric null | precio mostrado (informativo) |
| status | text default `requested` | `requested` \| `managed` \| `cancelled` |
| notes | text null | notas internas del admin |
| created_at | timestamptz default now() | |
| managed_at | timestamptz null | |
| managed_by | uuid null | admin que la gestionó |

**RLS** (patrón idéntico a `checkins`):
- Huésped: `INSERT`/`SELECT` propias (booking pertenece a su `auth.uid()` vía `bookings.primary_guest_user_id`).
- Staff/admin: `SELECT`/`UPDATE` por propiedad (`is_staff()` + property match, o `is_admin()`).

**Migración**: `supabase/migrations/<ts>_create_extra_requests.sql` (+ ROLLBACK).

## Aviso al admin

Desde el flujo del huésped, al crear la solicitud, llamar a
`NotificationService().notifyAdmins(...)`:
- `type`: `extra_request`
- `title`: `💝 Nueva solicitud: Pack Romántico`
- `body`: `{guest} ha solicitado el Pack Romántico en {unit}`

Aparece en la sección de notificaciones del admin + push FCM (infra ya existente).

> Decisión: se usa `notifyAdmins` desde cliente (no trigger backend) porque el
> huésped SIEMPRE pasa por el mismo botón (una sola pantalla), a diferencia del
> check-in que se validaba desde 2 pantallas admin. Menos complejidad y riesgo.

## Capa de datos (Flutter)

- `lib/features/guest/extras/data/models/extra_request_model.dart` (Freezed + JSON).
- `lib/features/guest/extras/domain/repositories/extra_request_repository.dart` (contrato):
  `create()`, `getAll({propertyId})`, `watchAll({propertyId})`, `markAsManaged(id)`.
- `lib/features/guest/extras/data/repositories/extra_request_repository_impl.dart`.
- Registrar en DI (`injection.dart`).

## Huésped (solicitud)

- En `romantic_pack_screen.dart` `_showPurchaseDialog`:
  1. Al confirmar: leer `context.read<AuthBloc>()` → `bookingId`, `propertyId`, `displayName`.
  2. `create()` la solicitud + `notifyAdmins(...)`.
  3. Abrir la web externa (se mantiene) **y** mostrar confirmación amable:
     "Hemos avisado al alojamiento; te contactarán para confirmar los detalles."
  4. Si falta `bookingId`/`propertyId` → registrar sin fallar (o avisar).

## Admin (listado con seguimiento)

- Nueva feature `lib/features/admin/extras/`:
  - `bloc/` (ExtrasRequestsBloc: cargar, refrescar, marcar gestionada).
  - `presentation/screens/extra_requests_screen.dart` (listado).
  - `presentation/widgets/extra_request_card.dart` (item con badge de estado
    `IntrinsicWidth` + `Align`, según regla de badges).
  - Acción "Marcar como gestionada" → `markAsManaged`.
- Añadir entrada en el menú/dashboard admin + ruta en el router.
- (Opcional) Realtime sobre `extra_requests` para que aparezcan en vivo (patrón ya usado).

## i18n

Nuevas claves en `app_es.arb` (+ en, fr, it, de, pt): confirmación al huésped,
título/estados del listado admin, textos de la notificación.

## Checklist proyecto

- [ ] Migración SQL (+ROLLBACK) tabla + RLS (+ realtime opcional)
- [ ] Model Freezed + contrato + impl + DI
- [ ] Flujo huésped (create + notifyAdmins + confirmación)
- [ ] Feature admin (bloc + pantalla + card + ruta + menú)
- [ ] i18n en todos los idiomas
- [ ] `build_runner` + `dart fix --apply` + `dart analyze` (0 warnings)
- [ ] Tests 85%+ (bloc huésped/admin, repo)

## Fuera de alcance

- Pasarela de pago dentro de la app (sigue siendo la web externa).
- Estados de pago (no podemos conocerlos). Solo `requested`/`managed`/`cancelled`.
