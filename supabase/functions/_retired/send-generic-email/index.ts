// ============================================================================
// COPIA DE SEGURIDAD — versión 17 desplegada de la Edge Function `send-generic-email`
// Retirada el 2026-10-19: estaba desplegada sin autenticación y aceptaba
// cualquier destinatario y cualquier plantilla de Brevo (relay de correo con la
// marca BF Stay). Nada la usaba: ni la app, ni la BD, ni el cron, y su registro
// en email_logs apuntaba a columnas que ya no existen.
// En producción se ha sustituido por un stub que responde 410.
// ============================================================================
// supabase/functions/send-generic-email/index.ts
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

type Payload = {
  to_email: string;
  to_name?: string;
  template_id: number;
  params: Record<string, string | number | boolean>;
  booking_id?: string;
  unit_id?: string;
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

  if (!payload?.params || typeof payload.params !== "object") {
    return jsonResponse({ error: "params is required and must be an object" }, 400, corsHeaders());
  }

  const brevoBody = {
    to: [{ email: payload.to_email, name: payload.to_name }],
    templateId: payload.template_id,
    params: payload.params,
  };

  const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
  const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  const supabase =
    SUPABASE_URL && SUPABASE_SERVICE_ROLE_KEY
      ? createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
          auth: { persistSession: false },
        })
      : null;

  let brevoRespText = "";
  let brevoStatus = 0;

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

    brevoStatus = brevoResp.status;
    brevoRespText = await brevoResp.text();

    if (!brevoResp.ok) {
      if (supabase) {
        await supabase.from("email_logs").insert({
          kind: "generic",
          to_email: payload.to_email,
          template_id: payload.template_id,
          status: "error",
          provider: "brevo",
          provider_status: brevoStatus,
          provider_response: brevoRespText,
          booking_id: payload.booking_id ?? null,
          unit_id: payload.unit_id ?? null,
          params: payload.params,
        });
      }

      return jsonResponse(
        {
          error: "Brevo send failed",
          provider_status: brevoStatus,
          provider_response: brevoRespText,
        },
        502,
        corsHeaders(),
      );
    }

    if (supabase) {
      await supabase.from("email_logs").insert({
        kind: "generic",
        to_email: payload.to_email,
        template_id: payload.template_id,
        status: "sent",
        provider: "brevo",
        provider_status: brevoStatus,
        provider_response: brevoRespText,
        booking_id: payload.booking_id ?? null,
        unit_id: payload.unit_id ?? null,
        params: payload.params,
      });
    }

    return jsonResponse(
      { ok: true, templateId: payload.template_id, provider_status: brevoStatus, provider_response: brevoRespText },
      200,
      corsHeaders(),
    );
  } catch (e) {
    if (supabase) {
      await supabase.from("email_logs").insert({
        kind: "generic",
        to_email: payload.to_email,
        template_id: payload.template_id,
        status: "error",
        provider: "brevo",
        provider_status: brevoStatus || null,
        provider_response: brevoRespText || String(e),
        booking_id: payload.booking_id ?? null,
        unit_id: payload.unit_id ?? null,
        params: payload.params,
      });
    }

    return jsonResponse({ error: "Unexpected error", details: String(e) }, 500, corsHeaders());
  }
});
