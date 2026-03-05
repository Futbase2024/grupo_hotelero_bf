# Edge Function: send-fcm-notifications

Procesa la cola de notificaciones (`notification_queue`) y envía push notifications a Firebase Cloud Messaging (FCM).

## Configuración de Secrets

Antes de deployar, necesitas configurar los secrets de Firebase en Supabase:

### 1. Obtener Service Account de Firebase

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto
3. Ve a **Project Settings** > **Service accounts**
4. Haz clic en **Generate new private key**
5. Guarda el archivo JSON de forma segura

### 2. Configurar Secrets en Supabase

Usa la CLI de Supabase para configurar los secrets:

```bash
# Configurar secrets (reemplaza con tus valores)
supabase secrets set FIREBASE_PROJECT_ID=tu-project-id

supabase secrets set FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@tu-project-id.iam.gserviceaccount.com

supabase secrets set FIREBASE_PRIVATE_KEY="$(cat firebase-key.json | jq -r '.private_key')"

# Opcional: API secret para autorización
supabase secrets set FCM_API_SECRET=tu-api-secret-personalizado
```

### 3. Deployar la Edge Function

```bash
# Desde la raíz del proyecto
supabase functions deploy send-fcm-notifications
```

### 4. Configurar pg_cron (procesamiento automático)

Ejecuta este SQL en el editor de Supabase:

```sql
-- Procesar notificaciones cada minuto
SELECT cron.schedule(
  'process-fcm-notifications',
  '* * * * *',
  $$
  SELECT net.http_post(
    url := 'https://qwepisgdqlmqfxwqkztz.supabase.co/functions/v1/send-fcm-notifications',
    headers := '{"Content-Type": "application/json"}'::jsonb,
    body := '{}'::jsonb
  );
  $$
);
```

## Uso Manual

Para procesar notificaciones manualmente:

```bash
curl -X POST \
  'https://qwepisgdqlmqfxwqkztz.supabase.co/functions/v1/send-fcm-notifications' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer tu-api-secret' \
  -d '{}'
```

## Estructura de la Cola

La tabla `notification_queue` debe tener:

| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | uuid | ID único |
| user_id | uuid | Usuario destinatario |
| token | text | Token FCM del dispositivo |
| title | text | Título de la notificación |
| body | text | Cuerpo del mensaje |
| data | jsonb | Datos adicionales |
| processed | boolean | Si ya fue procesado |
| processed_at | timestamp | Cuándo se procesó |
| error | text | Error si falló |
