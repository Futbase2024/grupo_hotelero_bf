# Plan: Ralentización progresiva de la app (BF Stay)

> **Fecha**: 2026-07-10
> **Estado**: Pendiente de aprobación
> **Prioridad**: Alta
> **Origen**: Reportes de usuarios de que la app va "poco a poco más lenta conforme pasa el tiempo"
> **Confirmado por el owner**: el síntoma se da **ambas cosas** → dentro de una sesión larga Y degradación general semana a semana.

---

## 🔎 Diagnóstico (basado en evidencia, no en suposiciones)

Investigación realizada: advisors de rendimiento de Supabase, tamaños/bloat de todas las tablas, jobs de `pg_cron`, y auditoría de fugas de recursos en todo `lib/`.

### Lo que se DESCARTÓ como causa
- ❌ **Advertencias de seguridad** (search_path, SECURITY DEFINER, buckets públicos) → no afectan al rendimiento.
- ❌ **Volumen de datos de negocio** → tablas minúsculas: `bookings` 582 filas, `messages` 683, `users` 510, `checkins` 582. Ninguna query se degrada por volumen.
- ❌ **Fugas de Realtime / StreamSubscription / BLoC / Timer en Flutter** → auditadas en todo `lib/`; se cierran correctamente (`ChatBloc`, `ConversationsBloc`, `AdminDashboardBloc`, etc.).

### Causas REALES confirmadas (ordenadas por impacto)

| # | Causa | Evidencia | Naturaleza |
|---|-------|-----------|-----------|
| **1** | **RLS mal optimizado** | 167 avisos `multiple_permissive_policies` + 73 `auth_rls_initplan` | Constante — lastra CADA query de todos los usuarios |
| **2** | **Bloat por notificaciones (pg_net)** | `net._http_response` = **59 MB con solo 180 filas** | Progresivo — crece con el tiempo, degrada el instance |
| **3** | **Historial de cron sin purgar** | `cron.job_run_details` = **51.929 filas / 18 MB** desde 29-abr (~720/día) | Progresivo — crecimiento ilimitado |
| **4** | **Índices** | 14 FK sin índice + 1 índice duplicado + 40 índices sin uso | Constante — coste extra en lecturas/escrituras |
| **5** | **Cliente (menor)** | `TextEditingController` de diálogos sin `dispose()`, Sets en memoria en chat | Progresivo intra-sesión (impacto bajo) |

> **Por qué "ambas cosas" encaja**: la causa #1 (RLS) hace que TODO vaya lento siempre; las causas #2 y #3 hacen que el instance de Postgres se degrade poco a poco con el uso (bloat + historial), lo que se percibe como "cada semana peor". La #5 explica la parte intra-sesión leve.

---

## 🎯 Objetivo

Devolver la app a rendimiento fluido y **evitar** que se vuelva a degradar con el tiempo, atacando tanto lo constante (RLS, índices) como lo progresivo (bloat, historial de cron, acumulación en cliente).

---

## 📅 Fases de ejecución

Cada fase es independiente y reversible. Nada se ejecuta sin autorización explícita del owner. Toda la parte SQL irá en **migraciones** (`supabase/migrations/`), nunca ejecutada suelta contra producción.

### FASE 1 — Limpieza inmediata del bloat progresivo 🟢 (rápido, bajo riesgo, alto alivio)

Ataca las causas #2 y #3. Es lo que provoca el "cada vez peor". Efecto casi inmediato.

**1.1 Purgar y desinflar `net._http_response`** (59 MB → ~KB)
```sql
-- Recupera los 59 MB de bloat que autovacuum no libera.
-- VACUUM FULL bloquea la tabla brevemente; es de pg_net (respuestas HTTP), no afecta datos de negocio.
VACUUM FULL net._http_response;
```

**1.2 Purgar historial de `pg_cron`** (51.929 filas) y automatizar la purga
```sql
-- Purga puntual del historial acumulado
DELETE FROM cron.job_run_details WHERE end_time < now() - interval '7 days';

-- Cron nuevo: purga automática semanal para que no vuelva a crecer sin límite
SELECT cron.schedule(
  'purge-cron-history',
  '0 3 * * 0',
  $$DELETE FROM cron.job_run_details WHERE end_time < now() - interval '7 days';$$
);
```

**1.3 Cron nuevo: mantener a raya `net._http_response`**
```sql
-- pg_net acumula respuestas; purga las viejas cada hora para que no vuelva el bloat.
SELECT cron.schedule(
  'purge-net-responses',
  '0 * * * *',
  $$DELETE FROM net._http_response WHERE created < now() - interval '6 hours';$$
);
```

**1.4 (A DECIDIR) Revisar la frecuencia del cron de FCM cada 2 min** (jobid 1)
- Actualmente `*/2 * * * *` → 720 ejecuciones/día llamando a la edge function `send-fcm-notifications`.
- Es la fuente del bloat de pg_net. **No lo cambiaré sin tu OK** porque afecta a la latencia de las notificaciones push.
- Opciones a valorar: mantener 2 min (con purga de 1.3 basta), o subir a 5 min si la latencia de notificación lo permite.

> ⚠️ Decisión pendiente del owner: ¿mantenemos 2 min o lo relajamos?

---

### FASE 2 — Optimización de RLS 🟠 (mayor impacto en velocidad, riesgo medio, requiere cuidado)

Ataca la causa #1. Es lo que más acelera cada query. Se hará en **dos sub-fases** por seguridad, porque tocar RLS puede alterar accesos.

