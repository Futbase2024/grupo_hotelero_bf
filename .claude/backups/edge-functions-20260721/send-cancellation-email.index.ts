import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from 'jsr:@supabase/supabase-js@2';

const BREVO_API_URL = 'https://api.brevo.com/v3/smtp/email';

// CORS headers
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const apiKey = Deno.env.get('BREVO_API_KEY');
    const templateId = parseInt(Deno.env.get('BREVO_TEMPLATE_REJECTION') || '3');

    if (!apiKey) {
      throw new Error('BREVO_API_KEY no configurada');
    }

    const body = await req.json();
    const { to_email, to_name, params, booking_id, unit_id } = body;

    console.log('📧 Enviando email de rechazo de check-in a:', to_email);
    console.log('📋 Template ID:', templateId);
    console.log('📦 Parámetros:', JSON.stringify(params, null, 2));

    // Construir payload para Brevo
    const payload = {
      sender: {
        name: 'BF Stay',
        email: 'noreply@bf-stay.app'
      },
      to: [{
        email: to_email,
        name: to_name || 'Huésped'
      }],
      templateId: templateId,
      params: params || {},
      tags: ['checkin', 'rechazo'],
    };

    console.log('🚀 Enviando a Brevo:', JSON.stringify(payload, null, 2));

    // Enviar email via Brevo API
    const response = await fetch(BREVO_API_URL, {
      method: 'POST',
      headers: {
        'accept': 'application/json',
        'content-type': 'application/json',
        'api-key': apiKey
      },
      body: JSON.stringify(payload)
    });

    const responseData = await response.json();
    console.log('📨 Respuesta de Brevo:', JSON.stringify(responseData, null, 2));

    if (!response.ok) {
      console.error('❌ Error de Brevo:', responseData);
      throw new Error(`Error de Brevo: ${responseData.message || response.statusText}`);
    }

    console.log('✅ Email de rechazo enviado correctamente');

    return new Response(
      JSON.stringify({
        success: true,
        messageId: responseData.messageId,
        templateId: templateId
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200
      }
    );

  } catch (error) {
    console.error('❌ Error enviando email:', error);

    return new Response(
      JSON.stringify({
        success: false,
        error: error.message
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500
      }
    );
  }
});