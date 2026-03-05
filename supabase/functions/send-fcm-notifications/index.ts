// Edge Function: send-fcm-notifications
// Procesa la cola de notificaciones y envía a FCM

import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { jwt } from 'https://esm.sh/google-jwt@1.0.0'

interface NotificationQueue {
  id: string
  user_id: string
  token: string
  title: string
  body: string
  data: Record<string, unknown>
}

interface FCMResponse {
  name?: string
  error?: {
    code: number
    message: string
    status: string
  }
}

// Configuración de Firebase (desde variables de entorno)
const FIREBASE_PROJECT_ID = Deno.env.get('FIREBASE_PROJECT_ID')!
const FIREBASE_CLIENT_EMAIL = Deno.env.get('FIREBASE_CLIENT_EMAIL')!
const FIREBASE_PRIVATE_KEY = Deno.env.get('FIREBASE_PRIVATE_KEY')!.replace(/\\n/g, '\n')

// Obtener token de acceso OAuth2 para FCM
async function getAccessToken(): Promise<string> {
  const scope = 'https://www.googleapis.com/auth/firebase.messaging'

  const token = await jwt({
    email: FIREBASE_CLIENT_EMAIL,
    key: FIREBASE_PRIVATE_KEY,
    scopes: [scope],
    expiration: 3600,
  })

  return token
}

// Enviar notificación a FCM HTTP v1 API
async function sendFCMNotification(
  accessToken: string,
  token: string,
  title: string,
  body: string,
  data: Record<string, unknown>
): Promise<FCMResponse> {
  const url = `https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`

  const message = {
    message: {
      token: token,
      notification: {
        title: title,
        body: body,
      },
      data: data ? Object.fromEntries(
        Object.entries(data).map(([k, v]) => [k, String(v)])
      ) : {},
      android: {
        priority: 'high',
        notification: {
          channel_id: 'bf_stay_channel',
          priority: 'high',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    },
  }

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(message),
  })

  return await response.json()
}

Deno.serve(async (req) => {
  try {
    // Verificar método
    if (req.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'Method not allowed' }), {
        status: 405,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // Verificar autorización (opcional: usar un secret como API key)
    const authHeader = req.headers.get('Authorization')
    const expectedAuth = Deno.env.get('FCM_API_SECRET')

    if (expectedAuth && authHeader !== `Bearer ${expectedAuth}`) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // Inicializar Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Obtener notificaciones pendientes (máximo 50 por lote)
    const { data: notifications, error: fetchError } = await supabase
      .from('notification_queue')
      .select('*')
      .eq('processed', false)
      .order('created_at', { ascending: true })
      .limit(50)

    if (fetchError) {
      console.error('Error fetching notifications:', fetchError)
      return new Response(JSON.stringify({ error: 'Failed to fetch notifications' }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    if (!notifications || notifications.length === 0) {
      return new Response(JSON.stringify({
        success: true,
        processed: 0,
        message: 'No pending notifications'
      }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    console.log(`Processing ${notifications.length} notifications...`)

    // Obtener token de acceso
    const accessToken = await getAccessToken()

    let successCount = 0
    let errorCount = 0

    // Procesar cada notificación
    for (const notification of notifications as NotificationQueue[]) {
      try {
        const result = await sendFCMNotification(
          accessToken,
          notification.token,
          notification.title,
          notification.body,
          notification.data || {}
        )

        if (result.error) {
          // Marcar como procesado con error
          await supabase
            .from('notification_queue')
            .update({
              processed: true,
              processed_at: new Date().toISOString(),
              error: result.error.message,
            })
            .eq('id', notification.id)

          console.error(`FCM error for ${notification.id}:`, result.error)
          errorCount++
        } else {
          // Marcar como procesado exitosamente
          await supabase
            .from('notification_queue')
            .update({
              processed: true,
              processed_at: new Date().toISOString(),
            })
            .eq('id', notification.id)

          console.log(`Sent notification ${notification.id}: ${result.name}`)
          successCount++
        }
      } catch (err) {
        // Error de red u otro error
        await supabase
          .from('notification_queue')
          .update({
            processed: true,
            processed_at: new Date().toISOString(),
            error: err instanceof Error ? err.message : 'Unknown error',
          })
          .eq('id', notification.id)

        console.error(`Error processing ${notification.id}:`, err)
        errorCount++
      }
    }

    return new Response(JSON.stringify({
      success: true,
      processed: successCount,
      errors: errorCount,
      total: notifications.length,
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    })

  } catch (error) {
    console.error('Edge function error:', error)
    return new Response(JSON.stringify({
      error: 'Internal server error',
      message: error instanceof Error ? error.message : 'Unknown error',
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})
