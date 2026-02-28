# Plan: Flujo Completo de Reservas y Check-in/Check-out

## Objetivo
Implementar el sistema completo de estados para gestionar el ciclo de vida de reservas, check-in y check-out.

---

## Estados Propuestos

### 1. BookingStatus (booking_status)
```
created    → Admin creó la reserva (nuevo)
active     → Check-in validado, estancia habilitada (nuevo)
confirmed  → Reserva confirmada (existente, mantener para compatibilidad)
checked_in → Check-in realizado (existente)
checked_out → Check-out realizado (existente)
closed     → Admin cerró tras validar check-out (nuevo)
cancelled  → Reserva cancelada (existente)
```

**Para MVP**: Simplificar a:
- `created` → `active` → `closed` (+ `cancelled`)

### 2. CheckinStatus (checkin_status)
```
not_started  → Sin iniciar (nuevo)
in_progress  → Huésped rellenando datos (nuevo, antes era draft)
submitted    → Enviado, pendiente de validación (existente)
validated    → Validado por admin (existente)
rejected     → Rechazado, necesita corrección (existente)
```

### 3. CheckoutStatus (checkout_status) - NUEVO
```
not_started  → Sin iniciar
requested    → Huésped solicitó check-out
validated    → Admin validó el check-out
rejected     → Hay incidencias/datos faltantes
```

---

## Campos Adicionales Necesarios

### En tabla `bookings`
```sql
-- Cambiar status a enum más granular
booking_status TEXT DEFAULT 'created' CHECK (booking_status IN ('created', 'active', 'closed', 'cancelled'))

-- Nuevo campo para check-out
checkout_status TEXT DEFAULT 'not_started' CHECK (checkout_status IN ('not_started', 'requested', 'validated', 'rejected'))

-- Timestamps adicionales
activated_at TIMESTAMPTZ
closed_at TIMESTAMPTZ
checkout_requested_at TIMESTAMPTZ
checkout_validated_at TIMESTAMPTZ

-- Notas
validation_notes TEXT
checkout_notes TEXT
```

### En tabla `checkins`
```sql
-- Ya tiene la mayoría, solo añadir:
in_progress_at TIMESTAMPTZ  -- Cuando empezó a rellenar
```

---

## Fases de Implementación

### FASE 1: Migración de Base de Datos
- [ ] Crear migración para nuevos campos en `bookings`
- [ ] Crear migración para nuevos campos en `checkins`
- [ ] Crear función RPC `update_booking_status()`
- [ ] Crear función RPC `request_checkout()`
- [ ] Crear función RPC `validate_checkout()`
- [ ] Migrar datos existentes al nuevo sistema de estados

### FASE 2: Entidades y Enums
- [ ] Crear `lib/core/enums/booking_status.dart`
- [ ] Crear `lib/core/enums/checkin_status.dart`
- [ ] Crear `lib/core/enums/checkout_status.dart`
- [ ] Actualizar `AdminBookingEntity` con nuevos campos
- [ ] Actualizar `CheckinDetailEntity` con nuevos campos
- [ ] Crear `CheckoutDetailEntity` (nueva)

### FASE 3: Repositorio
- [ ] Añadir método `activateBooking(bookingId)` al repositorio
- [ ] Añadir método `closeBooking(bookingId, notes)` al repositorio
- [ ] Añadir método `requestCheckout(bookingId)` al repositorio
- [ ] Añadir método `validateCheckout(bookingId, notes)` al repositorio
- [ ] Añadir método `rejectCheckout(bookingId, reason)` al repositorio

### FASE 4: Lógica de Acceso por Estado
- [ ] Crear `lib/core/guards/booking_access_guard.dart`
- [ ] Implementar reglas de acceso:
  - `canAccessPanel()`: checkin_status = validated AND booking_status = active
  - `canDoCheckin()`: checkin_status in [not_started, in_progress, rejected]
  - `canRequestCheckout()`: checkin_status = validated AND booking_status = active
  - `isReadOnly()`: booking_status = closed

### FASE 5: UI Admin
- [ ] Actualizar `BookingDetailScreen` con nuevos estados y acciones
- [ ] Añadir botón "Activar Reserva" (created → active)
- [ ] Añadir sección "Check-out" con validación
- [ ] Actualizar `CheckinDetailScreen` con timestamps
- [ ] Actualizar `DashboardTab` con nuevos filtros de estado

### FASE 6: UI Guest
- [ ] Actualizar `GuestHomeScreen` para mostrar estado actual
- [ ] Crear `CheckoutScreen` para solicitud de check-out
- [ ] Implementar acceso condicional según estados
- [ ] Añadir vista histórica para reservas cerradas

### FASE 7: Notificaciones
- [ ] Implementar notificación cuando check-in es validado
- [ ] Implementar notificación cuando check-in es rechazado
- [ ] Implementar notificación cuando check-out es validado

---

## Reglas de Acceso (Resumen)

| Estado | Acceso Huésped |
|--------|----------------|
| `booking_status = created` | Solo pantalla "Introducir código" |
| `checkin_status = not_started` | Ver bienvenida + botón iniciar check-in |
| `checkin_status = in_progress` | Formulario check-in + subida docs |
| `checkin_status = submitted` | Ver progreso + mensajes admin |
| `checkin_status = rejected` | Modo subsanación (corregir datos) |
| `checkin_status = validated` AND `booking_status = active` | **Panel completo** (recomendaciones, parking, chat, etc.) |
| `checkout_status = requested` | Panel activo + mensaje "salida en curso" |
| `booking_status = closed` | Solo histórico + reseña |

---

## Diagrama de Flujo Completo

