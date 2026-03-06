# Plan: Sistema de Notificaciones para Reservas y Check-ins

**Fecha**: 2025-03-05
**Estado**: Pendiente de implementación

---

## Resumen del Flujo

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           FLUJO DE NOTIFICACIONES                           │
└─────────────────────────────────────────────────────────────────────────────┘

1. ADMIN CREA RESERVA
   └──> Email al huésped (Brevo) con:
        - Código de acceso a la app
        - Datos de la reserva
        - Link de descarga

2. HUÉSPED HACE CHECK-IN
   └──> Notificación al ADMIN:
        - Push (FCM) si tiene la app
        - In-app notification (staff_notifications)
        - "El huésped X ha hecho check-in - Pendiente de revisión"

3. ADMIN REVISIONA CHECK-IN
   ├──> VALIDAR:
   │    └──> Notificación al HUÉSPED:
   │         - Push (FCM) si tiene la app
   │         - Email (Brevo) de confirmación
   │
   ├──> RECHAZAR:
   │    └──> Notificación al HUÉSPED:
   │         - Push (FCM) si tiene la app
   │         - Email (Brevo) de rechazo con motivo
   │
   └──> CANCELAR:
        └──> Notificación al HUÉSPED:
             - Push (FCM) si tiene la app
             - Email (Brevo) de cancelación
