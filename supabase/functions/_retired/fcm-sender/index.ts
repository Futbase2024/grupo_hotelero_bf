// ============================================================================
// COPIA DE SEGURIDAD — versión 13 desplegada de la Edge Function `fcm-sender`
// Retirada el 2026-10-19: sin uso (solo la referenciaba la función de BD
// process_notification_queue(), que nada llama) y desplegada sin autenticación.
// Usaba la API Legacy de FCM (retirada por Google): si alguien la llamaba,
// marcaba la cola como procesada con error y los push reales no salían.
// Además devolvía información de depuración del entorno.
// La cola la procesa `send-fcm-notifications`.
// En producción se ha sustituido por un stub que responde 410.
// ============================================================================
// Edge Function: fcm-sender
// Versión 2 - Con Legacy FCM HTTP API completo

import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

Deno.serve(async (req) => {
  console.log('=== FCM-SENDER V2 - INICIO ===')

  const debugInfo: Record<string, unknown> = {
    step: 'init',
    timestamp: new Date().toISOString(),
    version: 2,
  }

  try {
    // 1. Verificar método
    debugInfo.step = 'check_method'
    if (req.method !== 'POST') {
      return new Response(JSON.stringify({ debug: debugInfo, error: 'Method not allowed' }), {
        status: 405,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // 2. Verificar variables de entorno
    debugInfo.step = 'check_env'
    const FIREBASE_PROJECT_ID = Deno.env.get('FIREBASE_PROJECT_ID')
    const FCM_SERVER_KEY = Deno.env.get('FCM_API_SECRET')
    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

    debugInfo.env = {
      hasFirebaseProjectId: !!FIREBASE_PROJECT_ID,
      hasFcmServerKey: !!FCM_SERVER_KEY,
      fcmServerKeyLength: FCM_SERVER_KEY?.length || 0,
      hasSupabaseUrl: !!supabaseUrl,
      hasServiceKey: !!supabaseServiceKey,
    }

    if (!FIREBASE_PROJECT_ID || !FCM_SERVER_KEY) {
      return new Response(JSON.stringify({
        debug: debugInfo,
        error: 'Missing Firebase env vars. Need FIREBASE_PROJECT_ID and FCM_API_SECRET (Server Key)',
      }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    if (!supabaseUrl || !supabaseServiceKey) {
      return new Response(JSON.stringify({
        debug: debugInfo,
        error: 'Missing Supabase env vars',
      }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // 3. Inicializar Supabase
    debugInfo.step = 'init_supabase'
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // 4. Obtener notificaciones pendientes
    debugInfo.step = 'fetch_notifications'
    const { data: notifications, error: fetchError } = await supabase
      .from('notification_queue')
      .select('*')
      .eq('processed', false)
      .order('created_at', { ascending: true })
      .limit(50)

    if (fetchError) {
      return new Response(JSON.stringify({
        debug: debugInfo,
        error: 'Failed to fetch notifications',
        details: fetchError,
      }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    debugInfo.notificationsCount = notifications?.length || 0

    if (!notifications || notifications.length === 0) {
      return new Response(JSON.stringify({
        debug: debugInfo,
        success: true,
        processed: 0,
        message: 'No pending notifications',
      }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // 5. Enviar notificaciones usando Legacy FCM HTTP API
    debugInfo.step = 'send_notifications'
    let successCount = 0
    let errorCount = 0
    const errors: Array<{ id: string; error: string }> = []

    for (const notification of notifications) {
      try {
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

        debugInfo.currentNotification = notification.id

        const fcmResponse = await fetch(fcmUrl, {
          method: 'POST',
          headers: {
            'Authorization': `key=${FCM_SERVER_KEY}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(message),
        })

        const fcmResult = await fcmResponse.json()

        if (fcmResponse.ok && fcmResult.success !== undefined && fcmResult.success > 0) {
          await supabase.from('notification_queue').update({
            processed: true,
            processed_at: new Date().toISOString(),
          }).eq('id', notification.id)
          successCount++
          debugInfo.lastSuccess = true
        } else {
          const errorMsg = fcmResult.results?.[0]?.error || JSON.stringify(fcmResult)
          await supabase.from('notification_queue').update({
            processed: true,
            processed_at: new Date().toISOString(),
            error: errorMsg,
          }).eq('id', notification.id)
          errors.push({ id: notification.id, error: errorMsg })
          errorCount++
        }
      } catch (sendError) {
        errors.push({
          id: notification.id,
          error: sendError instanceof Error ? sendError.message : String(sendError),
        })
        errorCount++
      }
    }

    debugInfo.step = 'completed'
    debugInfo.successCount = successCount
    debugInfo.errorCount = errorCount

    return new Response(JSON.stringify({
      debug: debugInfo,
      success: true,
      processed: successCount,
      errors: errorCount,
      total: notifications.length,
      errorDetails: errors.length > 0 ? errors : undefined,
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    })

  } catch (globalError) {
    debugInfo.step = 'global_error'
    console.error('GLOBAL ERROR:', globalError)
    return new Response(JSON.stringify({
      debug: debugInfo,
      error: 'Global error',
      details: globalError instanceof Error ? {
        message: globalError.message,
        stack: globalError.stack,
        name: globalError.name,
      } : String(globalError),
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})
