// Edge Function: fcm-sender
// Procesa la cola de notificaciones y envía a FCM usando Legacy HTTP API

import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

interface NotificationQueue {
  id: string
  user_id: string
  token: string
  title: string
  body: string
  data: Record<string, unknown>
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

    // Inicializar Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const FCM_SERVER_KEY = Deno.env.get('FCM_SERVER_KEY')!

    if (!FCM_SERVER_KEY) {
      return new Response(JSON.stringify({ error: 'FCM_SERVER_KEY not configured' }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      })
    }

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

    let successCount = 0
    let errorCount = 0

    // Procesar cada notificación
    for (const notification of notifications as NotificationQueue[]) {
      try {
        // Legacy FCM HTTP API endpoint
        const fcmUrl = 'https://fcm.googleapis.com/fcm/send'

        const message = {
          to: notification.token,
          notification: {
            title: notification.title,
            body: notification.body,
          },
          data: notification.data || {},
          priority: 'high',
        }

        const fcmResponse = await fetch(fcmUrl, {
          method: 'POST',
          headers: {
            'Authorization': `key=${FCM_SERVER_KEY}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(message),
        })

        const fcmResult = await fcmResponse.json()

        if (!fcmResponse.ok) {
          // Marcar como procesado con error
          await supabase
            .from('notification_queue')
            .update({
              processed: true,
              processed_at: new Date().toISOString(),
              error: JSON.stringify(fcmResult),
            })
            .eq('id', notification.id)

          console.error(`FCM error for ${notification.id}:`, fcmResult)
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

          console.log(`Sent notification ${notification.id}: success`)
          successCount++
        }
      } catch (err) {
        // Marcar como procesado con error
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
