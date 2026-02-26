# Plan de Implementación: Panel de Administración BF-Stay

## Resumen
Implementar el panel de administración completo para staff y admin, incluyendo gestión de reservas, check-ins, propiedades y notificaciones en tiempo real.

## Estado Actual
- ✅ `AdminLoginBottomSheet` - Login con email + password
- ✅ `LogoTapTrigger` - Acceso oculto con 5 taps
- ✅ Sistema de autenticación con roles
- ✅ `StaffDashboardScreen` básico (mock)
- ✅ Design system (`AppColors`, `AppTheme`)

## Fases de Implementación

### FASE 1: Infraestructura Base
**Archivos a crear/modificar:**

1. `lib/features/admin/shared/status_badge.dart`
   - Widget de badge de estado coloreado
   - Variantes: confirmed, checked_in, checked_out, cancelled, draft, submitted, validated, rejected

2. `lib/features/admin/shared/bf_code_display_widget.dart`
   - Widget para mostrar código BF destacado
   - Botones de copiar y compartir

3. `lib/features/admin/shared/empty_state_widget.dart`
   - Estado vacío reutilizable para listas

4. `lib/features/admin/shared/confirmation_dialog.dart`
   - Diálogo de confirmación para acciones destructivas

5. `lib/features/admin/shared/booking_list_tile.dart`
   - Tile de reserva para listas

### FASE 2: Repository y BLoC
**Archivos a crear:**

1. `lib/features/admin/domain/repositories/admin_panel_repository.dart`
   - Contrato del repositorio admin
   - Métodos: listBookings, createBooking, regenerateCode, validateCheckin, rejectCheckin, listUnits, getNotifications

2. `lib/features/admin/data/repositories/admin_panel_repository_impl.dart`
   - Implementación que llama a Edge Functions
   - POST /functions/v1/admin-panel
   - POST /functions/v1/admin-login

3. `lib/features/admin/domain/entities/admin_booking_entity.dart`
   - Entity para reservas con datos completos

4. `lib/features/admin/domain/entities/admin_checkin_entity.dart`
   - Entity para check-ins

5. `lib/features/admin/domain/bloc/admin_dashboard_bloc.dart`
   - BLoC para estado del dashboard
   - Eventos: LoadDashboard, RefreshDashboard, ChangeTab
   - Estados: Initial, Loading, Loaded, Error

6. `lib/features/admin/domain/bloc/bookings_bloc.dart`
   - BLoC para gestión de reservas
   - CRUD completo + filtros

7. `lib/features/admin/domain/bloc/checkins_bloc.dart`
   - BLoC para gestión de check-ins
   - Validar/Rechazar check-ins

### FASE 3: Dashboard Principal
**Archivos a crear:**

1. `lib/features/admin/dashboard/admin_dashboard_screen.dart`
   - Shell con BottomNavigationBar
   - 4 tabs: Resumen, Reservas, Check-ins, Alojamientos
   - Tab "Alojamientos" solo visible para admin

2. `lib/features/admin/dashboard/dashboard_tab.dart`
   - Tab de resumen con stat_cards
   - Lista de últimos check-ins
   - Greeting según hora del día

3. `lib/features/admin/dashboard/widgets/stat_card.dart`
   - Tarjeta de estadística reutilizable

### FASE 4: Gestión de Reservas
**Archivos a crear:**

1. `lib/features/admin/bookings/bookings_tab.dart`
   - Lista filtrable de reservas
   - Search bar
   - Filter chips

2. `lib/features/admin/bookings/create_booking_bottom_sheet.dart`
   - Formulario de 2 pasos
   - Paso 1: Datos del huésped + reserva
   - Paso 2: Confirmación + código generado

3. `lib/features/admin/bookings/booking_detail_screen.dart`
   - Detalle completo de reserva
   - Acciones: regenerar código, cancelar
   - Sección de check-in si existe

### FASE 5: Gestión de Check-ins
**Archivos a crear:**

1. `lib/features/admin/checkins/checkins_tab.dart`
   - Lista filtrable de check-ins
   - Estados: draft, submitted, validated, rejected

2. `lib/features/admin/checkins/rejection_reason_sheet.dart`
   - BottomSheet para motivo de rechazo

3. `lib/features/admin/checkins/widgets/checkin_progress_steps.dart`
   - Barra de progreso visual del check-in

### FASE 6: Gestión de Propiedades (Solo Admin)
**Archivos a crear:**

1. `lib/features/admin/properties/properties_tab.dart`
   - Lista de propiedades
   - Solo visible para admin

2. `lib/features/admin/properties/property_detail_screen.dart`
   - Detalle de propiedad
   - Lista de unidades

3. `lib/features/admin/properties/create_unit_bottom_sheet.dart`
   - Formulario para crear unidad

### FASE 7: Notificaciones
**Archivos a crear:**

1. `lib/features/admin/notifications/notifications_screen.dart`
   - Lista de notificaciones
   - Suscripción Realtime a staff_notifications

2. `lib/features/admin/notifications/notification_tile.dart`
   - Tile de notificación

3. `lib/features/admin/notifications/notifications_bloc.dart`
   - BLoC con stream de Realtime

### FASE 8: Routing y DI
**Archivos a modificar:**

1. `lib/core/router/app_router.dart`
   - Añadir rutas `/admin/*`
   - Configurar redirect por rol

2. `lib/core/di/injection.dart`
   - Registrar nuevos repositories y BLoCs

## Orden de Implementación
1. Componentes compartidos (FASE 1)
2. Repository + Entities (FASE 2)
3. Dashboard principal (FASE 3)
4. Reservas (FASE 4) - Flujo más importante
5. Check-ins (FASE 5)
6. Propiedades (FASE 6)
7. Notificaciones (FASE 7)
8. Routing y DI (FASE 8)

## Notas Técnicas
- Usar BLoC + Freezed para estados/eventos
- Colores de `AppColors` (no hardcodear)
- Cupertino widgets según CLAUDE.md
- Ejecutar `dart fix --apply && dart analyze` después de cada archivo
- Conexión a Supabase via MCP o Edge Functions

## Dependencias Necesarias
- `timeago` para fechas relativas
- `share_plus` para compartir código
- `flutter_secure_storage` para tokens admin

## Tablas Supabase
- `properties` - Propiedades
- `units` - Unidades/Alojamientos
- `bookings` - Reservas
- `guests` - Huéspedes
- `checkins` - Check-ins
- `staff_notifications` - Notificaciones (crear si no existe)
