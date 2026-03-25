# Plan: Reservas Multi-Unidad (Flutter)

## Objetivo
Permitir que una reserva incluya múltiples habitaciones (1-9) bajo un mismo código y huésped, con un solo check-in.

---

## Cambios en Base de Datos ✅ COMPLETADO

1. ✅ Tabla `booking_units` creada
2. ✅ Datos migrados desde `bookings.unit_id`
3. ✅ Vistas actualizadas (`booking_checkin_status`, `admin_bookings_dashboard`)
4. ✅ Columna `unit_id` eliminada de `bookings`

---

## Cambios en Flutter

### 1. Nueva Entidad: `BookingUnitEntity`
**Archivo**: `lib/features/admin/domain/entities/booking_unit_entity.dart`

```dart
class BookingUnitEntity {
  final String id;
  final String unitId;
  final String name;
  final String? unitType;
  final String? wifiNetwork;
  final String? wifiPassword;
  final String? boxCode;
  final String? accessInstructions;
}
```

### 2. Actualizar `AdminBookingEntity`
**Archivo**: `lib/features/admin/domain/entities/admin_booking_entity.dart`

Cambios:
- Añadir `List<BookingUnitEntity> units` (lista de todas las unidades)
- Añadir `int totalUnits` (número de habitaciones)
- Mantener campos individuales (`unitId`, `unitName`, etc.) como el primero para compatibilidad

### 3. Actualizar `CreateBookingBottomSheet`
**Archivo**: `lib/features/admin/bookings/presentation/sheets/create_booking_bottom_sheet.dart`

Cambios:
- Selector de unidades múltiple (checkbox para cada unidad)
- Mostrar contador de unidades seleccionadas
- Validar máximo 9 unidades

### 4. Actualizar `BookingDetailScreen`
**Archivo**: `lib/features/admin/bookings/presentation/screens/booking_detail_screen.dart`

Cambios:
- Mostrar lista de todas las unidades reservadas
- Información de WiFi por cada unidad
- Check-in unificado para todas las unidades

### 5. Actualizar `BookingListTile`
**Archivo**: `lib/features/admin/shared/widgets/booking_list_tile.dart`

Cambios:
- Mostrar badge con número de unidades si > 1
- Mostrar "X habitaciones" en lugar de una sola

### 6. Crear/Actualizar Repository
- Añadir métodos para gestionar `booking_units`
- `addUnitsToBooking(bookingId, unitIds)`
- `removeUnitFromBooking(bookingId, unitId)`

---

## Orden de Implementación

1. Crear `BookingUnitEntity`
2. Actualizar `AdminBookingEntity` con soporte multi-unidad
3. Actualizar `CreateBookingBottomSheet` para selección múltiple
4. Actualizar widgets de visualización (`BookingListTile`, `BookingDetailScreen`)
5. Actualizar repository para gestionar `booking_units`

---

## UI Ejemplo: Crear Reserva

```
┌────────────────────────────────────┐
│  Nueva Reserva                      │
├────────────────────────────────────┤
│  Huésped: [Juan García           ] │
│  Email:   [juan@email.com        ] │
│  ...                               │
├────────────────────────────────────┤
│  Habitaciones (selecciona hasta 9) │
│  ┌──────────────────────────────┐  │
│  │ ☑ Suite Deluxe (Hab. 101)    │  │
│  │ ☑ Habitación Estándar (205)  │  │
│  │ ☑ Habitación Estándar (206)  │  │
│  │ ☐ Habitación Estándar (207)  │  │
│  └──────────────────────────────┘  │
│  Seleccionadas: 3 habitaciones     │
├────────────────────────────────────┤
│         [Crear Reserva]            │
└────────────────────────────────────┘
```

## UI Ejemplo: Detalle de Reserva

```
┌────────────────────────────────────┐
│  Reserva BF-2024-001               │
│  Juan García - 3 habitaciones      │
├────────────────────────────────────┤
│  📍 Habitaciones:                  │
│  • Suite Deluxe (Hab. 101)         │
│    WiFi: Hotel_Guest / pass123     │
│  • Habitación Estándar (205)       │
│    WiFi: Hotel_Guest / pass123     │
│  • Habitación Estándar (206)       │
│    WiFi: Hotel_Guest / pass123     │
├────────────────────────────────────┤
│  [✓] Check-in (todas las unidades) │
└────────────────────────────────────┘
```
