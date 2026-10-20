// ============================================================================
// COPIA DE SEGURIDAD — versión 17 desplegada de la Edge Function `send-marketing-email`
// Retirada el 2026-10-19: desplegada sin autenticación (cualquiera podía
// enviar emails con la marca BF Stay) y sin uso en la app, la BD ni el cron.
// En producción se ha sustituido por un stub que responde 410.
// ============================================================================
// supabase/functions/send-marketing-email/index.ts
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

type Payload = {
  to_email: string;
  to_name?: string;
  template_id: number;
  params: Record<string, string | number | boolean>;
};

function jsonResponse(body: unknown, status = 200, extraHeaders: HeadersInit = {}) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      ...extraHeaders,
    },
  });
}

function corsHeaders(origin = "*") {
  return {
    "Access-Control-Allow-Origin": origin,
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
  };
}

function isValidEmail(email: string) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders() });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405, corsHeaders());
  }

  const BREVO_API_KEY = Deno.env.get("BREVO_API_KEY");
  if (!BREVO_API_KEY) {
    return jsonResponse({ error: "Missing BREVO_API_KEY env var" }, 500, corsHeaders());
  }

  let payload: Payload;
  try {
    payload = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400, corsHeaders());
  }

  if (!payload?.to_email || !isValidEmail(payload.to_email)) {
    return jsonResponse({ error: "to_email is required and must be valid" }, 400, corsHeaders());
  }

  if (!payload?.template_id || !Number.isFinite(payload.template_id) || payload.template_id <= 0) {
    return jsonResponse({ error: "template_id is required and must be a positive number" }, 400, corsHeaders());
  }

  const brevoBody = {
    to: [{ email: payload.to_email, name: payload.to_name }],
    templateId: payload.template_id,
    params: payload.params,
  };

  try {
    const brevoResp = await fetch("https://api.brevo.com/v3/smtp/email", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "api-key": BREVO_API_KEY,
        "accept": "application/json",
      },
      body: JSON.stringify(brevoBody),
    });

    const brevoRespText = await brevoResp.text();

    if (!brevoResp.ok) {
      return jsonResponse(
        {
          error: "Brevo send failed",
          provider_status: brevoResp.status,
          provider_response: brevoRespText,
        },
        502,
        corsHeaders(),
      );
    }

    return jsonResponse(
      { ok: true, templateId: payload.template_id, provider_status: brevoResp.status, provider_response: brevoRespText },
      200,
      corsHeaders(),
    );
  } catch (e) {
    return jsonResponse({ error: "Unexpected error", details: String(e) }, 500, corsHeaders());
  }
});
