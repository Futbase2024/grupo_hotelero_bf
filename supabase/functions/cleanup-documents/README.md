# Edge Function: cleanup-documents

Elimina automáticamente los documentos expirados del bucket `guest-documents` y de la tabla `guest_documents`.

## 📋 Requisitos

- Supabase CLI instalado (`npm install -g supabase`)
- Proyecto vinculado (`supabase link --project-ref qwepisgdqlmqfxwqkztz`)
- Service Role Key (se configura automáticamente en Supabase)

## 🚀 Despliegue

```bash
# Desde la raíz del proyecto
supabase functions deploy cleanup-documents
```

## ⚙️ Configuración del Scheduler (Plan Pro)

Para ejecutar automáticamente cada día a las 3:00 AM:

1. Ve a **Supabase Dashboard** → **Edge Functions** → **cleanup-documents**
2. Click en **"Add Schedule"**
3. Configura:
   - **Cron Expression**: `0 3 * * *` (todos los días a las 3:00 AM UTC)
   - **Timezone**: Europe/Madrid

## 🔐 Protección con Secret (Opcional)

Para proteger la función con un secret:

1. Añade la variable de entorno:
   ```bash
   supabase secrets set CLEANUP_SECRET=tu_secreto_seguro_aqui
   ```

2. Al llamar la función, incluye el header:
   ```
   Authorization: Bearer tu_secreto_seguro_aqui
   ```

## 📞 Llamada Manual

### Sin secret:
```bash
curl -X POST \
  https://qwepisgdqlmqfxwqkztz.supabase.co/functions/v1/cleanup-documents \
  -H "Content-Type: application/json"
```

### Con secret:
```bash
curl -X POST \
  https://qwepisgdqlmqfxwqkztz.supabase.co/functions/v1/cleanup-documents \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer tu_secreto_seguro_aqui"
```

### Desde Flutter:
```dart
final response = await SupabaseConfig.client.functions.invoke(
  'cleanup-documents',
);

print('Eliminados: ${response.data['deleted_count']}');
```

## 📊 Respuesta

```json
{
  "success": true,
  "timestamp": "2026-02-28T10:00:00.000Z",
  "deleted_count": 5,
  "error_count": 0,
  "details": [
    {
      "id": "uuid",
      "path": "guests/booking-id/guest-id/dni/file.jpg",
      "status": "deleted"
    }
  ]
}
```

## 🔄 Alternativas al Scheduler

### Opción A: n8n (Gratis)
Crear un workflow que se ejecute diariamente:

1. **Trigger**: Schedule (Cada día a las 3:00)
2. **HTTP Request**: POST a la Edge Function

### Opción B: GitHub Actions (Gratis)
Crear `.github/workflows/cleanup-documents.yml`:

```yaml
name: Cleanup Expired Documents
on:
  schedule:
    - cron: '0 3 * * *'  # Cada día a las 3:00 UTC
  workflow_dispatch:  # Permite ejecutar manualmente

jobs:
  cleanup:
    runs-on: ubuntu-latest
    steps:
      - name: Call cleanup function
        run: |
          curl -X POST \
            https://qwepisgdqlmqfxwqkztz.supabase.co/functions/v1/cleanup-documents \
            -H "Authorization: Bearer ${{ secrets.CLEANUP_SECRET }}"
```

## 📝 Logs

Los logs se pueden ver en:
- **Supabase Dashboard** → **Edge Functions** → **cleanup-documents** → **Logs**
- **Supabase Dashboard** → **Logs** → **Edge Functions**

## ⚠️ Notas Importantes

1. **Plan Free**: El scheduler de Supabase no está disponible. Usar n8n o GitHub Actions.
2. **Plan Pro**: Usar el scheduler nativo de Supabase (recomendado).
3. Los documentos se eliminan después de **1 año** desde su creación.
4. La eliminación es **permanente** - no se puede recuperar.
