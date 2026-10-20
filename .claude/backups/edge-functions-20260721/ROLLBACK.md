# Punto de restauración — Edge Functions de email (2026-07-21)

Backup del código **original desplegado** de las 6 Edge Functions de email ANTES del
cambio de remitente al dominio autenticado `grupohotelerobf.com` + Reply-To + BCC.

## Estado original (lo que había antes del cambio)

| Función | Versión previa | Sender original | verify_jwt |
|---|---|---|---|
| send-new-booking-email        | 24 | ghotelerobf@gmail.com | false |
| send-checkin-email            | 32 | ghotelerobf@gmail.com | false |
| send-early-checkin-email      | 19 | ghotelerobf@gmail.com | false |
| send-cancellation-email       | 18 | noreply@bf-stay.app   | false |
| send-checkin-cancellation-email | 18 | noreply@bf-stay.app | false |
| send-access-code-email        | 18 | noreply@bf-stay.app   | false |

Project ID Supabase: `qwepisgdqlmqfxwqkztz`

## Cambios aplicados el 2026-07-21

1. **Sender** unificado al dominio autenticado en Brevo:
   - `send-new-booking-email` → `reservas@grupohotelerobf.com`
   - Las otras 5 → `info@grupohotelerobf.com`
2. **Reply-To**: `ghotelerobf@gmail.com` (las respuestas del huésped llegan al Gmail).
3. **BCC**: `ghotelerobf@gmail.com` (copia oculta de cada correo enviado).

Motivo: los remitentes anteriores (`@gmail.com` y `@bf-stay.app`) NO están autenticados
en Brevo, fallaban SPF/DKIM/DMARC y el relay `@guest.booking.com` los retenía
(greylisting), por eso "había que enviar varias veces". `grupohotelerobf.com` sí está
autenticado en Brevo.

## Cómo volver atrás (rollback)

Cada archivo `*.index.ts` de esta carpeta es el `index.ts` original de su función.
Para restaurar una función, redesplegar su archivo con `verify_jwt: false`:

- deploy_edge_function(project_id="qwepisgdqlmqfxwqkztz", name="<slug>",
  entrypoint_path="index.ts", verify_jwt=false, files=[{name:"index.ts", content: <contenido del backup>}])

O pídeselo a Claude: "restaura las edge functions de email desde el backup
edge-functions-20260721".