```
┌─────────────────────────────────────────────────────────────────────┐
│                         ADMIN                                        │
├─────────────────────────────────────────────────────────────────────┤
│  [Crear Reserva]                                                     │
│       │                                                              │
│       ▼                                                              │
│  booking_status = created                                            │
│  checkin_status = not_started                                        │
│  checkout_status = not_started                                       │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         HUÉSPED                                      │
├─────────────────────────────────────────────────────────────────────┤
│  [Entra con código]                                                  │
│       │                                                              │
│       ▼                                                              │
│  checkin_status = in_progress                                        │
│       │                                                              │
│       ▼ (Rellena datos + docs)                                       │
│       │                                                              │
│       ▼                                                              │
│  checkin_status = submitted                                          │
│       │                                                              │
│       │ (Acceso limitado: ver progreso, subir docs, normas)          │
└───────┴─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         ADMIN                                        │
├─────────────────────────────────────────────────────────────────────┤
│       │                                                              │
│       ├──────────────────────┬───────────────────────────────────────┤
│       ▼                      ▼                                       │
│  [Validar]               [Rechazar]                                  │
│       │                      │                                       │
│       ▼                      ▼                                       │
│  checkin_status          checkin_status                              │
│    = validated             = rejected                                │
│       │                      │                                       │
│       ▼                      │                                       │
│  booking_status            │                                         │
│    = active                │                                         │
│       │                    │                                         │
│       │    ┌───────────────┘                                         │
│       │    │  (Huésped corrige)                                      │
│       │    └──────────────► checkin_status = submitted               │
│       │                                                              │
└───────┴─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    HUÉSPED (Panel Completo)                          │
├─────────────────────────────────────────────────────────────────────┤
│  Acceso completo si:                                                 │
│  - checkin_status = validated                                        │
│  - booking_status = active                                           │
│                                                                      │
│  Funciones disponibles:                                              │
│  - Recomendaciones / Qué ver                                         │
│  - Parking                                                           │
│  - Chat con admin                                                    │
│  - Normas de la casa                                                 │
│  - Solicitar check-out                                               │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼ (Huésped solicita check-out)
┌─────────────────────────────────────────────────────────────────────┐
│                         HUÉSPED                                      │
├─────────────────────────────────────────────────────────────────────┤
│  [Solicitar Check-out]                                               │
│       │                                                              │
│       ▼                                                              │
│  checkout_status = requested                                         │
│       │                                                              │
│       │ (Panel sigue activo pero en modo "salida en curso")          │
└───────┴─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         ADMIN                                        │
├─────────────────────────────────────────────────────────────────────┤
│       │                                                              │
│       ├──────────────────────┬───────────────────────────────────────┤
│       ▼                      ▼                                       │
│  [Validar]               [Rechazar]                                  │
│  (todo OK)               (incidencias)                               │
│       │                      │                                       │
│       ▼                      ▼                                       │
│  checkout_status         checkout_status                             │
│    = validated             = rejected                                │
│       │                      │                                       │
│       ▼                      │                                       │
│  booking_status            │                                         │
│    = closed                │                                         │
│       │                    │                                         │
│       │    ┌───────────────┘                                         │
│       │    │  (Resolver incidencias)                                 │
│       │    └──────────────► checkout_status = requested              │
└───────┴─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    HUÉSPED (Modo Histórico)                          │
├─────────────────────────────────────────────────────────────────────┤
│  booking_status = closed                                             │
│                                                                      │
│  Acceso limitado:                                                    │
│  - Ver resumen de estancia                                           │
│  - Dejar reseña                                                      │
│  - Descargar factura (si aplica)                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Archivos a Crear/Modificar

### Nuevos
```
lib/core/enums/
├── booking_status.dart
├── checkin_status.dart
└── checkout_status.dart

lib/core/guards/
└── booking_access_guard.dart

lib/features/guest/checkout/
├── data/
│   └── repositories/
│       └── checkout_repository_impl.dart
├── domain/
│   └── repositories/
│       └── checkout_repository.dart
├── presentation/
│   ├── bloc/
│   │   ├── checkout_bloc.dart
│   │   ├── checkout_event.dart
│   │   └── checkout_state.dart
│   └── screens/
│       └── checkout_screen.dart

supabase/migrations/
├── 20260228000000_add_booking_checkout_status.sql
└── 20260228010000_add_checkout_rpc_functions.sql
```

### Modificar
```
lib/features/admin/
├── domain/
│   └── entities/
│       ├── admin_booking_entity.dart      # Añadir nuevos campos
│       └── checkin_detail_entity.dart     # Añadir in_progress_at
├── domain/
│   └── repositories/
│       └── admin_panel_repository.dart    # Añadir métodos checkout
├── data/
│   └── repositories/
│       └── admin_panel_repository_impl.dart
└── presentation/
    ├── screens/
    │   └── booking_detail_screen.dart     # Añadir sección checkout
    └── widgets/
        └── checkins_tab.dart              # Actualizar filtros

lib/features/guest/
└── home/
    └── presentation/
        └── screens/
            └── guest_home_screen.dart     # Lógica de acceso condicional
```

---

## Prioridad de Implementación

### MVP (Fase 1) - Lo esencial
1. Migración de base de datos con nuevos estados
2. Enums formales en Flutter
3. Actualización de entidades
4. Lógica de acceso básica (guard)
5. UI Admin: activar reserva, validar check-out

### Fase 2 - Experiencia completa
1. UI Guest: acceso condicional según estados
2. Pantalla de check-out para huésped
3. Vista histórica para reservas cerradas
4. Notificaciones

### Fase 3 - Pulido
1. Animaciones de transición entre estados
2. Estadísticas de estados en dashboard
3. Exportación de datos de reservas cerradas