**2.1 `auth_rls_initplan` (73 políticas) — cambio mecánico, sin cambio de semántica**
- Transformar `auth.uid()` → `(select auth.uid())` y `current_setting(...)` → `(select current_setting(...))` en cada política.
- Esto hace que Postgres evalúe la función **una vez por query** en lugar de **una vez por fila**. Mismo resultado de acceso, mucho más rápido.
- Tablas afectadas (nº de políticas): `fcm_tokens` (7), `profiles` (6), `staff_notifications` (4), `guest_notifications` (4), `conversation_participants` (4), `guest_documents` (4), `messages` (3), `bookings` (3), `checkins` (3), `booking_guests` (3), `user_roles` (3), `conversations` (3), `guests` (3), y ~15 tablas más con 1-2.
- **Procedimiento**: volcar la definición actual de cada política (`pg_policies`), generar el `ALTER/DROP+CREATE POLICY` equivalente con el wrap, revisar diff, aplicar por migración.

**2.2 `multiple_permissive_policies` (167 avisos) — consolidación, requiere revisar intención**
- Varias políticas permisivas para el mismo rol+acción se evalúan TODAS por fila. Se consolidan en una sola política con condiciones `OR`.
- Mayores ofensores: `booking_guests` (15), `fcm_tokens` (15), `guests` (15), `profiles` (15), `bookings` (10), `checkins` (10), `guest_documents` (10), `incidents` (10), `user_roles` (10).
- **Riesgo**: hay que preservar exactamente quién puede ver/editar qué. Se hará tabla por tabla, documentando la lógica combinada antes de aplicar.
- **Validación obligatoria por tabla**: probar acceso con rol `anon`, huésped y staff/admin antes de dar por buena cada consolidación.

> Recomendación: aplicar **2.1 primero** (mecánico, sin riesgo) y medir mejora. Luego 2.2 tabla por tabla.

---

### FASE 3 — Índices 🟢 (bajo riesgo)

Ataca la causa #4.

**3.1 Crear índices en FKs sin cubrir** (14): `booking_guests.guest_id`, `email_logs.booking_id`, `guest_documents.uploaded_by`, `guest_notifications.booking_id`, `guide_items.property_id`, `guide_items.unit_id`, `incidents.booking_id`, `incidents.created_by`, `incidents.property_id`, `invoices.created_by`, `marketing_campaigns.created_by`, `payments.booking_id`, `place_collections.collection_id`, `properties.parent_property_id`.

**3.2 Eliminar índice duplicado**: en `conversation_participants` existen `idx_conversation_participants_user` e `idx_participants_user` idénticos → borrar uno.

**3.3 Revisar los 40 índices sin uso** (`unused_index`) — NO borrar a ciegas. Muchos pueden ser recientes (ej. `message_translations`, feature nueva) o usarse en picos. Listar y decidir uno a uno; los índices sin uso solo penalizan escrituras, no lecturas, así que es la prioridad más baja.

---

### FASE 4 — Cliente Flutter 🟢 (impacto bajo, pulido intra-sesión)

Ataca la causa #5.

**4.1 `dispose()` de `TextEditingController` de diálogos** (crear controller, usarlo en `showDialog`, liberarlo al cerrar). Archivos:
- `booking_detail_screen.dart` (líneas ~334, 910, 1032, 1153, 1309)
- `checkin_detail_screen.dart` (~840, 956)
- `invoice_detail_screen.dart` (~369)
- `login_screen.dart` (~513)
- Patrón: envolver en un `StatefulWidget` de diálogo con su `dispose`, o usar `.then((_) => controller.dispose())` tras `showDialog`.

**4.2 Acotar Sets en memoria del chat**: `emittedMessageIds` en `chat_datasource.dart:494` crece mientras el chat está abierto. Limitar tamaño o limpiar en chats muy largos.

**4.3 Cerrar suscripción `authStateChanges`** en `auth_bloc.dart:141` dentro de `close()` (impacto real bajo — AuthBloc vive toda la sesión — pero es higiene).

> Cada `.dart` modificado pasa por `dart fix --apply && dart analyze` (hook obligatorio del proyecto).

---

## ✅ Verificación tras cada fase

- **F1**: re-consultar tamaños (`pg_total_relation_size`) → `_http_response` y `job_run_details` deben caer drásticamente.
- **F2**: re-lanzar `get_advisors(performance)` → `auth_rls_initplan` y `multiple_permissive_policies` deben desaparecer/reducirse; probar accesos por rol.
- **F3**: `get_advisors` sin `unindexed_foreign_keys` ni `duplicate_index`.
- **F4**: `dart analyze` limpio; prueba manual de abrir/cerrar diálogos repetidamente.

## ↩️ Rollback
- SQL: cada migración con su `-- rollback` documentado (recrear política original, recrear índice, `cron.unschedule`).
- Flutter: cambios aislados por commit, revertibles con git.

---

## 🧭 Orden recomendado de ejecución

1. **FASE 1** (alivio inmediato del "cada vez peor", riesgo mínimo) ← empezar aquí
2. **FASE 2.1** (aceleración global mecánica, sin riesgo de acceso)
3. **FASE 3** (índices)
4. **FASE 2.2** (consolidación RLS, tabla por tabla con validación)
5. **FASE 4** (pulido cliente)

---

## ❓ Decisiones pendientes del owner antes de implementar

1. ¿Empezamos por **FASE 1** (limpieza/bloat) como quick-win?
2. Cron FCM cada 2 min: ¿lo **mantenemos** (con purga automática) o lo **relajamos** a 5 min?
3. FASE 2.2 (consolidación RLS): ¿la abordamos ahora o la dejamos como segunda oleada tras medir el efecto de 2.1?
