// Edge Function: send-fcm-notifications
// Procesa la cola de notificaciones y envía a FCM

import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { SignJWT, importPKCS8 } from 'https://esm.sh/jose@5.9.6'

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

// Obtener token de acceso OAuth2 para FCM usando jose
async function getAccessToken(): Promise<string> {
  const scope = 'https://www.googleapis.com/auth/firebase.messaging'

  // Importar la clave privada
  const privateKey = await importPKCS8(FIREBASE_PRIVATE_KEY, 'RS256')

  // Crear el JWT
  const jwt = await new SignJWT({
    scope: scope,
  })
    .setProtectedHeader({ alg: 'RS256', typ: 'JWT' })
    .setIssuer(FIREBASE_CLIENT_EMAIL)
    .setSubject(FIREBASE_CLIENT_EMAIL)
    .setAudience('https://oauth2.googleapis.com/token')
    .setIssuedAt()
    .setExpirationTime('1h')
    .sign(privateKey)

  // Intercambiar JWT por access token
  const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }).toString(),
  })

  const tokenData = await tokenResponse.json()

  if (!tokenData.access_token) {
    throw new Error(`Failed to get access token: ${JSON.stringify(tokenData)}`)
  }

  return tokenData.access_token
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

  // Mensaje con notification payload para background/terminated
  // Flutter evitará duplicados en foreground verificando si hay notification payload
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
          notification_count: 1,
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

    // Verificar autorización solo si viene header (para llamadas externas)
    // Las llamadas internas desde triggers de Supabase no tienen header
    const authHeader = req.headers.get('Authorization')
    const expectedAuth = Deno.env.get('FCM_API_SECRET')

    // Si viene header de autorización, validarlo
    // Si NO viene header, permitir (llamada interna desde trigger)
    if (authHeader && expectedAuth && authHeader !== `Bearer ${expectedAuth}`) {
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
