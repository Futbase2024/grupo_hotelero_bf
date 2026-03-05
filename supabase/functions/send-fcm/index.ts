import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface NotificationRequest {
  token: string
  title: string
  body: string
  data?: Record<string, string>
}

interface FCMessage {
  message: {
    token: string
    notification: {
      title: string
      body: string
    }
    data?: Record<string, string>
    apns?: {
      payload: {
        aps: {
          sound: string
          badge: number
        }
      }
    }
    android?: {
      notification: {
        channel_id: string
        sound: string
      }
    }
  }
}

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Obtener credenciales de Firebase
    const firebaseProjectId = Deno.env.get('FIREBASE_PROJECT_ID')
    const serviceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')

    if (!firebaseProjectId || !serviceAccountJson) {
      throw new Error('Faltan credenciales de Firebase')
    }

    let serviceAccount
    try {
      serviceAccount = JSON.parse(serviceAccountJson)
    } catch (e) {
      throw new Error('Error parseando FIREBASE_SERVICE_ACCOUNT')
    }

    // Obtener access token usando OAuth2
    const now = Math.floor(Date.now() / 1000)
    const jwtHeader = btoa(JSON.stringify({ alg: 'RS256', typ: 'JWT' }))

    // Crear JWT assertion (simplificado - en producción usar una librería)
    const jwtPayload = {
      iss: serviceAccount.client_email,
      sub: serviceAccount.client_email,
      aud: 'https://oauth2.googleapis.com/token',
      iat: now,
      exp: now + 3600,
      scope: 'https://www.googleapis.com/auth/firebase.messaging'
    }

    // Obtener access token
    const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion: await createJWT(serviceAccount.private_key, jwtHeader, jwtPayload)
      })
    })

    const tokenData = await tokenResponse.json()
    const accessToken = tokenData.access_token

    if (!accessToken) {
      throw new Error('No se pudo obtener access token de Google')
    }

    // Verificar si es una petición directa o procesar cola
    const contentType = req.headers.get('content-type') || ''

    if (contentType.includes('application/json')) {
      // Petición directa para enviar notificación
      const body: NotificationRequest = await req.json()

      const fcmMessage: FCMessage = {
        message: {
          token: body.token,
          notification: {
            title: body.title,
            body: body.body
          },
          data: body.data,
          apns: {
            payload: {
              aps: {
                sound: 'default',
                badge: 1
              }
            }
          },
          android: {
            notification: {
              channel_id: 'bf_stay_channel',
              sound: 'default'
            }
          }
        }
      }

      // Enviar a FCM
      const fcmResponse = await fetch(
        `https://fcm.googleapis.com/v1/projects/${firebaseProjectId}/messages:send`,
        {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${accessToken}`,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify(fcmMessage)
        }
      )

      const fcmData = await fcmResponse.json()

      if (!fcmResponse.ok) {
        console.error('FCM Error:', fcmData)
        return new Response(
          JSON.stringify({ error: fcmData.error?.message || 'Error enviando notificación' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      return new Response(
        JSON.stringify({ success: true, messageId: fcmData.name }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Procesar cola de notificaciones
    const { data: notifications, error: fetchError } = await supabaseClient
      .from('notification_queue')
      .select('*')
      .eq('processed', false)
      .order('created_at', { ascending: true })
      .limit(50)

    if (fetchError) {
      throw fetchError
    }

    if (!notifications || notifications.length === 0) {
      return new Response(
        JSON.stringify({ message: 'No hay notificaciones pendientes' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    let successCount = 0
    let errorCount = 0

    for (const notification of notifications) {
      try {
        const fcmMessage: FCMessage = {
          message: {
            token: notification.token,
            notification: {
              title: notification.title,
              body: notification.body
            },
            data: notification.data || {},
            apns: {
              payload: {
                aps: {
                  sound: 'default',
                  badge: 1
                }
              }
            },
            android: {
              notification: {
                channel_id: 'bf_stay_channel',
                sound: 'default'
              }
            }
          }
        }

        const fcmResponse = await fetch(
          `https://fcm.googleapis.com/v1/projects/${firebaseProjectId}/messages:send`,
          {
            method: 'POST',
            headers: {
              'Authorization': `Bearer ${accessToken}`,
              'Content-Type': 'application/json'
            },
            body: JSON.stringify(fcmMessage)
          }
        )

        const fcmData = await fcmResponse.json()

        // Actualizar estado de la notificación
        if (fcmResponse.ok) {
          await supabaseClient
            .from('notification_queue')
            .update({
              processed: true,
              processed_at: new Date().toISOString()
            })
            .eq('id', notification.id)

          await supabaseClient
            .from('notification_logs')
            .insert({
              notification_id: notification.id,
              success: true,
              fcm_message_id: fcmData.name
            })

          successCount++
        } else {
          await supabaseClient
            .from('notification_queue')
            .update({
              processed: true,
              processed_at: new Date().toISOString(),
              error: fcmData.error?.message || 'Error desconocido'
            })
            .eq('id', notification.id)

          await supabaseClient
            .from('notification_logs')
            .insert({
              notification_id: notification.id,
              success: false,
              error_message: fcmData.error?.message || 'Error desconocido'
            })

          errorCount++
        }
      } catch (err) {
        console.error(`Error procesando notificación ${notification.id}:`, err)
        errorCount++
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        processed: notifications.length,
        successCount,
        errorCount
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

// Función auxiliar para crear JWT
async function createJWT(privateKey: string, header: string, payload: object): Promise<string> {
  const encoder = new TextEncoder()
  const privateKeyObj = await crypto.subtle.importKey(
    'pkcs8',
    pemToArrayBuffer(privateKey),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign']
  )

  const headerB64 = base64UrlEncode(header)
  const payloadB64 = base64UrlEncode(JSON.stringify(payload))
  const signatureInput = `${headerB64}.${payloadB64}`

  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    privateKeyObj,
    encoder.encode(signatureInput)
  )

  const signatureB64 = base64UrlEncode(new Uint8Array(signature))
  return `${signatureInput}.${signatureB64}`
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const pemContents = pem
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s/g, '')

  const binaryString = atob(pemContents)
  const bytes = new Uint8Array(binaryString.length)
  for (let i = 0; i < binaryString.length; i++) {
    bytes[i] = binaryString.charCodeAt(i)
  }
  return bytes.buffer
}

function base64UrlEncode(input: string | Uint8Array): string {
  let str: string
  if (input instanceof Uint8Array) {
    str = String.fromCharCode(...input)
  } else {
    str = input
  }
  return btoa(str)
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '')
}
