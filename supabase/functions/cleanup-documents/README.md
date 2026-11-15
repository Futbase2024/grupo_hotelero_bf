# Edge Function: cleanup-documents

Borra del bucket `guest-documents` las imágenes de DNI / NIE / pasaporte cuyo
plazo ha vencido y marca la fila de `guest_documents` con `deleted_at` y
`deleted_reason`. La fila se conserva como constancia; los datos del huésped
(nombre, número de documento, etc.) siguen en `guests`.

## Reglas de borrado

Definidas en SQL (`booking_documents_deletion_schedule`):

| Situación | Cuándo se borra | `deleted_reason` |
|---|---|---|
| Check-in validado | 24 h después de `checkins.validated_at` | `validated_24h` |
| Reserva cancelada | En la siguiente pasada | `booking_cancelled` |
| Nunca validada ni cancelada | Al día siguiente del `checkout_date` (Madrid) | `checkout_not_validated` |
| Retención activa (`booking_document_retentions`) | Nunca, hasta quitarla | — |
| Botón "Eliminar ahora" del panel | Al momento (lo hace la app) | `manual` |
| Archivo sin fila en `guest_documents` (huérfano) | Pasadas 24 h desde la subida | — (no hay fila) |

⚠️ Una imagen borrada **no se puede recuperar** (las copias de seguridad de
Supabase no incluyen el Storage). Si hay una incidencia, activar la retención
en el detalle del check-in antes de que venza el plazo.

## Ejecución

- pg_cron, job `cleanup-guest-documents`, cada 15 min
  (migración `20261115100100_schedule_guest_documents_cleanup.sql`).
- Hasta 1000 documentos por pasada.
- Autenticación: cabecera `x-internal-secret` (Vault `internal_functions_secret`)
  o la service role. Cualquier otra llamada devuelve 401.

## Despliegue

```bash
supabase functions deploy cleanup-documents --no-verify-jwt
```