```

---

## Estado Actual del Sistema

### Ya Implementado
- ✅ `EmailService` con métodos para emails Brevo
- ✅ `FcmService` para manejar tokens y recibir notificaciones
- ✅ Edge Function `send-fcm-notifications` para procesar cola
- ✅ Tabla `notification_queue` para encolar notificaciones push
- ✅ Tabla `staff_notifications` para notificaciones in-app al admin
- ✅ Tabla `fcm_tokens` para almacenar tokens de dispositivos
- ✅ Validar check-in YA envía email de confirmación
- ✅ Email al crear reserva (Edge Function `send-new-booking-email` + EmailService)
- ✅ Notificación push + in-app al admin cuando huésped hace check-in
- ✅ Notificación push al huésped cuando admin valida/rechaza/cancela
- ✅ Email de rechazo cuando admin rechaza check-in
- ✅ Email de cancelación cuando admin cancela reserva

### Completado ✅
Todas las fases del sistema de notificaciones están implementadas.

---

## Plan de Implementación

### FASE 1: Email al Crear Reserva

#### 1.1 Crear Edge Function `send-booking-created-email`
**Archivo**: `supabase/functions/send-booking-created-email/index.ts`

```typescript
// Envía email cuando admin crea una reserva
// Usa plantilla de Brevo con parámetros:
// - nombre_huesped
// - nombre_propiedad
// - codigo_reserva
// - fecha_entrada
// - fecha_salida
// - link_app
```

#### 1.2 Añadir método a EmailService
**Archivo**: `lib/features/admin/domain/services/email_service.dart`

```dart
Future<bool> sendBookingCreatedEmail({
  required String toEmail,
  required String guestName,
  required String propertyName,
  required String unitName,
  required String bookingCode,
  required DateTime checkinDate,
  required DateTime checkoutDate,
});
```

#### 1.3 Modificar CreateBookingBottomSheet
**Archivo**: `lib/features/admin/bookings/presentation/sheets/create_booking_bottom_sheet.dart`

- Tras crear reserva exitosamente, enviar email al huésped
- Mostrar feedback si el email falla (no bloquear)

---

### FASE 2: Notificación al Admin cuando Huésped hace Check-in

#### 2.1 Crear servicio de notificaciones
**Archivo nuevo**: `lib/core/services/notification_service.dart`

```dart
class NotificationService {
  /// Encola notificación push para un usuario
  Future<void> queuePushNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  });

  /// Crea notificación in-app para staff/admin
  Future<void> createStaffNotification({
    required String type,
    required String title,
    required String body,
    String? bookingId,
    String? propertyId,
    Map<String, dynamic>? data,
  });

  /// Notifica a todos los admins de una propiedad
  Future<void> notifyAdmins({
    required String propertyId,
    required String title,
    required String body,
    String? bookingId,
    Map<String, dynamic>? data,
  });
}
```

#### 2.2 Modificar submit_checkin en Supabase
**Archivo**: Nueva migración o modificación de función RPC

- Añadir trigger o lógica en `submit_guest_checkin` para:
  1. Obtener property_id de la reserva
  2. Obtener todos los user_id con rol 'admin' para esa propiedad
  3. Para cada admin:
     - Crear registro en `staff_notifications`
     - Encolar notificación push en `notification_queue`

#### 2.3 Alternative: Modificar CheckinBloc en Flutter
**Archivo**: `lib/features/guest/checkin/presentation/bloc/checkin_bloc.dart`

- Tras `submitCheckin` exitoso, llamar a `NotificationService.notifyAdmins()`

---

### FASE 3: Notificaciones al Huésped tras Revisión del Admin

#### 3.1 Crear helper para notificar huésped
**Archivo**: `lib/core/services/notification_service.dart`

```dart
/// Notifica al huésped del cambio de estado de su check-in
Future<void> notifyGuestCheckinStatus({
  required String bookingId,
  required String status, // 'validated', 'rejected', 'cancelled'
  String? reason,
});
```

#### 3.2 Modificar CheckinDetailScreen

**Validar** (ya tiene email, añadir push):
```dart
Future<void> _validateCheckin() async {
  // 1. Validar en BD (ya existe)
  await _client.rpc('validate_checkin', ...);

  // 2. Enviar email (ya existe)
  await EmailService().sendCheckinConfirmationEmail(...);

  // 3. NUEVO: Enviar notificación push
  await NotificationService().notifyGuestCheckinStatus(
    bookingId: _checkinDetail!.bookingId,
    status: 'validated',
  );
}
```

**Rechazar** (añadir email + push):
```dart
Future<void> _showRejectDialog() async {
  // 1. Rechazar en BD (ya existe)
  await _client.rpc('reject_checkin', ...);

  // 2. NUEVO: Enviar email de rechazo
  await EmailService().sendCheckinRejectionEmail(...);

  // 3. NUEVO: Enviar notificación push
  await NotificationService().notifyGuestCheckinStatus(
    bookingId: _checkinDetail!.bookingId,
    status: 'rejected',
    reason: reasonController.text,
  );
}
```

**Cancelar** (añadir email + push):
```dart
Future<void> _showCancelDialog() async {
  // 1. Cancelar en BD (ya existe)
  await _client.rpc('cancel_checkin', ...);

  // 2. NUEVO: Enviar email de cancelación
  await EmailService().sendCheckinCancellationEmail(...);

  // 3. NUEVO: Enviar notificación push
  await NotificationService().notifyGuestCheckinStatus(
    bookingId: _checkinDetail!.bookingId,
    status: 'cancelled',
    reason: reasonController.text,
  );
}
```

---

### FASE 4: Edge Functions de Brevo (si no existen)

Verificar que existen las Edge Functions:
- `send-checkin-email` ✅ (confirmación)
- `send-checkin-cancellation-email` ❓ (verificar)
- `send-cancellation-email` ❓ (rechazo)
- `send-booking-created-email` ❌ (crear)

---

## Archivos a Crear/Modificar

### Nuevos
1. `lib/core/services/notification_service.dart` - Servicio centralizado de notificaciones
2. `supabase/functions/send-booking-created-email/index.ts` - Edge Function para email de nueva reserva
3. `supabase/migrations/20260305120000_add_checkin_notification_triggers.sql` - Triggers para notificaciones automáticas

### Modificar
1. `lib/features/admin/domain/services/email_service.dart` - Añadir `sendBookingCreatedEmail`
2. `lib/features/admin/bookings/presentation/sheets/create_booking_bottom_sheet.dart` - Enviar email tras crear
3. `lib/features/admin/checkins/presentation/screens/checkin_detail_screen.dart` - Añadir notificaciones push
4. `lib/features/guest/checkin/presentation/bloc/checkin_bloc.dart` - Notificar al admin tras check-in

---

## Consultas SQL Útiles

### Obtener tokens FCM de admins de una propiedad
```sql
SELECT ft.token
FROM fcm_tokens ft
JOIN user_roles ur ON ft.user_id = ur.user_id
WHERE ur.property_id = :property_id
  AND ur.role = 'admin'
  AND ft.is_active = true;
```

### Obtener token FCM del huésped de una reserva
```sql
SELECT ft.token
FROM fcm_tokens ft
JOIN bookings b ON b.primary_guest_user_id = ft.user_id
WHERE b.id = :booking_id
  AND ft.is_active = true;
```

---

## Testing

### Checklist de pruebas
- [ ] Admin crea reserva → Email llega al huésped
- [ ] Huésped hace check-in → Admin recibe notificación push
- [ ] Huésped hace check-in → Admin ve notificación in-app
- [ ] Admin valida → Huésped recibe push + email
- [ ] Admin rechaza → Huésped recibe push + email con motivo
- [ ] Admin cancela → Huésped recibe push + email

---

## Orden de Implementación Recomendado

1. **FASE 3** - Notificaciones al huésped (mayor impacto inmediato)
2. **FASE 2** - Notificación al admin cuando check-in
3. **FASE 1** - Email al crear reserva (completa el flujo inicial)
